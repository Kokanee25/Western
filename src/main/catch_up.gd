class_name CatchUp
## How many physics ticks a frame may run to catch up with the clock (#1117). The game allows 2
## (project.godot, #435); the dev bridge raises it to 40 so a drawn run under lavapipe (a frame a
## second) keeps game time near real time. But once a tick costs as much as the 1/60 s it stands
## for, catching up can only fall further behind: every frame runs the most ticks it may, takes
## longer, and owes more ("the spiral of death", Glenn Fiedler's "Fix Your Timestep!"). The chaos
## playtest's 2 fps (physics 537 ms a frame for ~25 s) was that: ~35 ticks a frame after a blast.
## So the limit follows what a tick costs: when a tick costs nearly its own time, the floor (game
## time runs slower than the clock, as the game's own limit of 2 makes it); otherwise as many as fit
## in `wall_ms`, up to `most`. Nothing the player sees or does is skipped: the same ticks run, later.

## The most ticks a frame (the bridge's 40).
static var most := 40
## The fewest (the game's own, project.godot).
static var least := 2
## The wall time (ms) a frame's catching up may take.
static var wall_ms := 400.0
## A tick's cost (ms), smoothed over the last few frames.
static var tick_ms := 0.0


## After a frame that ran `ticks` physics ticks in `physics_ms`: the limit for the next frame,
## set on the engine.
static func after_frame(physics_ms: float, ticks: int) -> int:
	if ticks > 0:
		var per := physics_ms / ticks
		tick_ms = per if tick_ms <= 0.0 else lerpf(tick_ms, per, 0.3)
	var n := limit_for(tick_ms)
	Engine.max_physics_steps_per_frame = n
	return n


## The limit when a tick costs `ms`.
static func limit_for(ms: float) -> int:
	if ms <= 0.0:
		return most
	if ms >= 0.9 * 1000.0 / Engine.physics_ticks_per_second:
		return least
	return clampi(int(wall_ms / ms), least, most)
