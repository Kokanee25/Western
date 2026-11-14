"""The body lab's dynamite runs as one table: python3 blast_table.py RUN_ROOT [RUN_ROOT2]."""
import json, os, sys, glob, collections

def rows(root):
    out = collections.defaultdict(list)
    for f in glob.glob(os.path.join(root, "*", "dynamite_*", "summary.json")):
        d = json.load(open(f))
        r = d["scenario"]["range"]
        harm = []
        for h in d.get("hits", []):
            if h.get("kind") == "blast":
                harm += h.get("harm", [])
        inj = d["injuries"]
        out[r].append({
            "model": d["model"], "harm": harm, "severed": inj["severed"], "lungs": inj["lungs"],
            "eardrums": inj["eardrums"], "concussion": inj["concussion_s"] > 0,
            "dead_s": d["outcomes"]["none"]["dead_s"], "openings": d["body"]["openings"],
            "gravel": sorted(set(d.get("crossed", {}).keys())),
            "kpa": d["charge"]["chest_kpa_side_on"], "kg": d["charge"].get("kg"),
        })
    return out

def short(rs):
    n = len(rs)
    sev = collections.Counter(s for r in rs for s in r["severed"])
    lungs = sum(1 for r in rs if any("lungs torn" in h for h in r["harm"]))
    bruised = sum(1 for r in rs if any("lungs bruised" in h for h in r["harm"]))
    ears = sum(r["eardrums"] for r in rs)
    conc = sum(1 for r in rs if r["concussion"])
    down = sum(1 for r in rs if "thrown off his feet" in r["harm"])
    dead = [r["dead_s"] for r in rs if r["dead_s"] is not None]
    torn = sum(1 for r in rs for h in r["harm"] if h.endswith("torn off"))
    return "%d men | limbs off: %s | lungs torn %d, bruised %d | eardrums %d/%d | senseless %d | down %d | dead (untreated) %d%s" % (
        n, ", ".join("%s x%d" % kv for kv in sorted(sev.items())) or "none", lungs, bruised, ears, 2 * n, conc, down,
        len(dead), (" (%s s)" % ", ".join("%.0f" % x for x in sorted(dead))) if dead else "")

for root in sys.argv[1:]:
    print("##", root)
    data = rows(root)
    for r in sorted(data):
        print("  %4sm: %s" % (r, short(data[r])))
