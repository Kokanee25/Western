class_name BookLights
extends Node3D
## The book shown from the street (townsfolk step 2, #870; docs/briefs/townsfolk.md §7, 3: "lit
## windows, chimney smoke and shut doors that follow the book"): for each building someone in the
## town's day goes into, a window beside its door that glows after dark while someone's in at a lamp's
## doing (TownBook.lit) and smoke from its roof while someone's cooking (TownBook.smoke).
##
## A greybox stand-in, drawn by the gameplay lane till the art lane gives fronts their windows and
## chimneys (the brief's "Others' work it leans on"): a warm pane on a block's front with a small light
## out over the walk (no shadow); on a spec building (its own sash windows) the light alone, just
## inside its front. The smoke a few slow grey puffs. Set each time ValleyFolk reads the clock.

## The window: beside the door (m east of it), its middle this high over the walk, its size.
const WINDOW_BESIDE := 2.6
const WINDOW_UP := 1.5
const WINDOW_SIZE := Vector2(0.9, 1.2)
const LIGHT_ENERGY := 0.7
const LIGHT_RANGE := 4.5
const LIGHT_COLOUR := Color(1.0, 0.72, 0.42)

var folk: ValleyFolk
## place -> {"light": OmniLight3D, "pane": MeshInstance3D or null, "smoke": GPUParticles3D}.
var shows := {}


func _init() -> void:
	name = "BookLights"


## One for each building in `places` (lot ids; a way out of town has none).
func build(places: Array) -> void:
	for p: Variant in places:
		var id := String(p)
		var lot := folk.layout.lot(id)
		if lot.is_empty() or String(lot.get("kind", "")) != "building" or shows.has(StringName(id)):
			continue
		shows[StringName(id)] = _make(id, lot)


func _make(id: String, lot: Dictionary) -> Dictionary:
	var x0 := float(lot.get("x0", 0.0))
	var w := float(lot.get("x1", x0 + 10.0)) - x0
	var depth := float(lot.get("depth", 20.0))
	var door := float((lot.get("walk", {}) as Dictionary).get("door_x", x0 + w * 0.5)) - x0
	var a := clampf(door + WINDOW_BESIDE, 1.0, w - 1.0)
	var spec := lot.has("spec")
	var root := Node3D.new()
	root.name = "Book_" + id
	add_child(root)
	var face := folk.lot_point(id, a, -0.03, WINDOW_UP)
	var out_n := Vector3(0, 0, 1 if face.z < 0.0 else -1)  # the street's way
	var pane: MeshInstance3D = null
	if not spec:
		pane = MeshInstance3D.new()
		pane.name = "Pane"
		var q := QuadMesh.new()
		q.size = WINDOW_SIZE
		pane.mesh = q
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.25, 0.17, 0.08)
		m.emission_enabled = true
		m.emission = LIGHT_COLOUR
		m.emission_energy_multiplier = 1.6
		pane.material_override = m
		pane.transform = Transform3D(Basis.looking_at(-out_n, Vector3.UP), face)
		pane.visible = false
		root.add_child(pane)
	var light := OmniLight3D.new()
	light.name = "Light"
	light.light_color = LIGHT_COLOUR
	light.light_energy = LIGHT_ENERGY
	light.omni_range = LIGHT_RANGE
	light.shadow_enabled = false
	light.position = face + out_n * (0.6 if not spec else -1.0)
	light.visible = false
	root.add_child(light)
	# The chimney: toward the back of the roof, east of the middle.
	var top := folk.lot_point(id, w * 0.7, depth * 0.6, 0.0)
	var block := _block(id)
	top.y = (block.centre as Vector3).y + (block.size as Vector3).y + 0.3 if not block.is_empty() else top.y + 7.5
	var smoke := _smoke()
	smoke.position = top
	root.add_child(smoke)
	return {"light": light, "pane": pane, "smoke": smoke}


func _block(id: String) -> Dictionary:
	var world := folk.get_parent() as ValleyWorld
	if world == null or world.markers == null:
		return {}
	return world.markers.block(id)


static func _smoke() -> GPUParticles3D:
	var s := GPUParticles3D.new()
	s.name = "Smoke"
	s.amount = 10
	s.lifetime = 7.0
	s.emitting = false
	s.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 9, 6))
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 12.0
	pm.initial_velocity_min = 0.45
	pm.initial_velocity_max = 0.7
	pm.gravity = Vector3(0.12, 0.02, 0.05)  # a breath of wind
	pm.scale_min = 0.6
	pm.scale_max = 1.0
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 2.2))
	var gt := CurveTexture.new()
	gt.curve = grow
	pm.scale_curve = gt
	var fade := Gradient.new()
	fade.set_color(0, Color(0.62, 0.6, 0.58, 0.45))
	fade.set_color(1, Color(0.62, 0.6, 0.58, 0.0))
	var ft := GradientTexture1D.new()
	ft.gradient = fade
	pm.color_ramp = ft
	s.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.8, 0.8)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	q.material = m
	s.draw_pass_1 = q
	return s


## Each building's window and smoke to the book at `hour`.
func show_book(book: TownBook, hour: float) -> void:
	for place: StringName in shows:
		var s: Dictionary = shows[place]
		var lit := book.lit(place, hour)
		(s.light as OmniLight3D).visible = lit
		if s.pane != null:
			(s.pane as MeshInstance3D).visible = lit
		var smoke := s.smoke as GPUParticles3D
		var on := book.smoke(place)
		if smoke.emitting != on:
			smoke.emitting = on


## {place: {lit, smoke}} for the tests and the bridge.
func report() -> Dictionary:
	var out := {}
	for place: StringName in shows:
		var s: Dictionary = shows[place]
		out[String(place)] = {"lit": (s.light as OmniLight3D).visible, "smoke": (s.smoke as GPUParticles3D).emitting}
	return out
