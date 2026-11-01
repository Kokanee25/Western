extends BridgeLab
## The prop lab's dev bridge commands (README.md beside this file): kit props put down in the
## running town, for the prop factory's contact sheets (docs/briefs/prop-factory.md) shot in the
## game's own light. Lab only: what it puts down isn't saved and the town never places it.

const HELP := {
	"prop": "prop ID X Y Z [YAW] -> a kit prop (assets/props/kit/ID.json) put down there in the street, turned YAW degrees: its members, weight, whether it stands",
	"props_clear": "props_clear -> takes away every prop `prop` put down",
	"props_of": "props_of ID -> where the town's kit props of that id are (a hung deer head, the saloon's barrels): positions and which way they face",
	"deer_variant": "deer_variant ID [DIR] -> the town's hung deer heads made again as the deer fidelity lab's version ID (deer_fidelity/deer_variants.gd; DIR its files): the kit's own deer_head, its members drawn by that version; `game` the game's again, `none` none (the shots' background)",
}

var _deer_variants: RefCounted
var _deer_spots: Array = []
var _deer_heads: Array[Node] = []

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


## The deer fidelity lab (issue #524, deer_fidelity/README.md): every hung deer head in the town freed
## and made again where it hung, the kit's deer_head with its parts and material from the version
## (PropKit's and PropModels' caches, put back after: the game's files are never touched).
func _cmd_deer_variant(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": "deer_variant ID|game|none [DIR]"}
	var DV: GDScript = load("res://experiments/prop_lab/deer_fidelity/deer_variants.gd")
	if not a[0] in ["game", "none"] and not DV.VARIANTS.has(a[0]):
		return {"ok": false, "error": "versions: %s" % ", ".join(DV.VARIANTS.keys())}
	if _deer_variants == null or a.size() > 1:
		_deer_variants = DV.new(a[1] if a.size() > 1 else "")
	# Where the town hung them, the first time: each head's parent, place and name.
	if _deer_spots.is_empty():
		for n: Node in get_tree().root.find_children("*", "Node3D", true, false):
			if n is KitProp and (n as KitProp).kit_id == &"deer_head":
				_deer_spots.append([n.get_parent(), (n as Node3D).global_transform, n.name])
				_deer_heads.append(n)
	for p: Node in _deer_heads:
		if is_instance_valid(p):
			p.get_parent().remove_child(p)
			p.queue_free()
	_deer_heads.clear()
	if a[0] == "none":
		await physics_frames(2)
		return {"version": "none"}
	if a[0] != "game":
		_deer_variants.use_in_kit(a[0])
	for spot: Array in _deer_spots:
		var q := PropKit.make(&"deer_head")
		q.name = spot[2]
		(spot[0] as Node).add_child(q)
		q.global_transform = spot[1]
		_deer_heads.append(q)
	DV.restore()
	await physics_frames(KitProp.SETTLE_FRAMES + 4)
	var out := []
	for q: KitProp in _deer_heads:
		out.append({"at": arr(q.global_position), "hangs": not q.loose, "members": q.member_count()})
	return {"version": a[0], "heads": out}
