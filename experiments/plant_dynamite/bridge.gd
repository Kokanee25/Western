extends BridgeLab
## Planting dynamite (#506): what the stick in hand makes of the wall in front of you.

const HELP := {
	"plant_where": "plant_where -> where E would set the stick now (DynamiteViewmodel.plant_at), or why not: the hand's state and the eye ray's hit",
}


func _cmd_plant_where(_a: Array) -> Dictionary:
	var d := player.dynamite()
	await physics_frames(1)
	var cam := player.camera
	var out := {"selected": d.selected, "drawn": d.drawn, "sticks": d.sticks, "has_stick": d.has_stick(),
			"lit": d.lit, "hands_busy": d.hands_busy, "feet": snappedf(player.global_position.y, 0.001),
			"planting": d.planting, "planted": d.planted != null, "spot": {}}
	if not d.plant_at.is_empty():
		out.spot = {"at": arr(d.plant_at.at), "wall": arr(d.plant_at.wall)}
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position - cam.global_basis.z * 3.0, Layers.WORLD)
	q.exclude = [player.get_rid()]
	var hit := World.space(player).intersect_ray(q) if Engine.is_in_physics_frame() else {}
	if not hit.is_empty():
		out.eye_hit = {"at": arr(hit.position), "normal": arr(hit.normal), "what": str(hit.collider.name)}
	return out
