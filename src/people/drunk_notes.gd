class_name DrunkNotes
extends Node3D
## The town drunk's notes about town (#1312; config/drunk_notes.json): rhymes chalked on a wall, a note
## nailed to a door, a bill tacked up, a picture scratched in the boards, all about the deputy, for the
## player to find. Gameplay's (src/people); the lettering is SignArt's where the factory has painted it
## (`SignArt.letters`, none yet for these), else a hand's Label3D on the note's stuff: pencil on paper,
## chalk on stone or boards, a knife's scratches on wood (a picture's strokes are data: `strokes`).
##
## - **Placed by data**: a lot (`lot`, `a` m east of its west side, `b` m off its front, as
##   ValleyFolk.lot_point) and a height (`up`); a ray from there into the lot (`into_m`) finds the wall
##   and the note goes flat on it. Nothing hit: on a stake there, facing the street.
## - **Turns up over the days** (`appears`): from a town day (`day`, the day the badge went on is the
##   first), after the story's facts hold (`fact`, ValleyFolk.story_holds), or the morning after a deed of
##   Harlan's (`after`: a TownDrunk deed kind, `after_h` game hours on: he's heard of it and had a drink
##   over it). Once up it stays
##   (the card: "Whatever notes and chalked insults he left about town stay where they are").
## - **Read up close**: you within `read_m`, looking at it (`read_deg`), its face to you: its words on
##   screen (PlayerWounds.say, held), counted read (TownDrunk.read_note) and saved.

const PATH := "res://config/drunk_notes.json"

var folk: ValleyFolk
var d: Dictionary = {}
## Note id -> its node, once up.
var up := {}
## Note id -> the town day it went up.
var up_day := {}
## Note id -> the town day it was first read.
var read := {}
## Deed kind -> when it was first done (the folk's _abs_hours; `after` notes go up `after_h` on).
var after := {}
var _t := 0.0
var _reading := ""


func _init(f: ValleyFolk = null) -> void:
	folk = f
	name = "DrunkNotes"
	if FileAccess.file_exists(PATH):
		d = JSON.parse_string(FileAccess.get_file_as_string(PATH))


func _n(k: String, dflt: float) -> float:
	return float(d.get(k, dflt))


func notes() -> Array:
	return d.get("notes", [])


func note(id: String) -> Dictionary:
	for n: Dictionary in notes():
		if String(n.id) == id:
			return n
	return {}


## Is `n` due up on town day `day`?
func due(n: Dictionary, day: int) -> bool:
	var a: Dictionary = n.get("appears", {})
	if a.has("fact") and not ValleyFolk.story_holds(a.fact):
		return false
	if a.has("day"):
		var first := int(StoryState.get_fact("drunk.badge_day", -1))
		if first < 0 or day - first + 1 < int(a.day):
			return false
	if a.has("after"):
		var k := String(a.after)
		if not after.has(k) or _now() < float(after[k]) + float(a.get("after_h", _n("after_h", 2.0))):
			return false
	return true


func _now() -> float:
	return folk._abs_hours() if folk != null else 0.0


## Harlan did `kind` (TownDrunk.did): an `after` note for it goes up `after_h` later.
func deed(kind: String) -> void:
	if not after.has(kind):
		after[kind] = _now()


func step(delta: float) -> void:
	_t -= delta
	if _t > 0.0 or folk == null:
		return
	_t = _n("look_s", 0.25)
	var day := folk.town_day()
	if StoryState.has_fact("nolaw.deputy") and not StoryState.has_fact("drunk.badge_day"):
		StoryState.set_fact("drunk.badge_day", day)
	for n: Dictionary in notes():
		var id := String(n.id)
		if not up.has(id) and n.has("lot") and due(n, day) and not _in_view(n):
			put_up(n, day)
	_read_step()


## Not put up under your eyes (nothing appears in view): its spot seen, it waits.
func _in_view(n: Dictionary) -> bool:
	var at := _ray_start(n)
	return at != Vector3.INF and folk.seen(at)


func _ray_start(n: Dictionary) -> Vector3:
	if not n.has("lot"):
		return Vector3.INF
	return folk.lot_point(String(n.lot), float(n.get("a", 0.0)), float(n.get("b", -1.0)), float(n.get("up", 1.5)))


## Up it goes (built and placed): its node.
func put_up(n: Dictionary, day: int) -> Node3D:
	var id := String(n.id)
	var node := build(n)
	add_child(node)
	_place(node, n)
	up[id] = node
	up_day[id] = day
	return node


## Flat on the wall the ray finds going into the lot, a hair proud; else on a stake facing the street.
func _place(node: Node3D, n: Dictionary) -> void:
	var from := _ray_start(n)
	if from == Vector3.INF:
		return
	var lot := String(n.lot)
	var a := float(n.get("a", 0.0))
	var b := float(n.get("b", -1.0))
	var into := folk.lot_point(lot, a, b + 1.0) - folk.lot_point(lot, a, b)
	into.y = 0.0
	into = into.normalized()
	var to := from + into * float(n.get("into_m", 3.0))
	var hit := {}
	if is_inside_tree():
		var q := PhysicsRayQueryParameters3D.create(from, to, Layers.WORLD)
		hit = get_world_3d().direct_space_state.intersect_ray(q)
	var at := from + into * float(n.get("into_m", 3.0)) * 0.5
	var normal := -into
	if not hit.is_empty():
		normal = (hit.normal as Vector3)
		normal.y = 0.0
		normal = normal.normalized() if normal.length() > 0.1 else -into
		at = (hit.position as Vector3) + normal * 0.012
	# The note's +z its face (out of the wall).
	node.global_transform = Transform3D(Basis.looking_at(-normal, Vector3.UP), at)
	node.set_meta(&"normal", normal)
	node.set_meta(&"on_wall", not hit.is_empty())


## The note: its stuff (paper, a bill, chalk, a scratch) and its words or picture. Local +z its face.
static func build(n: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Note_" + String(n.id)
	var kind := String(n.get("kind", "paper"))
	var size: Array = n.get("size", [0.22, 0.28])
	var w := float(size[0])
	var h := float(size[1])
	if kind in ["paper", "bill"]:
		var sheet := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(w, h, 0.002)
		sheet.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.86, 0.82, 0.7) if kind == "paper" else Color(0.9, 0.86, 0.72)
		mat.roughness = 1.0
		sheet.material_override = mat
		root.add_child(sheet)
		var nail := MeshInstance3D.new()
		var nm := BoxMesh.new()
		nm.size = Vector3(0.012, 0.012, 0.01)
		nail.mesh = nm
		var nmat := StandardMaterial3D.new()
		nmat.albedo_color = Color(0.2, 0.18, 0.16)
		nail.material_override = nmat
		nail.position = Vector3(0.0, h * 0.5 - 0.02, 0.004)
		root.add_child(nail)
	var ink := Color(0.16, 0.14, 0.13)  # pencil
	if kind == "chalk":
		ink = Color(0.88, 0.87, 0.82)
	elif kind == "scratch":
		ink = Color(0.72, 0.62, 0.46)  # the pale wood under the weathered grey
	elif kind == "bill":
		ink = Color(0.1, 0.08, 0.07)
	var shown := String(n.get("shows", n.get("text", "")))
	if shown != "":
		var painted := SignArt.letters(String(n.id))
		if painted != null:
			var quad := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(w * 0.92, h * 0.92)
			quad.mesh = qm
			var qmat := StandardMaterial3D.new()
			qmat.albedo_texture = painted
			qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			quad.material_override = qmat
			quad.position.z = 0.003
			root.add_child(quad)
		else:
			var l := Label3D.new()
			l.text = shown
			l.modulate = ink
			l.outline_size = 0
			l.font_size = int(n.get("font", 40))
			l.pixel_size = float(n.get("pixel", 0.0016))
			l.width = w / l.pixel_size * 0.92
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.shaded = false
			l.double_sided = false
			l.alpha_cut = Label3D.ALPHA_CUT_OPAQUE_PREPASS
			l.position = Vector3(0.0, float(n.get("text_y", 0.0)), 0.003)
			l.name = "Words"
			root.add_child(l)
	# A picture's strokes ([x0, y0, x1, y1] in metres on the note, from its middle), thin as a knife's cut.
	for s: Array in n.get("strokes", []):
		var a := Vector2(float(s[0]), float(s[1]))
		var b := Vector2(float(s[2]), float(s[3]))
		var len := a.distance_to(b)
		if len < 0.001:
			continue
		var m := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(len, float(n.get("stroke_w", 0.012)), 0.002)
		m.mesh = sm
		var smat := StandardMaterial3D.new()
		smat.albedo_color = ink
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.material_override = smat
		m.position = Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 0.003)
		m.rotation.z = atan2(b.y - a.y, b.x - a.x)
		root.add_child(m)
	return root


## You up close, looking at one: its words on screen.
func _read_step() -> void:
	var p := get_tree().get_first_node_in_group(&"player") as Player if is_inside_tree() else null
	if p == null or p.camera == null:
		return
	var best := ""
	for id: String in up:
		if readable_by(id, p.camera.global_position, -p.camera.global_basis.z):
			best = id
			break
	if best == _reading:
		return
	_reading = best
	if best == "":
		return
	var n := note(best)
	if p.wounds != null:
		p.wounds.say(String(n.get("read", "")) + "\n\"" + String(n.get("text", "")) + "\"", _n("read_s", 6.0), true)
	if not read.has(best):
		read[best] = folk.town_day()
		if folk.drunk != null:
			folk.drunk.read_note(best)


## Is note `id` read from `eye` looking along `fwd`: near, in front, its face to you?
func readable_by(id: String, eye: Vector3, fwd: Vector3) -> bool:
	var node: Node3D = up.get(id)
	if node == null or not is_instance_valid(node):
		return false
	var at := node.global_position
	var to := at - eye
	if to.length() > _n("read_m", 1.8):
		return false
	if rad_to_deg(fwd.angle_to(to)) > _n("read_deg", 22.0):
		return false
	var normal: Vector3 = node.get_meta(&"normal", node.global_basis.z)
	return normal.dot(-to) > 0.0


func to_dict() -> Dictionary:
	return {"up_day": up_day.duplicate(), "read": read.duplicate(), "after": after.duplicate()}


func from_dict(s: Dictionary) -> void:
	for id: String in up:
		if is_instance_valid(up[id]):
			(up[id] as Node).queue_free()
	up.clear()
	up_day = {}
	read = (s.get("read", {}) as Dictionary).duplicate()
	after = (s.get("after", {}) as Dictionary).duplicate()
	var days: Dictionary = s.get("up_day", {})
	for id: String in days:
		var n := note(id)
		if not n.is_empty():
			put_up(n, int(days[id]))
