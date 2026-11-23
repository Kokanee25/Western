extends SceneTree
## Where the store's shelf goods really are (#1172, G2's step 2): the store built by the building lab
## from its spec (its `dressing` placed by PropDressing, as the game does), physics run a few seconds,
## then every dressed prop on a shelving bay's boards reported: its foot's y over the shop floor, the
## board it should stand on (the bay's `shelf<k>` member's top, read from the built members), how far
## it moved since it was placed, and whether it went loose. Headless, no render (~1 min after import).
##
##   godot --headless --fixed-fps 60 -s res://experiments/prop_lab/store/probe_shelves.gd -- [--batch=G1] [--frames=180]
##
## Untyped where it names game classes: -s scripts compile before autoloads.

const SPEC := "res://config/buildings/store.json"

var frames := 180
var batches: PackedStringArray = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--frames="):
			frames = int(a.get_slice("=", 1))
		elif a.begins_with("--batch="):
			batches = a.get_slice("=", 1).split(",")
	_run.call_deferred()


func _run() -> void:
	var Lab = load("res://experiments/building_lab/lab.gd")
	Lab.spec_path = SPEC
	var lab = Lab.new()
	root.add_child(lab)
	Lab.spec_path = ""
	for i in 3:
		await physics_frame
	var b = lab.building
	var floor_y: float = b.floor_top
	# The boards: every bay's shelf members' tops, in the building's space.
	var boards := {}  # bay id -> [[top y over floor, x0, x1, z0, z1], ...]
	var start := {}
	for batch: String in b.dressed:
		for id: String in b.dressed[batch]:
			var n: Node3D = b.dressed[batch][id]
			start[id] = b.to_local(n.global_position)
			if String(id).contains("shelves"):
				var tops := []
				for m in n.get_members():
					if String(m.name).contains("shelf") or String(m.name).contains("cupboard_top"):
						var c: Vector3 = b.to_local(m.global_position)
						var h: Vector3 = m.size * 0.5
						# (the bays face 0 or 180: the member's x/z extents swap no further)
						tops.append([c.y + h.y - floor_y, c.x - h.x, c.x + h.x, c.z - h.z, c.z + h.z, String(m.name)])
				boards[id] = tops
	for i in frames:
		await physics_frame
	var lines: PackedStringArray = []
	var bad := 0
	for batch: String in b.dressed:
		if not batches.is_empty() and not batches.has(batch):
			continue
		for id: String in b.dressed[batch]:
			var n: Node3D = b.dressed[batch][id]
			if [&"store_counter", &"store_shelving"].has(n.get(&"kit_id")):
				continue  # (the fixtures the goods stand on)
			var p: Vector3 = b.to_local(n.global_position)
			var foot := p.y - floor_y
			if foot < 0.5:
				if float(start[id].y) - floor_y > 0.5:
					lines.append("%-22s fell from %.3f to %.3f  <-- BAD" % [id, float(start[id].y) - floor_y, foot])
					bad += 1
				continue  # on the floor: not shelf stock
			# The board under it: the nearest top at or below its foot within the bay's footprint.
			var best := ""
			var gap := INF
			for bay: String in boards:
				for t: Array in boards[bay]:
					var x0: float = minf(t[1], t[2]) - 0.05
					var x1: float = maxf(t[1], t[2]) + 0.05
					if p.x < x0 or p.x > x1 or p.z < float(t[3]) - 0.05 or p.z > float(t[4]) + 0.05:
						continue
					var g: float = foot - float(t[0])
					if g > -0.03 and g < gap:
						gap = g
						best = "%s/%s@%.3f" % [bay, t[5], t[0]]
			var moved: float = p.distance_to(start[id])
			var loose: bool = n.get(&"loose") == true
			var top := _top_member_y(n, b) - floor_y
			var flag := ""
			if best == "" or absf(gap) > 0.02 or moved > 0.02 or loose:
				flag = "  <-- BAD"
				bad += 1
			lines.append("%-22s %-24s foot %.3f  board %s gap %+.3f  moved %.3f  top %.3f%s%s" % [
				id, String(n.get(&"kit_id")) if n.get(&"kit_id") != null else n.name, foot, best, gap if gap != INF else 9.99,
				moved, top, "  loose" if loose else "", flag])
	lines.append("%d shelf goods, %d bad" % [lines.size(), bad])
	print("\n".join(lines))
	quit(0)


## The highest point of a member prop's members (its top), else its own y.
func _top_member_y(n: Node3D, b: Node3D) -> float:
	if not n.has_method(&"get_members"):
		return b.to_local(n.global_position).y
	var hi := -INF
	for m in n.get_members():
		hi = maxf(hi, b.to_local(m.global_position).y + absf(m.size.y) * 0.5)
	return hi
