"""The library clips (issue #529): every candidate take in tools/blender/library_picks.json, from
Quaternius' Universal Animation Library and KayKit's Character Animations (both CC0; fetched by
tools/blender/fetch_library.sh into build/library_src/), retargeted onto our 17 segments by
retarget_motion.py's method, cleaned and judged; then each move's picked take written as the clip
HumanBody plays (assets/animations/library/<move>.json, MotionClip) beside its glTF, and one
manifest (assets/animations/library/manifest.json: source, licence, length, loop or not).

    ~/.venvs/studio/bin/python tools/blender/library_motion.py takes     # every take -> build/library/takes/, takes.json
    ~/.venvs/studio/bin/python tools/blender/library_motion.py promote   # each move's `pick` -> assets/animations/library/

Clean-up (docs/MOCAP.md): a looped clip is made seamless (its last frame turned onto its first over
the last quarter second, each joint by the turn between them); an in-place gait (the libraries'
walks don't travel) gets its speed from the planted foot sliding back under him, so the game can
drive its phase by the ground he covers and the planted foot stays put; a clip played once is
trimmed of its still ends and its feet held (retarget_motion.hold_feet). A take with both hands
together while it aims (a two-handed pistol grip: not 1882) is marked and not picked.
Written for this project.
"""
import json
import math
import os
import shutil
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import retarget_motion as rm

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PICKS = os.path.join(HERE, "library_picks.json")
SRC = os.path.join(ROOT, "build", "library_src")
WORK = os.path.join(ROOT, "build", "library")
OUT = os.path.join(ROOT, "assets", "animations", "library")
LIBS = {
    "uthana": {"pack": "Uthana text-to-motion (uthana/text-to-motion-diffusion-v2 on Replicate), generated for this project by the Character Studio (motions/gun_moves)",
               "licence": "Uthana: generated for this project (Replicate's terms)", "page": "https://replicate.com/uthana/text-to-motion-diffusion-v2"},
    "cmu": {"pack": "CMU Graphics Lab Motion Capture Database (B. Hahne's BVH conversion)", "licence": "CMU: free for research and commercial use",
            "page": "http://mocap.cs.cmu.edu"},
    "quaternius": {"pack": "Quaternius, Universal Animation Library (UAL1 Standard, free)", "licence": "CC0 1.0",
                   "page": "https://quaternius.com/packs/universalanimationlibrary.html"},
    "kaykit": {"pack": "Kay Lousberg, KayKit Character Animations 1.1 (Rig_Medium)", "licence": "CC0 1.0",
               "page": "https://kaylousberg.itch.io/kaykit-character-animations"},
}
SEAM_S = 0.25


def _q_mul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return [aw * bx + ax * bw + ay * bz - az * by, aw * by - ax * bz + ay * bw + az * bx,
            aw * bz + ax * by - ay * bx + az * bw, aw * bw - ax * bx - ay * by - az * bz]


def _q_inv(q):
    return [-q[0], -q[1], -q[2], q[3]]


def _q_slerp_id(q, w):
    """The identity turned toward q by w (0..1)."""
    if q[3] < 0:
        q = [-c for c in q]
    ang = 2 * math.acos(max(-1.0, min(1.0, q[3])))
    s = math.sqrt(max(0.0, 1 - q[3] * q[3]))
    if s < 1e-6:
        return [0.0, 0.0, 0.0, 1.0]
    axis = [c / s for c in q[:3]]
    h = ang * w / 2
    return [axis[0] * math.sin(h), axis[1] * math.sin(h), axis[2] * math.sin(h), math.cos(h)]


def _norm(q):
    n = math.sqrt(sum(c * c for c in q)) or 1.0
    q = [c / n for c in q]
    if q[3] < 0:
        q = [-c for c in q]
    return [round(c, 5) for c in q]


def _angle(a, b):
    """The turn between two unit quaternions (rad), from their chord (acos of their dot loses half a
    degree to 5-digit rounding near 1)."""
    if sum(x * y for x, y in zip(a, b)) < 0:
        b = [-c for c in b]
    chord = math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)))
    return 4 * math.asin(min(1.0, chord / 2))


def seam_error(frames):
    """The turn (deg, summed over the joints) between the last frame and the first."""
    return round(math.degrees(sum(_angle(frames[-1][s], frames[0][s]) for s in frames[0] if s in frames[-1])), 2)


def make_seamless(clip):
    """Turn the last SEAM_S of a looped clip onto its first frame: each joint's last frame meets
    its first exactly, the turn between them spread smoothly over the frames before. The hips'
    height the same. Returns the seam's error before and after (deg)."""
    fr = clip["frames"]
    n = len(fr)
    before = seam_error(fr)
    m = max(2, min(n // 3, int(SEAM_S * clip["fps"])))
    for seg in fr[0]:
        if seg not in fr[-1]:
            continue
        delta = _q_mul(fr[0][seg], _q_inv(fr[-1][seg]))
        for k in range(m + 1):
            i = n - 1 - m + k
            w = k / m
            w = w * w * (3 - 2 * w)
            fr[i][seg] = _norm(_q_mul(_q_slerp_id(delta, w), fr[i][seg]))
    hh = clip["hip_height"]
    dh = hh[0] - hh[-1]
    for k in range(m + 1):
        i = n - 1 - m + k
        w = k / m
        hh[i] = round(hh[i] + dh * w * w * (3 - 2 * w), 4)
    return before, seam_error(fr)


def _q_rot(q, v):
    x, y, z, w = q
    u = np.array([x, y, z])
    v = np.asarray(v, dtype=float)
    return v + 2.0 * np.cross(u, np.cross(u, v) + w * v)


def _carried_slide(feet, v, fps):
    """The lower ankle's level speed (m/s) over the loop with his hips carried at `v` (m/s): how much
    the foot carrying him skates."""
    n = len(feet["l"])
    low = {k: float(np.min(feet[k][:, 1])) for k in feet}
    tot, cnt = 0.0, 0
    for i in range(1, n):
        s = "l" if feet["l"][i][1] < feet["r"][i][1] else "r"
        o = "r" if s == "l" else "l"
        # Carrying him: the lower foot, and on the ground (within 2.5 cm of its lowest) both frames
        # (in a run's flight neither foot carries him).
        on = feet[s][i][1] < low[s] + 0.025 and feet[s][i - 1][1] < low[s] + 0.025
        if on and feet[s][i - 1][1] < feet[o][i - 1][1]:
            d = feet[s][i] - feet[s][i - 1] + v / fps
            tot += math.hypot(d[0], d[2])
            cnt += 1
    return tot / max(cnt, 1) * fps


def our_feet(clip, rig, point="sole"):
    """Each frame, his two soles (the foot segment's middle, its `a`..`b` line at the ground) in his
    hips' frame, worked forward through our own rig from the clip's turns: what the game's man does
    with the clip, whatever the source's proportions were (KayKit's are a chibi's)."""
    order = ["pelvis", "thigh_l", "shin_l", "foot_l", "thigh_r", "shin_r", "foot_r"]
    out = {"l": [], "r": []}
    for fr in clip["frames"]:
        G, P = {}, {}
        for seg in order:
            q = fr.get(seg, [0.0, 0.0, 0.0, 1.0])
            par = rig[seg]["parent"] or None
            piv = np.array(rig[seg]["pivot"])
            if par is None:
                G[seg] = q
                P[seg] = np.zeros(3)
            else:
                G[seg] = _q_mul(G[par], q)
                P[seg] = P[par] + _q_rot(G[par], piv - np.array(rig[par]["pivot"]))
        for side in ("l", "r"):
            f = "foot_" + side
            if point == "ankle":
                out[side].append(P[f])
                continue
            mid = (np.array(rig[f]["a"]) + np.array(rig[f]["b"])) * 0.5 - np.array(rig[f]["pivot"])
            out[side].append(P[f] + _q_rot(G[f], mid))
    return {s: np.array(v) for s, v in out.items()}


def gait_speed(clip, rig):
    """How fast the ground goes by under him (m/s, on our rig), and which way in his frame (x his
    right, -z ahead): the planted foot's level speed back under his hips (the frames a foot is the
    lower and within 4 cm of the lowest it gets), the clip in place (the libraries' are). Also how
    much the planted foot's speed wanders over the stance (m/s; low: it stays planted at that
    pace; after the fit, the carrying foot's skate left at that speed, m/s)."""
    fps = clip["fps"]
    feet = our_feet(clip, rig)
    floor = min(float(np.min(feet["l"][:, 1])), float(np.min(feet["r"][:, 1])))
    vs = []
    for i in range(1, len(feet["l"])):
        low = "l" if feet["l"][i][1] < feet["r"][i][1] else "r"
        if feet[low][i][1] - floor > 0.04:
            continue
        d = (feet[low][i] - feet[low][i - 1]) * fps
        d[1] = 0.0
        vs.append(-d)
    if not vs:
        return 0.0, [0.0, 0.0, -1.0], 0.0
    vs = np.array(vs)
    v = np.median(vs, axis=0)
    sp = float(np.linalg.norm(v))
    # Fitted: the speed along that way that keeps the foot carrying him (the lower ankle) stillest,
    # walked over the loop (a run's feet both leave the ground, which the median above can't tell).
    ank = our_feet(clip, rig, point="ankle")
    way = v / sp if sp > 1e-6 else np.array([0.0, 0.0, -1.0])
    best = (1e9, sp)
    for k in np.linspace(0.4, 2.5, 85):
        cost = _carried_slide(ank, way * sp * k, fps)
        if cost < best[0]:
            best = (cost, sp * k)
    v = way * best[1]
    sp = best[1]
    wander = round(best[0], 3)
    return sp, [round(float(c), 3) for c in (v / sp if sp > 1e-6 else np.array([0.0, 0.0, -1.0]))], round(wander, 3)


def _yaw_of_q(q):
    """His heading (rad) from a pelvis turn: where its -z points, level."""
    f = _q_rot(q, [0.0, 0.0, -1.0])
    return math.atan2(-f[0], -f[2])


def find_cycle(clip, lo_s, hi_s, skip=0.2, min_speed=0.0):
    """One loop out of a long take (a CMU walk goes on for metres, turns at its ends): the pair of
    frames i < j, j - i between lo_s and hi_s seconds, in the take's steady middle (its first and
    last `skip` left out), whose poses and the poses either side of them match best (each joint's
    turn summed; the pelvis's includes his heading, so a stretch where he turns scores badly).
    A gait's loop must go somewhere (`min_speed`, m/s of his hips over it): a still stretch matches
    itself best of all. Returns (i, j, cost in degrees)."""
    fr = clip["frames"]
    n = len(fr)
    fps = clip["fps"]
    lo, hi = max(2, int(lo_s * fps)), int(hi_s * fps)
    a, b = int(n * skip), int(n * (1 - skip))
    segs = [s for s in fr[0]]

    def d(x, y):
        return sum(_angle(fr[x][s], fr[y][s]) for s in segs if s in fr[x] and s in fr[y])

    best = (None, None, 1e9)
    for i in range(max(1, a), b):
        for j in range(i + lo, min(i + hi, b) + 1):
            if j + 1 >= n:
                break
            if min_speed > 0.0:
                r0, r1 = clip["root"][i], clip["root"][j]
                if math.hypot(r1[0] - r0[0], r1[2] - r0[2]) * fps / (j - i) < min_speed:
                    continue
            c = d(i, j) + 0.5 * (d(i - 1, j - 1) + d(i + 1, j + 1))
            if c < best[2]:
                best = (i, j, c)
    return best[0], best[1], round(math.degrees(best[2]), 2)


def level_heading(clip):
    """Turn the loop so he faces -z on the whole (the mean of his pelvis's heading over it taken
    out): a cut from the middle of a take faces whatever way he was walking then."""
    ys = [_yaw_of_q(fr["pelvis"]) for fr in clip["frames"] if "pelvis" in fr]
    if not ys:
        return 0.0
    mean = math.atan2(sum(math.sin(y) for y in ys), sum(math.cos(y) for y in ys))
    q = [0.0, math.sin(-mean / 2), 0.0, math.cos(-mean / 2)]
    for fr in clip["frames"]:
        if "pelvis" in fr:
            fr["pelvis"] = _norm(_q_mul(q, fr["pelvis"]))
    return round(math.degrees(mean), 1)


def mirror(clip):
    """Left for right: each joint's turn reflected across his middle (x -> -x: a quaternion's y and
    z flip) and the sides swapped. A sidestep to his right becomes one to his left."""
    out = []
    for fr in clip["frames"]:
        m = {}
        for s, q in fr.items():
            other = s[:-2] + ("_r" if s.endswith("_l") else "_l") if s.endswith(("_l", "_r")) else s
            m[other] = [q[0], -q[1], -q[2], q[3]]
        out.append(m)
    clip["frames"] = out
    for k in ("root", "hips_path", "hands_path"):
        if clip.get(k):
            clip[k] = [[-p[0], p[1], p[2]] for p in clip[k]]
    if clip.get("feet"):
        clip["feet"] = {"l": [[-p[0], p[1], p[2]] for p in clip["feet"]["r"]],
                        "r": [[-p[0], p[1], p[2]] for p in clip["feet"]["l"]]}


def source_path(sources, lib, part):
    s = sources[lib]
    return os.path.join(SRC, s % part if "%s" in s else s)


def run_take(lib, part, anim, move, kind, sources, rig, out_dir, opts=None):
    opts = opts or {}
    path = source_path(sources, lib, part)
    rest_path = os.path.join(SRC, opts["rest"]) if opts.get("rest") else None
    names, rest, frames, _ = rm.read_source(path, rest_path=rest_path, anim=anim, work=os.path.join(WORK, "converted"))
    clip, notes = rm.retarget(names, rest, frames, rig, move)
    j = {"lib": lib, "file": os.path.basename(path), "anim": anim, "frames_in": len(frames),
         "missing": notes.get("missing", []), "scale": notes.get("scale")}
    if opts.get("cycle"):
        # A long take (CMU's): one loop cut from its steady middle, facing ahead.
        lo, hi = opts["cycle"]
        i, k, cost = find_cycle(clip, lo, hi, opts.get("skip", 0.2), opts.get("min_speed", 0.5 if kind == "gait" else 0.0))
        rm._cut(clip, i, k)
        j["cycle"] = [round(i / clip["fps"], 2), round(k / clip["fps"], 2)]
        j["cycle_cost_deg"] = cost
        j["heading_taken_deg"] = level_heading(clip)
    if opts.get("mirror"):
        mirror(clip)
        j["mirrored"] = True
    # His hands' least distance apart (both hands near: a two-handed grip).
    bones = notes["bones"]
    if "hand_l" in bones and "hand_r" in bones:
        d = []
        for pose in frames:
            a = rm.to_godot_m(pose[bones["hand_l"]])[1]
            b = rm.to_godot_m(pose[bones["hand_r"]])[1]
            d.append(float(np.linalg.norm(a - b)) * notes["scale"])
        j["hands_apart_min_m"] = round(min(d), 3)
        j["hands_apart_mean_m"] = round(float(np.mean(d)), 3)
    if kind in ("once", "hold"):
        cut = rm.trim(clip, 0.03)
        j["trimmed"] = cut
        before, after = rm.hold_feet(clip)
        j["slide_before_m"], j["slide_after_m"] = before, after
    else:
        if len(clip["frames"]) >= 4:
            j["seam_before_deg"], j["seam_after_deg"] = make_seamless(clip)
        if kind == "gait":
            sp, way, wander = gait_speed(clip, rig)
            j["speed_mps"], j["way"], j["plant_wander_mps"] = round(sp, 3), way, wander
            # The ground he covers a loop: the game turns his distance into the clip's phase.
            j["stride_m"] = round(sp * (len(clip["frames"]) - 1) / clip["fps"], 3)
            # In place for the game: his walking moves him, never the clip's travel.
            clip["root"] = [[0.0, 0.0, 0.0] for _ in clip["root"]]
    e = rm.energy(clip)
    j["seconds"] = round((len(clip["frames"]) - 1) / clip["fps"], 3)
    j["jitter"] = round(float(np.mean(np.abs(np.diff(e)))), 4) if len(e) > 2 else 0.0
    j["hip_min_legs"] = round(min(clip["hip_height"]), 3)
    j["hip_max_legs"] = round(max(clip["hip_height"]), 3)
    return clip, j


def write_clip(clip, j, move, kind, out_dir, rig, glb=True):
    lib = LIBS[j["lib"]]
    path = os.path.join(out_dir, move + ".json")
    out = rm.write_json(clip, path, "%s %s" % (j["file"], j["anim"]), (), {}, "%s (%s)" % (lib["pack"], lib["licence"]))
    out["name"] = "library/" + move
    out["loop"] = kind != "once"
    out["kind"] = kind
    for k in ("speed_mps", "stride_m", "way"):
        if k in j:
            out[k] = j[k]
    with open(path, "w") as f:
        json.dump(out, f, separators=(",", ":"))
    if glb and rm.bpy is not None:
        try:
            rm.write_gltf(clip, rig, os.path.join(out_dir, move + ".glb"))
        except Exception as e:  # the JSON is what the game plays; the glTF is the record
            j["gltf_error"] = str(e)[:200]


def main(argv):
    what = argv[0] if argv else "takes"
    picks = json.load(open(PICKS))
    rig = json.load(open(rm.RIG_REST))
    sources = picks["sources"]
    only = rm.opt("only", "", argv)
    only = set(only.split(",")) if only else None
    if what == "takes":
        work = os.path.join(WORK, "takes")
        os.makedirs(work, exist_ok=True)
        report = {}
        for move, m in picks["moves"].items():
            if only and move not in only:
                continue
            for i, take in enumerate(m["takes"]):
                lib, part, anim = take[:3]
                clip, j = run_take(lib, part, anim, move, m["kind"], sources, rig, work, take[3] if len(take) > 3 else None)
                write_clip(clip, j, "%s_%d" % (move, i), m["kind"], work, rig, glb=False)
                report.setdefault(move, []).append(j)
                print("%s %d %s/%s: %s" % (move, i, lib, anim, json.dumps({k: j[k] for k in j if k in (
                    "seconds", "speed_mps", "way", "plant_wander_mps", "stride_m", "cycle", "cycle_cost_deg", "heading_taken_deg", "seam_before_deg", "slide_after_m", "hands_apart_min_m", "jitter", "missing")})))
        with open(os.path.join(WORK, "takes.json"), "w") as f:
            json.dump(report, f, indent=1)
        return
    if what == "promote":
        os.makedirs(OUT, exist_ok=True)
        manifest = {"_doc": "The library clips (issue #529; tools/blender/library_motion.py, picks in tools/blender/library_picks.json): "
                            "each move's clip, where it came from, its licence, its length and whether it loops. "
                            "HumanBody plays them through LibraryMotion when Settings.library_motion is on.",
                    "clips": {}}
        for move, m in picks["moves"].items():
            if "pick" not in m:
                continue
            take = m["takes"][m["pick"]]
            lib, part, anim = take[:3]
            clip, j = run_take(lib, part, anim, move, m["kind"], sources, rig, OUT, take[3] if len(take) > 3 else None)
            if m.get("parts"):
                # Only these segments: the rest of him stays the pose's.
                clip["frames"] = [{k: v for k, v in fr.items() if k in m["parts"]} for fr in clip["frames"]]
            drop = m.get("drop", picks.get("drop", []))
            if drop:
                # Left to the pose (and FaceLife's looks): CMU's two neck bones go into our neck and
                # head as a kink, the neck back and the head forward (the chin poked out; standing
                # still, the chin on his chest).
                clip["frames"] = [{k: v for k, v in fr.items() if k not in drop} for fr in clip["frames"]]
            write_clip(clip, j, move, m["kind"], OUT, rig)
            entry = {"source": "%s: %s%s" % (LIBS[lib]["pack"], j["file"], (", animation " + anim) if anim else ""), "licence": LIBS[lib]["licence"],
                     "page": LIBS[lib]["page"], "length_s": j["seconds"], "loop": m["kind"] != "once", "kind": m["kind"]}
            if m.get("parts"):
                entry["parts"] = m["parts"]
            if drop:
                entry["left_to_the_pose"] = drop
            for k in ("speed_mps", "stride_m", "seam_before_deg", "seam_after_deg", "slide_after_m", "missing", "why"):
                if k in j:
                    entry[k] = j[k]
            if m.get("why"):
                entry["why"] = m["why"]
            if m.get("variant_of"):
                entry["variant_of"] = m["variant_of"]
                entry["style"] = bool(m.get("style", False))
            manifest["clips"][move] = entry
            print("%s <- %s/%s %s" % (move, lib, anim, json.dumps({k: entry[k] for k in entry if k in ("length_s", "speed_mps", "seam_after_deg")})))
        with open(os.path.join(OUT, "manifest.json"), "w") as f:
            json.dump(manifest, f, indent=1)
        return
    sys.exit("library_motion: takes | promote")


if __name__ == "__main__":
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    main(args)
