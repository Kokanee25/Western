extends TestCase
## The single-action revolver's rules: cock for every shot, six chambers, click on empty,
## loading one chamber at a time through the gate, misfires, timings.

var gun: RevolverState


func before_each() -> void:
	gun = RevolverState.new(load("res://config/revolver.tres"))


func _wait() -> void:
	gun.tick(10.0)


func test_carried_with_five_and_the_hammer_on_an_empty() -> void:
	check_eq(gun.rounds_loaded(), 5, "five in the cylinder")
	check_eq(gun.chambers[gun.under_hammer], RevolverState.Chamber.EMPTY, "hammer rests on the empty chamber")
	check_eq(gun.hammer, RevolverState.Hammer.DOWN, "hammer down")


func test_trigger_does_nothing_until_cocked() -> void:
	check_eq(gun.pull_trigger(), RevolverState.Shot.NONE, "single action: trigger alone does nothing")
	check(gun.cock(), "cock")
	_wait()
	check_eq(gun.pull_trigger(), RevolverState.Shot.FIRED, "cocked, it fires")
	check_eq(gun.hammer, RevolverState.Hammer.DOWN, "hammer falls")
	_wait()
	check_eq(gun.pull_trigger(), RevolverState.Shot.NONE, "needs cocking again")


func test_cocking_turns_the_cylinder() -> void:
	var before := gun.under_hammer
	gun.cock()
	check_eq(gun.under_hammer, (before + 1) % 6, "one chamber on")
	_wait()
	check(not gun.cock(), "can't cock twice")


func test_five_shots_then_clicks() -> void:
	var results := []
	for i in 7:
		gun.cock()
		_wait()
		results.append(gun.pull_trigger())
		_wait()
	var fired := results.count(RevolverState.Shot.FIRED) + results.count(RevolverState.Shot.MISFIRE)
	check_eq(fired, 5, "five rounds go (fired or misfired)")
	check_eq(results[5], RevolverState.Shot.CLICK, "then it clicks on the empty")
	check_eq(gun.rounds_loaded(), 0, "nothing left")


func test_timing_limits_rate_of_fire() -> void:
	check(gun.cock(), "cock")
	check_eq(gun.pull_trigger(), RevolverState.Shot.NONE, "can't fire in the same instant as cocking")
	gun.tick(gun.tuning.cock_time)
	check_eq(gun.pull_trigger(), RevolverState.Shot.FIRED, "fires once the hammer is back")
	check(not gun.cock(), "recovering from the shot")


func test_reload_through_the_gate() -> void:
	for i in 5:
		gun.cock(); _wait(); gun.pull_trigger(); _wait()
	check_eq(gun.chambers.count(RevolverState.Chamber.SPENT) + gun.chambers.count(RevolverState.Chamber.DUD), 5, "five spent cases")
	var belt_before := gun.belt
	var steps := 0
	while gun.reload_step() and steps < 100:
		_wait()
		steps += 1
	check(gun.gate_open, "gate is open while loading")
	check_eq(gun.hammer, RevolverState.Hammer.HALF_COCK, "at half-cock")
	check_eq(gun.rounds_loaded(), 6, "all six loaded")
	check_eq(gun.belt, belt_before - 6, "six rounds came off the belt")
	check_eq(gun.pull_trigger(), RevolverState.Shot.NONE, "can't fire with the gate open")
	check(not gun.cock(), "can't cock with the gate open")
	check(gun.close_gate(), "close the gate")
	_wait()
	check(gun.cock(), "ready to shoot again")


func test_empty_belt_stops_loading() -> void:
	gun.belt = 1
	for i in 5:
		gun.cock(); _wait(); gun.pull_trigger(); _wait()
	var steps := 0
	while gun.reload_step() and steps < 100:
		_wait()
		steps += 1
	check_eq(gun.rounds_loaded(), 1, "only the one round went in")
	check_eq(gun.belt, 0, "belt empty")
	check_eq(gun.chambers.count(RevolverState.Chamber.SPENT), 0, "but the spent cases are all out")


func test_misfires_are_seeded() -> void:
	var t: RevolverTuning = load("res://config/revolver.tres").duplicate()
	t.misfire_chance = 1.0
	var dud := RevolverState.new(t)
	dud.cock()
	dud.tick(1.0)
	check_eq(dud.pull_trigger(), RevolverState.Shot.MISFIRE, "a dud")
	check_eq(dud.chambers[dud.under_hammer], RevolverState.Chamber.DUD, "stays in the chamber as a dud")


func test_state_round_trips() -> void:
	gun.cock(); _wait(); gun.pull_trigger()
	var other := RevolverState.new(load("res://config/revolver.tres"))
	other.from_dict(gun.to_dict())
	check_eq(other.to_dict(), gun.to_dict(), "saved and restored")
