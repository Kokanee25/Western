"""Props' metal (and their china, cloth and leather) the gun way (docs/briefs/prop-factory.md, #788).

The Colt's and the Winchester's surfaces (experiments/gun_lab/saa/saa_paint.py, win73_paint.py: their
node recipes adapted here) taught the factory how to make metal that reads as metal in the game's
light: each finish made from 3D noise in each part's own space (nothing stretches or repeats along a
long part), worn by its own shape (edges rubbed to what's under the finish: the Bevel node's
rounded normal parting from the face; hollows dark and duller: ambient occlusion within a few mm),
baked by Cycles as emission into one atlas a model, an albedo and an ORM (glTF's occlusion,
roughness, metal), which the game draws physically (`pbr:<model>`, PropModels.pbr): metallic 1, so
it mirrors the game's sky and lamps. No paid call.

A prop script builds its parts with common.py's shapes and calls

    export_baked(prop_id, [(part, finish), ...], size=1024)

which writes assets/props/models/<prop_id>.glb (the parts as objects, named as the kit file's
`"part"`s, on the atlas's UVs) and <prop_id>_albedo.png / _orm.png.

Each finish's evidence is its comment; a finish that isn't metal (china, oilcloth, ticking, wool) is
baked the same way, metal 0, so a prop is one atlas and one material.
"""
import math
import os

import common

# Each finish: how it's made (kind), its colour(s), roughness, metal, how much its edges wear.
FINISHES = {
    # Black japan (asphaltum varnish stoved on): the finish of cast and wrought iron bedsteads and
    # hospital cots through the 1870s-80s (period trade catalogues' "japanned iron bedsteads"); a
    # varnish, so not metal, worn on its edges to the iron under it, a little rust in the wear.
    "japanned": {"kind": "coat", "color": (0.030, 0.027, 0.024), "under": (0.30, 0.29, 0.28), "rust": 0.35,
                 "rough": 0.32, "metal": 0.0, "metal_under": 1.0, "wear": 0.8},
    # Nickel plate on steel: surgical instruments from the late 1870s on were nickel-plated (cheaper
    # than silver, harder than bare polished steel); warm white-grey, a soft polish, rubbed through
    # to the steel only on the hardest-used edges.
    "nickel": {"kind": "plate", "color": (0.70, 0.68, 0.62), "under": (0.56, 0.56, 0.57), "rust": 0.0,
               "rough": 0.20, "metal": 1.0, "wear": 0.35},
    # Bright polished steel (a saw's blade, a probe's shaft): cool grey, fine polish lines, a faint
    # brown bloom in the hollows where it's been put away damp.
    "steel": {"kind": "plate", "color": (0.58, 0.58, 0.60), "under": (0.50, 0.50, 0.51), "rust": 0.25,
              "rough": 0.24, "metal": 1.0, "wear": 0.2},
    # Cast and sheet brass (a lamp's font and foot, a scale's pans): yellow, darkened to brown in
    # the hollows by tarnish, rubbed bright where hands go.
    "brass": {"kind": "plate", "color": (0.62, 0.46, 0.22), "under": (0.80, 0.64, 0.34), "rust": 0.0,
              "rough": 0.30, "metal": 1.0, "wear": 0.6, "tarnish": 0.55},
    # Tinplate (sheet iron dipped in tin): a lamp's reflector and a cheap tray; bright grey, mottled
    # dull, specks of rust where the tin's worn.
    "tin": {"kind": "plate", "color": (0.66, 0.66, 0.64), "under": (0.42, 0.33, 0.24), "rust": 0.5,
            "rough": 0.26, "metal": 1.0, "wear": 0.3, "mottle": 0.5},
    # White enamel on iron (enamelled hollow-ware, made in the US from the 1870s): a doctor's basin
    # and instrument tray; glossy, chipped black at its rims.
    "enamel": {"kind": "coat", "color": (0.83, 0.83, 0.80), "under": (0.05, 0.05, 0.06), "rust": 0.2,
               "rough": 0.12, "metal": 0.0, "metal_under": 1.0, "wear": 0.5},
    # White ironstone china (the common washstand set of the 1860s-80s, English and American
    # potteries): a creamy white glaze, faint crazing, no metal.
    "china": {"kind": "coat", "color": (0.86, 0.85, 0.80), "under": (0.70, 0.66, 0.58), "rust": 0.0,
              "rough": 0.08, "metal": 0.0, "wear": 0.05, "craze": 0.5},
    # Black glazed oilcloth ("American cloth") over horsehair: the covering of doctors' couches and
    # examining tables; a dull sheen, cracked and greyed where it's worn.
    "oilcloth": {"kind": "coat", "color": (0.040, 0.036, 0.034), "under": (0.20, 0.17, 0.14), "rust": 0.0,
                 "rough": 0.45, "metal": 0.0, "wear": 0.6, "craze": 0.8},
    # Ebony (instrument handles until aseptic all-metal ones in the 1890s), and a knife's bone.
    "ebony": {"kind": "coat", "color": (0.045, 0.038, 0.033), "under": (0.10, 0.08, 0.06), "rust": 0.0,
              "rough": 0.35, "metal": 0.0, "wear": 0.3},
    # Blue-and-white striped ticking (a mattress's or pillow's cover, cotton twill) and a grey wool
    # blanket with a dark stripe at its ends (the army's and hospitals' issue): cloth, no metal.
    "ticking": {"kind": "stripes", "color": (0.70, 0.67, 0.58), "stripe": (0.20, 0.24, 0.34), "pitch": 0.025,
                "rough": 0.85, "metal": 0.0, "wear": 0.0},
    "wool": {"kind": "wool", "color": (0.36, 0.34, 0.31), "stripe": (0.16, 0.14, 0.13), "rough": 0.95,
             "metal": 0.0, "wear": 0.0},
    # A lamp's chimney and a bottle are drawn by the game's glass, not baked: this is only their
    # place on the atlas (a dark neutral, if anything shows it).
    "glass": {"kind": "coat", "color": (0.20, 0.21, 0.20), "under": (0.20, 0.21, 0.20), "rust": 0.0,
              "rough": 0.05, "metal": 0.0, "wear": 0.0},
}


class G:
    """A small node-graph builder (the Colt's, saa_paint.py)."""

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

    def maprange(self, v, a, b, c=0.0, d=1.0):
        n = self.N.new("ShaderNodeMapRange")
        n.inputs["From Min"].default_value = a
        n.inputs["From Max"].default_value = b
        n.inputs["To Min"].default_value = c
        n.inputs["To Max"].default_value = d
        self.L.new(v, n.inputs["Value"])
        return n.outputs["Result"]


def _node_tree(mat, look, img, mode):
    """mat's nodes for one bake: the albedo, or (occlusion, roughness, metal), into an Emission
    shader, the target image the active node (what Cycles bakes into)."""
    g = G(mat)
    out = g.node("ShaderNodeOutputMaterial")
    emit = g.node("ShaderNodeEmission")
    g.L.new(emit.outputs[0], out.inputs[0])
    obj = g.node("ShaderNodeTexCoord").outputs["Object"]  # metres, the part's own space
    # Wear: the edge (Bevel's rounded normal against the true one), broken up by noise.
    geo = g.node("ShaderNodeNewGeometry")
    bev = g.node("ShaderNodeBevel", Radius=0.0025)
    bev.samples = 8
    dot = g.N.new("ShaderNodeVectorMath")
    dot.operation = "DOT_PRODUCT"
    g.L.new(geo.outputs["Normal"], dot.inputs[0])
    g.L.new(bev.outputs[0], dot.inputs[1])
    edge = g.maprange(dot.outputs["Value"], 0.998, 0.93)
    brk = g.maprange(g.noise(obj, 160.0, 6.0), 0.35, 0.65)
    wear = g.math("MULTIPLY", g.math("MULTIPLY", edge, brk, True), look["wear"])
    # Grime: the hollows.
    ao = g.N.new("ShaderNodeAmbientOcclusion")
    ao.inputs["Distance"].default_value = 0.012
    ao.samples = 16
    cav = g.maprange(ao.outputs["AO"], 1.0, 0.35)
    tone = g.noise(obj, 18.0, 4.0)
    kind = look["kind"]
    r_var = g.math("MULTIPLY", g.noise(obj, 220.0, 3.0), 0.06)
    if kind in ("coat", "plate"):
        dark = tuple(c * 0.86 for c in look["color"])
        base = g.mix(tone, dark, look["color"])
        if look.get("mottle"):
            m = g.maprange(g.noise(obj, 40.0, 5.0), 0.45, 0.7, 0.0, look["mottle"])
            base = g.mix(m, base, tuple(c * 0.78 for c in look["color"]))
        if look.get("tarnish"):
            base = g.mix(g.math("MULTIPLY", cav, look["tarnish"]), base, (0.22, 0.15, 0.07))
        if look.get("craze"):
            # Fine crazing: thin dark lines of a cell noise's edges.
            vor = g.N.new("ShaderNodeTexVoronoi")
            vor.feature = "DISTANCE_TO_EDGE"
            vor.inputs["Scale"].default_value = 70.0
            g.L.new(obj, vor.inputs["Vector"])
            line = g.maprange(vor.outputs["Distance"], 0.03, 0.0, 0.0, look["craze"] * 0.35)
            base = g.mix(line, base, tuple(c * 0.55 for c in look["color"]))
        worn = g.mix(wear, base, look["under"])
        if look.get("rust"):
            spots = g.maprange(g.noise(obj, 260.0, 5.0, 0.6), 0.62, 0.78, 0.0, look["rust"])
            worn = g.mix(g.math("MULTIPLY", spots, g.math("ADD", wear, g.math("MULTIPLY", cav, 0.5))), worn, (0.24, 0.12, 0.05))
        mu = look.get("metal_under", look["metal"])  # a coat worn through to metal: metal there
        metal = look["metal"] if mu == look["metal"] else g.math("ADD", look["metal"], g.math("MULTIPLY", wear, mu - look["metal"]))
    elif kind == "stripes":
        sep = g.N.new("ShaderNodeSeparateXYZ")
        g.L.new(obj, sep.inputs[0])
        # Stripes along the part's X (the mattress's length): two narrow blue lines a pitch.
        wave = g.math("SINE", g.math("MULTIPLY", sep.outputs["Z"], 2 * math.pi / look["pitch"]), 0.0)
        stripe = g.maprange(wave, 0.55, 0.75)
        base = g.mix(stripe, look["color"], look["stripe"])
        base = g.mix(g.math("MULTIPLY", g.noise(obj, 30.0, 5.0), 0.35), base, (0.45, 0.40, 0.32))  # soil
        worn = base
        metal = 0.0
    else:  # wool
        sep = g.N.new("ShaderNodeSeparateXYZ")
        g.L.new(obj, sep.inputs[0])
        nap = g.noise(obj, 900.0, 3.0, 0.6)
        base = g.mix(g.math("MULTIPLY", nap, 0.5), look["color"], tuple(c * 0.75 for c in look["color"]))
        # A dark band a hand from each end (|x| near the blanket's ends: the part's own X).
        ax = g.math("ABSOLUTE", sep.outputs["X"], 0.0)
        band = g.math("MULTIPLY", g.maprange(ax, 0.66, 0.68), g.maprange(ax, 0.78, 0.76), True)
        worn = g.mix(band, base, look["stripe"])
        metal = 0.0
    if mode == "albedo":
        col = g.mix(g.math("MULTIPLY", cav, 0.55), worn, (0.03, 0.026, 0.022))
        g.L.new(col, emit.inputs["Color"])
    else:
        r = g.math("ADD", g.math("ADD", look["rough"], r_var), g.math("MULTIPLY", wear, 0.10))
        r = g.math("ADD", r, g.math("MULTIPLY", cav, 0.30), True)
        occ = g.maprange(ao.outputs["AO"], 0.3, 1.0, 0.55, 1.0)
        comb = g.node("ShaderNodeCombineColor")
        g.L.new(occ, comb.inputs["Red"])
        g.L.new(r, comb.inputs["Green"])
        if isinstance(metal, float):
            comb.inputs["Blue"].default_value = metal
        else:
            g.L.new(metal, comb.inputs["Blue"])
        g.L.new(comb.outputs[0], emit.inputs["Color"])
    target = g.N.new("ShaderNodeTexImage")
    target.image = img
    uvb = g.N.new("ShaderNodeUVMap")
    uvb.uv_map = "bake"
    g.L.new(uvb.outputs["UV"], target.inputs["Vector"])
    g.N.active = target
    target.select = True


def export_baked(prop_id, parts, size=1024):
    """Write assets/props/models/<prop_id>.glb with its baked albedo and ORM: `parts` a list of
    (common.Part, finish name). One object a part (the kit file's `"part"`), on one atlas."""
    import bpy

    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 16
    scene.render.bake.margin = 6
    objs = []
    mats = {}
    for part, finish in parts:
        verts = [(x, -z, y) for x, y, z in part.verts]  # game space -> Blender's (the exporter turns back)
        mesh = bpy.data.meshes.new(part.name)
        mesh.from_pydata(verts, [], part.faces)
        mesh.validate()
        for poly in mesh.polygons:
            poly.use_smooth = part.smooth
        obj = bpy.data.objects.new(part.name, mesh)
        scene.collection.objects.link(obj)
        if finish not in mats:
            m = bpy.data.materials.new(finish)
            m.use_nodes = True
            mats[finish] = m
        obj.data.materials.append(mats[finish])
        objs.append(obj)
    # One atlas for every part.
    for ob in objs:
        lay = ob.data.uv_layers.new(name="bake")
        ob.data.uv_layers.active = lay
    bpy.ops.object.select_all(action="DESELECT")
    for ob in objs:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(50), island_margin=0.006, area_weight=0.0, correct_aspect=True)
    bpy.ops.uv.pack_islands(margin=0.006, rotate=True)
    bpy.ops.object.mode_set(mode="OBJECT")
    os.makedirs(common.MODELS, exist_ok=True)
    out = {}
    for mode in ("albedo", "orm"):
        img = bpy.data.images.new("%s_%s" % (prop_id, mode), size, size, alpha=False)
        img.colorspace_settings.name = "sRGB" if mode == "albedo" else "Non-Color"
        for finish, m in mats.items():
            _node_tree(m, FINISHES[finish], img, mode)
        bpy.ops.object.select_all(action="DESELECT")
        for ob in objs:
            ob.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        bpy.ops.object.bake(type="EMIT", margin=6, use_clear=True)
        path = os.path.join(common.MODELS, "%s_%s.png" % (prop_id, mode))
        img.filepath_raw = path
        img.file_format = "PNG"
        img.save()
        out[mode] = path
    # The atlas the only UVs the game reads (its UV1), the materials left out (PropModels.pbr is the
    # one material).
    for ob in objs:
        ob.data.uv_layers.remove(ob.data.uv_layers["UVMap"]) if "UVMap" in ob.data.uv_layers else None
        ob.data.uv_layers["bake"].name = "UVMap"
        ob.data.materials.clear()
    path = os.path.join(common.MODELS, prop_id + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_materials="NONE", export_yup=True,
                              export_apply=True, export_animations=False, export_normals=True)
    tris = sum(len(f) - 2 for p, _ in parts for f in p.faces)
    print("%s: %d parts, %d triangles, %d atlas -> %s" % (prop_id, len(parts), tris, size, os.path.relpath(path, common.ROOT)))
    return path
