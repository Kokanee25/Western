//! The blast's face sums (issue #538): `Blast.face_impulse`'s sampled sum over a member's face and
//! `Blast.torn_stretch`'s search for the stretch a charge tears out, the same sums in the same
//! order as the GDScript (src/blast/blast.gd), so the same boards break and are cut the same:
//! `test_dynamite`'s `test_the_native_face_sum_is_the_scripts` holds them equal. The member's
//! geometry (its length, width, where the charge is along it, how far off its face and how square
//! to it) stays the script's; only the loops over the samples are here (~40 µs a call in GDScript,
//! a dozen calls a holed board).

use godot::prelude::*;

const P_ATM: f64 = 101.325;
/// Where the face is sampled, about its point nearest the charge (m along it): Blast.FACE_OFFSETS.
const FACE_OFFSETS: [f64; 17] = [
    0.0, 0.03, -0.03, 0.08, -0.08, 0.15, -0.15, 0.3, -0.3, 0.6, -0.6, 1.2, -1.2, 2.4, -2.4, 4.8, -4.8,
];
const WINDOW_OFFSETS: [f64; 5] = [0.0, -0.4, -0.15, 0.15, 0.4];

/// Godot's clampf, maxf and minf (CLAMP, MAX, MIN), comparison for comparison.
fn clampf(v: f64, lo: f64, hi: f64) -> f64 {
    if v < lo { lo } else if v > hi { hi } else { v }
}
fn maxf(a: f64, b: f64) -> f64 {
    if a > b { a } else { b }
}
fn minf(a: f64, b: f64) -> f64 {
    if a < b { a } else { b }
}

/// One member's face, as the script measured it.
struct Face {
    length: f64,
    width: f64,
    t0: f64,
    perp: f64,
    out: f64,
    w3: f64,
    strong: f64,
}

impl Face {
    /// face_impulse(m, at, kg, window, center): `center` None for NAN.
    fn sum(&self, window: f64, center: Option<f64>) -> f64 {
        let half = self.length * 0.5;
        let t0 = self.t0;
        let tc = match center {
            None => t0,
            Some(c) => clampf(c, -half, half),
        };
        let mut ts: Vec<f64> = Vec::with_capacity(22);
        for o in FACE_OFFSETS {
            let t = clampf(t0 + o, -half, half);
            if !ts.contains(&t) {
                ts.push(t);
            }
        }
        if tc != t0 && window < f64::INFINITY {
            for o in WINDOW_OFFSETS {
                let t = clampf(tc + o * window, -half, half);
                if !ts.contains(&t) {
                    ts.push(t);
                }
            }
        }
        ts.sort_by(|a, b| a.partial_cmp(b).unwrap());
        let n = ts.len();
        let mut total = 0.0;
        for i in 0..n {
            let mut lo = if i == 0 { -half } else { (ts[i - 1] + ts[i]) * 0.5 };
            let mut hi = if i == n - 1 { half } else { (ts[i] + ts[i + 1]) * 0.5 };
            if window < f64::INFINITY {
                lo = maxf(lo, tc - window * 0.5);
                hi = minf(hi, tc + window * 0.5);
            }
            let seg = hi - lo;
            if seg <= 0.0 {
                continue;
            }
            let along = ts[i] - t0;
            let r = maxf((self.perp * self.perp + along * along).sqrt(), 0.02);
            let mut mean = 0.0;
            for k in 0..3i64 {
                let off = self.width * ((k - 1) as f64) / 3.0;
                let rk = (r * r + off * off).sqrt();
                let square_on = clampf(self.out / rk, 0.0, 1.0);
                let z = maxf(rk, 0.02) / self.w3;
                let imp = 0.067 * (1.0 + (z / 0.23).powf(4.0)).sqrt()
                    / (z * z * (1.0 + (z / 1.55).powf(3.0)).powf(1.0 / 3.0))
                    * self.w3
                    * 100.0;
                let num = 808.0 * (1.0 + (z / 4.5).powf(2.0));
                let den = ((1.0 + (z / 0.048).powf(2.0)) * (1.0 + (z / 0.32).powf(2.0)) * (1.0 + (z / 1.35).powf(2.0))).sqrt();
                let kpa = P_ATM * num / den;
                let refl = 2.0 + (self.strong - 2.0) * kpa / (kpa + 7.0 * P_ATM);
                mean += imp * (1.0 + (refl - 1.0) * square_on);
            }
            total += mean / 3.0 * seg * self.width;
        }
        total
    }
}

/// Blast's native half (made by ClassDB: the web export runs without the plugin).
#[derive(GodotClass)]
#[class(base = RefCounted, init)]
pub struct BlastCore {
    base: Base<RefCounted>,
}

#[godot_api]
impl BlastCore {
    /// face_impulse's sum. `w3` is the charge's cube root (pow(maxf(kg, 1e-4), 1/3)), `strong`
    /// BlastTuning.reflection_strong; `window` INF for the whole face; `has_center` false for NAN.
    #[func]
    #[allow(clippy::too_many_arguments)]
    fn face_sum(&self, length: f64, width: f64, t0: f64, perp: f64, out: f64, w3: f64, strong: f64, window: f64, center: f64, has_center: bool) -> f64 {
        let f = Face { length, width, t0, perp, out, w3, strong };
        f.sum(window, if has_center { Some(center) } else { None })
    }

    /// torn_stretch's two ends [lo, hi] along the member, before the span's half is added: from
    /// `near` each way, the furthest point whose span-wide window still breaks it (`over`), to
    /// `step`, by halving; [near, near] if `near` itself doesn't.
    #[func]
    #[allow(clippy::too_many_arguments)]
    fn torn_ends(&self, length: f64, width: f64, t0: f64, perp: f64, out: f64, w3: f64, strong: f64, span: f64, mass: f64, share: f64, capacity: f64, near: f64, reach: f64, step: f64) -> PackedFloat64Array {
        let f = Face { length, width, t0, perp, out, w3, strong };
        let half = length * 0.5;
        let over = |tc: f64| -> bool {
            let j = f.sum(span, Some(tc));
            j * j / (2.0 * mass * share) > capacity
        };
        let last_over = |inside0: f64, outside0: f64| -> f64 {
            if over(outside0) {
                return outside0;
            }
            let (mut inside, mut outside) = (inside0, outside0);
            while (outside - inside).abs() > step {
                let mid = (inside + outside) * 0.5;
                if over(mid) {
                    inside = mid;
                } else {
                    outside = mid;
                }
            }
            inside
        };
        let mut lo = near;
        let mut hi = near;
        if over(near) {
            lo = last_over(near, maxf(near - reach, -half));
            hi = last_over(near, minf(near + reach, half));
        }
        PackedFloat64Array::from(&[lo, hi][..])
    }
}
