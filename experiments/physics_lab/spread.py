# spread.py BASE COND[,COND...]: a chaotic fall's spread over runs with --jitter (2026-10-21).
# Reads BASE/j_<COND>_<N>/ (one run.py root per --jitter=N) and prints, per fall and condition:
# how far he went in his own frame (median [least..most], m, + ahead), his centre of mass's median
# drop; then per condition how many falls crept over 5 cm after stopping (speed under 0.15 m/s held
# 0.5 s; the creep from 1 s after that to the end) and the flags per run.
import csv, glob, json, math, os, statistics, sys


def one(d):
    s = json.load(open(d + "/summary.json"))
    rows = list(csv.DictReader(open(d + "/ticks.csv")))
    ht = s.get("hit_t", s["limp_t"])
    after = [r for r in rows if float(r["t"]) >= ht]
    stop, run = None, 0
    for r in after:
        v = math.sqrt(sum(float(r[k]) ** 2 for k in ("com_vx", "com_vy", "com_vz")))
        run = run + 1 if v < 0.15 else 0
        if run == 30:
            stop = float(r["t"]) - ht - 0.5
            break
    late = [r for r in after if stop is not None and float(r["t"]) >= ht + stop + 1.0]
    creep = 0.0
    if late:
        a = [float(late[0][k]) for k in ("com_x", "com_y", "com_z")]
        b = [float(late[-1][k]) for k in ("com_x", "com_y", "com_z")]
        creep = math.dist(a, b)
    return {"ahead": -s["final_com_local"][2], "drop": float(after[0]["com_y"]) - float(after[-1]["com_y"]),
            "stop": stop, "creep": creep}


def main():
    base, conds = sys.argv[1], sys.argv[2].split(",")
    names = sorted({os.path.basename(os.path.dirname(p)) for p in glob.glob(base + "/j_%s_*/*/summary.json" % conds[0])})
    print("%-26s" % "fall" + "".join("| %-24s" % c for c in conds))
    agg = {c: {"creep": 0, "n": 0, "flags": 0} for c in conds}
    for n in names:
        cells = []
        for c in conds:
            ms = []
            for r in sorted(glob.glob(base + "/j_%s_*" % c)):
                if os.path.exists(r + "/" + n + "/summary.json"):
                    ms.append(one(r + "/" + n))
                if os.path.exists(r + "/" + n + "/flags.json"):
                    f = json.load(open(r + "/" + n + "/flags.json"))
                    agg[c]["flags"] += sum(v["count"] for v in f["flags"].values())
            for m in ms:
                agg[c]["n"] += 1
                agg[c]["creep"] += m["creep"] > 0.05
            a = [m["ahead"] for m in ms]
            cells.append("| %5.2f [%5.2f..%5.2f] %4.2f" % (statistics.median(a), min(a), max(a),
                         statistics.median([m["drop"] for m in ms])) if ms else "| -")
        print("%-26s" % n[:26] + "".join(cells))
    print("falls creeping > 5 cm after stopping / runs; flags per run:")
    for c in conds:
        runs = max(1, len(glob.glob(base + "/j_%s_*" % c)))
        print("  %-8s %d/%d  flags %.1f per run" % (c, agg[c]["creep"], agg[c]["n"], agg[c]["flags"] / runs))


if __name__ == "__main__":
    main()
