class_name GloveAct
extends Node3D
## A man takes off his long glove (#949; the choreography from the garment handoff's lab, #895,
## experiments/garment_handoff/handoff.gd): the glove (GarmentHandoff, made from his own skin) worn,
## his gloved hand out in front, his other hand to its fingertips, the glove drawn off down his
## fingers and forearm as real cloth (two tugs, his gloved arm drawing back), flicked away from the
## wrist, and left lying where it lands at no cost. The bridge's `glove MAN [toss_to X Y Z]`.
##
## Phases (s from `begin`): present, reach, take, draw, toss (the flick), lie (it falls and drapes),
## rest (its soft body out; his arms down), done. `reach_to` is renewed every tick while his hands
## are in it (a dropped reach drops the arm, and the worn glove would jump with it).

signal finished

## The act's timing and reach (s, m). The flick: a wind-up `flick_back` m back, then `flick_len` m
## out and `flick_lift` up in `flick` s, let go with `flick_speed` m/s out and `flick_up` up added.
var tune := {
	"present": 0.9, "reach_at": 1.0, "reach": 0.9, "take_at": 2.1, "draw_at": 2.25, "draw": 2.6,
	"draw_len": 0.62, "left_back": 0.12, "tug": 0.035, "flick": 0.32, "flick_back": 0.05,
	"flick_len": 0.2, "flick_lift": 0.1, "flick_speed": 1.1, "flick_up": 0.9,
	"end_after_rest": 1.0, "max_seconds": 12.0, "bare_rest_after": 4.5,
}
var man: HumanBody
var part: GarmentHandoff
var glove: WornGarment
## SolverCloth (ours) or GarmentCloth (Jolt's).
var cloth: Node3D
## The gloved arm ("l" or "r"); the other hand takes it off.
var side := "l"
## Where to flick it toward (world): its direction and roughly how hard, not aimed (it lands where
## it lands). INF: out to the side of the hand that takes it, a little forward.
var toss_to := Vector3.INF
var phase := "worn"
var t := 0.0
var started := false
var done := false
## Without the glove (the lab's cost runs): the same hands, nothing on them.
var with_glove := true
## The glove's triangles (simplified to about) and its skin shape's (-1: the part's default).
var tris := 700
var under_tris := -1
## His finer skin's (the hand's vertices kept under the cloth, #1008; -1: the part's default).
var fine_tris := -1
## Over the part's own tune.
var part_tune := {}
## Over the part's `solver_tune` (our cloth's numbers).
var solver_tune := {}
## (Debug: present and reach only, the glove left worn.)
var no_take := false

var phase_at := {}
var rest_at := -1.0

# Where things go (set at present and take).
var _g_at := Vector3.ZERO      # the gloved hand, out in front
var _h_take := Vector3.ZERO    # the other hand, at its fingertips
var _draw_dir := Vector3.ZERO
var _toss_from := Vector3.ZERO
var _flick_dir := Vector3.ZERO
var _rest_t := -1.0


## A long glove on `who`'s arm on `on_side` (made from his own skin) and the act to take it off,
## under `parent`; null if he has no skin to make it from.
static func put_on(who: HumanBody, parent: Node, on_side := "l") -> GloveAct:
	var act := GloveAct.new()
	act.name = "GloveAct_" + on_side
	act.side = on_side
	parent.add_child(act)
	if not bool(act.wear_on(who).get("ok", false)):
		act.queue_free()
		return null
	return act


## His glove made and put on (worn, part of his skinned mesh: nothing a tick).
func wear_on(who: HumanBody) -> Dictionary:
	man = who
	if not with_glove:
		return {"ok": true, "glove": "none"}
	part = GarmentHandoff.glove_on(man, get_parent(), side, null, tris,
			under_tris if under_tris >= 0 else GarmentHandoff.COLLIDER_TRIS,
			fine_tris if fine_tris >= 0 else GarmentHandoff.FINE_TRIS)
	if part == null:
		return {"ok": false, "error": "no Skin_whole on " + String(man.body_model)}
	glove = part.garment
	part.tune.merge(part_tune, true)
	part.solver_tune.merge(solver_tune, true)
	return {"ok": true, "glove": glove.report.duplicate()}


## The hand that takes it off.
func other() -> String:
	return "r" if side == "l" else "l"


## Toward the taking hand's side of him (world).
func _out() -> Vector3:
	return man.global_basis.x * (1.0 if side == "l" else -1.0)


func begin() -> void:
	started = true
	t = 0.0
	_enter("present")
	man.curl_hand(side, 0.0)
	var fwd := -man.global_basis.z
	var sh := (man.pivots[StringName("upper_arm_" + side)] as Node3D).global_position
	# Out in front, a little across toward his other side, a hand below the shoulder; palm down.
	_g_at = sh + fwd * 0.40 + _out() * 0.16 + Vector3.DOWN * 0.20


func _physics_process(delta: float) -> void:
	if not started or done:
		return
	var pt := Prof.start()
	t += delta
	_step(delta)
	Prof.stop(&"glove_handoff", pt)


## (The lab's measures, each tick the cloth is out.)
func _measure() -> void:
	pass


func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _step(_delta: float) -> void:
	var T: Dictionary = tune
	var h := other()
	var g_k := _ease(t / float(T.present))
	var g_at := _g_at
	if phase in ["draw", "toss", "lie", "rest"]:
		# His gloved arm draws back as the glove comes off it.
		g_at = _g_at - _draw_dir * float(T.left_back) * _ease((t - float(T.draw_at)) / float(T.draw))
	var down := phase in ["lie", "rest"]
	if not down:
		man.reach_to(side, g_at, Vector3.UP, g_k)
	elif t - float(phase_at.lie) < 0.6:
		man.reach_to(side, g_at, Vector3.UP, 1.0 - _ease((t - float(phase_at.lie)) / 0.6))
	match phase:
		"present":
			if t >= float(T.reach_at):
				_enter("reach")
		"reach":
			var tips: Vector3 = _tips_now()
			_h_take = tips + _finger_dir() * 0.025 + Vector3.UP * 0.012
			var k := _ease((t - float(T.reach_at)) / float(T.reach))
			man.reach_to(h, _h_take, Vector3.UP, k)
			man.curl_hand(h, 0.2 + 0.35 * k)
			if t >= float(T.take_at) and not no_take:
				_take()
		"take":
			man.reach_to(h, _h_take, Vector3.UP, 1.0)
			_measure()
			if t >= float(T.draw_at):
				_enter("draw")
		"draw":
			var u := (t - float(T.draw_at)) / float(T.draw)
			# Two tugs on the way (a pull and a little give), then one long draw.
			var tug := float(T.tug) * (sin(clampf(u, 0.0, 0.5) * TAU * 2.0)) * (1.0 - _ease(u * 2.0))
			var at := _h_take + _draw_dir * (float(T.draw_len) * _ease(u) + tug)
			man.reach_to(h, at, Vector3.UP, 1.0)
			_measure()
			if u >= 1.0:
				if part:
					part.let_go_of_arm()
				_toss_from = at
				var dir := (toss_to - at) if toss_to.is_finite() else (_out() - man.global_basis.z * 0.4)
				dir.y = 0.0
				_flick_dir = dir.normalized() if dir.length() > 0.01 else _out()
				_enter("toss")
		"toss":
			# The flick from the wrist: a short wind-up back and down, then out and up, let go at
			# its top with a little more than his hand's speed. Not aimed: it lands where it lands.
			var u := (t - float(phase_at.toss)) / float(T.flick)
			var back := _toss_from - _flick_dir * float(T.flick_back) + Vector3.DOWN * 0.03
			var top := _toss_from + _flick_dir * float(T.flick_len) + Vector3.UP * float(T.flick_lift)
			var at := _toss_from.lerp(back, _ease(u / 0.4)) if u < 0.4 else back.lerp(top, _ease((u - 0.4) / 0.6))
			man.reach_to(h, at, Vector3.UP, 1.0)
			_measure()
			if u >= 1.0:
				var speed := float(T.flick_speed)
				if toss_to.is_finite():
					var flat := toss_to - at
					flat.y = 0.0
					speed = clampf(flat.length() * 1.6, 0.6, 3.0)
				if part:
					part.let_go(_flick_dir * speed + Vector3.UP * float(T.flick_up))
				man.curl_hand(h, 0.1)
				_toss_from = at
				_enter("lie")
		"lie":
			if man.can_reach(h, _toss_from):
				man.reach_to(h, _toss_from, Vector3.UP, 1.0 - _ease((t - float(phase_at.lie)) / 0.8))
			_measure()
			var at_rest: bool = cloth.resting if cloth else t - float(phase_at.lie) >= float(T.bare_rest_after)
			if at_rest and _rest_t < 0.0:
				_rest_t = t
				rest_at = t
				_enter("rest")
			elif t >= float(T.max_seconds):
				_finish()
		"rest":
			if t - _rest_t >= float(T.end_after_rest):
				_finish()


func _finish() -> void:
	done = true
	finished.emit()


func _enter(p: String) -> void:
	phase = p
	phase_at[p] = snappedf(t, 0.001)


## The middle of the glove's fingertips as drawn now (world; his own middle fingertip if bare).
func _tips_now() -> Vector3:
	if glove == null:
		var sk: Skeleton3D = man.skeleton
		return sk.global_transform * sk.get_bone_global_pose(sk.find_bone("finger_middle_%s_2" % side)).origin
	var pts: PackedVector3Array = glove.posed()
	var c := Vector3.ZERO
	for i: int in glove.tips:
		c += pts[i]
	return c / maxf(glove.tips.size(), 1)


## Along his gloved hand toward its fingertips (world).
func _finger_dir() -> Vector3:
	var sk: Skeleton3D = man.skeleton
	var wr := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand_" + side)).origin
	var tip := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("finger_middle_%s_2" % side)).origin
	return (tip - wr).normalized()


## The handoff: the worn glove out, the cloth in where it was drawn, its fingertips in his other
## hand, the rest held on his arm by friction until the pull reaches it.
func _take() -> void:
	_draw_dir = (_finger_dir() + _out() * 0.35).normalized()  # out toward his other side
	if part:
		part.take(other())
		cloth = part.cloth
	_enter("take")
