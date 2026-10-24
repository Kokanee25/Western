"""The prop factory's Blender props (docs/briefs/prop-factory.md): every script in this folder that
has a `build()`, each writing assets/props/models/<id>.glb (common.py has the how).

    ~/bpyenv/bin/python tools/blender/props/build.py [--only=deer_head,feed_sack]

Needs bpy (pip `bpy`, Blender 5.0's module, on Python 3.11). After it, `godot --headless --import`
and commit the .glb with its .import file.
"""
import importlib
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

PROPS = ["deer_head", "hay_bale", "straw_pile", "feed_sack", "grain_sack", "horse_droppings"]


def main():
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = a.split("=", 1)[1].split(",")
    for name in PROPS:
        if only and name not in only:
            continue
        if not os.path.exists(os.path.join(HERE, name + ".py")):
            continue
        importlib.import_module(name).build()


if __name__ == "__main__":
    main()
