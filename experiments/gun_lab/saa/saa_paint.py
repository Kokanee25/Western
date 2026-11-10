"""The SAA's surfaces baked (#693 step 1). Sean's review after the first paint (2026-11-09): another
paint run isn't the fix; metal must behave like metal, no stretched UVs or stripes, then the surfaces:
case hardening as fine, subtle blue/straw/purple swirls on a dark base; barrel and cylinder a deep
blue-black worn on the edges.

So the metals are made here, free, from 3D noise in each part's own space (no UVs in their pattern, so
nothing stretches or repeats along the barrel); only the walnut keeps a painting (surfaces/raw,
walnut_1, laid by Cycles' box projection with its seams blended). On every material the gun's own wear
and grime, from its shape: edges (the Bevel node's rounded normal parting from the face) rubbed to
bare steel, the case colours silvered, the walnut lighter; the hollows (ambient occlusion within
4 mm) dark and duller. Baked by Cycles as emission into one atlas (UV "bake", smart-projected at 45
degrees: under 8% stretch across a strip), albedo (sRGB) and ORM (glTF's occlusion, roughness,
metal), exported in the glb.

    ~/bpyenv/bin/python experiments/gun_lab/saa/saa_paint.py [--size=2048] [--barrel=7.5] [--out=DIR]
        [--checker]       # the atlas proof instead: a checker on the bake UVs, as saa_<barrel>checker.glb
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
_src = open(os.path.join(HERE, "saa_blender.py")).read().replace("\nmain()\n", "\n")
exec(compile(_src, os.path.join(HERE, "saa_blender.py"), "exec"))  # build(), mats, arg, ... (no export)

import bpy  # noqa: E402  (already imported by saa_blender's code)

SURF = arg("surfaces", os.path.join(HERE, "surfaces"))
SIZE = int(arg("size", "2048"))
CHECKER = "--checker" in sys.argv
WALNUT = os.path.join(SURF, arg("walnut", "walnut_1") + ".png")
# Per material: how it is made, its wear and roughness, metal or not.
LOOK = {
    "saa_case":      {"kind": "case", "rough": 0.22, "metal": 1.0, "wear": 0.5},
    "saa_checker":   {"kind": "case", "rough": 0.26, "metal": 1.0, "wear": 0.7, "knurl": True},
    "saa_blued":     {"kind": "blued", "rough": 0.16, "metal": 1.0, "wear": 0.9},
    "saa_fire_blue": {"kind": "fire", "rough": 0.14, "metal": 1.0, "wear": 0.5},
    "saa_bright":    {"kind": "solid", "color": (0.56, 0.56, 0.57), "rough": 0.25, "metal": 1.0, "wear": 0.3},
    "saa_walnut":    {"kind": "walnut", "rough": 0.40, "metal": 0.0, "wear": 0.55},
    "saa_bore":      {"kind": "solid", "color": (0.04, 0.04, 0.045), "rough": 0.6, "metal": 1.0, "wear": 0.0},
}
BARE_STEEL = (0.50, 0.50, 0.51)


class G:
    """A small node-graph builder (the nodes of one material)."""
    def __init__(self, mat):
        self.nt = mat.node_tree
        self.nt.nodes.clear()
        self.N, self.L = self.nt.nodes, self.nt.links

    def node(self, kind, **inputs):
        n = self.N.new(kind)
        for k, v in inputs.items():
            if hasattr(v, "is_linked") or hasattr(v, "links"):
                self.L.new(v, n.inputs[k])
            else:
                n.inputs[k].default_value = v
        return n

    def math(self, op, a, b, clamp=False):
        n = self.N.new("ShaderNodeMath")
        n.operation = op
        n.use_clamp = clamp
        for i, v in enumerate((a, b)):
            if isinstance(v, (int, float)):
                n.inputs[i].default_value = v
            else:
                self.L.new(v, n.inputs[i])
        return n.outputs[0]

    def mix(self, fac, a, b, blend="MIX"):
        n = self.N.new("ShaderNodeMix")
        n.data_type = "RGBA"
        n.blend_type = blend
        for name, v in (("Factor", fac), ("A", a), ("B", b)):
            if isinstance(v, (int, float)):
                n.inputs[name].default_value = v
            elif isinstance(v, tuple):
                n.inputs[name].default_value = (*v, 1.0) if len(v) == 3 else v
            else:
                self.L.new(v, n.inputs[name])
        return n.outputs["Result"]

    def noise(self, vec, scale, detail=6.0, rough=0.55, distort=0.0):
        n = self.N.new("ShaderNodeTexNoise")
        n.inputs["Scale"].default_value = scale
        n.inputs["Detail"].default_value = detail
        n.inputs["Roughness"].default_value = rough
        n.inputs["Distortion"].default_value = distort
        self.L.new(vec, n.inputs["Vector"])
        return n.outputs["Fac"]

    def ramp(self, fac, stops):
        n = self.N.new("ShaderNodeValToRGB")
        cr = n.color_ramp
        cr.interpolation = "EASE"
        while len(cr.elements) < len(stops):
            cr.elements.new(0.5)
        for el, (pos, col) in zip(cr.elements, stops):
            el.position = pos
            el.color = (*col, 1.0)
        self.L.new(fac, n.inputs["Fac"])
        return n.outputs["Color"]

    def maprange(self, v, a, b, c=0.0, d=1.0):
        n = self.N.new("ShaderNodeMapRange")
        n.inputs["From Min"].default_value = a
        n.inputs["From Max"].default_value = b
        n.inputs["To Min"].default_value = c
        n.inputs["To Max"].default_value = d
        self.L.new(v, n.inputs["Value"])
        return n.outputs["Result"]


def node_tree(mat, look, img, mode):
    """mat's nodes rebuilt for one bake: the albedo, or (1, roughness, metal), into an Emission shader;
    the target image the active node (what Cycles bakes into)."""
    g = G(mat)
    out = g.node("ShaderNodeOutputMaterial")
    emit = g.node("ShaderNodeEmission")
    g.L.new(emit.outputs[0], out.inputs[0])
    obj = g.node("ShaderNodeTexCoord").outputs["Object"]           # metres, the part's own space
    if CHECKER:
        uvb = g.node("ShaderNodeUVMap")
        uvb.uv_map = "bake"
        chk = g.node("ShaderNodeTexChecker", Scale=96.0)
        chk.inputs["Color1"].default_value = (0.85, 0.85, 0.85, 1.0)
        chk.inputs["Color2"].default_value = (0.08, 0.08, 0.08, 1.0)
        g.L.new(uvb.outputs["UV"], chk.inputs["Vector"])
        col = chk.outputs["Color"] if mode == "albedo" else None
        if mode == "albedo":
            g.L.new(col, emit.inputs["Color"])
        else:
            comb = g.node("ShaderNodeCombineColor", Red=1.0, Green=0.6, Blue=0.0)
            g.L.new(comb.outputs[0], emit.inputs["Color"])
        _target(g, img)
        return
    # Wear: the edge (Bevel's rounded normal against the true one), broken up by noise.
    geo = g.node("ShaderNodeNewGeometry")
    bev = g.node("ShaderNodeBevel", Radius=0.0006)
    bev.samples = 8
    dot = g.N.new("ShaderNodeVectorMath")
    dot.operation = "DOT_PRODUCT"
    g.L.new(geo.outputs["Normal"], dot.inputs[0])
    g.L.new(bev.outputs[0], dot.inputs[1])
    edge = g.maprange(dot.outputs["Value"], 0.999, 0.94)
    brk = g.maprange(g.noise(obj, 700.0, 6.0), 0.35, 0.65)
    wear = g.math("MULTIPLY", g.math("MULTIPLY", edge, brk, True), look["wear"])
    # Grime: the hollows.
    ao = g.N.new("ShaderNodeAmbientOcclusion")
    ao.inputs["Distance"].default_value = 0.004
    ao.samples = 16
    cav = g.maprange(ao.outputs["AO"], 1.0, 0.35)
    kind = look["kind"]
    rough = look["rough"]
    if kind == "case":
        # Fine, subtle swirls of blue, violet and straw on a dark steel base: two layers of distorted
        # noise (~3-8 mm), through a ramp of the oxide colours, mostly left at the base.
        swirl = g.math("ADD", g.noise(obj, 120.0, 8.0, 0.6, 3.2), g.math("MULTIPLY", g.noise(obj, 380.0, 4.0, 0.5, 1.6), 0.35))
        swirl = g.maprange(swirl, 0.55, 1.05)
        # Mostly blues and violets; straw only in thin, dim bands (round 4a read as rust spots).
        oxide = g.ramp(swirl, [(0.00, (0.12, 0.12, 0.13)), (0.22, (0.09, 0.12, 0.27)), (0.36, (0.17, 0.11, 0.25)),
                               (0.47, (0.11, 0.15, 0.32)), (0.56, (0.27, 0.22, 0.12)), (0.62, (0.13, 0.13, 0.15)),
                               (0.80, (0.10, 0.14, 0.29)), (1.00, (0.21, 0.23, 0.31))])
        amount = g.maprange(g.noise(obj, 45.0, 3.0), 0.35, 0.70, 0.35, 0.85)
        base = g.mix(amount, (0.14, 0.14, 0.15), oxide)
        worn = g.mix(wear, base, (0.62, 0.62, 0.63))
        r_var = g.math("MULTIPLY", g.noise(obj, 300.0, 3.0), 0.08)
        if look.get("knurl"):
            # A diamond knurl, 1.2 mm a line, cut at 45 degrees across the pad (its top faces up and back):
            # two sine rows on (x + y) and (x - y) in the hammer's own space, dark and rough in the grooves.
            sep = g.N.new("ShaderNodeSeparateXYZ")
            g.L.new(obj, sep.inputs[0])
            k = 2 * math.pi / 0.0012
            rows = []
            for op in ("ADD", "SUBTRACT"):
                d = g.math(op, sep.outputs["X"], sep.outputs["Y"])
                wave = g.math("ABSOLUTE", g.math("SINE", g.math("MULTIPLY", d, k), 0.0), 0.0)
                rows.append(g.maprange(wave, 0.35, 0.10))
            groove = g.math("MAXIMUM", rows[0], rows[1], True)
            worn = g.mix(g.math("MULTIPLY", groove, 0.75), worn, (0.03, 0.03, 0.035))
            r_var = g.math("ADD", r_var, g.math("MULTIPLY", groove, 0.25))
    elif kind in ("blued", "fire"):
        # Deep blue-black, its fine polish lines along the gun (the noise stretched along the bore: the
        # part's local Y is the gun's forward in Blender for every part).
        stretch = g.N.new("ShaderNodeVectorMath")
        stretch.operation = "MULTIPLY"
        g.L.new(obj, stretch.inputs[0])
        stretch.inputs[1].default_value = (1.0, 0.012, 1.0)
        lines = g.noise(stretch.outputs[0], 2600.0, 2.0, 0.5)
        tone = g.noise(obj, 30.0, 3.0)                    # slow, faint unevenness of the blue
        if kind == "blued":
            dark, light = (0.10, 0.115, 0.165), (0.17, 0.19, 0.26)
        else:
            dark, light = (0.05, 0.08, 0.20), (0.08, 0.13, 0.28)   # fire blue: deep, not royal
        base = g.mix(g.math("ADD", g.math("MULTIPLY", lines, 0.6), g.math("MULTIPLY", tone, 0.4)), dark, light)
        # Edge wear: bluing gone to bare steel, a little browned where thin.
        worn = g.mix(wear, base, BARE_STEEL)
        thin = g.math("MULTIPLY", g.maprange(g.noise(obj, 90.0, 4.0), 0.55, 0.75), 0.35)
        worn = g.mix(g.math("MULTIPLY", thin, edge), worn, (0.24, 0.20, 0.18))
        r_var = g.math("MULTIPLY", lines, 0.06)
    elif kind == "walnut":
        tex = g.N.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(WALNUT, check_existing=True)
        tex.projection = "BOX"
        tex.projection_blend = 0.35
        tex.interpolation = "Cubic"
        sc = g.N.new("ShaderNodeVectorMath")
        sc.operation = "SCALE"
        sc.inputs["Scale"].default_value = 1.0 / 0.06
        g.L.new(obj, sc.inputs[0])
        g.L.new(sc.outputs[0], tex.inputs["Vector"])
        base = g.mix(1.0, tex.outputs["Color"], (0.48, 0.40, 0.34), "MULTIPLY")
        worn = g.mix(wear, base, g.mix(0.45, base, (0.55, 0.50, 0.45), "SCREEN"))
        r_var = g.math("MULTIPLY", g.noise(obj, 200.0, 3.0), 0.06)
    else:
        worn = g.mix(0.0, look["color"], look["color"])
        r_var = g.math("MULTIPLY", g.noise(obj, 200.0, 3.0), 0.04)
    if mode == "albedo":
        col = g.mix(g.math("MULTIPLY", cav, 0.6), worn, (0.035, 0.030, 0.025))
        g.L.new(col, emit.inputs["Color"])
    else:
        r = g.math("ADD", g.math("ADD", rough, r_var), g.math("MULTIPLY", wear, 0.08))
        r = g.math("ADD", r, g.math("MULTIPLY", cav, 0.35), True)
        comb = g.node("ShaderNodeCombineColor", Red=1.0, Blue=look["metal"])
        g.L.new(r, comb.inputs["Green"])
        g.L.new(comb.outputs[0], emit.inputs["Color"])
    _target(g, img)


def _target(g, img):
    target = g.N.new("ShaderNodeTexImage")
    target.image = img
    uvb = g.N.new("ShaderNodeUVMap")
    uvb.uv_map = "bake"
    g.L.new(uvb.outputs["UV"], target.inputs["Vector"])
    g.N.active = target
    target.select = True


def unwrap(objs):
    """One atlas for every baked part: a second UV layer, smart-projected and packed together."""
    for ob in objs:
        lay = ob.data.uv_layers.new(name="bake")
        ob.data.uv_layers.active = lay
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs:
        ob.hide_set(False)
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(45), island_margin=0.004, area_weight=0.0, correct_aspect=True)
    bpy.ops.uv.pack_islands(margin=0.004, rotate=True)
    bpy.ops.object.mode_set(mode="OBJECT")


def bake(objs, img, mode):
    for ob in objs:
        for slot in ob.material_slots:
            m = slot.material
            if m and m.name.split(".")[0] in LOOK:
                node_tree(m, LOOK[m.name.split(".")[0]], img, mode)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.bake(type="EMIT", margin=6, use_clear=True)


def main_paint():
    parts, rounds, markers, hinge, ej = build()
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = int(arg("samples", "24"))
    # The world space the rig, the markers and the export see is build()'s; bake in place.
    objs = [o for o in parts.values() if o.type == "MESH"]
    unwrap(objs)
    albedo = bpy.data.images.new("saa_albedo", SIZE, SIZE)
    orm = bpy.data.images.new("saa_orm", SIZE, SIZE)
    orm.colorspace_settings.name = "Non-Color"
    for m in bpy.data.materials:
        m.use_nodes = True
    bake(objs, albedo, "albedo")
    bake(objs, orm, "orm")
    # The game's material: the two baked maps on the bake UVs, the box UVs dropped (glTF's TEXCOORD_0).
    mat = bpy.data.materials.new("saa_painted")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    t_alb = nt.nodes.new("ShaderNodeTexImage")
    t_alb.image = albedo
    t_orm = nt.nodes.new("ShaderNodeTexImage")
    t_orm.image = orm
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    nt.links.new(t_alb.outputs["Color"], bsdf.inputs["Base Color"])
    nt.links.new(t_orm.outputs["Color"], sep.inputs[0])
    nt.links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])
    nt.links.new(sep.outputs["Blue"], bsdf.inputs["Metallic"])
    for ob in objs:
        for i, slot in enumerate(ob.material_slots):
            if slot.material and slot.material.name.split(".")[0] in LOOK:
                slot.material = mat
        if "UVMap" in ob.data.uv_layers:
            ob.data.uv_layers.remove(ob.data.uv_layers["UVMap"])
    # The atlases kept beside the glb (to look at; the glb carries its own copies).
    out_dir = arg("out", HERE)
    for img in (albedo, orm) if not CHECKER else ():
        os.makedirs(os.path.join(out_dir, "surfaces"), exist_ok=True)
        img.filepath_raw = os.path.join(out_dir, "surfaces", img.name + ".png")
        img.file_format = "PNG"
        img.save()
    return parts, rounds, markers, hinge, ej


def export(parts, rounds, markers, hinge, ej):
    keep = set()

    def walk(o):
        keep.add(o.name)
        for c in o.children:
            walk(c)
    walk(bpy.data.objects["ColtSAA"])
    for o in list(bpy.data.objects):
        if o.name not in keep:
            bpy.data.objects.remove(o, do_unlink=True)
    tag = ("%g" % BARREL).replace(".", "") + ("checker" if CHECKER else "")
    out = arg("out", HERE)
    glb = os.path.join(out, "saa_%s.glb" % tag)
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", export_apply=True, export_yup=True,
                              export_image_format="JPEG", export_jpeg_quality=92,
                              export_cameras=False, export_lights=False)
    rig_json(parts, markers, hinge, ej, os.path.join(out, "saa_%s_rig.json" % tag))
    print("SAA painted -> %s (%.1f MB)" % (glb, os.path.getsize(glb) / 1e6))


r = main_paint()
export(*r)
if PREVIEW:
    # The look check: the painted parts in a plain light (the real test is the game's real look).
    preview(PREVIEW)
