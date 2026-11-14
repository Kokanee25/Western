extends TestCase
## No Justice step 2 (#859; NoJusticeCamp, config/moments/no_justice_camp.json): Joe in the doctor's
## front office, the doctor's warning and the cowboy's, Joe's ask and your answer (a nod; a shake and
## then following him out; a shake and staying), the ride's card, the camp's damage, what the
## survivors said through Joe (and "You knew that already." only if you'd followed Cody out), the
## costume, the trail read toward the hideout, and Joe walking with you after.

var holder: Node
var valley: ValleyWorld
var said: Array = []  # [speaker id, text]


func before_each() -> void:
	StoryState.clear()
	said.clear()
	if not Events.spoke.is_connected(_on_spoke):
		Events.spoke.connect(_on_spoke)


func after_each() -> void:
	if Events.spoke.is_connected(_on_spoke):
		Events.spoke.disconnect(_on_spoke)
	StoryState.clear()
	if holder != null and is_instance_valid(holder):
		holder.queue_free()
		holder = null
		await physics_frames(3)


func _on_spoke(who: Node, text: String) -> void:
	said.append([String((who as HumanBody).person_id) if who is HumanBody else "?", text])


func _lines_of(id: String) -> Array:
	return said.filter(func(s: Array) -> bool: return s[0] == id).map(func(s: Array) -> String: return s[1])


func _player() -> Player:
	return get_tree().get_first_node_in_group(&"player") as Player


func _put(at: Vector3) -> void:
	var p := _player()
	p.global_position = at + Vector3.UP * 0.1
	p.velocity = Vector3.ZERO


func _nod(p: Player) -> void:
	for k: float in [0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5, 0.0, 0.5, 1.0, 0.5, 0.0]:
		p.add_look(Vector2(0.0, -12.0 * k - p.get_pitch_degrees()))
		await physics_frames(3)


func _shake(p: Player) -> void:
	for k: float in [0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5, 0.0, 0.5, 1.0, 0.5, 0.0]:
		p.add_look(Vector2(12.0 * k, 0.0))
		await physics_frames(3)


## The valley, the scene set up, you walked into the front office and asked; returns the act.
func _to_the_ask(opts := {}) -> NoJusticeCamp:
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(5)
	var o := {"set_up": true, "pace": 0.25, "joe_walk": 4.0}
	o.merge(opts, true)
	var m := Moment.start_named(&"no_justice_camp", valley, null, o) as NoJusticeCamp
	check(m != null and not m.done, "it starts (%s)" % (m.result() if m else {}))
	if m == null or m.done:
		return null
	var p := _player()
	check(p.carries(p.revolver()), "the sheriff's revolver is yours by now")
	check(m.joe != null and m.joe_brain.held, "Joe's there, held by the scene")
	check(m.doctor != null and m.cowboy != null, "the doctor and the cowboy are there")
	check(not m.folk.people.has(&"earl"), "Earl's at the undertaker's, not at cards")
	await physics_frames(10)
	check_eq(m.state, &"walk_in", "waiting for you to come in")
	_put(m._local([4.6, 1.2]))
	var asked := await wait_until(func() -> bool: return m._waiting, 60 * 60)
	check(asked, "to the ask (%s)" % m.result())
	check(_lines_of("doc").has("Bring them in if you like. I never yet saw a white man hang on an Indian's word."), "the doctor's warning (%s)" % [_lines_of("doc")])
	check(_lines_of("cowboy").has("Doc's right. No jury in Colorado'll hang a white man for a Ute woman. I've seen 'em try."), "the cowboy's (%s)" % [_lines_of("cowboy")])
	check(_lines_of("joe").has("I ride today. Will you come?"), "Joe asks (%s)" % [_lines_of("joe")])
	return m


## Out after Joe, the card, and the camp played through.
func _out_and_camp(m: NoJusticeCamp) -> void:
	var out := await wait_until(func() -> bool: return m.state == &"out", 60 * 5)
	check(out, "Joe goes out (%s)" % m.result())
	await physics_frames(60 * 2)
	_put(m._local([4.0, -5.5]))
	var rode := await wait_until(func() -> bool: return m.state in [&"ride", &"camp"], 60 * 20)
	check(rode, "the ride's card (%s)" % m.result())
	check(m.ride_s > 600.0 and m.ride_s < 2400.0, "the ride takes 10-40 minutes (%.0f s)" % m.ride_s)
	var at_camp := await wait_until(func() -> bool: return m.state == &"camp", 60 * 8)
	check(at_camp, "at the camp (%s)" % m.result())
	var p := _player()
	var place := ValleyLayout.main().place_at("ute_community")
	check(Vector2(p.global_position.x, p.global_position.z).distance_to(place) < 60.0, "you're at the Ute camp (%s)" % p.global_position)
	check(p.input_enabled, "your hands back after the card")
	var c := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	if c:
		check(c.time_of_day > 10.5 and c.time_of_day < 12.0, "you come in by daylight, the ride's minutes on (%.2f h)" % c.time_of_day)
	check(m.props.size() >= 6, "the raid's damage (%d props)" % m.props.size())
	var over := await wait_until(func() -> bool: return m.done, 60 * 150)
	check(over, "it plays out (%s)" % m.result())
	check(m.holes >= 6, "balls put through the camp's things (%d)" % m.holes)
	var jl := _lines_of("joe")
	check(jl.has("Wait here."), "Joe: wait here (%s)" % [jl])
	check(jl.has("The one who did it to her wore a red shirt. Faded. That is all they saw of him. It is enough."), "the faded red shirt (S1)")
	check(jl.has("They went toward the hills. That way."), "which way they went (S10)")
	check(jl.has("If they see a Ute, they go to the camp after. If they see a cowboy, they come to me."), "why the costume (S12)")
	check(jl.has("Six horses. One throws his right fore."), "he reads the trail")
	check(m.joe_brain.costume and StoryState.get_fact("nojustice.costume") == true, "in the cowboy's hat")
	check(not m.joe_brain.held, "with you again")
	check_eq(StoryState.get_fact("nojustice.camp"), "came", "nojustice.camp")
	check_eq(StoryState.get_fact("nojustice.trail"), "hideout", "nojustice.trail")
	# He walks with you now: you go 20 m on, he comes.
	_put(p.global_position + m.camp_on * 20.0)
	await physics_frames(60 * 8)
	check(Vector2(m.joe.global_position.x - p.global_position.x, m.joe.global_position.z - p.global_position.z).length() < 9.0, "Joe follows you (%s)" % m.result().get("you_to_joe_m"))


func test_nod_and_ride() -> void:
	var m := await _to_the_ask()
	if m == null:
		return
	await _nod(_player())
	await _out_and_camp(m)
	check_eq(m.met, "nod", "you nodded")
	check_eq(StoryState.get_fact("nojustice.met"), "nod", "nojustice.met")
	check(_lines_of("joe").has("Then we go now."), "Joe: then we go now")
	check(not _lines_of("joe").has("You knew that already."), "you didn't follow Cody: no 'you knew'")
	check_eq(StoryState.get_fact("nojustice.knew_the_way"), false, "nojustice.knew_the_way")


func test_shake_then_follow_him_out_and_you_knew() -> void:
	var m := await _to_the_ask({"followed": true})
	if m == null:
		return
	await _shake(_player())
	await _out_and_camp(m)
	check_eq(m.answer, "shake", "you shook your head")
	check(_lines_of("joe").has("No. I did not think so."), "Joe: I did not think so")
	check_eq(StoryState.get_fact("nojustice.met"), "followed", "followed him out: you came anyway")
	check(_lines_of("joe").has("You knew that already."), "you'd followed Cody out: he sees you knew (S10)")
	check_eq(StoryState.get_fact("nojustice.knew_the_way"), true, "nojustice.knew_the_way")


func test_shake_and_stay() -> void:
	var m := await _to_the_ask()
	if m == null:
		return
	await _shake(_player())
	var over := await wait_until(func() -> bool: return m.done, 60 * 30)
	check(over and m.state == &"declined", "he rides alone (%s)" % m.result())
	check_eq(StoryState.get_fact("nojustice.met"), "declined", "nojustice.met")
	check(not StoryState.has_fact("nojustice.camp"), "no camp")
