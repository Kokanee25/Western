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
//! - **his body** (step 2): the wearer's posed skin, triangles the caller moves once a tick (they
//!   move there evenly over the substeps, as pins do). Each free point is kept `body_thickness` off
//!   the nearest triangle **on the side it came from**: its side is taken when it comes within
//!   `body_band` and kept while it stays near, so a point pushed hard against his skin is put back on
//!   its own side, never resolved through to the other. A move that crosses a triangle within one
//!   substep is caught too (the segment against the moving triangle's plane, a continuous test), so a
//!   fast pull can't flip a point through. Friction (Coulomb) on the move along the skin relative to
//!   the skin's own move. Ideas from Bridson, Fedkiw, Anderson 2002 ("Robust treatment of
//!   collisions, contact and friction for cloth animation": a thickness, the side kept, friction on
//!   the relative tangential move) and Teschner et al. 2003 ("Optimized spatial hashing for collision
//!   detection of deformable objects": the triangles hashed into cells by their boxes each tick, the
//!   cloth's points looked up in them), as positions in XPBD's way. It comes last in a substep, so
//!   nothing ends a substep inside him.
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

/// m: two faces of his body facing each other this far into each other or less are a pinch (his
/// skin's two sides overlapping where they press together; a solid's far side is a finger's width).
const PINCH_OVERLAP: f32 = 0.003;
/// m: a point's reach for his body in a tick, past the band, at most.
const REACH: f32 = 0.03;

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
    /// m: points kept this far off his body's triangles.
    pub body_thickness: f32,
    /// m: within this of his body a point's side is taken and kept; farther, forgotten.
    pub body_band: f32,
    pub body_friction_static: f32,
    pub body_friction_kinetic: f32,
    /// His body is closed and its front is out (a man's skin): every point near it belongs on its
    /// front, whatever it was nearest when it came near (where his skin meets the cloth's own start,
    /// that side is a coin toss). Only a crossing from front to back is put back. False: each point's
    /// own side, tracked (a sheet, a two-sided body).
    pub body_front_only: bool,
    /// His body is met every this many substeps (and always on a tick's last), each time over the
    /// whole move since the last (the crossing test spans them, so nothing slips through between).
    pub body_every: u32,
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
            body_thickness: 0.001,
            body_band: 0.01,
            body_friction_static: 0.3,
            body_friction_kinetic: 0.2,
            body_front_only: false,
            body_every: 1,
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
    /// His body (the collider) and, per point, the side of it the point is on (+1 its front, −1 its
    /// back, 0 not near it).
    pub body: Body,
    pub side: Vec<i8>,
}

/// The wearer's skin as the cloth's collider: triangles of points the caller moves each tick.
#[derive(Clone, Debug, Default)]
pub struct Body {
    pub tris: Vec<[u32; 3]>,
    /// Per triangle, which of its edges (bit k: points k and k+1) no other triangle shares: an open
    /// end of his mesh (a sleeve's end), where a point past it has no side.
    open: Vec<u8>,
    /// Its points at the tick's start and where the caller has put them for its end.
    from: Vec<V3>,
    to: Vec<V3>,
    /// Its points at this substep's start and end, and its near triangles' normals then.
    before: Vec<V3>,
    now: Vec<V3>,
    /// Its near triangles' planes then (unit normal and offset: n·x = d on it), packed so a triangle
    /// too far from a point costs two loads and a dot product.
    p_before: Vec<[f32; 4]>,
    p_now: Vec<[f32; 4]>,
    /// The triangles near the free cloth this tick, and their points (the rest aren't posed or
    /// looked at).
    keep: Vec<bool>,
    used: Vec<bool>,
    /// The fraction of the tick at its last meeting, and each point's place then.
    at_f: f32,
    since: Vec<V3>,
    /// Each free point's triangles near enough to meet this tick (`cand[cand_at[i]..cand_at[i+1]]`).
    cand_at: Vec<u32>,
    cand: Vec<u32>,
    /// The spatial hash (Teschner et al. 2003): each bucket's triangles, `entries[start[k]..start[k+1]]`.
    start: Vec<u32>,
    entries: Vec<u32>,
    cell: f32,
    lo: Vec<V3>,
    hi: Vec<V3>,
    stamp: Vec<u32>,
    stamp_now: u32,
    /// Measures: points touching it at the last substep's end; crossings caught (a point that would
    /// have gone through in one substep, put back), since it was set.
    pub contacts: u32,
    pub crossings: u64,
    /// Points left between two faces of him that face each other (a pinch), since it was set.
    pub pinches: u64,
    /// Per point, what the last substep did with it (for the probes): 0 far from him, 1 a crossing
    /// put back, 2 pushed out, 3 a pinch (left), 4 past an open end, 5 near and clear.
    pub last: Vec<u8>,
    /// Each point's nearest triangle at its last check (u32::MAX none): looked at first, so the rest
    /// are mostly passed over by their planes.
    near_tri: Vec<u32>,
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
        c.side = vec![0; n];
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
        let body_on = !self.body.tris.is_empty();
        let every = self.t.body_every.max(1);
        if body_on {
            self.body_candidates(dt);
            self.body.at_f = 0.0;
            self.body.since.clear();
            self.body.since.extend_from_slice(&self.x);
        }
        let mut last_meet = 0u32;
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
            if body_on && ((s + 1) % every == 0 || s + 1 == n_sub) {
                let at = self.body.at_f;
                self.body.pose(at, f, at == 0.0);
                self.collide_body(&mut prev, s + 1 - last_meet, s + 1 == n_sub);
                last_meet = s + 1;
                self.body.at_f = f;
                self.body.since.copy_from_slice(&self.x);
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
        if body_on {
            let b = &mut self.body;
            b.from.copy_from_slice(&b.to);
        }
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


    // --- His body (the collider) ---

    /// His body: `points` (world, now) and `tris` (every three an index of `points`). Replaces any
    /// before; every point's side forgotten. False (and none) if an index is out of range.
    pub fn set_body(&mut self, points: &[V3], tris: &[u32]) -> bool {
        self.body = Body::default();
        for s in self.side.iter_mut() {
            *s = 0;
        }
        if tris.len() % 3 != 0 || tris.iter().any(|&i| i as usize >= points.len()) {
            return false;
        }
        let b = &mut self.body;
        b.tris = tris.chunks(3).filter(|t| t[0] != t[1] && t[1] != t[2] && t[0] != t[2]).map(|t| [t[0], t[1], t[2]]).collect();
        b.from = points.to_vec();
        b.to = points.to_vec();
        b.before = points.to_vec();
        b.now = points.to_vec();
        b.stamp = vec![0; b.tris.len()];
        let mut half: Vec<(u32, u32, usize, u8)> = Vec::with_capacity(b.tris.len() * 3);
        for (ti, t) in b.tris.iter().enumerate() {
            for k in 0..3 {
                let (p, q) = (t[k], t[(k + 1) % 3]);
                half.push((p.min(q), p.max(q), ti, k as u8));
            }
        }
        half.sort_unstable();
        b.open = vec![0; b.tris.len()];
        let mut i = 0;
        while i < half.len() {
            let mut j = i + 1;
            while j < half.len() && half[j].0 == half[i].0 && half[j].1 == half[i].1 {
                j += 1;
            }
            if j - i == 1 {
                b.open[half[i].2] |= 1 << half[i].3;
            }
            i = j;
        }
        // Cells about two of its triangles' edges across (and never under twice the band), so a
        // point's looked-up cells hold its near triangles and few more.
        let mut sum = 0.0f32;
        for t in &b.tris {
            sum += len(sub(points[t[0] as usize], points[t[1] as usize]));
        }
        let mean = if b.tris.is_empty() { 0.02 } else { sum / b.tris.len() as f32 };
        b.cell = (2.0 * mean).max(2.0 * self.t.body_band).max(1e-3);
        true
    }

    /// His body's points at the end of the next step (as the pins: it moves there evenly). Ignored if
    /// the count isn't his body's.
    pub fn move_body(&mut self, points: &[V3]) {
        if points.len() == self.body.to.len() {
            self.body.to.copy_from_slice(points);
        }
    }

    /// No body from now on.
    pub fn clear_body(&mut self) {
        self.body = Body::default();
        for s in self.side.iter_mut() {
            *s = 0;
        }
    }

    /// Once a tick: the triangles (where they are over the whole tick) hashed into cells, and each free
    /// point's near ones (within the band and its move this tick) listed.
    fn body_candidates(&mut self, dt: f32) {
        let n = self.x.len();
        let band = self.t.body_band.max(self.t.body_thickness);
        let b = &mut self.body;
        let nt = b.tris.len();
        b.lo.resize(nt, [0.0; 3]);
        b.hi.resize(nt, [0.0; 3]);
        // The free cloth's box over the tick: only triangles near it are hashed.
        let mut clo = [f32::MAX; 3];
        let mut chi = [f32::MIN; 3];
        let mut reach = vec![0.0f32; 0];
        reach.resize(n, 0.0);
        let mut any = false;
        for i in 0..n {
            if self.pinned[i] {
                continue;
            }
            any = true;
            // Its reach this tick: the band, twice its move at its speed now, and 5 mm (a pull can
            // speed it up within the tick).
            // (At most REACH: a point flying faster is far from him or soon will be, and a big reach
            // walks many cells.)
            let r = (band + 2.0 * len(self.v[i]) * dt + 0.002).min(band + REACH);
            reach[i] = r;
            for k in 0..3 {
                clo[k] = clo[k].min(self.x[i][k] - r);
                chi[k] = chi[k].max(self.x[i][k] + r);
            }
        }
        b.cand_at.clear();
        b.cand.clear();
        b.cand_at.push(0);
        b.keep.clear();
        b.keep.resize(nt, false);
        b.used.clear();
        b.used.resize(b.from.len(), false);
        if !any {
            b.cand_at.resize(n + 1, 0);
            return;
        }
        let cell = b.cell;
        let size = (2 * nt).next_power_of_two().max(64);
        let keep = &mut b.keep;
        let mut count = vec![0u32; size + 1];
        for t in 0..nt {
            let tr = b.tris[t];
            let mut lo = [f32::MAX; 3];
            let mut hi = [f32::MIN; 3];
            for &v in &tr {
                for p in [b.from[v as usize], b.to[v as usize]] {
                    for k in 0..3 {
                        lo[k] = lo[k].min(p[k]);
                        hi[k] = hi[k].max(p[k]);
                    }
                }
            }
            b.lo[t] = lo;
            b.hi[t] = hi;
            keep[t] = (0..3).all(|k| lo[k] <= chi[k] && hi[k] >= clo[k]);
            if keep[t] {
                for_cells(lo, hi, cell, |key| count[hash(key, size)] += 1);
            }
        }
        // Counting sort into buckets (fixed order: the same input, the same lists).
        b.start.clear();
        b.start.resize(size + 1, 0);
        let mut acc = 0u32;
        for k in 0..size {
            b.start[k] = acc;
            acc += count[k];
        }
        b.start[size] = acc;
        b.entries.clear();
        b.entries.resize(acc as usize, 0);
        let mut fill: Vec<u32> = b.start[..size].to_vec();
        for t in 0..nt {
            if b.keep[t] {
                for &v in &b.tris[t] {
                    b.used[v as usize] = true;
                }
                let (lo, hi) = (b.lo[t], b.hi[t]);
                let entries = &mut b.entries;
                for_cells(lo, hi, cell, |key| {
                    let h = hash(key, size);
                    entries[fill[h] as usize] = t as u32;
                    fill[h] += 1;
                });
            }
        }
        // Each free point's triangles: those in the cells its reach covers whose box is within it.
        for i in 0..n {
            if !self.pinned[i] {
                let r = reach[i];
                let p = self.x[i];
                let plo = [p[0] - r, p[1] - r, p[2] - r];
                let phi = [p[0] + r, p[1] + r, p[2] + r];
                b.stamp_now = b.stamp_now.wrapping_add(1);
                if b.stamp_now == 0 {
                    b.stamp.iter_mut().for_each(|s| *s = 0);
                    b.stamp_now = 1;
                }
                let (start, entries, stamp, lo, hi, cand) = (&b.start, &b.entries, &mut b.stamp, &b.lo, &b.hi, &mut b.cand);
                let now = b.stamp_now;
                for_cells(plo, phi, cell, |key| {
                    let h = hash(key, size);
                    for e in start[h]..start[h + 1] {
                        let t = entries[e as usize] as usize;
                        if stamp[t] == now {
                            continue;
                        }
                        stamp[t] = now;
                        if (0..3).all(|k| lo[t][k] <= phi[k] && hi[t][k] >= plo[k]) {
                            cand.push(t as u32);
                        }
                    }
                });
            }
            b.cand_at.push(b.cand.len() as u32);
        }
    }

    /// Each free point against his body, at the substep's end: kept `body_thickness` off the nearest
    /// triangle on its own side, a crossing within the substep put back, friction on its move along
    /// him relative to his skin's move.
    fn collide_body(&mut self, prev: &mut [V3], subs: u32, count: bool) {
        let th = self.t.body_thickness;
        let band = self.t.body_band.max(th);
        let (mu_s, mu_k) = (self.t.body_friction_static, self.t.body_friction_kinetic);
        let front_only = self.t.body_front_only;
        let mut contacts = 0u32;
        let b = &mut self.body;
        b.last.resize(self.x.len(), 0);
        b.near_tri.resize(self.x.len(), u32::MAX);
        for i in 0..self.x.len() {
            b.last[i] = 0;
            if self.pinned[i] {
                continue;
            }
            let (s0, s1) = (b.cand_at[i] as usize, b.cand_at[i + 1] as usize);
            if s0 == s1 {
                self.side[i] = 0;
                continue;
            }
            let x = self.x[i];
            // Its move since his body was last met (`subs` substeps).
            let p = b.since[i];
            // The nearest triangle now, and the earliest crossing of one within the substep.
            let mut best = f32::MAX;
            let mut bt = usize::MAX;
            let mut bq = [0.0f32; 3];
            let mut bbc = [0.0f32; 3];
            let mut cross_t = f32::MAX;
            let mut cross_tri = usize::MAX;
            let mut cross_sign = 0i8;
            // Faces near it (their normals, nearest points, and whether it's behind or touching each):
            // for a pinch.
            let mut near_n: [V3; 6] = [[0.0; 3]; 6];
            let mut near_q: [V3; 6] = [[0.0; 3]; 6];
            let mut near_in: [bool; 6] = [false; 6];
            let mut near = 0usize;
            // Its nearest last time first (moved to the front of its list): then most of the rest are
            // passed over by their planes.
            let first = b.near_tri[i];
            if first != u32::MAX {
                if let Some(f) = (s0..s1).find(|&k| b.cand[k] == first) {
                    b.cand.swap(s0, f);
                }
            }
            for k in s0..s1 {
                let t = b.cand[k] as usize;
                let tr = b.tris[t];
                let (a, bb, c) = (b.now[tr[0] as usize], b.now[tr[1] as usize], b.now[tr[2] as usize]);
                let pl = b.p_now[t];
                let n1 = [pl[0], pl[1], pl[2]];
                let sx = dot(x, n1) - pl[3];
                // A crossing: its start on one side of the triangle's plane as it was, its end on the
                // other as it is, through the triangle where they meet (Bridson et al. 2002's
                // continuous test, the triangle's plane moving linearly).
                let pb = b.p_before[t];
                let sp = dot(p, [pb[0], pb[1], pb[2]]) - pb[3];
                if (sp > 0.0 && sx < 0.0) || (sp < 0.0 && sx > 0.0) {
                    let u = sp / (sp - sx);
                    if u < cross_t {
                        let (a0, b0, c0) = (b.before[tr[0] as usize], b.before[tr[1] as usize], b.before[tr[2] as usize]);
                        let y = add(p, scale(sub(x, p), u));
                        let (ya, yb, yc) = (lerp(a0, a, u), lerp(b0, bb, u), lerp(c0, c, u));
                        let ybc = closest_on_tri(y, ya, yb, yc);
                        let yq = bary(ya, yb, yc, ybc);
                        // Through it (within its thickness of it where they meet).
                        if dot(sub(y, yq), sub(y, yq)) <= th * th && (!front_only || sp > 0.0) {
                            cross_t = u;
                            cross_tri = t;
                            cross_sign = if sp > 0.0 { 1 } else { -1 };
                        }
                    }
                }
                if sx.abs() > band {
                    continue;
                }
                // (For a pinch: every face within the band of it, by its plane: where it would meet it.)
                if near < 6 {
                    near_n[near] = n1;
                    near_q[near] = sub(x, scale(n1, sx));
                    near_in[near] = sx < th;
                    near += 1;
                }
                // Its distance to the triangle is at least to its plane: no nearer than the nearest yet,
                // no closer look.
                if sx * sx >= best {
                    continue;
                }
                let bc = closest_on_tri(x, a, bb, c);
                let q = bary(a, bb, c, bc);
                let d = dot(sub(x, q), sub(x, q));
                if d < best {
                    best = d;
                    bt = t;
                    bq = q;
                    bbc = bc;
                }
            }
            b.near_tri[i] = if bt == usize::MAX { u32::MAX } else { bt as u32 };
            if bt == usize::MAX && cross_tri == usize::MAX {
                self.side[i] = 0;
                continue;
            }
            // A pinch: two faces of him that face each other across a gap narrower than its thickness,
            // or overlapping a little (fingers pressed together: his skin's two sides meeting), and it's
            // behind or touching one. There's no room for it on either's front; it's left to the
            // cloth's own constraints, out of sight between them. (Two opposed faces of one solid, a
            // finger's two sides, face away from each other: not a pinch.)
            let mut pinch = false;
            for k in 0..near {
                for k2 in 0..k {
                    if (near_in[k] || near_in[k2])
                        && dot(near_n[k], near_n[k2]) < -0.3
                        && dot(sub(near_q[k2], near_q[k]), near_n[k]) > -PINCH_OVERLAP
                        && dot(sub(near_q[k], near_q[k2]), near_n[k2]) > -PINCH_OVERLAP
                        && len(sub(near_q[k], near_q[k2])) < 2.0 * th + PINCH_OVERLAP
                    {
                        pinch = true;
                    }
                }
            }
            if pinch {
                b.last[i] = 3;
                b.pinches += 1;
                continue;
            }
            let mut target: Option<(V3, V3, V3)> = None; // (where it goes, the triangle's normal, its point on him)
            if cross_tri != usize::MAX && (self.side[i] == 0 || self.side[i] == cross_sign) {
                // Through him in one substep: stopped where it met him, on the side it came from, and
                // the rest of its move kept along his skin there (at most the band a substep), so a
                // point pulled at a slant into him slides round him as cloth does.
                self.side[i] = cross_sign;
                b.crossings += 1;
                b.last[i] = 1;
                let tr = b.tris[cross_tri];
                let (a, bb, c) = (b.now[tr[0] as usize], b.now[tr[1] as usize], b.now[tr[2] as usize]);
                let n = face_normal(a, bb, c);
                let y = add(p, scale(sub(x, p), cross_t));
                let bc = closest_on_tri(y, a, bb, c);
                let q = bary(a, bb, c, bc);
                let rest = sub(x, y);
                let mut slide = sub(rest, scale(n, dot(rest, n)));
                let sl = len(slide);
                if sl > band {
                    slide = scale(slide, band / sl);
                }
                let sg = cross_sign as f32;
                target = Some((add(add(q, slide), scale(n, sg * th)), n, q));
                bbc = bc;
                bt = cross_tri;
            } else if best <= band * band {
                let tr = b.tris[bt];
                let (a, bb, c) = (b.now[tr[0] as usize], b.now[tr[1] as usize], b.now[tr[2] as usize]);
                let n = face_normal(a, bb, c);
                if front_only {
                    self.side[i] = 1;
                } else if self.side[i] == 0 {
                    // Its side: where it was at the substep's start, against the triangle as it was.
                    let (a0, b0, c0) = (b.before[tr[0] as usize], b.before[tr[1] as usize], b.before[tr[2] as usize]);
                    let sp = dot(sub(p, bary(a0, b0, c0, bbc)), face_normal(a0, b0, c0));
                    let sx = dot(sub(x, bq), n);
                    let s = if sp.abs() > 1e-7 { sp } else { sx };
                    self.side[i] = if s >= 0.0 { 1 } else { -1 };
                }
                let sg = self.side[i] as f32;
                let off = sub(x, bq);
                let h = dot(off, n) * sg;
                let d = best.sqrt();
                // Nearest an open end of his mesh: past it there's no side, only the distance.
                let o = b.open[bt];
                let at_end = (o & 1 != 0 && bbc[2] <= 1e-6) || (o & 2 != 0 && bbc[0] <= 1e-6) || (o & 4 != 0 && bbc[1] <= 1e-6);
                b.last[i] = 5;
                if at_end && h <= 0.0 {
                    b.last[i] = 4;
                    if d < th && d > 1e-9 {
                        target = Some((add(bq, scale(off, th / d)), n, bq));
                    }
                } else if d < th || h <= 0.0 {
                    b.last[i] = 2;
                    // Too near, or on the wrong side: out along the way from him if it's on its own
                    // side (round an edge too), else straight out of the face on its side.
                    let dir = if h > 0.0 && d > 1e-9 { scale(off, 1.0 / d) } else { scale(n, sg) };
                    target = Some((add(bq, scale(dir, th)), n, bq));
                } else if d < th * 1.5 {
                    contacts += 1;
                }
            } else {
                self.side[i] = 0;
            }
            if let Some((to, n, q)) = target {
                contacts += 1;
                let depth = len(sub(to, x));
                let mut y = to;
                // Friction on its move along him, less his skin's own move there.
                if mu_s > 0.0 || mu_k > 0.0 {
                    let tr = b.tris[bt];
                    let q0 = bary(b.before[tr[0] as usize], b.before[tr[1] as usize], b.before[tr[2] as usize], bbc);
                    let rel = sub(sub(y, p), sub(q, q0));
                    let tang = sub(rel, scale(n, dot(rel, n)));
                    let m = len(tang);
                    if m > 1e-12 {
                        if m < mu_s * depth {
                            y = sub(y, tang);
                        } else {
                            y = sub(y, scale(tang, (mu_k * depth / m).min(1.0)));
                        }
                    }
                }
                // No bounce: its speed along his skin's normal is his skin's own there (the push out
                // isn't kept as speed, or a point pushed out flies off him).
                let tr = b.tris[bt];
                let q0 = bary(b.before[tr[0] as usize], b.before[tr[1] as usize], b.before[tr[2] as usize], bbc);
                let extra = dot(sub(y, prev[i]), n) - dot(sub(q, q0), n) / subs as f32;
                prev[i] = add(prev[i], scale(n, extra));
                self.x[i] = y;
            }
        }
        if count {
            b.contacts = contacts;
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

    /// Per point, the normal of the triangles round it (area weighted), on the side Godot draws as
    /// the front: its triangles are clockwise seen from the front, so (c−a)×(b−a).
    pub fn normals(&self) -> Vec<V3> {
        let mut n = vec![[0.0f32; 3]; self.x.len()];
        for t in &self.tris {
            let (a, b, c) = (self.x[t[0] as usize], self.x[t[1] as usize], self.x[t[2] as usize]);
            let f = cross(sub(c, a), sub(b, a));
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

impl Body {
    /// Its points (those near triangles use) at fractions `f0` and `f1` of the tick (its last meeting
    /// and now), and its near triangles' planes. A meeting's start is the last one's end, the same
    /// floats: kept, not redone.
    fn pose(&mut self, f0: f32, f1: f32, first: bool) {
        let nt = self.tris.len();
        self.p_before.resize(nt, [0.0, 1.0, 0.0, 0.0]);
        self.p_now.resize(nt, [0.0, 1.0, 0.0, 0.0]);
        if first {
            self.place(f0);
        }
        std::mem::swap(&mut self.before, &mut self.now);
        std::mem::swap(&mut self.p_before, &mut self.p_now);
        self.place(f1);
    }

    fn place(&mut self, f: f32) {
        for k in 0..self.from.len() {
            if self.used[k] {
                self.now[k] = lerp(self.from[k], self.to[k], f);
            }
        }
        for t in 0..self.tris.len() {
            if self.keep[t] {
                let tr = self.tris[t];
                let a = self.now[tr[0] as usize];
                let n = face_normal(a, self.now[tr[1] as usize], self.now[tr[2] as usize]);
                self.p_now[t] = [n[0], n[1], n[2], dot(n, a)];
            }
        }
    }

    /// Where it is now (for the tests and the face).
    pub fn points(&self) -> &[V3] {
        &self.now
    }
}

#[inline]
fn lerp(a: V3, b: V3, f: f32) -> V3 {
    add(a, scale(sub(b, a), f))
}

#[inline]
fn bary(a: V3, b: V3, c: V3, w: V3) -> V3 {
    add(add(scale(a, w[0]), scale(b, w[1])), scale(c, w[2]))
}

/// A triangle's unit normal on Godot's front (clockwise seen from the front: (c−a)×(b−a)).
#[inline]
fn face_normal(a: V3, b: V3, c: V3) -> V3 {
    let f = cross(sub(c, a), sub(b, a));
    let l = len(f);
    if l > 1e-12 {
        scale(f, 1.0 / l)
    } else {
        [0.0, 1.0, 0.0]
    }
}

/// Barycentric weights of the point on triangle a, b, c nearest `p` (the regions as in Ericson,
/// "Real-Time Collision Detection", 5.1.5).
fn closest_on_tri(p: V3, a: V3, b: V3, c: V3) -> V3 {
    let ab = sub(b, a);
    let ac = sub(c, a);
    let ap = sub(p, a);
    let d1 = dot(ab, ap);
    let d2 = dot(ac, ap);
    if d1 <= 0.0 && d2 <= 0.0 {
        return [1.0, 0.0, 0.0];
    }
    let bp = sub(p, b);
    let d3 = dot(ab, bp);
    let d4 = dot(ac, bp);
    if d3 >= 0.0 && d4 <= d3 {
        return [0.0, 1.0, 0.0];
    }
    let vc = d1 * d4 - d3 * d2;
    if vc <= 0.0 && d1 >= 0.0 && d3 <= 0.0 {
        let v = d1 / (d1 - d3);
        return [1.0 - v, v, 0.0];
    }
    let cp = sub(p, c);
    let d5 = dot(ab, cp);
    let d6 = dot(ac, cp);
    if d6 >= 0.0 && d5 <= d6 {
        return [0.0, 0.0, 1.0];
    }
    let vb = d5 * d2 - d1 * d6;
    if vb <= 0.0 && d2 >= 0.0 && d6 <= 0.0 {
        let w = d2 / (d2 - d6);
        return [1.0 - w, 0.0, w];
    }
    let va = d3 * d6 - d5 * d4;
    if va <= 0.0 && (d4 - d3) >= 0.0 && (d5 - d6) >= 0.0 {
        let w = (d4 - d3) / ((d4 - d3) + (d5 - d6));
        return [0.0, 1.0 - w, w];
    }
    let denom = 1.0 / (va + vb + vc);
    let v = vb * denom;
    let w = vc * denom;
    [1.0 - v - w, v, w]
}

/// A cell's bucket (Teschner et al. 2003's hash of the cell's three indices by large primes).
#[inline]
fn hash(key: [i32; 3], size: usize) -> usize {
    let h = (key[0].wrapping_mul(73_856_093) ^ key[1].wrapping_mul(19_349_663) ^ key[2].wrapping_mul(83_492_791)) as u32;
    (h as usize) & (size - 1)
}

/// Every cell the box lo..hi touches, in a fixed order.
#[inline]
fn for_cells(lo: V3, hi: V3, cell: f32, mut f: impl FnMut([i32; 3])) {
    let a = [(lo[0] / cell).floor() as i32, (lo[1] / cell).floor() as i32, (lo[2] / cell).floor() as i32];
    let z = [(hi[0] / cell).floor() as i32, (hi[1] / cell).floor() as i32, (hi[2] / cell).floor() as i32];
    // (A box far larger than the cells, a huge triangle, still a bounded walk.)
    if (z[0] - a[0]) as i64 * (z[1] - a[1]) as i64 * (z[2] - a[2]) as i64 > 1 << 20 {
        return;
    }
    for i in a[0]..=z[0] {
        for j in a[1]..=z[1] {
            for k in a[2]..=z[2] {
                f([i, j, k]);
            }
        }
    }
}

/// A sheet `cols`×`rows` points, `w`×`d` m, lying flat at height `y` (x across, z along), its
/// triangles' diagonals alternating, its front up (Godot's winding). For the tests.
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
                tris.extend_from_slice(&[a, b, cc, b, dd, cc]);
            } else {
                tris.extend_from_slice(&[a, dd, cc, a, b, dd]);
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
    fn a_sheets_front_is_up() {
        let (p, tr) = sheet(4, 4, 0.3, 0.3, 0.0);
        let c = Cloth::build(&p, &tr, 0.2, Tuning::default()).unwrap();
        assert!(c.normals().iter().all(|n| n[1] > 0.99), "{:?}", c.normals()[0]);
    }

    /// A tube along Y through `ys`, `around` points a ring at radius `r(y)` (its front out).
    fn tube(around: usize, ys: &[f32], r: impl Fn(f32) -> f32) -> (Vec<V3>, Vec<u32>) {
        let mut pts = Vec::new();
        for &y in ys {
            for i in 0..around {
                let a = i as f32 / around as f32 * std::f32::consts::TAU;
                pts.push([r(y) * a.cos(), y, r(y) * a.sin()]);
            }
        }
        let mut tris = Vec::new();
        for j in 0..ys.len() - 1 {
            for i in 0..around {
                let (a, b) = ((j * around + i) as u32, (j * around + (i + 1) % around) as u32);
                let (c, d) = (a + around as u32, b + around as u32);
                tris.extend_from_slice(&[a, b, c, b, d, c]);
            }
        }
        (pts, tris)
    }

    /// The deepest of the free points from `from` on behind the nearest of his body's triangles (m;
    /// 0 if none is).
    fn under_body(c: &Cloth, from: usize, y0: f32, y1: f32) -> f32 {
        let b = &c.body;
        let mut worst = 0.0f32;
        for i in from..c.len() {
            let x = c.x[i];
            if x[1] < y0 || x[1] > y1 {
                continue;
            }
            let mut best = f32::MAX;
            let mut h = 0.0;
            for t in &b.tris {
                let (a, bb, cc) = (b.now[t[0] as usize], b.now[t[1] as usize], b.now[t[2] as usize]);
                let q = bary(a, bb, cc, closest_on_tri(x, a, bb, cc));
                let d = len(sub(x, q));
                if d < best {
                    best = d;
                    h = dot(sub(x, q), face_normal(a, bb, cc));
                }
            }
            if h < 0.0 {
                worst = worst.max(-h);
            }
        }
        worst
    }

    /// A big triangle in the plane y = 0 (front up) as his body.
    fn floor_tri() -> (Vec<V3>, Vec<u32>) {
        (vec![[-1.0, 0.0, -1.0], [1.0, 0.0, -1.0], [0.0, 0.0, 1.5]], vec![0, 1, 2])
    }

    #[test]
    fn a_tubes_front_is_out() {
        let (p, t) = tube(12, &[0.0, 0.1, 0.2], |_| 0.05);
        let c = Cloth::build(&p, &t, 0.2, Tuning::default()).unwrap();
        for (i, n) in c.normals().iter().enumerate() {
            let out = [p[i][0], 0.0, p[i][2]];
            assert!(dot(*n, out) > 0.0, "point {i}: {:?}", n);
        }
    }

    #[test]
    fn a_point_pulled_fast_across_his_skin_stays_on_its_side() {
        let (bp, bt) = floor_tri();
        let (p, tr) = sheet(4, 4, 0.1, 0.1, 0.004);
        let t = Tuning { floor_on: false, gravity: [0.0; 3], substeps: 12, ..Default::default() };
        let mut c = Cloth::build(&p, &tr, 0.2, t).unwrap();
        assert!(c.set_body(&bp, &bt));
        c.pin(0, true);
        // The pin dragged 30 cm through his skin in one tick (18 m/s), then held there.
        let mut least = f32::MAX;
        for k in 0..60 {
            if k == 1 {
                c.move_pin(0, [-0.05, -0.3, -0.05]);
            }
            c.step(1.0 / 60.0);
            for i in 1..c.len() {
                least = least.min(c.x[i][1]);
            }
        }
        assert!(least >= 0.001 - 1e-5, "a free point under his skin: {least}");
        assert!(c.side[1..].iter().all(|&s| s >= 0), "{:?}", c.side);
        assert!(c.x.iter().all(|p| p.iter().all(|v| v.is_finite())));
    }

    #[test]
    fn a_point_thrown_through_his_skin_in_one_substep_is_put_back() {
        let (bp, bt) = floor_tri();
        let (p, tr) = sheet(4, 4, 0.1, 0.1, 0.004);
        let t = Tuning { floor_on: false, gravity: [0.0; 3], substeps: 4, ..Default::default() };
        let mut c = Cloth::build(&p, &tr, 0.2, t).unwrap();
        c.set_body(&bp, &bt);
        c.add_velocity([0.0, -40.0, 0.0]); // 17 cm a substep: past the band in one
        for _ in 0..30 {
            c.step(1.0 / 60.0);
            assert!(c.lowest_y() >= 0.001 - 1e-5, "through: {}", c.lowest_y());
        }
        assert!(c.body.crossings > 0, "caught as crossings");
        // And from below it stays below (its side is the one it came from).
        let (p2, _) = sheet(4, 4, 0.1, 0.1, -0.004);
        let mut c2 = Cloth::build(&p2, &tr, 0.2, Tuning { floor_on: false, gravity: [0.0; 3], ..Default::default() }).unwrap();
        c2.set_body(&bp, &bt);
        c2.add_velocity([0.0, 40.0, 0.0]);
        for _ in 0..30 {
            c2.step(1.0 / 60.0);
        }
        assert!(c2.x.iter().all(|p| p[1] <= -0.001 + 1e-5), "below stays below");
    }

    #[test]
    fn a_sleeve_drawn_past_a_bulge_gives_by_its_strain_limit_not_through() {
        // His arm: radius 25 mm, a hand-like bulge of 28.5 mm at y 0.11-0.15, from y 0.05 up.
        let bump = |y: f32| {
            let s = |e0: f32, e1: f32, x: f32| {
                let u = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
                u * u * (3.0 - 2.0 * u)
            };
            0.025 + 0.0035 * s(0.07, 0.11, y) * (1.0 - s(0.15, 0.19, y))
        };
        let ys: Vec<f32> = (0..=40).map(|k| 0.05 + 0.01 * k as f32).collect();
        let (bp, bt) = tube(16, &ys, bump);
        // The sleeve: 3 mm over him, its narrow part (31 mm less than the bulge's 32.5 needed) above
        // the bulge, its end ring (pinned: the fingertips' hold) past his arm's end.
        let sy: Vec<f32> = (0..=33).map(|k| 0.02 + 0.01 * k as f32).collect();
        let sr = |y: f32| if y < 0.19 { bump(y.max(0.05)) + 0.003 } else { 0.028 };
        let (sp, st) = tube(16, &sy, sr);
        let t = Tuning {
            floor_on: false, gravity: [0.0; 3], max_strain: 1.08, stretch_compliance: 1e-6,
            bend_stiffness: 1e-5, substeps: 20, damping: 2.0,
            // (A tight hoop presses hard: at the default friction it holds, as a tight cuff does.)
            body_friction_static: 0.05, body_friction_kinetic: 0.03, ..Default::default()
        };
        let mut c = Cloth::build(&sp, &st, 0.3, t).unwrap();
        c.set_body(&bp, &bt);
        let ring: Vec<usize> = (0..16).collect();
        for &i in &ring {
            c.pin(i, true);
        }
        // How far the deepest free point is behind his skin (its faces as posed, by their normals).
        // (Only along his arm: past its open ends the nearest face is the end ring's, its side moot.)
        let inside = |c: &Cloth| under_body(c, 16, 0.06, 0.44);
        let (mut worst_in, mut worst_strain, mut widest) = (0.0f32, 0.0f32, 0.0f32);
        let mut over = 0;
        // The narrow part's points (rest radius 28 mm).
        let narrow: Vec<usize> = (0..sp.len()).filter(|&i| sp[i][1] >= 0.195).collect();
        let ticks = 120;
        for k in 1..=ticks + 60 {
            let u = (k as f32 / ticks as f32).min(1.0);
            for &i in &ring {
                c.move_pin(i, [sp[i][0], sp[i][1] - 0.45 * u, sp[i][2]]);
            }
            c.step(1.0 / 60.0);
            worst_in = worst_in.max(inside(&c));
            worst_strain = worst_strain.max(c.max_strain_now());
            if c.max_strain_now() > 1.08 * 1.05 {
                over += 1;
            }
            for &i in &narrow {
                let p = c.x[i];
                if p[1] > 0.12 && p[1] < 0.14 {
                    widest = widest.max((p[0] * p[0] + p[2] * p[2]).sqrt());
                }
            }
        }
        assert!(worst_in <= 2e-4, "a point inside his arm by {worst_in}");
        assert!(widest > 0.0285, "its narrow part (28 mm) widened over the bulge (28.5), not through it: {widest}");
        // Within it but a few per cent over, and for a tick or two more (as a landing: the collider
        // comes last in a substep, and a point that slips off the bulge's flank snaps its edges).
        assert!(over <= 3 && worst_strain < 1.25, "within its strain limit: {over} ticks over, worst {worst_strain}");
        let top = c.x.iter().fold(f32::MIN, |m, p| m.max(p[1]));
        assert!(top < 0.11, "drawn off past the bulge: its top at {top}");
        assert!(c.side.iter().all(|&s| s >= 0), "never on his inside");
    }

    #[test]
    fn on_a_closed_body_every_point_ends_on_its_front() {
        // A point that starts just behind his skin (a fold where the cloth's start and his skin meet)
        // goes out to the front; one tracked by its own side would stay behind.
        let (bp, bt) = floor_tri();
        let (p, tr) = sheet(4, 4, 0.1, 0.1, -0.0005);
        let t = Tuning { floor_on: false, gravity: [0.0; 3], body_front_only: true, ..Default::default() };
        let mut c = Cloth::build(&p, &tr, 0.2, t).unwrap();
        c.set_body(&bp, &bt);
        for _ in 0..10 {
            c.step(1.0 / 60.0);
        }
        assert!(c.lowest_y() >= 0.001 - 1e-5, "{}", c.lowest_y());
        assert!(c.side.iter().all(|&s| s == 1), "{:?}", c.side);
    }

    #[test]
    fn a_point_pinched_between_two_of_his_faces_is_left_to_the_cloth() {
        // Two faces 1 mm apart facing each other (fingers pressed together): no room on either's
        // front. A sheet across the gap, pulled along it by a pin, slides out instead of sticking.
        let bp = vec![[-1.0, 0.0, -1.0], [1.0, 0.0, -1.0], [0.0, 0.0, 1.5], [-1.0, 0.001, -1.0], [1.0, 0.001, -1.0], [0.0, 0.001, 1.5]];
        let bt = vec![0, 1, 2, 3, 5, 4]; // the lower one's front up, the upper one's down
        let (p, tr) = sheet(5, 5, 0.1, 0.1, 0.0005);
        let t = Tuning { floor_on: false, gravity: [0.0; 3], body_front_only: true, ..Default::default() };
        let mut c = Cloth::build(&p, &tr, 0.2, t).unwrap();
        c.set_body(&bp, &bt);
        c.pin(0, true);
        for k in 1..=60 {
            c.move_pin(0, [p[0][0] - 0.003 * k as f32, p[0][1], p[0][2]]);
            c.step(1.0 / 60.0);
        }
        assert!(c.body.pinches > 0);
        assert!(c.max_strain_now() < 1.08 * 1.02, "it follows its pin: {}", c.max_strain_now());
    }

    /// The cost of a sleeve drawn over his arm (`cargo test --release -- --ignored --nocapture cost`).
    #[test]
    #[ignore]
    fn cost_of_a_sleeve_on_his_arm() {
        let ys: Vec<f32> = (0..=40).map(|k| 0.05 + 0.01 * k as f32).collect();
        let (bp, bt) = tube(24, &ys, |_| 0.025);
        let sy: Vec<f32> = (0..=20).map(|k| 0.02 + 0.015 * k as f32).collect();
        let (sp, st) = tube(18, &sy, |_| 0.0265);
        let env = |k: &str, d: f32| std::env::var(k).ok().and_then(|v| v.parse().ok()).unwrap_or(d);
        let t = Tuning {
            floor_on: false, max_strain: 1.05, substeps: 20, body_thickness: 0.0007, body_front_only: true,
            body_band: env("BAND", 0.004), body_every: env("EVERY", 2.0) as u32, ..Default::default()
        };
        let mut c = Cloth::build(&sp, &st, 0.3, t).unwrap();
        if std::env::var("NO_BODY").is_err() {
            c.set_body(&bp, &bt);
        }
        for i in 0..18 {
            c.pin(i, true);
        }
        let t0 = std::time::Instant::now();
        let mut cands = 0usize;
        for k in 1..=120 {
            for i in 0..18 {
                c.move_pin(i, [sp[i][0], sp[i][1] - 0.002 * k as f32, sp[i][2]]);
            }
            c.step(1.0 / 60.0);
            cands += c.body.cand.len();
        }
        let ms = t0.elapsed().as_secs_f64() * 1000.0 / 120.0;
        eprintln!("{} points, {} body tris: {ms:.3} ms a tick, {:.1} candidates a point", c.len(), bt.len() / 3, cands as f64 / 120.0 / c.len() as f64);
    }

    #[test]
    fn with_his_body_the_same_start_gives_the_same_bits() {
        let go = || {
            let ys: Vec<f32> = (0..=10).map(|k| 0.03 * k as f32).collect();
            let (bp, bt) = tube(12, &ys, |_| 0.04);
            let (p, tr) = sheet(10, 10, 0.3, 0.3, 0.4);
            let mut c = Cloth::build(&p, &tr, 0.2, Tuning::default()).unwrap();
            c.set_body(&bp, &bt);
            c.jitter(9, 1e-3);
            for k in 0..120 {
                let moved: Vec<V3> = bp.iter().map(|q| [q[0] + 0.001 * k as f32, q[1], q[2]]).collect();
                c.move_body(&moved);
                c.step(1.0 / 60.0);
            }
            c.x
        };
        assert_eq!(go(), go());
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
