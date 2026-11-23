class_name SceneHold
extends Node
## A scene that holds its cast (#1050; DESIGN.md "Little acts in the world, not cutscenes"): an act's
## beats are written, the systems carry them out, and they hand back to the systems the moment you
## interfere. One way for every act and mission, not one per scene:
##
## 1. **The cast is held.** Its men's brains (`held`: CivilianBrain, OutlawBrain, CompanionBrain) stop
##    going about their own business, and the scene walks and turns them beat by beat; they still
##    sense, and a held outlaw still squares up to a man drawing on him.
## 2. **A quiet zone round the beat** (`centre`, `radius`). Townsfolk in it still sense and react (look,
##    flinch, back off, gossip later), but their walks are steered off its marks, its chairs and its
##    actors' way (HumanBody.walk_to asks `steer`), a held chair isn't free to them (Seating), an armed
##    man not invited in stops at its edge, and no armed man engages a held actor (OutlawBrain asks
##    `spares`) unless that actor turned on him. Outside it the town carries on as ever.
## 3. **You break it** (`breaks`): your shot (`shot`), your gun drawn (`draw`), your hand or ball on
##    anyone (`hit`: a hit, a shove, a kick), or you on a mark, in a held chair or in an actor's way
##    (`mark`). It lets go within the frame (the signal's own): every man's brain is his own again from
##    where he stands (a man the scene brought in brainless gets one: `brain_for`), what broke it is
##    handed to them (an armed actor you shot at fights you), and `broken` tells the scene to stop
##    driving them. The camera is never taken. A scene whose choices are your interference (the cabin)
##    breaks on nothing and lets go itself (`release`).
##
## Find the live holds with `live` (static: empty, and every hook costs one check, when no scene holds).

signal broken(why: StringName)

## Every kind of interference.
const BREAKS_ALL: Array[StringName] = [&"shot", &"draw", &"hit", &"mark"]
## A mark (and a held chair's seat) is kept clear this far round (m).
const MARK_R := 0.8
## You on a mark or in a held chair this near breaks it (m).
const YOU_ON_MARK := 0.45
## A held actor's way: a man this near ahead of him, while he walks, is in it (m).
const WAY_R := 1.3
const WAY_AHEAD := 2.0
## You in a walking actor's way this near ahead of him (m).
const YOU_IN_WAY := 0.8
## An armed man stops this far outside the zone (m).
const EDGE_GAP := 0.4
## Your shot or drawn gun breaks it from this far beyond the zone (m); a hit on the cast from anywhere.
const REACH := 15.0
## Walking, for a man stood in an actor's way (m/s).
const STEP_ASIDE := 1.2

static var live: Array[SceneHold] = []

## The scene's name (its notes, the bridge's `read hold`).
var label := &""
var cast: Array[HumanBody] = []
var marks: Array[Vector3] = []
var chairs: Array[KitProp] = []
var centre := Vector3.INF
## The zone's centre follows this (a table, an actor) when set.
var follow: Node3D
var radius := 8.0
var breaks: Array[StringName] = BREAKS_ALL.duplicate()
## Armed men not in the cast stop at the zone's edge.
var keep_armed := true
## A townsman stood in a walking actor's way steps aside (off for a scene whose actors walk up to
## other men: the cabin's Joe to Kett).
var make_way := true
## Armed men let in all the same (the scene's own extras).
var invited: Array[Node] = []
## A man the cast brought in without a brain gets one from this when it lets go (man -> Node or null);
## unset: an armed man an OutlawBrain, the rest a CivilianBrain.
var brain_for: Callable
var on := true
## Why it ended: &"" while on, &"done" for the scene's own release, else the break.
var why := &""
var ended_frame := -1
## What broke it: {kind, actor, target, at}.
var breaker := {}
## Men a cast man turned on (his gun on them, a ball at them): they may answer him.
var _turned_on := {}
var _was_held := {}
## Who sat in each held chair as it was held (his own still: Earl at the table): chair -> man.
var _owner := {}


## A scene's hold, a child of `scene` (it goes when the scene does). `opts`: cast, marks, chairs,
## centre, follow, radius, breaks, keep_armed, invited, label.
static func claim(scene: Node, opts := {}) -> SceneHold:
	var h := SceneHold.new()
	h.name = "SceneHold"
	h.label = StringName(opts.get("label", scene.name if scene else &"scene"))
	h.radius = float(opts.get("radius", 8.0))
	h.keep_armed = bool(opts.get("keep_armed", true))
	h.make_way = bool(opts.get("make_way", true))
	if opts.has("breaks"):
		h.breaks.assign(opts.breaks)
	if opts.has("centre"):
		h.centre = opts.centre
	h.follow = opts.get("follow") as Node3D
	for m: Variant in opts.get("marks", []):
		h.marks.append(m)
	for c: Variant in opts.get("chairs", []):
		h.add_chair(c as KitProp)
	for n: Variant in opts.get("invited", []):
		h.invited.append(n)
	if scene:
		scene.add_child(h)
	live.append(h)
	for m: Variant in opts.get("cast", []):
		h.add_cast(m as HumanBody)
	return h


## Every hold that's on (for tests: none left over between them).
static func clear_all() -> void:
	for h: SceneHold in _live():
		h.release(&"cleared")
	live.clear()


func _ready() -> void:
	Events.shot_fired.connect(_on_shot)
	Events.deed.connect(_on_deed)


func _exit_tree() -> void:
	if on:
		release(&"gone")


# --- The cast, the marks, the chairs -------------------------------------------------------------

func add_cast(man: HumanBody) -> void:
	if man == null or not is_instance_valid(man) or man in cast:
		return
	cast.append(man)
	if on:
		_hold_brain(man)


## Out of the cast (his part's done): his brain his own again.
func let_out(man: HumanBody) -> void:
	if man in cast:
		cast.erase(man)
		_free_brain(man)


func add_mark(at: Vector3) -> void:
	marks.append(at)


func set_marks(at: Array) -> void:
	marks.clear()
	for p: Variant in at:
		marks.append(p)


func add_chair(c: KitProp) -> void:
	if c != null and is_instance_valid(c) and not c in chairs:
		chairs.append(c)
		if c.seated != null:
			_owner[c] = c.seated


## Freed men and chairs out of the lists (a typed loop can't hold a freed one).
func _prune() -> void:
	var men: Array[HumanBody] = []
	for m: Variant in cast:
		if is_instance_valid(m):
			men.append(m)
	cast = men
	var cs: Array[KitProp] = []
	for c: Variant in chairs:
		if is_instance_valid(c):
			cs.append(c)
	chairs = cs


func holds(man: Node) -> bool:
	return on and in_cast(man)


## Is this one of its men? (Any node: `in` on the typed cast errors for one that isn't a HumanBody,
## the player among them: #1125, Joe turning on you with the office's hold still on.)
func in_cast(n: Variant) -> bool:
	return n is HumanBody and is_instance_valid(n) and (n as HumanBody) in cast


func zone_centre() -> Vector3:
	if follow != null and is_instance_valid(follow):
		return follow.global_position
	return centre


func in_zone(at: Vector3) -> bool:
	var c := zone_centre()
	return c != Vector3.INF and _flat(at, c) < radius


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _brain(man: Node) -> Node:
	return man.get_node_or_null(^"Brain") if man != null and is_instance_valid(man) else null


func _hold_brain(man: HumanBody) -> void:
	var b := _brain(man)
	if b != null and "held" in b:
		_was_held[man] = b.held
		b.held = true


func _free_brain(man: HumanBody) -> void:
	var b := _brain(man)
	if b != null and "held" in b:
		b.held = bool(_was_held.get(man, false))
	_was_held.erase(man)


# --- Letting go ----------------------------------------------------------------------------------

## The scene's own end (its beat done, or its choices are yours): everyone's own again, no brain
## added, nothing handed on.
func release(reason := &"done") -> void:
	if not on:
		return
	on = false
	why = reason
	ended_frame = Engine.get_physics_frames()
	live.erase(self)
	_prune()
	for man: HumanBody in cast:
		_free_brain(man)


## Broken by you: let go now, brains for the brainless, what you did handed to them, `broken` said.
func break_hold(kind: StringName, actor: Node = null, target: Node = null, at := Vector3.INF) -> void:
	if not on:
		return
	breaker = {"kind": kind, "actor": actor, "target": target, "at": at}
	release(kind)
	for man: HumanBody in cast:
		if not is_instance_valid(man) or not man.physiology.alive:
			continue
		# A held brain took it in as it happened (its senses and signals never stopped); a man the
		# scene brought in brainless gets one now, and what broke it handed to him.
		if _brain(man) == null:
			_hand_on(man, _give_brain(man), kind, actor, target, at)
	broken.emit(kind)


func _give_brain(man: HumanBody) -> Node:
	var b: Node = brain_for.call(man) if brain_for.is_valid() else null
	if b == null:
		if man.has_gun:
			b = OutlawBrain.new()
		else:
			var cb := CivilianBrain.new()
			cb.post = man.global_position
			cb.faces = man.global_position - man.global_basis.z * 2.0
			b = cb
	b.name = "Brain"
	man.add_child(b)
	man.move_child(b, 0)
	man.wake()
	return b


## What broke it, to a man given a brain as it let go: as he'd have taken it. An armed man shot at,
## hit, or with your ball fired near him fights you; a gun drawn is on his ladder; a townsman heard the
## shot (and saw who: he was in the scene) or saw what you did.
func _hand_on(man: HumanBody, b: Node, kind: StringName, actor: Node, target: Node, at: Vector3) -> void:
	if actor == null or not is_instance_valid(actor) or not man.physiology.is_conscious():
		return
	var near := actor is Node3D and (actor as Node3D).global_position.distance_to(man.global_position) < radius + REACH
	if b is OutlawBrain:
		var ob := b as OutlawBrain
		if kind == &"draw":
			ob.relations.perceive(actor, &"draw", man if near else null)
		elif kind in [&"shot", &"hit"] and (target == man or near):
			ob._provoked(actor)
		return
	var cb := b as CivilianBrain
	if cb == null:
		return
	await man.get_tree().physics_frame  # (his Senses go in deferred)
	if not is_instance_valid(cb) or cb.senses == null:
		return
	if kind == &"shot":
		cb._on_heard(at if at != Vector3.INF else (actor as Node3D).global_position, &"gunshot", actor)
	elif kind in [&"hit", &"draw"]:
		cb._on_deed(actor, &"shoot_at" if kind == &"hit" and target == man else kind, target, man.global_position)


# --- What breaks it ------------------------------------------------------------------------------

func _you(n: Node) -> bool:
	return n is Player


func _near_you(p: Node3D) -> bool:
	var c := zone_centre()
	return c != Vector3.INF and _flat(p.global_position, c) < radius + REACH


func _on_shot(origin: Vector3, _dir: Vector3, shooter: Node) -> void:
	if not on:
		return
	if _you(shooter) and &"shot" in breaks and _near_you(shooter as Node3D):
		break_hold(&"shot", shooter, null, origin)


func _on_deed(actor: Node, kind: StringName, target: Node, at: Vector3) -> void:
	if not on:
		return
	if actor is HumanBody and actor in cast:
		if kind in [&"shoot_at", &"hit", &"aim_at", &"kill"] and target != null and not in_cast(target):
			_turned_on[target] = actor
		return
	if not _you(actor):
		return
	if kind == &"draw" and &"draw" in breaks and _near_you(actor as Node3D):
		break_hold(&"draw", actor, target, at)
	elif kind == &"shoot_at" and &"shot" in breaks and (in_cast(target) or _near_you(actor as Node3D)):
		break_hold(&"shot", actor, target, at)  # (DeedWatch's word for your shot, ahead of shot_fired)
	elif kind in [&"hit", &"shove", &"kick", &"kick_down", &"kill"] and &"hit" in breaks \
			and (in_cast(target) or _near_you(actor as Node3D)):
		break_hold(&"hit", actor, target, at)


func _physics_process(delta: float) -> void:
	if not on:
		return
	_prune()
	var p := get_tree().get_first_node_in_group(&"player") as Player
	if p != null and &"mark" in breaks and _you_on_mark(p):
		return
	if make_way:
		_make_way(delta)


## You walking onto a mark, into a held chair, or into a walking actor's way (sat in your own chair at
## the table isn't: the scene put its marks round you).
func _you_on_mark(p: Player) -> bool:
	var seat := p.seat
	if seat != null and seat.seated():
		if seat.chair in chairs:
			break_hold(&"mark", p, seat.chair, p.global_position)
			return true
		return false
	for m: Vector3 in marks:
		if _flat(p.global_position, m) < YOU_ON_MARK:
			break_hold(&"mark", p, null, m)
			return true
	for c: KitProp in chairs:
		if is_instance_valid(c) and _flat(p.global_position, Seating.spot(c)) < YOU_ON_MARK:
			break_hold(&"mark", p, c, p.global_position)
			return true
	for man: HumanBody in cast:
		if man.move_speed > 0.3 and _in_way_of(man, p.global_position, YOU_IN_WAY):
			break_hold(&"mark", p, man, p.global_position)
			return true
	return false


## Is `at` in the way ahead of `man` as he walks (within `r` of his line, less than WAY_AHEAD on)?
static func _in_way_of(man: HumanBody, at: Vector3, r: float) -> bool:
	var fwd := -man.global_basis.z
	fwd.y = 0.0
	if fwd.length() < 0.01:
		return false
	fwd = fwd.normalized()
	var to := at - man.global_position
	to.y = 0.0
	var ahead := to.dot(fwd)
	if ahead < -0.2 or ahead > WAY_AHEAD:
		return false
	return (to - fwd * ahead).length() < r


## A townsman stood in a walking actor's way steps aside (a man going about his chore doesn't walk,
## so his own brain never would): sideways off the actor's line, at a walk. Townsfolk only (a
## CivilianBrain): an outlaw, a companion or a scene's other men are the scene's to place.
func _make_way(delta: float) -> void:
	for man: HumanBody in cast:
		if man.limp or man.move_speed < 0.3:
			continue
		for other: Node in man.get_tree().get_nodes_in_group(&"people"):
			var o := other as HumanBody
			if o == null or o == man or o in cast or o.limp or not o.physiology.is_conscious():
				continue
			if not _brain(o) is CivilianBrain:
				continue
			if o.global_position.distance_to(man.global_position) > WAY_AHEAD + 0.5:
				continue
			if not _in_way_of(man, o.global_position, WAY_R * 0.6):
				continue
			if o.pose in [&"sit", &"sit_back", &"sit_lean"]:
				continue  # sat: he stays sat (a chair's no actor's way)
			var fwd := -man.global_basis.z
			fwd.y = 0.0
			var side := fwd.cross(Vector3.UP).normalized()
			var to := o.global_position - man.global_position
			if to.dot(side) < 0.0:
				side = -side
			o.walk_to(o.global_position + side * 1.0, STEP_ASIDE, delta)


# --- What the townsfolk ask ----------------------------------------------------------------------

## The holds that are on (any freed with their scene dropped: a typed loop can't hold a freed one).
static func _live() -> Array[SceneHold]:
	var out: Array[SceneHold] = []
	for v: Variant in live:
		if is_instance_valid(v) and (v as SceneHold).on:
			out.append(v)
	if out.size() != live.size():
		live = out.duplicate()
	return out


## Where `man` may walk instead of `target`: off the live holds' marks, chairs and actors, and an armed
## man not invited stops outside a zone he isn't in. His own target if nothing holds it.
static func steer(man: HumanBody, target: Vector3) -> Vector3:
	for h: SceneHold in _live():
		if h.on and not man in h.cast:
			h._prune()
			target = h._steer(man, target)
	return target


func _steer(man: HumanBody, target: Vector3) -> Vector3:
	var c := zone_centre()
	if c == Vector3.INF:
		return target
	# Far from it, nothing to do.
	if _flat(man.global_position, c) > radius + 6.0 and _flat(target, c) > radius + 1.0:
		return target
	if keep_armed and _armed(man) and not man in invited and not _turned_on.has(man) \
			and not in_zone(man.global_position) and in_zone(target):
		var out := Vector3(target.x - c.x, 0.0, target.z - c.z)
		var from := Vector3(man.global_position.x - c.x, 0.0, man.global_position.z - c.z)
		var dir := from.normalized() if from.length() > 0.01 else out.normalized()
		var edge := c + dir * (radius + EDGE_GAP)
		edge.y = man.global_position.y
		return edge
	for m: Vector3 in marks:
		target = _off(target, m, MARK_R)
	for ch: KitProp in chairs:
		if is_instance_valid(ch) and ch.seated != man and _owner.get(ch) != man:
			target = _off(target, Seating.spot(ch), MARK_R)
	for a: HumanBody in cast:
		if is_instance_valid(a) and not a.limp:
			target = _off(target, a.global_position, WAY_R * 0.6)
	return target


static func _off(target: Vector3, from: Vector3, r: float) -> Vector3:
	var d := Vector3(target.x - from.x, 0.0, target.z - from.z)
	var l := d.length()
	if l >= r:
		return target
	var dir := d / l if l > 0.01 else Vector3.RIGHT
	var out := from + dir * r
	out.y = target.y
	return out


static func _armed(man: HumanBody) -> bool:
	return man.has_gun or man.held_gun != null


## A held chair isn't free to `man` (Seating): his own if the scene sat him in it.
static func chair_held(chair: KitProp, man: Node = null) -> bool:
	for h: SceneHold in _live():
		if h.on and chair in h.chairs and not (man != null and (h.in_cast(man) or h._owner.get(chair) == man)):
			return true
	return false


## `by` (an armed man) leaves `who` be: who's held by a scene `by` isn't in, and hasn't turned on him.
static func spares(by: Node, who: Node) -> bool:
	for h: SceneHold in _live():
		if h.on and h.in_cast(who) and not h.in_cast(by) and h._turned_on.get(by) != who:
			return true
	return false


## The live holding `man` (null if none).
static func holding(man: Node) -> SceneHold:
	for h: SceneHold in _live():
		if h.on and h.in_cast(man):
			return h
	return null


func report() -> Dictionary:
	return {"label": String(label), "on": on, "why": String(why), "cast": cast.map(func(m: HumanBody) -> String:
			return String(m.person_id) if is_instance_valid(m) else "?"), "marks": marks.size(),
			"chairs": chairs.size(), "radius": radius, "breaks": breaks.map(func(b: StringName) -> String: return String(b))}
