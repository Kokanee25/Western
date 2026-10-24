extends BridgeLab
## The prop lab's dev bridge commands (README.md beside this file): kit props put down in the
## running town, for the prop factory's contact sheets (docs/briefs/prop-factory.md) shot in the
## game's own light. Lab only: what it puts down isn't saved and the town never places it.

const HELP := {
	"prop": "prop ID X Y Z [YAW] -> a kit prop (assets/props/kit/ID.json) put down there in the street, turned YAW degrees: its members, weight, whether it stands",
	"props_clear": "props_clear -> takes away every prop `prop` put down",
	"props_of": "props_of ID -> where the town's kit props of that id are (a hung deer head, the saloon's barrels): positions and which way they face",
}

var _placed: Array[Node3D] = []


func _cmd_prop(a: Array) -> Dictionary:
	if a.size() < 4 or not PropKit.has(StringName(a[0])):
		return {"ok": false, "error": "prop ID X Y Z [YAW] (a kit file's id)"}
	var p := PropKit.make(StringName(a[0]))
	var at := vec(a, 1)
	var yaw := deg_to_rad(float(a[4])) if a.size() > 4 else 0.0
	street.add_child(p)
	p.global_transform = Transform3D(Basis(Vector3.UP, yaw), at)
	_placed.append(p)
	await physics_frames(KitProp.SETTLE_FRAMES + 2)
	var out := {"id": String(a[0]), "at": arr(p.global_position)}
	if p is KitProp:
		out["members"] = (p as KitProp).member_count()
		out["kg"] = snappedf((p as KitProp).mass(), 0.1)
		out["stands"] = not (p as KitProp).loose
	return out


func _cmd_props_clear(_a: Array) -> Dictionary:
	var n := 0
	for p in _placed:
		if is_instance_valid(p):
			p.queue_free()
			n += 1
	_placed.clear()
	return {"cleared": n}


func _cmd_props_of(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": "props_of ID"}
	var found := []
	for n: Node in get_tree().root.find_children("*", "Node3D", true, false):
		if n is KitProp and String((n as KitProp).kit_id) == String(a[0]):
			var p := n as Node3D
			found.append({"at": arr(p.global_position), "facing": arr(p.global_basis.z.normalized())})
	return {"props": found}
