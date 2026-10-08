## The seated man's diagnostic passes (the characters session's crispness experiments,
## docs/screenshots/tripo/experiments/): tools/screenshots.gd --man-diag=lit,id,wire,fix,litfix
## [--man-normals=DIR] renders them after a shot-match view, from the view's own camera.
##
## Each pass draws the man with a copy of his own shader patched here at run time (the art
## session's body_skin.gdshaderinc is read, never written):
##   lit     his albedo a flat grey, the scene's light as it is: what the light alone does to him
##   id      each square of his texture a colour of its own (the square's index hashed), unlit, the
##           rest of the frame black: where his squares' edges fall on the screen
##   wire    his triangles' edges (the viewport's wireframe), the rest of the frame black
##   fix     as the game draws him, but each square lit by one normal: the square's own (its
##           texels' mean, in his rest pose) carried into his pose by the turn between the texel's
##           rest normal and the normal he has there now (--man-normals=DIR: <tex>_nsq.png and
##           <tex>_ntx.png beside each texture's name, written by fit_tripo.py CELLS `normals`)
##   fix_nmsq  the same with his model's normal map, its mean over each square (CELLS `normal_map`:
##           <tex>_nmsq.png): the map's form at the square's size, no finer
##   fix_nmtx  his model's normal map texel by texel (<tex>_nmtx.png): its full detail
##   litfix, litfix_nmsq, litfix_nmtx  lit and the matching fix together
##   fixp, litfixp, fixp_nmsq, ...  the same, the light's point (shadows, a lamp's fall-off) also
##           the square's middle for every pixel of it (<tex>_dsq.png): the square lit as one
## The game itself draws him with body_skin as it was.
extends RefCounted

const INC := "res://src/bodies/shaders/body_skin.gdshaderinc"

const UNIFORMS := """
uniform int diag_mode = 0;
uniform bool diag_fix = false;
uniform sampler2D diag_nsq : filter_nearest, repeat_disable;
uniform sampler2D diag_ntx : filter_nearest, repeat_disable;
uniform float diag_grey = 0.35;
uniform bool diag_pos = false;
uniform bool diag_rest = false;
varying vec3 diag_rest_n;
uniform vec3 diag_shift = vec3(0.0);
uniform sampler2D diag_dsq : filter_nearest, repeat_disable;
"""

## After tile_light_at: one normal a square.
const FIX := """
	if (diag_fix && use_uv) {
		vec3 nsq = textureLod(diag_nsq, tuv, 0.0).rgb * 2.0 - 1.0;
		vec3 ntx = textureLod(diag_ntx, tuv, 0.0).rgb * 2.0 - 1.0;
		// His rest normal here: the mesh's own (CUSTOM1, put in by man_diag.swap), so the turn into
		// his pose is the bones' turn, the same all over a square; else the texel's from the bake.
		vec3 a = diag_rest ? normalize(diag_rest_n) : normalize(ntx);
		vec3 b = normalize(local_normal);
		vec3 v = cross(a, b);
		float c = dot(a, b);
		vec3 x = normalize(nsq);
		vec3 r = c > -0.95 ? x * c + cross(v, x) + v * dot(v, x) / (1.0 + c) : b;
		NORMAL = normalize((VIEW_MATRIX * MODEL_MATRIX * vec4(r, 0.0)).xyz);
		if (diag_pos) {
			// The light's point: the square's middle (fit_tripo.py DSQ_RANGE 0.02 m), the offset turned as
			// the normal is.
			vec3 dl = (textureLod(diag_dsq, tuv, 0.0).rgb * 2.0 - 1.0) * 0.02;
			vec3 dr = c > -0.95 ? dl * c + cross(v, dl) + v * dot(v, dl) / (1.0 + c) : dl;
			LIGHT_VERTEX = VERTEX + (VIEW_MATRIX * MODEL_MATRIX * vec4(dr, 0.0)).xyz;
		}
	}
"""

const GREY := "\tif (diag_mode == 1) { base = vec3(diag_grey); LIGHT_VERTEX += diag_shift; }\n"

## At the end of the fragment: the square's index, hashed to a colour.
const ID := """
	if (diag_mode == 3) {
		ALBEDO = vec3(0.0);
		SPECULAR = 0.0;
		EMISSION = vec3(1.0);
	}
	if (diag_mode == 2) {
		vec2 q = floor(t);
		vec3 h = fract(sin(vec3(dot(q, vec2(12.9898, 78.233)), dot(q, vec2(39.3468, 11.135)),
				dot(q, vec2(73.156, 52.235))) + float(tsize.x) * 0.0131) * 43758.5453);
		ALBEDO = vec3(0.0);
		SPECULAR = 0.0;
		AO = 1.0;
		EMISSION = 0.1 + h * 0.8;
	}
"""

static var _cache := {}


## His shader with the passes in (one per original shader: body_skin and body_skin_double).
static func patched(orig: Shader) -> Shader:
	if _cache.has(orig):
		return _cache[orig]
	var inc := FileAccess.get_file_as_string(INC)
	var edits := [
		["uniform vec3 shade_tint : source_color = vec3(1.0);\n", UNIFORMS],
		["tile_light_at(t, centre, VERTEX, NORMAL, LIGHT_VERTEX, NORMAL, 0.05);\n", FIX],
		["\tbase *= tint.rgb;\n", GREY],
		["\tlocal_normal = NORMAL;\n", "\tdiag_rest_n = CUSTOM1.xyz;\n"],
	]
	for e: Array in edits:
		assert(inc.contains(e[0]), "man_diag: body_skin.gdshaderinc has changed: " + e[0])
		inc = inc.replace(e[0], e[0] + e[1])
	var end := "\t}\n}\n\nvoid light() {"
	assert(inc.contains(end), "man_diag: body_skin.gdshaderinc's fragment end has changed")
	inc = inc.replace(end, "\t}\n" + ID + "}\n\nvoid light() {")
	var s := Shader.new()
	s.code = orig.code.replace('#include "%s"' % INC, inc)
	_cache[orig] = s
	return s


## Every body_skin material on the man (HumanBody draws him through material_override) swapped
## for the patched copy: {MeshInstance3D: its override} to put back with restore().
static func swap(man: Node3D, normals_dir: String) -> Dictionary:
	var was := {}
	for mi: MeshInstance3D in man.find_children("*", "MeshInstance3D", true, false):
		var m := mi.material_override as ShaderMaterial
		if m == null or m.shader == null or not m.shader.resource_path.begins_with("res://src/bodies/shaders/body_skin"):
			continue
		var d := m.duplicate() as ShaderMaterial
		d.shader = patched(m.shader)
		var tex := m.get_shader_parameter(&"albedo_tex") as Texture2D
		# Which normals light a square, by the pass's name (fix, fix_nmsq, fix_nmtx): nsq, its
		# geometry's mean; nmsq, with his model's normal map, its mean over the square; nmtx, the map
		# texel by texel. Each beside its texture: <tex>_<kind>.png, with <tex>_ntx.png.
		if tex != null and normals_dir != "":
			var stem := normals_dir.path_join(tex.resource_path.get_file().get_basename())
			if FileAccess.file_exists(stem + "_ntx.png"):
				d.set_shader_parameter(&"diag_ntx", ImageTexture.create_from_image(Image.load_from_file(stem + "_ntx.png")))
				var kinds := {}
				for kind in ["nsq", "nmsq", "nmtx"]:
					if FileAccess.file_exists(stem + "_%s.png" % kind):
						kinds[kind] = ImageTexture.create_from_image(Image.load_from_file(stem + "_%s.png" % kind))
				d.set_meta(&"normals", kinds)
				if FileAccess.file_exists(stem + "_dsq.png"):
					d.set_shader_parameter(&"diag_dsq", ImageTexture.create_from_image(Image.load_from_file(stem + "_dsq.png")))
		was[mi] = [m, mi.mesh]
		if mi.mesh is ArrayMesh:
			mi.mesh = with_rest_normals(mi.mesh)
			d.set_shader_parameter(&"diag_rest", true)
		mi.material_override = d
	return was


static func set_pass(was: Dictionary, mode: int, kind: String, pos := false) -> void:
	for mi: MeshInstance3D in was:
		var d := mi.material_override as ShaderMaterial
		var kinds: Dictionary = d.get_meta(&"normals", {})
		var fix := kind != "" and kinds.has(kind)
		if kind != "" and not fix and mi.visible:
			push_warning("man_diag: no %s normals for %s" % [kind, mi.get_path()])
		if fix:
			d.set_shader_parameter(&"diag_nsq", kinds[kind])
		d.set_shader_parameter(&"diag_mode", mode)
		d.set_shader_parameter(&"diag_fix", fix)
		d.set_shader_parameter(&"diag_pos", fix and pos)


static func restore(was: Dictionary) -> void:
	for mi: MeshInstance3D in was:
		if is_instance_valid(mi):
			mi.material_override = was[mi][0]
			mi.mesh = was[mi][1]


## A copy of `mesh` with each vertex's own (rest, unskinned) normal in CUSTOM1, so the fix can
## turn a square's rest normal by exactly the bones' turn (skinning turns NORMAL, not CUSTOM1).
static func with_rest_normals(mesh: Mesh) -> ArrayMesh:
	var out := ArrayMesh.new()
	for i in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(i)
		var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var c := PackedFloat32Array()
		c.resize(n.size() * 4)
		for j in n.size():
			c[j * 4] = n[j].x
			c[j * 4 + 1] = n[j].y
			c[j * 4 + 2] = n[j].z
			c[j * 4 + 3] = 0.0
		arrays[Mesh.ARRAY_CUSTOM1] = c
		var fmt: int = mesh.surface_get_format(i)
		var flags: int = Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT
		flags |= fmt & (Mesh.ARRAY_FORMAT_CUSTOM_MASK << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
		flags |= fmt & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
		out.surface_set_material(i, mesh.surface_get_material(i))
	return out


## The passes asked for, each saved as <stem>_diag_<pass>.png.
static func render(tree: SceneTree, viewport: SubViewport, cam: Camera3D, passes: PackedStringArray,
		normals_dir: String, stem: String, zoom := 1.0, target := &"head") -> void:
	var man := viewport.find_child("SeatedMan", true, false) as Node3D
	if man == null:
		push_warning("man_diag: no SeatedMan")
		return
	var was := swap(man, normals_dir)
	# Every lamp held at its own steady energy while the passes are drawn: their flicker (±7 %,
	# oil_lamp.gd) changed the light between passes and made the passes disagree with themselves.
	var lamps := []
	for n: Node in viewport.find_children("*", "Node3D", true, false):
		var sc := n.get_script() as Script
		if sc != null and sc.resource_path.ends_with("oil_lamp.gd") and n.get(&"_light") != null:
			n.set_process(false)
			(n.get(&"_light") as Light3D).light_energy = n.get(&"energy")
			lamps.append(n)
	# He's held still too: his idle (breathing, the pose easing) moved him between passes, so the
	# square-id pass no longer lined up with the light passes and square edges read as splits.
	var man_mode := man.process_mode
	man.process_mode = Node.PROCESS_MODE_DISABLED
	# --man-zoom=N[:part]: the passes from the view's camera turned onto one of his parts and its
	# lens narrowed N times, so his triangles and squares are big enough to tell apart.
	var cam_was := [cam.global_transform, cam.fov]
	if zoom > 1.0:
		var parts: Dictionary = man.get(&"parts")
		var part := parts.get(target) as Node3D
		if part != null:
			cam.look_at(part.global_position, Vector3.UP)
			cam.fov = cam_was[1] / zoom
			stem += "_zoom_%s" % target
	for i in 4:
		await tree.process_frame
	for name in passes:
		var p := name
		var black := p == "id" or p == "wire"
		var hidden := {}
		var env_was := cam.environment
		if black:
			for gi: GeometryInstance3D in viewport.find_children("*", "GeometryInstance3D", true, false):
				if not man.is_ancestor_of(gi) or String(gi.get_path()).contains("HeldCup"):
					hidden[gi] = gi.visible
					gi.visible = false
			var env := Environment.new()
			env.background_mode = Environment.BG_COLOR
			env.background_color = Color.BLACK
			env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
			cam.environment = env
		if p == "wire":
			viewport.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
		# lit, id, wire; fix / litfix (by each square's geometry), fix_nmsq / litfix_nmsq,
		# fix_nmtx / litfix_nmtx (by his model's normal map).
		var kind := ""
		# A "p" after fix (fixp, litfixp_nmsq) also takes the light's point to the square's middle.
		var pos := p.begins_with("fixp") or p.begins_with("litfixp")
		# "ns" in a pass's name (litns, litfixpns): every light's shadows off for it. "litshift":
		# the light's point moved 5 cm up (view space): do shadows follow LIGHT_VERTEX at all?
		var no_shadow := p.ends_with("ns")
		var shadows := {}
		if no_shadow:
			for l: Light3D in viewport.find_children("*", "Light3D", true, false):
				shadows[l] = l.shadow_enabled
				l.shadow_enabled = false
		for mi: MeshInstance3D in was:
			(mi.material_override as ShaderMaterial).set_shader_parameter(&"diag_shift",
					Vector3(0.0, 0.05, 0.0) if p == "litshift" else Vector3.ZERO)
		if no_shadow:
			p = p.trim_suffix("ns")
		# A trailing "2" (lit2) renders the same pass again: how much a pass differs run to run.
		p = p.trim_suffix("2")
		if p.begins_with("fix") or p.begins_with("litfix"):
			kind = p.get_slice("_", 1) if p.contains("_") else "nsq"
		var mode := 1 if p.begins_with("lit") else (2 if p == "id" else (3 if p == "wire" else 0))
		set_pass(was, mode, kind, pos)
		# As many frames as the view itself waits (screenshots.gd: 40), so the fog's and the
		# exposure's history from the pass before has gone (6 left the passes noisy run to run).
		for i in 40:
			await tree.process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("%s_diag_%s.png" % [stem, name])
		print("saved ", "%s_diag_%s.png" % [stem.get_file(), name])
		viewport.debug_draw = Viewport.DEBUG_DRAW_DISABLED
		for l: Light3D in shadows:
			l.shadow_enabled = shadows[l]
		cam.environment = env_was
		for gi: GeometryInstance3D in hidden:
			if is_instance_valid(gi):
				gi.visible = hidden[gi]
	restore(was)
	cam.global_transform = cam_was[0]
	cam.fov = cam_was[1]
	man.process_mode = man_mode
	for n: Node in lamps:
		if is_instance_valid(n):
			n.set_process(true)
