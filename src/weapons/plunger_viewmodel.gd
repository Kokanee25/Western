class_name PlungerViewmodel
extends WeaponViewmodel
## The blasting machine (5): a wooden box with a T-handle, held in both hands (#647, brief
## docs/briefs/dynamite-bundles.md). Period: H. Julius Smith's magneto-electric blasting machine,
## patented 12 March 1878 (US 201,296), sold by Laflin & Rand; push the handle down and it sends the
## current down the wire to every cap.
##
## Sean (#648): "I don't want the tying bundles together to the same plunger to explode at the same
## time to be an ordeal ... it doesn't need to be messy". So there's no wire to lay: every bundle you
## plant is capped and wired to this box as you plant it (DynamiteViewmodel.plant ->
## DynamiteStick.wire). Fire (LMB) held pushes the handle down over `push_time`; at the bottom every
## wired bundle goes off (`DynamiteStick.fire_wired`: the same moment to the eye, each blast on its
## own tick). Let go before the bottom and the handle comes back up: nothing goes.

const HIP_POS := Vector3(0.0, -0.36, -0.42)
const HIP_ROT := Vector3(-8.0, 0.0, 0.0)
const PUT_AWAY_POS := Vector3(0.1, -0.9, 0.0)
## The handle's throw (m): up as it's carried, down at the bottom of the push.
const THROW := 0.14

signal fired(count: int)

## 0 handle up .. 1 pushed home.
var push := 0.0
var box: Node3D
var handle: Node3D
var _bt: BlastTuning
var _sent := false


func _ready() -> void:
	armed = false  # a box isn't a gun to anyone watching (until they know what it is)
	_bt = Blast.t()
	_build()
	_setup_common()
	_pose_pos = HIP_POS
	_pose_rot = HIP_ROT
	_muzzle_local = HIP_POS
	_add_sound(&"close")
	_add_sound(&"break_open")
	_apply_pose(_draw)


func _build() -> void:
	var skin := GunParts.skin()
	var sleeve := GunParts.held_cloth("coat", Color(0.36, 0.25, 0.16))
	var wood := GunParts.material("plunger_box", PixelArt.skin("plunger_box", Color(0.42, 0.29, 0.17), 153), 0.0, 0.85)
	var iron := GunParts.blued()
	var brass := GunParts.material("plunger_brass", PixelArt.skin("plunger_brass", Color(0.74, 0.58, 0.3), 155), 0.6, 0.5)
	box = GunParts.pivot(self, "Box", Vector3.ZERO)
	GunParts.box(box, "Case", Vector3(0.2, 0.22, 0.14), Vector3(0, -0.11, 0), wood)
	GunParts.box(box, "Lid", Vector3(0.21, 0.012, 0.15), Vector3(0, 0.006, 0), wood)
	# The two terminals the leads are screwed to, on the lid's front corners.
	for x in [-0.07, 0.07]:
		GunParts.tube(box, "Post%d" % int(signf(x)), 0.007, 0.02, Vector3(x, 0.02, -0.06), brass, 6, Vector3.ZERO)
	handle = GunParts.pivot(box, "Handle", Vector3(0, THROW, 0))
	GunParts.box(handle, "Rack", Vector3(0.022, 0.2, 0.022), Vector3(0, -0.09, 0), iron)
	GunParts.box(handle, "Bar", Vector3(0.24, 0.026, 0.03), Vector3(0, 0.012, 0), wood)
	# Both fists on the bar's ends.
	for x in [-0.1, 0.1]:
		var fist := GunParts.pivot(handle, "Fist%d" % int(signf(x)), Vector3(x, 0.02, 0))
		GunParts.box(fist, "Fist", Vector3(0.05, 0.045, 0.07), Vector3.ZERO, skin)
		var arm := GunParts.pivot(fist, "Forearm", Vector3(0, -0.01, 0.04))
		arm.rotation_degrees = Vector3(40.0, -20.0 * signf(x), 0.0)
		GunParts.box(arm, "Sleeve", Vector3(0.07, 0.07, 0.28), Vector3(0, 0, 0.16), sleeve)


func _process(delta: float) -> void:
	if _can_act():
		_read_controls(delta)
	_animate(delta)


func _read_controls(delta: float) -> void:
	if hands_busy or arm_disabled:
		push = 0.0
		return
	if Input.is_action_just_pressed(&"holster"):
		drawn = not drawn
	if not drawn or _draw < 0.9:
		push = 0.0
		return
	if Input.is_action_pressed(&"fire") and _action_ok(&"fire"):
		push_down(delta)
	else:
		if push > 0.0 and not _sent:
			_play(&"break_open")  # back up empty-handed
		push = 0.0
		_sent = false


## `dt` s more on the handle; at the bottom (`push_time`) every wired bundle goes. Returns how
## many went (0 until then, or with none wired).
func push_down(dt: float) -> int:
	if _sent:
		return 0
	push = minf(push + dt / maxf(_bt.push_time, 0.01), 1.0)
	if push < 1.0:
		return 0
	_sent = true
	_play(&"close")
	var n := wired_count()
	var tree := get_tree()
	var at := global_position
	# (On the physics tick: a blast's queries are the physics frame's.)
	_in_tick(func() -> void: DynamiteStick.fire_wired(tree, at))
	fired.emit(n)
	if n == 0 and _player and _player.wounds:
		_player.wounds.say("Nothing on the wire.", 2.0)
	return n


## Bundles on the wire now.
func wired_count() -> int:
	return DynamiteStick.bundles_set(get_tree()).filter(func(s: DynamiteStick) -> bool: return s.wired).size()


func _why_not(action: StringName) -> String:
	if action == &"fire" and wired_count() == 0:
		return "no bundle's wired to it"
	return ""


func put_away() -> void:
	push = 0.0
	drawn = false


func take_out() -> void:
	drawn = true


func _animate(delta: float) -> void:
	_draw = move_toward(_draw, 1.0 if drawn else 0.0, delta / 0.4)
	visible = _draw > 0.02
	handle.position.y = THROW * (1.0 - push)
	var k := 1.0 - exp(-delta * 10.0)
	_pose_pos = _pose_pos.lerp(HIP_POS + Vector3(0, -0.04 * push, 0), k)
	_pose_rot = _pose_rot.lerp(HIP_ROT, k)
	tuck = lerpf(tuck, _tuck_target, 1.0 - exp(-delta * 10.0))
	_apply_pose(_draw)
	_animate_camera(delta, _base_fov)


func _apply_pose(drawn_amount: float) -> void:
	var t := smoothstep(0.0, 1.0, tuck)
	position = PUT_AWAY_POS.lerp(_pose_pos.lerp(Vector3(0.05, -0.42, -0.25), t), drawn_amount) + _body_pos() * drawn_amount
	rotation_degrees = _pose_rot + _body_rotation() * drawn_amount
