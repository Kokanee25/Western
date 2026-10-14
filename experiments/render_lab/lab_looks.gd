extends RefCounted
## The render lab's looks (experiments/render_lab/README.md): what changes between runs, and the
## paint probe. Loaded by path (a -s script compiles before the autoloads exist).
##
## The experiment, "paint light" (--look=paint): light keeps each surface's own colour. Every
## light still brightens and darkens a surface exactly as before (its luminance is untouched), but
## the share of the light's *colour* a surface takes rises with how lit it is: in half-light a
## board, a coat or a face keeps its painted colour (pl_tint of the light's hue), in full light it
## takes most of it (pl_tint_lit). The painters' rule of local colour: the lamp or the low sun
## shows in the highlights, not as one orange laid over every material. One rule for the world's
## texel grid, the ground and the people, from the same few numbers (SPEC); per material class
## where a class asks for its own (CLASSES).
##
## Made without touching the game's shaders: each production shader's code is read, its light()
## function (or Godot's own Burley/GGX, written out, for the texel grid that has none) gets the
## rule, and the variant is swapped onto the material in place. The game's files never change; a
## material swapped back is as it was.

## The rule's numbers (the common spec): the light's colour share in half-light and in full light,
## and the light (luminance × facing / PI, scene units) that counts as full. Tuned once on the two
## shots (2026-10-14): 0.3 / 0.85 / 0.9 first (paint_v1, kept), then these, which the judge and the
## lab both preferred.
const SPEC := {"pl_tint": 0.2, "pl_tint_lit": 1.0, "pl_lit": 0.25}
const SPEC_V1 := {"pl_tint": 0.3, "pl_tint_lit": 0.85, "pl_lit": 0.9}
## Per class (the material's shader family), what differs from SPEC: empty, one rule for all, so
## far; this is where skin, cloth, wood or metal would take their own share.
const CLASSES := {"grid": {}, "ground": {}, "skin": {}}

const GRID := "res://src/render/texel_grid.gdshader"
const HOLES := "res://src/structures/member_holes.gdshader"
const SKIN := "res://src/bodies/shaders/body_skin.gdshader"
const SKIN_DOUBLE := "res://src/bodies/shaders/body_skin_double.gdshader"
const GROUND := "res://src/world/ground.gdshader"
const SKIN_INC := "res://src/bodies/shaders/body_skin.gdshaderinc"

## The rule itself, put in front of each variant's light().
const RULE := """
// Render lab, paint light (experiments/render_lab/lab_looks.gd): the light's colour shared by how
// lit the surface is; its luminance untouched.
uniform float pl_tint = 0.3;
uniform float pl_tint_lit = 0.85;
uniform float pl_lit = 0.9;
vec3 pl_color(vec3 lc, float facing) {
	float l = dot(lc, vec3(0.2126, 0.7152, 0.0722));
	float s = mix(pl_tint, pl_tint_lit, smoothstep(0.0, pl_lit, l * facing / PI));
	return mix(vec3(l), lc, s);
}
"""

## Godot 4's own Burley diffuse and Schlick-GGX specular (the texel grid's render_mode), written
## out so the grid can take the rule with nothing else changed (from the engine's documented
## formulas: Burley 2012, "Physically Based Shading at Disney"; Karis 2013 for the GGX terms).
const GRID_LIGHT := """
float pl_schlick(float u) {
	float m = clamp(1.0 - u, 0.0, 1.0);
	float m2 = m * m;
	return m2 * m2 * m;
}
void light() {
	vec3 PL_LC = pl_color(LIGHT_COLOR, clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION);
	float NdotL = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float NdotV = clamp(dot(NORMAL, VIEW), 1e-4, 1.0);
	vec3 H = normalize(VIEW + LIGHT);
	float LdotH = clamp(dot(LIGHT, H), 0.0, 1.0);
	float NdotH = clamp(dot(NORMAL, H), 0.0, 1.0);
	float fd90 = 0.5 + 2.0 * LdotH * LdotH * ROUGHNESS;
	float fd = (1.0 + (fd90 - 1.0) * pl_schlick(NdotL)) * (1.0 + (fd90 - 1.0) * pl_schlick(NdotV));
	DIFFUSE_LIGHT += PL_LC * (fd * NdotL / PI) * ATTENUATION;
	float a = max(ROUGHNESS * ROUGHNESS, 0.002);
	float a2 = a * a;
	float d = NdotH * NdotH * (a2 - 1.0) + 1.0;
	float D = a2 / (PI * d * d);
	float k = a * 0.5;
	float V = 0.25 / ((NdotL * (1.0 - k) + k) * (NdotV * (1.0 - k) + k));
	float f0 = 0.16 * specular * specular;  // the grid's own uniform (light() can't read SPECULAR)
	float F = f0 + (1.0 - f0) * pl_schlick(LdotH);
	SPECULAR_LIGHT += PL_LC * (D * V * F * NdotL) * ATTENUATION * SPECULAR_AMOUNT;
}
"""

## Lights, grade and environment as they were before the probe.
static var _saved := {}
## Production shader path -> its paint-light variant; variant -> production shader.
static var _variants := {}
static var _originals := {}
static var _look := "base"


## Put `look` on everything under `root` ("base": the game as it is; "paint": the experiment;
## "paint_v1": its first tuning; "paint_flat": the colour share fixed at 0.3 everywhere, the
## control that stands for desaturating every light (an existing control); "paint_id": the
## variant shaders with the rule at a share of 1, which must draw exactly as base). Can be called
## again with another look at any time: the switch is live.
static func apply(root: Node, look: String) -> void:
	_look = look
	for gi: GeometryInstance3D in root.find_children("*", "GeometryInstance3D", true, false):
		_apply_to(gi)
	if root is GeometryInstance3D:
		_apply_to(root)


## Every node that enters `tree` from now on gets the look (for tools that build the scene
## themselves: shots.gd, play.gd).
static func install(tree: SceneTree, look: String) -> void:
	_look = look
	tree.node_added.connect(func(n: Node):
		if n is GeometryInstance3D:
			_apply_to.call_deferred(n))


static func _apply_to(gi: GeometryInstance3D) -> void:
	if not is_instance_valid(gi):
		return
	if gi.material_override:
		_swap(gi.material_override)
	if gi is MeshInstance3D:
		var mi := gi as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			if mi.get_surface_override_material(i):
				_swap(mi.get_surface_override_material(i))
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				if mi.mesh.surface_get_material(i):
					_swap(mi.mesh.surface_get_material(i))


static func _swap(m: Material) -> void:
	var sm := m as ShaderMaterial
	if sm == null or sm.shader == null:
		return
	var current := sm.shader
	var original: Shader = _originals.get(current, current)
	var path := original.resource_path
	if not path in [GRID, HOLES, SKIN, SKIN_DOUBLE, GROUND]:
		return
	if _look == "base" or _look == "blocks":
		sm.shader = original
		return
	sm.shader = _variant(original)
	var cls := "skin" if path in [SKIN, SKIN_DOUBLE] else ("ground" if path == GROUND else "grid")
	var spec: Dictionary = (SPEC_V1 if _look in ["paint_v1", "paint_flat"] else SPEC).duplicate()
	spec.merge(CLASSES[cls], true)
	if _look == "paint_flat":
		# The control: one share at every light level, which is what desaturating every light's
		# colour (an existing control) does.
		spec.pl_tint_lit = spec.pl_tint
	elif _look == "paint_id":
		spec.pl_tint = 1.0
		spec.pl_tint_lit = 1.0
	for k: String in spec:
		sm.set_shader_parameter(k, spec[k])


static func _variant(original: Shader) -> Shader:
	if _variants.has(original.resource_path):
		return _variants[original.resource_path]
	var code := original.code
	if code.contains(SKIN_INC):
		code = code.replace('#include "%s"' % SKIN_INC, FileAccess.get_file_as_string(SKIN_INC))
	var at := code.find("void light()")
	if at < 0:
		code += RULE + GRID_LIGHT
	else:
		var open := code.find("{", at)
		var depth := 0
		var close := open
		for i in range(open, code.length()):
			if code[i] == "{":
				depth += 1
			elif code[i] == "}":
				depth -= 1
				if depth == 0:
					close = i
					break
		var body := code.substr(open + 1, close - open - 1).replace("LIGHT_COLOR", "PL_LC")
		body = "\n\tvec3 PL_LC = pl_color(LIGHT_COLOR, clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION);" + body
		code = code.substr(0, at) + RULE + "void light() {" + body + "}" + code.substr(close + 1)
	var s := Shader.new()
	s.code = code
	_variants[original.resource_path] = s
	_originals[s] = original
	return s


## The paint probe on or off: every light out, an even white ambient of 1, no grade, fog, glow or
## occlusion, so each pixel is its surface's own colour as it goes into the lighting (the albedo),
## for the light's share of each lit pixel (analyse.py light).
static func probe(root: Node, env: Environment, on: bool) -> void:
	if on:
		_saved = {"env": env.duplicate(), "lights": {}}
		for l: Light3D in root.find_children("*", "Light3D", true, false):
			_saved.lights[l] = l.visible
			l.visible = false
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0, 0, 0)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(1, 1, 1)
		env.ambient_light_energy = 1.0
		env.ambient_light_sky_contribution = 0.0
		env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		env.tonemap_exposure = 1.0
		env.adjustment_enabled = false
		env.glow_enabled = false
		env.fog_enabled = false
		env.volumetric_fog_enabled = false
		env.ssao_enabled = false
		env.ssil_enabled = false
	else:
		var e: Environment = _saved.env
		for p in ["background_mode", "background_color", "ambient_light_source", "ambient_light_color",
				"ambient_light_energy", "ambient_light_sky_contribution", "reflected_light_source",
				"tonemap_mode", "tonemap_exposure", "adjustment_enabled", "glow_enabled", "fog_enabled",
				"volumetric_fog_enabled", "ssao_enabled", "ssil_enabled"]:
			env.set(p, e.get(p))
		for l: Light3D in _saved.lights:
			l.visible = _saved.lights[l]
