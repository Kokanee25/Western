class_name OilLamp
extends Node3D
## A kerosene lamp: warm light with a lazy flicker, lit in the evening and put out in the morning.
## Its model is PropModels.lamp().

@export var lit_from_hour := 18
@export var lit_until_hour := 7
@export var energy := 1.4
@export var light_range := 7.0
@export var hanging := false
## Off when a modelled lamp prop provides the look and this node only provides the light.
@export var show_mesh := true
## How much its light shows in the air (smoke, haze): the halo round a lamp in a smoky room.
@export var haze := 1.2
## Render layers this lamp's light leaves alone (the art session's staged shots: the saloon shot's
## lamps leave the seated man's head to its side key, ShotMatch.FACE_LAYER).
var cull_out := 0:
	set(value):
		cull_out = value
		if _light:
			_light.light_cull_mask &= ~value
## Shadows from its light (a lamp on a table, a porch lantern). Off for small wall lanterns: their
## own cap and frame cut hard wedges out of the light on the wall.
@export var casts_shadows := true
## Past this far from the camera (or with the camera outside the building it's in) its shadow
## is cast only by the buildings' shadow meshes (Layers.VIS_WALLS: one a building, where its
## batches are ~45), not by people, props and the bottles on the shelves, and in two passes, not six: a shadowed lamp draws everything in its
## reach six times a frame (a cube of shadow faces), and Godot 4.7 redraws it every frame, so the
## saloon's 14 seen from the street were 11,600 of the frame's 15,400 draw calls. The shadow
## stays on, so the walls still keep its light in (switched off it shone through them). 0 =
## always the full shadow.
@export var shadow_reach := 20.0
## Checked this often (seconds), with a metre's slack so a lamp at the edge doesn't flick.
const SHADOW_CHECK := 0.25
const SHADOW_SLACK := 1.0
## How far outside its building's walls a camera still gets an indoor lamp's full shadow.
## Indoors, how near a lamp in another building must be to shade fully (_indoors).
const NEIGHBOUR_REACH := 12.0
const LIGHTS_ALL := 0xFFFFF
## Walls-only lamps nearer than this keep six shadow passes: in two, a lamp's light leaks out
## through the seams between a wall's boards (the saloon's front from the street).
const CUBE_REACH := 40.0
static var _indoors_frame := -1
static var _indoors_now := false
const ROOM_MARGIN := 2.5
## What casts a far lamp's shadow.
const FAR_CASTERS := Layers.VIS_WALLS
const ALL_CASTERS := Layers.ALL_BUT_WALLS
@export var attenuation := 1.2:
	set(value):
		attenuation = value
		if _light:
			_light.omni_attenuation = value

var lit := true
## Shot or knocked to pieces: no light, and if it was lit, burning oil where it landed.
var broken := false

var _light: OmniLight3D
var _shadow_check := 0.0
var _building: Node
var _flame: MeshInstance3D
var _chimney: MeshInstance3D
var _flame_material: StandardMaterial3D
var _time := 0.0
## With the render thread (Settings.render_thread) every write to the light wakes that thread
## and waits on its queue's lock: the flicker, a write a lamp a frame, was 0.2 -> 1.0 ms a frame
## in the lab's saloon fight. Then each lamp writes it every third frame (lamps staggered); the
## flicker is a few hertz, so 20 writes a second draw the same. Without the thread, every frame.
const THREAD_FLICKER_FRAMES := 3


func _ready() -> void:
	_build()
	add_to_group(&"oil_lamps")  # SightLight: the light people are seen by
	Events.hour_changed.connect(_on_hour_changed)
	var clock := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	set_lit(true if clock == null else should_be_lit(clock.get_hour()))


func should_be_lit(hour: int) -> bool:
	if lit_from_hour > lit_until_hour:
		return hour >= lit_from_hour or hour < lit_until_hour
	return hour >= lit_from_hour and hour < lit_until_hour


func set_lit(on: bool) -> void:
	lit = on
	_light.visible = on
	if _chimney:
		_chimney.set_instance_shader_parameter(&"glow", 1.0 if on else 0.0)
	_flame_material.emission_enabled = on
	_flame_material.albedo_color = Color(1.0, 0.75, 0.4, 0.8) if on else Color(0.5, 0.55, 0.55, 0.4)


## Giving light (lit and in one piece).
func shines() -> bool:
	return lit and not broken and is_inside_tree()


## Where its light comes from, in the world.
func light_position() -> Vector3:
	return _light.global_position


## Its own hitbox, which a line from its flame starts inside (none once smashed).
func hitbox_rid() -> RID:
	var hitbox := get_node_or_null(^"Hitbox") as StaticBody3D
	return hitbox.get_rid() if hitbox and not hitbox.is_queued_for_deletion() else RID()


func _process(delta: float) -> void:
	var t := Prof.start()
	_process_step(delta)
	Prof.stop(&"lamps", t)


func _process_step(delta: float) -> void:
	if not lit:
		return
	if casts_shadows and shadow_reach > 0.0:
		_shadow_check -= delta
		if _shadow_check <= 0.0:
			_shadow_check = SHADOW_CHECK
			_shadow_for_distance()
	_time += delta
	if Settings.render_thread and (Engine.get_process_frames() + get_instance_id()) % THREAD_FLICKER_FRAMES != 0:
		return
	var flicker := 1.0 + sin(_time * 7.3) * 0.04 + sin(_time * 13.1 + 1.7) * 0.03
	_light.light_energy = energy * flicker


func _shadow_for_distance() -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	var at := cam.global_position
	var near_now := _light.shadow_caster_mask != FAR_CASTERS
	var slack := SHADOW_SLACK if near_now else 0.0
	var d := at.distance_to(_light.global_position)
	var near := d < shadow_reach + slack and (_sees_in(at, slack) or (d < NEIGHBOUR_REACH + slack and _indoors(at)))
	if near != near_now:
		_light.shadow_caster_mask = ALL_CASTERS if near else FAR_CASTERS
		# A room's lamps light the people in it only while you're in it or at its door: everyone a
		# light reaches is in its shadow work every frame they move, and from the street the men
		# inside are a glimpse through the door, lit by the room's fill (2-3 ms of the street's
		# render with the saloon's barkeep and drinkers in it).
		var indoor := _room() is FalseFrontBuilding
		_light.light_cull_mask = (LIGHTS_ALL if near or not indoor else LIGHTS_ALL & ~Layers.VIS_BODY) & ~cull_out
	# Far off, two shadow passes (a dual paraboloid) for six (a cube): each pass costs the render
	# thread ~50 us however little is in it, and from that far the seams' leaks don't show.
	var cube_now := _light.omni_shadow_mode == OmniLight3D.SHADOW_CUBE
	var cube := d < CUBE_REACH + (SHADOW_SLACK if cube_now else 0.0)
	if cube != cube_now:
		_light.omni_shadow_mode = OmniLight3D.SHADOW_CUBE if cube else OmniLight3D.SHADOW_DUAL_PARABOLOID


## A lamp in a building only shades fully for a camera in it, on its porch or at its door: from
## the street its shadows are behind the walls. A lamp hung outside them is the street's.
func _sees_in(at: Vector3, slack: float) -> bool:
	if not _room() is FalseFrontBuilding:
		return true
	var b := _building as FalseFrontBuilding
	var local := b.global_transform.affine_inverse() * at
	var m := ROOM_MARGIN + slack
	return local.x > -m and local.x < b.width + m and local.z > -m and local.z < b.depth + m


## The building whose room this lamp lights, or itself: none, or hung outside its walls (a porch
## lantern lights the street, not a room). Found once.
func _room() -> Node:
	if _building == null:
		var p := get_parent()
		while p and not p is FalseFrontBuilding:
			p = p.get_parent()
		_building = p if p else self
		if p:
			var own := (p as FalseFrontBuilding).global_transform.affine_inverse() * global_position
			if own.x < 0.0 or own.x > p.width or own.z < 0.0 or own.z > p.depth:
				_building = self
	return _building


## Is the camera inside any building's walls? Indoors, a lamp next door shows through the gaps
## between the boards, so it shades fully within NEIGHBOUR_REACH. Worked out once a frame.
static func _indoors(at: Vector3) -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var frame := Engine.get_physics_frames()
	if frame == _indoors_frame:
		return _indoors_now
	_indoors_frame = frame
	_indoors_now = false
	for s in tree.get_nodes_in_group(&"structures"):
		if not s is FalseFrontBuilding:
			continue
		var b := s as FalseFrontBuilding
		var local := b.global_transform.affine_inverse() * at
		if local.x > 0.0 and local.x < b.width and local.z > 0.0 and local.z < b.depth:
			_indoors_now = true
			break
	return _indoors_now


func _on_hour_changed(hour: int) -> void:
	set_lit(should_be_lit(hour))


func _build() -> void:
	# The lamp itself (PropModels.lamp: brass foot and font on the texel grid, a glass chimney);
	# the flame burns inside the chimney.
	var metal := PropModels.brass()
	var model := Node3D.new()
	model.name = "Model"
	PropModels.lamp(model)
	# Nothing of the lamp shades its own light (the font's shadow from a flame just over it was a
	# jagged black ring on the table); the chimney glows when it's lit.
	for mi in model.find_children("*", "MeshInstance3D", false, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_chimney = model.get_node(^"Chimney") as MeshInstance3D
	add_child(model)
	_flame_material = StandardMaterial3D.new()
	_flame_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flame_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flame_material.emission = Color(1.0, 0.68, 0.3)
	_flame_material.emission_energy_multiplier = 5.0
	_flame = MeshInstance3D.new()
	# A teardrop of flame, as the painting draws it filling the chimney's swell.
	var tongue := PropModels.lathe(PropModels._profile([[0.004, 0.0], [0.014, 0.012], [0.016, 0.026], [0.011, 0.046], [0.002, 0.066]]), 8)
	_flame.mesh = tongue
	_flame.material_override = _flame_material
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flame.position.y = 0.17
	add_child(_flame)

	if hanging:
		var bail := MeshInstance3D.new()
		var bail_mesh := BoxMesh.new()
		bail_mesh.size = Vector3(0.01, 0.2, 0.01)
		bail.mesh = bail_mesh
		bail.material_override = metal
		bail.position.y = 0.47
		add_child(bail)

	if not show_mesh:
		model.visible = false
		_flame.visible = false
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.74, 0.48)
	_light.light_volumetric_fog_energy = haze
	_light.light_energy = energy
	_light.omni_range = light_range
	_light.omni_attenuation = attenuation
	_light.shadow_enabled = casts_shadows
	_light.shadow_bias = 0.05
	_light.shadow_caster_mask = ALL_CASTERS
	_light.light_cull_mask = LIGHTS_ALL & ~cull_out
	_light.position.y = 0.22
	add_child(_light)
	# Something for a bullet to hit.
	var hitbox := StaticBody3D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = Layers.WORLD
	hitbox.collision_mask = 0
	hitbox.set_meta(&"oil_lamp", self)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.14, 0.38, 0.14)
	shape.shape = box
	shape.position.y = 0.19
	hitbox.add_child(shape)
	add_child(hitbox)


## A bullet (or a fall) breaks it: glass everywhere, and a lit lamp throws its burning oil down
## on whatever's below.
func smash(direction := Vector3.DOWN) -> void:
	if broken:
		return
	broken = true
	var was_lit := lit
	set_lit(false)
	for c in get_children():
		if c is MeshInstance3D or c.name == &"Model":
			(c as Node3D).visible = false
	var hitbox := get_node_or_null(^"Hitbox") as StaticBody3D
	if GameAudio.enabled():
		GameAudio.play(self, &"glass", global_position, {"unit_size": 5.0, "limit": GameAudio.t().breaking_limit})
	else:
		var snd := AudioStreamPlayer3D.new()
		snd.stream = SynthSounds.get_sound(&"glass")
		snd.unit_size = 5.0
		add_child(snd)
		snd.play()
	ImpactEffects.burst(get_parent(), global_position + Vector3.UP * 0.12, -direction, Color(0.8, 0.85, 0.8), 10, 1.5, 0.02)
	if not was_lit:
		return
	# Where the oil lands: straight down from the lamp, onto the counter, the floor, the boardwalk.
	var at := global_position
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.05, global_position + Vector3.DOWN * 4.0, Layers.WORLD)
	if hitbox:
		q.exclude = [hitbox.get_rid()]
	var hit := World.space(self).intersect_ray(q)
	if not hit.is_empty():
		at = hit.position
	if hitbox:
		hitbox.queue_free()
	var fire := FireSystem.find(get_tree())
	if fire and FireSystem.in_play:  # (fire out of the game for now: FireSystem.in_play)
		fire.spill(at)
