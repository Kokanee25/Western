"""Going up for height (#572), by opening: climbs (runs for a spot up the stair) and how they
ended, the way (m) and the run (s); stays up after a climb against stays up of men who started up
there; seconds up, hits on you and hits taken there; how many of the stays up were behind a
balustrade's screen. python3 climbs.py RUN [RUN...]"""
import json, glob, os, sys
from statistics import median


def tally(run):
    out = {}
    for p in glob.glob(run + "/fights/*.json"):
        r = json.load(open(p))
        op = "you" if os.path.basename(p).endswith("_shoot.json") else "they"
        t = out.setdefault(op, {"fights": 0, "climbs": 0, "how": {}, "way": [], "run": [], "fights_with": 0,
                                "climbed": [0, 0.0, 0, 0], "started": [0, 0.0, 0, 0], "screen": 0, "up": 0})
        t["fights"] += 1
        men = r["men"].values() if isinstance(r["men"], dict) else r["men"]
        any_climb = False
        for m in men:
            for mv in m.get("moves", []):
                if not mv.get("climb"):
                    continue
                any_climb = True
                t["climbs"] += 1
                how = "got there" if mv["how"] == "arrived" else mv["how"].split(":")[0]
                t["how"][how] = t["how"].get(how, 0) + 1
                t["way"].append(mv["way"])
                if mv["how"] == "arrived":
                    t["run"].append(mv["s"])
            for st in m.get("stays", []):
                if not st.get("up"):
                    continue
                t["up"] += 1
                t["screen"] += 1 if st.get("screen") else 0
                k = "climbed" if st.get("climbed") else "started"
                t[k][0] += 1
                t[k][1] += st.get("s", 0.0)
                t[k][2] += st.get("hits_on_you", 0)
                t[k][3] += st.get("hits", 0)
        t["fights_with"] += 1 if any_climb else 0
    return out


print("| Run | Opening | Fights with a climb | Climbs | How they ended | Way m (med) | Run s (med) | Stays at the spot climbed to: n, s a stay (mean), hits on you, hits on him | Other stays up: n, s, hits on you, on him | Stays up behind a screen |")
print("|---|---|---|---|---|---|---|---|---|---|")
for run in sys.argv[1:]:
    for op, t in sorted(tally(run).items(), reverse=True):
        c, s = t["climbed"], t["started"]
        print("| %s | %s | %d of %d | %d | %s | %s | %s | %d, %.1f, %d, %d | %d, %.1f, %d, %d | %d of %d |" % (
            os.path.basename(run.rstrip("/")), op, t["fights_with"], t["fights"], t["climbs"],
            ", ".join("%s %d" % kv for kv in sorted(t["how"].items(), key=lambda kv: -kv[1])) or "-",
            "%.1f" % median(t["way"]) if t["way"] else "-", "%.1f" % median(t["run"]) if t["run"] else "-",
            c[0], c[1] / max(c[0], 1), c[2], c[3], s[0], s[1] / max(s[0], 1), s[2], s[3], t["screen"], t["up"]))
