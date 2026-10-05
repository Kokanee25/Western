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
## A structure member broke (a pane shattered; in M3, boards and beams too).
signal member_broken(member_id: StringName)
## A bullet struck something. info: position, normal, direction, collider, member_id (if a building
## member), penetrated (bool), energy_before / energy_after (joules).
signal bullet_hit(info: Dictionary)
## A bullet went into a person. info: person (HumanBody), person_id, segment, hits
## ([{id, effect}]), position, direction, exit (world point or null), lodged (bool).
signal body_hit(info: Dictionary)
## A person went down (can't stand: shot in the leg, fainted, dead).
signal person_fell(person: Node, conscious: bool)
signal person_died(person: Node, cause: StringName)
## Someone shouted at the people around them ("Drop it!"). kind: &"drop_it" for now.
signal shouted(speaker: Node, kind: StringName)
## A bullet passed close by a person without hitting (the crack of a near miss): how close to
## his head, where it went by (nearest his head), how fast (m/s), and whether it's tumbling off a
## ricochet (it whizzes rather than snaps).
signal near_miss(person: Node, shooter: Node, distance: float, at: Vector3, speed: float, tumbling: bool)
## A ball took a man's hat off his head (the nearest near miss there is).
signal hat_shot(person: Node, shooter: Node, at: Vector3)
## Someone gave up: dropped their gun and put their hands up.
signal person_surrendered(person: Node)
## Someone said something out loud (shown as a subtitle to a player in earshot).
signal spoke(speaker: Node, text: String)
## Someone's too close to a fire: `amount` is how badly it burnt them this moment.
signal scorched(person: Node, amount: float)
## A charge went off: where, and how big (kg TNT).
signal exploded(at: Vector3, kg: float)
## A sound people might hear: where, how far it carries (m), what it was, and who made it.
signal noise(at: Vector3, loudness: float, kind: StringName, source: Node)
## Something someone did that others judge them by (Relations.WEIGHTS): drew, holstered, aimed at,
## shouted at, crowded, stared at, shot at, hit, killed, surrendered. `target` may be null.
signal deed(actor: Node, kind: StringName, target: Node, at: Vector3)
## A man shouting to his friends in a fight: kind (OutlawBrain.LINES "call_<kind>": &"reloading", &"hit",
## &"spotted", &"flank", &"covering", &"help", &"drag", &"down", &"dead", &"quit", &"fall_back",
## &"give_up"), who it's about (the man they're fighting, or a friend), and where (or Vector3.INF).
signal callout(speaker: Node, kind: StringName, about: Node, at: Vector3)
## Hours went by in a moment (the clock jumped: you were out cold, `why` &"out_cold"). Whatever
## runs on time catches up roughly: a fight is over, the gang's day is done, frights fade.
signal hours_passed(hours: float, why: StringName)
## Water thrown on a fire: where, how much (litres), and how many burning members it put out.
signal doused(at: Vector3, litres: float, put_out: int)


func _ready() -> void:
	DeedWatch.install(self)
