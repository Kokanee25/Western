class_name PropDressing
extends RefCounted
## A building's furniture and props laid into its rooms (#844): its spec's `dressing` (the doctor's,
## experiments/building_lab/doctor/doctor.json), placed by the building's own build
## (SpecBuilding._dressing), so the game and the labs that judge them read one placement and can't
## drift. Each entry is a kit prop at [x, y over the floor, z] in the building's space, turned
## `facing` degrees about Y (a prop faces +Z):
##   `on`         stands it on another entry's top (that kit's top board, or a glass prop's size);
##   `lift`       raises it a little more;
##   `fit`        a fixture fitted to a size [w, h, d] (PropKit.spawn_fitted);
##   `cloth_over` a cloth hung over that entry's `towel_bar` member (ClothProp.hang_over);
##   `light`      an OilLamp at that height in it, lit by the clock;
##   `row`        {kits, count, step, skip, jitter}: a row along `step` from `at`, the kits in turn
##                (a shelf of bottles), `skip` leaving gaps, each set down a little off by its id.
## Member props (KitProp) get the building's structure id and the entry's (`<building>_dress_<id>`),
## the same every build; at rest they join the street's PropBatch by themselves.


## The entries with every `row` laid out as single props.
static func expand(entries: Array) -> Array:
	var out: Array = []
	for e: Dictionary in entries:
		if not e.has("row"):
			out.append(e)
			continue
		var row: Dictionary = e.row
		var skip: Array = row.get("skip", [])
		for k in int(row.count):
			if skip.has(float(k)) or skip.has(k):
				continue
			var one := e.duplicate(true)
			one.erase("row")
			one.id = "%s_%d" % [e.id, k]
			one.kit = (row.kits as Array)[k % (row.kits as Array).size()]
			one.at = [float(e.at[0]) + float(row.step[0]) * k, float(e.at[1]) + float(row.step[1]) * k, float(e.at[2]) + float(row.step[2]) * k]
			# Set down by hand, not on a ruler (the prop lab's round 1 critic: rows like wallpaper):
			# each a little off its place and turned, by its id (the same every run).
			var j: Array = row.get("jitter", [0.0, 0.0, 0.0])
			if not j.is_empty():
				var h := hash(String(one.id))
				one.at[0] += float(j[0]) * (float(h % 1000) / 500.0 - 1.0)
				one.at[2] += float(j[1]) * (float((h / 1000) % 1000) / 500.0 - 1.0)
				one.facing = float(e.get("facing", 0.0)) + float(j[2]) * (float((h / 1000000) % 1000) / 500.0 - 1.0)
			out.append(one)
	return out


## `entries` laid into `parent` (a node in the building's space, already in the tree), the floor at
## `floor_y`; member props named from `structure_id`. Returns entry id -> its node.
static func place(parent: Node3D, entries: Array, floor_y: float, structure_id := "") -> Dictionary:
	var placed := {}
	var tops := {}
	for e: Dictionary in expand(entries):
		var id := StringName(e.kit)
		var def := PropKit.definition(id)
		var sid := StringName("%s_dress_%s" % [structure_id, e.id]) if structure_id != "" else &""
		if e.has("cloth_over"):
			var under: Node3D = placed[e.cloth_over]
			var cloth: Node3D = PropKit.make(id)
			parent.add_child(cloth)
			var bar = under.call(&"get_member", StringName("%s/towel_bar" % under.get(&"structure_id")))
			if bar:
				var top: Vector3 = bar.global_position + Vector3.UP * (float(bar.size.y) * 0.5 + 0.005)
				cloth.call(&"hang_over", bar, bar.global_basis.z, top)
			placed[e.id] = cloth
			continue
		var node: Node3D
		if e.has("fit"):
			node = PropKit.spawn_fitted(id, sid if sid != &"" else StringName("dress_%s" % e.id), Vector3(e.fit[0], e.fit[1], e.fit[2]))
		elif String(def.get("kind", "members")) == "members" and sid != &"":
			node = PropKit.spawn(id, sid)
		else:
			node = PropKit.make(id)
		var y := floor_y + float(e.at[1]) + float(e.get("lift", 0.0))
		if e.has("on"):
			y = float(tops[e.on]) + float(e.get("lift", 0.0))
		node.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(e.get("facing", 0.0)))), Vector3(e.at[0], y, e.at[2]))
		parent.add_child(node)
		tops[e.id] = y + top_of(e, def)
		if e.has("light"):
			var lamp := OilLamp.new()
			lamp.name = "Light"
			lamp.show_mesh = false
			lamp.lit_from_hour = 17
			lamp.lit_until_hour = 4
			# (a reflector lamp throws more of its light one way: a little over the sconces' 1.1)
			lamp.energy = 1.6
			lamp.light_range = 7.0
			lamp.position = Vector3(0, float(e.light), 0)
			node.add_child(lamp)
		placed[e.id] = node
	return placed


## How high over its foot an entry's top is: a fitted fixture's height, a member prop's highest top
## board (not a splashback over it), a glass or loose prop's size.
static func top_of(e: Dictionary, def: Dictionary) -> float:
	if e.has("fit"):
		return float(e.fit[1])
	if String(e.kit) == "wash_basin":
		return 0.014  # (its floor: the pitcher stands in it)
	if not def.has("members"):
		return float((def.get("size", [0, 0.1, 0]) as Array)[1])
	var tb := 0.0
	for m: Dictionary in PropKit.expand(def):
		if String(m.kind) == "furniture_top":
			tb = maxf(tb, float(m.at[1]) + float(m.size[1]) * 0.5)
	return tb if tb > 0.0 else PropKit.bounds(def).end.y
