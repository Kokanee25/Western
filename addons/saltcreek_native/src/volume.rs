//! Per-object voxel volumes: a grid of 8x8x8 bricks, each voxel a packed colour and material.
//! Ported from Kokanee25/Pixel-factory's src/volume.rs (bricks, the pool, the voxel packing and its
//! DDA), with one change for Salt Creek's members: a cell's size can differ per axis. A member is a
//! box of any size (a board 22 mm thick, a stud 2.4 m long), and its volume is cut into a whole
//! number of cells along each side, as near the wanted density as that allows, so the uncarved
//! volume meshes to exactly the member's box and textures land as they did before it was hit.

use glam::{IVec3, Vec3};

pub const BRICK: usize = 8;
pub const BRICK3: usize = BRICK * BRICK * BRICK;

/// A voxel is `r<<24 | g<<16 | b<<8 | material`; material 0 is empty air.
pub type Voxel = u32;

pub mod material {
    pub const EMPTY: u8 = 0;
    pub const WOOD: u8 = 7;
    pub const STONE: u8 = 11;
}

#[inline]
pub fn pack(r: u8, g: u8, b: u8, mat: u8) -> Voxel {
    ((r as u32) << 24) | ((g as u32) << 16) | ((b as u32) << 8) | mat as u32
}
#[inline]
pub fn mat_of(v: Voxel) -> u8 {
    (v & 255) as u8
}

/// Torn: a voxel left standing at the edge of a carve, its weathered face splintered off (drawn as
/// fresh wood). Kept in the colour bits (the lowest bit of blue).
pub const TORN: Voxel = 1 << 8;

#[inline]
pub fn torn(v: Voxel) -> bool {
    v & TORN != 0
}

#[derive(Clone)]
pub struct Brick {
    pub v: [Voxel; BRICK3],
}

impl Brick {
    #[inline]
    pub fn idx(x: usize, y: usize, z: usize) -> usize {
        (z * BRICK + y) * BRICK + x
    }
}

#[derive(Clone)]
pub struct Volume {
    /// Size in voxels.
    pub dims: IVec3,
    /// Size in bricks.
    pub bdims: IVec3,
    /// Index + 1 into `pool`; 0 = an empty brick.
    pub bricks: Vec<u32>,
    pub pool: Vec<Brick>,
    /// Size of one cell along each axis, metres.
    pub cell: Vec3,
    /// Object-space position of the volume's min corner.
    pub origin: Vec3,
    pub solid_count: usize,
}

impl Volume {
    pub fn new(origin: Vec3, dims: IVec3, cell: Vec3) -> Volume {
        let bdims = (dims + IVec3::splat(BRICK as i32 - 1)) / BRICK as i32;
        Volume {
            dims,
            bdims,
            bricks: vec![0; (bdims.x * bdims.y * bdims.z) as usize],
            pool: Vec::new(),
            cell,
            origin,
            solid_count: 0,
        }
    }

    /// A solid box of `size` metres centred on the origin (a member in its own space), about
    /// `per_m` cells a metre along each side but a whole number of them, never more than
    /// `max_voxels` in all (a long sill is cut coarser), every voxel `value`.
    pub fn solid_box(size: Vec3, per_m: f32, max_voxels: usize, value: Voxel) -> Volume {
        let count = |per: f32| -> IVec3 {
            IVec3::new(
                ((size.x * per).round() as i32).max(1),
                ((size.y * per).round() as i32).max(1),
                ((size.z * per).round() as i32).max(1),
            )
        };
        let mut per = per_m.max(1.0);
        let mut dims = count(per);
        let mut guard = 0;
        while (dims.x as usize * dims.y as usize * dims.z as usize) > max_voxels.max(1) && guard < 32 {
            let n = dims.x as f32 * dims.y as f32 * dims.z as f32;
            per *= (max_voxels as f32 / n).cbrt().min(0.97);
            dims = count(per);
            guard += 1;
        }
        let mut v = Volume::new(-size * 0.5, dims, size / dims.as_vec3());
        v.fill(value);
        v
    }

    /// Every voxel `value` (the volume solid), brick by brick.
    pub fn fill(&mut self, value: Voxel) {
        self.pool.clear();
        for bz in 0..self.bdims.z {
            for by in 0..self.bdims.y {
                for bx in 0..self.bdims.x {
                    let b = IVec3::new(bx, by, bz);
                    let mut brick = Brick { v: [0; BRICK3] };
                    for z in 0..BRICK {
                        for y in 0..BRICK {
                            for x in 0..BRICK {
                                let p = b * BRICK as i32 + IVec3::new(x as i32, y as i32, z as i32);
                                if self.in_bounds(p) {
                                    brick.v[Brick::idx(x, y, z)] = value;
                                }
                            }
                        }
                    }
                    self.pool.push(brick);
                    let i = self.brick_index(b);
                    self.bricks[i] = self.pool.len() as u32;
                }
            }
        }
        self.solid_count = if value == 0 { 0 } else { self.total() };
    }

    pub fn total(&self) -> usize {
        self.dims.x as usize * self.dims.y as usize * self.dims.z as usize
    }

    pub fn cell_volume(&self) -> f32 {
        self.cell.x * self.cell.y * self.cell.z
    }

    /// Object-space bounds.
    pub fn min(&self) -> Vec3 {
        self.origin
    }
    pub fn max(&self) -> Vec3 {
        self.origin + self.dims.as_vec3() * self.cell
    }
    pub fn size(&self) -> Vec3 {
        self.dims.as_vec3() * self.cell
    }

    #[inline]
    fn brick_index(&self, b: IVec3) -> usize {
        ((b.z * self.bdims.y + b.y) * self.bdims.x + b.x) as usize
    }

    #[inline]
    pub fn in_bounds(&self, p: IVec3) -> bool {
        p.x >= 0 && p.y >= 0 && p.z >= 0 && p.x < self.dims.x && p.y < self.dims.y && p.z < self.dims.z
    }

    #[inline]
    pub fn get(&self, p: IVec3) -> Voxel {
        if !self.in_bounds(p) {
            return 0;
        }
        let b = p / BRICK as i32;
        let bi = self.bricks[self.brick_index(b)];
        if bi == 0 {
            return 0;
        }
        let l = p - b * BRICK as i32;
        self.pool[bi as usize - 1].v[Brick::idx(l.x as usize, l.y as usize, l.z as usize)]
    }

    #[inline]
    pub fn solid(&self, p: IVec3) -> bool {
        self.get(p) != 0
    }

    pub fn set(&mut self, p: IVec3, v: Voxel) {
        if !self.in_bounds(p) {
            return;
        }
        let b = p / BRICK as i32;
        let bidx = self.brick_index(b);
        if self.bricks[bidx] == 0 {
            if v == 0 {
                return;
            }
            self.pool.push(Brick { v: [0; BRICK3] });
            self.bricks[bidx] = self.pool.len() as u32;
        }
        let l = p - b * BRICK as i32;
        let slot = &mut self.pool[self.bricks[bidx] as usize - 1].v[Brick::idx(l.x as usize, l.y as usize, l.z as usize)];
        if *slot == 0 && v != 0 {
            self.solid_count += 1;
        } else if *slot != 0 && v == 0 {
            self.solid_count -= 1;
        }
        *slot = v;
    }

    /// Object-space centre of a voxel.
    #[inline]
    pub fn centre(&self, p: IVec3) -> Vec3 {
        self.origin + (p.as_vec3() + 0.5) * self.cell
    }

    /// The cell a point is in (may be out of bounds).
    #[inline]
    pub fn cell_of(&self, at: Vec3) -> IVec3 {
        ((at - self.origin) / self.cell).floor().as_ivec3()
    }

    /// The solid stretches a ray crosses inside the volume: (enter, exit) distances along `d`
    /// (a unit vector) from `o`, between 0 and `max_t`, in order. Amanatides–Woo, as
    /// Pixel-factory's `dda`, over cells that may differ in size per axis.
    pub fn runs(&self, o: Vec3, d: Vec3, max_t: f32) -> Vec<(f32, f32)> {
        let mut out = Vec::new();
        let inv_d = Vec3::new(safe_inv(d.x), safe_inv(d.y), safe_inv(d.z));
        let Some((ta, tb)) = ray_box(o, inv_d, self.min(), self.max(), 0.0, max_t) else {
            return out;
        };
        let p = o + d * (ta + 1e-6);
        let mut c = self.cell_of(p).clamp(IVec3::ZERO, self.dims - 1);
        let step = IVec3::new(sign(d.x), sign(d.y), sign(d.z));
        let mut t_max = Vec3::splat(f32::INFINITY);
        let mut t_delta = Vec3::splat(f32::INFINITY);
        for a in 0..3 {
            if d[a] != 0.0 {
                let next = self.origin[a] + (c[a] + if step[a] > 0 { 1 } else { 0 }) as f32 * self.cell[a];
                t_max[a] = (next - o[a]) * inv_d[a];
                t_delta[a] = self.cell[a] * inv_d[a].abs();
            }
        }
        let mut t = ta;
        let mut start = 0.0;
        let mut inside = false;
        loop {
            let solid = self.solid(c);
            if solid && !inside {
                start = t;
                inside = true;
            } else if !solid && inside {
                out.push((start, t));
                inside = false;
            }
            let a = if t_max.x < t_max.y {
                if t_max.x < t_max.z { 0 } else { 2 }
            } else if t_max.y < t_max.z {
                1
            } else {
                2
            };
            if t_max[a] >= tb {
                break;
            }
            t = t_max[a];
            t_max[a] += t_delta[a];
            c[a] += step[a];
            if c[a] < 0 || c[a] >= self.dims[a] {
                break;
            }
        }
        if inside {
            out.push((start, tb));
        }
        out
    }

    /// Every cell a segment passes through (for a channel narrower than a cell: it still goes
    /// right through).
    pub fn cells_on_segment(&self, a: Vec3, b: Vec3) -> Vec<IVec3> {
        let mut out = Vec::new();
        let len = (b - a).length();
        if len < 1e-6 {
            let c = self.cell_of(a);
            if self.in_bounds(c) {
                out.push(c);
            }
            return out;
        }
        let d = (b - a) / len;
        let inv_d = Vec3::new(safe_inv(d.x), safe_inv(d.y), safe_inv(d.z));
        let Some((ta, tb)) = ray_box(a, inv_d, self.min(), self.max(), 0.0, len) else {
            return out;
        };
        let mut c = self.cell_of(a + d * (ta + 1e-6)).clamp(IVec3::ZERO, self.dims - 1);
        let step = IVec3::new(sign(d.x), sign(d.y), sign(d.z));
        let mut t_max = Vec3::splat(f32::INFINITY);
        let mut t_delta = Vec3::splat(f32::INFINITY);
        for k in 0..3 {
            if d[k] != 0.0 {
                let next = self.origin[k] + (c[k] + if step[k] > 0 { 1 } else { 0 }) as f32 * self.cell[k];
                t_max[k] = (next - a[k]) * inv_d[k];
                t_delta[k] = self.cell[k] * inv_d[k].abs();
            }
        }
        loop {
            out.push(c);
            let k = if t_max.x < t_max.y {
                if t_max.x < t_max.z { 0 } else { 2 }
            } else if t_max.y < t_max.z {
                1
            } else {
                2
            };
            if t_max[k] >= tb {
                break;
            }
            t_max[k] += t_delta[k];
            c[k] += step[k];
            if c[k] < 0 || c[k] >= self.dims[k] {
                break;
            }
        }
        out
    }
}

#[inline]
fn sign(x: f32) -> i32 {
    if x > 0.0 {
        1
    } else if x < 0.0 {
        -1
    } else {
        0
    }
}

#[inline]
fn safe_inv(x: f32) -> f32 {
    if x.abs() < 1e-12 {
        1e12_f32.copysign(x)
    } else {
        1.0 / x
    }
}

/// Slab test; returns the entry and exit distances along the ray inside [tmin, tmax].
#[inline]
pub fn ray_box(o: Vec3, inv_d: Vec3, bmin: Vec3, bmax: Vec3, tmin: f32, tmax: f32) -> Option<(f32, f32)> {
    let t0 = (bmin - o) * inv_d;
    let t1 = (bmax - o) * inv_d;
    let tn = t0.min(t1);
    let tf = t0.max(t1);
    let a = tn.max_element().max(tmin);
    let b = tf.min_element().min(tmax);
    if a <= b {
        Some((a, b))
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn wood() -> Voxel {
        pack(0, 0, 0, material::WOOD)
    }

    #[test]
    fn a_box_is_cut_into_whole_cells_and_fills_its_size() {
        let v = Volume::solid_box(Vec3::new(0.022, 0.15, 3.0), 96.0, 1 << 20, wood());
        assert_eq!(v.dims, IVec3::new(2, 14, 288));
        assert!((v.size() - Vec3::new(0.022, 0.15, 3.0)).abs().max_element() < 1e-5);
        assert_eq!(v.solid_count, v.total());
        assert!(v.solid(IVec3::new(1, 13, 287)) && !v.solid(IVec3::new(2, 0, 0)));
    }

    #[test]
    fn a_long_sill_is_cut_coarser_to_stay_in_budget() {
        let v = Volume::solid_box(Vec3::new(0.2, 0.2, 8.0), 96.0, 200_000, wood());
        assert!(v.total() <= 200_000, "{}", v.total());
        assert!(v.total() > 120_000);
    }

    #[test]
    fn a_ray_through_a_solid_box_is_one_run_its_thickness() {
        let v = Volume::solid_box(Vec3::new(0.05, 0.1, 1.0), 96.0, 1 << 20, wood());
        let runs = v.runs(Vec3::new(-1.0, 0.01, 0.2), Vec3::X, 5.0);
        assert_eq!(runs.len(), 1);
        assert!((runs[0].0 - 0.975).abs() < 1e-4 && (runs[0].1 - 1.025).abs() < 1e-4, "{:?}", runs);
        assert!(v.runs(Vec3::new(-1.0, 2.0, 0.0), Vec3::X, 5.0).is_empty());
    }
}
