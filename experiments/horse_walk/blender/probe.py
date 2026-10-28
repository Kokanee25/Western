"""Prints the game horse's skeleton as Blender imports it (bone heads/tails in metres)."""
import os
import sys

import bpy

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=os.path.join(ROOT, "assets/creatures/horse/horse.glb"))
for o in bpy.data.objects:
    print("OBJ", o.name, o.type, tuple(round(v, 3) for v in o.location), tuple(round(v, 3) for v in o.rotation_euler),
          o.parent.name if o.parent else None, [m.type for m in getattr(o, "modifiers", [])])
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
M = arm.matrix_world
for b in arm.data.bones:
    h = M @ b.head_local
    t = M @ b.tail_local
    print("BONE %-11s %-10s head (%6.3f %6.3f %6.3f) tail (%6.3f %6.3f %6.3f)" % (
        b.name, b.parent.name if b.parent else "-", *h, *t))
print("ACTIONS", [a.name for a in bpy.data.actions])
