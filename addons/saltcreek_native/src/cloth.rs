//! Our own cloth for garments, flags and curtains (docs/briefs/garment-cloth.md, step 1: the core).
//! Pure Rust with no crates, so `cargo test` and a bare `rustc --test` both run it; `cloth_core.rs`
//! is Godot's handle on it (`ClothCore`).
//!
//! Positions in small steps: XPBD (Macklin, Müller, Chentanez 2016, "XPBD: position-based
//! simulation of compliant constrained dynamics") with substeps and one pass each (Macklin et al.
//! 2019, "Small steps in physics simulation"). On each substep, in this order:
//! - **stretch**: a distance constraint per edge, its compliance per garment;
//! - **bending**, one of two per garment:
//!   - `FLAT`: isometric bending (Bergou, Wardetzky, Harmon, Zorin, Grinspun 2006, "A quadratic
//!     bending model for inextensible surfaces"; the cotangent weights as in Wardetzky et al. 2007).
//!     Its energy is k·3/(A0+A1)·|Σ Kᵢxᵢ|²/2 for each inner edge's four points, so the constraint
//!     Σ Kᵢxᵢ = 0 is linear, three independent rows (x, y, z), cheap and exact for a flat rest;
//!   - `SHAPED`: the two points across each inner edge held at their rest distance (a softer, cruder
//!     keeper of the rest shape's folds, for a garment that should still look like itself);
//! - **the strain limit** (Provot 1995, "Deformation constraints in a mass-spring model to describe
//!   rigid cloth behavior"): every edge pushed back within [min_strain, max_strain] of its rest
//!   length, `limit_passes` passes, whatever the compliance, each followed by:
//! - **the floor**: a plane, points kept `thickness` above it, with Coulomb friction on the move
//!   along it (static then kinetic, as in Müller et al. 2007, "Position based dynamics").
//! Pins are points with no inverse mass, carried by the caller: their targets are set once a tick
//! and they move there in even steps over the substeps.
//!
//! Deterministic: every loop runs in a fixed order, no hashing, no threads; the only randomness is a
//! seeded xorshift for the starting jitter (zero unless asked). The same inputs on one build give the
//! same bits. Ideas only from the papers named; no code copied from anywhere.

pub type V3 = [f32; 3];

#[inline]
fn sub(a: V3, b: V3) -> V3 {
    [a[0] - b[0], a[1] - b[1], a[2] - b[2]]
}
#[inline]
fn add(a: V3, b: V3) -> V3 {
    [a[0] + b[0], a[1] + b[1], a[2] + b[2]]
}
#[inline]
fn scale(a: V3, s: f32) -> V3 {
    [a[0] * s, a[1] * s, a[2] * s]
}
#[inline]
fn dot(a: V3, b: V3) -> f32 {
    a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
}
#[inline]
fn cross(a: V3, b: V3) -> V3 {
    [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
}
#[inline]
fn len(a: V3) -> f32 {
    dot(a, a).sqrt()
}

/// The cotangent of the angle between `a` and `b`.
fn cot(a: V3, b: V3) -> f32 {
    let s = len(cross(a, b));
    if s < 1e-12 {
        return 0.0;
    }
    dot(a, b) / s
}

pub const FLAT: i32 = 0;
pub const SHAPED: i32 = 1;

/// A garment's numbers (ClothCore.tune's names).
#[derive(Clone, Debug)]
pub struct Tuning {
    /// m/N: 0 is as stiff as the steps allow.
    pub stretch_compliance: f32,
    /// N·m: the bending stiffness (FLAT: k of the isometric energy; SHAPED: per cross edge, N/m·rest²).
    pub bend_stiffness: f32,
    pub bend_mode: i32,
    /// The strain limit: no edge longer than max_strain × rest or shorter than min_strain × rest.
    pub max_strain: f32,
    pub min_strain: f32,
    /// 1/s: velocity lost each second (linear drag on every point).
    pub damping: f32,
    pub gravity: V3,
    pub floor_on: bool,
    pub floor_y: f32,
    /// m: points kept this far above the floor.
    pub thickness: f32,
    pub friction_static: f32,
    pub friction_kinetic: f32,
    pub substeps: u32,
    /// Passes of the strain limit and the floor a substep.
    pub limit_passes: u32,
}

impl Default for Tuning {
    fn default() -> Self {
        Tuning {
            stretch_compliance: 0.0,
            bend_stiffness: 1e-4,
            bend_mode: FLAT,
            max_strain: 1.08,
            min_strain: 0.0,
            damping: 1.0,
            gravity: [0.0, -9.81, 0.0],
            floor_on: true,
            floor_y: 0.0,
            thickness: 0.002,
            friction_static: 0.6,
            friction_kinetic: 0.4,
            substeps: 12,
            limit_passes: 3,
        }
    }
}

/// An inner edge's bending: its four points (edge a-b, across it c and d) and their numbers.
#[derive(Clone, Copy, Debug)]
pub struct Bend {
    pub i: [u32; 4],
    /// FLAT: the cotangent weights Kᵢ; SHAPED: k[0] is the rest distance c-d.
    pub k: [f32; 4],
    /// FLAT: 3/(A0+A1); SHAPED: unused (1).
    pub area_term: f32,
}

#[derive(Clone, Debug, Default)]
pub struct Cloth {
    pub t: Tuning,
    pub x: Vec<V3>,
    pub v: Vec<V3>,
    /// Inverse mass now (0 while pinned) and as built.
    pub w: Vec<f32>,
    pub w_free: Vec<f32>,
    pub pinned: Vec<bool>,
    /// A pinned point's place at the tick's start and its target at the end.
    pin_from: Vec<V3>,
    pin_to: Vec<V3>,
    pub tris: Vec<[u32; 3]>,
    pub edges: Vec<[u32; 2]>,
    pub rest: Vec<f32>,
    pub bends_flat: Vec<Bend>,
    pub bends_shaped: Vec<Bend>,
    pub steps: u64,
    /// Each point's place at the substep's start (kept, so a step allocates nothing).
    prev: Vec<V3>,
}

impl Cloth {
    /// Made from `points` and `tris` (every three an index of `points`), `density` kg/m².
    /// Its rest shape is the shape given. False (and empty) if an index is out of range.
    pub fn build(points: &[V3], tris: &[u32], density: f32, t: Tuning) -> Option<Cloth> {
        let n = points.len();
        if tris.len() % 3 != 0 || tris.iter().any(|&i| i as usize >= n) {
            return None;
        }
        let mut c = Cloth { t, ..Default::default() };
        c.x = points.to_vec();
        c.v = vec![[0.0; 3]; n];
        c.pinned = vec![false; n];
        c.pin_from = points.to_vec();
        c.pin_to = points.to_vec();
        let mut mass = vec![0.0f32; n];
        for k in (0..tris.len()).step_by(3) {
            let t = [tris[k], tris[k + 1], tris[k + 2]];
            if t[0] == t[1] || t[1] == t[2] || t[0] == t[2] {
                continue;
            }
            let (a, b, cc) = (points[t[0] as usize], points[t[1] as usize], points[t[2] as usize]);
            let area = 0.5 * len(cross(sub(b, a), sub(cc, a)));
            for &i in &t {
                mass[i as usize] += density * area / 3.0;
            }
            c.tris.push(t);
        }
        // A point no triangle weighs (or a sliver's) still has a little mass.
        let least = mass.iter().cloned().filter(|m| *m > 0.0).fold(f32::MAX, f32::min);
        let least = if least == f32::MAX { 1e-3 } else { least };
        c.w = mass.iter().map(|&m| 1.0 / m.max(least * 0.1)).collect();
        c.w_free = c.w.clone();
        c.make_edges();
        Some(c)
    }

    /// Edges (each once, in the order first met) and, for every edge two triangles share, its bend.
    fn make_edges(&mut self) {
        // Sorted (low, high, the third point) for every triangle's edges; equal neighbours share one.
        let mut half: Vec<(u32, u32, u32)> = Vec::with_capacity(self.tris.len() * 3);
        for t in &self.tris {
            for k in 0..3 {
                let a = t[k];
                let b = t[(k + 1) % 3];
                let o = t[(k + 2) % 3];
                half.push((a.min(b), a.max(b), o));
            }
        }
        half.sort_unstable();
        let mut i = 0;
        while i < half.len() {
            let (a, b, o) = half[i];
            let mut j = i + 1;
            while j < half.len() && half[j].0 == a && half[j].1 == b {
                j += 1;
            }
            self.edges.push([a, b]);
            self.rest.push(len(sub(self.x[a as usize], self.x[b as usize])));
            if j - i == 2 {
                let d = half[i + 1].2;
                if d != o {
                    self.bends_flat.push(self.flat_bend(a, b, o, d));
                    let rd = len(sub(self.x[o as usize], self.x[d as usize]));
                    self.bends_shaped.push(Bend { i: [a, b, o, d], k: [rd, 0.0, 0.0, 0.0], area_term: 1.0 });
                }
            }
            i = j;
        }
    }

    /// The isometric bending weights of edge (0,1) with 2 and 3 across it (Wardetzky et al. 2007's
    /// K = (c03+c04, c01+c02, −c01−c03, −c02−c04), the cᵢⱼ cotangents of the angles at 0 and 1).
    fn flat_bend(&self, i0: u32, i1: u32, i2: u32, i3: u32) -> Bend {
        let (x0, x1, x2, x3) = (self.x[i0 as usize], self.x[i1 as usize], self.x[i2 as usize], self.x[i3 as usize]);
        let e0 = sub(x1, x0);
        let e1 = sub(x2, x0);
        let e2 = sub(x3, x0);
        let e3 = sub(x2, x1);
        let e4 = sub(x3, x1);
        let c01 = cot(e0, e1);
        let c02 = cot(e0, e2);
        let c03 = cot(scale(e0, -1.0), e3);
        let c04 = cot(scale(e0, -1.0), e4);
        let a0 = 0.5 * len(cross(e0, e1));
        let a1 = 0.5 * len(cross(e0, e2));
        Bend {
            i: [i0, i1, i2, i3],
            k: [c03 + c04, c01 + c02, -c01 - c03, -c02 - c04],
            area_term: 3.0 / (a0 + a1).max(1e-12),
        }
    }

    pub fn len(&self) -> usize {
        self.x.len()
    }

    /// Seeded jitter of the start (`amount` m at most each way), to break a perfect symmetry.
    pub fn jitter(&mut self, seed: u64, amount: f32) {
        let mut s = seed.wrapping_mul(0x9E37_79B9_7F4A_7C15) | 1;
        for i in 0..self.x.len() {
            if self.pinned[i] {
                continue;
            }
            for k in 0..3 {
                s ^= s << 13;
                s ^= s >> 7;
                s ^= s << 17;
                let u = (s >> 40) as f32 / (1u64 << 24) as f32; // 0..1
                self.x[i][k] += (u * 2.0 - 1.0) * amount;
            }
        }
    }

    /// Point `i` pinned (held where the caller puts it) or let go.
    pub fn pin(&mut self, i: usize, on: bool) {
        if i >= self.x.len() {
            return;
        }
        self.pinned[i] = on;
        self.w[i] = if on { 0.0 } else { self.w_free[i] };
        self.pin_from[i] = self.x[i];
        self.pin_to[i] = self.x[i];
        if on {
            self.v[i] = [0.0; 3];
        }
    }

    /// A pinned point's place at the end of the next step (it moves there evenly over the substeps).
    pub fn move_pin(&mut self, i: usize, to: V3) {
        if i < self.x.len() && self.pinned[i] {
            self.pin_to[i] = to;
        }
    }

    /// Every free point's velocity raised by `dv` (a throw).
    pub fn add_velocity(&mut self, dv: V3) {
        for i in 0..self.x.len() {
            if !self.pinned[i] {
                self.v[i] = add(self.v[i], dv);
            }
        }
    }

    /// One tick of `dt` s, in `t.substeps` small steps.
    pub fn step(&mut self, dt: f32) {
        let n_sub = self.t.substeps.max(1);
        let h = dt / n_sub as f32;
        if h <= 0.0 {
            return;
        }
        let n = self.x.len();
        let mut prev = std::mem::take(&mut self.prev);
        prev.resize(n, [0.0; 3]);
        let keep = (1.0 - self.t.damping * h).clamp(0.0, 1.0);
        for s in 0..n_sub {
            let f = (s + 1) as f32 / n_sub as f32;
            for i in 0..n {
                prev[i] = self.x[i];
                if self.pinned[i] {
                    self.x[i] = add(self.pin_from[i], scale(sub(self.pin_to[i], self.pin_from[i]), f));
                } else {
                    self.v[i] = scale(add(self.v[i], scale(self.t.gravity, h)), keep);
                    self.x[i] = add(self.x[i], scale(self.v[i], h));
                }
            }
            self.solve_stretch(h);
            self.solve_bend(h);
            // The strain limit and the floor in turn (the floor last): a landing's push off the floor
            // stretches edges a few millimetres long by a third unless the limit sees it.
            // Friction only on the first pass: it takes the substep's whole move along the floor, and on
            // later passes it would take back the strain limit's own corrections (a stuck point never
            // let its edges in).
            for pass in 0..self.t.limit_passes.max(1) {
                let moved = self.limit_strain();
                self.floor(&prev, pass == 0);
                if moved == 0 {
                    break;
                }
            }
            for i in 0..n {
                if !self.pinned[i] {
                    self.v[i] = scale(sub(self.x[i], prev[i]), 1.0 / h);
                } else {
                    self.v[i] = [0.0; 3];
                }
            }
        }
        for i in 0..n {
            if self.pinned[i] {
                self.pin_from[i] = self.x[i];
            }
        }
        self.prev = prev;
        self.steps += 1;
    }

    fn solve_stretch(&mut self, h: f32) {
        let alpha = self.t.stretch_compliance / (h * h);
        for e in 0..self.edges.len() {
            let [a, b] = self.edges[e];
            let (a, b) = (a as usize, b as usize);
            let wsum = self.w[a] + self.w[b];
            if wsum <= 0.0 {
                continue;
            }
            let d = sub(self.x[a], self.x[b]);
            let l = len(d);
            if l < 1e-9 {
                continue;
            }
            let c = l - self.rest[e];
            let dl = -c / (wsum + alpha);
            let n = scale(d, 1.0 / l);
            self.x[a] = add(self.x[a], scale(n, dl * self.w[a]));
            self.x[b] = sub(self.x[b], scale(n, dl * self.w[b]));
        }
    }

    fn solve_bend(&mut self, h: f32) {
        if self.t.bend_stiffness <= 0.0 {
            return;
        }
        if self.t.bend_mode == SHAPED {
            let alpha = 1.0 / (self.t.bend_stiffness * h * h);
            for bi in 0..self.bends_shaped.len() {
                let b = self.bends_shaped[bi];
                let (c, d) = (b.i[2] as usize, b.i[3] as usize);
                let wsum = self.w[c] + self.w[d];
                if wsum <= 0.0 {
                    continue;
                }
                let dv = sub(self.x[c], self.x[d]);
                let l = len(dv);
                if l < 1e-9 {
                    continue;
                }
                let dl = -(l - b.k[0]) / (wsum + alpha);
                let nrm = scale(dv, 1.0 / l);
                self.x[c] = add(self.x[c], scale(nrm, dl * self.w[c]));
                self.x[d] = sub(self.x[d], scale(nrm, dl * self.w[d]));
            }
            return;
        }
        for bi in 0..self.bends_flat.len() {
            let b = self.bends_flat[bi];
            let alpha = 1.0 / (self.t.bend_stiffness * b.area_term * h * h);
            let mut cv = [0.0f32; 3];
            let mut wsum = 0.0f32;
            for k in 0..4 {
                let p = b.i[k] as usize;
                cv = add(cv, scale(self.x[p], b.k[k]));
                wsum += self.w[p] * b.k[k] * b.k[k];
            }
            if wsum <= 0.0 {
                continue;
            }
            // Three rows (x, y, z), each its own constraint with the same gradient weights.
            let dl = scale(cv, -1.0 / (wsum + alpha));
            for k in 0..4 {
                let p = b.i[k] as usize;
                self.x[p] = add(self.x[p], scale(dl, self.w[p] * b.k[k]));
            }
        }
    }

    /// How many edges it moved.
    fn limit_strain(&mut self) -> usize {
        let (hi, lo) = (self.t.max_strain, self.t.min_strain);
        let mut moved = 0;
        for e in 0..self.edges.len() {
            let [a, b] = self.edges[e];
            let (a, b) = (a as usize, b as usize);
            let wsum = self.w[a] + self.w[b];
            if wsum <= 0.0 {
                continue;
            }
            let d = sub(self.x[a], self.x[b]);
            let l = len(d);
            if l < 1e-9 {
                continue;
            }
            let r = self.rest[e];
            let target = if l > r * hi {
                r * hi
            } else if l < r * lo {
                r * lo
            } else {
                continue;
            };
            let corr = (l - target) / wsum;
            let n = scale(d, 1.0 / l);
            self.x[a] = sub(self.x[a], scale(n, corr * self.w[a]));
            self.x[b] = add(self.x[b], scale(n, corr * self.w[b]));
            moved += 1;
        }
        moved
    }

    fn floor(&mut self, prev: &[V3], friction: bool) {
        if !self.t.floor_on {
            return;
        }
        let top = self.t.floor_y + self.t.thickness;
        for i in 0..self.x.len() {
            if self.pinned[i] || self.x[i][1] >= top {
                continue;
            }
            let depth = top - self.x[i][1];
            self.x[i][1] = top;
            if !friction {
                continue;
            }
            // Friction on the move along the floor this substep.
            let mv = [self.x[i][0] - prev[i][0], 0.0, self.x[i][2] - prev[i][2]];
            let m = len(mv);
            if m < 1e-12 {
                continue;
            }
            if m < self.t.friction_static * depth {
                self.x[i][0] = prev[i][0];
                self.x[i][2] = prev[i][2];
            } else {
                let k = (self.t.friction_kinetic * depth / m).min(1.0);
                self.x[i][0] -= mv[0] * k;
                self.x[i][2] -= mv[2] * k;
            }
        }
    }

    // --- Measures (for the tests, the face and the film) ---

    /// The largest edge length over its rest length now.
    pub fn max_strain_now(&self) -> f32 {
        let mut m = 0.0f32;
        for (e, [a, b]) in self.edges.iter().enumerate() {
            let l = len(sub(self.x[*a as usize], self.x[*b as usize]));
            m = m.max(l / self.rest[e].max(1e-9));
        }
        m
    }

    pub fn lowest_y(&self) -> f32 {
        self.x.iter().fold(f32::MAX, |m, p| m.min(p[1]))
    }

    pub fn mean_speed(&self) -> f32 {
        if self.v.is_empty() {
            return 0.0;
        }
        self.v.iter().map(|v| len(*v)).sum::<f32>() / self.v.len() as f32
    }

    /// Per point, the normal of the triangles round it (area weighted).
    pub fn normals(&self) -> Vec<V3> {
        let mut n = vec![[0.0f32; 3]; self.x.len()];
        for t in &self.tris {
            let (a, b, c) = (self.x[t[0] as usize], self.x[t[1] as usize], self.x[t[2] as usize]);
            let f = cross(sub(b, a), sub(c, a));
            for &i in t {
                n[i as usize] = add(n[i as usize], f);
            }
        }
        for v in n.iter_mut() {
            let l = len(*v);
            *v = if l > 1e-12 { scale(*v, 1.0 / l) } else { [0.0, 1.0, 0.0] };
        }
        n
    }

    /// Σ|Kᵢxᵢ| over the flat bends (0 for a flat sheet in any pose): how bent it is.
    pub fn bend_measure(&self) -> f32 {
        let mut s = 0.0;
        for b in &self.bends_flat {
            let mut cv = [0.0f32; 3];
            for k in 0..4 {
                cv = add(cv, scale(self.x[b.i[k] as usize], b.k[k]));
            }
            s += len(cv);
        }
        s
    }
}

/// A sheet `cols`×`rows` points, `w`×`d` m, lying flat at height `y` (x across, z along), its
/// triangles' diagonals alternating. For the tests and the film.
pub fn sheet(cols: usize, rows: usize, w: f32, d: f32, y: f32) -> (Vec<V3>, Vec<u32>) {
    let mut pts = Vec::with_capacity(cols * rows);
    for r in 0..rows {
        for c in 0..cols {
            pts.push([
                w * (c as f32 / (cols - 1) as f32 - 0.5),
                y,
                d * (r as f32 / (rows - 1) as f32 - 0.5),
            ]);
        }
    }
    let mut tris = Vec::new();
    for r in 0..rows - 1 {
        for c in 0..cols - 1 {
            let i = (r * cols + c) as u32;
            let (a, b, cc, dd) = (i, i + 1, i + cols as u32, i + cols as u32 + 1);
            if (r + c) % 2 == 0 {
                tris.extend_from_slice(&[a, cc, b, b, cc, dd]);
            } else {
                tris.extend_from_slice(&[a, cc, dd, a, dd, b]);
            }
        }
    }
    (pts, tris)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn hang(t: Tuning, secs: f32) -> Cloth {
        // 0.5 m square, 16×16 points, lying flat at 1 m, pinned at the two far corners.
        let (p, tr) = sheet(16, 16, 0.5, 0.5, 1.0);
        let mut c = Cloth::build(&p, &tr, 0.2, t).unwrap();
        c.pin(0, true);
        c.pin(15, true);
        for _ in 0..(secs * 60.0) as usize {
            c.step(1.0 / 60.0);
        }
        c
    }

    #[test]
    fn a_flat_sheet_has_no_bend_in_any_pose() {
        let (p, tr) = sheet(6, 5, 0.3, 0.2, 0.0);
        let c = Cloth::build(&p, &tr, 0.2, Tuning::default()).unwrap();
        assert!(c.bend_measure() < 1e-4, "{}", c.bend_measure());
        // Turned and moved, still flat.
        let mut c2 = c.clone();
        for x in c2.x.iter_mut() {
            *x = [x[0] * 0.6 - x[2] * 0.8 + 3.0, x[0] * 0.8 + x[2] * 0.6 - 1.0, x[1] + 2.0];
        }
        assert!(c2.bend_measure() < 1e-4, "{}", c2.bend_measure());
        // Folded, not.
        let mut c3 = c.clone();
        for x in c3.x.iter_mut() {
            if x[0] > 0.0 {
                x[1] = x[0];
            }
        }
        assert!(c3.bend_measure() > 1e-2, "{}", c3.bend_measure());
    }

    #[test]
    fn edges_and_bends_are_counted_once() {
        let (p, tr) = sheet(4, 3, 0.3, 0.2, 0.0);
        let c = Cloth::build(&p, &tr, 0.2, Tuning::default()).unwrap();
        // 3×2 squares: 4·2 + 3·3 + 6 diagonals = 23 edges; inner = 23 − boundary 10 = 13.
        assert_eq!(c.edges.len(), 23);
        assert_eq!(c.bends_flat.len(), 13);
        assert!(Cloth::build(&p, &[0, 1, 99], 0.2, Tuning::default()).is_none());
    }

    #[test]
    fn a_sheet_pinned_at_two_corners_hangs_within_its_strain_limit() {
        let c = hang(Tuning { floor_on: false, ..Default::default() }, 5.0);
        assert_eq!(c.x[0], [-0.25, 1.0, -0.25]);
        assert!(c.lowest_y() < 0.6, "it hangs: lowest {}", c.lowest_y());
        assert!(c.max_strain_now() < 1.08 * 1.01, "strain {}", c.max_strain_now());
        assert!(c.mean_speed() < 0.05, "settling: {}", c.mean_speed());
        assert!(c.x.iter().all(|p| p.iter().all(|v| v.is_finite())));
    }

    #[test]
    fn more_bending_stiffness_bends_less() {
        // Clamped along one edge (two rows pinned: one row is a hinge any flat sheet turns about), how
        // far the free edge droops once it's still.
        let droop = |k: f32| {
            let (p, tr) = sheet(12, 8, 0.3, 0.19, 1.0);
            let t = Tuning { bend_stiffness: k, floor_on: false, damping: 3.0, ..Default::default() };
            let mut c = Cloth::build(&p, &tr, 0.2, t).unwrap();
            for i in 0..24 {
                c.pin(i, true);
            }
            for _ in 0..600 {
                c.step(1.0 / 60.0);
            }
            1.0 - c.lowest_y()
        };
        let (soft, mid, stiff) = (droop(1e-5), droop(1e-3), droop(1e-2));
        assert!(soft > mid && mid > stiff, "{soft} {mid} {stiff}");
        assert!(stiff < 0.5 * soft, "{soft} {stiff}");
    }

    #[test]
    fn the_shaped_mode_keeps_a_fold() {
        let (mut p, tr) = sheet(10, 10, 0.3, 0.3, 0.0);
        for x in p.iter_mut() {
            x[1] = 0.5 + 0.3 * (x[0].abs() - 0.15).abs(); // a V across it
        }
        let run = |mode: i32| {
            let t = Tuning { bend_mode: mode, bend_stiffness: 1e-2, floor_on: false, gravity: [0.0; 3], ..Default::default() };
            let mut c = Cloth::build(&p, &tr, 0.2, t).unwrap();
            c.add_velocity([0.0, 0.0, 0.0]);
            for _ in 0..60 {
                c.step(1.0 / 60.0);
            }
            c.x.iter().zip(&p).map(|(a, b)| len(sub(*a, *b))).fold(0.0f32, f32::max)
        };
        assert!(run(SHAPED) < 1e-3, "shaped moved {}", run(SHAPED));
        assert!(run(FLAT) > 1e-2, "flat flattens it: {}", run(FLAT));
    }

    #[test]
    fn the_same_seed_gives_the_same_bits() {
        let go = |seed: u64| {
            let (p, tr) = sheet(12, 12, 0.4, 0.4, 0.5);
            let mut c = Cloth::build(&p, &tr, 0.2, Tuning::default()).unwrap();
            c.jitter(seed, 1e-3);
            for _ in 0..90 {
                c.step(1.0 / 60.0);
            }
            c.x
        };
        assert_eq!(go(5), go(5));
        assert_ne!(go(5), go(6));
    }

    #[test]
    fn nothing_goes_through_the_floor() {
        let (p, tr) = sheet(16, 16, 0.5, 0.5, 0.3);
        let mut c = Cloth::build(&p, &tr, 0.2, Tuning::default()).unwrap();
        c.jitter(3, 2e-3);
        c.add_velocity([0.5, -4.0, 0.0]); // thrown down hard
        let mut least = f32::MAX;
        for _ in 0..180 {
            c.step(1.0 / 60.0);
            least = least.min(c.lowest_y());
        }
        assert!(least >= 0.002 - 1e-6, "lowest {least}");
        assert!(c.mean_speed() < 0.05, "it lies: {}", c.mean_speed());
        assert!(c.max_strain_now() < 1.09, "{}", c.max_strain_now());
    }

    #[test]
    fn pins_move_where_they_are_put() {
        let (p, tr) = sheet(8, 8, 0.3, 0.3, 1.0);
        let mut c = Cloth::build(&p, &tr, 0.2, Tuning { floor_on: false, ..Default::default() }).unwrap();
        c.pin(0, true);
        for k in 1..=30 {
            c.move_pin(0, [-0.15 + 0.01 * k as f32, 1.0, -0.15]);
            c.step(1.0 / 60.0);
        }
        assert!(len(sub(c.x[0], [0.15, 1.0, -0.15])) < 1e-5, "{:?}", c.x[0]);
        c.pin(0, false);
        c.step(1.0 / 60.0);
        assert!(c.x[0][1] < 1.0, "let go, it falls");
    }
}
