"""At the posts, stepping out against pointing round them (#566), by opening: stays at a post, steps
out, seconds out, shots from a post (from out / pointed or bladed), hits on you from a post (from
out), hits taken there (out). python3 steps.py RUN [RUN...]"""
import json, glob, os, sys


def tally(run):
    out = {}
    for p in glob.glob(run + "/fights/*.json"):
        r = json.load(open(p))
        op = "you" if os.path.basename(p).endswith("_shoot.json") else "they"
        t = out.setdefault(op, {"fights": 0, "stays": 0, "steps": 0, "out_s": 0.0, "shots": 0, "shots_out": 0,
                                "hits_on_you": 0, "hits_on_you_out": 0, "hits": 0, "hits_out": 0, "s": 0.0})
        t["fights"] += 1
        men = r["men"].values() if isinstance(r["men"], dict) else r["men"]
        for m in men:
            for st in m.get("stays", []):
                if not st.get("post"):
                    continue
                t["stays"] += 1
                for k in ["steps", "out_s", "shots", "shots_out", "hits_on_you", "hits_on_you_out", "hits", "hits_out", "s"]:
                    t[k] += st.get(k, 0)
    return out


print("| Run | Opening | Stays at a post | Steps out | s out a step | Shots there (from out) | Hits on you there (from out) | Hits on him there (out) | Shots a hit on you |")
print("|---|---|---|---|---|---|---|---|---|")
for run in sys.argv[1:]:
    for op, t in sorted(tally(run).items(), reverse=True):
        print("| %s | %s | %d | %d | %.1f | %d (%d) | %d (%d) | %d (%d) | %s |" % (
            os.path.basename(run.rstrip("/")), op, t["stays"], t["steps"], t["out_s"] / max(t["steps"], 1),
            t["shots"], t["shots_out"], t["hits_on_you"], t["hits_on_you_out"], t["hits"], t["hits_out"],
            "%.1f" % (t["shots"] / t["hits_on_you"]) if t["hits_on_you"] else "-"))
