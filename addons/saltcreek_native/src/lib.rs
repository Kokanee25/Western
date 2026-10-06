//! Salt Creek's native plugin (docs/DESTRUCTION_BRIEF.md). Step 1, the foundation: the extension
//! loads in Godot 4.7.2, and `NativeBench` proves the round trip the later steps live on: a job
//! runs on a worker thread with no Godot objects in it, and the main thread collects its result
//! as packed arrays (here, a voxel sphere's visible cube faces as mesh arrays).
//! Step 2, members that take damage: `VoxelMember` (member.rs) over the brick volume
//! (volume.rs, from Pixel-factory), carving (carve.rs), greedy meshing (mesh.rs) on the worker
//! pool (pool.rs).

use godot::classes::Node;
use godot::prelude::*;
use std::sync::{Arc, Mutex};
use std::thread::JoinHandle;

pub mod carve;
pub mod member;
pub mod mesh;
pub mod pool;
pub mod smoke;
pub mod volume;
pub mod voxel;

struct SaltCreekNative;

#[gdextension]
unsafe impl ExtensionLibrary for SaltCreekNative {}

/// A job's output: positions, normals and colours of every visible cube face, as triangles.
pub struct MeshJob {
    pub positions: Vec<[f32; 3]>,
    pub normals: Vec<[f32; 3]>,
    pub colours: Vec<[f32; 4]>,
    pub voxels: usize,
    pub millis: f32,
}

#[derive(GodotClass)]
#[class(base = Node)]
pub struct NativeBench {
    base: Base<Node>,
    worker: Option<JoinHandle<()>>,
    result: Arc<Mutex<Option<MeshJob>>>,
}

#[godot_api]
impl INode for NativeBench {
    fn init(base: Base<Node>) -> Self {
        NativeBench { base, worker: None, result: Arc::new(Mutex::new(None)) }
    }
}

#[godot_api]
impl NativeBench {
    /// The plugin's version, so F3 and the tests can show it loaded.
    #[func]
    fn version(&self) -> GString {
        GString::from(concat!("saltcreek_native ", env!("CARGO_PKG_VERSION")))
    }

    /// How many threads the machine offers the plugin.
    #[func]
    fn threads(&self) -> i64 {
        std::thread::available_parallelism().map(|n| n.get() as i64).unwrap_or(1)
    }

    /// Start a job on a worker thread: voxelise a sphere of `radius` metres at `per_m` cubes a
    /// metre, carve a bite of `bite` metres out of its side, and mesh the visible faces.
    /// Returns false if a job is already running.
    #[func]
    fn start_sphere(&mut self, radius: f32, per_m: f32, bite: f32) -> bool {
        if self.worker.is_some() {
            return false;
        }
        let slot = Arc::clone(&self.result);
        *slot.lock().unwrap() = None;
        self.worker = Some(std::thread::spawn(move || {
            let t0 = std::time::Instant::now();
            let mut vol = voxel::Volume::sphere(radius, per_m);
            if bite > 0.0 {
                vol.carve_sphere([radius, 0.0, 0.0], bite);
            }
            let (positions, normals, colours) = vol.mesh_faces();
            let job = MeshJob { positions, normals, colours, voxels: vol.solid, millis: t0.elapsed().as_secs_f32() * 1000.0 };
            *slot.lock().unwrap() = Some(job);
        }));
        true
    }

    /// True once the job has finished (poll from _process; never blocks).
    #[func]
    fn done(&mut self) -> bool {
        let finished = self.worker.as_ref().map(|w| w.is_finished()).unwrap_or(false);
        if finished {
            if let Some(w) = self.worker.take() {
                let _ = w.join();
            }
        }
        self.worker.is_none() && self.result.lock().unwrap().is_some()
    }

    /// Block until the job is done (for tests and tools, not the frame loop).
    #[func]
    fn wait(&mut self) {
        if let Some(w) = self.worker.take() {
            let _ = w.join();
        }
    }

    /// The finished job's mesh arrays, in Mesh.ARRAY_* order (vertex, normal, colour), or an
    /// empty array if nothing has finished.
    #[func]
    fn mesh_arrays(&self) -> VarArray {
        let guard = self.result.lock().unwrap();
        let mut out = VarArray::new();
        if let Some(job) = guard.as_ref() {
            let pos: PackedVector3Array = job.positions.iter().map(|p| Vector3::new(p[0], p[1], p[2])).collect();
            let nrm: PackedVector3Array = job.normals.iter().map(|p| Vector3::new(p[0], p[1], p[2])).collect();
            let col: PackedColorArray = job.colours.iter().map(|c| Color::from_rgba(c[0], c[1], c[2], c[3])).collect();
            out.push(&pos.to_variant());
            out.push(&nrm.to_variant());
            out.push(&col.to_variant());
        }
        out
    }

    /// Solid voxels in the finished job, 0 if none.
    #[func]
    fn voxels(&self) -> i64 {
        self.result.lock().unwrap().as_ref().map(|j| j.voxels as i64).unwrap_or(0)
    }

    /// Milliseconds the worker took.
    #[func]
    fn millis(&self) -> f32 {
        self.result.lock().unwrap().as_ref().map(|j| j.millis).unwrap_or(0.0)
    }
}
