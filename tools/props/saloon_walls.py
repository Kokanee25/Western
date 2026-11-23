"""Saloon B's walls, batch S5 (#1030): the kit files this batch makes new (the wall clock has its own,
tools/props/wall_clock.py). Now the rifle over the bar.

    python3 tools/props/saloon_walls.py
    ~/.venvs/bpy/bin/python tools/blender/props/rifle_pegs.py     (its model: the game's own Winchester)

`rifle_pegs`: a Winchester 1873 laid on two square oak pegs driven into the wall, its right side to the
room and its muzzle to the right, where the bartender can reach up for it (the saloon keeper's gun, as
the period's photographs of bars show one hung over the back bar or the door). The gun is the gun lab's
model with its own painted sheets (assets/weapons/winchester73*: `pbr:@winchester73_w73_long`), not a
copy; the pegs are the material library's oak. Hung by the pegs (KitProp `hangs`: a nail through each
into the wall): a peg shot out drops the gun's end, the board going drops it all. The gun is a prop, not
a weapon: taking it down to use is gameplay's (a `use` later).
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
KIT = os.path.join(ROOT, "assets/props/kit")

# From tools/blender/props/rifle_pegs.py: the gun 1.10 long, 0.21 high (its lever's loop), its middle
# 0.075 off the wall; the pegs at x -0.36 (under the stock's wrist) and 0.30 (under the forend), their
# tops where the gun meets them (0 and 0.11 over the lower).
PEG = 0.026
PEG_OUT = 0.12
PEGS = [(-0.36, 0.0), (0.30, 0.1102)]
OAK = "lib:furniture_oak/old"


def rifle_pegs():
    members = []
    for i, (x, top) in enumerate(PEGS):
        members.append({"id": "peg%d" % i, "kind": "post", "size": [PEG, PEG, PEG_OUT], "at": [x, round(top - PEG * 0.5, 4), PEG_OUT * 0.5],
                        "look": OAK})
    members.append({"id": "rifle", "kind": "trim", "size": [1.08, 0.1, 0.04], "at": [0.0, 0.05, 0.075], "wood": "walnut",
                    "look": "pbr:@winchester73_w73_long",
                    "draw": {"shape": "mesh", "model": "rifle_pegs", "part": "RifleLong"},
                    "dress": [{"look": "pbr:@winchester73_w73_action", "draw": {"shape": "mesh", "model": "rifle_pegs", "part": "RifleAction"}}]})
    return {
        "_doc": __doc__.split("`rifle_pegs`: ")[1].replace("\n", " ").strip() + " The wall's face z = 0, the gun toward +z, the "
                "origin the lower peg's top (hang it ~3.25 m up over the back bar). ~4.4 kg. Written by tools/props/saloon_walls.py.",
        "id": "rifle_pegs",
        "kind": "members",
        "fixture": True,
        "in_game": False,
        "wood": "oak",
        "anchor": "wall",
        "drawn_bounds": True,
        "splits_below": 0.4,
        "hangs": {"nails": [[x, round(top - PEG * 0.5, 4), 0.004] for x, top in PEGS]},
        "factory": "tools/props/saloon_walls.py",
        "members": members,
    }


def main():
    for d in (rifle_pegs(),):
        open(os.path.join(KIT, d["id"] + ".json"), "w").write(json.dumps(d, indent=2) + "\n")
        print("%s: %d members" % (d["id"], len(d["members"])))


if __name__ == "__main__":
    main()
