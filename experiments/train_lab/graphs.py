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
    if os.path.exists(os.path.join(runs, "slack.csv")):
        step2(runs, out, summary)


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


CARS = ["engine", "tender", "ore 1", "ore 2", "boxcar", "express", "coach"]


def step2(runs, out, summary):
    """Step 2 (#551): slack.png (each car's speed on a start and a stop: the slack running out car by
    car and bunching), delay_distance.png (the engineer's delay against distance run, on time and
    3 minutes late, and on the re-laid line), and ten_stops.md (the table)."""
    rows = read(os.path.join(runs, "slack.csv"))
    start = [r for r in rows if r["phase"] == "start"]
    stop = [r for r in rows if r["phase"] == "stop"]
    n = len(CARS)
    cmap = plt.get_cmap("copper")
    fig, axes = plt.subplots(1, 2, figsize=(12, 4.5))
    ax = axes[0]
    for i in range(n):
        ax.plot([r["t"] for r in start if r["t"] < 8], [r["v%d" % i] * 3.6 for r in start if r["t"] < 8],
                color=cmap(i / (n - 1)), lw=1.6, label=CARS[i])
    for e in summary.get("slack_events", []):
        if e["phase"] == "start" and e["kind"] == "out" and e["t"] < 8:
            ax.axvline(e["t"], color="#999", lw=0.6, ls=":")
    ax.set_title("A start: the slack running out car by car (dotted: each coupler goes taut)", fontsize=10)
    ax.set_xlabel("seconds from a stand, regulator opening")
    ax.set_ylabel("km/h")
    ax.legend(fontsize=8, ncol=2)
    ax.grid(alpha=0.3)
    ax = axes[1]
    t0 = stop[0]["t"] if stop else 0.0
    for i in range(n):
        ax.plot([r["t"] - t0 for r in stop], [r["v%d" % i] * 3.6 for r in stop], color=cmap(i / (n - 1)), lw=1.6, label=CARS[i])
    ax2 = ax.twinx()
    for j in range(n - 1):
        ax2.plot([r["t"] - t0 for r in stop], [r["c%d" % j] / 1000.0 for r in stop], color="#3b6ea5", lw=0.6, alpha=0.5)
    ax2.set_ylabel("coupler force, kN (+ pulling, - pushing)", color="#3b6ea5")
    ax.set_title("A stop from 20 km/h, full brake: the cars running in (blue: the couplers)", fontsize=10)
    ax.set_xlabel("seconds from the brake handle")
    ax.set_ylabel("km/h")
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(os.path.join(out, "slack.png"), dpi=90)
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(11, 4.5))
    for name, colour, label in [("timetable_late0", "#5a8f4e", "on time"), ("timetable_late180", "#b5562b", "3 minutes late"),
                                ("timetable_relaid", "#3b6ea5", "on time, the re-laid line (2.1 km)")]:
        path = os.path.join(runs, name + ".csv")
        if not os.path.exists(path):
            continue
        rr = [r for r in read(path) if r["state"] != "done"]
        ax.plot([r["odo"] for r in rr], [r["delay"] for r in rr], color=colour, lw=1.8, label=label)
    ax.axhline(0, color="#333", lw=0.8)
    ax.set_title("The engineer against the timetable (depot, the mine, back): seconds late against distance run", fontsize=10)
    ax.set_xlabel("metres run")
    ax.set_ylabel("seconds late (- early)")
    ax.legend(fontsize=9)
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(os.path.join(out, "delay_distance.png"), dpi=90)
    plt.close(fig)

    lines = ["| Run | Error on the mark (m, + past it) | Time (s) | Top km/h |", "|---|---|---|---|"]
    for r in summary.get("ten_stops", []):
        lines.append("| %s | %+.2f | %.1f | %.1f |" % (r["name"], r["error"], r["time"], r["top_kmh"]))
    worst = max(abs(r["error"]) for r in summary.get("ten_stops", [])) if summary.get("ten_stops") else float("nan")
    lines.append("")
    lines.append("Worst: %.2f m (the proof asks within 1 m)." % worst)
    open(os.path.join(out, "ten_stops.md"), "w").write("\n".join(lines) + "\n")
    print(json.dumps({"ten_stops_worst_m": worst}))


if __name__ == "__main__":
    main()
