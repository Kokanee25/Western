class_name ValleyStreetDressing
extends Node3D
## Main Street in the valley dressed as a busy 1882 street (#1304, art's): what each owner puts out
## before his lot (the store's freight on its dock and below it, the livery's hay, the saloon's kegs,
## rail and trough, the blacksmith's wheels) and what stands in the street itself (wagons out in it
## at angles with their teams standing, droppings), all from config/valley_street.json, so every lab,
## mission and save sees the same street. ValleyWorld's `MainStreetDressing`; `-- --no-street-dress` leaves
## it out (the bench's before).
##
## Built of the game's parts, nothing of its own: kit props (PropKit: they break, burn and fall as
## any), HitchingRail, WaterTrough and Horse (tied at a rail by `tie_to`, or standing in a wagon's
## traces). The livery's rail is RideThere's (a ride-to place's), not made again here.
##
## Kept clear: nothing stands within `clear_m` of a town link (ValleyTown.add_ways: the doors' flights,
## the walks' ways, the passages' mouths, the street's spine), of a folk's spot (valley_folk.json: where
## a man stands a while or sits) or of a RideThere horse's stand; such an
## entry is left out and said so (`skipped`; test_valley_street_dressing: none is).
##
## At rest it costs nothing it needn't: the kit props are Structures (members at rest, drawn batched),
## and a horse nobody can see holds his pose (`_wake`: his idle and the collision following it stop
## while he's off screen or past `HORSE_AWAKE_M`, and go on when he's seen again; his body stays where
## his mesh is, so a ball or a man finds him where he's drawn).

const CONFIG := "res://config/valley_street.json"
const FOLK_CONFIG := "res://config/valley_folk.json"
## `-- --no-street-dress`: the valley without it.
static var dress_default := not "--no-street-dress" in OS.get_cmdline_user_args()
## Beyond this (m from the camera) a horse holds his pose even on screen: his idle (a weight shift,
## an ear flick) is under a texel there.
const HORSE_AWAKE_M := 60.0
## How often the horses' wake is looked at (s).
const WAKE_EVERY := 0.25
## A horse's footprint in his own space (head toward -X), for keeping him off the ways.
const HORSE_BOX := Rect2(-1.35, -0.38, 2.5, 0.76)
## Things of different entries stand at least this far apart, or the gap between them would be a slot a
## man walks into and sticks in (m).
const GAP_M := 0.9
## A folk's spot is kept clear along the way to each of this many places nearest it.
const SPOT_WAYS := 3
## A town link counts if both its ends are within this box (Main Street and its walks).
const TOWN_X := Vector2(-135.0, 140.0)
const TOWN_Z := 14.0

var layout: ValleyLayout
var town: ValleyTown
## The valley's places (ValleyMarkers.places), whose links are kept clear.
var places: Waypoints
## RideThere, whose horses' stands are kept clear.
var ride: RideThere
var data := {}
## What was made: {what, at (global), node}.
var made: Array[Dictionary] = []
## Entries left out: "<where>: <what> (<why>)".
var skipped: Array[String] = []
var horses: Array[Horse] = []
var rails: Array[HitchingRail] = []

var _front := 10.05
var _clear := 0.55
var _segments: Array = []  # [Vector2 a, Vector2 b] in x, z
var _placed: Array = []  # what's down: [its corners in x, z, grown by half GAP_M, its entry]
var _group := 0  # the entry being put down: its own things may touch
var _wake_t := 0.0
var _n := 0


func _ready() -> void:
	name = &"MainStreetDressing"
	data = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if layout == null:
		layout = ValleyLayout.main()
	_front = float((layout.town().get("main_street", {}) as Dictionary).get("width_between_fronts", 20.1)) * 0.5
	_clear = float(data.get("clear_m", 0.55))
	_collect_ways()
	var lots: Dictionary = data.get("lots", {})
	for lot_id: String in lots:
		var lot := layout.lot(lot_id)
		if lot.is_empty():
			skipped.append("%s: no such lot" % lot_id)
			continue
		for e: Dictionary in lots[lot_id]:
			_entry(e, lot_id)
	for e: Dictionary in data.get("street", []):
		_entry(e, "street")
	if not skipped.is_empty():
		push_warning("ValleyStreetDressing: left out %d: %s" % [skipped.size(), skipped])


# --- Where things stand ---------------------------------------------------------------------------

func _north(lot_id: String) -> bool:
	return layout.lots("north").any(func(x: Dictionary) -> bool: return String(x.id) == lot_id)


## The point in x, z an entry's `along`/`out` (a lot's) or `x`/`z` (the street's) names, plus `d` more
## along and out.
func _xz(e: Dictionary, lot_id: String, d := Vector2.ZERO) -> Vector2:
	if lot_id == "street":
		return Vector2(float(e.get("x", 0.0)) + d.x, float(e.get("z", 0.0)) + d.y)
	var sgn := -1.0 if _north(lot_id) else 1.0
	var x := float(layout.lot(lot_id).get("x0", 0.0)) + float(e.get("along", 0.0)) + d.x
	return Vector2(x, sgn * (_front + float(e.get("out", 0.0)) + d.y))


## What stands there takes: a walk's planks or the ground.
func surface(x: float, z: float) -> float:
	return ValleyFolk.surface_of(town, x, z)


## Turned `deg` from the kit's own way (a north lot's things face the street the same as a south lot's
## mirrored: the yaw is as the data says, about +Y).
func _basis(deg: float) -> Basis:
	return Basis(Vector3.UP, deg_to_rad(deg))


## Turned `deg` and tilted to the ground's slope under (x, z), as a wagon's four wheels sit on it (the
## town's plane falls ~3 % across the street: a wagon set level stands on two wheels). On a walk's
## planks, or across a walk's edge, level.
func _on_ground(deg: float, x: float, z: float) -> Basis:
	var r := 0.8
	var hx0 := surface(x - r, z)
	var hx1 := surface(x + r, z)
	var hz0 := surface(x, z - r)
	var hz1 := surface(x, z + r)
	if absf(hx1 - hx0) > 0.2 or absf(hz1 - hz0) > 0.2:
		return _basis(deg)
	var n := Vector3(hx0 - hx1, 2.0 * r, hz0 - hz1).normalized()
	var tilt := Quaternion(Vector3.UP, n)
	return Basis(tilt) * _basis(deg)


# --- Kept clear -----------------------------------------------------------------------------------

func _collect_ways() -> void:
	_segments.clear()
	if places == null:
		return
	for a: StringName in places.links:
		var pa := places.at(a)
		if not _in_town(pa):
			continue
		for b: StringName in places.links[a]:
			if String(a) > String(b):
				continue
			var pb := places.at(b)
			if _in_town(pb):
				_segments.append([Vector2(pa.x, pa.z), Vector2(pb.x, pb.z)])
	# The folk's spots and places on the lots (config/valley_folk.json: where a man stands a while, sits on
	# a bench or leans), each with the step from it back to its walk's door line: they aren't town links.
	var folk: Variant = JSON.parse_string(FileAccess.get_file_as_string(FOLK_CONFIG))
	if folk is Dictionary:
		for group: String in ["spots", "places"]:
			var d: Dictionary = (folk as Dictionary).get(group, {})
			for id: String in d:
				var sp: Variant = d[id]
				if not sp is Dictionary or not (sp as Dictionary).has("lot") or not (sp as Dictionary).has("at"):
					continue
				var lot_id := String(sp.lot)
				if layout.lot(lot_id).is_empty():
					continue
				var at: Array = sp.at
				var a := _xz({"along": float(at[0]), "out": float(at[1])}, lot_id)
				# A man goes from it straight to a place near it (the steps' head, the door): its few nearest.
				var near: Array = []
				for pn: StringName in places.points:
					var pp := places.at(pn)
					var dd := Vector2(pp.x, pp.z).distance_to(a)
					if dd < 15.0:
						near.append([dd, Vector2(pp.x, pp.z)])
				near.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
				_segments.append([a, a])
				for k in mini(SPOT_WAYS, near.size()):
					_segments.append([a, near[k][1]])
	if ride:
		for id: StringName in ride.order:
			var s: Dictionary = ride.spots[id]
			var h: Vector3 = s.horse
			var st: Vector3 = s.stand
			# His stand and yours, and the way between: a short segment each.
			_segments.append([Vector2(h.x - 1.3, h.z), Vector2(h.x + 1.3, h.z)])
			_segments.append([Vector2(st.x, st.z), Vector2(h.x, h.z)])


func _in_town(p: Vector3) -> bool:
	return p.x > TOWN_X.x and p.x < TOWN_X.y and absf(p.z) < TOWN_Z


## Whether a footprint (a rect in its own x, z, placed by `xf`) is clear of every way by `_clear`.
func clear_of_ways(rect: Rect2, xf: Transform3D) -> bool:
	var r := rect.grow(_clear)
	var inv := xf.affine_inverse()
	for s: Array in _segments:
		var a: Vector2 = s[0]
		var b: Vector2 = s[1]
		var n := maxi(1, ceili(a.distance_to(b) / 0.2))
		for i in n + 1:
			var p := a.lerp(b, float(i) / n)
			var l := inv * Vector3(p.x, xf.origin.y, p.y)
			if r.has_point(Vector2(l.x, l.z)):
				return false
	return true


func _rect_of(box: AABB) -> Rect2:
	return Rect2(box.position.x, box.position.z, box.size.x, box.size.z)


# --- The entries ----------------------------------------------------------------------------------

func _entry(e: Dictionary, lot_id: String) -> void:
	# One heap (`pile`: a lot's freight, kegs and wheels together) may touch; else each entry its own.
	_group = hash(lot_id + "/" + String(e.pile)) if e.has("pile") else _group + 1
	if e.has("kit"):
		var n := int(e.get("n", 1))
		var rows := int(e.get("rows", 1))
		var step: Array = e.get("step", [0.0, 0.0])
		for i in n:
			for k in rows:
				var d := Vector2(float(step[0]) * i, float(step[1]) * i)
				var yaw := float(e.get("yaw", 0.0)) + float(e.get("turn", 0.0)) * i
				_kit(StringName(e.kit), _xz(e, lot_id, d), yaw, float(e.get("up", 0.0)) + float(e.get("layer", 0.0)) * k, lot_id)
	elif e.has("rail"):
		_rail(e, lot_id)
	elif e.has("trough"):
		_trough(e, lot_id)
	elif e.has("wagon"):
		_wagon(e, lot_id)
	elif e.has("horse"):
		var p := _xz(e, lot_id)
		var xf := Transform3D(_basis(float(e.get("yaw", 0.0))), Vector3(p.x, surface(p.x, p.y), p.y))
		if _check(HORSE_BOX, xf, lot_id, "horse"):
			_horse(xf)
	else:
		skipped.append("%s: %s (what is it?)" % [lot_id, e])


## Clear of the ways and, unless it's `stacked` on something, of what's already been put down; then
## its footprint is kept for the next.
func _check(rect: Rect2, xf: Transform3D, lot_id: String, what: String, stacked := false) -> bool:
	if not clear_of_ways(rect, xf):
		skipped.append("%s: %s at (%.1f, %.1f) (on a way)" % [lot_id, what, xf.origin.x, xf.origin.z])
		return false
	if stacked:
		return true
	var mine := _corners(rect, xf)
	var grown := _corners(rect.grow(GAP_M * 0.5), xf)
	for other: Array in _placed:
		# Its own entry's things may touch (a row of crates, a rail's horses); another's stands off by
		# GAP_M or touches nothing: no slot a man walks into and sticks (#1304: a wagon and the jail's horses).
		var hit := _overlap(mine, other[0]) if other[2] == _group else _overlap(grown, other[1])
		if hit:
			skipped.append("%s: %s at (%.1f, %.1f) (on or too near another thing)" % [lot_id, what, xf.origin.x, xf.origin.z])
			return false
	_placed.append([mine, grown, _group])
	return true


## A footprint's four corners on the ground (x, z), a hair inside it (things may touch).
static func _corners(rect: Rect2, xf: Transform3D) -> PackedVector2Array:
	var r := rect.grow(-0.02)
	var out := PackedVector2Array()
	for c: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var g := xf * Vector3(c.x, 0.0, c.y)
		out.append(Vector2(g.x, g.z))
	return out


## Two convex quads overlap (separating axes: each one's edge normals).
static func _overlap(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	for poly: PackedVector2Array in [a, b]:
		for i in poly.size():
			var e := poly[(i + 1) % poly.size()] - poly[i]
			var axis := Vector2(-e.y, e.x)
			var amin := INF
			var amax := -INF
			for p in a:
				amin = minf(amin, p.dot(axis))
				amax = maxf(amax, p.dot(axis))
			var bmin := INF
			var bmax := -INF
			for p in b:
				bmin = minf(bmin, p.dot(axis))
				bmax = maxf(bmax, p.dot(axis))
			if amax <= bmin or bmax <= amin:
				return false
	return true


## A kit prop standing with its footprint's middle on `p`.
func _kit(id: StringName, p: Vector2, yaw: float, up: float, lot_id: String) -> KitProp:
	if not PropKit.has(id):
		skipped.append("%s: %s (no such kit prop)" % [lot_id, id])
		return null
	var box := PropKit.bounds(PropKit.definition(id))
	var mid := box.get_center()
	var b := _on_ground(yaw, p.x, p.y)
	var at := Vector3(p.x, surface(p.x, p.y) + up, p.y) - b * Vector3(mid.x, 0.0, mid.z)
	var xf := Transform3D(b, at)
	if not _check(_rect_of(box), xf, lot_id, String(id), up > 0.001):
		return null
	_n += 1
	var prop := PropKit.spawn(id, StringName("street_%s_%d" % [id, _n]))
	prop.rests = true
	add_child(prop)
	prop.global_transform = xf
	made.append({"what": id, "at": at, "node": prop})
	return prop


func _rail(e: Dictionary, lot_id: String) -> void:
	var length := float(e.rail)
	var p := _xz(e, lot_id)
	var xf := Transform3D(Basis.IDENTITY, Vector3(p.x - length * 0.5, surface(p.x, p.y), p.y))
	if not _check(Rect2(0.0, -0.1, length, 0.2), xf, lot_id, "rail"):
		return
	var r := HitchingRail.new()
	r.name = "Rail_%s_%d" % [lot_id, rails.size()]
	r.length = length
	add_child(r)
	r.global_transform = xf
	rails.append(r)
	made.append({"what": &"rail", "at": xf.origin, "node": r})
	# Its horses on its street side, nose to it, a stall apart from one end, every so often a stall empty.
	var count := int(e.get("horses", 0))
	if count <= 0:
		return
	var north := lot_id != "street" and _north(lot_id)
	var into := 1.0 if north else -1.0  # the street's way from the rail, in z
	var stall := float(data.get("stall_m", 1.7))
	var stalls := maxi(1, floori(length / stall))
	var made_h := 0
	for i in stalls:
		if made_h >= count:
			break
		if stalls > count and (i * 7 + _n) % 4 == 3:
			continue  # an empty stall
		var x := xf.origin.x + stall * (i + 0.5)
		var z := p.y + into * 1.7
		# Nose to the rail: his head (-X in his own space) toward -into in z.
		var yaw := -90.0 if north else 90.0
		yaw += float(((i * 37 + _n) % 11) - 5)  # not all square to it
		var hxf := Transform3D(_basis(yaw), Vector3(x, surface(x, z), z))
		if not _check(HORSE_BOX, hxf, lot_id, "horse at the rail"):
			continue
		var h := _horse(hxf)
		if h:
			h.tie_to(Vector3(x, xf.origin.y + r.height - 0.02, p.y))
		made_h += 1


func _trough(e: Dictionary, lot_id: String) -> void:
	var length := float(e.trough)
	var p := _xz(e, lot_id)
	var xf := Transform3D(Basis.IDENTITY, Vector3(p.x - length * 0.5, surface(p.x, p.y), p.y))
	if not _check(Rect2(0.0, -0.4, length, 0.8), xf, lot_id, "trough"):
		return
	var t := WaterTrough.new()
	_n += 1
	t.structure_id = StringName("street_trough_%d" % _n)
	t.name = "Trough_%s_%d" % [lot_id, _n]
	t.length = length
	t.rests = true
	add_child(t)
	t.global_transform = xf
	made.append({"what": &"trough", "at": xf.origin, "node": t})


## A kit wagon, its tongue toward -X turned by `yaw`, and its team (`team` horses) in the traces ahead.
func _wagon(e: Dictionary, lot_id: String) -> void:
	var id := StringName(e.wagon)
	if not PropKit.has(id):
		skipped.append("%s: %s (no such kit prop)" % [lot_id, id])
		return
	var box := PropKit.bounds(PropKit.definition(id))
	var team := int(e.get("team", 0))
	# The footprint with the team: ahead of the tongue's tip by a horse's length less the tongue's
	# reach between them.
	var rect := _rect_of(box)
	var ahead := box.position.x + TEAM_OVERLAP
	if team > 0:
		rect = rect.merge(Rect2(ahead - HORSE_BOX.size.x, -0.45 - 0.38 if team > 1 else -0.38, HORSE_BOX.size.x, 1.66 if team > 1 else 0.76))
	var mid := box.get_center()
	var p := _xz(e, lot_id)
	var b := _on_ground(float(e.get("yaw", 0.0)), p.x, p.y)
	var at := Vector3(p.x, surface(p.x, p.y), p.y) - b * Vector3(mid.x, 0.0, mid.z)
	var xf := Transform3D(b, at)
	if not _check(rect, xf, lot_id, String(id)):
		return
	_n += 1
	var w := PropKit.spawn(id, StringName("street_%s_%d" % [id, _n]))
	w.rests = true
	add_child(w)
	w.global_transform = xf
	made.append({"what": id, "at": at, "node": w})
	for i in team:
		var side := 0.0 if team == 1 else (-0.45 if i == 0 else 0.45)
		var local := Vector3(ahead - HORSE_BOX.end.x, 0.0, side)
		var g := xf * local
		_horse(Transform3D(b, Vector3(g.x, surface(g.x, g.z), g.z)))


## How far back over the tongue a team's hind ends stand from its tip (m).
const TEAM_OVERLAP := 1.9


func _horse(xf: Transform3D) -> Horse:
	if not Horse.available():
		return null
	var h := Horse.new()
	h.name = "Horse_%d" % horses.size()
	add_child(h)
	h.global_transform = xf
	horses.append(h)
	made.append({"what": &"horse", "at": xf.origin, "node": h})
	return h


# --- At rest --------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	_wake_t += delta
	if _wake_t < WAKE_EVERY:
		return
	_wake_t = 0.0
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var t := Prof.start()
	for h in horses:
		if is_instance_valid(h):
			_wake(h, cam)
	Prof.stop(&"street_dress", t)


## A horse's idle and its collision go on while he can be seen near enough to tell; else he holds
## the pose he's in (the body where the mesh is: nothing seen or hit is out of step with it).
func _wake(h: Horse, cam: Camera3D) -> void:
	var at := h.global_position + Vector3.UP
	var awake := cam.global_position.distance_to(at) < HORSE_AWAKE_M and cam.is_position_in_frustum(at)
	if awake != h.is_processing():
		h.set_process(awake)
		h.set_physics_process(awake)
		if not awake:
			h.follow_bones()  # his body to the pose he holds


## The dressing's things as data for a test or the bridge: counts by kind and what was left out.
func summary() -> Dictionary:
	var by := {}
	for m in made:
		by[String(m.what)] = int(by.get(String(m.what), 0)) + 1
	var awake := 0
	for h in horses:
		if is_instance_valid(h) and h.is_processing():
			awake += 1
	return {"made": made.size(), "by": by, "skipped": skipped, "horses": horses.size(), "awake": awake}
