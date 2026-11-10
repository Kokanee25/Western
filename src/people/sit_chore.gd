class_name SitChore
extends RefCounted
## A chore that sits a townsman in his kit chair (CivilianBrain.chores; Seating): the valley's card
## players (ValleyFolk, #756). Free and near it (REACH), he sits (Seating.sit_step: his weight on the
## seat, so a kick takes the chair and him with it, #204); trouble (not free) or sent off (`wanted`
## false), he gets up and it lets him go. Far off, it leaves him to his brain, which walks him back
## to his post (the chair's spot) by the town's places.

## Near his chair's spot (m): from here the chore has him (walked straight in and sat).
const REACH := 2.0
## His own chair gone, a free one this near (m) is his.
const ANOTHER := 2.0

var man: HumanBody
var chair: KitProp
## False: he's to get up and go (ValleyFolk sends him off at the end of his hours).
var wanted := true


func _init(m: HumanBody, c: KitProp) -> void:
	man = m
	chair = c


func busy() -> bool:
	return chair != null and is_instance_valid(chair) and chair.seated == man


## Sat still, his hands his own: he can tick slowly far from you (PeopleTick's bands), unlike a man
## at the bar cloth or the mop.
func lets_slow() -> bool:
	return true


func step_chore(delta: float, free: bool) -> bool:
	if not is_instance_valid(man):
		return false
	if chair == null or not is_instance_valid(chair) or chair.loose:
		# His chair's gone (kicked to pieces): another free one near takes its place (the playtest's
		# Earl stood on the wreck for minutes).
		if not free or not wanted or man.limp:
			return false
		var other := Seating.free_chair_near(man.get_tree(), man.global_position + Vector3.UP * 0.47, ANOTHER)
		if other == null:
			return false
		chair = other
	if not free or not wanted or man.limp:
		if chair.seated == man:
			Seating.stand_up(man, chair)
		return false
	if chair.seated != man:
		var flat := man.global_position - Seating.spot(chair)
		flat.y = 0.0
		if flat.length() > REACH or chair.seated != null:
			return false
	Seating.sit_step(man, chair, delta)
	return true
