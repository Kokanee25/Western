class_name ValleyMarkers
extends Node3D
## The valley's greybox markers (G4, #720; docs/briefs/valley-plan.md §3, §6-§8, §11, §12): every
## place in config/valley.json put on its ground from the file, nothing placed by hand.
##
##   - **Blocks** (`blocks`): a solid grey box for each building volume the plan has: the town's
##     lots of kind `building` (their frontage on Main Street, their `depth` back from the front),
##     the town's extras with a size (the second saloon), and each place with a `block` (the depot,
##     the freight warehouse, the water tank, the church, the Baron's town house: its pad's size
##     and middle unless the block gives its own `w`, `d`, `at`). Each stands from under its lowest corner to `h` over its
##     highest (LOT_H for a lot). One mesh, one body (Layers.WORLD), a box shape each.
##   - **Posts** (`posts`): a tall coloured post and the place's name where each place, ford and
##     bridge is (beside a block, on its side toward the crossroads), so a place can be found by
##     eye; one MultiMesh, the names Label3Ds seen within LABEL_RANGE.
##   - **Bridge A and the town bridge** (`bridge_a`, `bridge_t`): RoadBridges over the creek, the
##     deck level at the plan's `deck_y` out to where the ground (the bake: its approaches graded
##     to the deck by valley_plan.py) meets its underside; Bridge A's two spans on a log crib (its
##     `cribs`). Bridge B (the overpass) and the trestle are the railway's (ValleyRailway).
##   - **Places with height** (#736 B, valley.json `heights`): their `blocks` as above, a Ladder up
##     the one each climbs (`ladders`), places `<id>` (the ladder's foot, or the high spot on the
##     ground) and `<id>_top`; `high_spot(id)` where its shooter stands. The landforms are in the bake.
##   - **Places** (`places`, a Waypoints): every place, bridge, viewpoint and town lot by its id, a
##     point on the ground (or a bridge's deck) a man can stand at: the dev bridge's `goto PLACE`,
##     `look PLACE`, `read places` in the valley.
##
## The pads, roads, fords and beds are drawn on the ground itself (ValleyMarks, tinting
## ValleyGround's colours). `road_grades()` measures each road over the bake and the bridges'
## decks against the plan's limits.

## A town lot's block, how tall (m): the lots give no heights (the building lab's specs will).
const LOT_H := 6.0
## A place's block with no `h`.
const BLOCK_H := 6.0
## How far a post stands off a block's side (m), and its size.
const POST_OFF := 2.5
const POST_SIZE := Vector3(0.25, 4.0, 0.25)
## Names are drawn within this (m).
const LABEL_RANGE := 160.0
## A road's grade is measured over this (m), as the plan's tables do.
const GRADE_WINDOW := 20.0
## The plan's limits by class (%; valley-plan.md §11): wagon roads, lanes and streets 10, horse
## tracks 15; foot paths none.
const GRADE_LIMIT := {"wagon": 10.0, "lane": 10.0, "street": 10.0, "track": 15.0}

## Colours by a place's category (the greybox's: as the plan's maps).
const CAT_COLOUR := {
	"town": Color(0.85, 0.55, 0.30), "rail": Color(0.35, 0.35, 0.40), "baron": Color(0.65, 0.25, 0.25),
	"industry": Color(0.45, 0.40, 0.30), "homestead": Color(0.30, 0.55, 0.30), "community": Color(0.55, 0.45, 0.70),
	"outlaw": Color(0.20, 0.20, 0.20), "mission": Color(0.90, 0.20, 0.20), "edge": Color(0.95, 0.95, 0.95),
	"wild": Color(0.55, 0.65, 0.40), "ford": Color(0.35, 0.55, 0.70), "bridge": Color(0.60, 0.45, 0.25),
	"height": Color(0.49, 0.18, 0.07),
}
const BLOCK_COLOUR := Color(0.72, 0.72, 0.70)

var layout: ValleyLayout
var terrain: ValleyTerrain
## The railway (for Bridge B's and the trestle's decks: goto, the grades), if there is one.
var railway: ValleyRailway

## {id, kind (lot | extra | place), centre (Vector3, its base's middle), size (x across its
## heading, y up, z along), heading (compass deg)} each block.
var blocks: Array[Dictionary] = []
## {id, at (Vector3, the post's foot), name, cat} each post.
var posts: Array[Dictionary] = []
var places := Waypoints.new()
var bridge_a: RoadBridge
var bridge_t: RoadBridge
## The town's greybox (G5): boardwalks, passages, junk and the town's ways (ValleyTown).
var town: ValleyTown
## The town's greybox (G5); `-- --no-town`: the markers without it (the bench's before).
static var town_default := not "--no-town" in OS.get_cmdline_user_args()
var body: StaticBody3D
var build_ms := {}


func _init() -> void:
	name = "Markers"


func _ready() -> void:
	if layout == null:
		layout = ValleyLayout.main()
	if terrain == null:
		terrain = ValleyTerrain.main()
	var u := Time.get_ticks_usec()
	_find_blocks()
	_build_blocks()
	_build_ladders()
	build_ms["blocks"] = (Time.get_ticks_usec() - u) / 1000.0
	u = Time.get_ticks_usec()
	bridge_a = _build_bridge("bridge_a", "BridgeA")
	bridge_t = _build_bridge("bridge_t", "BridgeT")
	build_ms["bridges"] = (Time.get_ticks_usec() - u) / 1000.0
	u = Time.get_ticks_usec()
	if town_default:
		town = ValleyTown.new()
		town.layout = layout
		town.terrain = terrain
		add_child(town)
	build_ms["town"] = (Time.get_ticks_usec() - u) / 1000.0
	u = Time.get_ticks_usec()
	_find_places()
	_build_posts()
	build_ms["posts"] = (Time.get_ticks_usec() - u) / 1000.0


func ground(x: float, z: float) -> float:
	return terrain.height(x, z)


# --- Blocks ------------------------------------------------------------------------------------

func _find_blocks() -> void:
	blocks.clear()
	var t := layout.town()
	var front := float((t.get("main_street", {}) as Dictionary).get("width_between_fronts", 20.1)) * 0.5
	var lot_depth := float(t.get("lot_depth", 38.1))
	for side in ["north", "south"]:
		var sgn := -1.0 if side == "north" else 1.0
		for l: Dictionary in layout.lots(side):
			if l.get("kind", "") != "building":
				continue
			var depth := float(l.get("depth", lot_depth))
			var x0 := float(l.x0)
			var x1 := float(l.x1)
			var c := Vector2((x0 + x1) * 0.5, sgn * (front + depth * 0.5))
			# Its floor up or down with its walk (G7, #737): the roofline steps with the floors.
			var walk: Dictionary = l.get("walk", {})
			var lift := 0.0 if walk.get("none", false) else float(walk.get("h", ValleyTown.WALK_TOP)) - ValleyTown.WALK_TOP
			_add_block(String(l.id), "lot", c, Vector2(x1 - x0, depth), 90.0, LOT_H + lift)
	for ex: Dictionary in t.get("extras", []):
		if ex.has("at") and ex.has("w") and ex.has("d"):
			_add_block(String(ex.id), "extra", ValleyLayout.xz(ex.at), Vector2(float(ex.w), float(ex.d)), 90.0, float(ex.get("h", BLOCK_H)))
	for p: Dictionary in layout.places():
		var b: Dictionary = p.get("block", {})
		if b.is_empty():
			continue
		var pad: Dictionary = p.get("pad", {})
		var w := float(b.get("w", pad.get("w", 6.0)))
		var d := float(b.get("d", pad.get("d", 6.0)))
		var c := ValleyLayout.xz(b.at) if b.has("at") else ValleyLayout.xz(p.at)
		_add_block(String(p.id), "place", c, Vector2(w, d), float(pad.get("heading", 90.0)), float(b.get("h", BLOCK_H)))
	# The places with height (#736 B): each `blocks` entry, the one climbed by a ladder named as
	# the height (`<id>`), the others `<id>/<k>`.
	for hp: Dictionary in layout.heights():
		var k := 0
		for b: Dictionary in hp.get("blocks", []):
			var bid := String(hp.id) if b.get("ladder", false) else "%s/%d" % [hp.id, k]
			var c := ValleyLayout.xz(b.at) if b.has("at") else ValleyLayout.xz(hp.at)
			_add_block(bid, "height", c, Vector2(float(b.w), float(b.d)), float(b.get("heading", 90.0)), float(b.h))
			blocks[-1]["stand"] = String(b.get("stand", ""))
			k += 1


## A block w (along its heading) x d about c: from 0.3 m under the lowest of the ground at its corners
## and middle to h over the highest.
func _add_block(id: String, kind: String, c: Vector2, wd: Vector2, heading: float, h: float) -> void:
	var lo := INF
	var hi := -INF
	for p in _footprint(c, wd, heading) + PackedVector2Array([c]):
		var g := ground(p.x, p.y)
		lo = minf(lo, g)
		hi = maxf(hi, g)
	var bottom := lo - 0.3
	var top := hi + h
	blocks.append({"id": id, "kind": kind, "centre": Vector3(c.x, bottom, c.y), "size": Vector3(wd.x, top - bottom, wd.y),
		"heading": heading, "map": c, "wd": wd})


static func _axes(heading: float) -> Array[Vector2]:
	var hd := deg_to_rad(heading)
	var u := Vector2(sin(hd), -cos(hd))
	return [u, Vector2(-u.y, u.x)]


static func _footprint(c: Vector2, wd: Vector2, heading: float) -> PackedVector2Array:
	var ax := _axes(heading)
	var u := ax[0] * wd.x * 0.5
	var v := ax[1] * wd.y * 0.5
	return PackedVector2Array([c + u + v, c - u + v, c - u - v, c + u - v])


## The block's turn about +Y: its local +X along its heading (as a pad's w).
static func _block_basis(heading: float) -> Basis:
	var u := _axes(heading)[0]
	return Basis(Vector3.UP, atan2(-u.y, u.x))


func _build_blocks() -> void:
	if blocks.is_empty():
		return
	body = StaticBody3D.new()
	body.name = "Blocks"
	body.collision_layer = Layers.WORLD
	body.collision_mask = 0
	add_child(body)
	var st := SurfaceTool.new()
	for b: Dictionary in blocks:
		var size: Vector3 = b.size
		var xf := Transform3D(_block_basis(float(b.heading)), b.centre + Vector3(0.0, size.y * 0.5, 0.0))
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		shape.transform = xf
		shape.name = "B_%s" % b.id
		body.add_child(shape)
		var bm := BoxMesh.new()
		bm.size = size
		st.append_from(bm, 0, xf)
	var mi := MeshInstance3D.new()
	mi.name = "BlockMesh"
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = BLOCK_COLOUR
	mat.roughness = 1.0
	mi.material_override = mat
	add_child(mi)


static func _vertex_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	return m


# --- The places with height's ladders (#736 B) -------------------------------------------------

## {id (the height's), ladder (Ladder), foot (Vector3: where a man stands to climb, in front of it),
## top (Vector3: on the block behind its top)} each laddered height.
var ladders: Array[Dictionary] = []
## How far in front of a ladder its foot place stands, and behind its top the top place (m).
const LADDER_FOOT := 0.6
const LADDER_TOP_IN := 0.6


## A block by id, or {}.
func block(id: String) -> Dictionary:
	for b: Dictionary in blocks:
		if String(b.id) == id:
			return b
	return {}


## A Ladder up the side of each laddered height's block (its `ladder` block, or the place's block it
## names in `ladder_on`) that faces the crossroads, from the ground there to the block's top.
func _build_ladders() -> void:
	ladders.clear()
	for hp: Dictionary in layout.heights():
		var bid := String(hp.get("ladder_on", ""))
		if bid == "":
			for b: Dictionary in hp.get("blocks", []):
				if b.get("ladder", false):
					bid = String(hp.id)
		var b := block(bid)
		if b.is_empty():
			continue
		var c: Vector2 = b.map
		var ax := _axes(float(b.heading))
		var wd: Vector2 = b.wd
		# The side toward the crossroads: its outward normal and half-depth.
		var to := (Vector2.ZERO - c).normalized()
		var n: Vector2
		var half: float
		if absf(to.dot(ax[0])) * wd.y >= absf(to.dot(ax[1])) * wd.x:
			n = ax[0] * signf(to.dot(ax[0]))
			half = wd.x * 0.5
		else:
			n = ax[1] * signf(to.dot(ax[1]))
			half = wd.y * 0.5
		var face := c + n * half
		var foot_y := ground(face.x + n.x * 0.3, face.y + n.y * 0.3)
		var top_y: float = (b.centre as Vector3).y + (b.size as Vector3).y
		var l := Ladder.new()
		l.name = "Ladder_%s" % hp.id
		l.height = top_y - foot_y
		var out := Vector3(n.x, 0.0, n.y)
		l.transform = Transform3D(Basis.looking_at(-out, Vector3.UP), Vector3(face.x, foot_y, face.y))
		# Drawn (greybox): its stiles and rungs as one dark board a hand's breadth off the face.
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(l.width, l.height, 0.06)
		mi.mesh = bm
		mi.position = Vector3(0.0, l.height * 0.5, 0.05)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.33, 0.22, 0.12)
		mat.roughness = 1.0
		mi.material_override = mat
		l.add_child(mi)
		add_child(l)
		ladders.append({"id": String(hp.id), "ladder": l, "foot": Vector3(face.x + n.x * LADDER_FOOT, foot_y + 0.05, face.y + n.y * LADDER_FOOT),
			"top": Vector3(face.x - n.x * LADDER_TOP_IN, top_y + 0.05, face.y - n.y * LADDER_TOP_IN)})


## The places with height as places (#736 B): `<id>` where a man goes to it (a laddered one's
## ladder foot, else its high spot on the ground), `<id>_top` the top a ladder gets him onto, and a
## block's `stand` on its top.
func _add_height_places() -> void:
	var by_ladder := {}
	for l: Dictionary in ladders:
		by_ladder[l.id] = l
	for hp: Dictionary in layout.heights():
		var id := String(hp.id)
		if by_ladder.has(id):
			places.add(StringName(id), by_ladder[id].foot)
			places.add(StringName(id + "_top"), by_ladder[id].top)
		else:
			places.add(StringName(id), _on_ground(ValleyLayout.xz((hp.high as Dictionary).at)))
	for b: Dictionary in blocks:
		if String(b.get("stand", "")) != "":
			var c: Vector2 = b.map
			places.add(StringName(String(b.stand)), Vector3(c.x, (b.centre as Vector3).y + (b.size as Vector3).y + 0.05, c.y))


## The block a map point is in (the tallest, if more than one), or {}.
func block_at(c: Vector2) -> Dictionary:
	var best := {}
	for b: Dictionary in blocks:
		var r: Vector2 = c - (b.map as Vector2)
		var ax := _axes(float(b.heading))
		var wd: Vector2 = b.wd
		if absf(r.dot(ax[0])) <= wd.x * 0.5 and absf(r.dot(ax[1])) <= wd.y * 0.5:
			if best.is_empty() or (b.size as Vector3).y + (b.centre as Vector3).y > (best.size as Vector3).y + (best.centre as Vector3).y:
				best = b
	return best


## How far from `c` (inside block `b`) along `dir` (unit) its footprint's edge is.
static func block_exit(b: Dictionary, c: Vector2, dir: Vector2) -> float:
	var ax := _axes(float(b.heading))
	var wd: Vector2 = b.wd
	var r: Vector2 = c - (b.map as Vector2)
	var t := INF
	for k in 2:
		var u := r.dot(ax[k])
		var du := dir.dot(ax[k])
		var half := (wd.x if k == 0 else wd.y) * 0.5
		if absf(du) > 1e-6:
			t = minf(t, ((half if du > 0.0 else -half) - u) / du)
	return maxf(t, 0.0)


## A height's high spot (#736 B): where its shooter's feet are, on whatever is there (a block's top,
## the ground), from its `high.at`.
func high_spot(id: String) -> Vector3:
	var hp := layout.height(id)
	if hp.is_empty():
		return Vector3(NAN, NAN, NAN)
	var c := ValleyLayout.xz((hp.high as Dictionary).at)
	var y := surface(c.x, c.y)
	for b: Dictionary in blocks:
		var r: Vector2 = c - (b.map as Vector2)
		var ax := _axes(float(b.heading))
		var wd: Vector2 = b.wd
		if absf(r.dot(ax[0])) <= wd.x * 0.5 and absf(r.dot(ax[1])) <= wd.y * 0.5:
			y = maxf(y, (b.centre as Vector3).y + (b.size as Vector3).y)
	return Vector3(c.x, y, c.y)


# --- Bridges A and the town bridge -------------------------------------------------------------

## A bridge over the creek from the plan: its deck level at `deck_y` through `at`, along the road
## where it crosses (the segment of the bridge's road nearest it, if that passes within 3 m; else
## the bridge's `heading`), a main span of `span`, log cribs at its `cribs` (m from the middle).
func _build_bridge(id: String, node_name: String) -> RoadBridge:
	var b := layout.bridge(id)
	if b.is_empty() or not b.has("at"):
		return null
	var at := ValleyLayout.xz(b.at)
	var hd := deg_to_rad(float(b.get("heading", 0.0)))
	var dir := Vector2(sin(hd), -cos(hd))
	var road := layout.road_line(String(b.get("road", "")))
	var best := 3.0
	for i in road.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(at, road[i], road[i + 1])
		if q.distance_to(at) < best:
			best = q.distance_to(at)
			dir = (road[i + 1] - road[i]).normalized()
	var deck := float(b.get("deck_y", 0.0))
	var ter := terrain
	var br := RoadBridge.spanning(Vector3(at.x, deck, at.y), Vector3(dir.x, 0.0, dir.y), deck,
			func(x: float, z: float) -> float: return ter.height(x, z), float(b.get("span", 14.0)), 7.0, 0.5, b.get("cribs", []),
			1.5, 0.25, float((layout.road(String(b.get("road", ""))) as Dictionary).get("width", 5.0)))
	br.name = node_name
	br.structure_id = StringName(id)
	add_child(br)
	return br


## Every road bridge built: {id: RoadBridge} (Bridge B from the railway when it's there).
func road_bridges() -> Dictionary:
	var out := {}
	if bridge_a:
		out["bridge_a"] = bridge_a
	if bridge_t:
		out["bridge_t"] = bridge_t
	if railway and railway.overpass:
		out["bridge_b"] = railway.overpass
	return out


## A road bridge's deck middle (its top), or NAN in x.
static func deck_middle(br: RoadBridge) -> Vector3:
	if br == null:
		return Vector3(NAN, NAN, NAN)
	var m := br.to_global((br.deck_from + br.deck_to) * 0.5)
	return m


# --- Places and posts --------------------------------------------------------------------------

## The places a man can be sent to: each place (beside its block, if it has one: on the side toward
## the crossroads), each bridge's deck middle, each viewpoint and each town lot's front on Main
## Street, on the ground (or the deck) there.
func _find_places() -> void:
	places = Waypoints.new()
	var by_id := {}
	for b: Dictionary in blocks:
		by_id[b.id] = b
	for p: Dictionary in layout.places():
		var id := String(p.id)
		var c := ValleyLayout.xz(p.at)
		if by_id.has(id):
			c = _beside(by_id[id])
		places.add(StringName(id), _on_ground(c))
	for id: String in road_bridges():
		places.add(StringName(id), deck_middle(road_bridges()[id]) + Vector3.UP * 0.05)
	if railway and railway.line and not is_nan(railway.line.mark_s("trestle_mid")):
		places.add(&"bridge_c", railway.mark_point("trestle_mid") + Vector3.UP * 0.05)
	for vp: Dictionary in layout.viewpoints():
		places.add(StringName(vp.id), _on_ground(ValleyLayout.xz(vp.at)))
	# The town's ways (G5): doors, steps, passages, the streets, linked; a viewpoint on a walk is
	# linked to its door.
	if town:
		town.add_ways(places)
		for vp: Dictionary in layout.viewpoints():
			var c := ValleyLayout.xz(vp.at)
			var w := town.walk_at(c.x, c.y)
			if not w.is_empty():
				places.link(StringName(vp.id), StringName(String(w.id)))
	var front := float((layout.town().get("main_street", {}) as Dictionary).get("width_between_fronts", 20.1)) * 0.5
	for side in ["north", "south"]:
		var sgn := -1.0 if side == "north" else 1.0
		for l: Dictionary in layout.lots(side):
			var id := String(l.id)
			if places.has(StringName(id)):
				continue
			places.add(StringName(id), _on_ground(Vector2((float(l.x0) + float(l.x1)) * 0.5, sgn * (front - 1.5))))
	_add_height_places()
	# The roads out of town a man is sent along by name (G6): the East Road and the widow's lane;
	# Harlan's ford path (#746, the opening), its ends joined to his homestead and the East Road.
	for id: String in WAY_ROADS:
		if not layout.road(id).is_empty():
			_add_road_way(id)
	var ford: Array = ways.get("harlan_ford_path", [])
	if not ford.is_empty():
		if places.has(&"harlan_homestead") and ford[0] != &"harlan_homestead":
			join(&"harlan_homestead", ford[0])
		var east: Array = ways.get("east_road", [])
		var end := places.at(ford[-1])
		var near := &""
		var nd := INF
		for n: StringName in east:
			var d := places.at(n).distance_to(end)
			if d < nd:
				nd = d
				near = n
		if near != &"" and near != ford[-1]:
			join(ford[-1], near)


# --- The roads as ways (G6) --------------------------------------------------------------------

## The roads walked by the places (G6, #731): `walk farm_porch` from the crossroads goes down Main
## Street to its east end, along the East Road over Bridges A and B and up the widow's lane; and
## Harlan's ford path (#746) from his homestead down to the East Road at the opening's site.
const WAY_ROADS: Array[String] = ["east_road", "widow_lane", "harlan_ford_path"]
## A way's links: no longer than this (m), and the ground along one rising no more than WAY_RISE
## over its lower end (Waypoints._walkable sweeps it at the lower end's height: as ValleyTown's).
const WAY_LINK_MAX := 12.0
const WAY_RISE := 0.3
## Looked at every this (m) along a road.
const WAY_STEP := 1.0
## A way's end joins a place already there within this (m) (Main Street's end, a road it leaves).
const WAY_JOIN := 1.5
## Each road's way: its places' names in order along it.
var ways := {}


## A road's places along it (`<road>@<metres along>`), each link as long as WAY_LINK_MAX and
## WAY_RISE allow, a place at every bend; its ends taken by a place already there within WAY_JOIN.
func _add_road_way(id: String) -> void:
	var line := layout.road_line(id)
	var decks := road_bridges().values()
	var pts := PackedVector2Array()
	var ss := PackedFloat32Array()
	var bend := {}  # sample index -> true at the line's vertices
	var s_at := 0.0
	for i in range(1, line.size()):
		var n := maxi(1, ceili(line[i - 1].distance_to(line[i]) / WAY_STEP))
		for k in range(0 if i == 1 else 1, n + 1):
			var p := line[i - 1].lerp(line[i], float(k) / n)
			if pts.size() > 0:
				s_at += p.distance_to(pts[pts.size() - 1])
			pts.append(p)
			ss.append(s_at)
		bend[pts.size() - 1] = true
	var ys := PackedFloat32Array()
	for p in pts:
		ys.append(_surface(p, decks))
	var names: Array[StringName] = []
	var i0 := 0
	names.append(_way_place(id, pts[0], ys[0], ss[0], true))
	while i0 < pts.size() - 1:
		var best := i0 + 1
		var j := i0 + 1
		while j < pts.size():
			if pts[i0].distance_to(pts[j]) > WAY_LINK_MAX or _way_rise(ys, i0, j) > WAY_RISE:
				break
			best = j
			if bend.has(j):
				break
			j += 1
		var n := _way_place(id, pts[best], ys[best], ss[best], best == pts.size() - 1)
		if n != names[-1]:
			places.link(names[-1], n)
			names.append(n)
		i0 = best
	ways[id] = names


## The most the surface rises over the lower end of the piece from sample i to j.
static func _way_rise(ys: PackedFloat32Array, i: int, j: int) -> float:
	var low := minf(ys[i], ys[j])
	var worst := 0.0
	for k in range(i, j + 1):
		worst = maxf(worst, ys[k] - low)
	return worst


## The place at a way's point: at its ends one already there within WAY_JOIN, else a new one.
func _way_place(id: String, p: Vector2, y: float, s: float, end: bool) -> StringName:
	var best := &""
	var best_d := WAY_JOIN
	for n: StringName in (places.points if end else {}):
		var q: Vector3 = places.points[n]
		var d := Vector2(q.x - p.x, q.z - p.y).length()
		if d < best_d and absf(q.y - y) < 0.6:
			best_d = d
			best = n
	if best != &"":
		return best
	var name := StringName("%s@%d" % [id, roundi(s)])
	places.add(name, Vector3(p.x, y + 0.05, p.y))
	return name


## The place at a road's far end (its way's last), or "" if it has no way.
func way_end(id: String) -> StringName:
	var w: Array = ways.get(id, [])
	return w[-1] if not w.is_empty() else &""


## `a` linked to `b` through places between (`a>b~1`...) on the ground, each piece within
## WAY_LINK_MAX and WAY_RISE (as ValleyTown's ways): for what joins the valley's places later (the
## farmhouse's, G6).
func join(a: StringName, b: StringName) -> void:
	var pa := places.at(a)
	var pb := places.at(b)
	var flat := Vector2(pb.x - pa.x, pb.z - pa.z).length()
	var n := maxi(1, ceili(flat / WAY_LINK_MAX))
	var decks := road_bridges().values()
	while n < 64:
		var ys := PackedFloat32Array()
		var m := n * 8
		for k in m + 1:
			var q := pa.lerp(pb, float(k) / m)
			ys.append(_surface(Vector2(q.x, q.z), decks))
		var ok := true
		for k in n:
			if _way_rise(ys, k * 8, (k + 1) * 8) > WAY_RISE:
				ok = false
				break
		if ok:
			break
		n += 1
	var prev := a
	for k in range(1, n):
		var q := pa.lerp(pb, float(k) / n)
		var name_k := StringName("%s>%s~%d" % [a, b, k])
		places.add(name_k, Vector3(q.x, _surface(Vector2(q.x, q.z), decks) + 0.05, q.z), [prev])
		prev = name_k
	places.link(prev, b)


## A point POST_OFF off a block's side, toward the crossroads.
func _beside(b: Dictionary) -> Vector2:
	var c: Vector2 = b.map
	var to := (Vector2.ZERO - c)
	if to.length() < 0.01:
		to = Vector2(0, 1)
	to = to.normalized()
	var ax := _axes(float(b.heading))
	var wd: Vector2 = b.wd
	# The distance along `to` from the middle to the footprint's edge.
	var ex := absf(to.dot(ax[0]))
	var ez := absf(to.dot(ax[1]))
	var reach := minf(wd.x * 0.5 / maxf(ex, 1e-4), wd.y * 0.5 / maxf(ez, 1e-4))
	return c + to * (reach + POST_OFF)


## A map point on the ground there (or a town walk's planks: G5), stepped out of any block it falls
## in (to the block's nearest side, POST_OFF past it).
func _on_ground(c: Vector2) -> Vector3:
	c = out_of_blocks(c)
	return Vector3(c.x, surface(c.x, c.y) + 0.05, c.y)


## What a man stands on at a map point: a town walk's planks, else the ground.
func surface(x: float, z: float) -> float:
	return town.surface(x, z) if town else ground(x, z)


## `c`, or if it's inside a block (or within 0.3 m of it), the nearest point POST_OFF outside that
## block's nearest side.
func out_of_blocks(c: Vector2) -> Vector2:
	for b: Dictionary in blocks:
		var ax := _axes(float(b.heading))
		var wd: Vector2 = b.wd
		var r: Vector2 = c - (b.map as Vector2)
		var u := r.dot(ax[0])
		var v := r.dot(ax[1])
		var du := wd.x * 0.5 - absf(u)
		var dv := wd.y * 0.5 - absf(v)
		if du <= -0.3 or dv <= -0.3:
			continue  # (outside it by more than 0.3 m: one on its edge is in it)
		if du < dv:
			u = signf(u if u != 0.0 else 1.0) * (wd.x * 0.5 + POST_OFF)
		else:
			v = signf(v if v != 0.0 else 1.0) * (wd.y * 0.5 + POST_OFF)
		return (b.map as Vector2) + ax[0] * u + ax[1] * v
	return c


func _build_posts() -> void:
	posts.clear()
	for p: Dictionary in layout.places():
		var id := StringName(String(p.id))
		posts.append({"id": String(p.id), "at": places.at(id) - Vector3.UP * 0.05, "name": String(p.get("name", p.id)), "cat": String(p.get("cat", ""))})
	for f: Dictionary in ValleyMarks.fords(layout):
		var c: Vector2 = f.at
		posts.append({"id": "ford_%s" % f.road, "at": _on_ground(c) - Vector3.UP * 0.05, "name": "ford: %s" % f.what, "cat": "ford"})
	for hp: Dictionary in layout.heights():
		var hid := StringName(String(hp.id))
		if places.has(hid):
			# Beside its place, not on it (a post on a high spot stands in the shooter's view):
			# POST_OFF to the right of the way to its first target.
			var at := places.at(hid)
			var t := ValleyLayout.xz((hp.targets[0] as Dictionary).at) if not (hp.get("targets", []) as Array).is_empty() else Vector2(at.x, at.z + 1.0)
			var d := (t - Vector2(at.x, at.z)).normalized()
			var c := Vector2(at.x, at.z) + Vector2(-d.y, d.x) * POST_OFF
			posts.append({"id": String(hp.id), "at": _on_ground(c) - Vector3.UP * 0.05, "name": String(hp.get("short", hp.name)), "cat": "height"})
	for b: Dictionary in layout.bridges():
		var id := StringName(String(b.id))
		if places.has(id):
			posts.append({"id": String(b.id), "at": places.at(id) - Vector3.UP * 0.05, "name": String(b.get("name", b.id)), "cat": "bridge"})
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var box := BoxMesh.new()
	box.size = POST_SIZE
	mm.mesh = box
	mm.instance_count = posts.size()
	for i in posts.size():
		var p: Dictionary = posts[i]
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p.at + Vector3.UP * POST_SIZE.y * 0.5))
		mm.set_instance_color(i, CAT_COLOUR.get(p.cat, Color.WHITE))
		var label := Label3D.new()
		label.name = "L_%s" % p.id
		label.text = p.name
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.pixel_size = 0.01
		label.font_size = 48
		label.outline_size = 12
		label.visibility_range_end = LABEL_RANGE
		label.position = p.at + Vector3.UP * (POST_SIZE.y + 0.6)
		add_child(label)
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Posts"
	mmi.multimesh = mm
	var mat := _vertex_material()
	mmi.material_override = mat
	add_child(mmi)


# --- The roads' grades -------------------------------------------------------------------------

## Each road and town street over the ground as built: every 2 m along its line, the bake (or a
## bridge's deck where one carries it), its grade over GRADE_WINDOW m, against the plan's limit for
## its class: {id: {class, length, steepest (%), over (m over the limit), runs: [{from, to (m along),
## at [x, z], grade}]}}.
func road_grades(step := 2.0) -> Dictionary:
	var out := {}
	var decks := road_bridges().values()
	var all: Array = layout.roads().duplicate()
	for s: Dictionary in ValleyMarks.town_streets(layout):
		all.append({"id": s.id, "class": "street", "line": s.line})
	for r: Dictionary in all:
		var cls := String(r.get("class", "wagon"))
		var line := ValleyLayout.xz_line(r.line)
		var pts := PackedVector2Array()
		var ys := PackedFloat32Array()
		var ss := PackedFloat32Array()
		var s_at := 0.0
		for i in range(1, line.size()):
			var a := line[i - 1]
			var b := line[i]
			var n := maxi(1, ceili(a.distance_to(b) / step))
			for k in range(0 if i == 1 else 1, n + 1):
				var p := a.lerp(b, float(k) / n)
				if pts.size() > 0:
					s_at += p.distance_to(pts[pts.size() - 1])
				pts.append(p)
				ss.append(s_at)
				ys.append(_surface(p, decks))
		var limit := float(GRADE_LIMIT.get(cls, INF))
		var steepest := 0.0
		var over := 0.0
		var runs := []
		var cur := {}
		var j := 0
		for i in pts.size():
			while j < pts.size() - 1 and ss[j] - ss[i] < GRADE_WINDOW:
				j += 1
			if ss[j] - ss[i] < GRADE_WINDOW * 0.75:
				break
			var g := (ys[j] - ys[i]) / (ss[j] - ss[i]) * 100.0
			steepest = maxf(steepest, absf(g))
			if absf(g) > limit:
				over += ss[mini(i + 1, pts.size() - 1)] - ss[i]
				if cur.is_empty():
					cur = {"from": snappedf(ss[i], 1.0), "to": snappedf(ss[j], 1.0), "at": [roundi(pts[i].x), roundi(pts[i].y)], "grade": snappedf(g, 0.1)}
				cur.to = snappedf(ss[j], 1.0)
				if absf(g) > absf(float(cur.grade)):
					cur.grade = snappedf(g, 0.1)
					cur.at = [roundi(pts[i].x), roundi(pts[i].y)]
			elif not cur.is_empty():
				runs.append(cur)
				cur = {}
		if not cur.is_empty():
			runs.append(cur)
		out[String(r.id)] = {"class": cls, "length": snappedf(s_at, 1.0), "steepest": snappedf(steepest, 0.1),
			"limit": limit, "over": snappedf(over, 1.0), "runs": runs}
	return out


## The walking surface at a map point: a bridge's deck where one covers it, else the ground.
func _surface(p: Vector2, decks: Array) -> float:
	for br: RoadBridge in decks:
		var a := br.to_global(br.deck_from)
		var b := br.to_global(br.deck_to)
		var a2 := Vector2(a.x, a.z)
		var ab := Vector2(b.x, b.z) - a2
		var l := ab.length()
		if l < 0.01:
			continue
		var along := (p - a2).dot(ab) / l
		var across := absf((p - a2).cross(ab) / l)
		if along >= 0.0 and along <= l and across <= br.width * 0.5 + 0.5:
			return lerpf(a.y, b.y, along / l)
	return ground(p.x, p.y)


func report() -> Dictionary:
	var br := {}
	for id: String in road_bridges():
		var b: RoadBridge = road_bridges()[id]
		br[id] = {"length": snappedf(b.length(), 0.1), "bents": b.bents.size(), "cribs": b.cribs.size(), "members": b.get_members().size(),
			"deck": snappedf(b.to_global(b.deck_from).y, 0.01)}
	return {"blocks": blocks.size(), "posts": posts.size(), "places": places.points.size(), "bridges": br, "build_ms": build_ms,
		"town": town.report() if town else {}}
