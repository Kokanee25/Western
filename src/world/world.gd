class_name World
extends Object
## The rules every system keeps so a fight runs the same twice (docs/briefs/more-cores.md, "The
## design" F): under `deterministic` nothing that decides what happens in a tick reads the wall
## clock. Work spread over frames by a budget (a settle, the fire's look at a burning building,
## the batches' rebuild) is budgeted by a count instead of milliseconds (`WorkBudget`), and its
## gaps are kept in physics frames (`now()`).

## On for the tests (`tests/run_tests.gd`) and the labs (`-- --deterministic`, or
## `application/run/deterministic=true` in an override.cfg); off in the game, where a slow machine
## spreads a collapse over more frames rather than taking one long one.
static var deterministic: bool = bool(ProjectSettings.get_setting("application/run/deterministic", false)) \
		or "--deterministic" in OS.get_cmdline_user_args()


## Seconds, for the gaps between spread-out work: the wall clock, or under `deterministic` the
## physics frames so far.
static func now() -> float:
	if deterministic:
		return Engine.get_physics_frames() / float(Engine.physics_ticks_per_second)
	return Time.get_ticks_msec() / 1000.0
