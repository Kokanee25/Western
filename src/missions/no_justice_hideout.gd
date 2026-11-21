class_name NoJusticeHideout
extends Act
## No Justice, step 3 (#843's plan, #934; data config/moments/no_justice_hideout.json, its _doc has the
## whole scene; lines from docs/scripts/no_justice.json's ride and fight). From the camp's trail: you
## set off with Joe, the ride's a card (riding isn't built, #478), and you come in the back way off the
## mesa onto the slope above the gang's line shack. Joe counts them and asks how you want it; you
## choose by doing (creep in, or open fire). The crew are OutlawBrains posted about their camp
## (`hold`), the alarm theirs by what they see and hear; their calls are the script's lines in their
## own mouths (OutlawBrain.own_lines). Kett, the faded red shirt (S1), unarmed, breaks for the shack
## at the alarm and bars himself in (FalseFrontBuilding.shut_door): the act ends with the crew out of
## it and Kett barred in (step 4 forces the door), or dead or down outside.
##
## Joe is the CompanionBrain the camp handed over (`opts.joe`), or one made beside you.

const HOLED_UP := "holed_up"
const DEAD_OUTSIDE := "dead_outside"
const DOWN_OUTSIDE := "down_outside"
const DEAD_INSIDE := "dead_inside"

var folk: ValleyFolk
var joe: HumanBody
var joe_brain: CompanionBrain
var kett: HumanBody
var shack: FalseFrontBuilding
## The crew but Kett: {man, brain, id}.
var crew: Array[Dictionary] = []
var props: Array[Node3D] = []
var horses: Array[Node3D] = []
## The place's middle on its pad.
var centre := Vector3.ZERO
var ride_s := 0.0
var alarm_t := -1.0
var alarm_by := ""
var started := ""  # "opened" (your shot first), "seen" (they saw you or Joe first), "heard"
var kett_state := ""  # "", "running", HOLED_UP, DEAD_OUTSIDE, DOWN_OUTSIDE, DEAD_INSIDE
var kett_killer: Node = null
var state_t := 0.0
var _made: Array[Node] = []
var _trail_from := Vector3.ZERO
var _spoken := {}
var _kett_way: Array[Vector3] = []
var _kett_down_t := 0.0
var _kett_best := INF
var _kett_stuck := 0.0
var _over_t := -1.0
var _quit_given := false
var _call_t := 0.0
var _rng := RandomNumberGenerator.new()


## Enter after you went down here (`retry`): the valley starts this act again on its next load, on
## the slope above the hideout, the story as it was when the act began (#979's playtest: going down
## was a dead end, you came round at the doctor's and nothing went on).
static var retry_on_load := false
var _down_t := -1.0


func begin() -> void:
	_rng.seed = 934
	Events.shot_fired.connect(_on_shot)
	folk = street.get_tree().get_first_node_in_group(&"valley_folk") as ValleyFolk if street else null
	var l := ValleyLayout.main()
	var at2 := l.place_at(String(data.get("place", "hideout")))
	if at2 == Vector2.ZERO:
		_finish(&"no_place")
		return
	centre = Vector3(at2.x, _ground(at2.x, at2.y), at2.y)
	if opts.get("set_up", false):
		_set_up()
	StoryState.mark_checkpoint()  # a retry starts from the story as it is now (#864)
	var p := player()
	if p == null:
		_finish(&"no_player")
		return
	joe = opts.get("joe") as HumanBody if opts.get("joe") is HumanBody else null
	if joe == null or not is_instance_valid(joe):
		var at := p.global_position + p.global_transform.basis * Vector3(2.2, 0.0, 0.8)
		at.y = _ground(at.x, at.z) + 0.05
		joe = CompanionBrain.make_joe(street, at, p.rotation.y, p, folk.places if folk else null)
		_made.append(joe)
	joe_brain = joe.get_node(^"Brain") as CompanionBrain
	JoeLost.watch(self, joe, joe_brain)
	joe_brain.costume = true
	joe_brain.held = false
	_trail_from = p.global_position
	if opts.get("arrive", false):
		_build_set()
		_arrive()
		return
	prompt(String(_prompts().get("trail", "")), 6.0)
	_go(&"trail")


func _go(s: StringName) -> void:
	state = s
	state_t = 0.0
	_note("-> %s" % s)


## `-- --mission=no_justice_hideout` / the bridge's set_up: steps 1 and 2 done (No Law's sheriff
## dead, you his deputy with his revolver; Joe met at the doctor's, the camp seen, the trail read),
## you and Joe at the camp where he read it, early afternoon.
func _set_up() -> void:
	var c := clock()
	if c:
		c.set_time(float(opts.get("hour", 11.9)))
	var before := {"nolaw.murder": "done", "nolaw.sheriff": "dead", "nolaw.deputy": true, "nolaw.revolver": "given",
			"nojustice.met": "nod", "nojustice.camp": "came", "nojustice.costume": true, "nojustice.trail": "hideout",
			"nojustice.knew_the_way": false}
	for k: String in before:
		if not StoryState.has_fact(k):
			fact(k, before[k])
	var p := player()
	if p == null:
		return
	var l := ValleyLayout.main()
	var camp := l.place_at("ute_community")
	var to := (Vector2(centre.x, centre.z) - camp).normalized()
	var at2 := camp + to * 30.0
	p.global_position = Vector3(at2.x, _ground(at2.x, at2.y) + 0.1, at2.y)
	p.velocity = Vector3.ZERO
	p.rotation.y = atan2(-to.x, -to.y)
	p.give(&"revolver")


# --- Where --------------------------------------------------------------------------------------

## A point of the place's frame [east, south] (m off its middle) on the ground.
func spot(xz: Array, up := 0.0) -> Vector3:
	var x := centre.x + float(xz[0])
	var z := centre.z + float(xz[1])
	return Vector3(x, _ground(x, z) + up, z)


static func _ground(x: float, z: float) -> float:
	return ValleyTerrain.main().height(x, z)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _prompts() -> Dictionary:
	return data.get("prompts", {})


## Inside the shack's walls (its own space).
func in_shack(at: Vector3) -> bool:
	if shack == null or not is_instance_valid(shack):
		return false
	var l := shack.global_transform.affine_inverse() * at
	return l.x > 0.15 and l.x < shack.width - 0.15 and l.z > 0.15 and l.z < shack.depth - 0.15 and l.y > -0.5 and l.y < 2.5


func _shack_door(out_m: float) -> Vector3:
	return shack.global_transform * Vector3(shack.width * 0.5, 0.0, -out_m)


# --- The set ------------------------------------------------------------------------------------

func _build_set() -> void:
	if shack != null:
		return
	_build_shack()
	_build_fire()
	_build_props()
	_build_horses()
	_build_crew()
	_note("set: the shack, %d props, %d horses, %d men and Kett" % [props.size(), horses.size(), crew.size()])


func _build_shack() -> void:
	var sd: Dictionary = data.get("shack", {})
	shack = FalseFrontBuilding.new()
	shack.name = "HideoutShack"
	shack.structure_id = &"hideout_shack"
	shack.width = float(sd.get("width", 4.2))
	shack.depth = float(sd.get("depth", 5.0))
	shack.wall_height = float(sd.get("wall_height", 2.3))
	shack.front_height = shack.wall_height
	shack.floor_top = float(sd.get("floor_top", 0.18))
	var door: Array = sd.get("door", [0.95, 1.95])
	shack.door_size = Vector2(float(door[0]), float(door[1]))
	shack.gable_front = true
	shack.front_wood = &"weathered_pine"
	shack.front_windows = false
	shack.porch = false
	shack.porch_lantern = false
	shack.furnished = false
	shack.sign_text = ""
	shack.roof_pitch_degrees = 24.0
	var mid := spot(sd.get("at", [7.0, 5.0]))
	# Its floor on the ground's high corner (the pad's flat; a little set in where it's not).
	var lo := INF
	for cx: float in [-0.5, 0.5]:
		for cz: float in [-0.5, 0.5]:
			lo = minf(lo, _ground(mid.x + cx * shack.width, mid.z + cz * shack.depth))
	shack.position = Vector3(mid.x - shack.width * 0.5, lo, mid.z - shack.depth * 0.5)
	street.add_child(shack)
	_made.append(shack)
	_build_doorstep(sd)


## A flat stone before the door, half the floor's height (#966's playtest: you can step 0.3 m, and
## the shack's floor stands higher than that off the ground; Joe and Kett walk up more).
func _build_doorstep(sd: Dictionary) -> void:
	var ds: Array = sd.get("doorstep", [1.1, 0.5])
	var h := shack.floor_top * 0.5
	var at := _shack_door(float(ds[1]) * 0.5)
	var body := StaticBody3D.new()
	body.name = "HideoutDoorstep"
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(float(ds[0]), h, float(ds[1]))
	cs.shape = box
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.46, 0.42, 0.36)
	mat.roughness = 1.0
	mi.material_override = mat
	body.add_child(mi)
	street.add_child(body)
	body.global_transform = Transform3D(shack.global_basis, Vector3(at.x, shack.global_position.y + h * 0.5, at.z))
	_made.append(body)


func _build_fire() -> void:
	var at := spot(data.get("fire", [-2.0, -1.0]))
	var fire := Node3D.new()
	fire.name = "HideoutFire"
	street.add_child(fire)
	fire.global_position = at
	_made.append(fire)
	var log_mat := StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.12, 0.08, 0.05)
	log_mat.roughness = 1.0
	for i in 3:
		var m := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.06
		c.bottom_radius = 0.07
		c.height = 0.7
		c.radial_segments = 6
		m.mesh = c
		m.material_override = log_mat
		m.rotation = Vector3(PI * 0.5, i * TAU / 3.0, 0.0)
		m.position = Vector3(0.0, 0.08, 0.0)
		fire.add_child(m)
	var ember := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.16
	s.height = 0.14
	ember.mesh = s
	var em := StandardMaterial3D.new()
	em.albedo_color = Color(0.9, 0.35, 0.08)
	em.emission_enabled = true
	em.emission = Color(1.0, 0.42, 0.1)
	em.emission_energy_multiplier = 2.0
	ember.material_override = em
	ember.position = Vector3(0.0, 0.05, 0.0)
	fire.add_child(ember)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.3)
	light.light_energy = 0.8
	light.omni_range = 5.0
	light.position = Vector3(0.0, 0.5, 0.0)
	fire.add_child(light)


func _build_props() -> void:
	for d: Dictionary in data.get("props", []):
		if not PropKit.has(StringName(d.id)):
			continue
		var kp := PropKit.make(StringName(d.id))
		var at := spot(d.at)
		var b := Basis(Vector3.UP, deg_to_rad(float(d.get("yaw", 0.0))))
		if d.get("tipped", false):
			b = b * Basis(Vector3.FORWARD, PI * 0.5)
			at.y += 0.25
		kp.name = "Hideout_%s_%d" % [d.id, props.size()]
		kp.transform = Transform3D(b, at)
		if d.has("call"):
			kp.set_meta(&"call", String(d.call))
		street.add_child(kp)
		_made.append(kp)
		props.append(kp)


func _build_horses() -> void:
	var hd: Dictionary = data.get("horses", {})
	var n := int(hd.get("n", 0))
	var line_a: Array = hd.get("line", [])
	if n <= 0 or line_a.size() < 2 or not Horse.available():
		return
	var a := spot(line_a[0])
	var b := spot(line_a[1])
	var f: Array = hd.get("facing", [1.0, 0.0])
	var facing := Vector3(float(f[0]), 0.0, float(f[1])).normalized()
	for i in n:
		var at := a.lerp(b, (i + 0.5) / float(n)) - facing * 1.6
		at.y = _ground(at.x, at.z)
		var h := Horse.new()
		h.name = "HideoutHorse%d" % i
		street.add_child(h)
		h.global_transform = Transform3D(Basis(Vector3.UP, atan2(facing.z, -facing.x)), at)
		var nose := at + facing * 1.6
		h.tie_to(Vector3(nose.x, _ground(nose.x, nose.z) + 0.9, nose.z))
		horses.append(h)
		_made.append(h)


## The crew: five OutlawBrains posted about their camp, their lines the script's; Kett unarmed, no brain.
func _build_crew() -> void:
	var ids: Array[StringName] = []
	for m: Dictionary in data.get("crew", []):
		ids.append(StringName(m.id))
	var shirts: Array = data.get("crew_shirts", [])
	var k := 0
	for m: Dictionary in data.get("crew", []):
		var man := HumanBody.new()
		man.name = String(m.get("name", m.id))
		man.person_id = StringName(m.id)
		man.rng_seed = int(m.get("seed", 9340 + k))
		man.body_model = &"outlaw"
		man.start_holstered = true
		man.hat_color = Color(0.2, 0.16, 0.12)
		var at := spot(m.at, 0.05)
		var look := spot(m.get("look", [0, 0]), 1.0)
		if m.get("kett", false):
			man.has_gun = false
			var sh: Array = m.get("shirt", [0.62, 0.24, 0.2])
			man.shirt_color = Color(float(sh[0]), float(sh[1]), float(sh[2]))
			man.enter(street, at, HumanBody.yaw_toward(at, look))
			kett = man
			_made.append(man)
			man.hit.connect(_kett_hit)
			man.died.connect(func(_c: StringName) -> void: _note("Kett dead"))
			continue
		var sh2: Array = shirts[k % shirts.size()] if not shirts.is_empty() else [0.5, 0.46, 0.4]
		man.shirt_color = Color(float(sh2[0]), float(sh2[1]), float(sh2[2]))
		man.has_gun = true
		var brain := OutlawBrain.new()
		brain.name = "Brain"
		brain.nerve = float(m.get("nerve", 0.6))
		brain.temper = float(m.get("temper", 0.5))
		brain.leads = bool(m.get("leads", false))
		var friends: Array[StringName] = []
		for o: StringName in ids:
			if o != man.person_id:
				friends.append(o)
		brain.friends = friends
		if folk:
			brain.places = folk.places
		brain.hold = {"inside": in_reach, "post": at, "look": look}
		brain.agenda = [{"do": &"post"}]
		brain.own_lines = _crew_lines()
		man.add_child(brain)
		man.move_child(brain, 0)
		man.enter(street, at, HumanBody.yaw_toward(at, look))
		var g := {"man": man, "brain": brain, "id": String(m.id), "name": man.name}
		crew.append(g)
		_made.append(man)
		_watch(g)
		k += 1


func _crew_lines() -> Dictionary:
	return {&"call_hit": [line("hit")], &"call_help": [line("leg")]}


## Where they fight: about their camp (OutlawBrain.hold's `inside`).
func in_reach(at: Vector3) -> bool:
	return at != Vector3.INF and _flat(at, centre) < float(data.get("reach_m", 70.0))


## What each man sees, hears and takes raises the alarm.
func _watch(g: Dictionary) -> void:
	var man := g.man as HumanBody
	var brain := g.brain as OutlawBrain
	man.hit.connect(func(_info: Dictionary) -> void:
		var p := player()
		var yours := first_shot in ["you", "joe"]
		if alarm_t < 0.0 and started == "":
			started = "opened" if yours else "heard"
		_alarm(brain, p.global_position if yours and p else man.global_position, "%s hit" % g.name))
	man.died.connect(func(_c: StringName) -> void: _note("%s dead" % g.name))
	brain.mood_changed.connect(func(mood: OutlawBrain.Mood) -> void:
		if mood == OutlawBrain.Mood.SURRENDERED:
			# The last man's nerve breaking (fight.crew_quit): his words, said just after this.
			if crew.all(func(o: Dictionary) -> bool: return o == g or is_out(o)):
				brain.own_lines[&"surrender"] = [line_preview("quit")]
			_note("%s gives up" % g.name)
		elif mood == OutlawBrain.Mood.FLEEING:
			_note("%s runs" % g.name))
	(func() -> void:
		if not is_instance_valid(brain) or brain.senses == null:
			return
		brain.senses.spotted.connect(func(who: Node3D) -> void:
			if alarm_t < 0.0 and (who is Player or who == joe):
				started = "seen"
				_alarm(brain, who.global_position, "%s saw %s" % [g.name, "you" if who is Player else "Joe"]))
		brain.senses.heard.connect(func(at: Vector3, kind: StringName, _who: Node) -> void:
			if alarm_t < 0.0 and kind in [&"gunshot", &"blast", &"glass", &"timber", &"crash"]:
				if started == "":
					started = "heard"
				_alarm(brain, at, "%s heard %s" % [g.name, kind]))).call_deferred()


## The alarm: the man who has it calls it (the script's), the rest go to it.
func _alarm(by: OutlawBrain, at: Vector3, what: String) -> void:
	if alarm_t >= 0.0 or done:
		return
	alarm_t = t
	alarm_by = String(by.body.person_id) if by else ""
	_note("the alarm: " + what)
	var p := player()
	if p == null:
		return
	if by != null and is_instance_valid(by) and by.body.physiology.is_conscious():
		var hill := p.global_position.y - centre.y > float(data.get("hill_over_m", 2.5)) \
				and _flat(p.global_position, centre) > float(data.get("hill_far_m", 40.0))
		_say(by.body, line("alarm_hill" if hill else "alarm"))
	for g: Dictionary in crew:
		var b := g.brain as OutlawBrain
		if not is_instance_valid(b) or not b.body.physiology.alive:
			continue
		b.senses.note(p, at, 0.5 if b == by else 3.0)
		b.quiet_start = true
		b.relations.provoke(p)
	if fact_unset("nojustice.started"):
		fact("nojustice.started", started if started != "" else "seen")
	if state in [&"approach", &"watch"]:
		_go(&"fight")


## The first shot's whose: yours before any alarm is your opening fire (`started` = opened).
var first_shot := ""


var _their_shot_t := -1.0
## Shots fired since it started: yours, Joe's, theirs.
var shots := {"you": 0, "joe": 0, "them": 0}


func _on_shot(_o: Vector3, _d: Vector3, shooter: Node) -> void:
	if shooter == null:
		return
	var who := "you" if shooter is Player else ("joe" if shooter == joe else "them")
	shots[who] += 1
	if who == "them":
		_their_shot_t = t
	if first_shot != "":
		return
	# A man's ears can have it before this does (the same shot's signal): still yours.
	if alarm_t >= 0.0 and t - alarm_t < 0.1 and started == "heard" and who in ["you", "joe"]:
		started = "opened"
		fact("nojustice.started", started)
	first_shot = who
	if alarm_t < 0.0 and first_shot in ["you", "joe"]:
		started = "opened"


func fact_unset(k: String) -> bool:
	return not StoryState.has_fact(k)


# --- The tick -----------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	t += delta
	state_t += delta
	card_step(delta)
	if done:
		if state == &"you_down":
			_down_step()
		return
	var p := player()
	if p == null or joe == null or not is_instance_valid(joe):
		return
	match state:
		&"trail":
			_trail_step(p)
		&"ride":
			if not card_up():
				p.input_enabled = true
				_arrive()
		&"approach", &"watch":
			_approach_step(p)
			_kett_step(delta)
		&"fight":
			_kett_step(delta)
			_fight_step(p, delta)
		&"after":
			_kett_step(delta)
			_after_step(p)


## From the camp: on along the trail with Joe, and the card.
func _trail_step(p: Player) -> void:
	var td: Dictionary = data.get("trail", {})
	var to := Vector3(centre.x - _trail_from.x, 0.0, centre.z - _trail_from.z).normalized()
	var gone := p.global_position - _trail_from
	gone.y = 0.0
	var on := gone.dot(to)
	var off := rad_to_deg(gone.angle_to(to)) if gone.length() > 1.0 else 180.0
	var joe_near := _flat(p.global_position, joe.global_position) < float(td.get("joe_m", 14.0))
	# Their way only (the playtest: any walk at all, or standing 90 s, took you there).
	if on > float(td.get("go_m", 22.0)) and off < float(td.get("off_deg", 50.0)) and joe_near:
		_ride()


## The ride's metres: from where you set off to the mesa's back trail's top, then down it.
func ride_metres() -> float:
	var rd: Dictionary = data.get("ride", {})
	var line_xz := ValleyLayout.main().road_line(String(rd.get("back_trail", "mesa_back_trail")))
	if line_xz.size() < 2:
		return float(rd.get("from_m", 1200.0))
	var m := Vector2(_trail_from.x, _trail_from.z).distance_to(line_xz[0])
	for i in range(1, line_xz.size()):
		m += line_xz[i - 1].distance_to(line_xz[i])
	return m


func _ride() -> void:
	var rd: Dictionary = data.get("ride", {})
	var metres := ride_metres()
	ride_s = metres / float(rd.get("mps", 1.8))
	_note("the ride: %.0f m, %.0f s" % [metres, ride_s])
	card(String((data.get("cards", {}) as Dictionary).get("ride", "You ride on with Joe.")).replace("%d", str(roundi(ride_s / 60.0))), 5.0 * _pace())
	var c := clock()
	if c:
		c.set_time(c.time_of_day + ride_s / 3600.0)
	var p := player()
	if p:
		p.input_enabled = false
	_build_set()
	_go(&"ride")


## In on the slope west of the shack, above it, the way off the mesa.
func _arrive() -> void:
	var p := player()
	var at := spot(data.get("arrive", [-96.0, -34.0]), 0.1)
	p.global_position = at
	p.velocity = Vector3.ZERO
	var w := spot(data.get("watch", [-58.0, -14.0]))
	p.rotation.y = atan2(-(w.x - at.x), -(w.z - at.z))
	var jat := spot(data.get("joe_arrive", [-97.5, -36.0]), 0.05)
	joe.global_position = jat
	joe.rotation.y = HumanBody.yaw_toward(jat, w)
	joe_brain.held = false
	fact("nojustice.hideout", "came")
	_go(&"approach")


## Joe's closeness and warning on the way up; the count and the ask on the slope.
func _approach_step(p: Player) -> void:
	if state == &"approach":
		if not _spoken.has("close") and state_t > float(data.get("close_s", 2.0)):
			_say_once(joe, "close")
			prompt(String(_prompts().get("up", "")), 5.0)
		elif _spoken.has("close") and not _spoken.has("warn") and state_t > float(data.get("warn_s", 8.0)) * _pace():
			_say_once(joe, "warn")
		var w := spot(data.get("watch", [-58.0, -14.0]))
		if _spoken.has("warn") and _flat(p.global_position, w) < float(data.get("watch_m", 7.0)) \
				or _flat(p.global_position, centre) < _flat(w, centre) - 2.0:
			_go(&"watch")
	elif state == &"watch":
		if not _spoken.has("count") and state_t > 0.6:
			joe.face(kett.global_position + Vector3.UP * 1.4 if kett else centre)
			_say_once(joe, "count")
			_next_said = t + _gap(line_preview("count"))
		elif _spoken.has("count") and not _spoken.has("how") and t > _next_said:
			joe.face(p.global_position + Vector3.UP * 1.5)
			_say_once(joe, "how")
			prompt(String(_prompts().get("choose", "")), 5.0)


var _next_said := 0.0


func line_preview(beat: String) -> String:
	var by: Variant = (data.get("lines", {}) as Dictionary).get(beat, {})
	var l: Variant = (by as Dictionary).get("any", "") if by is Dictionary else by
	return String(l[0]) if l is Array and not (l as Array).is_empty() else String(l)


## Kett: by the fire till the alarm, then for the shack, in, the door shut and barred.
func _kett_step(delta: float) -> void:
	if kett == null or not is_instance_valid(kett):
		return
	if kett_state in [DEAD_OUTSIDE, DEAD_INSIDE]:
		return
	if not kett.physiology.alive:
		kett_state = DEAD_INSIDE if in_shack(kett.global_position) else DEAD_OUTSIDE
		_kett_dead()
		return
	if kett_state == HOLED_UP:
		return
	if alarm_t < 0.0:
		if not kett.limp:
			kett.set_pose(&"stand")
		return
	if t - alarm_t < float(data.get("kett_after_s", 0.8)):
		return
	if kett_state == "":
		kett_state = "running"
		var sd: Dictionary = data.get("shack", {})
		var inn: Array = sd.get("in", [0.0, 1.6])
		_kett_way = [_shack_door(1.4), _shack_door(-0.3), shack.global_transform * Vector3(shack.width * 0.5 + float(inn[0]), shack.floor_top, float(inn[1]) + 0.6)]
		_note("Kett breaks for the shack")
		_yell_after()
		if joe_brain and joe.physiology.is_conscious() and not joe.limp:
			_say_once(joe, "joe_runs")
	if kett.limp:
		if kett_state != DOWN_OUTSIDE and not in_shack(kett.global_position):
			_note("Kett down outside")
		kett_state = DOWN_OUTSIDE if not in_shack(kett.global_position) else kett_state
		_kett_down_t += delta
		if _kett_down_t > float(data.get("kett_up_s", 3.0)) and kett.physiology.is_conscious() and kett.physiology.can_stand():
			_kett_down_t = 0.0
			kett.get_up()
		return
	if kett.rising:
		return
	if kett_state == DOWN_OUTSIDE:
		kett_state = "running"
		_note("Kett up and running again")
	while not _kett_way.is_empty() and _flat(kett.global_position, _kett_way[0]) < 0.4:
		_kett_way.pop_front()
		_kett_best = INF
	# Stuck on something (a man in the way, a prop): past it to the next point, or nudged round it.
	if not _kett_way.is_empty():
		var d := _flat(kett.global_position, _kett_way[0])
		if d < _kett_best - 0.1:
			_kett_best = d
			_kett_stuck = 0.0
		else:
			_kett_stuck += delta
		if _kett_stuck > 1.5:
			_kett_stuck = 0.0
			_kett_best = INF
			if _kett_way.size() > 2 and d < 2.5:
				_kett_way.pop_front()
			else:
				var side := Vector3.UP.cross(_kett_way[0] - kett.global_position).normalized()
				_kett_way.push_front(kett.global_position + side * 1.2 * (1.0 if _rng.randf() < 0.5 else -1.0))
			_note("Kett stuck: round it")
	if _kett_way.is_empty():
		_holed_up()
		return
	kett.set_pose(&"stand")
	var speed := float(data.get("kett_run", 4.2)) if _kett_way.size() > 1 else 1.4
	kett.walk_to(_kett_way[0], speed if kett.physiology.can_stand() else 1.0, delta)


func _holed_up() -> void:
	kett_state = HOLED_UP
	shack.shut_door(true)
	kett.face(_shack_door(0.0) + Vector3.UP * 1.0)
	kett.set_pose(&"crouch")
	fact("nojustice.kett", HOLED_UP)
	prompt(String(_prompts().get("barred", "")), 4.0)


func _kett_hit(_info: Dictionary) -> void:
	if alarm_t < 0.0:
		if started == "":
			started = "opened" if first_shot in ["you", "joe"] else "heard"
		_alarm(null, kett.global_position, "Kett hit")


func _kett_dead() -> void:
	# Who hit him last (the ball marks its man: Ballistics' `last_hit_by`).
	if kett_killer == null and kett.has_meta(&"last_hit_by"):
		kett_killer = kett.get_meta(&"last_hit_by")
	fact("nojustice.kett", kett_state)
	if kett_state == DEAD_OUTSIDE and kett_killer == player() and joe.physiology.is_conscious():
		_say_once(joe, "mine")


## A man of the crew yells after him (fight.runs): the nearest still in it.
func _yell_after() -> void:
	var best: HumanBody = null
	var best_d := INF
	for g: Dictionary in crew:
		var m := g.man as HumanBody
		if not is_instance_valid(m) or not m.physiology.is_conscious() or m.limp:
			continue
		var d := m.global_position.distance_to(kett.global_position)
		if d < best_d:
			best = m
			best_d = d
	if best:
		_say(best, line("runs"))


## Joe went down in it (out, or off his feet) at any time.
var joe_went_down := false
## You went down: where you were hit and by what (PlayerWounds.down_line), on the retry card.
var down_line := ""


func _fight_step(p: Player, _delta: float) -> void:
	if not joe.physiology.is_conscious() or joe.limp:
		joe_went_down = true
	_call_t -= _delta
	if _call_t <= 0.0:
		_call_t = 1.0
		_crew_calls(p)
	if p.wounds and not p.wounds.physiology.is_conscious():
		fact("nojustice.hideout", "you_down")
		_down_t = t
		down_line = p.wounds.down_line()  # what hit you, from the wound record (#1095)
		_finish(&"you_down")
		return
	if _flat(p.global_position, centre) > float(data.get("left_m", 260.0)):
		fact("nojustice.hideout", "left")
		_finish(&"left")
		return
	var kett_settled := kett_state in [HOLED_UP, DEAD_OUTSIDE, DEAD_INSIDE] or kett_state == DOWN_OUTSIDE \
			and (not kett.physiology.can_stand() or not kett.physiology.is_conscious())
	# Over: every man out of it, or none of them has fired in `quiet_s` and none is up fighting.
	var quiet := t - maxf(_their_shot_t, alarm_t) > float(data.get("quiet_s", 20.0)) * _pace() \
			and not crew.any(func(g: Dictionary) -> bool: return not is_out(g) and (g.brain as OutlawBrain).mood == OutlawBrain.Mood.FIGHTING \
				and not (g.man as HumanBody).limp)
	if (crew_out() >= crew.size() or quiet) and kett_settled:
		if _over_t < 0.0:
			_over_t = t
		elif t - _over_t > float(data.get("end_after_s", 4.0)):
			_go(&"after")
	else:
		_over_t = -1.0


## Each second: the crew's spotted call by where you are (the script's, by the wagon, or there
## being two of you while Joe's up beside you).
func _crew_calls(p: Player) -> void:
	var where := ""
	for kp: Node3D in props:
		if is_instance_valid(kp) and kp.has_meta(&"call") and _flat(kp.global_position, p.global_position) < 4.0:
			where = String(kp.get_meta(&"call"))
	var two := joe.physiology.is_conscious() and not joe.limp and _flat(joe.global_position, p.global_position) < 20.0
	for g: Dictionary in crew:
		var b := g.brain as OutlawBrain
		if not is_instance_valid(b):
			continue
		if where != "":
			b.own_lines[&"call_spotted"] = [where]
		elif two:
			b.own_lines[&"call_spotted"] = [line_preview("call_two")]
		else:
			b.own_lines.erase(&"call_spotted")


## Out of it: dead, out cold, given up, run off far, down off his feet with no gun in his hand or
## not shooting (the playtest: a man down who could still stand held the end off for good).
func is_out(g: Dictionary) -> bool:
	var man := g.man as HumanBody
	if not is_instance_valid(man) or not man.physiology.alive or not man.physiology.is_conscious():
		return true
	var b := g.brain as OutlawBrain
	if b == null or not is_instance_valid(b):
		return true
	if b.mood == OutlawBrain.Mood.SURRENDERED:
		return true
	if b.mood == OutlawBrain.Mood.FLEEING:
		return _flat(man.global_position, centre) > float(data.get("fled_m", 90.0)) or man.held_gun == null
	if (man.limp or man.prone) and (man.held_gun == null or not b.mood in [OutlawBrain.Mood.FIGHTING, OutlawBrain.Mood.RELOADING]):
		return true
	return man.held_gun == null and b.mood != OutlawBrain.Mood.FIGHTING


func crew_out() -> int:
	return crew.filter(func(g: Dictionary) -> bool: return is_out(g)).size()


## The fight's over: the facts, and the act ends (step 4, the cabin, starts from it).
func _after_step(_p: Player) -> void:
	if done:
		return
	var tally := {"dead": 0, "down": 0, "quit": 0, "fled": 0}
	for g: Dictionary in crew:
		var man := g.man as HumanBody
		var b := g.brain as OutlawBrain
		if not is_instance_valid(man) or not man.physiology.alive:
			tally.dead += 1
		elif b and is_instance_valid(b) and b.mood == OutlawBrain.Mood.FLEEING:
			tally.fled += 1
		elif b and is_instance_valid(b) and b.mood == OutlawBrain.Mood.SURRENDERED:
			tally.quit += 1
		else:
			tally.down += 1
	fact("nojustice.crew", tally)
	fact("nojustice.seen", int(tally.fled) > 0)
	fact("nojustice.joe", "down" if joe_went_down or not joe.physiology.is_conscious() or joe.limp else "up")
	if not StoryState.has_fact("nojustice.kett") or StoryState.get_fact("nojustice.kett") == "running":
		fact("nojustice.kett", kett_state if kett_state != "running" else DOWN_OUTSIDE)
	fact("nojustice.hideout", "fought")
	var how := {HOLED_UP: "over_holed_up", DEAD_OUTSIDE: "over_dead", DEAD_INSIDE: "over_dead", DOWN_OUTSIDE: "over_down"}
	prompt(String(_prompts().get(how.get(kett_state, "over_holed_up"), "")), 8.0)
	_finish(StringName(kett_state if kett_state != "" else "over"))
	_next_act()


## Down in the fight: once you've come round (wherever they carried you), the way to try it again.
func _down_step() -> void:
	var p := player()
	if p == null or p.wounds == null or not p.wounds.physiology.is_conscious():
		return
	if not _spoken.has("retry") and t - _down_t > float(data.get("retry_after_s", 16.0)):
		_spoken["retry"] = t
		var text := String(_prompts().get("retry", ""))
		prompt(("%s\n%s" % [down_line, text]) if down_line != "" else text, 12.0, true)
	if _spoken.has("retry") and Input.is_action_just_pressed(&"mission_retry"):
		retry()


func retry() -> void:
	retry_on_load = true
	GameReset.retry(street.get_tree() if street else Engine.get_main_loop() as SceneTree, "No Justice's hideout, again")


## Step 4 from here (#966, NoJusticeCabin): the shack, Kett, Joe and the bodies stay this act's (the
## cabin's `hideout`). Not with `no_next` (the tests of this step alone, the cabin's own set-up).
var next_act: Moment


func _next_act() -> void:
	if opts.get("no_next", false):
		return
	next_act = Moment.start_named(&"no_justice_cabin", street, null, {"hideout": self, "pace": _pace()})


func _say_once(man: HumanBody, beat: String) -> void:
	if _spoken.has(beat):
		return
	_spoken[beat] = t
	_say(man, line(beat))


func _say(man: HumanBody, text: String) -> void:
	if text == "" or man == null or not is_instance_valid(man) or not man.physiology.is_conscious():
		return
	speak(man, text)
	_note("%s: %s" % [man.person_id, text])


func _gap(text: String) -> float:
	return maxf(2.4, float(text.length()) / 13.0 + 0.8) * _pace()


func _pace() -> float:
	return clampf(float(opts.get("pace", 1.0)), 0.05, 4.0)


func result() -> Dictionary:
	var r := {"moment": String(moment_name), "state": String(state), "t": snappedf(t, 0.01), "done": done,
			"alarm_t": snappedf(alarm_t, 0.01), "alarm_by": alarm_by, "started": started, "kett": kett_state,
			"crew_out": crew_out() if not crew.is_empty() else 0, "crew": crew.size(), "ride_s": snappedf(ride_s, 1.0),
			"props": props.size(), "horses": horses.size(), "shots": shots, "down_line": down_line}
	var men := {}
	for g: Dictionary in crew:
		var man := g.man as HumanBody
		var b := g.brain as OutlawBrain
		if is_instance_valid(man) and is_instance_valid(b):
			men[g.name] = "%s%s%s" % [OutlawBrain.Mood.keys()[b.mood], " limp" if man.limp else "", "" if man.physiology.alive else " dead"]
	r["men"] = men
	if kett and is_instance_valid(kett):
		var kp := kett.global_position
		r["kett_at"] = [snappedf(kp.x, 0.1), snappedf(kp.y, 0.1), snappedf(kp.z, 0.1)]
		r["kett_way"] = _kett_way.size()
		if not _kett_way.is_empty():
			r["kett_to_m"] = snappedf(_flat(kp, _kett_way[0]), 0.1)
	var p := player()
	if p and joe and is_instance_valid(joe):
		r["you_to_shack_m"] = snappedf(_flat(p.global_position, centre), 0.1)
		r["joe"] = {"held": joe_brain.held, "limp": joe.limp, "alive": joe.physiology.alive, "conscious": joe.physiology.is_conscious()}
	r["story"] = StoryState.to_dict().facts
	r["timeline"] = timeline.slice(-16)
	return r


## Take back its men and props (the bridge, the tests).
func reset() -> void:
	for n: Node in _made:
		if is_instance_valid(n):
			n.queue_free()
	var p := player()
	if p:
		p.input_enabled = true
	queue_free()
