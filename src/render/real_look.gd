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
## - anti-aliases the game viewport (FSR2 at native scale: sharper than Godot's TAA, which left the
##   frame soft in R0's renders; 16x anisotropic; `view.*` dials) and draws it to the window filtered
##   when it isn't native;
## - sets the environment's realistic dials (config/looks/real_dials.json: AgX, SSIL, SDFGI,
##   volumetric fog) through LookPreset, every one put back when it goes off;
## - exposure by a camera-attributes multiplier (DayCycle keeps setting the tonemap's own);
## - SDFGI outdoors only: a ray up from the camera four times a second, its energy eased to
##   `sdfgi_indoor` under a roof (the saloon's indoor light is RoomLight's) and `sdfgi_outdoor` out;
## - StandardMaterial3Ds' and decals' nearest filtering made linear (and back), including what's
##   added while it's on;
## - every building's interior probe (`interior_ambient`) taken again when the room's light changes
##   (RoomReflections.state: lamps lit or out, the sun up or down) and when it comes on: taken once
##   at the build (noon), its reflections put a grey-blue daylight sheen on the floor and bar at
##   night under the real look's specular (R1);
## - the lamps hung over a room (OilLamp meta `lamp_group` "hung") lit as a shaded lamp is (R1):
##   their tin shade casts a shadow and the lamp casts shadows, so the shade darkens the ceiling
##   over it and the light falls in a pool on the floor, the chairs and tables shadowed in it;
##   their energy and reach multiplied by `hung_energy` and `hung_reach` (each frame, after
##   OilLamp's flicker has set it: the flicker read back from the light).

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
	"exposure": 1.4, "relief": 0.004, "groove": 0.003, "specular": 0.35,
	"sdfgi_outdoor": 1.0, "sdfgi_indoor": 0.0, "hung_energy": 1.0, "hung_reach": 1.0,
}
## The hung lamps' meshes that cast a shadow under the real look (the tin shade over the flame).
const HUNG_CASTERS := [&"Shade", &"ShadeUnder"]
## A hung lamp's shadow only with the camera this near (from the street a room's lamps' shadows were
## most of the frame's draws: OilLamp's own far rule).
const HUNG_SHADOW_REACH := 14.0
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
var _room_state := -1
## The hung lamps made shaded: lamp -> the light energy this last wrote.
var _hung := {}


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
	_retake_probes()
	_hung_lamps()


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
	_room_state = -1  # the interior probes taken again in the light they're in now
	if not on:
		_unshade_hung()
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
## FSR2 at scale 1 is its temporal anti-aliasing alone (no upscale); a lower `view.scaling_3d_scale`
## makes it upscale. It takes the place of TAA and MSAA (R0's renders: TAA + MSAA 2x read soft).
const VIEW_REAL := {
	"msaa_3d": Viewport.MSAA_DISABLED, "use_taa": false, "screen_space_aa": Viewport.SCREEN_SPACE_AA_DISABLED,
	"anisotropic_filtering_level": Viewport.ANISOTROPY_16X, "use_debanding": true,
	"scaling_3d_mode": Viewport.SCALING_3D_MODE_FSR2, "scaling_3d_scale": 1.0, "fsr_sharpness": 0.2,
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


## The interior probes taken again when the room's light changes (and when the look comes on).
func _retake_probes() -> void:
	var clock := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	if clock == null:
		return
	var s := RoomReflections.state(clock.get_hour())
	if s == _room_state:
		return
	_room_state = s
	for p in get_tree().get_nodes_in_group(&"interior_ambient"):
		if p is ReflectionProbe:
			_retake(p as ReflectionProbe)


## UPDATE_ONCE takes a probe again when it changes: always for two frames and back, a frame after
## the lamps' own hour_changed has lit them (as RoomReflections.retake).
func _retake(p: ReflectionProbe) -> void:
	await get_tree().process_frame
	if not is_instance_valid(p) or not p.is_inside_tree():
		return
	p.update_mode = ReflectionProbe.UPDATE_ALWAYS
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(p) and p.is_inside_tree():
		p.update_mode = ReflectionProbe.UPDATE_ONCE


## The hung lamps shaded (shadows from their tin shade) and their light multiplied, every frame
## after OilLamp's flicker. New lamps are found in the `oil_lamps` group.
func _hung_lamps() -> void:
	var cam := _camera()
	for n in get_tree().get_nodes_in_group(&"oil_lamps"):
		var lamp := n as OilLamp
		if lamp == null or lamp.get_meta(&"lamp_group", &"") != &"hung" or lamp._light == null:
			continue
		var light := lamp._light
		if not _hung.has(lamp):
			_hung[lamp] = -1.0
			light.set_meta(&"real_shadow_before", light.shadow_enabled)
			var root := lamp.get_parent()
			for c: StringName in HUNG_CASTERS:
				var mi := root.get_node_or_null(NodePath(String(c))) as MeshInstance3D if root else null
				if mi:
					mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var near := cam != null and cam.global_position.distance_to(light.global_position) < HUNG_SHADOW_REACH
		if light.shadow_enabled != near:
			light.shadow_enabled = near
		light.omni_range = lamp.light_range * float(dials.hung_reach)
		# OilLamp sets energy x flicker (not every frame under the render thread): what it set is
		# read back only when it isn't what this wrote last.
		var e := light.light_energy
		if e != float(_hung[lamp]) and lamp.energy > 0.0:
			var w := e * float(dials.hung_energy)
			light.light_energy = w
			_hung[lamp] = w
	for lamp: Variant in _hung.keys():
		if not is_instance_valid(lamp):
			_hung.erase(lamp)


func _unshade_hung() -> void:
	for lamp: Variant in _hung.keys():
		if not is_instance_valid(lamp):
			continue
		var l := lamp as OilLamp
		var light := l._light
		if light:
			light.shadow_enabled = bool(light.get_meta(&"real_shadow_before", false))
			light.omni_range = l.light_range
			light.light_energy = l.energy
		var root := l.get_parent()
		for c: StringName in HUNG_CASTERS:
			var mi := root.get_node_or_null(NodePath(String(c))) as MeshInstance3D if root else null
			if mi:
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hung.clear()


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
