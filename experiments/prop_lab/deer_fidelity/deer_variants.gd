extends RefCounted
## The deer head's fidelity lab (issue #524; README.md beside this file): every version of the
## Rodin deer the A/B/C/D test draws, built at run time from make_variants.py's files (DIR,
## default build/deer_fidelity/variants: geometry GLBs and PNG maps, loaded from disk, not
## imported) or, for the game's own, from the game's files exactly as the kit draws them.
## Lab only: nothing in the game reads this.

const DEFAULT_DIR := "res://build/deer_fidelity/variants"

## Each version: its geometry ("live": the game's deer_head.glb, its four parts; or a GLB of DIR),
## how it's drawn ("grid": the game's texel grid shader, as PropModels.model_paint; "pbr": Godot's
## standard material, filtered and mipmapped), the colour map ("live": the game's
## deer_head_paint.png; or alb_<px>), mipmaps (grid only: pbr always has them), the normal map
## ("", "nrm_<px>": Rodin's own, "bake_nrm_<mesh>_2048": the master baked onto the cut mesh) and
## the roughness ("": one value, 0.85 as the game's; "rgh_<px>": Rodin's; "split_rgh_2048": by
## class). In the ladder's order: from the game's deer, one step at a time, to Rodin's master.
const VARIANTS := {
	"C0": {"label": "C0 the game's deer now: 6k, 1k paint, grid shader, no mipmaps, roughness 0.85",
			"mesh": "live", "draw": "grid", "alb": "live", "mips": false},
	"C1": {"label": "C1 C0 with mipmaps", "mesh": "live", "draw": "grid", "alb": "live", "mips": true},
	"C1f": {"label": "C1f C1 without the min-square coarsening (fixed_squares: a texel a square)", "mesh": "live", "draw": "grid",
			"alb": "live", "mips": true, "params": {"fixed_squares": true}},
	"C1fl": {"label": "C1fl C1f lit per pixel, not per texel (global tile_light 0: the wall too)", "mesh": "live", "draw": "grid",
			"alb": "live", "mips": true, "params": {"fixed_squares": true}, "globals": {"tile_light": 0.0}},
	"C2": {"label": "C2 C0 drawn by a standard (PBR) material: filtered, mipmapped", "mesh": "live", "draw": "pbr", "alb": "live"},
	"C3": {"label": "C3 6k, 2k paint, standard material", "mesh": "g6k", "draw": "pbr", "alb": "alb_2048"},
	"C4": {"label": "C4 C3 + normals baked from the master + Rodin's roughness (2k)", "mesh": "g6k", "draw": "pbr",
			"alb": "alb_2048", "nrm": "bake_nrm_g6k_2048", "rgh": "rgh_2048"},
	"C5": {"label": "C5 15k, 2k, baked normals, Rodin's roughness", "mesh": "g15k", "draw": "pbr", "alb": "alb_2048",
			"nrm": "bake_nrm_g15k_2048", "rgh": "rgh_2048"},
	"C6": {"label": "C6 the master's 30k, 2k maps (its own normal and roughness)", "mesh": "g_master", "draw": "pbr",
			"alb": "alb_2048", "nrm": "nrm_2048", "rgh": "rgh_2048"},
	"C7": {"label": "C7 C5 with roughness by surface (fur, antler, glass eye, wet nose, varnished plaque)", "mesh": "g15k",
			"draw": "pbr", "alb": "alb_2048", "nrm": "bake_nrm_g15k_2048", "rgh": "split_rgh_2048"},
	"Cg2": {"label": "Cg2 grid shader kept, 15k and 2k paint, mipmaps", "mesh": "g15k", "draw": "grid", "alb": "alb_2048", "mips": true},
	"Ag": {"label": "Ag the master's 30k and 4k paint through the grid shader (no mipmaps, as the game)", "mesh": "g_master",
			"draw": "grid", "alb": "alb_4096", "mips": false},
	"A": {"label": "A Rodin's master untouched: 30k, 4k colour, normal, roughness", "mesh": "g_master", "draw": "pbr",
			"alb": "alb_4096", "nrm": "nrm_4096", "rgh": "rgh_4096"},
}
## The kit's parts (deer_head_rodin.py's split, the same numbers): which a triangle at `c` is in.
const PARTS := ["plaque", "neck", "head", "nose"]

var dir := DEFAULT_DIR
var _tex := {}
var _meshes := {}


func _init(d := "") -> void:
	if d != "":
		dir = d


static func part_of(c: Vector3) -> String:
	if c.z < 0.06:
		return "plaque"
	if c.y < -0.10:
		return "neck"
	return "nose" if c.z > 0.30 and c.y < 0.04 else "head"


## A map of DIR as a texture (sRGB or not is the material's business), mipmapped if asked.
func texture(name: String, mips: bool) -> Texture2D:
	var key := "%s/%s" % [name, mips]
	if _tex.has(key):
		return _tex[key]
	var img := Image.load_from_file(ProjectSettings.globalize_path(dir.path_join(name + ".png")))
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	if mips:
		img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex[key] = t
	return t


## Its whole mesh (one surface) in the kit's space.
func mesh(id: String) -> ArrayMesh:
	var name: String = VARIANTS[id].mesh
	if _meshes.has(name):
		return _meshes[name]
	var st := SurfaceTool.new()
	if name == "live":
		for p: String in PARTS:
			st.append_from(PropKit.model_part("deer_head", p), 0, Transform3D.IDENTITY)
	else:
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var err := doc.append_from_file(ProjectSettings.globalize_path(dir.path_join(name + ".glb")), state)
		assert(err == OK, "no %s in %s: run make_variants.py" % [name, dir])
		var scene := doc.generate_scene(state)
		for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
			var xf := Transform3D.IDENTITY
			var n: Node = mi
			while n != scene and n is Node3D:
				xf = (n as Node3D).transform * xf
				n = n.get_parent()
			for s in mi.mesh.get_surface_count():
				st.append_from(mi.mesh, s, xf)
		scene.free()
	var m := st.commit()
	_meshes[name] = m
	return m


## Its mesh cut into the kit's parts, as deer_head_rodin.py cuts the game's: {part: ArrayMesh}, each
## with only its own vertices.
func parts(id: String) -> Dictionary:
	var arrays := mesh(id).surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if idx.is_empty():
		idx.resize(verts.size())
		for i in verts.size():
			idx[i] = i
	var out := {}
	for p: String in PARTS:
		var remap := {}
		var keep := PackedInt32Array()
		for t in range(0, idx.size(), 3):
			var c := (verts[idx[t]] + verts[idx[t + 1]] + verts[idx[t + 2]]) / 3.0
			if part_of(c) != p:
				continue
			for k in 3:
				var o: int = idx[t + k]
				if not remap.has(o):
					remap[o] = remap.size()
				keep.append(remap[o])
		var order := PackedInt32Array()
		order.resize(remap.size())
		for o: int in remap:
			order[remap[o]] = o
		var a := []
		a.resize(Mesh.ARRAY_MAX)
		a[Mesh.ARRAY_INDEX] = keep
		# Each per-vertex array cut to its vertices (a tangent is four floats a vertex).
		for k: int in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2, Mesh.ARRAY_COLOR]:
			var src: Variant = arrays[k]
			if src == null or src.size() == 0:
				continue
			var per := 4 if k == Mesh.ARRAY_TANGENT else 1
			var dst: Variant = src.duplicate()
			dst.resize(order.size() * per)
			for i in order.size():
				for j in per:
					dst[i * per + j] = src[order[i] * per + j]
			a[k] = dst
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
		out[p] = am
	return out


func triangles(id: String) -> int:
	var a := mesh(id).surface_get_arrays(0)
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	return (idx.size() if not idx.is_empty() else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3


func material(id: String) -> Material:
	var v: Dictionary = VARIANTS[id]
	if v.draw == "grid":
		var m: ShaderMaterial
		if v.alb == "live" and not v.mips:
			return PropModels.model_paint("deer_head")  # the game's own, shared
		m = PropModels.model_paint("deer_head").duplicate()
		var t: Texture2D = PropModels.model_paint("deer_head").get_shader_parameter(&"albedo_tex")
		if v.alb == "live":
			var img := t.get_image()
			img.decompress()
			img.generate_mipmaps()
			t = ImageTexture.create_from_image(img)
		else:
			t = texture(v.alb, v.mips)
		m.set_shader_parameter(&"albedo_tex", t)
		m.set_shader_parameter(&"texels_per_meter", float(t.get_width()))
		m.set_shader_parameter(&"use_mipmaps", v.mips)
		for k: String in v.get("params", {}):
			m.set_shader_parameter(StringName(k), v.params[k])
		return m
	var m2 := ShaderMaterial.new()
	m2.shader = pbr_shader()
	if v.alb == "live":
		var img2: Image = (PropModels.model_paint("deer_head").get_shader_parameter(&"albedo_tex") as Texture2D).get_image()
		img2.decompress()
		img2.generate_mipmaps()
		m2.set_shader_parameter(&"albedo_tex", ImageTexture.create_from_image(img2))
	else:
		m2.set_shader_parameter(&"albedo_tex", texture(v.alb, true))
	m2.set_shader_parameter(&"roughness", 0.85)
	if v.get("rgh", "") != "":
		m2.set_shader_parameter(&"use_rough", true)
		m2.set_shader_parameter(&"rough_tex", texture(v.rgh, true))
	if v.get("nrm", "") != "":
		m2.set_shader_parameter(&"use_normal", true)
		m2.set_shader_parameter(&"normal_tex", texture(v.nrm, true))
	return m2


## "pbr": Godot's standard material's lighting (Burley diffuse, Schlick-GGX specular 0.5, as a
## StandardMaterial3D's defaults) on the colour, normal and roughness maps, filtered and mipmapped;
## written out as a shader because the kit's `model:` look takes only a ShaderMaterial
## (PropModels.model_paint is typed so: a StandardMaterial3D there is refused and drawn as none).
static var _pbr: Shader


static func pbr_shader() -> Shader:
	if _pbr == null:
		_pbr = Shader.new()
		_pbr.code = """shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_normal = false;
uniform bool use_rough = false;
uniform float roughness = 0.85;
uniform float specular = 0.5;
void fragment() {
	ALBEDO = texture(albedo_tex, UV).rgb;
	ROUGHNESS = use_rough ? texture(rough_tex, UV).r : roughness;
	METALLIC = 0.0;
	SPECULAR = specular;
	if (use_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
}
"""
	return _pbr


## The shader globals it's drawn under ({} for the game's): set by the stand while it's drawn.
static func globals(id: String) -> Dictionary:
	return VARIANTS[id].get("globals", {})


## The texture memory it takes (bytes): as drawn here (RGBA8, mipmaps a third more) and as the game
## would ship it VRAM-compressed (BC7 colour, BC5 normal, BC4 roughness: 1, 1, 0.5 bytes a texel).
func texture_bytes(id: String) -> Dictionary:
	var v: Dictionary = VARIANTS[id]
	var raw := 0.0
	var vram := 0.0
	for key: String in ["alb", "nrm", "rgh"]:
		var name: String = v.get(key, "")
		if name == "":
			continue
		var px := 1024 if name == "live" else int(name.get_slice("_", name.get_slice_count("_") - 1))
		var mips := 4.0 / 3.0 if (v.draw == "pbr" or v.get("mips", false)) else 1.0
		raw += px * px * 4 * mips
		vram += px * px * {"alb": 1.0, "nrm": 1.0, "rgh": 0.5}[key] * mips
	return {"rgba8": int(raw), "vram_bc": int(vram)}


## The version, whole, drawn: a node in the kit's space.
func node(id: String) -> Node3D:
	var mi := MeshInstance3D.new()
	mi.name = "Deer_" + id
	mi.mesh = mesh(id)
	mi.material_override = material(id)
	return mi


## D: the kit's deer_head, its members drawn as this version: its parts and material laid into
## PropKit's and PropModels' caches before it's made (the kit file, the members, nails, fire and
## breaking all the game's own). Lab only; `restore()` puts the game's back.
func use_in_kit(id: String) -> void:
	var p := parts(id)
	for part: String in PARTS:
		PropKit._model_parts["deer_head/" + part] = p[part]
	PropModels._materials["model_deer_head"] = material(id)


static func restore() -> void:
	for part: String in PARTS:
		PropKit._model_parts.erase("deer_head/" + part)
	PropModels._materials.erase("model_deer_head")
