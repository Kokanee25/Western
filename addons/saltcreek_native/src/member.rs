//! `VoxelMember`: one building member's voxel volume (docs/DESTRUCTION_BRIEF.md step 2). Made when
//! the member is first hit. Carving happens at once, on the main thread, in the order hits come
//! (deterministic, and microseconds); meshing (the mesh and the collision faces) goes to the
//! worker threads and is collected when done. The volume is shared with a running job by `Arc`:
//! a carve while a job reads it copies it first, so neither ever waits for the other.

use crate::carve::Carve;
use crate::mesh::{mesh, MemberMesh, Surface};
use crate::pool;
use crate::volume::{material, pack, Volume};
use glam::Vec3;
use godot::prelude::*;
use std::sync::{Arc, Mutex};

#[derive(GodotClass)]
#[class(base = RefCounted, init)]
pub struct VoxelMember {
    base: Base<RefCounted>,
    vol: Option<Arc<Volume>>,
    job: Option<Arc<Mutex<Option<MemberMesh>>>>,
    ready: Option<MemberMesh>,
    /// Carved since the running job started: mesh again when it's done.
    dirty: bool,
    chunks: Vec<(Vec3, u32)>,
    total: usize,
}

fn v3(v: Vector3) -> Vec3 {
    Vec3::new(v.x, v.y, v.z)
}

fn gv3(v: Vec3) -> Vector3 {
    Vector3::new(v.x, v.y, v.z)
}

fn surface_arrays(s: &Surface) -> VarArray {
    let mut a = VarArray::new();
    // Mesh.ARRAY_MAX slots, the unused ones null.
    for _ in 0..13 {
        a.push(&Variant::nil());
    }
    if s.positions.is_empty() {
        return VarArray::new();
    }
    let pos: PackedVector3Array = s.positions.iter().map(|p| gv3(*p)).collect();
    let nrm: PackedVector3Array = s.normals.iter().map(|p| gv3(*p)).collect();
    let uv: PackedVector2Array = s.uv.iter().map(|p| Vector2::new(p.x, p.y)).collect();
    let uv2: PackedVector2Array = s.uv2.iter().map(|p| Vector2::new(p.x, p.y)).collect();
    let idx: PackedInt32Array = s.indices.iter().copied().collect();
    a.set(0, &pos.to_variant());
    a.set(1, &nrm.to_variant());
    a.set(4, &uv.to_variant());
    a.set(5, &uv2.to_variant());
    a.set(12, &idx.to_variant());
    a
}

#[godot_api]
impl VoxelMember {
    /// Voxelise a member of `size` (metres, centred on its origin) at about `per_m` cells a metre,
    /// at most `max_voxels`; `stone` for stone, else wood. Returns the voxel count.
    #[func]
    fn setup(&mut self, size: Vector3, per_m: f32, max_voxels: i64, stone: bool) -> i64 {
        let mat = if stone { material::STONE } else { material::WOOD };
        let v = Volume::solid_box(v3(size), per_m, max_voxels.max(1) as usize, pack(0, 0, 0, mat));
        self.total = v.total();
        self.vol = Some(Arc::new(v));
        self.total as i64
    }

    #[func]
    fn is_setup(&self) -> bool {
        self.vol.is_some()
    }

    /// The solid stretches along a ray from `from` (member space) in direction `dir`, up to
    /// `max_t` metres: [enter, exit, enter, exit, ...] distances from `from`.
    #[func]
    fn runs(&self, from: Vector3, dir: Vector3, max_t: f32) -> PackedFloat32Array {
        let mut out = PackedFloat32Array::new();
        if let Some(v) = &self.vol {
            let d = v3(dir).normalize_or_zero();
            if d == Vec3::ZERO {
                return out;
            }
            for (a, b) in v.runs(v3(from), d, max_t) {
                out.push(a);
                out.push(b);
            }
        }
        out
    }

    /// Carve a hit (member space): the channel from `entry` to `exit` of `radius`, and `spall_m3`
    /// of wood torn out round it, reaching `grain_split` times as far along `grain_axis` (-1:
    /// none). Returns the voxels removed; `chunks()` has the debris.
    #[allow(clippy::too_many_arguments)]
    #[func]
    fn carve(&mut self, entry: Vector3, exit: Vector3, radius: f32, spall_m3: f32, seed: i64, ragged: f32, flare: f32, grain_axis: i64, grain_split: f32, island_max: i64, max_chunks: i64) -> i64 {
        let Some(arc) = self.vol.as_mut() else {
            return 0;
        };
        let vol = Arc::make_mut(arc);
        let r = vol.carve(&Carve {
            entry: v3(entry),
            exit: v3(exit),
            radius,
            spall_m3,
            ragged,
            flare,
            grain: if (0..3).contains(&grain_axis) { Some(grain_axis as usize) } else { None },
            grain_split,
            seed: seed as u64,
            island_max: island_max.max(0) as usize,
            max_chunks: max_chunks.max(0) as usize,
        });
        self.chunks = r.chunks;
        if r.removed > 0 && self.job.is_some() {
            self.dirty = true;
        }
        r.removed as i64
    }

    /// The last carve's debris: centre (member space) and how many voxels in each lump (w).
    #[func]
    fn chunks(&self) -> PackedVector4Array {
        self.chunks.iter().map(|(c, n)| Vector4::new(c.x, c.y, c.z, *n as f32)).collect()
    }

    /// What's left of the section along `axis` (0 x, 1 y, 2 z): Vector2(share left at the
    /// weakest place, where that is along the axis in member space), holes within `window`
    /// metres of each other along it counted together.
    #[func]
    fn section(&self, axis: i64, window: f32) -> Vector2 {
        let Some(v) = &self.vol else {
            return Vector2::new(1.0, 0.0);
        };
        let a = axis.clamp(0, 2) as usize;
        let cells = (window / v.cell[a]).round() as i32;
        let (keep, at) = v.section(a, cells.max(1));
        Vector2::new(keep, at)
    }

    #[func]
    fn solid(&self) -> i64 {
        self.vol.as_ref().map(|v| v.solid_count as i64).unwrap_or(0)
    }

    #[func]
    fn total(&self) -> i64 {
        self.total as i64
    }

    #[func]
    fn cell_size(&self) -> Vector3 {
        self.vol.as_ref().map(|v| gv3(v.cell)).unwrap_or(Vector3::ZERO)
    }

    #[func]
    fn cell_volume(&self) -> f32 {
        self.vol.as_ref().map(|v| v.cell_volume()).unwrap_or(0.0)
    }

    /// Mesh the volume on a worker. If a job is already running, it's meshed again once that one
    /// is done (`poll()` starts it). Returns true if a job was started now.
    #[func]
    fn start_mesh(&mut self) -> bool {
        if self.job.is_some() {
            self.dirty = true;
            return false;
        }
        let Some(v) = &self.vol else {
            return false;
        };
        let snapshot = Arc::clone(v);
        let slot: Arc<Mutex<Option<MemberMesh>>> = Arc::new(Mutex::new(None));
        let out = Arc::clone(&slot);
        pool::submit(move || {
            let m = mesh(&snapshot);
            *out.lock().unwrap() = Some(m);
        });
        self.job = Some(slot);
        self.dirty = false;
        true
    }

    /// Check on the job (never blocks). True when a finished mesh is waiting in `take_mesh()`.
    #[func]
    fn poll(&mut self) -> bool {
        if let Some(job) = &self.job {
            let done = job.lock().unwrap().take();
            if let Some(m) = done {
                self.job = None;
                self.ready = Some(m);
                if self.dirty {
                    // Carved again meanwhile: this mesh is shown now and a fresh one started.
                    self.start_mesh();
                }
            }
        }
        self.ready.is_some()
    }

    /// True while a job is running or waiting to be collected.
    #[func]
    fn busy(&self) -> bool {
        self.job.is_some() || self.dirty
    }

    /// Block until the running job is done (tests and tools; never in the frame loop).
    #[func]
    fn wait(&mut self) {
        while self.job.is_some() {
            if self.poll() && self.job.is_none() {
                break;
            }
            std::thread::sleep(std::time::Duration::from_micros(200));
        }
        self.poll();
    }

    /// The finished mesh: [outer surface arrays, inner surface arrays, collision faces, worker
    /// milliseconds]. A surface with no faces is an empty array. Empty if nothing's ready.
    #[func]
    fn take_mesh(&mut self) -> VarArray {
        let mut out = VarArray::new();
        if let Some(m) = self.ready.take() {
            out.push(&surface_arrays(&m.outer).to_variant());
            out.push(&surface_arrays(&m.inner).to_variant());
            let faces: PackedVector3Array = m.collision.iter().map(|p| gv3(*p)).collect();
            out.push(&faces.to_variant());
            out.push(&m.millis.to_variant());
        }
        out
    }

    /// Worker threads the plugin runs (F3, the bench).
    #[func]
    fn workers(&self) -> i64 {
        pool::threads() as i64
    }
}
