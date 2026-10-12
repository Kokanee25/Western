class_name HandModel
extends Node3D
## A right hand gripping a revolver, finger by finger: three bones per finger, two for the thumb,
## so a finger can later be shot away and seen to be gone. Posed in code; the index finger
## squeezes the trigger and the thumb reaches for the hammer.
## Built round RevolverModel's grip (same local space as the gun): the palm against the grip's
## right side and backstrap, the middle, ring and little fingers wrapped round the front strap
## to the left side, the index through the guard onto the trigger, the thumb along the left of
## the frame. Every part is a rounded loft (GunParts.sweep / lofted), flat-shaded so its facets
## read as the form, on the held texel grid.

var index: Array[Node3D] = []
var thumb: Array[Node3D] = []
var fingers := {}  # name -> Array[Node3D] segments

var _trigger := 0.0
var _thumb_reach := 0.0
# The thumb's turn from resting along the frame to on the hammer spur.
var _thumb_turn := Quaternion.IDENTITY

# How far off the grip's wood the skin lies, and the fingers' half-thickness at their roots.
const GAP := 0.0012
const FINGER_R := 0.0098


func _ready() -> void:
	_build()


func _build() -> void:
	var skin := GunParts.skin()
	var sleeve := GunParts.held_cloth("coat", Color(0.36, 0.25, 0.16))
	var cuff := GunParts.held_cloth("cuff", Color(0.82, 0.76, 0.62))

	# Middle, ring and little fingers wrap round the front strap: knuckle on the right side, the
	# first bone forward to the strap, the second round it, the tip back along the left side.
	var names := ["middle", "ring", "little"]
	var heights := [-0.0265, -0.047, -0.0665]
	var reach := [0.1, 0.094, 0.08]
	var thick := [1.0, 0.97, 0.88]
	for i in 3:
		# The knuckle stands out on the back of the hand; the bone settles onto the wood as it
		# reaches the front strap.
		var path := _round_grip(heights[i], 112.0, -150.0, FINGER_R * thick[i] + GAP, 24)
		for k in path.size():
			var phi := lerpf(112.0, -150.0, float(k) / 24.0)
			var lift := 0.011 * smoothstep(60.0, 112.0, phi)
			path[k] = _grip_point(heights[i], phi, FINGER_R * thick[i] + GAP + lift)
		fingers[names[i]] = chain(self, names[i], cut(path, reach[i]), [0.46, 0.3, 0.24],
				FINGER_R * thick[i], skin)

	# Index: from its knuckle at the top of the grip's right side, forward into the guard, round
	# the front of the trigger and hooked back on its left.
	var ip := smooth([Vector3(0.0215, -0.002, 0.012), Vector3(0.019, -0.006, -0.004),
			Vector3(0.012, -0.010, -0.019), Vector3(0.002, -0.0135, -0.029),
			Vector3(-0.009, -0.015, -0.028), Vector3(-0.0155, -0.0145, -0.019)], 4)
	index = chain(self, "index", cut(ip, 0.092), [0.46, 0.3, 0.24], FINGER_R * 0.97, skin)
	fingers["index"] = index

	# Thumb: from the web high on the backstrap, along the left of the frame under the hammer,
	# pointing forward.
	var tp := smooth([Vector3(-0.012, 0.004, 0.044), Vector3(-0.024, 0.009, 0.026),
			Vector3(-0.031, 0.015, 0.006), Vector3(-0.033, 0.018, -0.012)], 4)
	thumb = chain(self, "thumb", cut(tp, 0.062), [0.55, 0.45], 0.0116, skin)
	fingers["thumb"] = thumb
	# Cocked: the tip up and back onto the hammer's spur.
	var rest := (tp[tp.size() - 1] - tp[0]).normalized()
	var spur := (Vector3(-0.005, 0.068, 0.024) - tp[0]).normalized()
	_thumb_turn = Quaternion(rest, spur)

	# The palm and the back of the hand, wrapped round the grip's back and right side from the
	# knuckles to the web, from under the hammer to the heel below the little finger.
	var rings := []
	var ys := [0.011, 0.004, -0.008, -0.022, -0.038, -0.054, -0.068, -0.079, -0.086]
	for y in ys:
		rings.append(_palm_ring(y))
	GunParts.lofted(self, "Palm", rings, skin)

	# Wrist and forearm: out of the heel of the hand, back, down and out to the right towards the
	# shoulder (out of the sight line). The wrist is taller than it's thick: the hand stands on
	# its edge round the grip.
	var start := Vector3(0.009, -0.038, 0.06)
	var dir := Basis.from_euler(Vector3(deg_to_rad(32.0), deg_to_rad(22.0), 0.0), EULER_ORDER_YXZ) * Vector3.BACK
	var arm := [
		[0.0, 0.017, 0.026, skin], [0.03, 0.020, 0.028, skin], [0.06, 0.022, 0.030, skin],
		[0.075, 0.0225, 0.031, skin]]
	GunParts.lofted(self, "Wrist", tube(start, dir, arm), skin)
	# The shirt's cuff, then the coat's sleeve.
	GunParts.lofted(self, "Cuff", tube(start, dir, [[0.068, 0.028, 0.035], [0.072, 0.031, 0.037],
			[0.098, 0.032, 0.038], [0.104, 0.030, 0.036]]), cuff)
	GunParts.lofted(self, "Sleeve", tube(start, dir, [[0.094, 0.034, 0.040], [0.1, 0.039, 0.044],
			[0.2, 0.042, 0.047], [0.34, 0.045, 0.05]]), sleeve)


## The grip's cross-section at height `y`, offset `off` out from the wood: (x, z) at angle `phi`
## degrees round it (0 the front strap, 90 the right side, 180 the backstrap, -90 the left).
static func _grip_point(y: float, phi: float, off: float) -> Vector3:
	var fz := _strap_z(RevolverModel.GRIP_FRONT, y)
	var bz := _strap_z(RevolverModel.GRIP_BACK, y)
	var t := clampf((0.002 - y) / 0.095, 0.0, 1.0)
	var w := lerpf(0.0125, 0.0165, smoothstep(0.0, 0.75, t)) + off
	var h := (bz - fz) * 0.5 + off
	var zc := (fz + bz) * 0.5
	var a := deg_to_rad(phi)
	var c := cos(a)
	var s := sin(a)
	var cx := signf(c) * pow(absf(c), 0.7)
	var sx := signf(s) * pow(absf(s), 0.7)
	return Vector3(w * sx, y, zc - h * cx)


## Where a strap's curve (forward, up knots) is at height `y`, as z.
static func _strap_z(knots: Array, y: float) -> float:
	for i in knots.size() - 1:
		var a: Array = knots[i]
		var b: Array = knots[i + 1]
		if (y <= a[1] and y >= b[1]) or i == knots.size() - 2:
			var k := clampf((y - a[1]) / (b[1] - a[1]), 0.0, 1.0) if b[1] != a[1] else 0.0
			return -lerpf(a[0], b[0], k)
	return -float(knots[0][0])


## Points round the grip at height `y` from angle `from` to `to`, `off` out from the wood.
static func _round_grip(y: float, from: float, to: float, off: float, steps: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in steps + 1:
		out.append(_grip_point(y, lerpf(from, to, float(i) / steps), off))
	return out


## A ring of the palm at height `y`: the hand's skin from the knuckles on the right side round the
## backstrap to the web on the left, thick on the right (palm, bones, back of the hand) and at the
## back (the heel), thin where it wraps the left.
func _palm_ring(y: float) -> PackedVector3Array:
	var inner := PackedVector3Array()
	var outer := PackedVector3Array()
	# Up high it narrows to the web between thumb and index; low it's the heel of the hand.
	var top := smoothstep(0.0, 0.013, y)
	var from := lerpf(98.0, 128.0, top)
	var to := lerpf(238.0, 206.0, top)
	var steps := 10
	for i in steps + 1:
		var phi := lerpf(from, to, float(i) / steps)
		var p := _grip_point(y, phi, GAP)
		# Thickness by where round: the back of the hand on the right, the heel behind.
		var right := clampf(1.0 - absf(phi - 115.0) / 70.0, 0.0, 1.0)
		var back := clampf(1.0 - absf(phi - 185.0) / 60.0, 0.0, 1.0)
		var t := 0.008 + 0.014 * right + 0.012 * back * (1.0 - top * 0.6)
		var q := _grip_point(y, phi, GAP + t)
		inner.append(p)
		outer.append(q)
	var ring := PackedVector3Array()
	for v in outer:
		ring.append(v)
	for i in range(inner.size() - 1, -1, -1):
		ring.append(inner[i])
	return ring


## Rings of a tube along `dir` from `start`: each [distance, half-thickness across x, half-height].
static func tube(start: Vector3, dir: Vector3, stations: Array, sides := 10) -> Array:
	var fwd := dir.normalized()
	var up := (Vector3.UP - fwd * Vector3.UP.dot(fwd)).normalized()
	var side := up.cross(fwd).normalized()
	var rings := []
	for s in stations:
		var c: Vector3 = start + fwd * float(s[0])
		var ring := PackedVector3Array()
		for k in sides:
			var a := TAU * k / sides
			ring.append(c + side * cos(a) * float(s[1]) + up * sin(a) * float(s[2]))
		rings.append(ring)
	return rings


## A point on an oval round the z axis (a stock's wrist, a forend): centre `c`, `rx` across and
## `ry` up, `off` out from it, at `phi` degrees round (0 underneath, 90 the right side, 180 the
## top, -90 the left).
static func oval_point(c: Vector3, rx: float, ry: float, phi: float, off: float) -> Vector3:
	var a := deg_to_rad(phi)
	return c + Vector3((rx + off) * sin(a), -(ry + off) * cos(a), 0.0)


## Points round that oval from `from` to `to` degrees.
static func round_oval(c: Vector3, rx: float, ry: float, from: float, to: float, off: float, steps: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in steps + 1:
		out.append(oval_point(c, rx, ry, lerpf(from, to, float(i) / steps), off))
	return out


## A closed ring of skin laid over part of an oval: out along `outer`, back along `inner`.
static func shell_ring(inner: PackedVector3Array, outer: PackedVector3Array) -> PackedVector3Array:
	var ring := PackedVector3Array()
	for v in outer:
		ring.append(v)
	for i in range(inner.size() - 1, -1, -1):
		ring.append(inner[i])
	return ring


## A smooth path through `knots` (Catmull-Rom), `per` points a span.
static func smooth(knots: Array, per: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in knots.size() - 1:
		var p0: Vector3 = knots[maxi(i - 1, 0)]
		var p1: Vector3 = knots[i]
		var p2: Vector3 = knots[i + 1]
		var p3: Vector3 = knots[mini(i + 2, knots.size() - 1)]
		for s in per:
			var t := float(s) / per
			out.append(0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
					+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t))
	out.append(knots[knots.size() - 1])
	return out


## The first `length` metres of `path`.
static func cut(path: PackedVector3Array, length: float) -> PackedVector3Array:
	var out := PackedVector3Array([path[0]])
	var left := length
	for i in path.size() - 1:
		var seg := path[i].distance_to(path[i + 1])
		if seg >= left:
			out.append(path[i].lerp(path[i + 1], left / seg))
			return out
		out.append(path[i + 1])
		left -= seg
	return out


## A finger along `path`, cut into bones of `shares` of its length: each a pivot at its knuckle
## (nested, so turning one carries the rest) with a rounded, tapering bone, a little longer than
## its share so the joints close. `r` is the root's half-thickness.
static func chain(root: Node3D, n: String, path: PackedVector3Array, shares: Array, r: float, mat: Material) -> Array[Node3D]:
	var total := 0.0
	var dist := [0.0]
	for i in path.size() - 1:
		total += path[i].distance_to(path[i + 1])
		dist.append(total)
	var segs: Array[Node3D] = []
	var parent: Node3D = root
	var parent_at := Vector3.ZERO
	var from := 0.0
	for b in shares.size():
		var to: float = from + total * float(shares[b])
		var bone := PackedVector3Array()
		for i in path.size():
			var d: float = dist[i]
			if d > from + 1e-5 and d < to - 1e-5:
				bone.append(path[i])
		bone.insert(0, _at(path, dist, from))
		bone.append(_at(path, dist, minf(to + r * 0.6, total)))
		var k := GunParts.pivot(parent, "%s%d" % [n.capitalize(), b], bone[0] - parent_at)
		var local := PackedVector3Array()
		for v in bone:
			local.append(v - bone[0])
		var r0 := r * (1.0 - 0.12 * b)
		var taper := (1.0 - 0.12 * (b + 1)) / (1.0 - 0.12 * b)
		if b == shares.size() - 1:
			taper = 0.72
		# A little taller than wide: neighbours touch, as a gripping hand's do.
		GunParts.sweep(k, "Bone", local, r0 * 0.94, r0 * 1.08, mat, 8, taper)
		segs.append(k)
		parent = k
		parent_at = bone[0]
		from = to
	return segs


static func _at(path: PackedVector3Array, dist: Array, d: float) -> Vector3:
	for i in path.size() - 1:
		if d <= float(dist[i + 1]) or i == path.size() - 2:
			var span: float = float(dist[i + 1]) - float(dist[i])
			return path[i].lerp(path[i + 1], clampf((d - float(dist[i])) / maxf(span, 1e-6), 0.0, 1.0))
	return path[path.size() - 1]


## 0 = finger resting on the trigger, 1 = squeezed.
func set_trigger(amount: float) -> void:
	_trigger = amount
	if index.size() == 3:
		index[1].rotation_degrees.y = amount * 10.0
		index[2].rotation_degrees.y = amount * 16.0


## 0 = thumb resting along the frame, 1 = thumb on the hammer spur, pulling.
func set_thumb(amount: float) -> void:
	_thumb_reach = amount
	if thumb.size() == 2:
		thumb[0].quaternion = Quaternion.IDENTITY.slerp(_thumb_turn, amount)
		thumb[1].rotation_degrees.x = -amount * 25.0
