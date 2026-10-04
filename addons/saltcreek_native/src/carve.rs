//! Carving a member's volume: a projectile's channel, the wood it tears out round it (the spall,
//! a set volume, ragged), anything left hanging by nothing, and what's left of the section.
//! All of it runs on the main thread in the order the hits come (it's a few hundred voxels and
//! microseconds), so a charge's pellets see each other's holes and the result is the same every
//! run; only meshing goes to the workers.

use crate::volume::Volume;
use glam::{IVec3, Vec3};
use std::collections::{HashMap, HashSet};

/// How a carve goes. Distances in metres, in the member's own space.
#[derive(Clone, Copy, Debug)]
pub struct Carve {
    /// Where it went in and where it came out (the same point for one that stopped at the face).
    pub entry: Vec3,
    pub exit: Vec3,
    /// The channel's radius: every voxel whose centre is this near the path goes, and every voxel
    /// the path crosses, however narrow.
    pub radius: f32,
    /// Wood torn out round the channel, m³ (the blast and the splintering: set by the caller).
    pub spall_m3: f32,
    /// How uneven the spall's edge is (0 a clean cone, 1 very ragged).
    pub ragged: f32,
    /// How much wider the tear-out is at the exit than at the entry (wood splinters out the back).
    pub flare: f32,
    /// Wood splits along its grain: the spall reaches this many times as far along `grain` (an
    /// axis, 0 x 1 y 2 z; None for stone) as across it.
    pub grain: Option<usize>,
    pub grain_split: f32,
    pub seed: u64,
    /// Pieces held on by nothing this big or smaller go too (voxels).
    pub island_max: usize,
    /// Debris pieces to report.
    pub max_chunks: usize,
}

#[derive(Default, Debug)]
pub struct Carved {
    pub removed: usize,
    /// Debris: (centre in member space, voxels in it), biggest first.
    pub chunks: Vec<(Vec3, u32)>,
}

#[inline]
fn hash3(p: IVec3, seed: u64) -> f32 {
    let mut h = seed ^ 0x9E37_79B9_7F4A_7C15;
    for k in [p.x, p.y, p.z] {
        h ^= k as u32 as u64;
        h = h.wrapping_mul(0xBF58_476D_1CE4_E5B9);
        h ^= h >> 31;
    }
    (h >> 40) as f32 / (1u64 << 24) as f32
}

/// Clumpy noise in [0, 1): a lattice every 2 cells, blended, with a little per-cell grain, so
/// a spall's edge comes out in splinters and lumps, not single-cell speckle.
fn noise(p: IVec3, seed: u64) -> f32 {
    let q = IVec3::new(p.x.div_euclid(2), p.y.div_euclid(2), p.z.div_euclid(2));
    let f = (p - q * 2).as_vec3() * 0.5;
    let mut sum = 0.0;
    for dz in 0..2 {
        for dy in 0..2 {
            for dx in 0..2 {
                let w = (if dx == 1 { f.x } else { 1.0 - f.x }) * (if dy == 1 { f.y } else { 1.0 - f.y }) * (if dz == 1 { f.z } else { 1.0 - f.z });
                sum += w * hash3(q + IVec3::new(dx, dy, dz), seed);
            }
        }
    }
    sum * 0.7 + hash3(p, seed.wrapping_add(17)) * 0.3
}

/// Distance from `p` to the segment a–b, and where along it (0 at a, 1 at b).
#[inline]
fn to_segment(p: Vec3, a: Vec3, b: Vec3) -> (f32, f32) {
    let ab = b - a;
    let l2 = ab.length_squared();
    if l2 < 1e-12 {
        return ((p - a).length(), 0.0);
    }
    let t = ((p - a).dot(ab) / l2).clamp(0.0, 1.0);
    ((p - (a + ab * t)).length(), t)
}

const NEIGHBOURS: [IVec3; 6] = [IVec3::X, IVec3::NEG_X, IVec3::Y, IVec3::NEG_Y, IVec3::Z, IVec3::NEG_Z];

impl Volume {
    /// Carve a hit. Returns how many voxels went and the debris they make.
    pub fn carve(&mut self, c: &Carve) -> Carved {
        let mut gone: Vec<IVec3> = Vec::new();
        let r_cell = self.cell.max_element();
        let len = (c.exit - c.entry).length();
        let spall_cells = (c.spall_m3.max(0.0) / self.cell_volume()).round() as usize;
        // How wide to look: enough for the channel and a spall of that volume round it, twice
        // over for the ragged edge.
        let spall_r = if len > 2.0 * c.radius {
            (c.spall_m3.max(0.0) / (std::f32::consts::PI * len.max(r_cell)) + c.radius * c.radius).sqrt()
        } else {
            (c.spall_m3.max(0.0) * 3.0 / (4.0 * std::f32::consts::PI)).cbrt() + c.radius
        };
        // Along the grain the spall reaches further and across it less, the same volume in all.
        let split = c.grain_split.max(1.0);
        let mut stretch = Vec3::ONE;
        if let Some(g) = c.grain {
            stretch = Vec3::splat(1.0 / split.sqrt());
            stretch[g] = split / split.sqrt();
        }
        let reach = c.radius.max(spall_r * (1.0 + c.flare) * (1.0 + c.ragged)) * 1.6 + 2.0 * r_cell;
        let reach3 = Vec3::splat(c.radius + 2.0 * r_cell).max(stretch * reach);
        let lo = self.cell_of(c.entry.min(c.exit) - reach3).max(IVec3::ZERO);
        let hi = self.cell_of(c.entry.max(c.exit) + reach3).min(self.dims - 1);
        // The channel: everything this near the path, and every cell the path crosses.
        for p in self.cells_on_segment(c.entry, c.exit) {
            if self.solid(p) {
                self.set(p, 0);
                gone.push(p);
            }
        }
        let mut candidates: Vec<(f32, IVec3)> = Vec::new();
        for z in lo.z..=hi.z {
            for y in lo.y..=hi.y {
                for x in lo.x..=hi.x {
                    let p = IVec3::new(x, y, z);
                    if !self.solid(p) {
                        continue;
                    }
                    let centre = self.centre(p);
                    let (d, t) = to_segment(centre, c.entry, c.exit);
                    if d <= c.radius {
                        self.set(p, 0);
                        gone.push(p);
                    } else if spall_cells > 0 {
                        // Nearest the path first (measured with the grain stretched: splits run
                        // along it), wider toward the exit, the edge broken up.
                        let (ds, _) = to_segment(centre / stretch, c.entry / stretch, c.exit / stretch);
                        if ds <= reach {
                            let profile = 1.0 + c.flare * t;
                            let n = noise(p, c.seed);
                            candidates.push((ds / profile * (1.0 + c.ragged * (n - 0.5) * 2.0), p));
                        }
                    }
                }
            }
        }
        if spall_cells > 0 && !candidates.is_empty() {
            candidates.sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap().then_with(|| a.1.to_array().cmp(&b.1.to_array())));
            for (_, p) in candidates.into_iter().take(spall_cells) {
                if self.solid(p) {
                    self.set(p, 0);
                    gone.push(p);
                }
            }
        }
        // Splinters left hanging by nothing go too.
        let loose = self.loose_pieces(&gone, c.island_max);
        for p in &loose {
            self.set(*p, 0);
        }
        gone.extend(loose);
        self.tear_edges(&gone, c);
        Carved { removed: gone.len(), chunks: self.chunks(&gone, c.max_chunks) }
    }

    /// The wood round what's gone is torn: its weathered face splintered off, fresh wood showing
    /// (every solid neighbour, and a ragged run further along the grain).
    fn tear_edges(&mut self, gone: &[IVec3], c: &Carve) {
        let mut mark: Vec<IVec3> = Vec::new();
        for g in gone {
            for n in NEIGHBOURS {
                let q = *g + n;
                if self.solid(q) {
                    mark.push(q);
                }
            }
            if let Some(axis) = c.grain {
                for dir in [1, -1] {
                    for k in 2..4 {
                        let mut q = *g;
                        q[axis] += dir * k;
                        if self.solid(q) && noise(q, c.seed.wrapping_add(31)) < 0.75 - 0.2 * k as f32 {
                            mark.push(q);
                        }
                    }
                }
            }
        }
        for q in mark {
            let v = self.get(q);
            self.set(q, v | crate::volume::TORN);
        }
    }

    /// Solid pieces next to what's just gone that aren't joined to anything bigger than
    /// `max` voxels: torn free. Each search stops as soon as it's bigger, so it's cheap.
    fn loose_pieces(&self, gone: &[IVec3], max: usize) -> Vec<IVec3> {
        let mut out = Vec::new();
        if max == 0 {
            return out;
        }
        // Cells found to be part of something big (held on), and of something small (loose).
        let mut held: HashSet<IVec3> = HashSet::new();
        let mut loose: HashSet<IVec3> = HashSet::new();
        for g in gone {
            for n in NEIGHBOURS {
                let s = *g + n;
                if !self.solid(s) || held.contains(&s) || loose.contains(&s) {
                    continue;
                }
                let mut piece = vec![s];
                let mut stack = vec![s];
                let mut here: HashSet<IVec3> = HashSet::from([s]);
                let mut big = false;
                'flood: while let Some(p) = stack.pop() {
                    for m in NEIGHBOURS {
                        let q = p + m;
                        if !self.solid(q) || here.contains(&q) {
                            continue;
                        }
                        // Joined to a piece already found to be big: so is this one.
                        if held.contains(&q) || piece.len() >= max {
                            big = true;
                            break 'flood;
                        }
                        here.insert(q);
                        piece.push(q);
                        stack.push(q);
                    }
                }
                if big {
                    held.extend(here);
                } else {
                    loose.extend(here);
                    out.extend(piece);
                }
            }
        }
        out
    }

    /// What's gone, grouped into lumps 4 cells across: the biggest `max` of them.
    fn chunks(&self, gone: &[IVec3], max: usize) -> Vec<(Vec3, u32)> {
        let mut groups: HashMap<IVec3, (Vec3, u32)> = HashMap::new();
        for p in gone {
            let k = IVec3::new(p.x.div_euclid(4), p.y.div_euclid(4), p.z.div_euclid(4));
            let e = groups.entry(k).or_insert((Vec3::ZERO, 0));
            e.0 += self.centre(*p);
            e.1 += 1;
        }
        let mut list: Vec<(IVec3, Vec3, u32)> = groups.into_iter().map(|(k, (s, n))| (k, s / n as f32, n)).collect();
        list.sort_by(|a, b| b.2.cmp(&a.2).then_with(|| a.0.to_array().cmp(&b.0.to_array())));
        list.into_iter().take(max).map(|(_, c, n)| (c, n)).collect()
    }

    /// What's left of the section along `axis`: the share of the cross-section still solid at
    /// the weakest place, holes within `window` cells along the grain counted together (wood
    /// splits from one to the next), and where that is (the window's middle, member space).
    pub fn section(&self, axis: usize, window: i32) -> (f32, f32) {
        let b = (axis + 1) % 3;
        let c = (axis + 2) % 3;
        let n = self.dims[axis];
        let (nb, nc) = (self.dims[b] as usize, self.dims[c] as usize);
        let cross = nb * nc;
        let w = window.clamp(1, n);
        // gone[slice][cell]
        let mut gone = vec![false; n as usize * cross];
        let mut any = false;
        for s in 0..n {
            for j in 0..nc {
                for i in 0..nb {
                    let mut p = IVec3::ZERO;
                    p[axis] = s;
                    p[b] = i as i32;
                    p[c] = j as i32;
                    if !self.solid(p) {
                        gone[s as usize * cross + j * nb + i] = true;
                        any = true;
                    }
                }
            }
        }
        if !any {
            return (1.0, 0.0);
        }
        let mut count = vec![0u16; cross];
        let mut missing = 0usize;
        // The weakest windows: the first and last of them (equally weak in between: the middle).
        let mut best = (usize::MAX, 0);
        let mut last = 0;
        for s in 0..n as usize {
            for k in 0..cross {
                if gone[s * cross + k] {
                    if count[k] == 0 {
                        missing += 1;
                    }
                    count[k] += 1;
                }
            }
            if s + 1 > w as usize {
                let old = s - w as usize;
                for k in 0..cross {
                    if gone[old * cross + k] {
                        count[k] -= 1;
                        if count[k] == 0 {
                            missing -= 1;
                        }
                    }
                }
            }
            if s + 1 >= w as usize {
                let start = s + 1 - w as usize;
                if best.0 == usize::MAX || missing > best.1 {
                    best = (start, missing);
                    last = start;
                } else if missing == best.1 && last + 1 == start {
                    last = start;
                }
            }
        }
        let keep = 1.0 - best.1 as f32 / cross as f32;
        let mid = self.origin[axis] + ((best.0 + last) as f32 * 0.5 + w as f32 * 0.5) * self.cell[axis];
        (keep, mid)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::volume::{material, pack};

    fn board() -> Volume {
        // A siding board: 22 mm thick, 15 cm wide, 1 m long (thin along x).
        Volume::solid_box(Vec3::new(0.022, 0.15, 1.0), 96.0, 1 << 20, pack(0, 0, 0, material::WOOD))
    }

    fn shot(spall_m3: f32) -> Carve {
        Carve {
            entry: Vec3::new(-0.011, 0.0, 0.0),
            exit: Vec3::new(0.011, 0.0, 0.0),
            radius: 0.004,
            spall_m3,
            ragged: 0.6,
            flare: 0.5,
            grain: Some(2),
            grain_split: 2.0,
            seed: 7,
            island_max: 24,
            max_chunks: 6,
        }
    }

    #[test]
    fn a_channel_goes_through_and_lets_a_ray_past() {
        let mut v = board();
        let r = v.carve(&shot(0.0));
        assert!(r.removed > 0);
        let runs = v.runs(Vec3::new(-0.5, 0.0, 0.0), Vec3::X, 2.0);
        assert!(runs.is_empty(), "{:?}", runs);
        // Beside the hole it's still solid.
        assert_eq!(v.runs(Vec3::new(-0.5, 0.05, 0.0), Vec3::X, 2.0).len(), 1);
    }

    #[test]
    fn the_spall_takes_the_volume_asked_for() {
        let mut base = board();
        let channel = base.carve(&shot(0.0)).removed;
        let mut v = board();
        let want = 30e-6; // 30 cm³
        let r = v.carve(&shot(want));
        let got = (r.removed - channel) as f32 * v.cell_volume();
        assert!((got - want).abs() / want < 0.15, "{} cm³ vs {}", got * 1e6, want * 1e6);
        assert!(!r.chunks.is_empty() && r.chunks.len() <= 6);
        assert_eq!(v.solid_count, v.total() - r.removed);
    }

    #[test]
    fn the_spall_splits_along_the_grain() {
        let mut v = board();
        let mut c = shot(40e-6);
        c.grain_split = 3.0;
        v.carve(&c);
        // Wider along the board (z, its grain) than across it (y).
        let along = (-30..=30).filter(|k| v.runs(Vec3::new(-0.5, 0.0, *k as f32 * 0.002), Vec3::X, 2.0).len() != 1 || v.runs(Vec3::new(-0.5, 0.0, *k as f32 * 0.002), Vec3::X, 2.0).iter().map(|r| r.1 - r.0).sum::<f32>() < 0.02).count();
        let across = (-30..=30).filter(|k| v.runs(Vec3::new(-0.5, *k as f32 * 0.002, 0.0), Vec3::X, 2.0).len() != 1 || v.runs(Vec3::new(-0.5, *k as f32 * 0.002, 0.0), Vec3::X, 2.0).iter().map(|r| r.1 - r.0).sum::<f32>() < 0.02).count();
        assert!(along > across * 3 / 2, "along {} across {}", along, across);
    }

    #[test]
    fn the_same_carve_comes_out_the_same() {
        let mut a = board();
        let mut b = board();
        a.carve(&shot(20e-6));
        b.carve(&shot(20e-6));
        for (x, y) in a.pool.iter().zip(b.pool.iter()) {
            assert_eq!(x.v, y.v);
        }
    }

    #[test]
    fn the_section_left_is_the_weakest_place() {
        // A stud 5 x 10 cm, 2.4 m tall (along y): take 60 % of its section at one height.
        let mut v = Volume::solid_box(Vec3::new(0.05, 2.4, 0.1), 96.0, 1 << 20, pack(0, 0, 0, material::WOOD));
        assert_eq!(v.section(1, 8).0, 1.0);
        let y = v.cell_of(Vec3::new(0.0, 0.3, 0.0)).y;
        let total = (v.dims.x * v.dims.z) as usize;
        let mut taken = 0;
        'out: for z in 0..v.dims.z {
            for x in 0..v.dims.x {
                if taken * 10 >= total * 6 {
                    break 'out;
                }
                v.set(IVec3::new(x, y, z), 0);
                taken += 1;
            }
        }
        let (keep, at) = v.section(1, 8);
        assert!((keep - 0.4).abs() < 0.03, "{}", keep);
        assert!((at - 0.3).abs() < 0.015, "{}", at);
    }

    #[test]
    fn a_band_cut_across_leaves_the_sides_standing() {
        // A channel across a stud takes the middle of its section; the sides either side of it
        // are joined to the stud above and below, so they stay.
        let mut v = Volume::solid_box(Vec3::new(0.05, 2.4, 0.1), 96.0, 1 << 20, pack(0, 0, 0, material::WOOD));
        let mut c = shot(0.0);
        c.entry = Vec3::new(-0.025, -0.1, 0.0);
        c.exit = Vec3::new(0.025, -0.1, 0.0);
        c.radius = 0.03;
        c.island_max = 48;
        v.carve(&c);
        let (keep, at) = v.section(1, 10);
        assert!((keep - 0.4).abs() < 0.03, "{}", keep);
        assert!((at + 0.1).abs() < 0.015, "{}", at);
    }

    #[test]
    fn a_splinter_cut_free_goes_too() {
        let mut v = board();
        let mut c = shot(0.0);
        c.radius = 0.03;
        v.carve(&c);
        // A two-cell splinter left floating in the hole; the next shot cuts one cell of it, and
        // the other, held by nothing, goes with it.
        let p = v.cell_of(Vec3::new(-0.005, 0.0, 0.0));
        let q = p + IVec3::X;
        v.set(p, pack(0, 0, 0, material::WOOD));
        v.set(q, pack(0, 0, 0, material::WOOD));
        let mut cut = shot(0.0);
        cut.radius = 0.0;
        cut.entry = v.centre(q) - Vec3::Y * 0.001;
        cut.exit = v.centre(q) + Vec3::Y * 0.001;
        let r = v.carve(&cut);
        assert_eq!(r.removed, 2);
        assert!(!v.solid(p) && !v.solid(q));
    }

    #[test]
    fn holes_close_along_the_grain_count_together() {
        let mut v = board();
        // Two channels 2 cm apart along the board, at different heights across it.
        for (z, y) in [(0.0, -0.04), (0.02, 0.04)] {
            let mut c = shot(0.0);
            c.entry = Vec3::new(-0.011, y, z);
            c.exit = Vec3::new(0.011, y, z);
            v.carve(&c);
        }
        let one = v.section(2, 1).0;
        let together = v.section(2, 4).0;
        assert!(together < one, "{} {}", together, one);
    }
}
