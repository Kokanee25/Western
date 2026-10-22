#!/usr/bin/env python3
"""The sound lab's measures (README.md): each scenario's heard.wav (what came out of the Master bus)
measured round its event, and the lab's table.

    python3 experiments/sound_lab/measure.py ROOT            # ROOT/measures.json, ROOT/table.md
    python3 experiments/sound_lab/measure.py ROOT --compare=BASE   # and each against a baseline

Loudness is ITU-R BS.1770 (K-weighted, both channels summed): `lufs_max` the loudest 400 ms
(momentary), `lufs` over the window. Times are game seconds from the event's mark.
"""
import json
import math
import os
import sys

import numpy as np
import scipy.io.wavfile as wavfile
from scipy.signal import lfilter

SPEED_OF_SOUND = 343.0


def k_weight(x, rate):
    # BS.1770-4's two stages at 48 kHz (the shelf, then the RLB high-pass).
    if rate != 48000:
        raise ValueError(f"K-weighting is written for 48 kHz, not {rate}")
    b1 = [1.53512485958697, -2.69169618940638, 1.19839281085285]
    a1 = [1.0, -1.69065929318241, 0.73248077421585]
    b2 = [1.0, -2.0, 1.0]
    a2 = [1.0, -1.99004745483398, 0.99007225036621]
    return lfilter(b2, a2, lfilter(b1, a1, x, axis=0), axis=0)


def db(x, floor=-120.0):
    return max(10.0 * math.log10(x), floor) if x > 0 else floor


def envelope(x, rate, ms=10.0):
    """RMS of both channels in ms-long hops, in dBFS."""
    hop = int(rate * ms / 1000)
    n = len(x) // hop
    if n == 0:
        return np.array([-120.0]), hop
    e = (x[: n * hop] ** 2).mean(axis=1).reshape(n, hop).mean(axis=1)
    return 10 * np.log10(np.maximum(e, 1e-12)), hop


def momentary(kw, rate):
    """BS.1770 momentary loudness (400 ms) every 10 ms."""
    win, hop = int(rate * 0.4), int(rate * 0.01)
    p = (kw ** 2).sum(axis=1)
    c = np.concatenate([[0.0], np.cumsum(p)])
    out = []
    for i in range(0, max(len(p) - win, 0) + 1, hop):
        out.append(-0.691 + db((c[i + win] - c[i]) / win))
    return np.array(out) if out else np.array([-120.0])


def steady(x, rate, t0, t1):
    """A sound that goes on (a fire, steps): its loudness over the window and its spectrum."""
    seg = x[int(t0 * rate): int(min(t1, len(x) / rate) * rate)]
    if len(seg) < rate * 0.5:
        return {}
    kw = k_weight(seg, rate)
    out = {"peak_dbfs": round(db(float(np.abs(seg).max()) ** 2), 1), "lufs_max": round(float(momentary(kw, rate).max()), 1),
           "lufs": round(-0.691 + db(float((kw ** 2).sum(axis=1).mean())), 1)}
    if out["peak_dbfs"] < -90:
        out["silent"] = True
        return out
    w = seg.mean(axis=1)
    spec = np.abs(np.fft.rfft(w * np.hanning(len(w)))) ** 2
    f = np.fft.rfftfreq(len(w), 1.0 / rate)
    out["centroid_hz"] = int(float((spec * f).sum()) / max(float(spec.sum()), 1e-12))
    return out


def measure_window(x, rate, t0, t1, floor_db):
    """One event: from its mark t0 to t1 (seconds into the WAV)."""
    a, b = int(max(t0 - 0.01, 0) * rate), int(min(t1, len(x) / rate) * rate)
    seg = x[a:b]
    if len(seg) < rate * 0.05:
        return {}
    env, hop = envelope(seg, rate)
    peak_env = float(env.max())
    out = {"peak_dbfs": round(db(float(np.abs(seg).max()) ** 2), 1)}
    gate = max(floor_db + 20.0, -70.0)
    above = np.nonzero(env > gate)[0]
    if len(above) == 0 or peak_env < -90:
        out["silent"] = True
        out["lufs_max"] = round(float(momentary(k_weight(seg, rate), rate).max()), 1)
        return out
    onset_i = int(above[0])
    onset = onset_i * hop / rate
    kw = k_weight(seg, rate)
    m = momentary(kw, rate)
    out["lufs_max"] = round(float(m.max()), 1)
    out["lufs"] = round(-0.691 + db(float((kw ** 2).sum(axis=1).mean())), 1)
    out["onset_s"] = round(onset - (t0 - max(t0 - 0.01, 0)), 3)
    last_40 = np.nonzero(env > peak_env - 40.0)[0]
    out["length_s"] = round((int(last_40[-1]) - onset_i + 1) * hop / rate, 2)
    pk = int(env.argmax())
    below = np.nonzero(env[pk:] < peak_env - 20.0)[0]
    out["decay20_s"] = round(int(below[0]) * hop / rate, 3) if len(below) else None
    s0 = onset_i * hop
    early = float((seg[s0: s0 + int(0.05 * rate)] ** 2).sum())
    late = float((seg[s0 + int(0.05 * rate):] ** 2).sum())
    out["c50_db"] = round(db(early) - db(late), 1) if late > 0 else None
    # The spectrum of its first half second.
    w = seg[s0: s0 + int(0.5 * rate)].mean(axis=1)
    if len(w) > 256:
        spec = np.abs(np.fft.rfft(w * np.hanning(len(w)))) ** 2
        f = np.fft.rfftfreq(len(w), 1.0 / rate)
        tot = float(spec.sum()) or 1e-12
        out["centroid_hz"] = int(float((spec * f).sum()) / tot)
        bands = {"<100": (0, 100), "100-500": (100, 500), "500-2k": (500, 2000), "2k-6k": (2000, 6000), ">6k": (6000, rate / 2)}
        out["bands_db"] = {k: round(db(float(spec[(f >= lo) & (f < hi)].sum()) / tot), 1) for k, (lo, hi) in bands.items()}
    el, er = float((seg[:, 0] ** 2).sum()), float((seg[:, 1] ** 2).sum())
    out["balance_db"] = round(db(el) - db(er), 1)
    return out


def load(path):
    rate, d = wavfile.read(path)
    x = d.astype(np.float64) / 32768.0
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    return rate, x


def events_of(s):
    """(label, mark t, end t, distance) for a scenario's events, from its marks."""
    kind = s["spec"]["kind"]
    marks = s["marks"]
    end = s["seconds"]
    out = []
    pick = {"gun": ["shot_fired"], "pass": ["fired"], "impact": ["fired"], "ricochet": ["fired"], "dynamite": ["exploded"]}
    if kind in pick:
        ms = [m for m in marks if m["name"] in pick[kind]]
        if kind == "gun":
            ms = [m for m in ms if m.get("who") == "player"]
        if ms:
            m = ms[0]
            t1 = min(end, m["t"] + s["spec"]["window"]) if "window" in s["spec"] else end
            out.append(("event", m["t"], t1, s["setup"].get("distance_m", m.get("distance_m"))))
    elif kind in ("fire", "steps"):
        seg = [m for m in marks if m["name"] not in ("shot_fired", "exploded")]
        for i, m in enumerate(seg):
            t1 = seg[i + 1]["t"] if i + 1 < len(seg) else end
            out.append((m["name"], m["t"], t1, m.get("distance_m")))
    elif kind == "fight":
        ms = [m for m in marks if m["name"] == "fight"]
        if ms:
            out.append(("fight", ms[0]["t"], end, None))
    return out


def measure_scenario(d):
    s = json.load(open(os.path.join(d, "summary.json")))
    rate, x = load(os.path.join(d, "heard.wav"))
    fl, _ = envelope(x[: int(0.4 * rate)], rate)
    floor_db = float(fl.max()) if len(fl) else -120.0
    r = {"scenario": s["scenario"], "kind": s["spec"]["kind"], "floor_dbfs": round(max(floor_db, -120.0), 1),
         "sounds": sorted({b["sound"] for b in s["started"]}), "voices_max": s.get("voices_max", 0), "events": {}}
    for label, t0, t1, dist in events_of(s):
        if s["spec"]["kind"] in ("fire", "steps"):
            m = steady(x, rate, t0, t1)
        else:
            m = measure_window(x, rate, t0, t1, floor_db)
        if dist is not None:
            m["distance_m"] = dist
        r["events"][label] = m
    if s["spec"]["kind"] == "gun":
        shot = [b for b in s["started"] if b["sound"] in ("gunshot", "shotgun")]
        if shot:
            r["godot_db_at_ears"] = shot[0].get("godot_db_at_ears")
    if s["spec"]["kind"] == "fight":
        import csv
        rows = list(csv.DictReader(open(os.path.join(d, "voices.csv"))))
        v = np.array([int(row["voices"]) for row in rows]) if rows else np.array([0])
        ms = np.array([float(row["frame_ms"]) for row in rows]) if rows else np.array([0.0])
        r["fight"] = {"voices_max": int(v.max()), "voices_p95": float(np.percentile(v, 95)), "voices_mean": round(float(v.mean()), 2),
                      "began": len(s["started"]), "began_by_sound": _count([b["sound"] for b in s["started"]]),
                      "frame_ms_median": round(float(np.median(ms)), 2), "shots": len([m for m in s["marks"] if m["name"] == "shot_fired"])}
    if s["spec"]["kind"] == "cost":
        r["cost"] = s["setup"].get("cost")
    r["hits"] = s.get("hits", [])
    return r


def _count(a):
    out = {}
    for k in a:
        out[k] = out.get(k, 0) + 1
    return dict(sorted(out.items(), key=lambda kv: -kv[1]))


def table(root, compare=None):
    rows = {}
    for name in sorted(os.listdir(root)):
        d = os.path.join(root, name)
        if os.path.exists(os.path.join(d, "summary.json")) and os.path.exists(os.path.join(d, "heard.wav")):
            try:
                rows[name] = measure_scenario(d)
            except Exception as e:  # one bad run shouldn't lose the table
                rows[name] = {"scenario": name, "error": str(e)}
    derived = derive(rows)
    json.dump({"scenarios": rows, "derived": derived}, open(os.path.join(root, "measures.json"), "w"), indent=1)
    base = None
    if compare:
        base = json.load(open(os.path.join(compare, "measures.json")))["scenarios"]
    lines = ["| scenario | dist m | peak dBFS | LUFS max | onset s | length s | decay20 s | C50 dB | centroid Hz | sounds |",
             "|---|---|---|---|---|---|---|---|---|---|"]
    for name, r in rows.items():
        for label, m in r.get("events", {}).items():
            lab = name if label == "event" else f"{name} / {label}"
            def v(k, m=m, label=label, name=name):
                val = m.get(k)
                if base and val is not None and isinstance(val, (int, float)):
                    b = base.get(name, {}).get("events", {}).get(label, {}).get(k)
                    if isinstance(b, (int, float)):
                        return f"{val} ({val - b:+.1f})" if isinstance(val, float) else f"{val} ({val - b:+d})"
                return "–" if val is None else str(val)
            lines.append(f"| {lab} | {v('distance_m')} | {v('peak_dbfs')} | {v('lufs_max')} | {v('onset_s')} | {v('length_s')} | "
                         f"{v('decay20_s')} | {v('c50_db')} | {v('centroid_hz')} | {', '.join(r.get('sounds', [])) or 'none'} |")
    lines += ["", "```", json.dumps(derived, indent=1), "```"]
    open(os.path.join(root, "table.md"), "w").write("\n".join(lines) + "\n")
    print("\n".join(lines[:2 + sum(len(r.get('events', {})) for r in rows.values())]))
    print(json.dumps(derived, indent=1))


def derive(rows):
    """Falloff a doubling of distance, delay against the speed of sound, inside against out, walls."""
    out = {}
    ev = lambda n: rows.get(n, {}).get("events", {}).get("event", {})
    for w in ("revolver", "shotgun"):
        for place, ds in (("street", ["2", "7", "20", "80"]), ("saloon", ["2", "20", "80"])):
            pts = [(ev(f"{w}_{place}_{d}").get("distance_m"), ev(f"{w}_{place}_{d}").get("lufs_max")) for d in ds]
            pts = [(d, l) for d, l in pts if d and l is not None]
            if len(pts) >= 2:
                xs = np.log2([p[0] for p in pts])
                ys = np.array([p[1] for p in pts])
                slope = float(np.polyfit(xs, ys, 1)[0])
                out[f"{w}_{place}_falloff_db_per_doubling"] = round(slope, 1)
            delays = {}
            for d in ds:
                e = ev(f"{w}_{place}_{d}")
                if e.get("onset_s") is not None and e.get("distance_m"):
                    delays[d] = {"heard_after_s": e["onset_s"], "sound_would_take_s": round(e["distance_m"] / SPEED_OF_SOUND, 3)}
            if delays:
                out[f"{w}_{place}_delay"] = delays
        a, b = ev(f"{w}_street_2"), ev(f"{w}_saloon_2")
        if a and b:
            out[f"{w}_inside_vs_out_at_2m"] = {k: [a.get(k), b.get(k)] for k in ("lufs_max", "decay20_s", "c50_db", "length_s", "centroid_hz")}
        s7, d7, w7 = ev(f"{w}_street_7"), ev(f"{w}_saloon_door7"), ev(f"{w}_saloon_wall7")
        if s7 and d7 and w7:
            out[f"{w}_open_door_wall_at_7m"] = {k: [s7.get(k), d7.get(k), w7.get(k)] for k in ("distance_m", "lufs_max", "centroid_hz")}
    for place in ("out", "in"):
        pts = [(ev(f"dynamite_{place}_{d}").get("distance_m"), ev(f"dynamite_{place}_{d}").get("lufs_max")) for d in ("5", "30", "100")]
        pts = [(d, l) for d, l in pts if d and l is not None]
        if len(pts) >= 2:
            out[f"dynamite_{place}_falloff_db_per_doubling"] = round(float(np.polyfit(np.log2([p[0] for p in pts]), [p[1] for p in pts], 1)[0]), 1)
            out[f"dynamite_{place}_lufs"] = {str(round(p[0])): p[1] for p in pts}
    return out


if __name__ == "__main__":
    root = sys.argv[1]
    comp = None
    for a in sys.argv[2:]:
        if a.startswith("--compare="):
            comp = a.split("=", 1)[1]
    table(root, comp)
