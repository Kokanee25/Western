extends RefCounted
## The lived-in pass drawn (docs/briefs/lived-in.md): the marks marks.gd put on a structure's
## members (and its kit props') baked into a wear volume in the structure's own space and a finer
## map per floor level, and its batches drawn in the worn wood (wear_wood.gdshader: the game's wood
## with wear.gdshaderinc laid on through its WEAR hook). The building lab's only: for the game the
## marks go into the woods' shader itself (art, after Gate A).
##
##   WearPaint.apply(building)   # after it's built and batched (in the tree)

## The game's wood shaders and the lab's worn versions of them (the same wood, the marks laid on it).
const WOOD := {
	"res://src/render/texel_grid.gdshader": preload("res://experiments/building_lab/wear_wood.gdshader"),
	"res://src/render/texel_grid_blocks.gdshader": preload("res://experiments/building_lab/wear_wood_blocks.gdshader"),
}
## Wear volume cells a metre (walls, rails, posts, treads), floor map texels a metre.
const VOL_RES := 6.0
const FLOOR_RES := 20.0
## Which channel each mark goes in: 0 worn by feet, 1 polished, 2 dirt, 3 fresh. The outside
## weather (`splash`, `streak`, `bleach`) is the game's weathering layer's (texel_grid's stain sheet),
## not this: through a wall thinner than a cell it would also darken the wall's inside.
const CHANNEL := {
	&"foot": 0, &"heel": 0, &"scuff": 0,
	&"hand": 1, &"boot": 1, &"elbow": 1,
	&"grime": 2, &"rings": 2, &"spill": 2, &"burn": 2, &"cut": 2, &"soot": 2, &"holes": 2,
	&"bullet": 2, &"carved": 2,
	&"new": 3, &"pale": 3, &"scrubbed": 3, &"filled": 3,
}


static func apply(b: Structure, levels: Array[float] = []) -> Dictionary:
	var to_b := b.global_transform.affine_inverse()
	# Every marked member, with its transform in the building's space.
	var marked: Array = []
	var structures: Array = [b]
	structures.append_array(b.find_children("*", "KitProp", true, false))
	var bounds := AABB()
	var first := true
	for st: Structure in structures:
		var to_here: Transform3D = to_b * st.global_transform
		for m in st.get_members():
			var box: AABB = to_here * m.structure_aabb()
			if first:
				bounds = box
				first = false
			else:
				bounds = bounds.merge(box)
			if m.has_meta(&"marks"):
				marked.append([m, to_here * m.transform])
	bounds = bounds.grow(0.2)
	var vn := Vector3i((bounds.size * VOL_RES).ceil())
	# Bytes (0-255), as the textures take them: the deepest mark in a cell wins.
	var vol := PackedByteArray()
	vol.resize(vn.x * vn.y * vn.z * 4)
	var fn := Vector2i(ceili(bounds.size.x * FLOOR_RES), ceili(bounds.size.z * FLOOR_RES))
	var floors: Array[PackedByteArray] = []
	for l in levels:
		var f := PackedByteArray()
		f.resize(fn.x * fn.y * 4)
		floors.append(f)
	var written := 0
	for e: Array in marked:
		var m: StructureMember = e[0]
		var xf: Transform3D = e[1]
		var top := (xf * Vector3(0, m.size.y * 0.5, 0)).y
		var level := -1
		if m.kind == &"floor_board":
			for i in levels.size():
				if absf(top - levels[i]) < 0.03:
					level = i
		for mk: Dictionary in m.get_meta(&"marks", []):
			var ch: int = CHANNEL.get(StringName(mk.kind), -1)
			if ch < 0:
				continue
			written += 1
			if level >= 0:
				_paint(floors[level], Vector3i(fn.x, fn.y, 0), Vector3(bounds.position.x, 0, bounds.position.z), FLOOR_RES, m, xf, mk, ch, true)
			else:
				_paint(vol, Vector3i(vn), bounds.position, VOL_RES, m, xf, mk, ch, false)
	# The floors softened (a board's wear runs into its neighbours', as boots don't keep to boards).
	for f in floors:
		_soften(f, fn, 2)
	# What went in (for the lab's report): cells with any wear, in the volume and the floors.
	var stats := {"vol_cells": vol.count(0), "floor_cells": 0}
	stats.vol_cells = vol.size() - int(stats.vol_cells)
	for f in floors:
		stats.floor_cells += f.size() - f.count(0)
	# Into textures: the volume's slices (y up the stack), the floors as layers.
	var slices: Array[Image] = []
	var slab := vn.x * vn.y * 4
	for z in vn.z:
		slices.append(Image.create_from_data(vn.x, vn.y, false, Image.FORMAT_RGBA8, vol.slice(z * slab, (z + 1) * slab)))
	var tex3 := ImageTexture3D.new()
	tex3.create(Image.FORMAT_RGBA8, vn.x, vn.y, vn.z, false, slices)
	var layers: Array[Image] = []
	for f in floors:
		layers.append(Image.create_from_data(fn.x, fn.y, false, Image.FORMAT_RGBA8, f))
	var floors_tex := Texture2DArray.new()
	if not layers.is_empty():
		floors_tex.create_from_images(layers)
	var lv := Vector4(-99, -99, -99, -99)
	for i in mini(levels.size(), 4):
		lv[i] = levels[i]
	var params := {"wear_vol": tex3, "floor_maps": floors_tex, "wear_vol_origin": bounds.position,
			"wear_vol_size": Vector3(vn) / VOL_RES, "wear_floor_origin": Vector2(bounds.position.x, bounds.position.z),
			"wear_floor_size": Vector2(fn) / FLOOR_RES, "wear_floor_levels": lv, "wear_floor_count": mini(levels.size(), 4)}
	# Every batch of the building's and its kit props' drawn in the worn wood: its own material's
	# every parameter, the marks' textures, and the way from its space to the building's.
	var swapped := 0
	var made := {}
	for st: Structure in structures:
		var to_here := Projection(to_b * st.global_transform)
		for c in st.get_children(true):
			var mi := c as MeshInstance3D
			if mi == null or mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
				continue
			var orig := mi.material_override as ShaderMaterial
			if orig == null or not WOOD.has(orig.shader.resource_path):
				continue
			var key := [orig, st]
			if not made.has(key):
				var mat := ShaderMaterial.new()
				mat.shader = WOOD[orig.shader.resource_path]
				for u in orig.shader.get_shader_uniform_list():
					mat.set_shader_parameter(u.name, orig.get_shader_parameter(u.name))
				for k: String in params:
					mat.set_shader_parameter(k, params[k])
				mat.set_shader_parameter(&"wear_to_structure", to_here)
				made[key] = mat
			mi.material_override = made[key]
			swapped += 1
	return {"stats": stats, "marks_drawn": written, "volume": [vn.x, vn.y, vn.z], "floor_map": [fn.x, fn.y], "batches": swapped, "materials": made.size()}


## One mark into a grid (the volume, or a floor map in x and z): every cell whose centre is in the
## mark's part of the member gets the mark's strength (the deepest wins), falling off at its ends.
static func _paint(grid: PackedByteArray, n: Vector3i, origin: Vector3, res: float, m: StructureMember, xf: Transform3D,
		mk: Dictionary, ch: int, flat: bool) -> void:
	var half := m.size * 0.5
	var lo := -half
	var hi := half
	var ax := m.axis_index()
	var soft := Vector3.ZERO
	var centre := Vector3.INF
	var r := 0.0
	if mk.has("along"):
		lo[ax] = maxf(lo[ax], float(mk.along[0]) - 0.05)
		hi[ax] = minf(hi[ax], float(mk.along[1]) + 0.05)
		soft[ax] = 0.12
	elif mk.has("at"):
		centre = Vector3(mk.at[0], mk.at[1], mk.at[2])
		r = float(mk.r)
	elif String(mk.get("where", "")) == "centre":
		# A tread worn in the middle of its width, most at its front (where the foot lands).
		lo[ax] = -half[ax] * 0.6
		hi[ax] = half[ax] * 0.6
		soft[ax] = half[ax] * 0.45
	var s := float(mk.s)
	# The member's part as a box in the grid's space, cell by cell.
	var box := xf * AABB(lo, hi - lo)
	var c0 := ((box.position - origin) * res).floor()
	var c1 := ((box.end - origin) * res).ceil()
	var inv := xf.affine_inverse()
	for x in range(maxi(int(c0.x), 0), mini(int(c1.x), n.x)):
		for z in range(maxi(int(c0.z), 0), mini(int(c1.z), n.z if not flat else n.y)):
			var ys := [0] if flat else range(maxi(int(c0.y), 0), mini(int(c1.y), n.y))
			for y: int in ys:
				var p := origin + (Vector3(x, y, z) + Vector3(0.5, 0.5, 0.5)) / res
				if flat:
					p.y = (xf * Vector3(0, half.y, 0)).y - 0.001
				var l := inv * p
				# Within the part (a cell's half a cell of slack: thin members are thinner than a cell).
				var slack := 0.5 / res
				if l.x < lo.x - slack or l.x > hi.x + slack or l.y < lo.y - slack or l.y > hi.y + slack or l.z < lo.z - slack or l.z > hi.z + slack:
					continue
				var w := 1.0
				if centre != Vector3.INF:
					var d := (l - centre)
					if flat:
						d.y = 0.0
					var dist := d.length()
					if dist > r:
						continue
					w = 1.0 - smoothstep(r * 0.15, r, dist)
				for k in 3:
					if soft[k] > 0.0:
						var edge := minf(l[k] - lo[k], hi[k] - l[k])
						w *= clampf(edge / soft[k], 0.0, 1.0)
				var i := ((z * (1 if flat else n.y) + (0 if flat else y)) * n.x + x) * 4 + ch
				if flat:
					i = (z * n.x + x) * 4 + ch
				grid[i] = maxi(grid[i], int(clampf(s * w, 0.0, 1.0) * 255.0))


## A box blur over a floor map, `passes` times (each a 3x3 average, the deepest kept toward its centre).
static func _soften(f: PackedByteArray, n: Vector2i, passes: int) -> void:
	for p in passes:
		var src := f.duplicate()
		for y in range(1, n.y - 1):
			for x in range(1, n.x - 1):
				var base := (y * n.x + x) * 4
				for c in 4:
					var sum := 0
					for dy in [-1, 0, 1]:
						for dx in [-1, 0, 1]:
							sum += src[((y + dy) * n.x + x + dx) * 4 + c]
					f[base + c] = maxi(sum / 9, int(src[base + c] * 0.6))
