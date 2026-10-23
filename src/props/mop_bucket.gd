class_name MopBucket
extends Node3D
## The mop's bucket (kit kind "bucket", `mop_bucket.json`; docs/briefs/mopping.md): the bucket line's
## wooden bucket (BucketLine.bucket_model) with water in it, and what's been rinsed into the water:
## dirt (g), blood and spilt drink (ml). Its water darkens with them. Carried by its bail in a hand,
## set down where it's wanted; emptied (indoors, a big spill on the boards: FloorMarks; outside it
## soaks into the street) and filled again.

var kit_id := &"mop_bucket"
var definition := {}
var water_ml := 0.0
var dirt := 0.0
var blood := 0.0
var other := 0.0
var body: StaticBody3D
var model: Node3D
var carrier: HumanBody
var _surface: MeshInstance3D
var _mat: StandardMaterial3D


func _ready() -> void:
	if definition.is_empty():
		definition = PropKit.definition(kit_id)
	add_to_group(&"mop_buckets")
	model = BucketLine.bucket_model()
	add_child(model)
	_surface = model.get_node(^"Water") as MeshInstance3D
	_mat = (WoodMaterials.water() as StandardMaterial3D).duplicate() as StandardMaterial3D
	_surface.material_override = _mat
	body = StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = float(definition.get("radius", 0.15))
	cyl.height = float(definition.get("height", 0.3))
	cs.shape = cyl
	cs.position.y = cyl.height * 0.5
	body.add_child(cs)
	body.set_meta(&"mop_bucket", self)
	add_child(body)
	if water_ml <= 0.0:
		fill()
	_show()


## Full of clean water.
func fill(ml := -1.0) -> void:
	water_ml = ml if ml >= 0.0 else float(definition.get("litres", 9.0)) * 1000.0
	dirt = 0.0
	blood = 0.0
	other = 0.0
	_show()


## How dirty its water is: what's in it a millilitre of water (dirt g/ml, blood and drink ml/ml).
func concentration() -> Dictionary:
	var w := maxf(water_ml, 1.0)
	return {"dirt": dirt / w, "blood": blood / w, "other": other / w}


## How murky it looks (0 clean .. 1 as dark as it gets).
func murk() -> float:
	var c := concentration()
	return clampf(1.0 - exp(-(c.dirt * 400.0 + c.blood * 30.0 + c.other * 5.0)), 0.0, 1.0)


## Water and what's in it given to it (a mop pressed out).
func receive(ml: float, d: float, b: float, o: float) -> void:
	water_ml += ml
	dirt += d
	blood += b
	other += o
	_show()


## `ml` of its water taken out (into a mop), with its share of what's in it: {dirt, blood, other}.
func give(ml: float) -> Dictionary:
	ml = minf(ml, water_ml)
	var c := concentration()
	var out := {"dirt": c.dirt * ml, "blood": c.blood * ml, "other": c.other * ml}
	water_ml -= ml
	dirt -= out.dirt
	blood -= out.blood
	other -= out.other
	_show()
	return out


## The top of its water (world), and whether a point is in its water.
func surface_y() -> float:
	return _surface.global_position.y


func holds(p: Vector3) -> bool:
	var c := global_position
	return Vector2(p.x - c.x, p.z - c.z).length() < float(definition.get("radius", 0.15)) - 0.02 \
			and p.y > c.y + 0.02 and p.y < surface_y() + 0.01


func _show() -> void:
	if _surface == null:
		return
	var full := clampf(water_ml / (float(definition.get("litres", 9.0)) * 1000.0), 0.0, 1.0)
	_surface.visible = full > 0.03
	_surface.position.y = lerpf(0.03, 0.26, full)
	var cl: Array = definition.get("clean", [0.32, 0.38, 0.4])
	var md: Array = definition.get("muddy", [0.26, 0.19, 0.12])
	var bl: Array = definition.get("bloody", [0.32, 0.07, 0.05])
	var c := concentration()
	var red := clampf(c.blood * 30.0 / maxf(c.dirt * 400.0 + c.blood * 30.0, 1e-6), 0.0, 1.0)
	var dirty := Color(md[0], md[1], md[2]).lerp(Color(bl[0], bl[1], bl[2]), red)
	_mat.albedo_color = Color(cl[0], cl[1], cl[2]).lerp(dirty, murk())


# --- Carried ---------------------------------------------------------------------------------------

## By its bail in `by`'s hand on `side`.
func carry(by: HumanBody, side: String) -> void:
	var hand := by.parts.get(StringName("hand_" + side)) as Node3D
	if hand == null:
		return
	carrier = by
	body.collision_layer = 0
	reparent(hand, false)
	# The bail in his curled fingers, the bucket hanging under.
	position = Vector3(0, -0.36, 0)
	rotation = Vector3.ZERO
	top_level = true
	by.curl_hand(side, 0.7)


## Each tick it's carried it hangs plumb under his hand.
func _physics_process(_delta: float) -> void:
	if carrier == null:
		return
	var hand := get_parent() as Node3D
	if hand == null or not is_instance_valid(carrier) or carrier.limp:
		set_down(global_position - Vector3.UP * 0.1)
		return
	global_transform = Transform3D(Basis(Vector3.UP, carrier.global_rotation.y), hand.global_position - Vector3.UP * 0.36)


## Down on whatever's under `at` (a floor, the street).
func set_down(at: Vector3, parent: Node = null) -> void:
	var by := carrier
	carrier = null
	top_level = false
	var to := parent if parent != null else (by.get_parent() if by != null and is_instance_valid(by) else get_parent())
	reparent(to, true)
	var y := at.y
	var marks := FloorMarks.find(get_tree())
	var under := marks.surface_at(at, 0.6) if marks else {}
	if not under.is_empty():
		y = (under.at as Vector3).y
	else:
		var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.6, at - Vector3.UP * 1.0, Layers.WORLD)
		q.exclude = [body.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			y = (hit.position as Vector3).y
	global_transform = Transform3D(Basis(Vector3.UP, global_rotation.y), Vector3(at.x, y, at.z))
	body.collision_layer = Layers.WORLD
	if by != null and is_instance_valid(by):
		by.curl_hand("l", 0.15)
		by.curl_hand("r", 0.15)


## Thrown out: on boards a spill of dirty water (FloorMarks), on the street it soaks away.
func empty_out(toward: Vector3) -> void:
	var marks := FloorMarks.find(get_tree())
	if marks != null and water_ml > 0.0:
		var under := marks.surface_at(toward, 0.8)
		if not under.is_empty():
			marks.add_liquid(under.at, &"water", water_ml)
			marks.add_dirt(under.at, dirt)
			if blood > 0.0:
				marks.add_liquid(under.at, &"blood", blood)
	Events.noise.emit(toward, 0.4, &"splash", self)
	water_ml = 0.0
	dirt = 0.0
	blood = 0.0
	other = 0.0
	_show()
