"""The Winchester's surfaces baked (#734; Sean's A on #767, 2026-11-10: "do the surfaces the way the
Colt's were done, generated in Blender, no paid call, metal that reflects the game's sky, with the
finishes taken from period references, not memory").

The Colt's way (experiments/gun_lab/saa/saa_paint.py, whose node recipes this copies and adapts): the
metals are made here, free, from 3D noise in each part's own space (nothing stretches or repeats along
the 43" gun); the walnut is the Colt's free walnut painting (saa/surfaces/raw/walnut_1.jpg, cut seamless
here) laid by box projection. On every material the gun's own wear and grime from its shape: edges
rubbed to bare steel (the Bevel node's rounded normal parting from the face), the hollows dark and
duller (ambient occlusion within 4 mm). Baked by Cycles as emission into two atlases (the action's
parts, and the long ones: barrel, tube, wood, furniture), each albedo (sRGB) + ORM (glTF's occlusion,
roughness, metal), exported in the glb with JPEG images.

Which finish each part gets is FINISH below, each line with its evidence (README "The surfaces").

    ~/bpyenv/bin/python experiments/gun_lab/win73/win73_paint.py [--size=2048] [--barrel=24] [--out=DIR]
        [--preview=DIR --views=...]   # Cycles stills of the painted gun (the real judge is the game's light)
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
_src = open(os.path.join(HERE, "win73_blender.py")).read().replace("\nmain()\n", "\n")
exec(compile(_src, os.path.join(HERE, "win73_blender.py"), "exec"))  # build(), arg, rig_json, preview, ...

import bpy  # noqa: E402
import numpy as np  # noqa: E402

SIZE = int(arg("size", "2048"))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
WALNUT_RAW = os.path.join(HERE, "..", "saa", "surfaces", "raw", "walnut_1.jpg")
SURF = os.path.join(HERE, "surfaces")

# Each part's finish: README "The surfaces" gives the evidence for each.
FINISH = {
    "Receiver": "blued", "Barrel": "blued", "MagTube": "blued", "ForendCap": "blued", "MagBand": "blued",
    "DustCover": "blued", "Gate": "blued", "RearSight": "blued", "FrontSight": "blued",
    "Buttplate": "blued",
    "Hammer": "case", "Lever": "case", "Trigger": "case",
    "Bolt": "bright", "Carrier": "bright",
    "Forend": "walnut", "Buttstock": "walnut",
}
SCREW = "fire"
# Per finish: how it is made, its wear and roughness, metal or not.
LOOK = {
    "case":   {"kind": "case", "rough": 0.24, "metal": 1.0, "wear": 0.55},
    "blued":  {"kind": "blued", "rough": 0.21, "metal": 1.0, "wear": 0.9},   # 0.17 blew the sun to a white point (round 1)
    "fire":   {"kind": "fire", "rough": 0.15, "metal": 1.0, "wear": 0.5},
    "bright": {"kind": "bright", "rough": 0.24, "metal": 1.0, "wear": 0.3},
    "walnut": {"kind": "walnut", "rough": 0.42, "metal": 0.0, "wear": 0.55},
    "bore":   {"kind": "solid", "color": (0.04, 0.04, 0.045), "rough": 0.6, "metal": 1.0, "wear": 0.0},
}
BARE_STEEL = (0.50, 0.50, 0.51)
# The hammer's spur is checkered (a knurl) above this height in its own space (metres over its pivot).
SPUR_Z = (0.35 + 1.90) * IN
# The action's atlas (seen close in first person) and the long parts' atlas.
ACTION = ("Receiver", "Hammer", "Lever", "Trigger", "Gate", "DustCover", "Bolt", "Carrier", "RearSight")


def walnut_tile():
    """The Colt's walnut painting made seamless (the texture factory's blend, used, not changed), 1024."""
    sys.path.insert(0, os.path.join(ROOT, "tools", "textures"))
    import reduce as rd
    from PIL import Image
    os.makedirs(SURF, exist_ok=True)
    out = os.path.join(SURF, "walnut_1.png")
    if not os.path.exists(out):
        a = np.asarray(Image.open(WALNUT_RAW).convert("RGB").resize((1024, 1024), Image.LANCZOS)).astype(np.float32) / 255.0
        a = rd.seamless(a, np.random.default_rng(sum(map(ord, "walnut_1"))))
        Image.fromarray((np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8)).save(out)
    return out


class G:
    """A small node-graph builder (the Colt's)."""
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


def node_tree(mat, look, img, mode, knurl=False):
    """mat's nodes rebuilt for one bake: the albedo, or (1, roughness, metal), into an Emission shader;
    the target image the active node (what Cycles bakes into)."""
    g = G(mat)
    out = g.node("ShaderNodeOutputMaterial")
    emit = g.node("ShaderNodeEmission")
    g.L.new(emit.outputs[0], out.inputs[0])
    obj = g.node("ShaderNodeTexCoord").outputs["Object"]           # metres, the part's own space
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
    ao = g.N.new("ShaderNodeAmbientOcclusion")
    ao.inputs["Distance"].default_value = 0.004
    ao.samples = 16
    cav = g.maprange(ao.outputs["AO"], 1.0, 0.35)
    # Nothing rubs inside a hollow: the side plates' seams and the screws' slots keep their finish (the
    # first round's seams wore bright both sides and read as a dotted white line).
    wear = g.math("MULTIPLY", wear, g.maprange(ao.outputs["AO"], 0.80, 0.95))
    kind = look["kind"]
    rough = look["rough"]
    if kind == "case":
        # The Colt's: fine, subtle swirls of blue, violet and a little straw on a dark steel base.
        swirl = g.math("ADD", g.noise(obj, 120.0, 8.0, 0.6, 3.2), g.math("MULTIPLY", g.noise(obj, 380.0, 4.0, 0.5, 1.6), 0.35))
        swirl = g.maprange(swirl, 0.55, 1.05)
        oxide = g.ramp(swirl, [(0.00, (0.12, 0.12, 0.13)), (0.22, (0.09, 0.12, 0.27)), (0.36, (0.17, 0.11, 0.25)),
                               (0.47, (0.11, 0.15, 0.32)), (0.56, (0.27, 0.22, 0.12)), (0.62, (0.13, 0.13, 0.15)),
                               (0.80, (0.10, 0.14, 0.29)), (1.00, (0.21, 0.23, 0.31))])
        amount = g.maprange(g.noise(obj, 45.0, 3.0), 0.35, 0.70, 0.35, 0.85)
        base = g.mix(amount, (0.14, 0.14, 0.15), oxide)
        worn = g.mix(wear, base, (0.62, 0.62, 0.63))
        r_var = g.math("MULTIPLY", g.noise(obj, 300.0, 3.0), 0.08)
    elif kind in ("blued", "fire"):
        # Deep blue-black with fine polish lines along the gun (Blender's local Y is the gun's forward for
        # every part) and a slow unevenness; edges worn to bare steel, browned where thin.
        stretch = g.N.new("ShaderNodeVectorMath")
        stretch.operation = "MULTIPLY"
        g.L.new(obj, stretch.inputs[0])
        stretch.inputs[1].default_value = (1.0, 0.012, 1.0)
        lines = g.noise(stretch.outputs[0], 2600.0, 2.0, 0.5)
        tone = g.noise(obj, 30.0, 3.0)
        if kind == "blued":
            dark, light = (0.10, 0.115, 0.165), (0.17, 0.19, 0.26)
        else:
            dark, light = (0.05, 0.08, 0.20), (0.08, 0.13, 0.28)
        base = g.mix(g.math("ADD", g.math("MULTIPLY", lines, 0.6), g.math("MULTIPLY", tone, 0.4)), dark, light)
        worn = g.mix(wear, base, BARE_STEEL)
        thin = g.math("MULTIPLY", g.maprange(g.noise(obj, 90.0, 4.0), 0.55, 0.75), 0.35)
        worn = g.mix(g.math("MULTIPLY", thin, edge), worn, (0.24, 0.20, 0.18))
        r_var = g.math("MULTIPLY", lines, 0.06)
    elif kind == "bright":
        # Steel left in the white (polished, not blued): light grey with fine machining lines, dulled.
        stretch = g.N.new("ShaderNodeVectorMath")
        stretch.operation = "MULTIPLY"
        g.L.new(obj, stretch.inputs[0])
        stretch.inputs[1].default_value = (1.0, 0.02, 1.0)
        lines = g.noise(stretch.outputs[0], 1800.0, 2.0, 0.5)
        base = g.mix(lines, (0.44, 0.44, 0.45), (0.56, 0.56, 0.57))
        worn = base
        r_var = g.math("MULTIPLY", lines, 0.08)
    elif kind == "walnut":
        tex = g.N.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(walnut_tile(), check_existing=True)
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
    if knurl:
        # The hammer spur's checkering: a diamond knurl, 1.0 mm a line, on the spur above SPUR_Z in the
        # hammer's own space (the Colt's knurl, a touch lighter: Sean's note on the Colt's).
        sep = g.N.new("ShaderNodeSeparateXYZ")
        g.L.new(obj, sep.inputs[0])
        k = 2 * math.pi / 0.0010
        rows = []
        for op in ("ADD", "SUBTRACT"):
            d = g.math(op, sep.outputs["Y"], sep.outputs["Z"])
            wave = g.math("ABSOLUTE", g.math("SINE", g.math("MULTIPLY", d, k), 0.0), 0.0)
            rows.append(g.maprange(wave, 0.35, 0.10))
        on = g.maprange(sep.outputs["Z"], SPUR_Z - 0.0015, SPUR_Z + 0.0015)
        groove = g.math("MULTIPLY", g.math("MAXIMUM", rows[0], rows[1], True), on)
        worn = g.mix(g.math("MULTIPLY", groove, 0.55), worn, (0.06, 0.06, 0.065))
        r_var = g.math("ADD", r_var, g.math("MULTIPLY", groove, 0.25))
    if mode == "albedo":
        col = g.mix(g.math("MULTIPLY", cav, 0.6), worn, (0.035, 0.030, 0.025))
        g.L.new(col, emit.inputs["Color"])
    else:
        r = g.math("ADD", g.math("ADD", rough, r_var), g.math("MULTIPLY", wear, 0.08))
        r = g.math("ADD", r, g.math("MULTIPLY", cav, 0.35), True)
        comb = g.node("ShaderNodeCombineColor", Red=1.0, Blue=look["metal"])
        g.L.new(r, comb.inputs["Green"])
        g.L.new(comb.outputs[0], emit.inputs["Color"])
    target = g.N.new("ShaderNodeTexImage")
    target.image = img
    uvb = g.N.new("ShaderNodeUVMap")
    uvb.uv_map = "bake"
    g.L.new(uvb.outputs["UV"], target.inputs["Vector"])
    g.N.active = target
    target.select = True


def unwrap(objs):
    """One atlas for a set of parts: a second UV layer, smart-projected and packed together (the Colt's)."""
    for ob in objs:
        lay = ob.data.uv_layers.new(name="bake")
        ob.data.uv_layers.active = lay
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(45), island_margin=0.003, area_weight=0.0, correct_aspect=True)
    bpy.ops.uv.pack_islands(margin=0.003, rotate=True)
    bpy.ops.object.mode_set(mode="OBJECT")


def finish_of(part):
    return FINISH.get(part, SCREW if part.startswith("Screw_") else None)


def assign(parts):
    """Each part's main material replaced by its finish's (the bore keeps its own): one material a finish."""
    mats_ = {}
    for name, ob in parts.items():
        f = finish_of(name)
        if f is None:
            continue
        if f not in mats_:
            m = bpy.data.materials.new("w73f_" + f)
            m.use_nodes = True
            mats_[f] = m
        ob.material_slots[0].material = mats_[f]
        if name == "Hammer":
            # its own copy, for the spur's knurl
            m = bpy.data.materials.new("w73f_case_knurl")
            m.use_nodes = True
            ob.material_slots[0].material = m
    return mats_


def bake(objs, img, mode):
    for ob in objs:
        for slot in ob.material_slots:
            m = slot.material
            if not m:
                continue
            key = m.name.split(".")[0]
            if key == "w73f_case_knurl":
                node_tree(m, LOOK["case"], img, mode, knurl=True)
            elif key.startswith("w73f_"):
                node_tree(m, LOOK[key[5:]], img, mode)
            elif key == "w73_bore":
                node_tree(m, LOOK["bore"], img, mode)
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.bake(type="EMIT", margin=6, use_clear=True)


def painted_material(name, albedo, orm):
    mat = bpy.data.materials.new(name)
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
    return mat


def main_paint():
    parts, rounds, markers, tube_end = build()
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = int(arg("samples", "24"))
    assign(parts)
    for m in bpy.data.materials:
        m.use_nodes = True
    sets = {"action": [o for n, o in parts.items() if n in ACTION or n.startswith("Screw_")],
            "long": [o for n, o in parts.items() if n not in ACTION and not n.startswith("Screw_")]}
    out_dir = arg("out", HERE)
    for tag, objs in sets.items():
        unwrap(objs)
        albedo = bpy.data.images.new("w73_%s_albedo" % tag, SIZE, SIZE)
        orm = bpy.data.images.new("w73_%s_orm" % tag, SIZE, SIZE)
        orm.colorspace_settings.name = "Non-Color"
        bake(objs, albedo, "albedo")
        bake(objs, orm, "orm")
        mat = painted_material("w73_%s_painted" % tag, albedo, orm)
        for ob in objs:
            for slot in ob.material_slots:
                if slot.material and slot.material.name.split(".")[0].startswith(("w73f_", "w73_bore")):
                    slot.material = mat
            if "UVMap" in ob.data.uv_layers:
                ob.data.uv_layers.remove(ob.data.uv_layers["UVMap"])
        os.makedirs(os.path.join(out_dir, "surfaces"), exist_ok=True)
        for img in (albedo, orm):
            img.filepath_raw = os.path.join(out_dir, "surfaces", img.name + ".png")
            img.file_format = "PNG"
            img.save()
    return parts, rounds, markers


def export(parts, rounds, markers):
    keep = set()

    def walk(o):
        keep.add(o.name)
        for c in o.children:
            walk(c)
    walk(bpy.data.objects["Win73"])
    for o in list(bpy.data.objects):
        if o.name not in keep:
            bpy.data.objects.remove(o, do_unlink=True)
    tag = "%g" % BARREL
    out = arg("out", HERE)
    glb = os.path.join(out, "win73_%s.glb" % tag)
    bpy.ops.export_scene.gltf(filepath=glb, export_format="GLB", export_apply=True, export_yup=True,
                              export_image_format="JPEG", export_jpeg_quality=92,
                              export_cameras=False, export_lights=False)
    rig_json(parts, markers, os.path.join(out, "win73_%s_rig.json" % tag))
    print("Win73 painted -> %s (%.1f MB)" % (glb, os.path.getsize(glb) / 1e6))


r = main_paint()
export(*r)
for w in WARN:
    print("WARN boolean", w)
if PREVIEW:
    preview(PREVIEW)
