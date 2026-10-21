"""Bake the flame types' fire simulations (docs/briefs/fire-look.md, "The next approach").

    python tools/textures/fire_sim/bake_flames.py [--only=lick,tongue] [--out=build/fire_sim]

(`python` with the pip bpy: the sheets in the repo were baked with bpy 4.5.3 under Python 3.11;
5.1 and 5.2 under 3.13 bake too. About ten minutes for all three on four cores.)

Blender as a Python module (the pip `bpy`, as tools/blender/ runs), its Mantaflow gas solver: for
each type in flames.json a domain open at the top and sides, a box of fuel on its floor and a
turbulence field for the flicker, baked for `warm` + 64 + `blend` frames. Each frame's grids
(flame, smoke density, heat, velocity) are read back and projected along the depth (y) into 2D:
the flame and smoke summed through the fire (metres of each), the heat, and the flame- and
smoke-weighted velocity across the picture. Saved as <out>/<type>.npz for make_sheets.py, which
loops, paints and packs them; the simulation is the slow part and is kept apart from that.
"""
import json
import os
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import manta_relink  # noqa: F401,E402  (before any bake)
import bpy  # noqa: E402
import numpy as np  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))


def build(kind, spec):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.render.fps = 24
    sx, sy, sz = spec["domain_size"]
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, sz * 0.5))
    dom = bpy.context.object
    dom.scale = (sx, sy, sz)
    bpy.ops.object.transform_apply(scale=True)
    mod = dom.modifiers.new("Fluid", "FLUID")
    mod.fluid_type = "DOMAIN"
    d = mod.domain_settings
    d.domain_type = "GAS"
    d.resolution_max = spec["res"]
    d.use_adaptive_domain = False
    d.use_noise = False
    # Open to the air on every side but the floor.
    d.use_collision_border_top = False
    d.use_collision_border_front = False
    d.use_collision_border_back = False
    d.use_collision_border_left = False
    d.use_collision_border_right = False
    d.use_collision_border_bottom = True
    for k, v in spec["domain"].items():
        setattr(d, k, v)
    total = spec["warm"] + 64 + spec["blend"]
    d.cache_directory = tempfile.mkdtemp(prefix="saltcreek_fire_%s_" % kind)
    d.cache_type = "ALL"
    d.cache_frame_start = 1
    d.cache_frame_end = total
    sc.frame_start = 1
    sc.frame_end = total
    ex, ey, ez = spec["emitter"]
    cell = max(sx, sy, sz) / spec["res"]
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, cell * 1.5 + ez * 0.5))
    em = bpy.context.object
    em.scale = (ex, ey, ez)
    bpy.ops.object.transform_apply(scale=True)
    f = em.modifiers.new("Fluid", "FLUID")
    f.fluid_type = "FLOW"
    fs = f.flow_settings
    fs.flow_type = "FIRE"
    fs.flow_behavior = "INFLOW"
    fs.flow_source = "MESH"
    for k, v in spec["flow"].items():
        setattr(fs, k, v)
    strength, size = spec["turbulence"]
    bpy.ops.object.effector_add(type="TURBULENCE", location=(0.0, 0.0, sz * 0.4))
    tb = bpy.context.object
    tb.field.strength = strength
    tb.field.size = size
    tb.field.seed = spec["seed"]
    tb.field.flow = 0.0
    return sc, dom, total


def project(de, res, cell):
    """One frame's grids, summed through the depth (y): images [z, x] with z up."""
    rx, ry, rz = res
    flame = np.array(de.flame_grid, dtype=np.float32).reshape(rz, ry, rx)
    dens = np.array(de.density_grid, dtype=np.float32).reshape(rz, ry, rx)
    heat = np.array(de.heat_grid, dtype=np.float32).reshape(rz, ry, rx)
    vel = np.array(de.velocity_grid, dtype=np.float32).reshape(rz, ry, rx, 3)
    fsum = flame.sum(axis=1) * cell
    dsum = dens.sum(axis=1) * cell
    hsum = np.clip(heat, 0.0, None).sum(axis=1) * cell
    eps = 1e-6
    fv = (vel[..., [0, 2]] * flame[..., None]).sum(axis=1) / (flame.sum(axis=1)[..., None] + eps)
    dv = (vel[..., [0, 2]] * dens[..., None]).sum(axis=1) / (dens.sum(axis=1)[..., None] + eps)
    return fsum, dsum, hsum, fv, dv


def bake(kind, spec, out):
    t0 = time.time()
    sc, dom, total = build(kind, spec)
    with bpy.context.temp_override(object=dom, active_object=dom, scene=sc):
        r = bpy.ops.fluid.bake_all()
    if "FINISHED" not in r:
        raise RuntimeError("%s: the bake didn't finish (%s)" % (kind, r))
    t1 = time.time()
    first = spec["warm"] + 1
    frames = {k: [] for k in ("flame", "smoke", "heat", "flame_vel", "smoke_vel")}
    res = cell = None
    for fr in range(first, total + 1):
        sc.frame_set(fr)
        de = dom.evaluated_get(bpy.context.evaluated_depsgraph_get()).modifiers["Fluid"].domain_settings
        if res is None:
            res = tuple(de.domain_resolution)
            cell = max(spec["domain_size"]) / max(res)
        fl, dn, ht, fv, dv = project(de, res, cell)
        for k, v in zip(frames, (fl, dn, ht, fv, dv)):
            frames[k].append(v)
    arrays = {k: np.stack(v).astype(np.float32) for k, v in frames.items()}
    np.savez_compressed(os.path.join(out, kind + ".npz"), cell=cell, fps=sc.render.fps,
                        dt=1.0 / sc.render.fps, res=np.array(res), **arrays)
    print("%s: %d frames at %s cells (%.3f m), bake %.0f s, read %.0f s; flame up to %.2f m, smoke %.2f m"
          % (kind, len(frames["flame"]), res, cell, t1 - t0, time.time() - t1,
             arrays["flame"].max(), arrays["smoke"].max()), flush=True)


def main():
    args = dict(a[2:].split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    cfg = json.load(open(os.path.join(HERE, "flames.json")))
    out = os.path.join(ROOT, args.get("out", "build/fire_sim"))
    os.makedirs(out, exist_ok=True)
    only = args.get("only", "").split(",") if args.get("only") else list(cfg["types"])
    for kind in only:
        bake(kind, cfg["types"][kind], out)
    sys.stdout.flush()
    # Mantaflow aborts on the way out of the module ("some grids are still in use").
    os._exit(0)


if __name__ == "__main__":
    main()
