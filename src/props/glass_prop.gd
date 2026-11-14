class_name GlassProp
extends Node3D
## A prop that shatters (docs/briefs/prop-lab.md: the kit's second kind, "shatters"): a bottle, a
## lamp. Its kit file names its model (PropModels'), which of the model's parts are glass, which
## come through whole (a bottle's cork and neck, a lamp's brass foot), and what it holds.
##
## Standing, it's its model (drawn batched by StaticBatch, as the drawn props are) over a frozen
## body: a ball goes through it (Ballistics' `ballistic_thickness`, the glass's two walls) and
## breaks it. It breaks:
## - **shot:** always (a lead ball through bottle glass);
## - **dropped or struck:** landing or hit faster than its `breaks_at` (a lamp chimney's thin glass
##   at a walk's pace; a thick bottle on a wooden floor at about a metre's fall: many don't break
##   falling off a table);
## - **by a blast:** overpressure past `shatters_kpa` breaks it where it stands; short of that it's
##   thrown (Blast's push for anything loose) and breaks if it lands hard;
## - **in a fire:** flames on it for `heat_seconds` crack it (thermal shock).
## Losing what it stands on (its table going over, the shelf burning) it falls with it; hung on
## a nail (a sconce: "hangs"), losing what the nail's in (the wall's board shot out or burnt); hung
## by a hook ("hangs": {"hook"}: a hanging lamp, #866), losing what's over the hook (the joist
## broken, burnt or fallen). Hung by a hook it swings ("swing": its pivot, length and damping): when
## what it hangs from moves (a dance floor working over it), a blast or a knock pushes it
## (`push_swing`); the swing is drawn (its model and lights turned about the hook), not simulated,
## so it costs no body.
##
## Breaking: shards of its glass fly (on with what broke it, the rest outward and down), the
## parts that come through whole fall as their own piece, the glass sound, people hear it, the
## shards cut whoever's close (GlassCuts). What it held is let go: a lit lamp's oil burns
## (OilLamp.smash, as before); anything else goes out on the bus (`Events.liquid_spilled`) for the
## spills (the water lab's) to take up; lamp oil let go into flames catches (FireSystem.spill).
## (LooseProp, the kit's "loose" kind, stands the same way but is knocked and dented instead.)

signal shattered(at: Vector3, direction: Vector3)

const CHECK_EVERY := 0.25
const SETTLE_FRAMES := 4
const FOOT_REACH := 0.03
const MOVED := 0.05
## Thrown slower than this by a blast it stays put (m/s): a slide of under 2 cm.
const LOOSE_FROM := 0.4
## Shards lying about, oldest first; past MAX_SHARDS the oldest go.
const MAX_SHARDS := 160
const SHARD_SETTLE := 2.5

var kit_id: StringName
var definition: Dictionary
var variant := 0
var broken := false
var loose := false
var body: RigidBody3D
var model: Node3D

static var _shards: Array = []

var _frames := 0
var _check_t := 0.0
var _heat_t := 0.0
var _under := []  # [[StructureMember or null for fixed ground, its position]]
var _footed := false
var _v_before := Vector3.ZERO
var _lamp_list: Array[Node] = []
## Hung by a hook (#866): what it swings about, what it hangs from, and its swing (the bob's
## sideways angles about x and z, radians, and their rates).
var _pivot: Node3D
var _pivot_rest := Vector3.ZERO
var _anchor: StructureMember
var _anchor_rest := Vector3.ZERO
var _anchor_last := Vector3.INF
var _anchor_v := Vector3.ZERO
var _theta := Vector2.ZERO
var _omega := Vector2.ZERO
var _swinging := false
## Swinging, it has left the batch (drawn on its own, as a prop that moves must be).
var _unbatched := false
## The most a swing leans (radians): past it, it's against the joist.
const MAX_SWING := 0.7
## Its hook looks this far over itself for what it hangs from (m).
const HOOK_REACH := 0.06
## Pushed faster than this (m/s) it comes off its hook instead of swinging.
const OFF_HOOK := 4.0


func _ready() -> void:
	if definition.is_empty() and kit_id != &"":
		definition = PropKit.definition(kit_id)
	add_to_group(&"glass_props")
	_build()
	Events.bullet_hit.connect(_on_bullet_hit)
	Events.exploded.connect(_on_exploded)
	# A lamp's light (OilLamp) brings its own hitbox for balls; this prop is its hitbox now (a shot
	# breaks it, and it smashes the lamp), and a fixed box inside a falling lamp stops what it meets.
	_lamp_list = find_children("*", "OilLamp", true, false)
	for lamp in _lamp_list:
		_take_hitbox(lamp)
		_onto_pivot.call_deferred(lamp)
	# (The town's callers add a lamp's light after it's built: PropLibrary's "light_height".)
	child_entered_tree.connect(func(n: Node) -> void:
		if n is OilLamp:
			_lamp_list.append(n)
			_take_hitbox.call_deferred(n)
			_onto_pivot.call_deferred(n))


## A light added to a lamp that swings swings with it (onto its pivot, where it is).
func _onto_pivot(n: Node) -> void:
	if _pivot and is_instance_valid(n) and n.get_parent() == self and not loose:
		n.reparent(_pivot, true)


func _take_hitbox(lamp: Node) -> void:
	if not is_instance_valid(lamp):
		return
	var hb := lamp.get_node_or_null(^"Hitbox") as CollisionObject3D
	if hb:
		hb.collision_layer = 0
	# Its chimney is this prop's (the lamp's own model is hidden): the lamp lights it when it's lit,
	# so the glass glows round its flame (chimney_glass.gdshader's `glow`; #788: a kit lamp's chimney
	# never glowed).
	var chimney := _chimney_mesh()
	if chimney and lamp.get(&"show_mesh") == false:
		lamp.set(&"_chimney", chimney)
		lamp.call(&"set_lit", bool(lamp.get(&"lit")))


## The model's glass chimney (a lamp's), or null.
func _chimney_mesh() -> MeshInstance3D:
	if model == null:
		return null
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).begins_with("Chimney") and mi.material_override is ShaderMaterial:
			return mi
	return null


func _build() -> void:
	var size := PropKit.vec(definition.get("size", [0.1, 0.3, 0.1]))
	model = Node3D.new()
	model.name = "Model"
	match String(definition.get("model", "bottle")):
		"bottle":
			PropModels.bottle(model, variant)
		"lamp":
			PropModels.lamp(model)
		var other when String(other).begins_with("glb:"):
			# A model made in Blender (docs/briefs/prop-factory.md), each part in the look its kit
			# file's "looks" gives it by name ("" for the rest).
			var looks: Dictionary = definition.get("looks", {})
			for key: String in looks:
				# A part named with "%d" is one of `variants` (a bottle's labels, #805): the Nth made
				# wears the (N mod variants)th.
				var part := key % posmod(variant, int(definition.get("variants", 1))) if key.contains("%d") else key
				var mesh := PropKit.model_part(String(other).substr(4), part)
				if mesh:
					var mi := MeshInstance3D.new()
					mi.name = part if part != "" else "Mesh"
					mi.mesh = mesh
					mi.material_override = PropKit.material(String(looks[key]), variant)
					if String(looks[key]).begins_with("glass:"):
						# See-through glass casts no shadow of its own (what's in it does): and no
						# draw in each shadow pass for every bottle on a shelf (#805).
						mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					elif part in definition.get("no_shadow", []):
						# Parts under a lamp's own flame (a hanging lamp's font and burner, #879):
						# their shadow would black out a metre round the table it's hung over (the
						# room has no bounce light to fill it, as a real room's walls and shade do).
						mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					model.add_child(mi)
		var other:
			var built := PropModels.build(StringName(other), variant)
			if built:
				model.add_child(built)
			else:
				push_warning("GlassProp: no model %s" % other)
	add_child(model)
	if definition.has("swing"):
		# Its model (and its lights, as they come) on a pivot at its hook, turned as it swings.
		_pivot = Node3D.new()
		_pivot.name = "Swing"
		_pivot_rest = PropKit.vec(definition.swing.get("pivot", [0.0, size.y, 0.0]))
		_pivot.position = _pivot_rest
		add_child(_pivot)
		remove_child(model)
		_pivot.add_child(model)
		model.position -= _pivot_rest
	var shape_box := AABB(Vector3(-size.x * 0.5, 0.0, -size.z * 0.5), size)
	if definition.get("fit", false):
		# As PropLibrary fits a drawn prop: scaled to the manifest's height, its anchor (a wall
		# prop's back centre, else its bottom centre) at the origin.
		var raw := PropLibrary._model_bounds(model)
		var k := PropLibrary.size_of(kit_id).y / maxf(raw.size.y, 0.0001)
		var anchor := Vector3(raw.get_center().x, raw.position.y, raw.get_center().z)
		if PropLibrary.definition(kit_id).get("anchor", "floor") == "wall":
			anchor = Vector3(raw.get_center().x, raw.get_center().y, raw.position.z)
		model.scale = Vector3.ONE * k
		model.position = -anchor * k
		shape_box = AABB((raw.position - anchor) * k, raw.size * k)
	body = RigidBody3D.new()
	body.name = "Body"
	body.collision_layer = Layers.DEBRIS
	body.collision_mask = Layers.DEBRIS_MASK
	body.mass = float(definition.get("mass", 1.0))
	body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	body.freeze = true
	body.contact_monitor = true
	body.max_contacts_reported = 4
	body.continuous_cd = true
	body.set_meta(&"ballistic_thickness", float(definition.get("wall", 0.004)) * 2.0)
	body.set_meta(&"glass_prop", self)
	var cs := CollisionShape3D.new()
	if definition.has("hit"):
		# Its body only the part a ball breaks (a hanging lamp's, not its chain's).
		var hb := BoxShape3D.new()
		hb.size = PropKit.vec(definition.hit.size)
		cs.shape = hb
		cs.position = PropKit.vec(definition.hit.at)
	elif definition.get("fit", false) and definition.get("shape", "box") == "cylinder":
		# Round (it rolls): a cylinder the model's height, as wide as its narrower side.
		var cyl := CylinderShape3D.new()
		cyl.radius = minf(shape_box.size.x, shape_box.size.z) * 0.5
		cyl.height = shape_box.size.y
		cs.shape = cyl
		cs.position = shape_box.get_center()
	elif definition.get("fit", false):
		var bs := BoxShape3D.new()
		bs.size = shape_box.size
		cs.shape = bs
		cs.position = shape_box.get_center()
	else:
		var cyl := CylinderShape3D.new()
		cyl.radius = maxf(size.x, size.z) * 0.5
		cyl.height = size.y
		cs.shape = cyl
		cs.position.y = size.y * 0.5
	body.add_child(cs)
	add_child(body)
	body.body_entered.connect(_on_body_entered)


func _lamps() -> Array[Node]:
	return _lamp_list.filter(func(n: Node) -> bool: return is_instance_valid(n))


func _physics_process(delta: float) -> void:
	if broken:
		return
	if loose:
		_v_before = body.linear_velocity
		return
	if not _footed:
		_frames += 1
		if _frames >= SETTLE_FRAMES:
			_find_footing()
			# Spread over the quarter second, by its name: Godot's global dice made each run check
			# on its own frame, so a sconce whose wall a blast took fell a frame sooner or later.
			_check_t = posmod(hash(name), 1000) / 1000.0 * CHECK_EVERY
		return
	if _pivot:
		_swing_step(delta)
	_check_t -= delta
	if _check_t > 0.0:
		return
	_check_t = CHECK_EVERY
	# Its light smashed some other way (a lamp's own rule): the glass is gone with it.
	for lamp in _lamp_list:
		if is_instance_valid(lamp) and bool(lamp.get(&"broken")):
			shatter(body.global_position + Vector3.UP * 0.25, Vector3.DOWN)
			return
	if not _has_footing():
		wake()
		return
	_heat(CHECK_EVERY)


# --- What it stands on ---------------------------------------------------------------------------

func _find_footing() -> void:
	_footed = true
	_under.clear()
	var size := PropKit.vec(definition.get("size", [0.1, 0.3, 0.1]))
	var q := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x * 0.8, FOOT_REACH, size.z * 0.8)
	q.shape = box
	q.transform = Transform3D(global_basis, global_position + global_basis.y * (0.002 - FOOT_REACH * 0.5))
	var nails: Array = definition.get("hangs", {}).get("nails", [])
	var hook: Variant = definition.get("hangs", {}).get("hook")
	if hook != null:
		# Hung by a hook: what's just over it (a joist's underside, a beam).
		box.size = Vector3(0.05, HOOK_REACH, 0.05)
		q.transform = Transform3D(global_basis, global_transform * (PropKit.vec(hook) + Vector3.UP * (HOOK_REACH * 0.5 - 0.002)))
	elif not nails.is_empty():
		# Hung on a nail (a sconce's back plate): what's behind it, up to KitProp.WALL_REACH back.
		var p := PropKit.vec(nails[0])
		box.size = Vector3(0.03, 0.03, KitProp.WALL_REACH)
		q.transform = Transform3D(global_basis, global_transform * Vector3(p.x, p.y, -KitProp.WALL_REACH * 0.5 + 0.005))
	q.collision_mask = Layers.WORLD
	q.exclude = [body.get_rid()]
	for hit in World.space(self).intersect_shape(q, 8):
		var c: Object = hit.collider
		if c is StructureMember:
			_under.append([c, (c as StructureMember).global_position])
			if hook != null and _anchor == null:
				_anchor = c as StructureMember
				_anchor_rest = _anchor.global_position
			# A kit prop it stands on going over takes it at once (not at the next look: left
			# frozen a moment, it's a fixed thing the table rises into).
			var owner_prop := (c as Node).get_parent()
			if owner_prop is KitProp and not (owner_prop as KitProp).went_loose.is_connected(_on_support_loose):
				(owner_prop as KitProp).went_loose.connect(_on_support_loose)
		elif c is StaticBody3D:
			_under.append([null, Vector3.ZERO])
	if _under.is_empty():
		wake()  # put down in the air


func _has_footing() -> bool:
	for e: Array in _under:
		var f: Variant = e[0]
		if f == null:
			return true
		if is_instance_valid(f) and not (f as StructureMember).broken and not (f as StructureMember).consumed \
				and (f as StructureMember).global_position.distance_to(e[1]) < MOVED:
			return true
	return false


func _on_support_loose() -> void:
	if not loose and not broken:
		wake()


## It's moving now: out of the batch, its model on its body, the body free (with `velocity`).
func wake(velocity := Vector3.ZERO) -> void:
	if loose or broken:
		return
	loose = true
	_swinging = false
	StaticBatch.release_in(get_tree(), self)
	model.reparent(body, true)
	for lamp in _lamps():
		lamp.reparent(body, true)
	body.freeze = false
	body.sleeping = false
	body.linear_velocity = velocity
	_v_before = velocity


# --- Swinging on its hook (#866) -----------------------------------------------------------------

## Pushed at its bob (`velocity`, m/s, world): it swings (a hand, a knock, a blast's wind).
func push_swing(velocity: Vector3) -> void:
	if _pivot == null or loose or broken:
		return
	var local := global_basis.inverse() * velocity
	_omega += Vector2(local.x, local.z) / _length()
	_swinging = true


## How far it leans now (radians, the bob's sideways angles about x and z), for tests and the bridge.
func swing_angle() -> Vector2:
	return _theta


func _length() -> float:
	return maxf(float(definition.get("swing", {}).get("length", 0.7)), 0.1)


## A damped pendulum about its hook, driven by what it hangs from moving under it (its
## acceleration: a joist working as the dancers stamp), drawn by turning its pivot. Idle (nothing
## moving, no swing) it does nothing but look at its joist.
func _swing_step(dt: float) -> void:
	var drive := Vector3.ZERO
	var offset := Vector3.ZERO
	if is_instance_valid(_anchor):
		var p := _anchor.global_position
		if _anchor_last != Vector3.INF and dt > 0.0:
			var v := (p - _anchor_last) / dt
			drive = ((v - _anchor_v) / dt).limit_length(60.0)
			_anchor_v = v
		_anchor_last = p
		offset = p - _anchor_rest
	if drive.length_squared() > 1e-6:
		_swinging = true
	if not _swinging and offset.length_squared() < 1e-8:
		return
	var swing: Dictionary = definition.get("swing", {})
	var length := _length()
	var local_a := global_basis.inverse() * drive
	var acc := -(9.81 / length) * _theta - float(swing.get("damping", 0.3)) * _omega - Vector2(local_a.x, local_a.z) / length
	_omega += acc * dt
	_theta += _omega * dt
	if _theta.length() > MAX_SWING:
		_theta = _theta.limit_length(MAX_SWING)
		_omega *= 0.5
	if not _unbatched:
		_unbatched = true
		StaticBatch.release_in(get_tree(), self)
	_pivot.transform = Transform3D(Basis.from_euler(Vector3(-_theta.y, 0.0, _theta.x)), _pivot_rest + global_basis.inverse() * offset)
	if _theta.length() < 0.002 and _omega.length() < 0.004 and drive.length_squared() < 1e-6:
		_swinging = false
		_theta = Vector2.ZERO
		_omega = Vector2.ZERO
		_pivot.transform = Transform3D(Basis.IDENTITY, _pivot_rest + global_basis.inverse() * offset)


# --- What breaks it ------------------------------------------------------------------------------

func _on_bullet_hit(info: Dictionary) -> void:
	if not broken and info.get("collider") == body:
		shatter(info.get("position", body.global_position), info.get("direction", Vector3.DOWN), true)


## Falling onto something, or something moving into it, faster than its glass takes.
func _on_body_entered(other: Node) -> void:
	if broken:
		return
	var v := _v_before if loose else Vector3.ZERO
	var other_v := (other as RigidBody3D).linear_velocity if other is RigidBody3D else Vector3.ZERO
	var closing := (v - other_v).length()
	if closing >= float(definition.get("breaks_at", 3.0)):
		shatter(body.global_position + Vector3.UP * 0.05, (v - other_v).normalized())
	elif not loose and other_v.length() > LOOSE_FROM:
		if _pivot and other_v.length() * 0.5 < OFF_HOOK:
			push_swing(other_v * 0.5)  # knocked: it swings on its hook
		else:
			wake(other_v * 0.5)  # knocked over by what struck it


func _on_exploded(at: Vector3, kg: float) -> void:
	if broken or not is_inside_tree():
		return
	var centre := body.global_position + Vector3.UP * PropKit.vec(definition.get("size", [0.1, 0.3, 0.1])).y * 0.5
	if definition.get("fit", false):
		centre = (body.get_child(0) as CollisionShape3D).global_position
	var r := maxf(centre.distance_to(at), 0.05)
	if r > Blast.reach(kg) + 2.0:
		return
	var shield := Blast.shielding(self, at, centre, [body.get_rid()])
	# Side-on, not reflected (as panes and people take it, #220): on a thing a few cm across the
	# reflected spike clears in a tenth of a millisecond, a stick's pulse lasts ~1 ms (Baker et al.,
	# "Explosion Hazards and Evaluation", 1983, ch. 6: clearing and diffraction loading).
	var kpa := Blast.overpressure_kpa(kg, r) * shield
	var away := (centre - at).normalized()
	if kpa > float(definition.get("shatters_kpa", 60.0)):
		shatter(centre, away)
		return
	var kgs := body.mass
	var area := pow(maxf(kgs / 500.0, 1e-5), 2.0 / 3.0)
	var v := (away + Vector3.UP * 0.3).normalized() * Blast.impulse(kg, r) * area * shield / maxf(kgs, 0.05)
	if v.length() > Blast.t().max_throw:
		v = v.normalized() * Blast.t().max_throw
	if not loose and definition.has("hangs"):
		# Hung: the wall takes what drives it in, the nail what drives it down.
		var local := global_basis.inverse() * v
		local.z = maxf(local.z, 0.0)
		local.y = maxf(local.y, 0.0)
		v = global_basis * local
	if _pivot and not loose and v.length() < OFF_HOOK:
		push_swing(v)  # hung by a hook: the blast swings it
		return
	if v.length() >= LOOSE_FROM:
		if loose:
			body.linear_velocity += v
		else:
			wake(v)


## In the flames long enough, the glass cracks.
func _heat(dt: float) -> void:
	var fire := FireSystem.find(get_tree())
	if fire == null or (fire.active.is_empty() and fire.spills.is_empty()):
		_heat_t = 0.0
		return
	if int(fire.fire_near(body.global_position, 0.35).count) > 0:
		_heat_t += dt
		if _heat_t >= float(definition.get("heat_seconds", 25.0)):
			shatter(body.global_position + Vector3.UP * 0.1, Vector3.UP)
	else:
		_heat_t = maxf(_heat_t - dt, 0.0)


# --- Breaking ------------------------------------------------------------------------------------

## It breaks at `at` (world), struck going `direction`.
func shatter(at: Vector3, direction: Vector3, shot := false) -> void:
	if broken:
		return
	broken = true
	if not loose:
		StaticBatch.release_in(get_tree(), self)
	var dir := direction.normalized() if direction.length() > 0.01 else Vector3.DOWN
	var host: Node = get_parent() if get_parent() else self
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(name) + int(at.x * 1000.0) * 31 + int(at.z * 1000.0)
	var glass_names: Array = definition.get("glass", ["Glass"])
	var glass_mat: Material = null
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).rstrip("0123456789") in glass_names or mi.name in glass_names:
			glass_mat = mi.material_override if glass_mat == null else glass_mat
	_shards_from(host, rng, at, dir, glass_mat)
	_whole_pieces(host, dir)
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mi.visible = false
	# Its light, if it's a lamp: out, and its burning oil down if it was lit (OilLamp's own).
	var lit := false
	for lamp in _lamps():
		lit = lit or bool(lamp.get(&"lit"))
		lamp.call(&"smash", dir)
	body.collision_layer = 0
	body.collision_mask = 0
	body.freeze = true
	_sound(host, at)
	var excl: Array[RID] = [body.get_rid()]
	GlassCuts.spray(host as Node3D if host is Node3D else self, at, dir, float(definition.get("cut_area", 0.05)), rng.randi(), excl)
	if not lit:
		_let_go(host, at)
	shattered.emit(at, dir)


## Shards of its glass: thin, small, on with what broke it (the shot's way, fast) or out and down.
func _shards_from(host: Node, rng: RandomNumberGenerator, at: Vector3, dir: Vector3, mat: Material) -> void:
	var size := PropKit.vec(definition.get("size", [0.1, 0.3, 0.1]))
	var r := maxf(size.x, size.z) * 0.5
	var centre := body.global_transform * Vector3(0, size.y * 0.5, 0)
	var wall := float(definition.get("wall", 0.004))
	for i in int(definition.get("shards", 12)):
		var shard := RigidBody3D.new()
		shard.name = "GlassShard"
		shard.add_to_group(&"glass_shards")
		shard.collision_layer = Layers.DEBRIS
		shard.collision_mask = Layers.DEBRIS_MASK
		var dims := Vector3(rng.randf_range(0.008, 0.035), rng.randf_range(0.008, 0.04), wall)
		shard.mass = maxf(dims.x * dims.y * dims.z * 2500.0, 0.002)
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = dims
		cs.shape = box
		shard.add_child(cs)
		var mi := MeshInstance3D.new()
		mi.mesh = MemberMesh.box(dims)
		mi.material_override = mat if mat else WoodMaterials.glass()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shard.add_child(mi)
		var a := rng.randf() * TAU
		var out := Vector3(cos(a), 0.0, sin(a))
		var p := centre + out * r + Vector3.UP * rng.randf_range(-0.4, 0.4) * size.y
		var b := Basis(out.cross(Vector3.UP).normalized(), rng.randf() * TAU) * Basis.looking_at(out, Vector3.UP)
		# Not inside the wall it hung on or the shelf beside it: a 2 g shard pushed out of timber
		# goes off at any speed (and its NaN spreads to what it meets). Inside where the glass was,
		# else none.
		if _in_world(Transform3D(b, p), dims):
			p = centre + out * r * 0.3 + Vector3.UP * (p.y - centre.y) * 0.3
			if _in_world(Transform3D(b, p), dims):
				shard.free()
				continue
		host.add_child(shard)
		shard.global_transform = Transform3D(b, p)
		RubbleRest.watch(shard)  # (lying still, drawn with the rest: #459)
		var with_it := rng.randf() < 0.55
		var v := (dir * rng.randf_range(1.5, 5.0) if with_it else out * rng.randf_range(0.4, 2.0)) \
				+ Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.2, 1.2), rng.randf_range(-0.5, 0.5))
		shard.linear_velocity = v + (body.linear_velocity if loose else Vector3.ZERO)
		shard.angular_velocity = Vector3(rng.randf_range(-15, 15), rng.randf_range(-15, 15), rng.randf_range(-15, 15))
		shard.angular_damp = 1.5
		shard.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		shard.get_tree().create_timer(SHARD_SETTLE, true, true).timeout.connect(_settle_shard.bind(shard))
		_shards.append(shard)
	_shards = _shards.filter(func(s: Variant) -> bool: return is_instance_valid(s))
	while _shards.size() > MAX_SHARDS:
		var old: Variant = _shards.pop_front()
		if is_instance_valid(old):
			(old as Node).queue_free()


## Whether a box of `size` at `xf` (world) overlaps the fixed world (members, the ground).
func _in_world(xf: Transform3D, size: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = size
	q.shape = box
	q.transform = xf
	q.collision_mask = Layers.WORLD
	q.exclude = [body.get_rid()]
	return not World.space(self).intersect_shape(q, 1).is_empty()


static func _settle_shard(shard: Variant) -> void:
	if is_instance_valid(shard):
		(shard as RigidBody3D).freeze = true


## The parts that come through whole (a bottle's neck and cork, a lamp's brass foot): each group a
## loose piece of its own, knocked on a little.
func _whole_pieces(host: Node, dir: Vector3) -> void:
	for group: Array in definition.get("whole", []):
		var meshes: Array[MeshInstance3D] = []
		for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			if String(mi.name).rstrip("0123456789") in group or mi.name in group:
				meshes.append(mi)
		if meshes.is_empty():
			continue
		var piece := RigidBody3D.new()
		piece.name = "Piece"
		piece.collision_layer = Layers.DEBRIS
		piece.collision_mask = Layers.DEBRIS_MASK
		piece.add_to_group(&"glass_shards")
		host.add_child(piece)
		var box := AABB()
		var first := true
		for mi in meshes:
			var b := mi.global_transform * mi.get_aabb()
			box = b if first else box.merge(b)
			first = false
		piece.global_position = box.get_center()
		for mi in meshes:
			var copy := MeshInstance3D.new()
			copy.mesh = mi.mesh
			copy.material_override = mi.material_override
			piece.add_child(copy)
			copy.global_transform = mi.global_transform
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = box.size.max(Vector3.ONE * 0.01)
		cs.shape = bs
		# Out of the wall it hung on (a sconce's plate is flush with the boards) or what it stood on.
		var away := global_basis.z if definition.has("hangs") else Vector3.UP
		for k in 8:
			if not _in_world(Transform3D(Basis.IDENTITY, piece.global_position), bs.size):
				break
			piece.global_position += away * 0.01
		piece.add_child(cs)
		piece.mass = maxf(float(definition.get("piece_mass", 0.15)), 0.02)
		piece.linear_velocity = dir * 1.2 + Vector3.UP * 0.5 + (body.linear_velocity if loose else Vector3.ZERO)
		piece.angular_velocity = Vector3(dir.z, 0.0, -dir.x) * 6.0
		piece.continuous_cd = true


func _sound(host: Node, at: Vector3) -> void:
	Events.noise.emit(at, 40.0, &"glass", null)
	var snd := AudioStreamPlayer3D.new()
	snd.stream = SynthSounds.get_sound(&"glass")
	snd.unit_size = 5.0
	host.add_child(snd)
	snd.global_position = at
	snd.play()
	snd.finished.connect(snd.queue_free)


## What it held, let go on the floor under it: out on the bus for the spills, a splash of it, and
## lamp oil into flames catches.
func _let_go(host: Node, at: Vector3) -> void:
	var contents: Dictionary = definition.get("contents", {})
	var litres := float(contents.get("litres", 0.0))
	if litres <= 0.0:
		return
	var floor_at := at
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.05, at + Vector3.DOWN * 4.0, Layers.WORLD)
	q.exclude = [body.get_rid()]
	var hit := World.space(self).intersect_ray(q)
	if not hit.is_empty():
		floor_at = hit.position
	var colour := Color(0.5, 0.3, 0.1)
	var c: Array = contents.get("colour", [])
	if c.size() >= 3:
		colour = Color(float(c[0]), float(c[1]), float(c[2]))
	ImpactEffects.burst(host, at, Vector3.UP, colour, 14, 1.4, 0.03)
	Events.liquid_spilled.emit(floor_at, StringName(contents.get("liquid", "water")), litres, self)
	if bool(contents.get("flammable", false)):
		var fire := FireSystem.find(get_tree())
		if fire and int(fire.fire_near(floor_at, 0.6).count) > 0:
			fire.spill(floor_at)
