class_name Relations
extends RefCounted
## How one person stands towards everyone else, built only from what they've done that he saw or
## heard (Events.deed). No "enemy" flag: every man starts at nothing, and a fight happens between
## particular people because of particular deeds. Each other person gets:
##   pressure  how provoked he is by them right now (rises with deeds, settles when they stop)
##   grudge    what stays after (a man who shot at him isn't forgiven for holstering)
##   fear      how dangerous they seem
##   stance    the rung of the ladder: IGNORE, NOTICE, WARY, WARNING, THREAT, FIGHT
## The ladder climbs one rung at a time (so each step can be read and answered) except when he's
## shot at or hit, and steps back down when the other man stops. What provokes him depends on him:
## `temper` scales the small things (a stare, crowding him, a drawn gun); the big ones (a gun
## pointed at him, a shot) move anyone.

enum Stance { IGNORE, NOTICE, WARY, WARNING, THREAT, FIGHT }

## Pressure needed for each rung.
const RUNG := [0.0, 0.05, 0.3, 0.6, 1.0, 2.0]
## Seconds between rungs going up, and how long below a rung before stepping down.
const CLIMB_EVERY := 0.8
const STEP_DOWN_AFTER := 2.5
## Pressure settling per second: while they carry on, and once they've stopped threatening.
const SETTLE := 0.04
const SETTLE_CALM := 0.25
## Grudge fading per second (a shot at him takes the best part of an hour to forget).
const GRUDGE_FADE := 0.0005

## What each deed is worth (pressure) when done to him, to a friend of his, or near him to someone
## else. Per second for the continuous ones (aim_at, crowd, stare).
const WEIGHTS := {
	&"draw": [0.5, 0.4, 0.25],
	&"holster": [-0.3, -0.2, -0.1],
	&"aim_at": [0.45, 0.35, 0.05],
	&"shout": [0.4, 0.2, 0.05],
	&"crowd": [0.25, 0.0, 0.0],
	&"stare": [0.12, 0.0, 0.0],
	&"shoot_at": [INF, 2.5, 0.35],
	&"hit": [INF, INF, 0.5],
	&"kill": [INF, INF, 0.8],
	&"surrender": [-1.5, -0.8, -0.3],
	# Hands laid on someone: a shove, a grab at the collar.
	&"shove": [0.8, 0.3, 0.05],
	# "You! Step out into the street!"
	&"call_out": [0.35, 0.1, 0.0],
}
## Deeds that stop counting for much once he's backed down to that man (he's letting it go).
const COWED_BY := [&"aim_at", &"draw", &"shout", &"crowd", &"stare"]
## Deeds that are small only a hothead minds (scaled by temper); the rest move anyone.
const PETTY := [&"crowd", &"stare", &"draw"]

var me: Node
## 0 cool (a professional) .. 1 hothead.
var temper := 0.5
var friends: Array[StringName] = []
var entries := {}  ## Node -> {pressure, grudge, fear, stance, below (s), climb (s), last (s)}


func _init(owner_node: Node = null, temper_value := 0.5) -> void:
	me = owner_node
	temper = temper_value


func entry(who: Node) -> Dictionary:
	if not entries.has(who):
		entries[who] = {"pressure": 0.0, "grudge": 0.0, "fear": 0.0, "stance": Stance.IGNORE,
				"below": 0.0, "climb": 0.0, "last": 0.0, "armed": false, "aiming": 0.0, "cowed": false}
	return entries[who]


func stance(who: Node) -> Stance:
	return entries[who].stance if entries.has(who) else Stance.IGNORE


## Is that man pointing a gun at him right now (as far as he's seen)?
func aiming_at_me(who: Node) -> bool:
	return entries.has(who) and entries[who].aiming > 0.0


## A deed he perceived. `target` is who it was done to.
func perceive(actor: Node, kind: StringName, target: Node, dt := 1.0) -> void:
	if actor == null or actor == me or not WEIGHTS.has(kind):
		return
	if _is_friend(actor) and target != me:
		return  # his friends' business with other people is their business
	var e := entry(actor)
	var w: Array = WEIGHTS[kind]
	var weight: float = w[0] if target == me else (w[1] if _is_friend(target) else w[2])
	if kind in PETTY:
		weight *= lerpf(0.25, 1.6, temper)
	if e.cowed and kind in COWED_BY:
		weight *= 0.1
	match kind:
		&"draw":
			e.armed = true
		&"holster":
			e.armed = false
			e.aiming = 0.0
		&"aim_at":
			e.armed = true
			if target == me:
				e.aiming = 0.6  # seconds: the aim deeds come a few times a second
				if e.stance >= Stance.THREAT:
					# Guns on each other: a standoff, and how long he stands it depends on him.
					weight *= 0.25 * lerpf(0.5, 1.5, temper)
			weight *= dt
		&"crowd", &"stare":
			weight *= dt
	if weight == INF:
		e.pressure = maxf(e.pressure, RUNG[Stance.FIGHT] + 0.5)
		e.grudge = maxf(e.grudge, 1.5 if target == me else 1.0)
		e.fear += 0.3
		e.stance = Stance.FIGHT
		e.climb = CLIMB_EVERY
		return
	e.pressure = maxf(e.pressure + weight, 0.0)
	if kind in [&"shoot_at", &"hit", &"kill"]:
		e.fear += 0.15
		e.grudge = maxf(e.grudge, 0.4)
	if target == me and kind == &"aim_at":
		e.fear += 0.05 * dt


## He's been shot at by them (or it's otherwise come to it): straight to a fight.
func provoke(who: Node) -> void:
	perceive(who, &"shoot_at", me)


## He's backed down to that man: the ladder steps back down (and stays down unless it comes to
## more than a gun on him), and it rankles.
func back_down(who: Node) -> void:
	var e := entry(who)
	e.cowed = true
	e.grudge = maxf(e.grudge, 0.5)
	e.pressure = RUNG[Stance.WARY]
	e.stance = mini(e.stance, Stance.WARY)
	e.below = 0.0


## Squared up to him again (calling him out): no longer letting it go.
func uncow(who: Node) -> void:
	if entries.has(who):
		entries[who].cowed = false


func _is_friend(who: Node) -> bool:
	return who is HumanBody and friends.has((who as HumanBody).person_id)


## Time passing: pressure settles (faster when they've put the gun away), the ladder steps.
func tick(delta: float) -> void:
	for who in entries.keys():
		if not is_instance_valid(who):
			entries.erase(who)
			continue
		var e: Dictionary = entries[who]
		var calm: bool = not e.armed and e.aiming <= 0.0
		e.pressure = maxf(e.pressure - (SETTLE_CALM if calm else SETTLE) * delta, e.grudge)
		e.aiming = maxf(e.aiming - delta, 0.0)
		# Grudges fade, slowly.
		e.grudge = maxf(e.grudge - GRUDGE_FADE * delta, 0.0)
		e.fear = maxf(e.fear - 0.01 * delta, 0.0)
		e.climb = maxf(e.climb - delta, 0.0)
		var want := _rung_for(e.pressure)
		if e.cowed and want < Stance.FIGHT:
			want = Stance.WARY if want > Stance.WARY else want  # he's letting it go
		if want > e.stance and e.climb <= 0.0:
			e.stance += 1
			e.climb = CLIMB_EVERY
			e.below = 0.0
		elif want < e.stance and e.stance != Stance.FIGHT:
			e.below += delta
			if e.below >= STEP_DOWN_AFTER:
				e.stance -= 1
				e.below = 0.0
		else:
			e.below = 0.0


static func _rung_for(p: float) -> Stance:
	var s := Stance.IGNORE
	for i in RUNG.size():
		if p >= RUNG[i] and i > 0:
			s = i as Stance
	return s


## The man he's most worked up about (and how), or null.
func focus() -> Node:
	var best: Node = null
	var best_s := -1
	var best_p := -1.0
	for who in entries:
		if not is_instance_valid(who):
			continue
		var e: Dictionary = entries[who]
		if e.stance > best_s or (e.stance == best_s and e.pressure > best_p):
			best = who
			best_s = e.stance
			best_p = e.pressure
	return best if best_s > Stance.IGNORE else null


## Out of the fight with someone (they're gone, down, or he's lost them): back to watching them,
## with the grudge holding him at wary.
func stand_down(who: Node) -> void:
	if not entries.has(who):
		return
	var e: Dictionary = entries[who]
	e.stance = Stance.WARY if e.grudge > 0.0 else Stance.NOTICE
	e.pressure = minf(e.pressure, RUNG[Stance.WARY] + e.grudge * 0.2)
	e.grudge = minf(e.grudge, 0.3)
	e.below = 0.0


func to_dict() -> Dictionary:
	var out := {}
	for who in entries:
		if is_instance_valid(who):
			var key := String((who as HumanBody).person_id) if who is HumanBody else ("player" if who is Player else str(who.name))
			var e: Dictionary = entries[who]
			out[key] = {"pressure": e.pressure, "grudge": e.grudge, "fear": e.fear, "stance": e.stance}
	return out
