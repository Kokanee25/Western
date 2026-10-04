class_name FrameBudget
extends Resource
## What each part of the frame may cost (config/frame_budget.tres; CLAUDE.md "Frame budget"):
## milliseconds a frame at 60 fps on one 3.25 GHz core (Sean's Shadow), with headroom under
## 16.7. `tools/perf_bench.gd` reports every scene against it (the "budget" lines); Prof's timers
## are summed into these parts by `parts`. The physics engine and render CPU aren't script timers:
## the bench measures the engine by pausing the physics server for a stretch, and render CPU only
## with --render (a real or software GPU).

## part -> ms a frame on the 3.25 GHz core.
@export var budgets := {
	&"people": 4.0, &"physics": 2.0, &"structures": 1.0, &"fire_effects": 2.0,
	&"render_cpu": 4.0, &"else": 1.0,
}
## The whole frame (the sum of the parts).
@export var total := 14.0
## part -> Prof systems (timer names) summed into it; anything not listed is "else".
@export var parts := {
	&"people": [&"people_body", &"people_skeleton", &"senses", &"outlaw_brain", &"civilian_brain",
			&"player", &"town_life", &"blood"],
	&"structures": [&"structures", &"voxels", &"ballistics"],
	&"fire_effects": [&"fire", &"smoke", &"dynamite"],
}
## This workspace's core against Sean's (2.1 / 3.25 GHz): the bench scales its wall-clock numbers
## by this before comparing them with the budgets.
@export var clock_scale := 0.65


## Which part a Prof system belongs to.
func part_of(system: StringName) -> StringName:
	for p: StringName in parts:
		if (parts[p] as Array).has(system):
			return p
	return &"else"
