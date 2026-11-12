class_name CoachCut
extends Node3D
## The coach heist in the valley's coach cut (#794; Sean's ram on #791; the place,
## docs/briefs/valley-heights.md section 3 and config/valley.json's `heights` coach_cut): the South
## Road through the hogback, level in the cut (the bake holds it `over_natural` over its span) with
## 1:1.5 banks. A SwingingRam straddles the road at the cut's middle, its log held back up the
## south-west bank by its trip pin; the Baron's coach (`baron_coach`, its strongbox under the rear
## bench) comes up the grade from town toward his ranch, driven at the team's walk on the ground
## (CoachDrive.ground), four guards inside and the driver and messenger on the box. Shoot the pin as it
## comes (from the high spot on the bank, 14 m off the road and ~8 m from the pin) and the log meets
## its upper plates at the bottom of its swing: over it goes, dented.
## After the hit (#815): CoachFight, the guards out of the wreck fighting and the strongbox taken;
## won up the rimrock trail with the papers or the box, lost and Enter tries again from the high spot.
## `-- --world=valley --mission=coach` (you at the high spot, the coach `start_back` down the road),
## or the coach heist lab's bridge `ch_cut` (experiments/coach_heist/).

const START_ARG := "--mission=coach"
## Enter after a try (CoachFight.retry): the valley starts it again on its next load.
static var start_on_load := false
const CUT := "coach_cut"
const ROAD := "south_road"
## The coach's near plates' outer face from its middle (m), and the gap the log's face is hung off it.
const PLATE_FACE := 0.708
const LOG_GAP := 0.02

var layout: ValleyLayout
## The ground's height (x, z) -> y (default: the valley's bake).
var height_at := Callable()
## How far down the road (m) the coach starts.
@export var start_back := 40.0
## Let the pin go by itself when the coach's middle is this far short of the ram's line (m; the
## lab's and the bridge's `auto`), or never (< 0: the player shoots it).
@export var release_lead := -1.0
@export var guards_n := 4

var ram: SwingingRam
var coach: KitProp
var drive: CoachDrive
var watch: DentWatch
var riders: Array[HumanBody] = []
## The fight after the hit (#815), made with the coach.
var fight: CoachFight
## The hit's seed (the guards' daze, nerve, who's hurt).
@export var fight_seed := 815
## The cut's geometry (world): the road's middle at the cut, the coach's way along it (toward the
## Baron's) and the side the ram is held back on (up the south-west bank).
var middle := Vector3.ZERO
var road_dir := Vector3.ZERO
var side := Vector3.ZERO
## The road's flat between its banks (offsets along `side` from `middle`, m).
var road_from := 0.0
var road_to := 0.0
var t := 0.0
var released_at := -1.0
var hit_at := -1.0
var max_lean := 0.0
## The ram's log at the hand-off: its speed, where it was (the ram's space), how far along the coach.
var hit := {}
var _dents_from := 0  # (the scene's watch may have dented before this cut was made)


func _init() -> void:
	name = "CoachCut"


## The cut's place from the plan, the ram built on it (held), the coach not yet on the road.
func setup() -> void:
	if layout == null:
		layout = ValleyLayout.main()
	if not height_at.is_valid():
		var terrain := ValleyTerrain.main()
		height_at = func(x: float, z: float) -> float: return terrain.height(x, z)
	_find_road()
	watch = DentWatch.of(get_tree())
	_dents_from = watch.made.size()
	ram = SwingingRam.new()
	add_child(ram)
	var line := middle + side * (PLATE_FACE + ram.log_radius + LOG_GAP)
	ram.global_transform = Transform3D(_basis(), line)
	# The legs stand just off the road's flat, on the banks' feet; set into the higher ground.
	ram.leg_back = (road_to + 0.4) - (PLATE_FACE + ram.log_radius + LOG_GAP)
	ram.leg_fore = (PLATE_FACE + ram.log_radius + LOG_GAP) - (road_from - 0.4)
	var bx := ram.log_length * 0.5 + ram.bent_gap
	ram.foot_back = _lowest(line, side * ram.leg_back, bx) - line.y
	ram.foot_fore = _lowest(line, -side * ram.leg_fore, bx) - line.y
	var held := ram.held_at()
	var tz := held.z - 2.5
	var trip := ram.global_transform * Vector3(0.0, 0.0, tz)
	ram.trip_at = Vector3(0.0, float(height_at.call(trip.x, trip.z)) - line.y, tz)
	ram.build()
	ram.released.connect(func() -> void: released_at = t)


## The coach `start_back` m down the road, its riders in it, driving up into the cut.
func start_coach() -> void:
	coach = PropKit.spawn(&"baron_coach", &"baron_coach_cut")
	add_child(coach)
	var at := middle - road_dir * start_back
	at.y = float(height_at.call(at.x, at.z))
	coach.global_transform = Transform3D(_basis(), at)
	drive = CoachDrive.new()
	drive.name = "CoachDrive"
	add_child(drive)
	drive.ground = height_at
	drive.start(coach)
	drive.strikers.append(ram.log_body)
	fight = CoachFight.new()
	fight.cut = self
	fight.seed_value = fight_seed
	add_child(fight)
	drive.handed_off.connect(func(b: Array) -> void:
		fight.on_hit(b)
		hit_at = t
		var lg := ram.log_body
		hit = {"speed": snappedf(lg.linear_velocity.length(), 0.01), "at": _arr(ram.to_local(lg.global_position)),
				"along": snappedf((lg.global_position - coach.global_position).dot(road_dir), 0.01)})
	_seat_riders()


## Both at once (the mission's start).
func begin() -> void:
	setup()
	start_coach()


## The player at the high spot on the south-west bank, facing the pin.
func place_player(player: Node3D) -> void:
	var cut := layout.height(CUT)
	var hi: Array = cut.get("high", {}).get("at", [])
	if player == null or hi.size() < 2:
		return
	var at := Vector3(float(hi[0]), 0.0, float(hi[1]))
	at.y = float(height_at.call(at.x, at.z)) + 0.05
	var look := ram.pin_position() if ram else middle
	look.y = at.y
	player.global_transform = Transform3D(Basis.looking_at((look - at).normalized(), Vector3.UP), at)
	if fight:
		fight._say("The Baron's coach is coming up the grade. Shoot the pin as it comes under the log.", 8.0)


func _physics_process(delta: float) -> void:
	t += delta
	if ram and ram.is_held() and release_lead >= 0.0 and coach and drive and not drive.loose:
		var short := (ram.global_position - coach.global_position).dot(road_dir)
		if short <= release_lead:
			ram.release()
	if drive and drive.loose:
		max_lean = maxf(max_lean, drive.lean())
		# Past the frame and on, a coach not struck is driven on out of the cut (CoachDrive drives
		# straight: stop it once it's left the cut's level road).
	elif drive and drive.driving and (coach.global_position - middle).dot(road_dir) > 60.0:
		drive.driving = false


## What happened, for the bridge and the lab.
func result() -> Dictionary:
	var deepest := 0.0
	var mine: Array = watch.made.slice(_dents_from) if watch else []
	for d: Dictionary in mine:
		deepest = maxf(deepest, float(d.depth))
	var out := {"released_at": snappedf(released_at, 0.01), "hit_at": snappedf(hit_at, 0.01),
		"over": max_lean > 60.0, "max_lean": snappedf(max_lean, 0.1), "dents": mine.size(),
		"deepest_cm": snappedf(deepest * 100.0, 0.1), "traces_on": drive.traces_on() if drive else 0,
		"ram": ram.state() if ram else {}, "hit": hit, "riders": []}
	for man in riders:
		if is_instance_valid(man):
			(out.riders as Array).append({"who": String(man.person_id), "limp": man.limp,
					"conscious": man.physiology.is_conscious()})
	if coach:
		out["coach_at"] = [snappedf(coach.global_position.x, 0.1), snappedf(coach.global_position.z, 0.1)]
		var sb := coach.carried("strongbox")
		out["strongbox_loose"] = sb.loose if sb else false
	if fight:
		out["fight"] = fight.result()
	return out


static func _arr(v: Vector3) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]


# --- The place ------------------------------------------------------------------------------------

## The cut's road: its way from the plan's line (the segment nearest the cut, toward its later
## points, the Baron's); its middle and edges from the ground across it (the level bed between banks).
func _find_road() -> void:
	var cut := layout.height(CUT)
	var a: Array = cut.get("at", [400, 805])
	var c := Vector2(float(a[0]), float(a[1]))
	var line := layout.road_line(ROAD)
	var best := INF
	var d := Vector2.RIGHT
	for i in line.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(c, line[i], line[i + 1])
		if q.distance_to(c) < best:
			best = q.distance_to(c)
			d = (line[i + 1] - line[i]).normalized()
	road_dir = Vector3(d.x, 0.0, d.y)
	# The deck's bank (the plan's "south-west bank"): to the right of the way toward the Baron's.
	side = Vector3(-d.y, 0.0, d.x)
	var c3 := Vector3(c.x, 0.0, c.y)
	var low := INF
	var hs := {}
	for k in range(-24, 25):
		var o := k * 0.5
		var p := c3 + side * o
		var h := float(height_at.call(p.x, p.z))
		hs[o] = h
		low = minf(low, h)
	var flat: Array[float] = []
	for o: float in hs:
		if hs[o] <= low + 0.2:
			flat.append(o)
	road_from = flat.min() if not flat.is_empty() else -2.5
	road_to = flat.max() if not flat.is_empty() else 2.5
	var mid := (road_from + road_to) * 0.5
	middle = c3 + side * mid
	middle.y = float(height_at.call(middle.x, middle.z))
	road_from -= mid
	road_to -= mid


## The coach's and the ram's turn: front (-x) along the road, +z away from the ram's bank.
func _basis() -> Basis:
	var x := -road_dir
	var z := -side
	return Basis(x, z.cross(x), z)


## The lower ground under the two bents' legs at `off` from the ram's line `at` (each bent `bx`
## along the road), 5 cm down: set into the bank, not standing over air.
func _lowest(at: Vector3, off: Vector3, bx: float) -> float:
	var lo := INF
	for sx in [-1.0, 1.0]:
		var p: Vector3 = at + off + road_dir * bx * sx
		lo = minf(lo, float(height_at.call(p.x, p.z)))
	return lo - 0.05


func _seat_riders() -> void:
	var k := 0
	for s: Dictionary in coach.definition.get("seats_at", []):
		var who := String(s.get("who", ""))
		if who == "" and k >= guards_n:
			continue
		var man := HumanBody.new()
		man.name = who.to_pascal_case() if who != "" else "Guard%d" % k
		man.body_model = &"outlaw"
		man.has_gun = true
		man.start_holstered = true
		man.person_id = StringName(who if who != "" else "coach_guard_%d" % k)
		man.rng_seed = 9400 + riders.size()
		add_child(man)
		var at := PropKit.vec(s.at)
		drive.seat(man, at, at.y - 0.405 if who != "" else 1.105, float(s.get("yaw", NAN)))
		riders.append(man)
		fight.add_man(man, &"inside" if who == "" else &"box")
		if who == "":
			k += 1
