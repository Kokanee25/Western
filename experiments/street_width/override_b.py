"""#1295's version B, a THROWAWAY override (never commit what it writes): Main Street ~16 m between
fronts, both sides moved in by the same amount, so the street's middle stays at z 0 and the
North-South Street, the back street and the rear lane stay put (the lots get that much shallower
behind). Writes config/valley.json and the street-front specs in place; `git checkout` them after.
  python3 experiments/street_width/override_b.py [WIDTH]
"""
import json, sys, re, pathlib
W = float(sys.argv[1]) if len(sys.argv) > 1 else 16.0
root = pathlib.Path(__file__).resolve().parents[2]
vp = root / "config/valley.json"
v = json.loads(vp.read_text())
ms = v["town"]["main_street"]
old = ms["width_between_fronts"]
d = (old - W) / 2.0
ms["width_between_fronts"] = W
moved = []
for side, sgn in (("north", 1.0), ("south", -1.0)):
    for l in v["town"][side]:
        pad = l.get("pad")
        if pad and "z" in pad:
            pad["z"] = [round(z + sgn * d, 3) for z in pad["z"]]
            moved.append(l["id"] + ".pad")
vp.write_text(json.dumps(v, indent="\t", ensure_ascii=False) + "\n")
for f in sorted((root / "config/buildings").glob("*.json")):
    s = json.loads(f.read_text())
    at = (s.get("lot") or {}).get("at")
    if at and abs(abs(at[2]) - old / 2) < 0.01:
        at[2] = round(at[2] + (d if at[2] < 0 else -d), 3)
        f.write_text(json.dumps(s, indent="\t", ensure_ascii=False) + "\n")
        moved.append(f.name)
print("width %.2f -> %.2f, each side in %.3f m; moved: %s" % (old, W, d, ", ".join(moved)))
# The ground shader's walk edge (the old front less the walk) is a dial, not derived: move it too.
tp = root / "src/art/valley_ground_art_tuning.gd"
t = tp.read_text()
new_edge = W / 2 - float(ms["boardwalk_depth"])
t2 = re.sub(r"(@export var walk_edge := )[0-9.]+", lambda m: m.group(1) + "%.2f" % new_edge, t)
assert t2 != t, "walk_edge not found"
tp.write_text(t2)
print("walk_edge -> %.2f" % new_edge)
