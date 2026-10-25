"""The horse's idle loop as bone transforms (numpy; tools/blender/horse.py keys them in Blender).

Twelve seconds that loop: he rests his left hind on its toe, shifts his weight and stands square,
rests the right, then the left again; swishes his tail twice; flicks an ear back three times;
drops his head once to nose at the dirt; breathes. The hooves he stands on stay where they are
(each leg solved from its top joint to its planted hoof, two bones bending in the leg's own
plane), so the body sways over them without the feet sliding.

A pose is, for each bone, a 4x4 A that carries a rest-space point to its posed place
(posed = A @ rest). horse.py turns A into Blender's pose basis (rest⁻¹ · A_parent⁻¹ · A · rest).
"""
import math

import numpy as np

LOOP = 12.0  # seconds
FPS = 15


def _rot(axis, angle):
    a = np.asarray(axis, float)
    a = a / np.linalg.norm(a)
    x, y, z = a
    c, s = math.cos(angle), math.sin(angle)
    C = 1.0 - c
    return np.array([[c + x * x * C, x * y * C - z * s, x * z * C + y * s],
                     [y * x * C + z * s, c + y * y * C, y * z * C - x * s],
                     [z * x * C - y * s, z * y * C + x * s, c + z * z * C]])


def _between(u, v):
    """The smallest rotation taking direction u to direction v."""
    u = np.asarray(u, float) / np.linalg.norm(u)
    v = np.asarray(v, float) / np.linalg.norm(v)
    axis = np.cross(u, v)
    s = np.linalg.norm(axis)
    c = float(np.clip(u @ v, -1.0, 1.0))
    if s < 1e-9:
        return np.eye(3)
    return _rot(axis / s, math.atan2(s, c))


def _affine(R=None, t=None):
    m = np.eye(4)
    if R is not None:
        m[:3, :3] = R
    if t is not None:
        m[:3, 3] = t
    return m


def _about(point, R):
    """Rotation R about a point: T(p) R T(-p)."""
    p = np.asarray(point, float)
    return _affine(R, p - R @ p)


def _rigid(rest_from, posed_from, R):
    """The transform turning by R and carrying rest point `rest_from` to `posed_from`."""
    return _affine(R, np.asarray(posed_from, float) - R @ np.asarray(rest_from, float))


def _apply(A, p):
    return A[:3, :3] @ np.asarray(p, float) + A[:3, 3]


def _ss(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3.0 - 2.0 * x)


def ramp(t, a, b):
    return _ss((t - a) / (b - a))


def window(t, a, b, rise):
    return ramp(t, a, a + rise) * (1.0 - ramp(t, b - rise, b))


def pulse(t, a, b):
    """0 → 1 → 0 over [a, b], a sine bump."""
    if t <= a or t >= b:
        return 0.0
    return math.sin(math.pi * (t - a) / (b - a))


Y = np.array([0.0, 1.0, 0.0])
X = np.array([1.0, 0.0, 0.0])
Z = np.array([0.0, 0.0, 1.0])


def schedule(t):
    """The idle's dials at time t (seconds, looping): how far each hind rests, each ear, the tail..."""
    t = t % LOOP
    rest_l = 1.0 - ramp(t, 3.0, 4.0) + ramp(t, 10.5, 11.5)
    rest_r = ramp(t, 5.0, 6.0) - ramp(t, 9.2, 10.2)
    lift_l = pulse(t, 3.0, 4.0) + pulse(t, 10.5, 11.5)
    lift_r = pulse(t, 5.0, 6.0) + pulse(t, 9.2, 10.2)
    swish = window(t, 1.5, 2.9, 0.25) * math.sin(2 * math.pi * (t - 1.5) / 1.4) \
        - window(t, 8.4, 9.8, 0.25) * math.sin(2 * math.pi * (t - 8.4) / 1.4)
    return {
        "rest": {"L": rest_l, "R": rest_r},
        "lift": {"L": lift_l, "R": lift_r},
        "head_dip": window(t, 6.0, 8.8, 0.9),
        "sniff": math.sin(2 * math.pi * (t - 6.0) / 0.8) * window(t, 6.6, 8.2, 0.3),
        "ear": {"L": pulse(t, 2.2, 2.75) + 0.5 * pulse(t, 10.0, 10.8),
                "R": pulse(t, 7.3, 7.85) + 0.5 * pulse(t, 10.0, 10.8)},
        "swish": swish,
        "breath": math.sin(2 * math.pi * t / 4.0),
        "sway": math.sin(2 * math.pi * t / LOOP),
        "nod": math.sin(2 * math.pi * t / 6.0 + 1.0),
    }


SIDES = {"L": -1.0, "R": 1.0}


def _two_bone(root, target, a, b, pole):
    """The middle joint of a two-bone chain from `root` reaching `target` (lengths a, b), bending
    towards `pole` (a direction)."""
    d_vec = np.asarray(target, float) - np.asarray(root, float)
    d = float(np.linalg.norm(d_vec))
    d = min(max(d, abs(a - b) + 1e-4), a + b - 1e-4)
    u = d_vec / np.linalg.norm(d_vec)
    v = np.asarray(pole, float) - (np.asarray(pole, float) @ u) * u
    v /= np.linalg.norm(v)
    cos_a = (a * a + d * d - b * b) / (2 * a * d)
    sin_a = math.sqrt(max(0.0, 1.0 - cos_a * cos_a))
    return np.asarray(root, float) + u * a * cos_a + v * a * sin_a


def pose(bones, t):
    """Every bone's A at time t."""
    s = schedule(t)
    A = {}
    head = {n: np.asarray(v[0]) for n, v in bones.items()}
    tail = {n: np.asarray(v[1]) for n, v in bones.items()}
    parent = {n: v[2] for n, v in bones.items()}

    def fk(name, R=np.eye(3), shift=(0.0, 0.0, 0.0)):
        p = A[parent[name]] if parent[name] else np.eye(4)
        A[name] = p @ _affine(None, shift) @ _about(head[name], R)

    A["root"] = np.eye(4)
    # The body sways onto the standing hind and sinks a little on a resting one.
    rl, rr = s["rest"]["L"], s["rest"]["R"]
    fk("body", _rot(X, math.radians(0.6) * (rl - rr)), (0.0, 0.016 * (rl - rr), -0.008 * (rl + rr)))
    # The hip drops on the resting side.
    fk("pelvis", _rot(X, math.radians(3.2) * (rl - rr)))
    fk("spine", _rot(Y, math.radians(0.35) * s["breath"]))
    fk("chest", _rot(Y, math.radians(-0.25) * s["breath"]))
    # The neck: a slow look about, the dip to the ground and a sniff at the bottom of it.
    dip = s["head_dip"]
    yaw = math.radians(3.0) * s["sway"]
    fk("neck1", _rot(Z, yaw * 0.4) @ _rot(Y, math.radians(-9.0) * dip + math.radians(1.0) * s["nod"]))
    fk("neck2", _rot(Z, yaw * 0.3) @ _rot(Y, math.radians(-8.0) * dip))
    fk("neck3", _rot(Z, yaw * 0.3) @ _rot(Y, math.radians(-5.0) * dip))
    fk("head", _rot(Y, math.radians(-10.0) * dip + math.radians(3.0) * s["sniff"] + math.radians(1.5) * s["nod"]))
    for side, sg in SIDES.items():
        # An ear flicks back (its tip towards +X), and both turn a little all the while.
        e = s["ear"][side]
        fk("ear." + side, _rot(Z, sg * math.radians(8.0) * s["nod"]) @ _rot(Y, math.radians(45.0) * e))
    # The tail: a swing to the side running down it, and a little sway.
    for i in range(1, 7):
        name = "tail%d" % i
        if name not in bones:
            break
        lag = schedule(t - 0.07 * (i - 1))
        amp = [1.5, 3.0, 3.5, 3.5, 3.0, 2.5][i - 1]  # ~17 degrees at the tip: a flick, not a flag
        ang = math.radians(amp) * lag["swish"] + math.radians(1.5) * lag["sway"]
        fk(name, _rot(X, ang))

    for side, sg in SIDES.items():
        # The forelegs stand where they are: the scapula rides the chest, the upper arm and the
        # straight forearm-and-cannon reach the planted fetlock.
        fk("scapula." + side)
        S = _apply(A["scapula." + side], head["upperarm." + side])
        E, F = head["forearm." + side], head["pastern." + side]
        a = np.linalg.norm(E - head["upperarm." + side])
        b = np.linalg.norm(F - E)
        line = F - head["upperarm." + side]
        pole = (E - head["upperarm." + side]) - ((E - head["upperarm." + side]) @ line) / (line @ line) * line
        pole = A["scapula." + side][:3, :3] @ pole
        E2 = _two_bone(S, F, a, b, pole)
        A["upperarm." + side] = _rigid(head["upperarm." + side], S, _between(E - head["upperarm." + side], E2 - S))
        Rf = _between(F - E, F - E2)
        A["forearm." + side] = _rigid(E, E2, Rf)
        A["cannon." + side] = _rigid(E, E2, Rf)
        A["pastern." + side] = np.eye(4)
        A["hoof." + side] = np.eye(4)

        # The hind: rested on the toe (the fetlock flexed, the cannon tipped forward, the hoof's
        # heel up), or flat; lifted a little as it changes.
        r = s["rest"][side]
        lift = s["lift"][side]
        toe_rest = tail["hhoof." + side]
        toe = toe_rest + np.array([-0.05 * r, 0.0, 0.05 * lift])
        Rh = _rot(Y, math.radians(-28.0) * r)  # the toe down, the heel up
        C = toe + Rh @ (head["hhoof." + side] - toe_rest)
        Rp = _rot(Y, math.radians(-45.0) * r)
        F = C + Rp @ (head["hpastern." + side] - head["hhoof." + side])
        Rc = _rot(Y, math.radians(-12.0) * r)
        Hk = F + Rc @ (head["hcannon." + side] - head["hpastern." + side])
        H = _apply(A["pelvis"], head["thigh." + side])
        St_r, Hk_r = head["shin." + side], head["hcannon." + side]
        a = np.linalg.norm(St_r - head["thigh." + side])
        b = np.linalg.norm(Hk_r - St_r)
        line = Hk_r - head["thigh." + side]
        pole = (St_r - head["thigh." + side]) - ((St_r - head["thigh." + side]) @ line) / (line @ line) * line
        pole = A["pelvis"][:3, :3] @ pole
        St = _two_bone(H, Hk, a, b, pole)
        A["thigh." + side] = _rigid(head["thigh." + side], H, _between(St_r - head["thigh." + side], St - H))
        A["shin." + side] = _rigid(St_r, St, _between(Hk_r - St_r, Hk - St))
        A["hcannon." + side] = _rigid(Hk_r, Hk, Rc)
        A["hpastern." + side] = _rigid(head["hpastern." + side], F, Rp)
        A["hhoof." + side] = _rigid(head["hhoof." + side], C, Rh)
    return A


def frames():
    """The loop's sample times: FPS a second, the last equal to the first."""
    n = int(LOOP * FPS)
    return [i / FPS for i in range(n + 1)]
