extends Node
## The event bus. Systems announce what happened here and anything that cares listens, so fire,
## structures, bodies, sound, witnesses and memory can react to each other without knowing each
## other's internals. Keep signals small and explicit.

## Look input in degrees: x turns right, y pitches up. Sent by the mouse and touch screen; the player polls the stick itself.
signal look_input(delta_degrees: Vector2)
## The in-game clock entered a new hour (0-23).
signal hour_changed(hour: int)
## A new in-game day began. Day 1 is the first morning.
signal day_started(day: int)
## The debug time multiplier changed.
signal time_scale_changed(scale: float)
## A gun went off: where, which way, and who fired (for sound, witnesses, smoke...).
signal shot_fired(origin: Vector3, direction: Vector3, shooter: Node)
## A bullet struck something. info: position, normal, direction, collider, member_id (if a building
## member), penetrated (bool), energy_before / energy_after (joules).
signal bullet_hit(info: Dictionary)
