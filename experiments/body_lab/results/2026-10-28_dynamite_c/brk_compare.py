"""Two breakage lab runs side by side: python3 brk_compare.py BEFORE AFTER."""
import json, os, sys, glob

def load(root):
    out = {}
    for f in glob.glob(os.path.join(root, "*", "summary.json")):
        d = json.load(open(f))
        name = os.path.basename(os.path.dirname(f)).split("__")[0]
        kinds = d["broken"].get("by_kind", {})
        glass = sum(v for k, v in kinds.items() if k.startswith("glass"))
        men = d.get("men", [])
        harm = sorted(set(h for m in men for h in m.get("harm", []) if "eardrum" not in h))
        out[name] = {
            "kg": d["charge"].get("kg"), "broken": d["fingerprint"]["broken"], "panes": glass,
            "opened": (d.get("surface") or {}).get("opened_m2"),
            "lamps": d["fire"].get("lamps_smashed", 0), "caught": d["fire"].get("caught_count", 0),
            "frame": d["frame"].get("event_frame_ms"), "result": (d.get("target_result") or {}).get("result", ""),
            "men": "; ".join(harm),
        }
    return out

a, b = load(sys.argv[1]), load(sys.argv[2])
print("| scenario | broken | panes | opened m² | lamps smashed | caught | blast frame ms | target | the man (not ears) |")
print("|---|---|---|---|---|---|---|---|---|")
f = lambda x, y: "%s → %s" % (x, y) if x != y else "%s" % x
for n in sorted(set(a) | set(b)):
    x, y = a.get(n), b.get(n)
    if not x or not y:
        continue
    op = lambda v: "-" if v is None else "%.2f" % v
    print("| %s | %s | %s | %s | %s | %s | %s | %s | %s |" % (n, f(x["broken"], y["broken"]), f(x["panes"], y["panes"]),
          f(op(x["opened"]), op(y["opened"])), f(x["lamps"], y["lamps"]), f(x["caught"], y["caught"]),
          f("%.0f" % (x["frame"] or 0), "%.0f" % (y["frame"] or 0)), f(x["result"], y["result"]), f(x["men"] or "-", y["men"] or "-")))
