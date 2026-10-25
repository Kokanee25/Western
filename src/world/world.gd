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


## The physics space `node` is in, for a query (a ray, a shape, a cast). Every query asks here: with
## physics on its own thread the space can only be asked inside the physics frame (outside it,
## Godot has none to give), and inside it every query sees the world as the last step left it,
## whoever moved what this tick. A debug build says once for each place that asks outside it.
static func space(node: Node) -> PhysicsDirectSpaceState3D:
	if OS.is_debug_build() and not Engine.is_in_physics_frame():
		_outside(get_stack())
	var w: World3D = (node as Node3D).get_world_3d() if node is Node3D else (node.get_viewport().find_world_3d() if node and node.get_viewport() else null)
	return w.direct_space_state if w else null


static var _told := {}


static func _outside(stack: Array) -> void:
	var at: Dictionary = stack[1] if stack.size() > 1 else {}
	var site := "%s:%d in %s" % [at.get("source", "?"), at.get("line", 0), at.get("function", "?")]
	if _told.has(site):
		return
	_told[site] = true
	var chain := " <- ".join(stack.slice(1, 5).map(func(f: Dictionary) -> String: return "%s:%d" % [String(f.source).get_file(), f.line]))
	push_error("a physics query outside the physics frame: %s (%s)" % [site, chain])
