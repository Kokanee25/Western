#!/usr/bin/env python3
"""The train lab's graphs (issue #543), from run.gd's CSVs and a bridge run's frame log.

    python3 experiments/train_lab/graphs.py --runs=build/train_lab [--frames=build/train_lab/frames_curve.csv] --out=DIR

Writes speed_time.png (speed against time for the four scenarios), speed_distance.png (speed
against distance along the line, with the line's grade under it), the whole run A to B, and, with
--frames, jitter.png: each car's heading turn per drawn frame through the bend against what the
line's curvature asks (v x k), and the trucks' distance off the line. Prints the checks.
"""
import csv
import json
import math
import os
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402


def opt(name, default=None):
    for a in sys.argv[1:]:
        if a.startswith("--" + name + "="):
            return a.split("=", 1)[1]
    return default


def read(path):
    with open(path) as f:
        rows = list(csv.DictReader(f))
    out = []
    for r in rows:
        d = {}
        for k, v in r.items():
            try:
                d[k] = float(v)
            except ValueError:
                d[k] = v
        out.append(d)
    return out


NAMES = {
    "start": "Start from a stand at A, regulator full",
    "stop30": "Stop from 30 km/h, full brake (level)",
    "climb": "Into the 2.5 % climb at 38 km/h, regulator full",
    "descent": "Down the 2.5 % from 15 km/h, coasting",
}


def main():
    runs = opt("runs", "build/train_lab")
    out = opt("out", runs)
    os.makedirs(out, exist_ok=True)
    summary = json.load(open(os.path.join(runs, "summary.json")))
    data = {k: read(os.path.join(runs, k + ".csv")) for k in list(NAMES) + ["whole_run"]}

    # Speed against time.
    fig, axes = plt.subplots(2, 2, figsize=(11, 7))
    for ax, k in zip(axes.flat, NAMES):
        rows = data[k]
        t = [r["t"] for r in rows]
        ax.plot(t, [r["v"] * 3.6 for r in rows], color="#b5562b", lw=2, label="speed")
        ax.set_title(NAMES[k], fontsize=10)
        ax.set_xlabel("seconds")
        ax.set_ylabel("km/h")
        ax.grid(alpha=0.3)
        ax2 = ax.twinx()
        ax2.plot(t, [r["regulator"] * 100 for r in rows], color="#3a6ea5", lw=1, ls="--", label="regulator %")
        ax2.plot(t, [r["brake"] * 100 for r in rows], color="#777", lw=1, ls=":", label="brake %")
        ax2.set_ylim(0, 105)
        ax2.set_ylabel("%", color="#555")
        s = summary[k]
        if k == "start":
            ax.axhline(25, color="#999", lw=0.8)
            ax.annotate("25 km/h at %.1f s (%.0f m)" % (s["t25"], s["s25"]), (s["t25"], 25), xytext=(10, -40),
                        textcoords="offset points", arrowprops={"arrowstyle": "->"})
        if k == "stop30":
            ax.text(0.4, 0.8, "stops in %.0f m, %.1f s" % (s["distance"], s["time"]), transform=ax.transAxes)
        if k == "climb":
            ax.text(0.3, 0.8, "falls to %.1f km/h (settles at %.0f)" % (s["lowest_kmh"], s["balance_on_climb_kmh"]),
                    transform=ax.transAxes)
        if k == "descent":
            ax.text(0.05, 0.8, "gathers to %.1f km/h at the foot" % s["foot_kmh"], transform=ax.transAxes)
    h1, l1 = axes.flat[0].get_legend_handles_labels()
    fig.suptitle("Train lab step 1: speed against time (proposed dials, config/train.tres)")
    fig.tight_layout()
    fig.savefig(os.path.join(out, "speed_time.png"), dpi=90)
    plt.close(fig)

    # Speed against distance, with the grade under it.
    fig, axes = plt.subplots(3, 1, figsize=(11, 9), sharex=False)
    ax = axes[0]
    for k, c in [("start", "#b5562b"), ("stop30", "#333"), ("climb", "#3a6ea5"), ("descent", "#5a9a4a")]:
        rows = data[k]
        ax.plot([r["s"] for r in rows], [r["v"] * 3.6 for r in rows], color=c, lw=2, label=NAMES[k])
    ax.set_ylabel("km/h")
    ax.set_xlim(0, 1500)
    ax.legend(fontsize=8, loc="upper left")
    ax.grid(alpha=0.3)
    ax.set_title("Speed against distance along the line (the train's front)")
    ax = axes[1]
    rows = data["whole_run"]
    ax.plot([r["s"] for r in rows], [r["v"] * 3.6 for r in rows], color="#b5562b", lw=2, label="speed")
    ax.set_ylabel("km/h")
    ax.set_xlim(0, 1500)
    ax.grid(alpha=0.3)
    ax.set_title("The whole run, A to B, a simple driver holding 25 km/h (%.0f s; stops %.1f m from B)" % (
        summary["whole_run"]["time"], -summary["whole_run"]["short_of_B"]))
    for m, at in (("A", 120), ("B", 1440)):
        ax.axvline(at, color="#999", lw=0.8)
        ax.text(at + 5, 2, m)
    ax = axes[2]
    ax.plot([r["s"] for r in rows], [r["grade"] * 100 for r in rows], color="#555", lw=1.5)
    ax.axvspan(400, 648, color="#e8c070", alpha=0.3, label="the bend (120 m radius)")
    ax.set_xlim(0, 1500)
    ax.set_ylabel("grade % under the train")
    ax.set_xlabel("metres along the line")
    ax.legend(fontsize=8)
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(os.path.join(out, "speed_distance.png"), dpi=90)
    plt.close(fig)

    frames = opt("frames")
    if frames and os.path.exists(frames):
        jitter(read(frames), out)


def jitter(rows, out):
    """Each car's heading change a metre of drawn distance through the bend (its curvature as drawn),
    against the line's own (smooth = no jitter). Per metre, not per second: the frames fall between
    ticks, so a per-second rate would show the tick timing, not the cars."""
    n = sum(1 for k in rows[0] if k.startswith("yaw"))
    fig, axes = plt.subplots(2, 1, figsize=(11, 7))
    worst = 0.0
    for c in range(n):
        s, k = [], []
        for a, b in zip(rows, rows[1:]):
            ds = b["s"] - a["s"]
            if ds < 0.02:  # the same tick drawn twice, or standing
                continue
            d = b["yaw%d" % c] - a["yaw%d" % c]
            d = (d + math.pi) % (2 * math.pi) - math.pi
            s.append(b["s"])
            k.append(d / ds * 1000.0)  # 1/km
        # Roughness: the largest jump of the drawn curvature from one frame to the next, beyond a
        # smooth change (the second difference), 1/km.
        rough = max(abs(k[i + 1] - 2 * k[i] + k[i - 1]) for i in range(1, len(k) - 1))
        worst = max(worst, rough)
        axes[0].plot(s, k, lw=1.2, label="car %d (rough %.2f /km)" % (c, rough))
    axes[0].plot([r["s"] for r in rows], [r["k"] * 1000.0 for r in rows], color="k", ls="--", lw=1,
                 label="the line's curvature under the engine")
    axes[0].set_ylabel("heading turn per km (1/km)")
    axes[0].set_title("Through the bend at 25 km/h: each car's turn as drawn, frame to frame (a jitter would show as spikes)")
    axes[0].legend(fontsize=7)
    axes[0].grid(alpha=0.3)
    off = [r["truck_off"] * 1000 for r in rows]
    axes[1].plot([r["s"] for r in rows], off, color="#b5562b")
    axes[1].set_ylabel("trucks off the line, mm")
    axes[1].set_xlabel("metres along the line")
    axes[1].set_title("Drift: the drawn trucks against where the 1D distance puts them (max %.3f mm)" % max(off))
    axes[1].grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(os.path.join(out, "jitter.png"), dpi=90)
    plt.close(fig)
    print(json.dumps({"frames": len(rows), "worst_curvature_roughness_per_km": worst, "max_truck_off_mm": max(off)}))


if __name__ == "__main__":
    main()
