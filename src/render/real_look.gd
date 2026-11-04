class_name RealLook
extends Node
## The real look (docs/briefs/red-dead.md R0, Sean 2026-11-04: realistic, in Red Dead's
## direction): the game drawn as a realistic renderer draws it, behind a switch
## (`Settings.real_look`: the look panel N, `--real` for a run, `--look=config/looks/real.json`,
## the screenshots' `--variants=config/looks/real.json`). The painted look stays the default and
## is untouched: this node changes what's drawn while the switch is on and puts it back when it
## goes off, with no reload, so one run can render both.
##
## On, it:
## - recompiles the world's shaders (SHADERS) with REAL_LOOK defined (src/render/real_look.gdshaderinc):
##   their textures filtered, mipmapped and anisotropic, no texel squares, no light per texel, the
##   members' seams as soft grooves with rounded edges, relief from the textures (until R2's maps),
##   people lit by the engine's own light rather than painted;
## - turns the texel grid's globals off (Settings.tile_globals: squares, ragged, mosaic, seams);
## - anti-aliases the game viewport (TAA, MSAA 2x, 16x anisotropic; `view.*` dials) and draws it to
##   the window filtered when it isn't native;
## - sets the environment's realistic dials (config/looks/real_dials.json: AgX, SSIL, SDFGI,
##   volumetric fog) through LookPreset, every one put back when it goes off;
## - exposure by a camera-attributes multiplier (DayCycle keeps setting the tonemap's own);
## - SDFGI outdoors only: a ray up from the camera four times a second, its energy eased to
##   `sdfgi_indoor` under a roof (the saloon's indoor light is RoomLight's) and `sdfgi_outdoor` out;
## - StandardMaterial3Ds' and decals' nearest filtering made linear (and back), including what's
##   added while it's on.

const SHADERS := [
	"res://src/render/texel_grid.gdshader", "res://src/render/texel_grid_blocks.gdshader",
	"res://src/structures/member_holes.gdshader", "res://src/structures/member_holes_blocks.gdshader",
	"res://src/world/ground.gdshader",
	"res://src/bodies/shaders/body_skin.gdshader", "res://src/bodies/shaders/body_skin_double.gdshader",
	"res://src/bodies/shaders/body_inside.gdshader", "res://src/bodies/shaders/body_organ.gdshader",
]
const DIALS_PATH := "res://config/looks/real_dials.json"
const DEFINE := "#define REAL_LOOK"
const ROOF_CHECK := 0.25
const ROOF_REACH := 30.0

## The real look's own dials (look addresses `real.<dial>`): exposure (a multiplier on DayCycle's),
## relief / groove / specular (the shaders' globals, real_look.gdshaderinc), SDFGI's energy
## outdoors and under a roof.
static var dials := {
	"exposure": 1.6, "relief": 0.004, "groove": 0.003, "specular": 0.35,
	"sdfgi_outdoor": 1.0, "sdfgi_indoor": 0.0,
}
## Whether the world's shaders are compiled for the real look now.
static var shaders_real := false
static var _original_code := {}

var _applied := false
## What each address real_dials.json sets read before it set them (put back when it goes off).
var _before := {}
var _view_before := {}
var _attributes: CameraAttributesPractical
var _env_attributes_before: CameraAttributes
var _since_roof := 1.0
var _under_roof := false
var _sdfgi := 1.0
var _pending: Array[Node] = []


func _ready() -> void:
	add_to_group(&"real_look")
	process_priority = 100  # after DayCycle and the light looks have set this frame's light
	# At once when the switch moves (a preset's later values, view.* say, then go over it).
	Settings.changed.connect(_sync)
	_sync.call_deferred()


func _exit_tree() -> void:
	if Settings.changed.is_connected(_sync):
		Settings.changed.disconnect(_sync)


func _sync() -> void:
	if is_inside_tree() and Settings.real_look != _applied:
		_set_applied(Settings.real_look)


func _process(delta: float) -> void:
	_sync()
	if not _applied:
		return
	if not _pending.is_empty():
		var batch := _pending.slice(0, 64)
		_pending = _pending.slice(64)
		for n in batch:
			if is_instance_valid(n):
				_filters(n, true)
	_ease_sdfgi(delta)


func _physics_process(delta: float) -> void:
	if not _applied:
		return
	_since_roof += delta
	if _since_roof < ROOF_CHECK:
		return
	_since_roof = 0.0
	var cam := _camera()
	var space := World.space(self)
	if cam == null or space == null:
		return
	var from := cam.global_position
	var q := PhysicsRayQueryParameters3D.create(from, from + Vector3.UP * ROOF_REACH, Layers.WORLD)
	_under_roof = not space.intersect_ray(q).is_empty()


## The game's 3D viewport (Main's GameViewport), or null.
func viewport() -> SubViewport:
	var p := get_parent()
	return p.get_node_or_null(^"GameViewport") as SubViewport if p else null


func _camera() -> Camera3D:
	var vp := viewport()
	return vp.get_camera_3d() if vp else get_viewport().get_camera_3d()


func _set_applied(on: bool) -> void:
	_applied = on
	swap_shaders(on)
	_globals(on)
	_view(on)
	_environment(on)
	RenderingServer.decals_set_filter(RenderingServer.DECAL_FILTER_LINEAR_MIPMAPS_ANISOTROPIC if on
			else int(ProjectSettings.get_setting("rendering/textures/decals/filter", 0)) as RenderingServer.DecalFilter)
	_filters(get_tree().root, on)
	var tree := get_tree()
	if on and not tree.node_added.is_connected(_added):
		tree.node_added.connect(_added)
	elif not on and tree.node_added.is_connected(_added):
		tree.node_added.disconnect(_added)
		_pending.clear()
	_sdfgi = -1.0  # snap to where the camera is, not ease from the last value
	print("[real look] %s" % ("on" if on else "off"))


## The world's shaders recompiled with REAL_LOOK defined (on) or as written (off). Every material
## using them follows: the same Shader resource, new code.
static func swap_shaders(on: bool) -> void:
	if on == shaders_real:
		return
	shaders_real = on
	for path: String in SHADERS:
		if not ResourceLoader.exists(path):
			continue
		var s := load(path) as Shader
		if not _original_code.has(path):
			_original_code[path] = s.code
		var code: String = _original_code[path]
		s.code = _with_define(code) if on else code


static func _with_define(code: String) -> String:
	var at := code.find("shader_type")
	if at < 0:
		return DEFINE + "\n" + code
	var eol := code.find("\n", at)
	return code.substr(0, eol + 1) + DEFINE + "\n" + code.substr(eol + 1)


func _globals(on: bool) -> void:
	Settings.apply_tile_globals()
	RenderingServer.global_shader_parameter_set(&"real_relief", float(dials.relief) if on else 0.0)
	RenderingServer.global_shader_parameter_set(&"real_groove", float(dials.groove))
	RenderingServer.global_shader_parameter_set(&"real_specular", float(dials.specular))


## The viewport's anti-aliasing and filtering (view.* dials), and the window's blow-up filtered.
const VIEW_REAL := {
	"msaa_3d": Viewport.MSAA_2X, "use_taa": true, "screen_space_aa": Viewport.SCREEN_SPACE_AA_DISABLED,
	"anisotropic_filtering_level": Viewport.ANISOTROPY_16X, "use_debanding": true,
	"scaling_3d_mode": Viewport.SCALING_3D_MODE_BILINEAR, "scaling_3d_scale": 1.0,
}


func _view(on: bool) -> void:
	var vp := viewport()
	if vp == null:
		return
	if on:
		for k: String in VIEW_REAL:
			if not _view_before.has(k):
				_view_before[k] = vp.get(k)
			vp.set(k, VIEW_REAL[k])
	else:
		for k: String in _view_before:
			vp.set(k, _view_before[k])
		_view_before.clear()
	var screen := get_parent().get_node_or_null(^"Screen") as TextureRect
	if screen:
		screen.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR if on else CanvasItem.TEXTURE_FILTER_NEAREST


func _environment(on: bool) -> void:
	var tree := get_tree()
	var preset := LookPreset.load_file(DIALS_PATH)
	var values: Dictionary = preset.get("values", {})
	if on:
		for a: String in values:
			if not _before.has(a):
				var v: Variant = LookPreset.get_value(tree, a)
				if v != null:
					_before[a] = v
		LookPreset.apply(tree, preset)
	else:
		for a: String in _before:
			LookPreset.set_value(tree, a, _before[a])
		_before.clear()
	var we := tree.root.find_child("WorldEnvironment", true, false) as WorldEnvironment
	if we == null:
		return
	if on:
		_env_attributes_before = we.camera_attributes
		_attributes = CameraAttributesPractical.new()
		_attributes.exposure_multiplier = float(dials.exposure)
		we.camera_attributes = _attributes
	elif _attributes != null:
		we.camera_attributes = _env_attributes_before
		_attributes = null


func _ease_sdfgi(delta: float) -> void:
	var env := LookPreset.environment(get_tree())
	if env == null or not env.sdfgi_enabled:
		return
	var want: float = dials.sdfgi_indoor if _under_roof else dials.sdfgi_outdoor
	_sdfgi = want if _sdfgi < 0.0 else move_toward(_sdfgi, want, delta * 2.0)
	if not is_equal_approx(env.sdfgi_energy, _sdfgi):
		env.sdfgi_energy = _sdfgi


## A look address `real.<dial>`: set and read (LookPreset).
static func set_dial(tree: SceneTree, key: String, v: Variant) -> bool:
	if not dials.has(key):
		return false
	dials[key] = float(v)
	var node := tree.get_first_node_in_group(&"real_look") as RealLook
	if node and node._applied:
		node._globals(true)
		if node._attributes:
			node._attributes.exposure_multiplier = float(dials.exposure)
	return true


static func get_dial(key: String) -> Variant:
	return dials.get(key)


## A look address `view.<prop>`: the game viewport's own properties (msaa_3d, use_taa,
## scaling_3d_mode, scaling_3d_scale, fsr_sharpness...).
static func view(tree: SceneTree) -> Viewport:
	var node := tree.get_first_node_in_group(&"real_look") as RealLook
	var vp: Viewport = node.viewport() if node else null
	if vp == null:
		# No main scene (the street on its own, the tests): the viewport the street draws in.
		var we := tree.root.find_child("WorldEnvironment", true, false)
		vp = we.get_viewport() if we else null
	return vp


## Nearest filtering on every StandardMaterial3D under `root` made its linear, anisotropic
## equivalent (on) or put back (off). The originals are kept on each material.
func _filters(root: Node, on: bool) -> void:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is GeometryInstance3D:
			_fix_instance(n as GeometryInstance3D, on)


func _fix_instance(gi: GeometryInstance3D, on: bool) -> void:
	_fix_material(gi.material_override, on)
	if gi is MeshInstance3D:
		var mi := gi as MeshInstance3D
		for i in mi.get_surface_override_material_count():
			_fix_material(mi.get_surface_override_material(i), on)
		if mi.mesh:
			for i in mi.mesh.get_surface_count():
				_fix_material(mi.mesh.surface_get_material(i), on)
	elif gi is SpriteBase3D:
		var sp := gi as SpriteBase3D
		var nearest := sp.texture_filter in [BaseMaterial3D.TEXTURE_FILTER_NEAREST, BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS,
				BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC]
		if on and nearest and not sp.has_meta(&"real_filter_before"):
			sp.set_meta(&"real_filter_before", sp.texture_filter)
			sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		elif not on and sp.has_meta(&"real_filter_before"):
			sp.texture_filter = sp.get_meta(&"real_filter_before")
			sp.remove_meta(&"real_filter_before")


static func _fix_material(m: Material, on: bool) -> void:
	var b := m as BaseMaterial3D
	if b == null:
		return
	var f := b.texture_filter
	if on:
		var nearest := f == BaseMaterial3D.TEXTURE_FILTER_NEAREST or f == BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS \
				or f == BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
		if nearest and not b.has_meta(&"real_filter_before"):
			b.set_meta(&"real_filter_before", f)
			b.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	elif b.has_meta(&"real_filter_before"):
		b.texture_filter = b.get_meta(&"real_filter_before")
		b.remove_meta(&"real_filter_before")
	if b.next_pass:
		_fix_material(b.next_pass, on)


func _added(n: Node) -> void:
	if n is GeometryInstance3D:
		_pending.append(n)
