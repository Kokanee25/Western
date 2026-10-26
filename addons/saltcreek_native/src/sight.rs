//! `SightWorld` (docs/briefs/more-cores.md step 3): what a man can see, what hides him, which lamp
//! reaches him, answered from a copy of the sight layers' shapes (sight_geo.rs) instead of Jolt.
//! `src/people/sight.gd` feeds it (the bodies by their RIDs: it reads each one's shapes from the
//! physics server itself) and asks it. Batches of more than `SPLIT` rays go across the plugin's
//! worker threads; the answer is the same whichever thread gives it.

use crate::pool;
use crate::sight_geo::{Geo, Hit, Prim, Scene, TriMesh};
use glam::{Affine3A, Vec3, Vec3A};
use godot::classes::physics_server_3d::{BodyMode, BodyState, ShapeType};
use godot::classes::PhysicsServer3D;
use godot::prelude::*;
use std::collections::HashMap;
use std::sync::mpsc::channel;
use std::sync::Arc;

/// A batch longer than this is split across the worker threads.
const SPLIT: usize = 200;
/// The tree is built again once this many prims sit beside it, or a quarter of it is dead.
const LOOSE_MAX: usize = 256;

struct Body {
    prims: Vec<u32>,
    /// The body's shapes in its own space (what a move re-places).
    shapes: Vec<(Geo, Affine3A)>,
    /// Moved by the physics (rigid, kinematic): placed again every `refresh_moving`.
    moving: bool,
    /// Taken again since it was first taken (moved or reshaped by script: the horse on his bones,
    /// a prop set down): kept beside the tree until it's built again.
    beside: bool,
    /// Changed since the tree was last built: one that keeps changing (the horse) stays beside.
    changed: bool,
    layer: u32,
    kind: i32,
}

#[derive(GodotClass)]
#[class(base = RefCounted, init)]
pub struct SightWorld {
    base: Base<RefCounted>,
    scene: Arc<Scene>,
    bodies: HashMap<i64, Body>,
    /// The bodies the physics moves, in the order taken (placed again each `refresh_moving`).
    movers: Vec<i64>,
    #[init(val = Rid::Invalid)]
    space: Rid,
    loose_fixed: usize,
    beside_prims: usize,
    unsupported: i64,
    rebuilds: i64,
    last: Vec<Hit>,
    #[init(val = Hit::NONE)]
    one: Hit,
}

fn v3(v: Vector3) -> Vec3 {
    Vec3::new(v.x, v.y, v.z)
}

fn gv3(v: Vec3) -> Vector3 {
    Vector3::new(v.x, v.y, v.z)
}

fn affine(t: Transform3D) -> Affine3A {
    let b = t.basis;
    Affine3A::from_mat3_translation(
        glam::Mat3::from_cols(v3(b.col_a()), v3(b.col_b()), v3(b.col_c())),
        v3(t.origin),
    )
}

fn same_geo(a: &Geo, b: &Geo) -> bool {
    match (a, b) {
        (Geo::Box(x), Geo::Box(y)) => x == y,
        (Geo::Sphere(x), Geo::Sphere(y)) => x == y,
        (Geo::Capsule(r, h), Geo::Capsule(r2, h2)) | (Geo::Cylinder(r, h), Geo::Cylinder(r2, h2)) => r == r2 && h == h2,
        (Geo::Mesh(m, s), Geo::Mesh(m2, s2)) => s == s2 && m.tris.len() == m2.tris.len() && m.tris == m2.tris,
        _ => false,
    }
}

fn ids(exclude: &Array<Rid>) -> Vec<i64> {
    exclude.iter_shared().map(|r| r.to_u64() as i64).collect()
}

fn dict_f32(d: &VarDictionary, key: &str) -> f32 {
    d.get(&key.to_variant()).and_then(|v| v.try_to::<f32>().ok()).unwrap_or(0.0)
}

/// A shape's geometry from the server's description (PhysicsServer3D.shape_get_data), or None
/// for a type sight doesn't take (it's counted: `unsupported`).
fn geo_of(server: &Gd<PhysicsServer3D>, shape: Rid) -> Option<Geo> {
    let ty = server.shape_get_type(shape);
    let data = server.shape_get_data(shape);
    if ty == ShapeType::BOX {
        return data.try_to::<Vector3>().ok().map(|h| Geo::Box(v3(h)));
    }
    if ty == ShapeType::SPHERE {
        return data.try_to::<f32>().ok().map(Geo::Sphere);
    }
    if ty == ShapeType::CAPSULE || ty == ShapeType::CYLINDER {
        let d = data.try_to::<VarDictionary>().ok()?;
        let r = dict_f32(&d, "radius");
        let h = dict_f32(&d, "height");
        return Some(if ty == ShapeType::CAPSULE {
            Geo::Capsule(r, (h * 0.5 - r).max(0.0))
        } else {
            Geo::Cylinder(r, h * 0.5)
        });
    }
    if ty == ShapeType::CONCAVE_POLYGON {
        let d = data.try_to::<VarDictionary>().ok()?;
        let faces = d.get(&"faces".to_variant())?.try_to::<PackedVector3Array>().ok()?;
        let f = faces.as_slice();
        let tris: Vec<[Vec3A; 3]> = f
            .chunks_exact(3)
            .map(|c| [Vec3A::from(v3(c[0])), Vec3A::from(v3(c[1])), Vec3A::from(v3(c[2]))])
            .collect();
        let two_sided = d.get(&"backface_collision".to_variant()).and_then(|v| v.try_to::<bool>().ok()).unwrap_or(false);
        return Some(Geo::Mesh(Arc::new(TriMesh::new(tris)), two_sided));
    }
    if ty == ShapeType::HEIGHTMAP {
        let d = data.try_to::<VarDictionary>().ok()?;
        let w = dict_f32(&d, "width") as usize;
        let dp = dict_f32(&d, "depth") as usize;
        let heights = d.get(&"heights".to_variant())?.try_to::<PackedFloat32Array>().ok()?;
        return Some(Geo::Mesh(Arc::new(TriMesh::height_field(w, dp, heights.as_slice())), true));
    }
    None
}

impl SightWorld {
    fn scene_mut(&mut self) -> &mut Scene {
        Arc::make_mut(&mut self.scene)
    }

    fn drop_body(&mut self, id: i64) {
        if let Some(b) = self.bodies.remove(&id) {
            if b.moving {
                self.movers.retain(|&m| m != id);
            }
            let scene = Arc::make_mut(&mut self.scene);
            for i in b.prims {
                if let Some(p) = scene.prims.get_mut(i as usize) {
                    if p.alive {
                        p.alive = false;
                        scene.dead += 1;
                    }
                }
            }
        }
    }

    fn place(&mut self, id: i64, xf: Affine3A) {
        let Some(b) = self.bodies.get(&id) else { return };
        let (layer, kind) = (b.layer, b.kind);
        let placed: Vec<(u32, Prim)> =
            b.prims.iter().zip(b.shapes.iter()).map(|(&i, (g, local))| (i, Prim::new(g.clone(), xf * *local, id, layer, kind))).collect();
        let scene = self.scene_mut();
        for (i, p) in placed {
            scene.prims[i as usize] = p;
        }
    }

    fn push_loose(&mut self, placed: Vec<Prim>) -> Vec<u32> {
        let scene = Arc::make_mut(&mut self.scene);
        let mut out = Vec::with_capacity(placed.len());
        for p in placed {
            let i = scene.prims.len() as u32;
            out.push(i);
            scene.loose.push(i);
            scene.prims.push(p);
        }
        out
    }

    /// The tree again, if enough has changed beside it: what's new, what's gone, what changed
    /// once (a body changed again since the last build stays beside: the horse on his bones).
    fn tidy(&mut self) {
        let n = self.scene.prims.len();
        if self.loose_fixed <= LOOSE_MAX && self.beside_prims <= LOOSE_MAX && self.scene.dead * 4 <= n.max(16) {
            return;
        }
        let mut keep_beside = std::collections::HashSet::new();
        self.beside_prims = 0;
        for (id, b) in self.bodies.iter_mut() {
            if b.moving {
                keep_beside.insert(*id);
            } else if b.beside && b.changed {
                keep_beside.insert(*id);
                b.changed = false;
            } else {
                b.beside = false;
            }
        }
        let remap = Arc::make_mut(&mut self.scene).rebuild(|p| keep_beside.contains(&p.id));
        for b in self.bodies.values_mut() {
            for i in b.prims.iter_mut() {
                *i = remap[*i as usize];
            }
            if b.beside && !b.moving {
                self.beside_prims += b.prims.len();
            }
        }
        self.loose_fixed = 0;
        self.rebuilds += 1;
    }

    fn cast_all(&mut self, from: &[Vector3], to: &[Vector3], mask: u32, exclude: Vec<i64>) -> Vec<Hit> {
        self.tidy();
        let n = from.len().min(to.len());
        let rays: Vec<(Vec3, Vec3)> = (0..n).map(|i| (v3(from[i]), v3(to[i]))).collect();
        if n <= SPLIT {
            return rays.iter().map(|(a, b)| self.scene.cast(*a, *b, mask, &exclude)).collect();
        }
        let parts = (pool::threads() + 1).min(n.div_ceil(SPLIT / 2)).max(1);
        let per = n.div_ceil(parts);
        let rays = Arc::new(rays);
        let exclude = Arc::new(exclude);
        let (tx, rx) = channel::<(usize, Vec<Hit>)>();
        for k in 1..parts {
            let (scene, rays, exclude, tx) = (Arc::clone(&self.scene), Arc::clone(&rays), Arc::clone(&exclude), tx.clone());
            pool::submit(move || {
                let lo = (k * per).min(rays.len());
                let hi = ((k + 1) * per).min(rays.len());
                let out: Vec<Hit> = rays[lo..hi].iter().map(|(a, b)| scene.cast(*a, *b, mask, &exclude)).collect();
                // Let go of the scene before answering, so the next change doesn't copy it.
                drop(scene);
                let _ = tx.send((k, out));
            });
        }
        drop(tx);
        let mut chunks: Vec<Vec<Hit>> = vec![Vec::new(); parts];
        chunks[0] = rays[0..per.min(n)].iter().map(|(a, b)| self.scene.cast(*a, *b, mask, &exclude)).collect();
        for (k, out) in rx.iter() {
            chunks[k] = out;
        }
        chunks.into_iter().flatten().collect()
    }
}

#[godot_api]
impl SightWorld {
    /// Only bodies in this physics space are taken (the game's world, not a preview's).
    #[func]
    fn set_space(&mut self, space: Rid) {
        self.space = space;
    }

    /// Take (or take again) these bodies by their RIDs' ids, reading their shapes, layer, mode and
    /// place from the physics server: `kinds` what the game says each is, `disabled` a bit for
    /// each of its first 64 shapes that's switched off. Returns how many were taken.
    #[func]
    fn add_bodies(&mut self, ids: PackedInt64Array, kinds: PackedInt32Array, disabled: PackedInt64Array) -> i64 {
        let server = PhysicsServer3D::singleton();
        let ids = ids.as_slice();
        let kinds = kinds.as_slice();
        let disabled = disabled.as_slice();
        let mut taken = 0;
        for (k, &id) in ids.iter().enumerate() {
            let rid = Rid::new(id as u64);
            if !rid.is_valid() || (self.space.is_valid() && server.body_get_space(rid) != self.space) {
                self.drop_body(id);
                continue;
            }
            let layer = server.body_get_collision_layer(rid);
            let off = disabled.get(k).copied().unwrap_or(0);
            let mut shapes = Vec::new();
            for i in 0..server.body_get_shape_count(rid) {
                if i < 64 && off & (1i64 << i) != 0 {
                    continue;
                }
                match geo_of(&server, server.body_get_shape(rid, i)) {
                    Some(g) => shapes.push((g, affine(server.body_get_shape_transform(rid, i)))),
                    None => self.unsupported += 1,
                }
            }
            let moving = server.body_get_mode(rid) != BodyMode::STATIC;
            let xf = server.body_get_state(rid, BodyState::TRANSFORM).try_to::<Transform3D>().map(affine).unwrap_or(Affine3A::IDENTITY);
            let kind = kinds.get(k).copied().unwrap_or(0);
            let placed: Vec<Prim> = shapes.iter().map(|(g, local)| Prim::new(g.clone(), xf * *local, id, layer, kind)).collect();
            let old = self.bodies.remove(&id);
            if let Some(mut b) = old {
                if b.prims.len() == placed.len() {
                    let scene = Arc::make_mut(&mut self.scene);
                    // Taken again with nothing changed (a member's shape taken off and put back as
                    // it's batched): as it was.
                    let same = b.prims.iter().zip(placed.iter()).all(|(&i, p)| {
                        let q = &scene.prims[i as usize];
                        q.alive && q.aabb.min == p.aabb.min && q.aabb.max == p.aabb.max && q.xf == p.xf && same_geo(&q.geo, &p.geo)
                    });
                    if same && b.layer == layer {
                        for (&i, p) in b.prims.iter().zip(placed) {
                            scene.prims[i as usize].kind = p.kind;
                        }
                        b.kind = kind;
                        self.bodies.insert(id, b);
                        taken += 1;
                        continue;
                    }
                    // The same shapes, changed: in place, beside the tree until it's built again.
                    if !b.moving && !b.beside {
                        scene.loose.extend_from_slice(&b.prims);
                        self.beside_prims += b.prims.len();
                    }
                    for (&i, p) in b.prims.iter().zip(placed) {
                        scene.prims[i as usize] = p;
                    }
                    b.shapes = shapes;
                    if moving && !b.moving {
                        self.movers.push(id);
                    } else if !moving && b.moving {
                        self.movers.retain(|&m| m != id);
                    }
                    b.moving = moving;
                    b.beside = true;
                    b.changed = true;
                    b.layer = layer;
                    b.kind = kind;
                    self.bodies.insert(id, b);
                    taken += 1;
                    continue;
                }
                self.bodies.insert(id, b);
                self.drop_body(id);
                let prims = self.push_loose(placed);
                if moving {
                    self.movers.push(id);
                }
                self.beside_prims += prims.len();
                self.bodies.insert(id, Body { prims, shapes, moving, beside: true, changed: true, layer, kind });
                taken += 1;
                continue;
            }
            let prims = self.push_loose(placed);
            if moving {
                self.movers.push(id);
            } else {
                self.loose_fixed += prims.len();
            }
            self.bodies.insert(id, Body { prims, shapes, moving, beside: false, changed: false, layer, kind });
            taken += 1;
        }
        taken
    }

    /// Bodies whose shapes moved on them but are the same shapes (the horse's, on his bones): their
    /// places read again, not their shapes. One not yet taken, or whose shapes changed in number,
    /// is taken whole.
    #[func]
    fn move_shapes(&mut self, ids: PackedInt64Array) {
        let server = PhysicsServer3D::singleton();
        let mut whole = PackedInt64Array::new();
        let mut whole_kinds = PackedInt32Array::new();
        for &id in ids.as_slice() {
            let rid = Rid::new(id as u64);
            let Some(b) = self.bodies.get(&id) else { continue };
            if server.body_get_shape_count(rid) as usize != b.shapes.len() {
                whole.push(id);
                whole_kinds.push(b.kind);
                continue;
            }
            let xf = server.body_get_state(rid, BodyState::TRANSFORM).try_to::<Transform3D>().map(affine).unwrap_or(Affine3A::IDENTITY);
            let locals: Vec<Affine3A> = (0..b.shapes.len() as i32).map(|i| affine(server.body_get_shape_transform(rid, i))).collect();
            let mut b = self.bodies.remove(&id).unwrap();
            for (shape, local) in b.shapes.iter_mut().zip(locals) {
                shape.1 = local;
            }
            let placed: Vec<Prim> = b.shapes.iter().map(|(g, local)| Prim::new(g.clone(), xf * *local, id, b.layer, b.kind)).collect();
            let scene = Arc::make_mut(&mut self.scene);
            if !b.moving && !b.beside {
                scene.loose.extend_from_slice(&b.prims);
                self.beside_prims += b.prims.len();
            }
            for (&i, p) in b.prims.iter().zip(placed) {
                scene.prims[i as usize] = p;
            }
            b.beside = true;
            b.changed = true;
            self.bodies.insert(id, b);
        }
        if !whole.is_empty() {
            let off = PackedInt64Array::from(vec![0i64; whole.len()].as_slice());
            self.add_bodies(whole, whole_kinds, off);
        }
    }

    /// One body placed where the physics server has it now (the player after his move).
    #[func]
    fn refresh_body(&mut self, id: i64) {
        if self.bodies.contains_key(&id) {
            let server = PhysicsServer3D::singleton();
            if let Ok(t) = server.body_get_state(Rid::new(id as u64), BodyState::TRANSFORM).try_to::<Transform3D>() {
                self.place(id, affine(t));
            }
        }
    }

    #[func]
    fn remove_bodies(&mut self, ids: PackedInt64Array) {
        for &id in ids.as_slice() {
            self.drop_body(id);
        }
    }

    #[func]
    fn has_body(&self, id: i64) -> bool {
        self.bodies.contains_key(&id)
    }

    /// Every body the physics moves (rubble, the player, a loose prop) placed where it is now.
    #[func]
    fn refresh_moving(&mut self) -> i64 {
        let server = PhysicsServer3D::singleton();
        let movers = std::mem::take(&mut self.movers);
        for &id in &movers {
            let rid = Rid::new(id as u64);
            if let Ok(t) = server.body_get_state(rid, BodyState::TRANSFORM).try_to::<Transform3D>() {
                self.place(id, affine(t));
            }
        }
        let n = movers.len() as i64;
        self.movers = movers;
        n
    }

    /// The fraction along each segment `from[i]`..`to[i]` where it first meets something on `mask`
    /// (1.0 for nothing), the bodies in `exclude` aside. `hit_ids`, `hit_normals` and `hit_kinds`
    /// have the rest.
    #[func]
    fn cast(&mut self, from: PackedVector3Array, to: PackedVector3Array, mask: i64, exclude: Array<Rid>) -> PackedFloat32Array {
        let hits = self.cast_all(from.as_slice(), to.as_slice(), mask as u32, ids(&exclude));
        let out: PackedFloat32Array = hits.iter().map(|h| h.t).collect();
        self.last = hits;
        out
    }

    #[func]
    fn hit_ids(&self) -> PackedInt64Array {
        self.last.iter().map(|h| h.id).collect()
    }

    #[func]
    fn hit_normals(&self) -> PackedVector3Array {
        self.last.iter().map(|h| gv3(h.normal)).collect()
    }

    #[func]
    fn hit_kinds(&self) -> PackedInt32Array {
        self.last.iter().map(|h| h.kind).collect()
    }

    /// One segment, as `cast`: its fraction; `one_id`, `one_normal`, `one_kind` the rest.
    #[func]
    fn cast_one(&mut self, from: Vector3, to: Vector3, mask: i64, exclude: Array<Rid>) -> f32 {
        self.tidy();
        self.one = self.scene.cast(v3(from), v3(to), mask as u32, &ids(&exclude));
        self.one.t
    }

    /// Nothing on `mask` between `from` and `to` (the bodies in `exclude` aside), or nothing short
    /// of `near` metres from `to` (the thing looked at itself). Stops at the first thing found.
    #[func]
    fn clear(&mut self, from: Vector3, to: Vector3, mask: i64, exclude: Array<Rid>, near: f32) -> bool {
        self.tidy();
        let (a, b) = (v3(from), v3(to));
        let len = a.distance(b);
        if len <= near {
            return true;
        }
        !self.scene.any(a, b, mask as u32, &ids(&exclude), 1.0 - near / len)
    }

    #[func]
    fn one_id(&self) -> i64 {
        self.one.id
    }

    #[func]
    fn one_normal(&self) -> Vector3 {
        gv3(self.one.normal)
    }

    #[func]
    fn one_kind(&self) -> i32 {
        self.one.kind
    }

    /// What it holds: {bodies, prims, moving, loose, dead, rebuilds, unsupported, threads}.
    #[func]
    fn stats(&self) -> VarDictionary {
        let mut d = VarDictionary::new();
        d.set(&"bodies".to_variant(), &(self.bodies.len() as i64).to_variant());
        d.set(&"prims".to_variant(), &((self.scene.prims.len() - self.scene.dead) as i64).to_variant());
        d.set(&"moving".to_variant(), &(self.movers.len() as i64).to_variant());
        d.set(&"beside".to_variant(), &(self.bodies.values().filter(|b| b.beside).count() as i64).to_variant());
        d.set(&"loose".to_variant(), &(self.scene.loose.len() as i64).to_variant());
        d.set(&"dead".to_variant(), &(self.scene.dead as i64).to_variant());
        d.set(&"rebuilds".to_variant(), &self.rebuilds.to_variant());
        d.set(&"unsupported".to_variant(), &self.unsupported.to_variant());
        d.set(&"threads".to_variant(), &(pool::threads() as i64 + 1).to_variant());
        d
    }
}
