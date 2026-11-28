extends BridgeLab
## The crowd lab's dev bridge commands (#1303, the AI crowd bake-off; README.md beside this file):
## men of any model walking, standing or sat where the bridge puts them, the private cast held off
## so each keeps his own model, and the triangles each of his levels draws. Changes nothing in the
## game; debug builds only, as the bridge is.

const HELP := {
	"crowd_hold": "crowd_hold -> the private cast held off (each man keeps the model he's given)",
	"crowd_walk": "crowd_walk MODEL X Y Z TX TZ [SPEED] -> a man of that model walking from X Y Z to TX TZ (SPEED m/s, 1.3), no brain; back and forth until crowd_clear",
	"crowd_pose": "crowd_pose PERSON stand|sit|crouch -> his pose",
	"crowd_lods": "crowd_lods MODEL -> the triangles of his mesh at each level Godot's importer cut",
	"crowd_clear": "crowd_clear -> the lab's men gone",
}

var _n := 0
var _walkers := []      # [man, a, b, speed, heading_to_b]


func _cmd_crowd_hold(_a: Array) -> Dictionary:
	PeopleBodies.cast_suspended = true
	return {"cast_suspended": true}


func _cmd_crowd_walk(a: Array) -> Dictionary:
	if a.size() < 6:
		return {"ok": false, "error": HELP.crowd_walk}
	var model := StringName(a[0])
	if not PeopleBodies.has_model(model):
		return {"ok": false, "error": "no assets/people/%s.glb" % model}
	_n += 1
	var m := HumanBody.new()
	m.has_gun = false
	m.body_model = model
	m.rng_seed = 1300 + _n
	m.person_id = StringName("crowd%d" % _n)
	m.name = "Crowd%d" % _n
	var from := vec(a, 1)
	var to := Vector3(float(a[4]), from.y, float(a[5]))
	m.enter(street, from, HumanBody.yaw_toward(from, to))
	_walkers.append([m, from, to, float(a[6]) if a.size() > 6 else 1.3, true])
	await physics_frames(3)
	return {"person": String(m.person_id), "model": String(model)}


func _physics_process(delta: float) -> void:
	for w in _walkers:
		var m: HumanBody = w[0]
		if not is_instance_valid(m):
			continue
		if m.walk_to(w[2] if w[4] else w[1], w[3], delta):
			w[4] = not w[4]


func _cmd_crowd_pose(a: Array) -> Dictionary:
	var m := person(String(a[0])) if a.size() > 1 else null
	if m == null:
		return {"ok": false, "error": HELP.crowd_pose}
	m.set_pose(StringName(a[1]))
	await physics_frames(30)
	return {"person": String(a[0]), "pose": String(m.pose)}


func _cmd_crowd_lods(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": HELP.crowd_lods}
	var scene := load("res://assets/people/%s.glb" % a[0]) as PackedScene
	if scene == null:
		return {"ok": false, "error": "no assets/people/%s.glb" % a[0]}
	var root := scene.instantiate()
	var out := []
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := (mi as MeshInstance3D).mesh as ArrayMesh
		if mesh == null:
			continue
		for s in mesh.get_surface_count():
			var arrays := mesh.surface_get_arrays(s)
			var levels := [int(arrays[Mesh.ARRAY_INDEX].size() / 3)]
			# The importer's levels live in the server's surface: each a block of indices
			# (16-bit under 65,536 vertices, else 32-bit).
			var surf: Dictionary = RenderingServer.mesh_get_surface(mesh.get_rid(), s)
			var bytes := 2 if arrays[Mesh.ARRAY_VERTEX].size() <= 65535 else 4
			for lod in surf.get("lods", []):
				levels.append(int(lod["index_data"].size() / (bytes * 3)))
			out.append({"mesh": String(mi.name), "surface": s, "triangles": levels})
	root.free()
	return {"model": String(a[0]), "meshes": out}


func _cmd_crowd_clear(_a: Array) -> Dictionary:
	for w in _walkers:
		if is_instance_valid(w[0]):
			w[0].queue_free()
	_walkers.clear()
	return {"cleared": true}
