class_name DeedWatch
## Turns what happens into deeds and noises that people can perceive: a shot is loud (heard across
## town) and is a deed against everyone it passes close to; a hit, a death, a surrender, a shout.
## Wired once to the event bus (Events._ready).

## How far sounds carry (m).
const GUNSHOT := 350.0
const BLAST := 900.0
const SHOUT := 45.0
const SPEECH := 14.0
## A shot "at" someone: its line passes this close to him within this range.
const SHOT_AT_WITHIN := 2.2
const SHOT_RANGE := 90.0


static func install(events: Node) -> void:
	events.shot_fired.connect(_on_shot)
	events.exploded.connect(func(at: Vector3, _kg: float) -> void: events.noise.emit(at, BLAST, &"blast", null))
	events.person_died.connect(_on_death)
	events.person_surrendered.connect(func(p: Node) -> void:
		events.deed.emit(p, &"surrender", null, (p as Node3D).global_position if p is Node3D else Vector3.ZERO))
	events.spoke.connect(func(p: Node, _t: String) -> void:
		if p is Node3D:
			events.noise.emit((p as Node3D).global_position + Vector3.UP * 1.6, SPEECH, &"speech", p))
	events.shouted.connect(func(p: Node, _k: StringName) -> void:
		if p is Node3D:
			events.noise.emit((p as Node3D).global_position + Vector3.UP * 1.6, SHOUT, &"shout", p))


static func _on_shot(origin: Vector3, dir: Vector3, shooter: Node) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	Events.noise.emit(origin, GUNSHOT, &"gunshot", shooter)
	if tree == null:
		return
	var d := dir.normalized()
	for p: Node in tree.get_nodes_in_group(&"people") + tree.get_nodes_in_group(&"player"):
		if p == shooter or not p is Node3D:
			continue
		var at := (p as Node3D).global_position + Vector3.UP * 1.2
		var along := (at - origin).dot(d)
		if along < 0.0 or along > SHOT_RANGE:
			continue
		if (origin + d * along).distance_to(at) < SHOT_AT_WITHIN:
			Events.deed.emit(shooter, &"shoot_at", p, origin)


static func _on_death(person: Node, _cause: StringName) -> void:
	# Who did it: the last man to hit him (HumanBody keeps note).
	var killer: Node = person.get_meta(&"last_hit_by") if person and person.has_meta(&"last_hit_by") else null
	if killer and is_instance_valid(killer):
		Events.deed.emit(killer, &"kill", person, (person as Node3D).global_position)
