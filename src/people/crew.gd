class_name Crew
extends RefCounted
## What one man knows of his own crew in a fight: who's with him, and what they've shouted or he's
## seen happen to them (reloading, hit, going round, being helped, down, dead, quit). Each gang
## member keeps his own: a man out of earshot doesn't know his friend's empty, and a friend he
## didn't see fall isn't down to him until somebody shouts it. Owned by an OutlawBrain.

## How far a shout carries to him (m), halved through a wall (DeedWatch.SHOUT).
const EARSHOT := DeedWatch.SHOUT
## A flank called this long ago is still going on (s): nobody else goes round meanwhile.
const FLANK_LASTS := 8.0

var me: HumanBody
## Person ids of his friends (OutlawBrain.friends).
var ids: Array[StringName] = []
## kind -> {mate: time he heard it}.
var heard := {}
## Mate -> how he's out of it, as far as this man knows: &"down", &"dead", &"quit", &"fled".
var out := {}
## Wounded mate -> the friend who's said he's getting him out.
var helper := {}
## Every mate he's had with him in this fight (for how thin the gang's getting).
var known := {}
## The gang's thinned out to half: he's taken that in once.
var thinned := false
var _said := {}
var _mates: Array[HumanBody] = []
var _mates_at := -INF


func _init(owner_body: HumanBody = null, friend_ids: Array[StringName] = []) -> void:
	me = owner_body
	ids = friend_ids


func is_mate(who: Node) -> bool:
	return who != me and who is HumanBody and is_instance_valid(who) and ids.has((who as HumanBody).person_id)


## His friends in town right now (looked up once a second).
func mates(now: float) -> Array[HumanBody]:
	if now - _mates_at > 1.0 or _mates.any(func(m: HumanBody) -> bool: return not is_instance_valid(m)):
		_mates_at = now
		_mates.clear()
		if me and me.is_inside_tree() and not ids.is_empty():
			for n in me.get_tree().get_nodes_in_group(&"people"):
				if is_mate(n):
					_mates.append(n as HumanBody)
					known[n] = true
	return _mates


## Friends still on their feet and in it (not down, dead, given up or gone, as far as he knows).
func standing(now: float) -> Array[HumanBody]:
	var out_list: Array[HumanBody] = []
	for m in mates(now):
		if not out.has(m) and m.physiology.is_conscious() and not m.limp and not m.prone:
			out_list.append(m)
	return out_list


## Is any friend near enough to hear him shout?
func any_in_earshot(now: float) -> bool:
	for m in standing(now):
		if m.global_position.distance_to(me.global_position) <= EARSHOT:
			return true
	return false


## Note a callout he heard.
func note(kind: StringName, mate: Node, now: float) -> void:
	if not heard.has(kind):
		heard[kind] = {}
	heard[kind][mate] = now


## Seconds since any mate (or this one) shouted that (INF if never).
func since(kind: StringName, now: float, mate: Node = null) -> float:
	if not heard.has(kind):
		return INF
	var best := INF
	for m in heard[kind]:
		if mate != null and m != mate:
			continue
		best = minf(best, now - float(heard[kind][m]))
	return best


## Is a friend going round on the man right now?
func someone_flanking(now: float) -> bool:
	if not heard.has(&"flank"):
		return false
	for m in heard[&"flank"]:
		if is_instance_valid(m) and not out.has(m) and now - float(heard[&"flank"][m]) < FLANK_LASTS:
			return true
	return false


## Not too often: true (and noted) if he hasn't shouted this in `every` seconds.
func may_say(kind: StringName, now: float, every: float) -> bool:
	if now - float(_said.get(kind, -INF)) < every:
		return false
	_said[kind] = now
	return true


## Note a friend out of it; false if he'd already taken that in.
func mark_out(mate: Node, how: StringName) -> bool:
	if out.get(mate, &"") == how or (out.get(mate, &"") == &"dead"):
		return false
	known[mate] = true
	out[mate] = how
	return true


## How much of the gang (him included) is out of it, as far as he knows (0..1).
func out_share() -> float:
	return float(out.size()) / float(known.size() + 1)


static func leads(mate: Node) -> bool:
	var b := brain_of(mate)
	return b != null and b.leads


static func brain_of(mate: Node) -> OutlawBrain:
	if mate == null or not is_instance_valid(mate):
		return null
	return mate.get_node_or_null(^"Brain") as OutlawBrain


## How a man is named when his friends shout about him.
static func name_of(mate: Node) -> String:
	if mate is HumanBody:
		return String((mate as HumanBody).person_id).capitalize()
	return "him"
