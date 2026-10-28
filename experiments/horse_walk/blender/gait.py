"""The walk, worked out without Blender: hoof paths by phase, each leg solved in its own sagittal
plane, the trunk's rise and fall, the head's nod, the tail's sway. Pure numpy/scipy, so it can be
tested and later ported to the game's procedural gait.

The numbers (README "Sources"): four-beat lateral sequence LH, LF, RH, RF (Hildebrand 1965; Clayton
2004), the fore landing 0.30 of a stride after its hind (the clip 0.33, an even walk 0.25); duty factor 0.62 (the clip measures 0.67 slowed; 0.60-0.65 published); stride
1.1 s (Clayton; Barrey); two nods of the head and two rises of the trunk a stride (Buchner et al. 1996).

Angles live in the (u, z) plane: u = -x (forward, his head's way), z up; a segment's angle is its
direction's, counter-clockwise from +u (straight down = -90 degrees). A joint's angle is the child's
minus the parent's. Flexion signs (the README's table): fore knee and fetlock fold with Δ < 0;
elbow with Δ > 0; hind stifle Δ < 0, hock Δ > 0 (the reciprocal apparatus: Δstifle ≈ -Δhock).
"""
import math

import numpy as np
from scipy.optimize import least_squares

D2R = math.pi / 180.0


class Walk:
    def __init__(self, T=1.1, L=1.35, duty=0.62, lateral=0.30, fps=60):
        self.T, self.L, self.duty, self.fps = T, L, duty, fps
        self.v = L / T
        # where each leg lands in the stride (LH first)
        self.offset = {"LH": 0.0, "LF": lateral, "RH": 0.5, "RF": 0.5 + lateral}
        self.frames = int(round(T * fps))
        # swing shapes: the toe's height over the ground (m) and when it peaks (share of the swing);
        # the hoof's turn (degrees, + = heel up/sole back) through the swing as (share, turn): the
        # breakover's at lift-off, flipped sole-back early as the knee and fetlock fold, carried
        # level by mid-swing (not tipped toe-down: round 4's "dancer's toe"), a touch toe-up, flat
        self.lift = {"F": 0.09, "H": 0.10}
        self.lift_peak = {"F": 0.32, "H": 0.36}
        self.breakover = {"F": 45.0, "H": 50.0}
        # the heel starts up at this share of the stance: the hind's earlier, so it leaves heel up
        # with the pastern near upright (round 4: "flat at lift-off")
        self.breakover_from = {"F": 0.67, "H": 0.58}
        self.hang_flex = {"F": 8.0, "H": 8.0}
        self.turns = {"F": [(0.2, 60.0), (0.55, 4.0), (0.85, -10.0)],
                      "H": [(0.2, 55.0), (0.55, 4.0), (0.85, -6.0)]}
        # stance: the fetlock's sink at mid-stance (degrees, pastern toward level); swing: the knee's
        # and hock's fold at their most
        self.sink = {"F": 18.0, "H": 15.0}
        # the fold peaks early in the swing (a third of the way: the hoof picked up, then the leg
        # carried forward), as the clip's fore and hind do; the elbow flexes with the knee
        self.knee_fold = 55.0
        self.hock_fold = 50.0
        self.elbow_fold = 18.0
        self.fold_peak = {"F": 0.3, "H": 0.4}
        # the hock closes over the stance's last part, the stifle with it: the hind leaves angled
        self.hock_close = 12.0
        # the trunk: rise and fall at withers and croup (m, half the swing), the neck's nod (degrees)
        self.bob = 0.02
        self.nod = 5.0
        self.tail_sway = 4.0
        # the walk's carriage against the model's standing pose (head up, alert): the neck lowered
        # and the nose put forward, as a horse walking on a loose rein carries them (the clip)
        self.neck_carriage = -34.0
        self.head_carriage = 24.0

    # --- phases -------------------------------------------------------------------------------
    def phase(self, leg, t):
        return (t / self.T - self.offset[leg]) % 1.0

    def stance(self, leg, t):
        return self.phase(leg, t) < self.duty

    # --- the hoof's path ----------------------------------------------------------------------
    def hoof(self, leg, t, rest_toe, rest_angle):
        """The toe's (u, z) on the ground's frame (the body moving at v from u=0 at t=0) and the
        hoof bone's angle, at time t. rest_toe: the toe's (u, z) in the rest pose."""
        kind = leg[1]
        s = self.phase(leg, t)
        b = self.duty
        k = math.floor(t / self.T - self.offset[leg])  # which stride this phase belongs to
        land_t = (k + self.offset[leg]) * self.T       # when this stance began
        # each stance placed about the rest toe: the fore's a touch ahead, the hind's behind (the
        # hind retracts further than it protracts; the clip's fore: +15 at contact, -20 at lift-off)
        ahead = 0.02 if kind == "F" else 0.0
        land_u = rest_toe[0] + self.v * land_t + self.L * b / 2 + ahead
        if s < b:
            u = land_u
            z = rest_toe[1]
            # breakover: the heel rises about the toe over the stance's last part
            q0 = self.breakover_from[kind]
            q = max(0.0, (s / b - q0) / (1.0 - q0))
            turn = self.breakover[kind] * smooth(q) ** 1.5
            return (u, z), rest_angle - math.radians(turn)
        w = (s - b) / (1.0 - b)                         # 0..1 through the swing
        u = land_u + self.L * minjerk(w)
        z = rest_toe[1] + self.lift[kind] * lift_curve(w, self.lift_peak[kind])
        keys = [(0.0, self.breakover[kind])] + self.turns[kind] + [(1.0, 0.0)]
        for (w0, a0), (w1, a1) in zip(keys, keys[1:]):
            if w <= w1:
                turn = lerp(a0, a1, smooth((w - w0) / (w1 - w0)))
                break
        return (u, z), rest_angle - math.radians(turn)

    def hang(self, leg, t):
        """How much the hoof hangs from the folded leg (0..1) rather than following `turns`, and
        its flex past the cannon's line (degrees). In the clip's swings the hoof hangs in line with
        the cannon, sole back, as the knee or hock folds: a hoof turned by the clock alone read as
        a pointed toe where the cannon was upright (round 4) and as tipped where it was back."""
        s = self.phase(leg, t)
        if s < self.duty:
            return 0.0, 0.0
        w = (s - self.duty) / (1.0 - self.duty)
        return smooth(w / 0.2) * (1.0 - smooth((w - 0.55) / 0.3)), self.hang_flex[leg[1]]

    # --- preferences for the leg solve --------------------------------------------------------
    def prefs(self, leg, t):
        """Wanted joint changes from rest (degrees) and how much each is wanted. The weights blend
        over the stance's last fifth and the swing's first tenth: a step in them makes the solve
        jump between two keys, and the keys' blend then dips the hoof."""
        kind = leg[1]
        s = self.phase(leg, t)
        b = self.duty
        if s < b:
            sink = self.sink[kind] * math.sin(math.pi * s / b)
            swing = 0.0
            lock = 1.0 - smooth((s / b - 0.8) / 0.2) * 0.5
        else:
            sink = 0.0
            swing = (s - b) / (1.0 - b)
            lock = 0.5 * (1.0 - smooth(swing / 0.1)) + 0.0
        peak = self.fold_peak[kind]
        if kind == "F":
            k = bump(swing, peak) if s >= b else 0.0
            # the scapula (the chain's root) held loosely: more of the reach comes from its slide
            # (Sean, #474). Its key was "scap" before, which the solve never read: the default 0.02
            return {"root": (0.0, 0.02), "shoulder": (0.0, 0.05), "elbow": (self.elbow_fold * k, 0.8),
                    "knee": (-self.knee_fold * k, 4.0 + 16.0 * lock), "fetlock": (0.0, 0.05),
                    "pastern_abs": (sink, 3.0 * lock)}
        if s >= b:
            fold = self.hock_fold * bump(swing, peak)
            # the push-off's closed hock carried into the swing's start
            fold = max(fold, self.hock_close * (1.0 - smooth(swing / 0.25)))
        else:
            fold = self.hock_close * smooth((s / b - 0.7) / 0.3)
        return {"root": (0.0, 0.02), "stifle": (-fold, 0.4), "hock": (fold, 2.0), "fetlock": (0.0, 0.05),
                "pastern_abs": (sink, 3.0 * lock), "couple": (0.0, 3.0)}

    # --- the trunk, neck, tail ----------------------------------------------------------------
    def trunk(self, t):
        """(rise at the withers, rise at the croup) in metres: each highest over its limbs'
        mid-stances (the walk's vault), twice a stride."""
        b = self.duty
        mid_h = self.offset["LH"] + b / 2
        mid_f = self.offset["LF"] + b / 2
        p = t / self.T
        return (self.bob * math.cos(4 * math.pi * (p - mid_f)),
                self.bob * math.cos(4 * math.pi * (p - mid_h)))

    def neck(self, t):
        """The neck's turn (degrees, + = nose down) twice a stride: lowest just after each fore
        lands, as the fore takes the weight (Buchner et al. 1996)."""
        p = t / self.T
        low = self.offset["LF"] + 0.08
        return self.nod * math.cos(4 * math.pi * (p - low))

    def tail(self, t, k):
        """The tail's k-th bone's sideways sway (degrees), once a stride, each bone later."""
        p = t / self.T
        return self.tail_sway * (0.5 + 0.06 * k) * math.sin(2 * math.pi * (p - 0.08 * k))


def smooth(x):
    x = min(1.0, max(0.0, x))
    return x * x * (3 - 2 * x)


def minjerk(x):
    x = min(1.0, max(0.0, x))
    return x ** 3 * (10 - 15 * x + 6 * x * x)


def bump(x, peak=0.5):
    """0 at 0 and 1, 1 at `peak`, smooth."""
    x = min(1.0, max(0.0, x))
    if x < peak:
        return math.sin(0.5 * math.pi * x / peak) ** 2
    return math.sin(0.5 * math.pi * (1 - x) / (1 - peak)) ** 2


def lift_curve(x, peak):
    """The toe's height through a swing: off the ground at once (the toe leaves as the stance
    ends), down softly to land."""
    x = min(1.0, max(0.0, x))
    if x < peak:
        return math.sin(0.5 * math.pi * x / peak) ** 1.2
    return math.sin(0.5 * math.pi * (1 - x) / (1 - peak)) ** 2


def lerp(a, b, x):
    return a + (b - a) * x


# --- a leg in its sagittal plane --------------------------------------------------------------


class Leg:
    """A chain of segments from an anchor (the scapula's top or the hip) to the coronet, solved so
    the coronet meets a target while each joint stays in its range and near what the gait wants.

    joints: names of the joints between consecutive segments (len = segments - 1); limits: each
    joint's (lo, hi) change from rest, degrees; the first segment's angle is limited by `root`."""

    def __init__(self, points, joints, limits, root):
        P = np.asarray(points, float)                   # (n+1, 2) u, z: anchor ... coronet
        d = np.diff(P, axis=0)
        self.lengths = np.linalg.norm(d, axis=1)
        self.rest_abs = np.arctan2(d[:, 1], d[:, 0])
        self.rest_rel = np.concatenate([[self.rest_abs[0]], np.diff(self.rest_abs)])
        self.joints = joints
        lo = [root[0]] + [limits[j][0] for j in joints]
        hi = [root[1]] + [limits[j][1] for j in joints]
        self.lo = self.rest_rel + np.array(lo) * D2R
        self.hi = self.rest_rel + np.array(hi) * D2R
        self.x = self.rest_rel.copy()

    def fk(self, rel, anchor, tilt=0.0):
        a = np.cumsum(rel) + tilt
        pts = [np.asarray(anchor, float)]
        for L_, ang in zip(self.lengths, a):
            pts.append(pts[-1] + L_ * np.array([math.cos(ang), math.sin(ang)]))
        return np.array(pts), a

    def solve(self, anchor, target, prefs, tilt=0.0, hoof=None, rest_coffin=0.0):
        """rel angles (radians) with the coronet at `target`; `tilt` is the trunk's pitch (the
        anchor's girdle turns with it); `hoof`: the hoof bone's angle, so the coffin joint (pastern
        to hoof) is kept near its rest and inside (-40, 30) degrees."""
        names = ["root"] + self.joints

        def res(rel):
            pts, a = self.fk(rel, anchor, tilt)
            r = [(pts[-1] - target) * 400.0]
            dr = (rel - self.rest_rel) / D2R
            for i, n in enumerate(names):
                want, wgt = prefs.get(n, (0.0, 0.02))
                r.append([math.sqrt(wgt) * (dr[i] - want) * 0.05])
            pa = prefs.get("pastern_abs")
            if pa and pa[1] > 0:
                r.append([math.sqrt(pa[1]) * ((a[-1] - self.rest_abs[-1] - tilt) / D2R - pa[0]) * 0.05])
            if hoof is not None:
                dc = (hoof - a[-1] - rest_coffin) / D2R
                over = max(0.0, dc - 30.0) + max(0.0, -40.0 - dc)
                r.append([0.4 * dc * 0.05, over * 2.0])
            cp = prefs.get("couple")
            if cp:
                i_s, i_h = names.index("stifle"), names.index("hock")
                r.append([math.sqrt(cp[1]) * (dr[i_s] + dr[i_h]) * 0.05])
            return np.concatenate(r)
        x0 = np.clip(self.x, self.lo + 1e-6, self.hi - 1e-6)
        sol = least_squares(res, x0, bounds=(self.lo, self.hi), xtol=1e-10, ftol=1e-10, max_nfev=400)
        self.x = sol.x
        pts, a = self.fk(sol.x, anchor, tilt)
        return sol.x, pts, a, float(np.linalg.norm(pts[-1] - target))


# Joint ranges (change from the standing pose, degrees) a horse's leg has: no joint may bend the
# wrong way (the knee and hock not past straight, the fetlock not folded forward). From Clayton
# (2004) and Back & Clayton (2013)'s walk ranges, with room.
FORE_LIMITS = {"shoulder": (-30, 30), "elbow": (-12, 60), "knee": (-110, 2), "fetlock": (-100, 30)}
HIND_LIMITS = {"stifle": (-65, 30), "hock": (-15, 65), "fetlock": (-90, 30)}
FORE_ROOT = (-22, 22)   # the scapula's swing about its top (±16 left the elbow doing the reach)
HIND_ROOT = (-35, 35)   # the thigh at the hip
