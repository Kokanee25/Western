//! The fire's member tick (docs/briefs/more-cores.md step 8; `FireSystem`, `src/fire/fire_core.gd`
//! is the same rules in GDScript for where the plugin isn't). Every member the fire has met has a
//! slot here holding its temperature, water, char and burn time (the member's own properties read
//! and write them through), its size, what it's made of, and the members it heats with how hard.
//! A tick's visit (`visit`) runs the rules over a slice of the burning and hot members in
//! FireSystem's order and hands back what the scene must do (burn away, catch, crack, drop out of
//! the fire's list, newly hot) as events, in the order they happened; FireSystem does them on the
//! main thread. Only plain numbers here: no Godot objects, so it's the same answer every run.
//! The numbers are f64 as GDScript's floats are, and a member's size f32 as its Vector3 is, each
//! sum in the order the GDScript does it: the same rules give the same numbers either way
//! (`tests/test_fire_core.gd` runs both).

use godot::prelude::*;

const BURNING: u8 = 1;
const CONSUMED: u8 = 2;
const ACTIVE: u8 = 4;
const VALID: u8 = 8;
const FLAMMABLE: u8 = 16;
const GLASS: u8 = 32;
const HAS_NEAR: u8 = 64;
const BROKEN: u8 = 128;
/// No visit recorded (FireSystem's `_last` had no entry).
const NONE: i64 = i64::MIN;

/// What `visit` hands back, as pairs (event, which): `which` is the index in the slice's slots
/// for all but ACTIVATE, whose `which` is a slot.
pub const EV_GONE: i32 = 0;
pub const EV_CONSUME: i32 = 1;
pub const EV_IGNITE: i32 = 2;
pub const EV_GLASS: i32 = 3;
pub const EV_ACTIVATE: i32 = 4;

#[derive(Clone)]
pub struct Tuning {
    pub ignition: f64,
    pub ambient: f64,
    pub cracks: f64,
    pub cooling: f64,
    pub growth: f64,
    pub char_rate: f64,
    pub ash: f64,
    pub water_per_degree: f64,
    pub evaporation: f64,
    pub far_every: i64,
}

impl Default for Tuning {
    // config/fire.tres's defaults (FireSystem sets them from its tuning).
    fn default() -> Self {
        Tuning {
            ignition: 290.0,
            ambient: 20.0,
            cracks: 240.0,
            cooling: 0.0055,
            growth: 32.0,
            char_rate: 0.0000625,
            ash: 0.004,
            water_per_degree: 0.0007,
            evaporation: 0.002,
            far_every: 4,
        }
    }
}

/// The slots, as plain arrays (index = slot).
#[derive(Default)]
pub struct Core {
    pub t: Tuning,
    pub temp: Vec<f64>,
    pub wet: Vec<f64>,
    pub burn: Vec<f64>,
    pub chr: Vec<f64>,
    pub size: Vec<[f32; 3]>,
    pub flags: Vec<u8>,
    pub hash: Vec<i64>,
    pub last: Vec<i64>,
    pub structure: Vec<i32>,
    pub near: Vec<Vec<(u32, f64)>>,
    pub near_age: Vec<f64>,
    /// Where it is (min xyz, max xyz), for `near`: a standing member's box, rubble's as it lay at
    /// the grid's last rebuild.
    pub bx: Vec<[f32; 6]>,
}

impl Core {
    #[allow(clippy::too_many_arguments)]
    pub fn add(&mut self, temp: f64, wet: f64, chr: f64, burn: f64, flags: u8, size: [f32; 3], hash: i64, structure: i32) -> usize {
        self.temp.push(temp);
        self.wet.push(wet);
        self.chr.push(chr);
        self.burn.push(burn);
        self.size.push(size);
        self.flags.push(flags | VALID);
        self.hash.push(hash);
        self.last.push(NONE);
        self.structure.push(structure);
        self.near.push(Vec::new());
        self.near_age.push(0.0);
        self.bx.push([0.0; 6]);
        self.temp.len() - 1
    }

    fn has(&self, s: usize, f: u8) -> bool {
        self.flags[s] & f != 0
    }

    fn set(&mut self, s: usize, f: u8, on: bool) {
        if on {
            self.flags[s] |= f;
        } else {
            self.flags[s] &= !f;
        }
    }

    /// StructureMember.thickness(): the thinnest side of the sound wood left.
    pub fn thickness(&self, s: usize) -> f64 {
        let mut t = f64::INFINITY;
        for i in 0..3 {
            let v = self.size[s][i] as f64 - self.chr[s] * 2.0;
            if v < t {
                t = v;
            }
        }
        if t > 0.0 { t } else { 0.0 }
    }

    /// FireSystem._heat: `amount` is °C for a 1 cm member. True if it wasn't on the fire's list.
    pub fn heat(&mut self, s: usize, amount: f64) -> bool {
        let cm = maxf(self.thickness(s) * 100.0, 0.5);
        let mut rise = amount / cm;
        let newly = !self.has(s, ACTIVE);
        self.flags[s] |= ACTIVE;
        if self.wet[s] > 0.0 {
            // Wet: the heat goes into drying it, and it gets no hotter than boiling till it's dry.
            let dries = amount * self.t.water_per_degree;
            if dries < self.wet[s] {
                self.wet[s] -= dries;
                self.temp[s] = minf(self.temp[s] + rise, 100.0);
                return newly;
            }
            rise *= 1.0 - self.wet[s] / dries;
            self.wet[s] = 0.0;
            self.temp[s] = minf(self.temp[s], 100.0);
        }
        self.temp[s] += rise;
        newly
    }

    /// Its band's turn this tick? (FireSystem's bands: a far structure's members every so many
    /// ticks, each on its own phase.)
    fn band(&self, s: usize, bands: &[i32]) -> i64 {
        let st = self.structure[s];
        if st >= 0 && (st as usize) < bands.len() { bands[st as usize] as i64 } else { 1 }
    }

    fn skipped(&self, s: usize, banded: bool, ticks: i64, bands: &[i32]) -> bool {
        if !banded {
            return false;
        }
        let b = self.band(s, bands);
        b > 1 && (ticks + self.hash[s]).rem_euclid(b) != 0
    }

    fn live(&self, s: i32) -> Option<usize> {
        if s < 0 || s as usize >= self.flags.len() {
            return None;
        }
        let s = s as usize;
        if !self.has(s, VALID) || self.has(s, CONSUMED) { None } else { Some(s) }
    }

    /// Of the slice's slots, the ones whose list of what they heat is to be made (again) before
    /// `visit`: burning, visited this tick, and with no list or one past its age (rubble 2 s,
    /// standing 30 s, each later by its id).
    pub fn near_due(&self, slots: &[i32], banded: bool, ticks: i64, bands: &[i32]) -> Vec<i32> {
        let mut out = Vec::new();
        for (i, &s) in slots.iter().enumerate() {
            let Some(s) = self.live(s) else { continue };
            if !self.has(s, BURNING) || self.skipped(s, banded, ticks, bands) {
                continue;
            }
            if !self.has(s, HAS_NEAR) {
                out.push(i as i32);
                continue;
            }
            let spread = self.hash[s].rem_euclid(16) as f64 / 16.0;
            let keep = if self.has(s, BROKEN) { 2.0 + spread * 0.5 } else { 30.0 + spread * 4.0 };
            if self.near_age[s] >= keep {
                out.push(i as i32);
            }
        }
        out
    }

    /// FireSystem._visit over a slice: each member heats, burns and cools by the rules; what it
    /// heats on its list. Events in the order they happen.
    pub fn visit(&mut self, slots: &[i32], tick_dt: f64, banded: bool, ticks: i64, bands: &[i32]) -> Vec<i32> {
        let mut ev: Vec<i32> = Vec::new();
        let far = self.t.far_every.max(1);
        for (i, &raw) in slots.iter().enumerate() {
            let i = i as i32;
            let Some(s) = self.live(raw) else {
                ev.extend_from_slice(&[EV_GONE, i]);
                continue;
            };
            let mut dt = tick_dt;
            if banded {
                if self.skipped(s, banded, ticks, bands) {
                    continue; // far off: not its tick
                }
                let last = if self.last[s] == NONE { ticks - 1 } else { self.last[s] };
                dt = tick_dt * ((ticks - last).clamp(1, far) as f64);
                self.last[s] = ticks;
            }
            if self.has(s, BURNING) {
                self.burn[s] += dt;
                let intensity = clampf(self.burn[s] / self.t.growth, 0.15, 1.0);
                self.temp[s] = maxf(self.temp[s], 650.0);
                self.chr[s] += self.t.char_rate * dt;
                let mut near = std::mem::take(&mut self.near[s]);
                let mut dropped = false;
                for &(o, w) in near.iter() {
                    let o = o as usize;
                    // Burning or burnt away, heat makes no more difference to it (and neither ever
                    // goes back): left out from here on.
                    if !self.has(o, VALID) || self.has(o, CONSUMED) || self.has(o, BURNING) {
                        dropped = true;
                        continue;
                    }
                    if self.heat(o, w * intensity * dt) {
                        ev.extend_from_slice(&[EV_ACTIVATE, o as i32]);
                    }
                }
                if dropped {
                    near.retain(|&(o, _)| {
                        let f = self.flags[o as usize];
                        f & VALID != 0 && f & (CONSUMED | BURNING) == 0
                    });
                }
                self.near[s] = near;
                if self.thickness(s) <= self.t.ash {
                    self.set(s, CONSUMED, true);
                    self.set(s, BURNING, false);
                    ev.extend_from_slice(&[EV_CONSUME, i]);
                }
            } else {
                self.temp[s] += (self.t.ambient - self.temp[s]) * self.t.cooling * dt;
                if self.wet[s] > 0.0 {
                    self.wet[s] = maxf(self.wet[s] - self.t.evaporation * dt, 0.0);
                }
                if self.has(s, FLAMMABLE) && self.temp[s] >= self.t.ignition {
                    self.set(s, BURNING, true);
                    self.burn[s] = 0.0;
                    ev.extend_from_slice(&[EV_IGNITE, i]);
                } else if self.has(s, GLASS) && self.temp[s] >= self.t.cracks {
                    // Cracks and falls out, unless it has already (FireSystem looks).
                    if !self.has(s, BROKEN) {
                        ev.extend_from_slice(&[EV_GLASS, i]);
                    }
                } else if self.temp[s] < self.t.ambient + 5.0 && self.wet[s] <= 0.0 {
                    ev.extend_from_slice(&[EV_GONE, i]);
                }
            }
        }
        ev
    }

    /// Off the fire's list: its list of what it heats and its last visit go with it.
    pub fn forget(&mut self, s: usize) {
        self.set(s, ACTIVE | HAS_NEAR, false);
        self.near[s] = Vec::new();
        self.near_age[s] = 0.0;
        self.last[s] = NONE;
    }

    /// FireSystem.fire_near over the burning slots: (count, nearest point, its distance).
    pub fn near(&self, at: [f32; 3], radius: f64) -> (i64, [f32; 3], f64) {
        let mut count = 0;
        let mut best = [f32::INFINITY; 3];
        let mut best_d = f64::INFINITY;
        for s in 0..self.flags.len() {
            let f = self.flags[s];
            if f & (VALID | BURNING) != (VALID | BURNING) || f & CONSUMED != 0 {
                continue;
            }
            let b = &self.bx[s];
            // at.clamp(box.position, box.end), then its distance (Vector3: f32 sums, the length f32).
            let p = [clamp32(at[0], b[0], b[3]), clamp32(at[1], b[1], b[4]), clamp32(at[2], b[2], b[5])];
            let d = [p[0] - at[0], p[1] - at[1], p[2] - at[2]];
            let d = ((d[0] * d[0] + d[1] * d[1] + d[2] * d[2]).sqrt()) as f64;
            if d > radius {
                continue;
            }
            count += 1;
            if d < best_d {
                best_d = d;
                best = p;
            }
        }
        (count, best, best_d)
    }
}

// GDScript's minf/maxf/clampf (no NaN here).
fn minf(a: f64, b: f64) -> f64 {
    if a < b { a } else { b }
}
fn maxf(a: f64, b: f64) -> f64 {
    if a > b { a } else { b }
}
// Godot's CLAMP (Vector3.clamp): no panic on a box turned inside out.
fn clamp32(v: f32, lo: f32, hi: f32) -> f32 {
    if v < lo { lo } else if v > hi { hi } else { v }
}
fn clampf(v: f64, lo: f64, hi: f64) -> f64 {
    if v < lo { lo } else if v > hi { hi } else { v }
}

/// Godot's handle on the slots (FireSystem's `_core`).
#[derive(GodotClass)]
#[class(base = RefCounted, init)]
pub struct FireCore {
    base: Base<RefCounted>,
    c: Core,
}

impl FireCore {
    /// Alight (not burnt away, not freed): for the smoke grid's sources.
    pub fn burning_slot(&self, s: i32) -> bool {
        if s < 0 || s as usize >= self.c.flags.len() {
            return false;
        }
        let f = self.c.flags[s as usize];
        f & (VALID | BURNING) == (VALID | BURNING) && f & CONSUMED == 0
    }
}

fn slot(c: &Core, s: i64) -> Option<usize> {
    if s >= 0 && (s as usize) < c.flags.len() { Some(s as usize) } else { None }
}

#[godot_api]
impl FireCore {
    /// One of the rules' numbers (FireTuning's names); false if it isn't one.
    #[func]
    fn tune(&mut self, name: GString, value: f64) -> bool {
        let t = &mut self.c.t;
        match name.to_string().as_str() {
            "ignition_temperature" => t.ignition = value,
            "ambient_temperature" => t.ambient = value,
            "glass_cracks_at" => t.cracks = value,
            "cooling" => t.cooling = value,
            "growth_seconds" => t.growth = value,
            "char_rate" => t.char_rate = value,
            "ash_thickness" => t.ash = value,
            "water_per_degree" => t.water_per_degree = value,
            "evaporation" => t.evaporation = value,
            "far_every" => t.far_every = value as i64,
            _ => return false,
        }
        true
    }

    /// A member met for the first time: its slot. `flags` as FireCoreScript.F_*.
    #[func]
    #[allow(clippy::too_many_arguments)]
    fn add(&mut self, temperature: f64, wet: f64, char_depth: f64, burn_time: f64, flags: i64, size: Vector3, id_hash: i64, structure: i64) -> i64 {
        self.c.add(temperature, wet, char_depth, burn_time, flags as u8, [size.x, size.y, size.z], id_hash, structure as i32) as i64
    }

    /// The member's been freed: nothing heats it, nothing it heats.
    #[func]
    fn release(&mut self, s: i64) {
        if let Some(s) = slot(&self.c, s) {
            self.c.set(s, VALID, false);
            self.c.forget(s);
        }
    }

    #[func]
    fn size(&self) -> i64 {
        self.c.flags.len() as i64
    }

    #[func]
    fn temperature(&self, s: i64) -> f64 {
        slot(&self.c, s).map_or(20.0, |s| self.c.temp[s])
    }
    #[func]
    fn set_temperature(&mut self, s: i64, v: f64) {
        if let Some(s) = slot(&self.c, s) {
            self.c.temp[s] = v;
        }
    }
    #[func]
    fn wet(&self, s: i64) -> f64 {
        slot(&self.c, s).map_or(0.0, |s| self.c.wet[s])
    }
    #[func]
    fn set_wet(&mut self, s: i64, v: f64) {
        if let Some(s) = slot(&self.c, s) {
            self.c.wet[s] = v;
        }
    }
    #[func]
    fn char_depth(&self, s: i64) -> f64 {
        slot(&self.c, s).map_or(0.0, |s| self.c.chr[s])
    }
    #[func]
    fn set_char_depth(&mut self, s: i64, v: f64) {
        if let Some(s) = slot(&self.c, s) {
            self.c.chr[s] = v;
        }
    }
    #[func]
    fn burn_time(&self, s: i64) -> f64 {
        slot(&self.c, s).map_or(0.0, |s| self.c.burn[s])
    }
    #[func]
    fn set_burn_time(&mut self, s: i64, v: f64) {
        if let Some(s) = slot(&self.c, s) {
            self.c.burn[s] = v;
        }
    }
    /// A flag (FireCoreScript.F_BURNING, F_CONSUMED, F_ACTIVE, F_BROKEN) on or off.
    #[func]
    fn set_flag(&mut self, s: i64, flag: i64, on: bool) {
        if let Some(s) = slot(&self.c, s) {
            self.c.set(s, flag as u8, on);
        }
    }
    #[func]
    fn flag(&self, s: i64, flag: i64) -> bool {
        slot(&self.c, s).is_some_and(|s| self.c.has(s, flag as u8))
    }

    #[func]
    fn thickness(&self, s: i64) -> f64 {
        slot(&self.c, s).map_or(0.0, |s| self.c.thickness(s))
    }

    /// Heat it (spilt oil, a rag): true if it's newly on the fire's list.
    #[func]
    fn heat(&mut self, s: i64, amount: f64) -> bool {
        slot(&self.c, s).is_some_and(|s| self.c.heat(s, amount))
    }

    /// What it heats (slots) and how hard; its list's age starts again.
    #[func]
    fn set_near(&mut self, s: i64, others: PackedInt32Array, weights: PackedFloat64Array) {
        let Some(s) = slot(&self.c, s) else { return };
        let o = others.as_slice();
        let w = weights.as_slice();
        self.c.near[s] = o.iter().zip(w.iter()).map(|(&o, &w)| (o as u32, w)).collect();
        self.c.near_age[s] = 0.0;
        self.c.set(s, HAS_NEAR, true);
    }

    /// Every list of what a member heats a tick older.
    #[func]
    fn age_near(&mut self, dt: f64) {
        for s in 0..self.c.flags.len() {
            if self.c.has(s, HAS_NEAR) {
                self.c.near_age[s] += dt;
            }
        }
    }

    #[func]
    fn forget(&mut self, s: i64) {
        if let Some(s) = slot(&self.c, s) {
            self.c.forget(s);
        }
    }

    #[func]
    fn near_due(&self, slots: PackedInt32Array, banded: bool, ticks: i64, bands: PackedInt32Array) -> PackedInt32Array {
        PackedInt32Array::from(self.c.near_due(slots.as_slice(), banded, ticks, bands.as_slice()))
    }

    #[func]
    fn visit(&mut self, slots: PackedInt32Array, tick_dt: f64, banded: bool, ticks: i64, bands: PackedInt32Array) -> PackedInt32Array {
        PackedInt32Array::from(self.c.visit(slots.as_slice(), tick_dt, banded, ticks, bands.as_slice()))
    }

    /// Where it is, for `fire_near`.
    #[func]
    fn set_box(&mut self, s: i64, b: Aabb) {
        if let Some(s) = slot(&self.c, s) {
            let (p, e) = (b.position, b.position + b.size);
            self.c.bx[s] = [p.x, p.y, p.z, e.x, e.y, e.z];
        }
    }

    /// The burning members within `radius` of `at` (each one's box): [count, nearest point
    /// (Vector3.INF if none), its distance].
    #[func]
    fn burning_near(&self, at: Vector3, radius: f64) -> VarArray {
        let (n, p, d) = self.c.near([at.x, at.y, at.z], radius);
        let mut out = VarArray::new();
        out.push(&n.to_variant());
        out.push(&Vector3::new(p[0], p[1], p[2]).to_variant());
        out.push(&d.to_variant());
        out
    }

    /// How many are burning (not burnt away, not freed).
    #[func]
    fn burning_count(&self) -> i64 {
        let mut n = 0;
        for &f in &self.c.flags {
            if f & (VALID | BURNING) == (VALID | BURNING) && f & CONSUMED == 0 {
                n += 1;
            }
        }
        n
    }

    /// Each slot's burn time, for a list of slots at once.
    #[func]
    fn burn_times(&self, slots: PackedInt32Array) -> PackedFloat64Array {
        let out: Vec<f64> = slots.as_slice().iter().map(|&s| slot(&self.c, s as i64).map_or(0.0, |s| self.c.burn[s])).collect();
        PackedFloat64Array::from(out)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn board(c: &mut Core, temp: f64, flags: u8) -> usize {
        c.add(temp, 0.0, 0.0, 0.0, flags | FLAMMABLE | ACTIVE, [2.0, 0.15, 0.02], 7, -1)
    }

    #[test]
    fn a_burning_board_heats_its_neighbour_till_it_catches() {
        let mut c = Core::default();
        let a = board(&mut c, 700.0, BURNING);
        let b = c.add(20.0, 0.0, 0.0, 0.0, FLAMMABLE, [2.0, 0.15, 0.02], 9, -1);
        c.near[a] = vec![(b as u32, 30.0)];
        c.set(a, HAS_NEAR, true);
        let ev = c.visit(&[a as i32], 0.25, false, 1, &[]);
        assert_eq!(ev, vec![EV_ACTIVATE, b as i32]);
        let mut caught = false;
        for tick in 0..2000 {
            let ev = c.visit(&[a as i32, b as i32], 0.25, false, tick, &[]);
            if ev.chunks(2).any(|e| e[0] == EV_IGNITE && e[1] == 1) {
                caught = true;
                break;
            }
        }
        assert!(caught, "the neighbour catches");
    }

    #[test]
    fn a_board_burns_away() {
        let mut c = Core::default();
        let a = board(&mut c, 700.0, BURNING);
        c.set(a, HAS_NEAR, true);
        let mut gone = false;
        for tick in 0..100_000 {
            let ev = c.visit(&[a as i32], 0.25, false, tick, &[]);
            if ev == vec![EV_CONSUME, 0] {
                gone = true;
                break;
            }
        }
        assert!(gone && c.has(a, CONSUMED) && !c.has(a, BURNING));
    }

    #[test]
    fn far_off_it_ticks_on_its_phase_with_the_time_since() {
        let mut c = Core::default();
        let a = c.add(400.0, 0.0, 0.0, 0.0, ACTIVE, [1.0, 1.0, 1.0], 2, 0);
        let mut visited = 0;
        for tick in 0..8 {
            let before = c.temp[a];
            c.visit(&[a as i32], 0.25, true, tick, &[4]);
            if c.temp[a] != before {
                visited += 1;
            }
        }
        assert_eq!(visited, 2);
    }
}
