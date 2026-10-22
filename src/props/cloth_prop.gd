class_name ClothProp
extends Node3D
## A prop that's cloth (the kit's kind "cloth"; docs/briefs/barkeep-rag.md): the barkeep's bar rag.
## One soft body of points (Jolt's, SoftBody3D: checked under 4.7.2, ~0.04 ms a tick at Sean's for
## the rag's 48 points, experiments/barkeep_rag/softbody_probe.gd), so it drapes over a shoulder,
## hangs from a hand and slumps on a bar top by its own physics. Held, the points under the hand
## (or across the shoulder) are pinned and carried where that part of him goes; let go, none are.
## (Under Jolt a pinned point isn't held by the engine: it creeps down, and SoftBody3D's attachment
## never moves it. So each tick this moves its pinned points itself, `soft_body_move_point`.)
##
## A real prop:
## - **dropped** (`let_go`) it falls and lies where it lands; **knocked off** by a blast, a ball
##   through it, a shove at the man wearing it or him going down; **picked up** by anyone's hand
##   (`hold`; the barkeep's chore goes and gets it);
## - **burns:** in flames `catch_seconds` it catches and burns `burn_seconds` as a small fire of its
##   own (FireSystem.small_fire: heats what's under it, scorches who's close, counts as fire), going
##   black from where it caught; then it's gone. Held, it's dropped; water on it puts it out;
## - **bloody:** in a hand pressed on a bleeding wound it takes up `soaks` of what comes out under
##   it (HumanBody.wound_under_hand), red where his palm is, up to `holds_ml`.
## Its look is a texture painted in code (linen, stains, a frayed hem); the texture factory's
## `bar_cloth` takes its place once there is one (painting it waits on Sean's OK of the cost).

signal caught_fire
signal burnt_away

enum Held { FREE, HAND, SHOULDER }

const CHECK_EVERY := 0.25
## A rag's own fire is found this near its middle (m).
const FLAME_FOUND := 0.18
## Pressing on it with a hand: points this near the palm are gripped (m; the kit's grip_radius).
const GRIP_MIN := 2
## Laid over a shoulder, it's held there by its middle: this many points square (the rest drapes).
const SHOULDER_ROWS := 2
## A ball within this of its middle goes through it (m), pushing it on with this much (N s).
const SHOT_REACH := 0.16
const SHOT_PUSH := 0.012
## A blast pushes it as a sheet this many m² (it catches the air), and off a man past this (m/s).
const KNOCK_OFF := 1.0
## Let go, the hands that had it stay out of it this long (s).
const HANDS_CLEAR := 0.6
## The colour of blood soaked into linen, and of linen charred.
const BLOOD := Color(0.36, 0.05, 0.04)
const CHAR := Color(0.08, 0.06, 0.05)

var kit_id := &"bar_cloth"
var definition := {}
var soft: SoftBody3D
var cols := 8
var rows := 6
var size := Vector2(0.4, 0.3)
var held := Held.FREE
## Who has it (HAND or SHOULDER) and by which side ("r"/"l").
var holder: HumanBody
var side := ""
var burning := false
var burnt := false
var wet := 0.0
## Blood in it (ml).
var blood_ml := 0.0
var rng_seed := 7

var _uv: PackedVector2Array
var _rest: PackedVector3Array
## The pinned points: [index, the node carrying it, where it is in that node's frame].
var _pins: Array = []
var _image: Image
var _tex: ImageTexture
var _tex_dirty := false
var _check_t := 0.0
var _heat_t := 0.0
var _burn_t := 0.0
var _caught_at := Vector2.ZERO
var _flame: Dictionary = {}
var _solid_again: Variant
var _wick: FastNoiseLite
var _solid_in := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	if definition.is_empty():
		definition = PropKit.definition(kit_id)
	add_to_group(&"cloth_props")
	_rng.seed = rng_seed
	var sz: Array = definition.get("size", [0.4, 0.3])
	size = Vector2(sz[0], sz[1])
	var pts: Array = definition.get("points", [8, 6])
	cols = int(pts[0])
	rows = int(pts[1])
	_build()
	Events.bullet_hit.connect(_on_bullet_hit)
	Events.exploded.connect(_on_exploded)
	Events.doused.connect(_on_doused)
	Events.deed.connect(_on_deed)
	_check_t = _rng.randf() * CHECK_EVERY


func _build() -> void:
	soft = SoftBody3D.new()
	soft.name = "Cloth"
	soft.mesh = _grid_mesh()
	soft.total_mass = float(definition.get("mass", 0.035))
	soft.linear_stiffness = float(definition.get("stiffness", 0.6))
	soft.damping_coefficient = float(definition.get("damping", 0.04))
	soft.simulation_precision = int(definition.get("precision", 5))
	# Nothing finds it (no ball, no ray, no walker): it lies on the world and on people.
	soft.collision_layer = 0
	soft.collision_mask = Layers.WORLD | Layers.BODY_PARTS | Layers.DEBRIS
	soft.ray_pickable = false
	soft.material_override = _material()
	soft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(soft)


## Laid flat, its length along X and its breadth along Z, about the node's origin; UVs in metres
## (as the game's textures are laid).
func _grid_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	_rest = PackedVector3Array()
	var normals := PackedVector3Array()
	_uv = PackedVector2Array()
	for j in rows:
		for i in cols:
			var u := size.x * i / float(cols - 1)
			var v := size.y * j / float(rows - 1)
			verts.append(Vector3(u - size.x * 0.5, 0.0, v - size.y * 0.5))
			_rest.append(verts[verts.size() - 1])
			normals.append(Vector3.UP)
			_uv.append(Vector2(u, v))
	var idx := PackedInt32Array()
	for j in rows - 1:
		for i in cols - 1:
			var a := j * cols + i
			idx.append_array([a, a + 1, a + cols, a + 1, a + cols + 1, a + cols])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = _uv
	arrays[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


func _material() -> StandardMaterial3D:
	var factory := PixelArt.factory("bar_cloth")
	_image = factory.get_image() if factory else paint(definition, rng_seed)
	if _image.is_compressed():
		_image.decompress()
	_image.convert(Image.FORMAT_RGBA8)
	_tex = ImageTexture.create_from_image(_image)
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.cull_mode = BaseMaterial3D.CULL_DISABLED  # a single sheet, seen from both sides
	m.roughness = 1.0
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.uv1_scale = Vector3(1.0 / size.x, 1.0 / size.y, 1.0)  # UVs are in metres
	return m


## The rag painted in code: off-white linen in its weave, grey-brown stains of beer and grease, a
## frayed hem a shade darker. `texels` a metre (the close props' hand, 240-256).
static func paint(def: Dictionary, seed_value: int) -> Image:
	var sz: Array = def.get("size", [0.4, 0.3])
	var texels := float(def.get("texels", 240))
	var w := maxi(int(round(float(sz[0]) * texels)), 8)
	var h := maxi(int(round(float(sz[1]) * texels)), 8)
	var c: Array = def.get("colour", [0.86, 0.83, 0.75])
	var base := Color(c[0], c[1], c[2])
	var st: Array = def.get("stains", [0.52, 0.45, 0.34])
	var stain := Color(st[0], st[1], st[2])
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.06
	var blot := FastNoiseLite.new()
	blot.seed = seed_value + 1
	blot.frequency = 0.035
	blot.fractal_octaves = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for y in h:
		for x in w:
			# The weave: alternate threads a touch lighter and darker, the cloth's own unevenness.
			var weave := 0.035 if (x + y) % 2 == 0 else -0.035
			var col := base.lightened(weave) if weave > 0.0 else base.darkened(-weave)
			col = col.darkened(0.08 * (noise.get_noise_2d(x, y) * 0.5 + 0.5))
			var s := blot.get_noise_2d(x, y)
			if s > 0.18:
				col = col.lerp(stain, clampf((s - 0.18) * 3.0, 0.0, 0.55))
			var edge := mini(mini(x, w - 1 - x), mini(y, h - 1 - y))
			if edge < 2:
				col = col.darkened(0.12 if edge == 0 else 0.06)  # the hem
				if edge == 0 and rng.randf() < 0.25:
					col = col.darkened(0.2)  # frayed
			img.set_pixel(x, y, col)
	# A few grease spots.
	for i in 5:
		var px := rng.randi_range(4, w - 5)
		var py := rng.randi_range(4, h - 5)
		var r := rng.randi_range(1, 3)
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if dx * dx + dy * dy <= r * r:
					img.set_pixel(px + dx, py + dy, img.get_pixel(px + dx, py + dy).lerp(stain.darkened(0.3), 0.45))
	return img


# --- Where it is ---------------------------------------------------------------------------------

func point_count() -> int:
	return cols * rows


func point(i: int) -> Vector3:
	return soft.get_point_transform(i)


## Its middle (the mean of its points).
func centre() -> Vector3:
	var sum := Vector3.ZERO
	var n := point_count()
	for i in n:
		sum += soft.get_point_transform(i)
	return sum / n


## The point nearest `at`, and the point at its own middle (where a hand takes it to fold it over
## a shoulder).
func nearest_point(at: Vector3) -> int:
	var best := 0
	var best_d := INF
	for i in point_count():
		var d := soft.get_point_transform(i).distance_squared_to(at)
		if d < best_d:
			best_d = d
			best = i
	return best


func middle_point() -> int:
	return (rows / 2) * cols + cols / 2


## Its lowest and highest point (y).
func height_range() -> Vector2:
	var lo := INF
	var hi := -INF
	for i in point_count():
		var y := soft.get_point_transform(i).y
		lo = minf(lo, y)
		hi = maxf(hi, y)
	return Vector2(lo, hi)


## Lays it flat as made at `xf` (world), wherever it was.
func place(xf: Transform3D) -> void:
	if not soft.is_inside_tree():
		transform = xf
		return
	var rid := soft.get_physics_rid()
	for i in point_count():
		PhysicsServer3D.soft_body_move_point(rid, i, xf * _rest[i])


# --- Held, hung, let go ----------------------------------------------------------------------------

## In `by`'s hand on `hand_side`: the points within the grip of his palm (at least GRIP_MIN, the
## nearest) go where the hand goes. Whoever had it lets go.
func hold(by: HumanBody, hand_side: String) -> void:
	if burnt or by == null:
		return
	var hand := by.parts.get(StringName("hand_" + hand_side)) as Node3D
	if hand == null:
		return
	var at := by.palm(hand_side)
	var reach := float(definition.get("grip_radius", 0.055))
	var take: Array[int] = []
	for i in point_count():
		if soft.get_point_transform(i).distance_to(at) <= reach:
			take.append(i)
	if take.size() < GRIP_MIN:
		take = _nearest(at, GRIP_MIN)
	_release_all()
	_pin(take, hand)
	_take_holder(by)
	held = Held.HAND
	side = hand_side


## Over `by`'s shoulder on `shoulder_side`: if it's in his hand there, the points he holds are laid
## on the shoulder where they are; otherwise (put there at the start) it's laid flat across it,
## its length front to back, and its middle band pinned on top. Either way his chest carries it.
func hang_on(by: HumanBody, shoulder_side: String) -> void:
	if burnt or by == null:
		return
	var chest := by.parts.get(&"chest") as Node3D
	if chest == null:
		return
	var take: Array[int] = []
	if held == Held.HAND and holder == by:
		take = pinned_points()
	else:
		_release_all()
		place(shoulder_xf(by, shoulder_side))
		var mid := cols / 2
		var mid_j := rows / 2
		for j in range(mid_j - SHOULDER_ROWS / 2, mid_j + SHOULDER_ROWS / 2):
			for i in range(mid - SHOULDER_ROWS / 2, mid + SHOULDER_ROWS / 2):
				take.append(j * cols + i)
	_release_all()
	_pin(take, chest)
	_take_holder(by)
	held = Held.SHOULDER
	side = shoulder_side


## On top of his shoulder (world), where a rag over it lies: above the joint, in toward his neck.
static func shoulder_top(by: HumanBody, shoulder_side: String) -> Vector3:
	var joint := (by.pivots[StringName("upper_arm_" + shoulder_side)] as Node3D).global_position
	var neck := (by.pivots[&"neck"] as Node3D).global_position
	var at := joint.lerp(Vector3(neck.x, joint.y, neck.z), 0.35)
	return at + Vector3.UP * 0.075


## The rag laid flat over his shoulder: its length (X) along his front-to-back, a little over.
static func shoulder_xf(by: HumanBody, shoulder_side: String) -> Transform3D:
	var fwd := -by.global_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var b := Basis(fwd, Vector3.UP, fwd.cross(Vector3.UP).normalized() * -1.0)
	return Transform3D(b.orthonormalized(), shoulder_top(by, shoulder_side) + Vector3.UP * 0.01)


## Let go: nothing holds it, it falls (with `velocity`, m/s).
func let_go(velocity := Vector3.ZERO) -> void:
	_release_all()
	var was: Variant = holder
	var was_side := side
	var was_held := held
	# His hands pass through it a moment longer: let go under his palm, the palm would trap it.
	_solid_again = holder if is_instance_valid(holder) else null
	_solid_in = HANDS_CLEAR
	holder = null
	side = ""
	held = Held.FREE
	if is_instance_valid(was) and was_held == Held.HAND:
		(was as HumanBody).curl_hand(was_side, 0.15)
	if velocity != Vector3.ZERO:
		soft.apply_central_impulse(velocity * soft.total_mass)


## Knocked: off whoever has it, with this push (N s).
func knock(impulse: Vector3) -> void:
	let_go()
	soft.apply_central_impulse(impulse)


func _take_holder(by: HumanBody) -> void:
	if holder != null and holder != by and is_instance_valid(holder) and held == Held.HAND:
		holder.curl_hand(side, 0.15)
	if holder != by:
		_hands_through(holder, false)
		_hands_through(by, true)
	if _solid_again == by:
		_solid_again = null
		_solid_in = 0.0
	holder = by


## His hands and forearms pass through the cloth he has (pressing it on the bar, they'd squeeze
## its free points out through the top: a point flung a metre in a tick and back).
func _hands_through(who: Variant, through: bool) -> void:
	if not is_instance_valid(who) or not who is HumanBody:
		return
	for sid in [&"hand_r", &"hand_l", &"forearm_r", &"forearm_l"]:
		var got: Variant = who.parts.get(sid)
		if not is_instance_valid(got):
			continue
		var part := got as PhysicsBody3D
		if through:
			soft.add_collision_exception_with(part)
		else:
			soft.remove_collision_exception_with(part)


func _pin(points: Array[int], to: Node3D) -> void:
	var inv := to.global_transform.affine_inverse()
	_pins.clear()
	for i in points:
		soft.set_point_pinned(i, true)
		_pins.append([i, to, inv * soft.get_point_transform(i)])


func _release_all() -> void:
	for p: Array in _pins:
		soft.set_point_pinned(int(p[0]), false)
	_pins.clear()


## The pinned points carried to where their part of him is now.
func _carry_pins() -> void:
	var rid := soft.get_physics_rid()
	for p: Array in _pins:
		if is_instance_valid(p[1]):
			PhysicsServer3D.soft_body_move_point(rid, int(p[0]), (p[1] as Node3D).global_transform * (p[2] as Vector3))


func _nearest(at: Vector3, n: int) -> Array[int]:
	var order: Array = []
	for i in point_count():
		order.append([soft.get_point_transform(i).distance_squared_to(at), i])
	order.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var out: Array[int] = []
	for k in mini(n, order.size()):
		out.append(int(order[k][1]))
	return out


## The points he holds (pinned), for the deed's eyes and the lab.
func pinned_points() -> Array[int]:
	var out: Array[int] = []
	for p: Array in _pins:
		out.append(int(p[0]))
	return out


# --- What happens to it ----------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var t := Prof.start()
	_physics_step(delta)
	Prof.stop(&"cloth", t)


func _physics_step(delta: float) -> void:
	if burnt:
		return
	if holder != null and (not is_instance_valid(holder) or holder.limp or holder.prone):
		let_go()  # he's gone down (or gone): it comes off him
	if not _pins.is_empty():
		_carry_pins()
	if _solid_in > 0.0:
		_solid_in -= delta
		if _solid_in <= 0.0 and (not is_instance_valid(_solid_again) or _solid_again != holder):
			_hands_through(_solid_again, false)
			_solid_again = null
	_check_t -= delta
	if _check_t > 0.0:
		return
	_check_t = CHECK_EVERY
	var at := centre()
	_fire_step(at, CHECK_EVERY)
	_blood_step(CHECK_EVERY)
	wet = maxf(wet - CHECK_EVERY / 600.0, 0.0)  # dries over ten minutes
	if _tex_dirty:
		_tex_dirty = false
		_tex.update(_image)


func _fire_step(at: Vector3, dt: float) -> void:
	var fire := FireSystem.find(get_tree())
	if burning:
		_burn_t += dt
		if fire != null and not _flame.is_empty():
			fire.move_small_fire(_flame, at)
		_char(_burn_t / float(definition.get("burn_seconds", 35.0)))
		if holder != null:
			let_go()  # nobody holds a burning rag
		if _burn_t >= float(definition.get("burn_seconds", 35.0)):
			_burn_away()
		return
	if fire == null or (fire.active.is_empty() and fire.spills.is_empty()):
		_heat_t = 0.0
		return
	if int(fire.fire_near(at, FLAME_FOUND).count) > 0:
		_heat_t += dt * (0.25 if wet > 0.0 else 1.0)  # a wet rag has to dry first
		if _heat_t >= float(definition.get("catch_seconds", 2.0)):
			ignite()
	else:
		_heat_t = maxf(_heat_t - dt, 0.0)


## It catches: its own small fire, which goes where it goes.
func ignite() -> void:
	if burning or burnt:
		return
	burning = true
	_burn_t = 0.0
	wet = 0.0
	var at := centre()
	_caught_at = _uv[nearest_point(at)] if not _uv.is_empty() else size * 0.5
	var fire := FireSystem.find(get_tree())
	if fire:
		_flame = fire.small_fire(at, float(definition.get("flame_radius", 0.14)),
				float(definition.get("burn_seconds", 35.0)) + 5.0, float(definition.get("flame_heating", 0.6)))
	caught_fire.emit()


func _burn_away() -> void:
	burning = false
	burnt = true
	var fire := FireSystem.find(get_tree())
	if fire and not _flame.is_empty():
		fire.end_small_fire(_flame)
	_flame = {}
	let_go()
	soft.visible = false
	soft.process_mode = Node.PROCESS_MODE_DISABLED
	soft.collision_mask = 0
	burnt_away.emit()


## Black spreading out from where it caught, `k` of the way through burning.
func _char(k: float) -> void:
	var w := _image.get_width()
	var h := _image.get_height()
	var from := Vector2(_caught_at.x / size.x * w, _caught_at.y / size.y * h)
	var reach := clampf(k * 1.3, 0.0, 1.3) * Vector2(w, h).length()
	for y in h:
		for x in w:
			var d := Vector2(x, y).distance_to(from)
			if d < reach:
				var c := _image.get_pixel(x, y)
				_image.set_pixel(x, y, c.lerp(CHAR, clampf((reach - d) / 6.0, 0.0, 1.0) * 0.6))
	_tex_dirty = true


func _blood_step(dt: float) -> void:
	if held != Held.HAND or holder == null or blood_ml >= float(definition.get("holds_ml", 120.0)):
		return
	var flow := holder.wound_under_hand(side)
	if flow <= 0.0:
		return
	soak(flow * float(definition.get("soaks", 0.8)) * dt, holder.palm(side))


## Takes up `ml` of blood where it touches `at` (world): red there, spreading as it fills.
func soak(ml: float, at: Vector3) -> void:
	if ml <= 0.0 or burnt:
		return
	blood_ml = minf(blood_ml + ml, float(definition.get("holds_ml", 120.0)))
	var uv := _uv[nearest_point(at)]
	var w := _image.get_width()
	var h := _image.get_height()
	var c := Vector2(uv.x / size.x * w, uv.y / size.y * h)
	# The stain's radius grows with what's in it: ~5 ml wets a palm's width of linen.
	var r := clampf(sqrt(blood_ml / 5.0) * 6.0, 2.0, maxf(w, h) * 0.6)
	var x0 := maxi(int(c.x - r) - 1, 0)
	var x1 := mini(int(c.x + r) + 1, w - 1)
	var y0 := maxi(int(c.y - r) - 1, 0)
	var y1 := mini(int(c.y + r) + 1, h - 1)
	if _wick == null:
		_wick = FastNoiseLite.new()
		_wick.seed = rng_seed + 3
		_wick.frequency = 0.22
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			# Blood wicks out along the threads unevenly: the stain's edge wanders.
			var d := Vector2(x, y).distance_to(c) / (r * (0.5 + 0.9 * (_wick.get_noise_2d(x, y) * 0.5 + 0.5)))
			if d < 1.0:
				var a := clampf((1.0 - d) * 1.6, 0.0, 0.9)
				_image.set_pixel(x, y, _image.get_pixel(x, y).lerp(BLOOD, a))
	_tex_dirty = true


## How red it is (0..1: the share of its texels mostly blood).
func bloodiness() -> float:
	var n := 0
	var w := _image.get_width()
	var h := _image.get_height()
	for y in h:
		for x in w:
			var c := _image.get_pixel(x, y)
			if c.r > c.g * 2.2 and c.r > c.b * 2.0:
				n += 1
	return float(n) / float(w * h)


func _on_bullet_hit(info: Dictionary) -> void:
	if burnt:
		return
	var hit: Vector3 = info.get("position", Vector3.INF)
	var dir: Vector3 = info.get("direction", Vector3.ZERO)
	if hit == Vector3.INF or dir == Vector3.ZERO:
		return
	var at := centre()
	# The ball's last metre and a half before what it struck: did it pass through the rag?
	var from := hit - dir.normalized() * 1.5
	var on := Geometry3D.get_closest_point_to_segment(at, from, hit)
	if on.distance_to(at) > SHOT_REACH:
		return
	if held == Held.FREE:
		soft.apply_impulse(nearest_point(on), dir.normalized() * SHOT_PUSH * 3.0)
		soft.apply_central_impulse(dir.normalized() * SHOT_PUSH)
	else:
		knock(dir.normalized() * SHOT_PUSH)


func _on_exploded(at: Vector3, kg: float) -> void:
	if burnt or not is_inside_tree():
		return
	var c := centre()
	var r := maxf(c.distance_to(at), 0.05)
	if r > Blast.reach(kg) + 2.0:
		return
	var shield := Blast.shielding(self, at, c, [])
	var area := size.x * size.y
	var mass := soft.total_mass
	var away := (c - at).normalized()
	var v := (away + Vector3.UP * 0.3).normalized() * Blast.impulse(kg, r) * area * shield / mass
	if v.length() > Blast.t().max_throw:
		v = v.normalized() * Blast.t().max_throw
	if held != Held.FREE and v.length() < KNOCK_OFF:
		return
	knock(v * mass)


func _on_doused(at: Vector3, litres: float, _put_out: int) -> void:
	if burnt or litres <= 0.0:
		return
	var c := centre()
	if c.distance_to(at) > 1.2:
		return
	wet += litres
	if burning:
		burning = false
		var fire := FireSystem.find(get_tree())
		if fire and not _flame.is_empty():
			fire.end_small_fire(_flame)
		_flame = {}


## A shove at the man wearing it over his shoulder knocks it off.
func _on_deed(_actor: Node, kind: StringName, target: Node, _at: Vector3) -> void:
	if kind == &"shove" and target == holder and held == Held.SHOULDER and holder != null:
		knock((-holder.global_basis.z + Vector3.UP * 0.5) * soft.total_mass * 1.5)


func _exit_tree() -> void:
	if burning:
		var fire := FireSystem.find(get_tree())
		if fire and not _flame.is_empty():
			fire.end_small_fire(_flame)
		_flame = {}
