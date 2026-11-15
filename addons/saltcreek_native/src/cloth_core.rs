//! Godot's handle on the cloth (cloth.rs): `ClothCore`, driven by `SolverCloth`
//! (src/bodies/solver_cloth.gd) and the tests (tests/test_cloth_core.gd). One per garment; the main
//! thread steps it (a garment is a few hundred points: ~0.25 ms a tick at Sean's).

use crate::cloth::{Cloth, Tuning, V3};
use godot::prelude::*;

#[derive(GodotClass)]
#[class(base = RefCounted, init)]
pub struct ClothCore {
    base: Base<RefCounted>,
    c: Option<Cloth>,
    t: Tuning,
    millis: f64,
}

fn v3(v: Vector3) -> V3 {
    [v.x, v.y, v.z]
}
fn gv(v: V3) -> Vector3 {
    Vector3::new(v[0], v[1], v[2])
}

#[godot_api]
impl ClothCore {
    /// One of the numbers (cloth.rs Tuning's names); false if it isn't one. Applies at once, to a
    /// cloth already built too (but `bend_mode` and the rest shape are read as it steps).
    #[func]
    fn tune(&mut self, name: GString, value: f64) -> bool {
        let t = &mut self.t;
        let v = value as f32;
        match name.to_string().as_str() {
            "stretch_compliance" => t.stretch_compliance = v,
            "bend_stiffness" => t.bend_stiffness = v,
            "bend_mode" => t.bend_mode = value as i32,
            "max_strain" => t.max_strain = v,
            "min_strain" => t.min_strain = v,
            "damping" => t.damping = v,
            "gravity_y" => t.gravity[1] = v,
            "floor_on" => t.floor_on = value != 0.0,
            "floor_y" => t.floor_y = v,
            "thickness" => t.thickness = v,
            "friction_static" => t.friction_static = v,
            "friction_kinetic" => t.friction_kinetic = v,
            "substeps" => t.substeps = value.max(1.0) as u32,
            _ => return false,
        }
        if let Some(c) = self.c.as_mut() {
            c.t = self.t.clone();
        }
        true
    }

    /// Made from `points` (its rest shape) and `triangles`, `density` kg/m². False if an index
    /// is out of range.
    #[func]
    fn build(&mut self, points: PackedVector3Array, triangles: PackedInt32Array, density: f64) -> bool {
        let pts: Vec<V3> = points.as_slice().iter().map(|p| v3(*p)).collect();
        if triangles.as_slice().iter().any(|&i| i < 0) {
            self.c = None;
            return false;
        }
        let tris: Vec<u32> = triangles.as_slice().iter().map(|&i| i as u32).collect();
        self.c = Cloth::build(&pts, &tris, density as f32, self.t.clone());
        self.c.is_some()
    }

    /// A seeded jitter of the free points' start, `amount` m at most each way.
    #[func]
    fn jitter(&mut self, seed: i64, amount: f64) {
        if let Some(c) = self.c.as_mut() {
            c.jitter(seed as u64, amount as f32);
        }
    }

    /// These points pinned (held where `move_pins` puts them) or let go.
    #[func]
    fn pin(&mut self, points: PackedInt32Array, on: bool) {
        if let Some(c) = self.c.as_mut() {
            for &i in points.as_slice() {
                if i >= 0 {
                    c.pin(i as usize, on);
                }
            }
        }
    }

    /// Pinned points' places at the end of the next step: `at[k]` for `points[k]`.
    #[func]
    fn move_pins(&mut self, points: PackedInt32Array, at: PackedVector3Array) {
        if let Some(c) = self.c.as_mut() {
            let at = at.as_slice();
            for (k, &i) in points.as_slice().iter().enumerate() {
                if i >= 0 && k < at.len() {
                    c.move_pin(i as usize, v3(at[k]));
                }
            }
        }
    }

    #[func]
    fn is_pinned(&self, i: i64) -> bool {
        self.c.as_ref().is_some_and(|c| i >= 0 && (i as usize) < c.len() && c.pinned[i as usize])
    }

    /// Every free point's velocity raised by `dv` (a throw).
    #[func]
    fn add_velocity(&mut self, dv: Vector3) {
        if let Some(c) = self.c.as_mut() {
            c.add_velocity(v3(dv));
        }
    }

    /// One tick of `dt` s.
    #[func]
    fn step(&mut self, dt: f64) {
        let t0 = std::time::Instant::now();
        if let Some(c) = self.c.as_mut() {
            c.step(dt as f32);
        }
        self.millis = t0.elapsed().as_secs_f64() * 1000.0;
    }

    /// Its points now.
    #[func]
    fn points(&self) -> PackedVector3Array {
        self.c.as_ref().map_or_else(PackedVector3Array::new, |c| c.x.iter().map(|p| gv(*p)).collect())
    }

    /// Its points' normals now (area-weighted).
    #[func]
    fn normals(&self) -> PackedVector3Array {
        self.c.as_ref().map_or_else(PackedVector3Array::new, |c| c.normals().iter().map(|p| gv(*p)).collect())
    }

    #[func]
    fn point_count(&self) -> i64 {
        self.c.as_ref().map_or(0, |c| c.len() as i64)
    }
    #[func]
    fn edge_count(&self) -> i64 {
        self.c.as_ref().map_or(0, |c| c.edges.len() as i64)
    }
    #[func]
    fn bend_count(&self) -> i64 {
        self.c.as_ref().map_or(0, |c| c.bends_flat.len() as i64)
    }
    /// The longest edge over its rest length.
    #[func]
    fn max_strain(&self) -> f64 {
        self.c.as_ref().map_or(1.0, |c| c.max_strain_now() as f64)
    }
    #[func]
    fn lowest_y(&self) -> f64 {
        self.c.as_ref().map_or(0.0, |c| c.lowest_y() as f64)
    }
    #[func]
    fn mean_speed(&self) -> f64 {
        self.c.as_ref().map_or(0.0, |c| c.mean_speed() as f64)
    }
    /// Σ|Kᵢxᵢ| over the inner edges: 0 for a flat sheet in any pose.
    #[func]
    fn bend_measure(&self) -> f64 {
        self.c.as_ref().map_or(0.0, |c| c.bend_measure() as f64)
    }
    /// The last step's time (ms, this machine).
    #[func]
    fn millis(&self) -> f64 {
        self.millis
    }
}
