class_name BodyMesh
## A person's visible body, generated in code: one continuous skin (trunk, neck, head with a
## face, arms running into the palms, legs) lofted through cross-sections shaped on a real man's
## proportions and fitted round the anatomy's hitboxes, then clothes as looser shells over it
## (shirt, vest, trousers, boots, belts, bandana). Everything is skinned to one flat skeleton with
## a bone per anatomy segment, so it bends smoothly at the joints while the hitboxes and the
## ragdoll carry on driving it. The fingers, hat and holster stay separate rigid pieces.
##
## Body space = the anatomy's rest pose: facing -Z, feet at the origin, his right is +X.

const HEAD_BOTTOM := 1.545
const HEAD_TOP := 1.795

## Cross-sections: [centre, half width (x), front depth, back depth, bone A, bone B, weight of B].
## "Front" is toward -Z for upright parts. Right side; the left mirrors it.
const TRUNK := [
	[Vector3(0, 0.80, 0.005), 0.10, 0.075, 0.08, &"pelvis", &"pelvis", 0.0],
	[Vector3(0, 0.86, 0.005), 0.17, 0.095, 0.115, &"pelvis", &"pelvis", 0.0],
	[Vector3(0, 0.93, 0.0), 0.178, 0.1, 0.11, &"pelvis", &"pelvis", 0.0],
	[Vector3(0, 1.00, 0.0), 0.162, 0.098, 0.097, &"pelvis", &"abdomen", 0.5],
	[Vector3(0, 1.07, 0.0), 0.158, 0.104, 0.094, &"abdomen", &"abdomen", 0.0],
	[Vector3(0, 1.145, 0.0), 0.168, 0.11, 0.1, &"abdomen", &"chest", 0.3],
	[Vector3(0, 1.22, 0.0), 0.186, 0.12, 0.108, &"abdomen", &"chest", 0.75],
	[Vector3(0, 1.30, 0.0), 0.198, 0.126, 0.114, &"chest", &"chest", 0.0],
	[Vector3(0, 1.37, 0.004), 0.2, 0.116, 0.108, &"chest", &"chest", 0.0],
	[Vector3(0, 1.425, 0.008), 0.188, 0.088, 0.092, &"chest", &"chest", 0.0],
	[Vector3(0, 1.462, 0.012), 0.098, 0.062, 0.07, &"chest", &"neck", 0.3],
	[Vector3(0, 1.49, 0.012), 0.062, 0.052, 0.058, &"chest", &"neck", 0.6],
]
const NECK := [
	[Vector3(0, 1.46, 0.012), 0.058, 0.052, 0.056, &"chest", &"neck", 0.5],
	[Vector3(0, 1.51, 0.008), 0.054, 0.05, 0.052, &"neck", &"neck", 0.0],
	[Vector3(0, 1.55, 0.004), 0.052, 0.05, 0.05, &"neck", &"head", 0.4],
	[Vector3(0, 1.575, 0.0), 0.05, 0.046, 0.052, &"neck", &"head", 0.8],
]
## [centre, half width, front depth, back depth] from the chin to the crown, all on the head bone.
const HEAD := [
	[Vector3(0, 1.545, -0.035), 0.022, 0.042, 0.03],
	[Vector3(0, 1.56, -0.022), 0.05, 0.07, 0.058],
	[Vector3(0, 1.584, -0.01), 0.064, 0.083, 0.083],
	[Vector3(0, 1.61, -0.006), 0.07, 0.09, 0.094],
	[Vector3(0, 1.636, -0.006), 0.074, 0.091, 0.1],
	[Vector3(0, 1.66, -0.006), 0.075, 0.088, 0.102],
	[Vector3(0, 1.684, -0.004), 0.075, 0.093, 0.1],
	[Vector3(0, 1.714, 0.0), 0.072, 0.086, 0.095],
	[Vector3(0, 1.745, 0.002), 0.062, 0.072, 0.082],
	[Vector3(0, 1.772, 0.004), 0.045, 0.052, 0.058],
	[Vector3(0, 1.79, 0.004), 0.022, 0.025, 0.028],
]
## Right arm, shoulder to knuckles (the palm is part of the skin; fingers are separate).
const ARM := [
	[Vector3(0.188, 1.478, 0.004), 0.026, 0.026, 0.026, &"upper_arm_r", &"chest", 0.3],
	[Vector3(0.198, 1.452, 0.002), 0.055, 0.05, 0.052, &"upper_arm_r", &"chest", 0.25],
	[Vector3(0.206, 1.40, 0.0), 0.058, 0.052, 0.055, &"upper_arm_r", &"upper_arm_r", 0.0],
	[Vector3(0.212, 1.32, 0.0), 0.05, 0.048, 0.046, &"upper_arm_r", &"upper_arm_r", 0.0],
	[Vector3(0.218, 1.24, -0.004), 0.046, 0.05, 0.045, &"upper_arm_r", &"upper_arm_r", 0.0],
	[Vector3(0.222, 1.165, 0.0), 0.042, 0.042, 0.043, &"upper_arm_r", &"forearm_r", 0.2],
	[Vector3(0.225, 1.12, 0.002), 0.04, 0.04, 0.046, &"upper_arm_r", &"forearm_r", 0.5],
	[Vector3(0.228, 1.07, -0.004), 0.044, 0.044, 0.042, &"forearm_r", &"forearm_r", 0.0],
	[Vector3(0.231, 0.98, -0.008), 0.037, 0.036, 0.035, &"forearm_r", &"forearm_r", 0.0],
	[Vector3(0.234, 0.905, -0.01), 0.029, 0.025, 0.025, &"forearm_r", &"forearm_r", 0.0],
	[Vector3(0.235, 0.866, -0.01), 0.026, 0.022, 0.022, &"forearm_r", &"hand_r", 0.5],
	[Vector3(0.237, 0.84, -0.011), 0.018, 0.034, 0.03, &"hand_r", &"hand_r", 0.0],
	[Vector3(0.239, 0.80, -0.012), 0.016, 0.037, 0.033, &"hand_r", &"hand_r", 0.0],
	[Vector3(0.24, 0.773, -0.012), 0.012, 0.035, 0.031, &"hand_r", &"hand_r", 0.0],
]
## Right leg, hip to ankle.
const LEG := [
	[Vector3(0.088, 0.94, 0.0), 0.08, 0.08, 0.085, &"pelvis", &"thigh_r", 0.5],
	[Vector3(0.094, 0.86, 0.002), 0.088, 0.084, 0.098, &"pelvis", &"thigh_r", 0.8],
	[Vector3(0.097, 0.76, -0.004), 0.079, 0.08, 0.084, &"thigh_r", &"thigh_r", 0.0],
	[Vector3(0.099, 0.64, 0.0), 0.069, 0.07, 0.07, &"thigh_r", &"thigh_r", 0.0],
	[Vector3(0.1, 0.545, 0.0), 0.057, 0.057, 0.054, &"thigh_r", &"shin_r", 0.2],
	[Vector3(0.1, 0.485, -0.004), 0.052, 0.058, 0.05, &"thigh_r", &"shin_r", 0.5],
	[Vector3(0.1, 0.43, 0.0), 0.05, 0.05, 0.056, &"shin_r", &"shin_r", 0.0],
	[Vector3(0.1, 0.34, 0.005), 0.051, 0.047, 0.062, &"shin_r", &"shin_r", 0.0],
	[Vector3(0.1, 0.22, 0.01), 0.04, 0.04, 0.045, &"shin_r", &"shin_r", 0.0],
	[Vector3(0.1, 0.11, 0.01), 0.03, 0.032, 0.032, &"shin_r", &"shin_r", 0.0],
	[Vector3(0.1, 0.075, 0.01), 0.03, 0.034, 0.034, &"shin_r", &"foot_r", 0.5],
]
## Right boot foot, heel to toe: [centre, half width, height above centre, depth below centre].
const BOOT_FOOT := [
	[Vector3(0.1, 0.062, 0.072), 0.034, 0.045, 0.06],
	[Vector3(0.1, 0.068, 0.045), 0.046, 0.06, 0.07],
	[Vector3(0.1, 0.062, -0.03), 0.049, 0.05, 0.064],
	[Vector3(0.1, 0.046, -0.1), 0.05, 0.036, 0.048],
	[Vector3(0.1, 0.036, -0.165), 0.043, 0.026, 0.037],
	[Vector3(0.1, 0.034, -0.198), 0.026, 0.017, 0.034],
]

## The hat's crown, band to top: [centre, half width, front, back] on the head bone. Worn low, the
## brim about 3 cm over the brows (the painting's), and roomy enough for the generated (MakeHuman)
## skull, which is longer front to back than the lofted one: ~1 cm clear all round at the band.
## The painting's crown is low and wide at the band (about half the brim's width, 10 cm tall).
const HAT_CROWN := [
	[Vector3(0, 1.708, -0.004), 0.088, 0.114, 0.108],
	[Vector3(0, 1.752, -0.002), 0.086, 0.108, 0.102],
	[Vector3(0, 1.787, 0.0), 0.081, 0.099, 0.095],
	[Vector3(0, 1.807, 0.004), 0.072, 0.086, 0.084],
]
## The brim, band outwards: [half width, front, back, side lift, front and back dip]. Rolled up hard
## at the sides and dipping over the eyes, the painting's cattleman brim.
const HAT_BRIM := [
	[0.16, 0.172, 0.165, 0.012, 0.005],
	[0.205, 0.215, 0.205, 0.046, 0.016],
]
## The holster on his right hip, top to toe (flat against the thigh).
const HOLSTER := [
	[Vector3(0.198, 0.905, 0.012), 0.042, 0.022, 0.018, &"pelvis", &"pelvis", 0.0],
	[Vector3(0.203, 0.84, 0.0), 0.038, 0.021, 0.018, &"pelvis", &"pelvis", 0.0],
	[Vector3(0.206, 0.74, -0.012), 0.024, 0.017, 0.015, &"pelvis", &"pelvis", 0.0],
	[Vector3(0.207, 0.69, -0.018), 0.016, 0.014, 0.012, &"pelvis", &"pelvis", 0.0],
]

static var _cache := {}


## Everything a HumanBody needs to show a person: {bones: Array[StringName], rests:
## Array[Transform3D], shapes: {shape name: {bone index: [skinned mesh, rigid mesh]}}}. Each shape
## is cut into a piece per body part (each triangle goes to the part that moves it most), so
## wounds can open a part and a limb can come off; the skinned piece still bends with its
## neighbours at the joints, the rigid one (after an amputation) follows its own part only. `outfit` lists what he wears:
## shirt, vest, trousers, boots, gun_belt, bandana, coat (booleans), plus colours and `look`
## (see PeopleArt.face). Meshes are cached per outfit shape; materials are per person.
static func build(anatomy: Anatomy, outfit: Dictionary) -> Dictionary:
	var bones := anatomy.segment_order()
	var index := {}
	for i in bones.size():
		index[bones[i]] = i
	var rests: Array[Transform3D] = []
	for sid in bones:
		rests.append(Transform3D(Basis.IDENTITY, anatomy.segment_center(sid)))
	var key := ""
	for k in ["shirt", "vest", "coat", "trousers", "boots", "gun_belt", "bandana", "hat"]:
		key += "1" if outfit.get(k, k != "coat") else "0"
	var shapes: Dictionary
	if _cache.has(key):
		shapes = _cache[key]
	else:
		shapes = _build_shapes(index, outfit, anatomy.segment_center)
		_cache[key] = shapes
	return {"bones": bones, "rests": rests, "shapes": shapes}


static func _build_shapes(index: Dictionary, outfit: Dictionary, centre_of: Callable) -> Dictionary:
	var out := {}
	# The body itself: skin, and the head with its face.
	var skin := Lofter.new(index)
	skin.loft(TRUNK, 12, Vector3.FORWARD, 0.0, true, true)
	skin.loft(NECK, 10, Vector3.FORWARD, 0.0, false, false)
	for side in [1.0, -1.0]:
		skin.loft(_side(ARM, side), 10, Vector3.FORWARD, 0.0, true, true)
		skin.loft(_side(LEG, side), 10, Vector3.FORWARD, 0.0, true, true)
	out["skin"] = skin
	var head := Lofter.new(index)
	head.uv_mode = &"head"
	var head_rings := []
	for r: Array in HEAD:
		head_rings.append([r[0], r[1], r[2], r[3], &"head", &"head", 0.0])
	head.bumps = {4: [[0.62, 0.35, 0.05], [-0.62, 0.35, 0.05]], 5: [[0.38, 0.22, -0.05], [-0.38, 0.22, -0.05]],
			6: [[0.4, 0.3, 0.04], [-0.4, 0.3, 0.04]], 2: [[1.2, 0.4, 0.06], [-1.2, 0.4, 0.06]]}
	head.loft(head_rings, 16, Vector3.FORWARD, 0.0, true, true)
	head.bumps = {}
	_nose_and_ears(head)
	out["head"] = head
	# Clothes: each a looser shell over what it covers.
	if outfit.get("shirt", true):
		var shirt := Lofter.new(index)
		shirt.loft(_inflate(_rows(TRUNK, 0.93, 1.48), 0.008), 12, Vector3.FORWARD, 0.0, false, false)
		shirt.loft(_inflate(_rows(NECK, 1.45, 1.52), 0.01), 10, Vector3.FORWARD, 0.0, false, false)
		for side in [1.0, -1.0]:
			var sleeve := _inflate(_rows(_side(ARM, side), 0.885, 1.49), 0.011)
			for i in 2:  # snug over the shoulder, looser down the arm
				sleeve[i] = _widen(sleeve[i], Vector3.ZERO, -0.007)
			sleeve.append(_cuff(sleeve.back()))
			shirt.loft(sleeve, 10, Vector3.FORWARD, 0.0, true, false)
		out["shirt"] = shirt
	if outfit.get("vest", true):
		var vest := Lofter.new(index)
		var rows := _inflate(_rows(TRUNK, 0.99, 1.44), 0.019)
		# Open down the front: a V from the collar to a gap at the bottom.
		vest.gaps = [0.22, 0.2, 0.18, 0.2, 0.3, 0.46, 0.66, 0.9]
		vest.loft(rows, 16, Vector3.FORWARD, 0.0, false, false)
		vest.gaps = []
		out["vest"] = vest
	if outfit.get("coat", false):
		var coat := Lofter.new(index)
		var body_rows := _inflate(_rows(TRUNK, 0.78, 1.47), 0.03)
		body_rows.push_front(_widen(_inflate([TRUNK[0]], 0.05)[0], Vector3(0, -0.18, 0.02), 0.03))
		coat.gaps = [0.1, 0.1, 0.12, 0.14, 0.16, 0.2, 0.3, 0.45, 0.6, 0.7, 0.8, 0.95, 1.0]
		coat.loft(body_rows, 16, Vector3.FORWARD, 0.0, false, false)
		coat.gaps = []
		for side in [1.0, -1.0]:
			coat.loft(_inflate(_rows(_side(ARM, side), 0.9, 1.49), 0.02), 10, Vector3.FORWARD, 0.0, true, false)
		out["coat"] = coat
	if outfit.get("trousers", true):
		var trousers := Lofter.new(index)
		trousers.loft(_inflate(_rows(TRUNK, 0.8, 1.02), 0.012), 12, Vector3.FORWARD, 0.0, true, false)
		for side in [1.0, -1.0]:
			trousers.loft(_inflate(_rows(_side(LEG, side), 0.3, 0.95), 0.013), 10, Vector3.FORWARD, 0.0, false, false)
		out["trousers"] = trousers
	if outfit.get("boots", true):
		var boots := Lofter.new(index)
		for side in [1.0, -1.0]:
			var shaft := _inflate(_rows(_side(LEG, side), 0.07, 0.43), 0.02)
			shaft[0] = _widen(shaft[0], Vector3(0, 0.0, 0), 0.006)  # the top flares a little
			boots.loft(shaft, 10, Vector3.FORWARD, 0.0, false, true)
			var foot := []
			var foot_bone := StringName("foot_r" if side > 0 else "foot_l")
			var shin_bone := StringName("shin_r" if side > 0 else "shin_l")
			for i in BOOT_FOOT.size():
				var r: Array = BOOT_FOOT[i]
				var c: Vector3 = r[0]
				c.x *= side
				foot.append([c, r[1], r[2], r[3], shin_bone if i < 2 else foot_bone, foot_bone, 0.5 if i < 2 else 0.0])
			boots.loft(foot, 10, Vector3.UP, 0.0, true, true)
		out["boots"] = boots
	if outfit.get("gun_belt", true):
		var belt := Lofter.new(index)
		belt.band(0.965, 0.905, 0.06, 0.028, 16)
		out["gun_belt"] = belt
		var tbelt := Lofter.new(index)
		tbelt.band(1.0, 1.0, 0.035, 0.017, 16)
		out["belt"] = tbelt
	if outfit.get("bandana", true):
		var bandana := Lofter.new(index)
		var rows := _inflate(_rows(NECK, 1.45, 1.52), 0.018)
		bandana.loft(rows, 10, Vector3.FORWARD, 0.0, false, false)
		# The knotted triangle hanging at the front.
		bandana.triangle(Vector3(-0.05, 1.49, -0.07), Vector3(0.05, 1.49, -0.07), Vector3(0, 1.4, -0.105), &"chest")
		out["bandana"] = bandana
	if outfit.get("hat", true):
		var hat := Lofter.new(index)
		var crown := []
		for r: Array in HAT_CROWN:
			crown.append([r[0], r[1], r[2], r[3], &"head", &"head", 0.0])
		# The cattleman crease: pinched in at the front of the top.
		hat.bumps = {2: [[0.6, 0.3, -0.1], [-0.6, 0.3, -0.1]], 3: [[0.55, 0.3, -0.28], [-0.55, 0.3, -0.28], [0.0, 0.25, -0.1], [PI, 0.4, -0.12]]}
		hat.loft(crown, 14, Vector3.FORWARD, 0.0, false, true)
		hat.bumps = {}
		out["hat"] = hat
		var brim := Lofter.new(index)
		var b0: Array = HAT_CROWN[0]
		var brim_rings := [[b0[0], b0[1] - 0.004, b0[2] - 0.004, b0[3] - 0.004, &"head", &"head", 0.0]]
		for i in HAT_BRIM.size():
			var r: Array = HAT_BRIM[i]
			brim_rings.append([(b0[0] as Vector3) + Vector3(0, -0.004, 0), r[0], r[1], r[2], &"head", &"head", 0.0])
			brim.curl[i + 1] = r[3]
			brim.dip[i + 1] = r[4]
		brim.loft(brim_rings, 18, Vector3.FORWARD, 0.0, false, false)
		out["hat_brim"] = brim
		var band := Lofter.new(index)
		band.loft([[b0[0], b0[1] + 0.003, b0[2] + 0.003, b0[3] + 0.003, &"head", &"head", 0.0],
				[(b0[0] as Vector3) + Vector3(0, 0.022, 0), b0[1] + 0.002, b0[2] + 0.002, b0[3] + 0.002, &"head", &"head", 0.0]], 14, Vector3.FORWARD, 0.0, false, false)
		out["hat_band"] = band
	if outfit.get("gun_belt", true):
		var holster := Lofter.new(index)
		holster.loft(HOLSTER, 8, Vector3.RIGHT, 0.0, true, true)
		out["holster"] = holster
	var centres := {}
	for b: StringName in index:
		centres[index[b]] = centre_of.call(b)
	var meshes := {}
	for k: String in out:
		if not (out[k] as Lofter).is_empty():
			meshes[k] = (out[k] as Lofter).to_pieces(centres)
	return meshes


## Mirror right-side rings to the left (x flips, _r bones become _l).
static func _side(rows: Array, side: float) -> Array:
	if side > 0.0:
		return rows
	var out := []
	for r: Array in rows:
		var c: Vector3 = r[0]
		out.append([Vector3(-c.x, c.y, c.z), r[1], r[2], r[3], _mirror_bone(r[4]), _mirror_bone(r[5]), r[6]])
	return out


static func _mirror_bone(b: StringName) -> StringName:
	var s := String(b)
	if s.ends_with("_r"):
		return StringName(s.trim_suffix("_r") + "_l")
	return b


## The rings whose centres lie between two heights.
static func _rows(rows: Array, y0: float, y1: float) -> Array:
	var out := []
	for r: Array in rows:
		var y: float = (r[0] as Vector3).y
		if y >= y0 - 1e-4 and y <= y1 + 1e-4:
			out.append(r.duplicate())
	return out


static func _inflate(rows: Array, by: float) -> Array:
	var out := []
	for r: Array in rows:
		out.append([r[0], r[1] + by, r[2] + by, r[3] + by, r[4], r[5], r[6]])
	return out


static func _widen(r: Array, move: Vector3, by: float) -> Array:
	return [(r[0] as Vector3) + move, r[1] + by, r[2] + by, r[3] + by, r[4], r[5], r[6]]


## A shirt cuff: the sleeve's last ring again, a little lower and wider.
static func _cuff(r: Array) -> Array:
	return [(r[0] as Vector3) + Vector3(0, -0.012, 0), r[1] + 0.004, r[2] + 0.004, r[3] + 0.004, r[4], r[5], r[6]]


static func _nose_and_ears(head: Lofter) -> void:
	var hb := &"head"
	# Nose: a wedge from the bridge to the tip, flaring at the nostrils.
	var bridge := Vector3(0, 1.664, -0.088)
	var tip := Vector3(0, 1.624, -0.114)
	var under := Vector3(0, 1.616, -0.1)
	var l := Vector3(-0.015, 1.619, -0.094)
	var r := Vector3(0.015, 1.619, -0.094)
	head.tri(bridge, tip, r, hb)
	head.tri(bridge, l, tip, hb)
	head.tri(tip, under, r, hb)
	head.tri(tip, l, under, hb)
	# Ears: flat flaps standing off the sides.
	for s in [1.0, -1.0]:
		var top := Vector3(0.074 * s, 1.664, 0.006)
		var bottom := Vector3(0.072 * s, 1.612, 0.004)
		var back := Vector3(0.086 * s, 1.648, 0.022)
		var front := Vector3(0.078 * s, 1.638, -0.008)
		if s > 0.0:
			head.tri(top, back, front, hb)
			head.tri(front, back, bottom, hb)
		else:
			head.tri(top, front, back, hb)
			head.tri(front, bottom, back, hb)


## Builds skinned triangle lists: lofts through cross-sections, bands, loose triangles.
## Cut a skinned mesh into a piece per bone: each triangle goes to the bone that moves its corners
## most. Per bone: [skinned mesh, rigid mesh (every vertex on that bone only)], with CUSTOM0 = each
## vertex's rest position relative to its bone's centre (the wound shader opens holes there).
## `bones`/`weights` are 4 per vertex.
static func split_pieces(verts: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array,
		bones: PackedInt32Array, weights: PackedFloat32Array, tris: PackedInt32Array, centres: Dictionary) -> Dictionary:
	var owner := {}  # bone -> Array of triangle starts (a plain Array: packed ones copy)
	for t in range(0, tris.size(), 3):
		var score := {}
		for j in 3:
			var v := tris[t + j]
			for w in 4:
				var b := bones[v * 4 + w]
				score[b] = float(score.get(b, 0.0)) + weights[v * 4 + w]
		var best := -1
		var best_score := -1.0
		for b: int in score:
			if score[b] > best_score:
				best_score = score[b]
				best = b
		(owner.get_or_add(best, []) as Array).append(t)
	var out := {}
	for b: int in owner:
		var remap := {}
		var pv := PackedVector3Array()
		var pn := PackedVector3Array()
		var pu := PackedVector2Array()
		var pb := PackedInt32Array()
		var pw := PackedFloat32Array()
		var rb := PackedInt32Array()
		var rw := PackedFloat32Array()
		var pc := PackedFloat32Array()
		var pi := PackedInt32Array()
		var centre: Vector3 = centres.get(b, Vector3.ZERO)
		for t: int in owner[b]:
			for j in 3:
				var v := tris[t + j]
				if not remap.has(v):
					remap[v] = pv.size()
					pv.append(verts[v])
					pn.append(normals[v].normalized() if normals[v].length_squared() > 1e-12 else Vector3.UP)
					pu.append(uvs[v])
					for w in 4:
						pb.append(bones[v * 4 + w])
						pw.append(weights[v * 4 + w])
					rb.append_array([b, 0, 0, 0])
					rw.append_array([1.0, 0.0, 0.0, 0.0])
					var local := verts[v] - centre
					pc.append_array([local.x, local.y, local.z])
				pi.append(remap[v])
		out[b] = [Lofter._mesh(pv, pn, pu, pb, pw, pc, pi), Lofter._mesh(pv, pn, pu, rb, rw, pc, pi)]
	return out


class Lofter:
	var index: Dictionary
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var tris := PackedInt32Array()
	## &"metres": UVs in metres for tiling cloth; &"head": the face layout (see PeopleArt.face).
	var uv_mode := &"metres"
	## ring index -> [[angle, width, amount]]: bulges (+) or hollows (-) on that ring.
	var bumps := {}
	## Per ring, half-angle of an opening down the front (vests, coats); [] = closed.
	var gaps := []
	## ring index -> how far the sides of that ring lift (hat brims curl up at the sides).
	var curl := {}
	## ring index -> how far the front and back of that ring drop (a brim dipping over the eyes).
	var dip := {}

	func _init(bone_index: Dictionary) -> void:
		index = bone_index

	func _bone(b: StringName) -> int:
		return index.get(b, 0)

	## Loft through `rings` ([centre, half width, front, back, bone A, bone B, weight B]).
	## `front` is the direction that counts as the front of each ring.
	func loft(rings: Array, sides: int, front: Vector3, _twist: float, cap_start: bool, cap_end: bool) -> void:
		var n := rings.size()
		if n < 2:
			return
		var base := verts.size()
		var cols := sides + 1
		var length := 0.0
		var avg_perimeter := 0.0
		for r: Array in rings:
			var ea: float = r[1]
			var eb: float = (r[2] + r[3]) * 0.5
			avg_perimeter += PI * (3.0 * (ea + eb) - sqrt((3.0 * ea + eb) * (ea + 3.0 * eb)))
		avg_perimeter /= n
		var frames := []
		for i in n:
			var c: Vector3 = rings[i][0]
			var prev: Vector3 = rings[maxi(i - 1, 0)][0]
			var next: Vector3 = rings[mini(i + 1, n - 1)][0]
			var axis := (next - prev).normalized()
			var f := (front - axis * front.dot(axis)).normalized()
			var s := f.cross(axis).normalized()
			frames.append([axis, f, s])
		for i in n:
			var r: Array = rings[i]
			var c: Vector3 = r[0]
			if i > 0:
				length += c.distance_to(rings[i - 1][0])
			var f: Vector3 = frames[i][1]
			var s: Vector3 = frames[i][2]
			var gap: float = gaps[mini(i, gaps.size() - 1)] if not gaps.is_empty() else 0.0
			for k in cols:
				var t := float(k) / sides
				var theta := PI + TAU * t  # the seam at the back; t = 0.5 straight ahead
				if gap > 0.0:
					theta = gap + (TAU - 2.0 * gap) * t
				var ct := cos(theta)
				var st := sin(theta)
				var depth: float = r[2] if ct > 0.0 else r[3]
				var k_bump := 1.0
				for b: Array in bumps.get(i, []):
					var d := wrapf(theta - float(b[0]), -PI, PI)
					k_bump += float(b[2]) * exp(-(d * d) / (float(b[1]) * float(b[1])))
				var p := c + (f * ct * depth + s * st * float(r[1])) * k_bump
				p += Vector3.UP * (float(curl.get(i, 0.0)) * st * st - float(dip.get(i, 0.0)) * ct * ct)
				verts.append(p)
				normals.append(Vector3.ZERO)
				if uv_mode == &"head":
					var u := wrapf(theta / TAU + 0.5, 0.0, 1.0) if k < sides else 1.0
					if k == 0:
						u = 0.0
					uvs.append(Vector2(u, 1.0 - (p.y - HEAD_BOTTOM) / (HEAD_TOP - HEAD_BOTTOM)))
				else:
					uvs.append(Vector2(t * avg_perimeter, length))
				_skin(r[4], r[5], r[6])
		for i in n - 1:
			for k in sides:
				var a := base + i * cols + k
				var b := a + 1
				var c := a + cols
				var d := c + 1
				_quad(a, b, d, c, rings[i][0], rings[i + 1][0])
		if cap_start:
			_cap(base, cols, rings[0], frames[0][0] * -1.0, true)
		if cap_end:
			_cap(base + (n - 1) * cols, cols, rings[n - 1], frames[n - 1][0], false)
		# Smooth across the seam: the first and last columns share normals.
		_finish(base)
		if gaps.is_empty():
			for i in n:
				var a := base + i * cols
				var b := a + sides
				var sum := normals[a] + normals[b]
				normals[a] = sum
				normals[b] = sum

	func _skin(a: StringName, b: StringName, w: float) -> void:
		var ia := _bone(a)
		var ib := _bone(b)
		if ia == ib or w <= 0.0:
			bones.append_array([ia, 0, 0, 0])
			weights.append_array([1.0, 0.0, 0.0, 0.0])
		else:
			bones.append_array([ia, ib, 0, 0])
			weights.append_array([1.0 - w, w, 0.0, 0.0])

	## Two triangles facing out, away from the axis between the ring centres.
	func _quad(a: int, b: int, d: int, c: int, c0: Vector3, c1: Vector3) -> void:
		var mid := (verts[a] + verts[b] + verts[c] + verts[d]) * 0.25
		var axis_pt := (c0 + c1) * 0.5
		var out := mid - axis_pt
		out -= (c1 - c0).normalized() * out.dot((c1 - c0).normalized())
		_tri_out(a, b, d, out)
		_tri_out(a, d, c, out)

	## Add triangle i0-i1-i2, flipped if needed so it faces `outward` (Godot's front faces are
	## clockwise seen from outside).
	func _tri_out(i0: int, i1: int, i2: int, outward: Vector3) -> void:
		var n := (verts[i2] - verts[i0]).cross(verts[i1] - verts[i0])
		if n.dot(outward) < 0.0:
			tris.append_array([i0, i2, i1])
		else:
			tris.append_array([i0, i1, i2])

	func _cap(first: int, cols: int, ring: Array, outward: Vector3, _start: bool) -> void:
		var centre: Vector3 = ring[0]
		var ci := verts.size()
		verts.append(centre + outward * 0.004)
		normals.append(Vector3.ZERO)
		uvs.append(uvs[first] if uv_mode == &"head" else Vector2(0, uvs[first].y))
		_skin(ring[4], ring[5], ring[6])
		for k in cols - 1:
			_tri_out(ci, first + k, first + k + 1, outward)

	## A loose triangle on one bone (noses, ears, a bandana's knot), facing the way it winds.
	func tri(a: Vector3, b: Vector3, c: Vector3, bone: StringName) -> void:
		var base := verts.size()
		for p in [a, b, c]:
			verts.append(p)
			normals.append(Vector3.ZERO)
			if uv_mode == &"head":
				var ang := atan2(p.x, -p.z)
				uvs.append(Vector2(0.5 + ang / TAU, 1.0 - (p.y - HEAD_BOTTOM) / (HEAD_TOP - HEAD_BOTTOM)))
			else:
				uvs.append(Vector2(p.x + p.z, p.y))
			_skin(bone, bone, 0.0)
		tris.append_array([base, base + 1, base + 2])
		_finish(base)

	## Double-sided loose triangle.
	func triangle(a: Vector3, b: Vector3, c: Vector3, bone: StringName) -> void:
		tri(a, b, c, bone)
		tri(a, c, b, bone)

	## A belt round the hips: bottom edge from `y_left` (his left hip) to `y_right`, `width` high,
	## standing `off` metres out from the trunk's surface.
	func band(y_left: float, y_right: float, width: float, off: float, sides: int) -> void:
		var base := verts.size()
		var cols := sides + 1
		var perim := 0.0
		for row in 2:
			perim = 0.0
			var last := Vector3.ZERO
			for k in cols:
				var t := float(k) / sides
				var theta := PI + TAU * t
				var sx := sin(theta)
				var y := lerpf(y_left, y_right, (sx + 1.0) * 0.5) + width * row
				var r := BodyMesh.trunk_at(y)
				var ct := cos(theta)
				var depth: float = r[1] if ct > 0.0 else r[2]
				var p := Vector3(sx * (r[0] + off), y, -ct * (depth + off) + r[3])
				if k > 0:
					perim += p.distance_to(last)
				last = p
				verts.append(p)
				normals.append(Vector3.ZERO)
				uvs.append(Vector2(perim, 0.0625 * row))
				var bw := clampf((y - 0.97) / 0.06, 0.0, 1.0)
				_skin(&"pelvis", &"abdomen", bw * 0.5)
		for k in sides:
			var a := base + k
			var b := a + 1
			var c := a + cols
			var d := c + 1
			var mid := (verts[a] + verts[d]) * 0.5
			_tri_out(a, b, d, Vector3(mid.x, 0, mid.z))
			_tri_out(a, d, c, Vector3(mid.x, 0, mid.z))
		_finish(base)
		for a in [base, base + cols]:
			var sum: Vector3 = normals[a] + normals[a + sides]
			normals[a] = sum
			normals[a + sides] = sum

	## Accumulate face normals into the vertices added since `from`.
	func _finish(from: int) -> void:
		for t in range(0, tris.size(), 3):
			var i0 := tris[t]
			if i0 < from:
				continue
			var i1 := tris[t + 1]
			var i2 := tris[t + 2]
			var n := (verts[i2] - verts[i0]).cross(verts[i1] - verts[i0])
			normals[i0] += n
			normals[i1] += n
			normals[i2] += n

	## Cut into a piece per bone: {bone index: [skinned ArrayMesh, rigid ArrayMesh]}. Each vertex
	## carries its rest position relative to its piece's bone centre in CUSTOM0 (for wounds).
	func to_pieces(centres: Dictionary) -> Dictionary:
		return BodyMesh.split_pieces(verts, normals, uvs, bones, weights, tris, centres)

	static func _mesh(pv: PackedVector3Array, pn: PackedVector3Array, pu: PackedVector2Array, pb: PackedInt32Array,
			pw: PackedFloat32Array, pc: PackedFloat32Array, pi: PackedInt32Array) -> ArrayMesh:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = pv
		arrays[Mesh.ARRAY_NORMAL] = pn
		arrays[Mesh.ARRAY_TEX_UV] = pu
		arrays[Mesh.ARRAY_BONES] = pb
		arrays[Mesh.ARRAY_WEIGHTS] = pw
		arrays[Mesh.ARRAY_CUSTOM0] = pc
		arrays[Mesh.ARRAY_INDEX] = pi
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {},
				Mesh.ARRAY_CUSTOM_RGB_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
		return mesh

	func is_empty() -> bool:
		return tris.is_empty()

	func to_mesh() -> ArrayMesh:
		var ns := PackedVector3Array()
		ns.resize(normals.size())
		for i in normals.size():
			ns[i] = normals[i].normalized() if normals[i].length_squared() > 1e-12 else Vector3.UP
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = ns
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
		arrays[Mesh.ARRAY_INDEX] = tris
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return mesh


## The trunk's cross-section at a height: [half width, front depth, back depth, centre z].
static func trunk_at(y: float) -> Array:
	for i in TRUNK.size() - 1:
		var a: Array = TRUNK[i]
		var b: Array = TRUNK[i + 1]
		var ya: float = (a[0] as Vector3).y
		var yb: float = (b[0] as Vector3).y
		if y >= ya and y <= yb:
			var t := (y - ya) / (yb - ya)
			return [lerpf(a[1], b[1], t), lerpf(a[2], b[2], t), lerpf(a[3], b[3], t), lerpf((a[0] as Vector3).z, (b[0] as Vector3).z, t)]
	var e: Array = TRUNK[0] if y < 0.9 else TRUNK.back()
	return [e[1], e[2], e[3], (e[0] as Vector3).z]
