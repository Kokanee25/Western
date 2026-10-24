extends BridgeLab
## The ragdoll lab's dev bridge commands (README.md beside this file): men in the game's kit chairs,
## for footage of the chair falls in the town (results/2026-10-24_chair_tip).

const HELP := {
	"seat": "seat PERSON [X Y Z] -> sit him now in the free kit chair nearest him (or X Y Z), sat back (Seating)",
	"chair_kick_spot": "chair_kick_spot PERSON [side|behind] -> where you stand (x y z yaw) to kick his chair's near back leg out with E (PlayerKick), from his side or behind",
	"kick_chair": "kick_chair KICKER PERSON [front|sweep] [side|behind] -> KICKER walks to the kick spot of PERSON's chair and kicks it (HumanBody.kick); what the boot did",
}


## The chair he's sat in, or null.
func _chair_of(man: HumanBody) -> KitProp:
	for c in man.get_tree().get_nodes_in_group(&"structures"):
		if c is KitProp and (c as KitProp).seated == man:
			return c
	for c in man.get_tree().root.find_children("*", "KitProp", true, false):
		if (c as KitProp).seated == man:
			return c
	return null


func _cmd_seat(a: Array) -> Dictionary:
	var man := person(String(a[0])) if not a.is_empty() else null
	if man == null:
		return {"ok": false, "error": "seat PERSON [X Y Z]"}
	var near := vec(a, 1) if a.size() >= 4 else man.global_position
	# A chair (back legs to kick out), not a stool: the free one nearest.
	var chair: KitProp = null
	for c: Node in man.get_tree().get_nodes_in_group(&"structures"):
		var kp := c as KitProp
		if kp and kp.kit_id == &"chair" and not kp.loose and kp.seated == null and kp.is_inside_tree() \
				and (chair == null or kp.seat_position().distance_to(near) < chair.seat_position().distance_to(near)):
			chair = kp
	if chair == null:
		return {"ok": false, "error": "no free kit chair near %s" % [arr(near)]}
	# Put a step in front of it, then he sits as he would: his brain's drink sat down (an outlaw's),
	# or Seating's walk and sit.
	var out := chair.global_basis.z
	out.y = 0.0
	man.global_position = Seating.spot(chair) + out.normalized() * 0.7
	var brain := man.get_node_or_null(^"Brain")
	if brain and brain.get(&"agenda") is Array:
		(brain.agenda as Array).insert(0, {"do": &"drink", "seconds": 900.0, "face": Seating.faces(chair), "first": false, "sit": true})
		brain.set(&"_step_started", false)
		brain.set(&"_chair", chair)
	for i in 600:
		if chair.seated == man:
			break
		if brain == null:
			Seating.sit_step(man, chair, 1.0 / 60.0)
		await physics_frames(1)
	return {"ok": chair.seated == man, "chair": String(chair.structure_id), "at": arr(chair.global_position)}


## The near back leg of his chair from `from` (side: his right; behind) and where to stand to kick
## it (a man's kick_spot, a player 0.5 m off it).
func _spot(man: HumanBody, chair: KitProp, how: String, reach: float) -> Dictionary:
	var right := man.global_basis.x
	var back := man.global_basis.z
	var from := man.global_position + (right * 1.5 if how != "behind" else back * 1.5)
	var best: StructureMember = null
	for id in ["post_back_l", "post_back_r"]:
		var m := chair.get_member(StringName("%s/%s" % [chair.structure_id, id]))
		if m and not m.broken and (best == null or m.global_position.distance_to(from) < best.global_position.distance_to(from)):
			best = m
	if best == null:
		return {}
	var at := Vector3(best.global_position.x, chair.global_position.y + 0.07, best.global_position.z)
	var dir := Vector3(from.x - at.x, 0.0, from.z - at.z).normalized()
	var stand := at + dir * reach
	stand.y = chair.global_position.y
	return {"at": at, "stand": stand, "yaw": rad_to_deg(atan2(dir.x, dir.z))}


func _cmd_chair_kick_spot(a: Array) -> Dictionary:
	var man := person(String(a[0])) if not a.is_empty() else null
	var chair := _chair_of(man) if man else null
	if chair == null:
		return {"ok": false, "error": "chair_kick_spot PERSON [side|behind]: he isn't sat in a kit chair"}
	var s := _spot(man, chair, String(a[1]) if a.size() > 1 else "side", PlayerKick.FROM + 0.3)
	# Facing from north (-z), as `goto`: you face the leg.
	var f: Vector3 = (s.at - s.stand) * Vector3(1, 0, 1)
	return {"ok": true, "x": s.stand.x, "y": s.stand.y, "z": s.stand.z, "yaw": rad_to_deg(atan2(f.x, -f.z)), "leg": arr(s.at)}


func _cmd_kick_chair(a: Array) -> Dictionary:
	if a.size() < 2:
		return {"ok": false, "error": "kick_chair KICKER PERSON [front|sweep] [side|behind]"}
	var kicker := person(String(a[0]))
	var man := person(String(a[1]))
	var chair := _chair_of(man) if man else null
	if kicker == null or chair == null:
		return {"ok": false, "error": "no such kicker, or %s isn't sat in a kit chair" % a[1]}
	var how := StringName(a[2]) if a.size() > 2 else &"front"
	var s := _spot(man, chair, String(a[3]) if a.size() > 3 else "side", 1.0)
	var spot := kicker.kick_spot(s.at, s.stand)
	for i in 600:
		if kicker.walk_to(spot, 1.3, 1.0 / 60.0):
			break
		await physics_frames(1)
	kicker.face(s.at)
	await physics_frames(10)
	var result := [&"none"]
	kicker.kicked.connect(func(r: StringName) -> void: result[0] = r, CONNECT_ONE_SHOT)
	if not kicker.kick(s.at, how):
		return {"ok": false, "error": "out of his reach from %s" % [arr(kicker.global_position)]}
	await seconds(0.8)
	log_event("kick", "%s kicked %s's chair: %s" % [a[0], a[1], result[0]])
	return {"ok": true, "result": String(result[0]), "chair_loose": chair.loose, "down": man.limp}
