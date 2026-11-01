class_name HouseDefence
extends Node
## The men holding the farmhouse fought as one (issue #520, Sean: "make the AI know the house and
## paths fantastically"). The house's tactics are data (its spec's `tactics`: the firing spots, what
## each covers, a plan for each place you might be); this works out where you are from what the
## men know of you, and gives each of them a spot to hold (OutlawBrain.give_order):
##
## - **Outside:** which side you're on (front, back, either end), the windows that side first, then a
##   man on the door you'd come in by, then the rest. They move window to window as you go round.
## - **A breach:** the nearest man (not the guard) to a spot with a clear line on the hole, the rest
##   to that side's plan.
## - **Inside:** the men in the room you're in fight you there (their own cover, OutlawBrain); the
##   rest hold the doorways into it from the next room (room to room: the kitchen's door from behind
##   its table, the stair head from the loft).
## - **The guard** keeps to the bedroom: its door, or its window when you're at that end.
##
## Where you are changes their plan only once it's held a moment (not every glimpse), and a man
## keeps his spot if the new plan has it. One of them calls where you are when it changes.

const PLAN_EVERY := 0.5
## How long (s) a new place for you must hold before the plan changes.
const SETTLE := 1.2
## A man who's lost you this long (s) everywhere doesn't steer the plan (they keep the last one).
const STALE := 20.0

const CALLS := {
	"front": ["Out front! He's out front!", "Front! Watch the front!"],
	"back": ["Round back! Watch the back door!", "He's at the back!"],
	"east": ["He's round the side!", "Side of the house! By the bedroom!"],
	"west": ["West side! Under the window!", "He's round the side, by the stove!"],
	"front_room": ["He's inside! Front room!", "He's in! He's in the house!"],
	"kitchen": ["Kitchen! He's in the kitchen!", "He's come in the back!"],
	"bedroom": ["He's at the old man! Bedroom!", "Bedroom!"],
	"loft": ["He's up in the loft!", "Loft! He's up top!"],
	"breach": ["The wall! Watch the hole!", "He's blowing his way in!"],
}

var brains: Array[OutlawBrain] = []
var guard: OutlawBrain
var player: Player
## The spec's tactics, its spots by id (each with `world` and `look_world` worked out).
var spots := {}
var plans := {}
var guard_plan := {}
var entries := {}
## Where you are as they have it ("front", "kitchen", ...), and since when the latest guess.
var where := ""
var _guess := ""
var _guess_t := 0.0
var _plan_t := 0.0
var _t := 0.0
var _hole := Vector3.INF
var _hole_t := -99.0
var _rng := RandomNumberGenerator.new()
## Who holds which spot: brain -> spot id.
var held := {}


func setup(spec: Dictionary, men: Array[OutlawBrain], the_guard: OutlawBrain, p: Player) -> void:
	brains = men
	guard = the_guard
	player = p
	_rng.seed = 5200
	var tac: Dictionary = spec.get("tactics", {})
	for sp: Dictionary in tac.get("spots", []):
		var floor := Farmhouse.LOFT if sp.room == "loft" else Farmhouse.FLOOR
		var d := sp.duplicate()
		d.world = Farmhouse.at(Vector3(sp.at[0], floor, sp.at[1]))
		d.look_world = Farmhouse.at(Vector3(sp.look[0], floor + float(sp.look[1]), sp.look[2]))
		spots[sp.id] = d
	plans = tac.get("plans", {})
	guard_plan = tac.get("guard", {})
	for k: String in tac.get("entries", {}):
		var e: Array = tac.entries[k]
		entries[k] = Farmhouse.at(Vector3(e[0], Farmhouse.FLOOR, e[1]))


## A blast at the house: a breach where it went off (`at`): a man on the hole.
func breach(at: Vector3) -> void:
	_hole = at
	_hole_t = _t
	_plan_t = 0.0  # now
	_say_where("breach")


func _physics_process(delta: float) -> void:
	_t += delta
	_plan_t -= delta
	if _plan_t > 0.0:
		return
	_plan_t = PLAN_EVERY
	var known := _known_player()
	if known == Vector3.INF:
		return
	var guess := place_of(known)
	if guess != _guess:
		_guess = guess
		_guess_t = _t
	if guess != where and _t - _guess_t >= SETTLE:
		where = guess
		_say_where(where)
	if where == "":
		return
	_plan()


## Where they know you are: the freshest of what each man knows (seen, heard, told); INF if none
## of them has had you for a while.
func _known_player() -> Vector3:
	var best := Vector3.INF
	var best_age := STALE
	for b in brains:
		if not _able(b) or b.senses == null:
			continue
		var age := b.senses.since_known(player)
		if age < best_age:
			var p := b.senses.last_known(player)
			if p != Vector3.INF:
				best = p
				best_age = age
	return best


## The place a point is: a room of the house, or the side of it it's on.
static func place_of(p: Vector3) -> String:
	var l := Farmhouse.origin().affine_inverse() * p
	if FarmhouseMission.inside(p):
		if l.y > Farmhouse.LOFT - 0.6:
			return "loft"
		if l.z > 5.15:
			return "kitchen"
		return "bedroom" if l.x > 5.6 else "front_room"
	var d := Vector2(l.x - 4.5, l.z - 3.8)
	if absf(d.y) * 1.2 > absf(d.x):
		return "front" if d.y < 0.0 else "back"
	return "west" if d.x < 0.0 else "east"


func _able(b: OutlawBrain) -> bool:
	return is_instance_valid(b) and is_instance_valid(b.body) and b.body.physiology.alive and b.body.physiology.is_conscious() \
			and not b.body.limp and b.mood in [OutlawBrain.Mood.FIGHTING, OutlawBrain.Mood.RELOADING]


## Each man his spot for where you are.
func _plan() -> void:
	var free: Array[OutlawBrain] = []
	for b in brains:
		if not _able(b):
			held.erase(b)
			if is_instance_valid(b):
				b.give_order({})
			continue
		if b == guard:
			_guard_order(b)
			continue
		# In the room you're in: his own fight (close, his cover there).
		if where in ["front_room", "kitchen", "bedroom", "loft"] and place_of(b.body.global_position) == where:
			held.erase(b)
			b.give_order({})
			continue
		free.append(b)
	var want: Array = []
	# A fresh breach: a man on the hole first.
	if _hole != Vector3.INF and _t - _hole_t < 25.0 and not where in ["front_room", "kitchen", "bedroom", "loft"]:
		var on_hole := _spot_on(_hole)
		if on_hole != "":
			want.append(on_hole)
	for id in plans.get(where, []):
		if not want.has(id):
			want.append(id)
	# Keep a man on the spot he holds if it's still wanted; then the nearest free man to each.
	var given := {}
	var left: Array[OutlawBrain] = []
	for b in free:
		var id: String = held.get(b, "")
		if id != "" and want.has(id) and not given.has(id):
			given[id] = b
		else:
			left.append(b)
	for id in want:
		if given.has(id) or left.is_empty():
			continue
		var sp: Dictionary = spots.get(id, {})
		if sp.is_empty():
			continue
		var best: OutlawBrain = null
		var best_d := INF
		for b in left:
			var d := b.body.global_position.distance_to(sp.world)
			if d < best_d:
				best = b
				best_d = d
		given[id] = best
		left.erase(best)
	held.clear()
	for id: String in given:
		var b: OutlawBrain = given[id]
		held[b] = id
		b.give_order(_order_for(id))
	for b in left:
		b.give_order({})  # spare: his own cover, in the house


func _guard_order(b: OutlawBrain) -> void:
	if b.menace != null:
		return
	var id: String = guard_plan.get(where, guard_plan.get("default", ""))
	if spots.has(id):
		b.give_order(_order_for(id))


func _order_for(id: String) -> Dictionary:
	var sp: Dictionary = spots[id]
	return {"id": id, "at": sp.world, "look": sp.look_world, "low": sp.get("low", false), "window": sp.get("window", false),
			"why": "%s (you're %s)" % [id.replace("_", " "), where.replace("_", " ")]}


## The spot (not a window, not the guard's) with the best clear line on a hole at `at`: near it
## but not on it, behind low cover if there's one.
func _spot_on(at: Vector3) -> String:
	var space := World.space(self.get_parent() as Node3D) if get_parent() is Node3D else null
	var best := ""
	var best_k := -INF
	for id: String in spots:
		var sp: Dictionary = spots[id]
		if sp.get("window", false) or sp.get("guard", false) or sp.room == "loft":
			continue
		var w: Vector3 = sp.world
		var d := w.distance_to(at)
		if d < 2.0 or d > 8.0:
			continue
		if space != null and Engine.is_in_physics_frame():
			var q := PhysicsRayQueryParameters3D.create(w + Vector3.UP * 1.3, at + Vector3.UP * 0.5, Layers.WORLD)
			var hit := space.intersect_ray(q)
			if not hit.is_empty() and (hit.position as Vector3).distance_to(at) > 1.0:
				continue  # a wall between
		var k := -absf(d - 4.0) + (1.0 if sp.get("low", false) else 0.0)
		if k > best_k:
			best_k = k
			best = id
	return best


## One of them who knows calls where you are (the first time in a while for that place).
func _say_where(place: String) -> void:
	var lines: Array = CALLS.get(place, [])
	if lines.is_empty():
		return
	var speaker: OutlawBrain = null
	for b in brains:
		if _able(b) and b != guard:
			speaker = b
			if b.senses.sees(player):
				break
	if speaker == null:
		return
	Events.spoke.emit(speaker.body, lines[_rng.randi() % lines.size()])
	Events.noise.emit(speaker.body.global_position + Vector3.UP * 1.6, 30.0, &"shout", speaker.body)
