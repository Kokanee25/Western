//! The sight service's geometry (docs/briefs/more-cores.md, "The design" A): the shapes on the
//! sight layers as the physics server holds them, a bounding-volume hierarchy over the standing
//! ones, and rays cast against it. Pure data, no Godot objects, so a batch of rays can be split
//! across the worker threads (pool.rs) and every thread gives the same answer.
//!
//! The rules are Jolt's as Godot asks it (`intersect_ray` with its defaults: bodies, not areas;
//! `hit_from_inside` false; `hit_back_faces` true): a convex shape (box, sphere, capsule, cylinder)
//! a ray starts inside isn't hit at all; a triangle (a carved member, a dug tile) is hit from
//! either side; the nearest hit wins. The BVH is a plain median split (the idea from Wald's "On
//! fast construction of SAH-based bounding volume hierarchies", 2007, taken only as far as its
//! simplest form): built again when enough has changed, with what moves kept in a short list
//! beside it and tested one by one.

use glam::{Affine3A, Vec3, Vec3A};
use std::sync::Arc;

#[derive(Clone, Copy, Debug)]
pub struct Aabb {
    pub min: Vec3A,
    pub max: Vec3A,
}

impl Aabb {
    pub const EMPTY: Aabb = Aabb { min: Vec3A::splat(f32::INFINITY), max: Vec3A::splat(f32::NEG_INFINITY) };

    pub fn grow(&mut self, o: &Aabb) {
        self.min = self.min.min(o.min);
        self.max = self.max.max(o.max);
    }

    pub fn add(&mut self, p: Vec3A) {
        self.min = self.min.min(p);
        self.max = self.max.max(p);
    }

    pub fn centre(&self) -> Vec3A {
        (self.min + self.max) * 0.5
    }

    /// The ray's entry fraction into the box, if it enters before `best` (inclusive of its
    /// faces, and a ray parallel to a pair of faces counts only between them: Jolt's RayAABox).
    #[inline]
    fn ray(&self, o: Vec3A, inv: &RayInv, best: f32) -> Option<f32> {
        // Loose (the box is grown by GROW): four lanes at once, no case for a parallel axis.
        let t1 = (self.min - o) * inv.wide;
        let t2 = (self.max - o) * inv.wide;
        let tmin = t1.min(t2).max_element().max(0.0);
        let tmax = t1.max(t2).min_element().min(best);
        if tmin <= tmax {
            Some(tmin)
        } else {
            None
        }
    }

    pub fn grown(&self) -> Aabb {
        Aabb { min: self.min - Vec3A::splat(GROW), max: self.max + Vec3A::splat(GROW) }
    }

    fn area(&self) -> f32 {
        let e = (self.max - self.min).max(Vec3A::ZERO);
        e.x * e.y + e.y * e.z + e.z * e.x
    }
}

/// A ray's direction made ready for slab tests: its inverse, and which axes it runs along a
/// slab's faces (Jolt's RayInvDirection: within 1e-20 of nothing).
#[derive(Clone, Copy, Debug)]
pub struct RayInv {
    inv: Vec3A,
    parallel: [bool; 3],
    /// For the trees' boxes (grown by `GROW`, so the test can be loose): the inverse with a
    /// parallel axis's taken as huge, no special case.
    wide: Vec3A,
}

impl RayInv {
    pub fn new(d: Vec3A) -> RayInv {
        let parallel = [d.x.abs() <= 1e-20, d.y.abs() <= 1e-20, d.z.abs() <= 1e-20];
        let inv = Vec3A::new(
            if parallel[0] { 0.0 } else { 1.0 / d.x },
            if parallel[1] { 0.0 } else { 1.0 / d.y },
            if parallel[2] { 0.0 } else { 1.0 / d.z },
        );
        let wide = Vec3A::new(
            if parallel[0] { 1e30 } else { inv.x },
            if parallel[1] { 1e30 } else { inv.y },
            if parallel[2] { 1e30 } else { inv.z },
        );
        RayInv { inv, parallel, wide }
    }
}

/// The trees' boxes (and each prim's world box) are grown by this (m) all round, so their quick
/// test never turns away a shape the exact test would hit (a line along a face, a hair's float).
const GROW: f32 = 1e-4;

/// The entry and exit fractions of a ray through the box `lo`..`hi`, or None if it misses (or
/// runs parallel to a pair of faces outside them).
#[inline]
fn slab(o: Vec3A, r: &RayInv, lo: Vec3A, hi: Vec3A) -> Option<(f32, f32)> {
    let mut tmin = f32::NEG_INFINITY;
    let mut tmax = f32::INFINITY;
    for a in 0..3 {
        if r.parallel[a] {
            if o[a] < lo[a] || o[a] > hi[a] {
                return None;
            }
            continue;
        }
        let t1 = (lo[a] - o[a]) * r.inv[a];
        let t2 = (hi[a] - o[a]) * r.inv[a];
        tmin = tmin.max(t1.min(t2));
        tmax = tmax.min(t1.max(t2));
    }
    if tmin > tmax || tmax < 0.0 {
        return None;
    }
    Some((tmin, tmax))
}

/// A shape in its own space, as Godot's server describes it.
#[derive(Clone, Debug)]
pub enum Geo {
    /// Half extents.
    Box(Vec3),
    Sphere(f32),
    /// Radius and the half height of its straight part (along y).
    Capsule(f32, f32),
    /// Radius and half height (along y).
    Cylinder(f32, f32),
    /// Triangles, and whether their backs are hit too (a height field's are; a carved member's,
    /// Godot's ConcavePolygonShape3D with `backface_collision` off, aren't).
    Mesh(Arc<TriMesh>, bool),
}

/// Triangles with a BVH of their own (a carved member's voxel faces, a dug tile's height field).
#[derive(Debug)]
pub struct TriMesh {
    pub tris: Vec<[Vec3A; 3]>,
    pub bvh: Bvh,
    pub bounds: Aabb,
}

impl TriMesh {
    pub fn new(tris: Vec<[Vec3A; 3]>) -> TriMesh {
        let boxes: Vec<Aabb> = tris
            .iter()
            .map(|t| {
                let mut b = Aabb::EMPTY;
                for p in t {
                    b.add(*p);
                }
                b.grown()
            })
            .collect();
        let mut bounds = Aabb::EMPTY;
        for b in &boxes {
            bounds.grow(b);
        }
        let bvh = Bvh::build(&boxes, (0..tris.len() as u32).collect());
        TriMesh { tris, bvh, bounds }
    }

    /// Godot's HeightMapShape3D: `width` x `depth` heights, one unit apart, centred on the origin.
    /// Each cell is two triangles, split corner to corner.
    pub fn height_field(width: usize, depth: usize, heights: &[f32]) -> TriMesh {
        let mut tris = Vec::new();
        if width >= 2 && depth >= 2 && heights.len() >= width * depth {
            let ox = (width as f32 - 1.0) * 0.5;
            let oz = (depth as f32 - 1.0) * 0.5;
            let p = |x: usize, z: usize| Vec3A::new(x as f32 - ox, heights[z * width + x], z as f32 - oz);
            for z in 0..depth - 1 {
                for x in 0..width - 1 {
                    let (a, b, c, d) = (p(x, z), p(x + 1, z), p(x, z + 1), p(x + 1, z + 1));
                    tris.push([a, b, d]);
                    tris.push([a, d, c]);
                }
            }
        }
        TriMesh::new(tris)
    }

    fn ray(&self, o: Vec3A, d: Vec3A, best: f32, two_sided: bool) -> Option<(f32, Vec3A)> {
        let inv = RayInv::new(d);
        let mut hit: Option<(f32, Vec3A)> = None;
        let mut best = best;
        self.bvh.walk(o, &inv, &mut best, |i, best| {
            if let Some((t, n)) = ray_triangle(o, d, &self.tris[i as usize]) {
                if t < *best && (two_sided || n.dot(d) < 0.0) {
                    *best = t;
                    hit = Some((t, n));
                }
            }
        });
        hit
    }
}

/// One shape of one body, placed in the world.
#[derive(Clone, Debug)]
pub struct Prim {
    pub geo: Geo,
    /// World from shape, and back.
    pub xf: Affine3A,
    pub inv: Affine3A,
    pub aabb: Aabb,
    /// The body's id (its RID's), layer and kind (what the game says it is: sight.gd's KIND_*).
    pub id: i64,
    pub layer: u32,
    pub kind: i32,
    pub alive: bool,
}

impl Prim {
    pub fn new(geo: Geo, xf: Affine3A, id: i64, layer: u32, kind: i32) -> Prim {
        let local = match &geo {
            Geo::Box(h) => Aabb { min: (-*h).into(), max: (*h).into() },
            Geo::Sphere(r) => Aabb { min: Vec3A::splat(-r), max: Vec3A::splat(*r) },
            Geo::Capsule(r, hh) | Geo::Cylinder(r, hh) => {
                Aabb { min: Vec3A::new(-r, -hh - r, -r), max: Vec3A::new(*r, hh + r, *r) }
            }
            Geo::Mesh(m, _) => m.bounds,
        };
        let mut aabb = Aabb::EMPTY;
        if local.min.x <= local.max.x {
            for i in 0..8 {
                let c = Vec3A::new(
                    if i & 1 == 0 { local.min.x } else { local.max.x },
                    if i & 2 == 0 { local.min.y } else { local.max.y },
                    if i & 4 == 0 { local.min.z } else { local.max.z },
                );
                aabb.add(xf.transform_point3a(c));
            }
        }
        Prim { geo, xf, inv: xf.inverse(), aabb: aabb.grown(), id, layer, kind, alive: true }
    }

    /// Where along the ray (world space, `o + d * t`, t in 0..`best`) it meets this shape, and the
    /// surface normal there (world space).
    #[inline]
    pub fn ray(&self, o: Vec3A, d: Vec3A, best: f32) -> Option<(f32, Vec3A)> {
        // An affine map keeps a point's fraction along a segment, so the test runs in shape space.
        let lo = self.inv.transform_point3a(o);
        let ld = self.inv.transform_vector3a(d);
        let (t, n) = match &self.geo {
            Geo::Box(h) => ray_box(lo, ld, Vec3A::from(*h))?,
            Geo::Sphere(r) => ray_sphere(lo, ld, Vec3A::ZERO, *r)?,
            Geo::Capsule(r, hh) => ray_capsule(lo, ld, *r, *hh)?,
            Geo::Cylinder(r, hh) => ray_cylinder(lo, ld, *r, *hh)?,
            Geo::Mesh(m, two_sided) => m.ray(lo, ld, best, *two_sided)?,
        };
        if t >= best {
            return None;
        }
        // Normals go out by the inverse transpose.
        let m = self.inv.matrix3.transpose();
        Some((t, (m * n).normalize_or_zero()))
    }
}

// --- The shapes ------------------------------------------------------------------------------

/// A convex shape is hit only where the ray goes in, and only if it starts outside (t > 0). The
/// normal is the face nearest the point it went in at (Jolt's BoxShape::GetSurfaceNormal, its
/// ties included).
fn ray_box(o: Vec3A, d: Vec3A, h: Vec3A) -> Option<(f32, Vec3A)> {
    let r = RayInv::new(d);
    let (tmin, _) = slab(o, &r, -h, h)?;
    if tmin <= 0.0 || tmin > 1.0 {
        return None;
    }
    let p = o + d * tmin;
    let off = (p.abs() - h).abs();
    let axis = if off.x < off.y {
        if off.z < off.x {
            2
        } else {
            0
        }
    } else if off.z < off.y {
        2
    } else {
        1
    };
    let mut n = Vec3A::ZERO;
    n[axis] = if p[axis] > 0.0 { 1.0 } else { -1.0 };
    Some((tmin, n))
}

fn ray_sphere(o: Vec3A, d: Vec3A, c: Vec3A, r: f32) -> Option<(f32, Vec3A)> {
    let m = o - c;
    let a = d.dot(d);
    if a <= 0.0 {
        return None;
    }
    let b = m.dot(d);
    let cc = m.dot(m) - r * r;
    if cc <= 0.0 {
        return None; // starts inside
    }
    let disc = b * b - a * cc;
    if disc < 0.0 {
        return None;
    }
    let t = (-b - disc.sqrt()) / a;
    if t <= 0.0 || t > 1.0 {
        return None;
    }
    Some((t, (m + d * t) / r))
}

fn inside_capsule(p: Vec3A, r: f32, hh: f32) -> bool {
    let y = p.y.clamp(-hh, hh);
    (p - Vec3A::new(0.0, y, 0.0)).length_squared() < r * r
}

fn ray_capsule(o: Vec3A, d: Vec3A, r: f32, hh: f32) -> Option<(f32, Vec3A)> {
    if inside_capsule(o, r, hh) {
        return None;
    }
    let mut best: Option<(f32, Vec3A)> = None;
    // The straight part: an infinite cylinder about y, cut at +-hh.
    let a = d.x * d.x + d.z * d.z;
    if a > 1e-12 {
        let b = o.x * d.x + o.z * d.z;
        let c = o.x * o.x + o.z * o.z - r * r;
        let disc = b * b - a * c;
        if disc >= 0.0 {
            let t = (-b - disc.sqrt()) / a;
            if t > 0.0 && t <= 1.0 {
                let y = o.y + d.y * t;
                if y.abs() <= hh {
                    best = Some((t, Vec3A::new(o.x + d.x * t, 0.0, o.z + d.z * t) / r));
                }
            }
        }
    }
    for cy in [hh, -hh] {
        if let Some((t, n)) = ray_sphere(o, d, Vec3A::new(0.0, cy, 0.0), r) {
            if best.map(|b| t < b.0).unwrap_or(true) {
                best = Some((t, n));
            }
        }
    }
    best
}

fn ray_cylinder(o: Vec3A, d: Vec3A, r: f32, hh: f32) -> Option<(f32, Vec3A)> {
    if o.y.abs() < hh && o.x * o.x + o.z * o.z < r * r {
        return None;
    }
    let mut best: Option<(f32, Vec3A)> = None;
    let a = d.x * d.x + d.z * d.z;
    if a > 1e-12 {
        let b = o.x * d.x + o.z * d.z;
        let c = o.x * o.x + o.z * o.z - r * r;
        let disc = b * b - a * c;
        if disc >= 0.0 {
            let t = (-b - disc.sqrt()) / a;
            if t > 0.0 && t <= 1.0 && (o.y + d.y * t).abs() <= hh {
                best = Some((t, Vec3A::new(o.x + d.x * t, 0.0, o.z + d.z * t) / r));
            }
        }
    }
    if d.y.abs() > 1e-12 {
        for cy in [hh, -hh] {
            let t = (cy - o.y) / d.y;
            if t > 0.0 && t <= 1.0 {
                let p = o + d * t;
                if p.x * p.x + p.z * p.z <= r * r && best.map(|b| t < b.0).unwrap_or(true) {
                    best = Some((t, Vec3A::new(0.0, cy.signum(), 0.0)));
                }
            }
        }
    }
    best
}

/// Möller and Trumbore's test ("Fast, minimum storage ray/triangle intersection", 1997), both
/// faces. The normal is the triangle's front, by Godot's winding (clockwise is the front).
fn ray_triangle(o: Vec3A, d: Vec3A, t: &[Vec3A; 3]) -> Option<(f32, Vec3A)> {
    let e1 = t[1] - t[0];
    let e2 = t[2] - t[0];
    let p = d.cross(e2);
    let det = e1.dot(p);
    if det.abs() < 1e-12 {
        return None;
    }
    let inv = 1.0 / det;
    let s = o - t[0];
    let u = s.dot(p) * inv;
    if !(0.0..=1.0).contains(&u) {
        return None;
    }
    let q = s.cross(e1);
    let v = d.dot(q) * inv;
    if v < 0.0 || u + v > 1.0 {
        return None;
    }
    let tt = e2.dot(q) * inv;
    if tt < 0.0 || tt > 1.0 {
        return None;
    }
    Some((tt, e2.cross(e1).normalize_or_zero()))
}

// --- The hierarchy -----------------------------------------------------------------------------

#[derive(Clone, Copy, Debug)]
struct Node {
    bounds: Aabb,
    /// A leaf: its items are `items[first..first + count]`; else its children are `first` and
    /// `first + 1`.
    first: u32,
    count: u32,
}

#[derive(Debug, Default)]
pub struct Bvh {
    nodes: Vec<Node>,
    items: Vec<u32>,
}

const LEAF: usize = 4;

impl Bvh {
    /// Over `items` (indices into `boxes`).
    pub fn build(boxes: &[Aabb], mut items: Vec<u32>) -> Bvh {
        let mut bvh = Bvh { nodes: Vec::with_capacity(items.len() / 2 + 1), items: Vec::new() };
        if items.is_empty() {
            return bvh;
        }
        bvh.nodes.push(Node { bounds: Aabb::EMPTY, first: 0, count: 0 });
        let n = items.len();
        bvh.split(boxes, &mut items, 0, 0, n);
        bvh.items = items;
        bvh
    }

    fn split(&mut self, boxes: &[Aabb], items: &mut [u32], node: usize, start: usize, end: usize) {
        let mut bounds = Aabb::EMPTY;
        let mut centres = Aabb::EMPTY;
        for &i in &items[start..end] {
            let b = &boxes[i as usize];
            bounds.grow(b);
            centres.add(b.centre());
        }
        self.nodes[node].bounds = bounds;
        let count = end - start;
        let ext = centres.max - centres.min;
        if count <= LEAF || ext.max_element() <= 0.0 {
            self.nodes[node].first = start as u32;
            self.nodes[node].count = count as u32;
            return;
        }
        // The split by surface area (binned, along the box's longest spread of centres): the cost
        // of each side its area times its count, the cheapest of BINS - 1 planes.
        let axis = if ext.x >= ext.y && ext.x >= ext.z {
            0
        } else if ext.y >= ext.z {
            1
        } else {
            2
        };
        const BINS: usize = 12;
        let lo = centres.min[axis];
        let scale = BINS as f32 / ext[axis];
        let bin_of = |i: u32| (((boxes[i as usize].centre()[axis] - lo) * scale) as usize).min(BINS - 1);
        let mut bin_box = [Aabb::EMPTY; BINS];
        let mut bin_n = [0usize; BINS];
        for &i in &items[start..end] {
            let b = bin_of(i);
            bin_box[b].grow(&boxes[i as usize]);
            bin_n[b] += 1;
        }
        let mut left_area = [0f32; BINS];
        let mut left_n = [0usize; BINS];
        let mut acc = Aabb::EMPTY;
        let mut n = 0;
        for b in 0..BINS - 1 {
            acc.grow(&bin_box[b]);
            n += bin_n[b];
            left_area[b] = acc.area();
            left_n[b] = n;
        }
        let mut best_cost = f32::INFINITY;
        let mut best_plane = BINS / 2 - 1;
        let mut acc = Aabb::EMPTY;
        let mut n = 0;
        for b in (1..BINS).rev() {
            acc.grow(&bin_box[b]);
            n += bin_n[b];
            let cost = left_area[b - 1] * left_n[b - 1] as f32 + acc.area() * n as f32;
            if left_n[b - 1] > 0 && n > 0 && cost < best_cost {
                best_cost = cost;
                best_plane = b - 1;
            }
        }
        let mut mid = start;
        for k in start..end {
            if bin_of(items[k]) <= best_plane {
                items.swap(k, mid);
                mid += 1;
            }
        }
        if mid == start || mid == end {
            // All in one bin: halve by order of centre (ties by index, so the same boxes make the
            // same tree).
            mid = start + count / 2;
            items[start..end].select_nth_unstable_by(count / 2, |a, b| {
                let ca = boxes[*a as usize].centre()[axis];
                let cb = boxes[*b as usize].centre()[axis];
                ca.total_cmp(&cb).then(a.cmp(b))
            });
        }
        let left = self.nodes.len();
        self.nodes.push(Node { bounds: Aabb::EMPTY, first: 0, count: 0 });
        self.nodes.push(Node { bounds: Aabb::EMPTY, first: 0, count: 0 });
        self.nodes[node].first = left as u32;
        self.nodes[node].count = 0;
        self.split(boxes, items, left, start, mid);
        self.split(boxes, items, left + 1, mid, end);
    }

    /// Every item whose leaf the ray reaches before `best`, nearer boxes first; `visit` may
    /// shorten `best`.
    pub fn walk(&self, o: Vec3A, inv: &RayInv, best: &mut f32, mut visit: impl FnMut(u32, &mut f32)) {
        if self.nodes.is_empty() {
            return;
        }
        let mut stack: [u32; 64] = [0; 64];
        let mut sp = 1usize;
        stack[0] = 0;
        while sp > 0 {
            sp -= 1;
            let node = &self.nodes[stack[sp] as usize];
            if node.bounds.ray(o, inv, *best).is_none() {
                continue;
            }
            if node.count > 0 {
                for &i in &self.items[node.first as usize..(node.first + node.count) as usize] {
                    visit(i, best);
                }
                continue;
            }
            let (a, b) = (node.first, node.first + 1);
            let ta = self.nodes[a as usize].bounds.ray(o, inv, *best);
            let tb = self.nodes[b as usize].bounds.ray(o, inv, *best);
            // Far child pushed first, so the near one is looked at first.
            match (ta, tb) {
                (Some(x), Some(y)) => {
                    let (near, far) = if x <= y { (a, b) } else { (b, a) };
                    if sp + 2 <= stack.len() {
                        stack[sp] = far;
                        stack[sp + 1] = near;
                        sp += 2;
                    }
                }
                (Some(_), None) => {
                    stack[sp] = a;
                    sp += 1;
                }
                (None, Some(_)) => {
                    stack[sp] = b;
                    sp += 1;
                }
                (None, None) => {}
            }
        }
    }
}

// --- The scene ----------------------------------------------------------------------------------

/// What a ray met: the fraction along it (1.0 for nothing), the body's id (0 for nothing), the
/// surface normal and the body's kind.
#[derive(Clone, Copy, Debug)]
pub struct Hit {
    pub t: f32,
    pub id: i64,
    pub normal: Vec3,
    pub kind: i32,
}

impl Hit {
    pub const NONE: Hit = Hit { t: 1.0, id: 0, normal: Vec3::ZERO, kind: 0 };
}

#[derive(Clone, Debug, Default)]
pub struct Scene {
    pub prims: Vec<Prim>,
    /// Prims in the tree (standing things), and those beside it (moving things, and what changed
    /// since it was built), tested one by one.
    pub bvh: Arc<Bvh>,
    pub loose: Vec<u32>,
    pub dead: usize,
}

impl Clone for Bvh {
    fn clone(&self) -> Bvh {
        Bvh { nodes: self.nodes.clone(), items: self.items.clone() }
    }
}

impl Scene {
    /// The tree built again from every live prim that doesn't move (`moving(prim)`): the dead
    /// ones dropped. Returns the map from old prim index to new (u32::MAX for dropped).
    pub fn rebuild(&mut self, moving: impl Fn(&Prim) -> bool) -> Vec<u32> {
        let mut remap = vec![u32::MAX; self.prims.len()];
        let mut prims = Vec::with_capacity(self.prims.len() - self.dead.min(self.prims.len()));
        for (i, p) in self.prims.drain(..).enumerate() {
            if p.alive {
                remap[i] = prims.len() as u32;
                prims.push(p);
            }
        }
        self.prims = prims;
        self.dead = 0;
        let mut fixed = Vec::new();
        self.loose.clear();
        for (i, p) in self.prims.iter().enumerate() {
            if moving(p) {
                self.loose.push(i as u32);
            } else {
                fixed.push(i as u32);
            }
        }
        let boxes: Vec<Aabb> = self.prims.iter().map(|p| p.aabb).collect();
        self.bvh = Arc::new(Bvh::build(&boxes, fixed));
        remap
    }

    /// The nearest thing on `mask` the segment `from`..`to` meets, the bodies in `exclude` aside.
    pub fn cast(&self, from: Vec3, to: Vec3, mask: u32, exclude: &[i64]) -> Hit {
        self.cast_within(from, to, mask, exclude, 1.0, false)
    }

    /// Anything on `mask` along the first `upto` of the segment (0..1)? Stops at the first found.
    pub fn any(&self, from: Vec3, to: Vec3, mask: u32, exclude: &[i64], upto: f32) -> bool {
        self.cast_within(from, to, mask, exclude, upto, true).id != 0
    }

    fn cast_within(&self, from: Vec3, to: Vec3, mask: u32, exclude: &[i64], upto: f32, first: bool) -> Hit {
        let o = Vec3A::from(from);
        let d = Vec3A::from(to - from);
        let inv = RayInv::new(d);
        // Just past `upto`, so a hit at it counts (as a closest hit at it would).
        let mut best = if upto >= 1.0 { 1.0f32 } else { upto.max(0.0) * (1.0 + 1e-6) + 1e-9 };
        let mut hit = Hit::NONE;
        let mut done = false;
        let mut test = |i: u32, best: &mut f32| {
            if done {
                return;
            }
            let p = &self.prims[i as usize];
            if !p.alive || p.layer & mask == 0 || exclude.contains(&p.id) {
                return;
            }
            if p.aabb.ray(o, &inv, *best).is_none() {
                return;
            }
            if let Some((t, n)) = p.ray(o, d, *best) {
                *best = t;
                hit = Hit { t, id: p.id, normal: n.into(), kind: p.kind };
                if first {
                    done = true;
                    *best = -1.0;
                }
            }
        };
        self.bvh.walk(o, &inv, &mut best, &mut test);
        for &i in &self.loose {
            test(i, &mut best);
        }
        hit
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn scene(prims: Vec<Prim>) -> Scene {
        let mut s = Scene { prims, ..Default::default() };
        s.rebuild(|_| false);
        s
    }

    #[test]
    fn box_hit_and_inside() {
        let s = scene(vec![Prim::new(Geo::Box(Vec3::splat(0.5)), Affine3A::from_translation(Vec3::new(0.0, 0.0, 5.0)), 7, 1, 0)]);
        let h = s.cast(Vec3::ZERO, Vec3::new(0.0, 0.0, 10.0), 1, &[]);
        assert_eq!(h.id, 7);
        assert!((h.t - 0.45).abs() < 1e-5);
        assert!((h.normal - Vec3::new(0.0, 0.0, -1.0)).length() < 1e-5);
        // From inside: not hit (Jolt's hit_from_inside false).
        assert_eq!(s.cast(Vec3::new(0.0, 0.0, 5.0), Vec3::new(0.0, 0.0, 10.0), 1, &[]).id, 0);
        // Excluded, or off the mask.
        assert_eq!(s.cast(Vec3::ZERO, Vec3::new(0.0, 0.0, 10.0), 1, &[7]).id, 0);
        assert_eq!(s.cast(Vec3::ZERO, Vec3::new(0.0, 0.0, 10.0), 2, &[]).id, 0);
        // Short of it.
        assert_eq!(s.cast(Vec3::ZERO, Vec3::new(0.0, 0.0, 4.0), 1, &[]).id, 0);
    }

    #[test]
    fn many_boxes_nearest() {
        let mut prims = Vec::new();
        for i in 0..1000 {
            let x = (i % 10) as f32;
            let z = (i / 10) as f32;
            prims.push(Prim::new(Geo::Box(Vec3::splat(0.2)), Affine3A::from_translation(Vec3::new(x, 0.0, z)), i + 1, 1, 0));
        }
        let s = scene(prims);
        let h = s.cast(Vec3::new(3.0, 0.0, -5.0), Vec3::new(3.0, 0.0, 200.0), 1, &[]);
        assert_eq!(h.id, 4); // x=3, z=0
        let h = s.cast(Vec3::new(-5.0, 0.0, 7.0), Vec3::new(50.0, 0.0, 7.0), 1, &[71]);
        assert_eq!(h.id, 72);
    }

    #[test]
    fn capsule_and_rotated_box() {
        let rot = Affine3A::from_rotation_y(0.7) * Affine3A::from_translation(Vec3::new(0.0, 1.0, 0.0));
        let s = scene(vec![
            Prim::new(Geo::Capsule(0.3, 0.6), Affine3A::from_translation(Vec3::new(0.0, 1.0, 3.0)), 1, 1, 0),
            Prim::new(Geo::Box(Vec3::new(1.0, 0.1, 0.1)), rot, 2, 1, 0),
        ]);
        let h = s.cast(Vec3::new(0.0, 1.0, 10.0), Vec3::new(0.0, 1.0, 3.0), 1, &[]);
        assert_eq!(h.id, 1);
        assert!((h.t * 7.0 - 6.7).abs() < 1e-4);
        // The cap.
        let h = s.cast(Vec3::new(0.0, 5.0, 3.0), Vec3::new(0.0, 0.0, 3.0), 1, &[]);
        assert_eq!(h.id, 1);
        assert!(((5.0 - h.t * 5.0) - 1.9).abs() < 1e-4);
        let h = s.cast(Vec3::new(0.0, 1.0, -3.0), Vec3::new(0.0, 1.0, 0.0), 1, &[]);
        assert_eq!(h.id, 2);
    }

    #[test]
    fn height_field_both_faces() {
        let m = Arc::new(TriMesh::height_field(3, 3, &[0.0; 9]));
        let s = scene(vec![Prim::new(Geo::Mesh(m, true), Affine3A::IDENTITY, 3, 1, 0)]);
        let down = s.cast(Vec3::new(0.3, 1.0, 0.2), Vec3::new(0.3, -1.0, 0.2), 1, &[]);
        assert_eq!(down.id, 3);
        assert!((down.t - 0.5).abs() < 1e-5);
        let up = s.cast(Vec3::new(0.3, -1.0, 0.2), Vec3::new(0.3, 1.0, 0.2), 1, &[]);
        assert_eq!(up.id, 3);
    }

    #[test]
    fn along_a_face_and_first_found() {
        // A line laid in a box's face plane counts as touching it (Jolt's RayAABox: a parallel axis
        // inclusive of its faces).
        let s = scene(vec![Prim::new(Geo::Box(Vec3::new(1.0, 0.5, 0.5)), Affine3A::from_translation(Vec3::new(0.0, 0.0, 3.0)), 1, 1, 0)]);
        let h = s.cast(Vec3::new(0.0, 0.5, -1.0), Vec3::new(0.0, 0.5, 9.0), 1, &[]);
        assert_eq!(h.id, 1);
        // On the top edge: the tie goes to y (Jolt's lowest component of the faces' offsets).
        assert!((h.normal - Vec3::new(0.0, 1.0, 0.0)).length() < 1e-5);
        assert_eq!(s.cast(Vec3::new(0.0, 0.5001, -1.0), Vec3::new(0.0, 0.5001, 9.0), 1, &[]).id, 0);
        // `any`: only short of `upto`.
        assert!(s.any(Vec3::ZERO, Vec3::new(0.0, 0.0, 10.0), 1, &[], 0.26));
        assert!(!s.any(Vec3::ZERO, Vec3::new(0.0, 0.0, 10.0), 1, &[], 0.24));
    }

    #[test]
    fn one_sided_mesh() {
        // Godot's winding: clockwise is the front. A floor triangle facing up, seen from above.
        let tri = [Vec3A::new(0.0, 0.0, 0.0), Vec3A::new(1.0, 0.0, 0.0), Vec3A::new(0.0, 0.0, 1.0)];
        let m = Arc::new(TriMesh::new(vec![tri]));
        let s = scene(vec![Prim::new(Geo::Mesh(m, false), Affine3A::IDENTITY, 5, 1, 0)]);
        let down = s.cast(Vec3::new(0.2, 1.0, 0.2), Vec3::new(0.2, -1.0, 0.2), 1, &[]);
        assert_eq!(down.id, 5);
        assert!(down.normal.y > 0.99);
        assert_eq!(s.cast(Vec3::new(0.2, -1.0, 0.2), Vec3::new(0.2, 1.0, 0.2), 1, &[]).id, 0);
    }
}
