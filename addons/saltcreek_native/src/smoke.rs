//! `SmokeGrid`: smoke round a fire as a box of cells (docs/briefs/smoke.md). Not a fluid solver:
//! the few things smoke does round buildings, as rules on cells. Hot smoke rises into the cell
//! above while there's room in it (a cell holds `cap`), so a room fills from the ceiling down;
//! smoke that can't rise (a roof over it, or the cell above full) runs sideways toward the nearest
//! way up (each cell knows how far it is from open sky or the box's edge, by a search made when
//! the solids are set), the ceiling jet, so it runs along the underside of an overhang to its edge
//! and up, and in a room gathers against the wall with the door until it's down to the lintel and
//! spills out under it; and it spreads under a ceiling faster than in open air; everything mixes
//! a little with its neighbours; cells open to the sky drift with the wind; smoke thins, faster in
//! the open, and leaves by the top and sides of the box. Blocked cells (members) take none.
//! Cells are x fastest, then y (up), then z: i = x + nx * (y + ny * z).

use crate::pool;
use godot::prelude::*;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{Arc, Mutex};

/// The grid behind Godot's handle. Stepped on a worker thread (`step_async`) so a burning town's
/// smoke costs the main thread nothing but queueing its sources and taking the last step's bytes.
#[derive(GodotClass)]
#[class(base = RefCounted, init)]
pub struct SmokeGrid {
    base: Base<RefCounted>,
    g: Arc<Mutex<Grid>>,
    /// Sources queued since the last step was handed off.
    pending: Vec<(usize, f32, f32)>,
    busy: Arc<AtomicBool>,
    /// The smoke as bytes after the last finished step, and how many steps have finished.
    latest: Arc<Mutex<Vec<u8>>>,
    steps: Arc<AtomicU64>,
}

#[derive(Default, Clone)]
pub struct Grid {
    pub nx: usize,
    pub ny: usize,
    pub nz: usize,
    /// Metres a cell.
    pub cell: f32,
    pub solid: Vec<u8>,
    /// Open to the sky: nothing solid in any cell above.
    pub sky: Vec<u8>,
    /// Cells to the nearest open sky or edge of the box, through cells that aren't solid.
    pub escape: Vec<u16>,
    pub smoke: Vec<f32>,
    pub heat: Vec<f32>,
    /// What the fire puts in this step, per second: (cell, smoke, heat).
    pub sources: Vec<(usize, f32, f32)>,
    pub t: Tuning,
    scratch: Vec<f32>,
    scratch_heat: Vec<f32>,
}

#[derive(Clone, Copy)]
pub struct Tuning {
    /// How much smoke a cell holds.
    pub cap: f32,
    /// Share of a cell's smoke that rises into the cell above a second, cold, and how much more
    /// for each unit of heat it carries.
    pub rise: f32,
    pub rise_hot: f32,
    /// Sideways mixing a second, everywhere, and under a ceiling (blocked or full above).
    pub mix: f32,
    pub ceiling_spread: f32,
    /// Share of a ceilinged cell's smoke that runs a cell toward the nearest way up, a second.
    pub jet: f32,
    /// Up-and-down mixing a second.
    pub mix_up: f32,
    /// Share of the smoke that thins away a second, indoors and open to the sky.
    pub fade: f32,
    pub fade_open: f32,
    /// Share of the heat lost a second.
    pub cool: f32,
}

impl Default for Tuning {
    fn default() -> Self {
        Tuning {
            cap: 1.0,
            rise: 1.6,
            rise_hot: 1.5,
            mix: 0.25,
            ceiling_spread: 0.8,
            jet: 2.5,
            mix_up: 0.08,
            fade: 0.01,
            fade_open: 0.12,
            cool: 0.25,
        }
    }
}

impl Grid {
    pub fn new(nx: usize, ny: usize, nz: usize, cell: f32) -> Grid {
        let n = nx * ny * nz;
        Grid {
            nx,
            ny,
            nz,
            cell,
            solid: vec![0; n],
            sky: vec![1; n],
            escape: vec![0; n],
            smoke: vec![0.0; n],
            heat: vec![0.0; n],
            sources: Vec::new(),
            t: Tuning::default(),
            scratch: vec![0.0; n],
            scratch_heat: vec![0.0; n],
        }
    }

    #[inline]
    pub fn idx(&self, x: usize, y: usize, z: usize) -> usize {
        x + self.nx * (y + self.ny * z)
    }

    pub fn len(&self) -> usize {
        self.nx * self.ny * self.nz
    }

    pub fn set_solid(&mut self, solid: &[u8]) {
        let n = self.len();
        self.solid.clear();
        self.solid.extend(solid.iter().take(n).map(|&b| (b != 0) as u8));
        self.solid.resize(n, 0);
        // A cell gone solid holds no smoke.
        for i in 0..n {
            if self.solid[i] != 0 {
                self.smoke[i] = 0.0;
                self.heat[i] = 0.0;
            }
        }
        // Open to the sky: walk each column down from the top.
        for z in 0..self.nz {
            for x in 0..self.nx {
                let mut open = 1u8;
                for y in (0..self.ny).rev() {
                    let i = self.idx(x, y, z);
                    if self.solid[i] != 0 {
                        open = 0;
                    }
                    self.sky[i] = open;
                }
            }
        }
        self.find_escapes();
    }

    /// How far each cell is from a way up: a breadth-first search out from every cell open to the
    /// sky and every cell on the box's sides and top, through cells that aren't solid.
    fn find_escapes(&mut self) {
        let (nx, ny, nz) = (self.nx, self.ny, self.nz);
        let n = self.len();
        self.escape = vec![u16::MAX; n];
        let mut queue = std::collections::VecDeque::new();
        for z in 0..nz {
            for y in 0..ny {
                for x in 0..nx {
                    let i = self.idx(x, y, z);
                    let edge = x == 0 || z == 0 || x + 1 == nx || z + 1 == nz || y + 1 == ny;
                    if self.solid[i] == 0 && (self.sky[i] != 0 || edge) {
                        self.escape[i] = 0;
                        queue.push_back((x, y, z));
                    }
                }
            }
        }
        while let Some((x, y, z)) = queue.pop_front() {
            let d = self.escape[self.idx(x, y, z)] + 1;
            let mut visit = |x: usize, y: usize, z: usize, g: &mut Grid| {
                let j = g.idx(x, y, z);
                if g.solid[j] == 0 && g.escape[j] > d {
                    g.escape[j] = d;
                    queue.push_back((x, y, z));
                }
            };
            if x > 0 { visit(x - 1, y, z, self); }
            if x + 1 < nx { visit(x + 1, y, z, self); }
            if y > 0 { visit(x, y - 1, z, self); }
            if y + 1 < ny { visit(x, y + 1, z, self); }
            if z > 0 { visit(x, y, z - 1, self); }
            if z + 1 < nz { visit(x, y, z + 1, self); }
        }
    }

    pub fn total(&self) -> f32 {
        self.smoke.iter().sum()
    }

    pub fn step(&mut self, dt: f32, wind_x: f32, wind_z: f32) {
        let (nx, ny, nz) = (self.nx, self.ny, self.nz);
        let n = self.len();
        if n == 0 {
            return;
        }
        let t = self.t;
        // 1. What the fire puts in.
        for &(i, s, h) in &self.sources {
            if i < n && self.solid[i] == 0 {
                self.smoke[i] += s * dt;
                self.heat[i] += h * dt;
            }
        }
        self.sources.clear();
        // 2. Rising, top row first, so smoke moves at most one cell a step. The top row loses what
        // would rise out of the box.
        let row = nx;
        let slab = nx * ny;
        for z in 0..nz {
            for y in (0..ny).rev() {
                for x in 0..nx {
                    let i = x + row * y + slab * z;
                    let s = self.smoke[i];
                    if s <= 1e-6 || self.solid[i] != 0 {
                        continue;
                    }
                    let share = ((t.rise + t.rise_hot * self.heat[i].min(2.0)) * dt).min(0.9);
                    if y + 1 == ny {
                        let gone = s * share;
                        self.smoke[i] -= gone;
                        continue;
                    }
                    let j = i + row;
                    if self.solid[j] != 0 {
                        continue;
                    }
                    let room = (t.cap - self.smoke[j]).max(0.0);
                    let moved = (s * share).min(room);
                    if moved <= 0.0 {
                        continue;
                    }
                    let carried = self.heat[i] * moved / s;
                    self.smoke[i] -= moved;
                    self.smoke[j] += moved;
                    self.heat[i] -= carried;
                    self.heat[j] += carried;
                }
            }
        }
        // 3. The ceiling jet: smoke that can't rise runs a cell sideways toward the nearest way up,
        // into the neighbour nearest it, while there's room there.
        let full_jet = 0.85 * t.cap;
        self.scratch.iter_mut().for_each(|v| *v = 0.0);
        self.scratch_heat.iter_mut().for_each(|v| *v = 0.0);
        let jet_share = (t.jet * dt).min(0.5);
        for z in 0..nz {
            for y in 0..ny {
                for x in 0..nx {
                    let i = x + row * y + slab * z;
                    let s = self.smoke[i];
                    if s <= 1e-6 || self.solid[i] != 0 || y + 1 >= ny {
                        continue;
                    }
                    let up = i + row;
                    if self.solid[up] == 0 && self.smoke[up] < full_jet {
                        continue; // it can still rise
                    }
                    let mut best = usize::MAX;
                    let mut best_d = self.escape[i];
                    for (ok, j) in [(x > 0, i.wrapping_sub(1)), (x + 1 < nx, i + 1), (z > 0, i.wrapping_sub(slab)), (z + 1 < nz, i + slab)] {
                        if ok && self.solid[j] == 0 && self.escape[j] < best_d {
                            best_d = self.escape[j];
                            best = j;
                        }
                    }
                    if best == usize::MAX {
                        continue;
                    }
                    let room = (t.cap - self.smoke[best] - self.scratch[best]).max(0.0);
                    let moved = (s * jet_share).min(room);
                    if moved <= 0.0 {
                        continue;
                    }
                    let carried = self.heat[i] * moved / s;
                    self.scratch[i] -= moved;
                    self.scratch[best] += moved;
                    self.scratch_heat[i] -= carried;
                    self.scratch_heat[best] += carried;
                }
            }
        }
        for i in 0..n {
            self.smoke[i] = (self.smoke[i] + self.scratch[i]).max(0.0);
            self.heat[i] = (self.heat[i] + self.scratch_heat[i]).max(0.0);
        }
        // 4. Mixing with neighbours: sideways (strong under a ceiling), and a little up and down.
        // Symmetric between pairs, so it moves smoke without making or losing any; the box's sides
        // are open air (smoke mixing out of them is gone).
        let full = 0.85 * t.cap;
        let ceiled = |g: &Grid, i: usize, y: usize| -> bool {
            y + 1 < g.ny && (g.solid[i + row] != 0 || g.smoke[i + row] >= full)
        };
        self.scratch.iter_mut().for_each(|v| *v = 0.0);
        self.scratch_heat.iter_mut().for_each(|v| *v = 0.0);
        let limit = 0.12; // a pair's share a step, at most (stable)
        for z in 0..nz {
            for y in 0..ny {
                for x in 0..nx {
                    let i = x + row * y + slab * z;
                    if self.solid[i] != 0 {
                        continue;
                    }
                    // Nothing here or in the neighbours it pairs with: nothing to mix.
                    if self.smoke[i] <= 1e-7
                        && self.heat[i] <= 1e-7
                        && (x + 1 >= nx || self.smoke[i + 1] <= 1e-7)
                        && (z + 1 >= nz || self.smoke[i + slab] <= 1e-7)
                        && (y + 1 >= ny || self.smoke[i + row] <= 1e-7)
                    {
                        continue;
                    }
                    let ci = ceiled(self, i, y);
                    // +x and +z neighbours (each pair once), and the box's -x/-z sides.
                    let pair = |j: Option<usize>, jy: usize, g: &mut Grid| {
                        let (sj, hj, cj) = match j {
                            Some(j) if g.solid[j] != 0 => return,
                            Some(j) => (g.smoke[j], g.heat[j], ceiled(g, j, jy)),
                            None => (0.0, 0.0, false),
                        };
                        let k = t.mix + if ci || cj { t.ceiling_spread } else { 0.0 };
                        let f = (k * dt).min(limit);
                        let ds = (g.smoke[i] - sj) * f;
                        let dh = (g.heat[i] - hj) * f;
                        g.scratch[i] -= ds;
                        g.scratch_heat[i] -= dh;
                        if let Some(j) = j {
                            g.scratch[j] += ds;
                            g.scratch_heat[j] += dh;
                        }
                    };
                    pair(if x + 1 < nx { Some(i + 1) } else { None }, y, self);
                    pair(if z + 1 < nz { Some(i + slab) } else { None }, y, self);
                    if x == 0 {
                        pair(None, y, self);
                    }
                    if z == 0 {
                        pair(None, y, self);
                    }
                    // Up and down, gently.
                    if y + 1 < ny && self.solid[i + row] == 0 {
                        let j = i + row;
                        let f = (t.mix_up * dt).min(limit);
                        let ds = (self.smoke[i] - self.smoke[j]) * f;
                        self.scratch[i] -= ds;
                        self.scratch[j] += ds;
                    }
                }
            }
        }
        for i in 0..n {
            self.smoke[i] = (self.smoke[i] + self.scratch[i]).max(0.0);
            self.heat[i] = (self.heat[i] + self.scratch_heat[i]).max(0.0);
        }
        // 5. The wind, in the open: each cell open to the sky hands a share downwind (upwind
        // differences, at most half a cell a step).
        let fx = (wind_x.abs() * dt / self.cell).min(0.5);
        let fz = (wind_z.abs() * dt / self.cell).min(0.5);
        if fx > 0.0 || fz > 0.0 {
            self.scratch.iter_mut().for_each(|v| *v = 0.0);
            for z in 0..nz {
                for y in 0..ny {
                    for x in 0..nx {
                        let i = x + row * y + slab * z;
                        let s = self.smoke[i];
                        if s <= 1e-6 || self.sky[i] == 0 || self.solid[i] != 0 {
                            continue;
                        }
                        for (f, step, at_edge) in [
                            (fx, if wind_x >= 0.0 { 1isize } else { -1 }, if wind_x >= 0.0 { x + 1 == nx } else { x == 0 }),
                            (fz, if wind_z >= 0.0 { slab as isize } else { -(slab as isize) }, if wind_z >= 0.0 { z + 1 == nz } else { z == 0 }),
                        ] {
                            if f <= 0.0 {
                                continue;
                            }
                            let moved = s * f;
                            self.scratch[i] -= moved;
                            if !at_edge {
                                let j = (i as isize + step) as usize;
                                if self.solid[j] == 0 {
                                    self.scratch[j] += moved;
                                } else {
                                    self.scratch[i] += moved; // against a wall: it stays
                                }
                            }
                        }
                    }
                }
            }
            for i in 0..n {
                self.smoke[i] = (self.smoke[i] + self.scratch[i]).max(0.0);
            }
        }
        // 6. Thinning and cooling.
        let keep_in = (1.0 - t.fade * dt).max(0.0);
        let keep_open = (1.0 - (t.fade + t.fade_open) * dt).max(0.0);
        let keep_heat = (1.0 - t.cool * dt).max(0.0);
        for i in 0..n {
            self.smoke[i] *= if self.sky[i] != 0 { keep_open } else { keep_in };
            self.heat[i] *= keep_heat;
        }
    }

    /// The smoke as bytes, 0 none to 255 a full cell, in cell order (slices of constant z), each
    /// share raised to `1 / gamma` (2.2 for a texture the renderer reads as a colour and takes back
    /// to linear: thin smoke was crushed to nothing; 1 as it is).
    pub fn bytes(&self, gamma: f32) -> Vec<u8> {
        let inv = 1.0 / self.t.cap.max(1e-6);
        let e = 1.0 / gamma.max(0.1);
        self.smoke
            .iter()
            .map(|&s| ((s * inv).clamp(0.0, 1.0).powf(e) * 255.0).round() as u8)
            .collect()
    }
}

#[godot_api]
impl SmokeGrid {
    /// A box of nx × ny × nz cells, `cell` metres a side, with no smoke and nothing solid.
    #[func]
    fn setup(&mut self, nx: i64, ny: i64, nz: i64, cell: f32) {
        let mut g = self.g.lock().unwrap();
        let t = g.t;
        *g = Grid::new(nx.max(1) as usize, ny.max(1) as usize, nz.max(1) as usize, cell.max(0.01));
        g.t = t;
        *self.latest.lock().unwrap() = vec![0; g.len()];
    }

    /// One byte a cell (non-zero = a member there), in cell order.
    #[func]
    fn set_solid(&mut self, solid: PackedByteArray) {
        self.g.lock().unwrap().set_solid(solid.as_slice());
    }

    /// Tuning by name: cap, rise, rise_hot, mix, ceiling_spread, jet, mix_up, fade, fade_open, cool.
    #[func]
    fn tune(&mut self, name: GString, value: f32) -> bool {
        let mut g = self.g.lock().unwrap();
        let t = &mut g.t;
        match name.to_string().as_str() {
            "cap" => t.cap = value,
            "rise" => t.rise = value,
            "rise_hot" => t.rise_hot = value,
            "mix" => t.mix = value,
            "ceiling_spread" => t.ceiling_spread = value,
            "jet" => t.jet = value,
            "mix_up" => t.mix_up = value,
            "fade" => t.fade = value,
            "fade_open" => t.fade_open = value,
            "cool" => t.cool = value,
            _ => return false,
        }
        true
    }

    /// Smoke and heat put into a cell in the next step, per second.
    #[func]
    fn emit(&mut self, cell: i64, smoke: f32, heat: f32) {
        if cell >= 0 {
            self.pending.push((cell as usize, smoke, heat));
        }
    }

    /// One step of `dt` seconds with the wind (m/s, world x and z: the box is laid square to
    /// them), here and now.
    #[func]
    fn step(&mut self, dt: f32, wind_x: f32, wind_z: f32) {
        let mut g = self.g.lock().unwrap();
        g.sources.append(&mut self.pending);
        g.step(dt, wind_x, wind_z);
        *self.latest.lock().unwrap() = g.bytes(1.0);
        self.steps.fetch_add(1, Ordering::SeqCst);
    }

    /// The same step on a worker thread; false (and nothing done) while the last is still
    /// running. `steps()` counts the finished ones; `latest_bytes()` is the newest's smoke.
    #[func]
    fn step_async(&mut self, dt: f32, wind_x: f32, wind_z: f32) -> bool {
        if self.busy.swap(true, Ordering::SeqCst) {
            return false;
        }
        let sources = std::mem::take(&mut self.pending);
        let (g, busy, latest, steps) = (self.g.clone(), self.busy.clone(), self.latest.clone(), self.steps.clone());
        pool::submit(move || {
            {
                let mut g = g.lock().unwrap();
                g.sources = sources;
                g.step(dt, wind_x, wind_z);
                let b = g.bytes(1.0);
                *latest.lock().unwrap() = b;
            }
            steps.fetch_add(1, Ordering::SeqCst);
            busy.store(false, Ordering::SeqCst);
        });
        true
    }

    #[func]
    fn is_busy(&self) -> bool {
        self.busy.load(Ordering::SeqCst)
    }

    #[func]
    fn steps(&self) -> i64 {
        self.steps.load(Ordering::SeqCst) as i64
    }

    #[func]
    fn density(&self, x: i64, y: i64, z: i64) -> f32 {
        let g = self.g.lock().unwrap();
        if x < 0 || y < 0 || z < 0 || x as usize >= g.nx || y as usize >= g.ny || z as usize >= g.nz {
            return 0.0;
        }
        g.smoke[g.idx(x as usize, y as usize, z as usize)]
    }

    #[func]
    fn total(&self) -> f32 {
        self.g.lock().unwrap().total()
    }

    /// The smoke as one byte a cell (0..255 of a full cell, each share raised to `1 / gamma`), in
    /// cell order: slice z is the bytes from nx*ny*z, rows of x from the bottom (y 0) up.
    #[func]
    fn bytes(&self, gamma: f32) -> PackedByteArray {
        PackedByteArray::from(self.g.lock().unwrap().bytes(gamma).as_slice())
    }

    /// The bytes after the newest finished step (no waiting on a running one).
    #[func]
    fn latest_bytes(&self) -> PackedByteArray {
        PackedByteArray::from(self.latest.lock().unwrap().as_slice())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A burning point at the bottom middle of a box, 5 m a side in 0.5 m cells.
    fn run(g: &mut Grid, seconds: f32, src: usize) {
        let dt = 1.0 / 15.0;
        let steps = (seconds / dt) as usize;
        for _ in 0..steps {
            g.sources.push((src, 3.0, 1.0));
            g.step(dt, 0.0, 0.0);
        }
    }

    fn sum_where(g: &Grid, f: impl Fn(usize, usize, usize) -> bool) -> f32 {
        let mut s = 0.0;
        for z in 0..g.nz {
            for y in 0..g.ny {
                for x in 0..g.nx {
                    if f(x, y, z) {
                        s += g.smoke[g.idx(x, y, z)];
                    }
                }
            }
        }
        s
    }

    #[test]
    fn in_the_open_it_goes_straight_up() {
        let mut g = Grid::new(11, 16, 11, 0.5);
        let src = g.idx(5, 0, 5);
        run(&mut g, 6.0, src);
        let over = sum_where(&g, |x, _, z| x.abs_diff(5) <= 1 && z.abs_diff(5) <= 1);
        assert!(over > 0.6 * g.total(), "the column holds most of it: {over} of {}", g.total());
        assert!(sum_where(&g, |_, y, _| y >= 8) > 0.1 * g.total(), "and it's climbed");
    }

    #[test]
    fn under_an_overhang_it_spreads_rolls_out_and_rises() {
        // A porch roof 2 m up (y 4) over x 0..=7, z 2..=8 (the fire under it at x 3, z 5), a wall
        // at x 0 (the building's front), open past the roof's edge and its ends.
        let (nx, ny, nz) = (16, 14, 11);
        let mut g = Grid::new(nx, ny, nz, 0.5);
        let mut solid = vec![0u8; nx * ny * nz];
        for z in 0..nz {
            for y in 0..ny {
                solid[g.idx(0, y, z)] = 1;
            }
        }
        for z in 2..=8 {
            for x in 0..=7 {
                solid[g.idx(x, 4, z)] = 1;
            }
        }
        g.set_solid(&solid);
        let src = g.idx(3, 0, 5);
        run(&mut g, 12.0, src);
        let porch = |x: usize, z: usize| x <= 7 && (2..=8).contains(&z);
        let under = sum_where(&g, |x, y, z| porch(x, z) && y < 4);
        // Just over the roof above the fire (the plume's own spread higher up is the open air's).
        let over_roof = sum_where(&g, |x, y, z| (1..=5).contains(&x) && (3..=7).contains(&z) && (5..=7).contains(&y));
        let climbed_out = sum_where(&g, |x, y, z| !porch(x, z) && y > 4);
        assert!(under > 0.0 && climbed_out > 0.0);
        assert!(climbed_out > 0.3 * g.total(), "it rolls out and climbs: {climbed_out} of {}", g.total());
        assert!(over_roof < 0.15 * climbed_out, "little over the roof itself: {over_roof} against {climbed_out}");
        // Under the roof it lies along the ceiling, not the floor.
        let ceiling = sum_where(&g, |x, y, z| porch(x, z) && y == 3);
        let floor = sum_where(&g, |x, y, z| porch(x, z) && x != 3 && y == 1);
        assert!(ceiling > 2.0 * floor, "a layer under the ceiling: {ceiling} against {floor} low down");
    }

    #[test]
    fn a_room_fills_from_the_ceiling_and_pours_out_of_the_door_top() {
        // A room x 1..=8, z 1..=6, floor y 0, walls to y 5, ceiling y 6; a door in the x 8 wall,
        // z 3..=4, from the floor to y 3 (its lintel at y 4).
        let (nx, ny, nz) = (16, 12, 8);
        let mut g = Grid::new(nx, ny, nz, 0.5);
        let mut solid = vec![0u8; nx * ny * nz];
        for z in 0..nz {
            for y in 0..=6 {
                for x in 0..nx {
                    let wall = (x == 0 || x == 8 || z == 0 || z == 7) && x <= 8 && y <= 5;
                    let ceiling = y == 6 && x <= 8;
                    let door = x == 8 && (3..=4).contains(&z) && y <= 3;
                    if (wall || ceiling) && !door {
                        solid[g.idx(x, y, z)] = 1;
                    }
                }
            }
        }
        g.set_solid(&solid);
        let src = g.idx(3, 0, 3);
        let dt = 1.0 / 15.0;
        for _ in 0..(40.0 / dt) as usize {
            g.sources.push((src, 3.0, 1.0));
            g.step(dt, 0.0, 0.0);
        }
        let high = g.smoke[g.idx(6, 5, 5)];
        let low = g.smoke[g.idx(6, 1, 5)];
        assert!(high > low, "fuller under the ceiling than low down: {high} against {low}");
        let out_top = sum_where(&g, |x, y, z| x == 9 && (2..=3).contains(&y) && (3..=4).contains(&z));
        let out_low = sum_where(&g, |x, y, z| x == 9 && y == 0 && (3..=4).contains(&z));
        assert!(out_top > 0.05, "it leaves by the door's top: {out_top}");
        assert!(out_top > 2.0 * out_low, "by its top, not its foot: {out_top} against {out_low}");
        let outside_up = sum_where(&g, |x, y, _| x >= 9 && y >= 7);
        assert!(outside_up > 0.0, "and goes up outside");
    }

    #[test]
    fn the_wind_leans_the_column() {
        let mut g = Grid::new(21, 16, 9, 0.5);
        let src = g.idx(5, 0, 4);
        let dt = 1.0 / 15.0;
        for _ in 0..(8.0 / dt) as usize {
            g.sources.push((src, 3.0, 1.0));
            g.step(dt, 2.0, 0.0);
        }
        let downwind = sum_where(&g, |x, y, _| x > 8 && y > 4);
        let upwind = sum_where(&g, |x, y, _| x < 3 && y > 4);
        assert!(downwind > 5.0 * upwind.max(1e-3), "downwind {downwind}, upwind {upwind}");
    }

    #[test]
    fn nothing_made_out_of_nothing() {
        let mut g = Grid::new(10, 10, 10, 0.5);
        g.t.fade = 0.0;
        g.t.fade_open = 0.0;
        let src = g.idx(5, 0, 5);
        g.sources.push((src, 15.0, 1.0));
        g.step(1.0 / 15.0, 0.0, 0.0);
        let before = g.total();
        for _ in 0..3 {
            g.step(1.0 / 15.0, 0.0, 0.0);
        }
        assert!(g.total() <= before + 1e-4, "{} after {before}", g.total());
    }
}

