class_name RevolverModel
extends Node3D
## A Colt Single Action Army with a 7½" barrel, built in code from its side profile (the way a
## gunsmith draws it): the case-hardened frame with its curve down into the trigger guard, the
## top strap and round-topped recoil shield, the fluted cylinder, the plum-shaped walnut grip
## between brass straps, the hammer with its spur, the ejector rod under the barrel. The hammer,
## trigger, cylinder, loading gate and ejector rod are separate moving parts; the chambers show
## brass when loaded.
## Local space: barrel along -Z, top up +Y, origin where the grip meets the frame. Profiles below
## are (forward, up) in metres: forward is -Z.

const CHAMBER_RADIUS := 0.0135
const CYLINDER_AXIS := Vector3(0.0, 0.03, -0.034)
const CYLINDER_LENGTH := 0.042
const CYLINDER_RADIUS := 0.021
const BORE_Y := 0.04
const BARREL_FROM := 0.066
const BARREL_LENGTH := 0.19

var hammer: Node3D
var trigger: Node3D
var cylinder: Node3D
var gate: Node3D
var ejector: Node3D
var muzzle: Marker3D
var gate_point: Marker3D

var _rims: Array[MeshInstance3D] = []
var _primers: Array[MeshInstance3D] = []


func _ready() -> void:
	_build()


static func _pts(a: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in a:
		out.append(Vector2(p[0], p[1]))
	return out


## Points along a smooth curve through `knots` (Catmull-Rom), `per` a span.
static func _curve(knots: Array, per := 4) -> PackedVector2Array:
	var k := _pts(knots)
	var out := PackedVector2Array()
	for i in k.size() - 1:
		var p0 := k[maxi(i - 1, 0)]
		var p1 := k[i]
		var p2 := k[i + 1]
		var p3 := k[mini(i + 2, k.size() - 1)]
		for s in per:
			var t := float(s) / per
			out.append(0.5 * (2.0 * p1 + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
					+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t))
	out.append(k[k.size() - 1])
	return out


static func _v3(p: Vector2, x := 0.0) -> Vector3:
	return Vector3(x, p.y, -p.x)


func _build() -> void:
	var steel := GunParts.blued()
	var frame_mat := GunParts.case_hardened()
	var brass := GunParts.brass()
	var dark := GunParts.grid("bore", PixelArt.metal("bore", Color(0.04, 0.04, 0.05), 91))

	# The frame below and in front of the cylinder: the bottom bar under the cylinder window, the
	# post the barrel screws into, and its curve down into the trigger guard.
	var lower := _pts([[-0.007, 0.002], [0.010, 0.0], [0.030, -0.001], [0.044, 0.0], [0.054, 0.004],
			[0.062, 0.011], [0.068, 0.020], [0.069, 0.050], [0.066, 0.057], [0.058, 0.057],
			[0.0565, 0.011], [0.014, 0.0095], [0.012, 0.0085], [-0.004, 0.009]])
	GunParts.slab(self, "Frame", lower, 0.0125, frame_mat, 0.0016)
	# The top strap over the cylinder, with the rear sight's groove behind.
	GunParts.slab(self, "TopStrap", _pts([[-0.002, 0.052], [0.066, 0.0535], [0.066, 0.061],
			[0.010, 0.0612], [0.002, 0.0605], [-0.004, 0.058]]), 0.0072, frame_mat, 0.0014)
	# The recoil shield behind the cylinder, round-topped about its axis, and the hammer's well.
	var shield := _pts([[-0.008, 0.002], [0.013, 0.004], [0.0135, 0.040], [0.012, 0.050], [0.0085, 0.056],
			[0.004, 0.0585], [-0.001, 0.056], [-0.005, 0.046], [-0.009, 0.030]])
	GunParts.slab(self, "RecoilShield", shield, 0.0185, frame_mat, 0.002)
	# Frame screws, the base pin and its latch screw: bright dots on the case colours.
	for s in [[0.002, 0.012], [0.036, 0.004], [0.028, 0.054]]:
		GunParts.tube(self, "Screw%d" % int(s[0] * 1000), 0.0023, 0.0024, Vector3(0.0135, s[1], -s[0]), steel, 8, Vector3(0, 0, 90))
	GunParts.tube(self, "BasePinLatch", 0.0022, 0.0024, Vector3(0.0128, 0.024, -0.062), steel, 8, Vector3(0, 0, 90))
	GunParts.tube(self, "BasePin", 0.0032, 0.016, _v3(Vector2(0.074, CYLINDER_AXIS.y)), steel, 10)

	# Barrel: a little swelled at the frame, crowned at the muzzle, the front sight a blade.
	var barrel_rings := []
	for st in [[BARREL_FROM - 0.004, 0.0098], [BARREL_FROM + 0.01, 0.0098], [BARREL_FROM + 0.014, 0.0088],
			[BARREL_FROM + BARREL_LENGTH - 0.002, 0.0083], [BARREL_FROM + BARREL_LENGTH, 0.0075]]:
		barrel_rings.append(_ring_z(st[0], BORE_Y, st[1], st[1], 16))
	GunParts.lofted(self, "Barrel", barrel_rings, steel)
	GunParts.tube(self, "BarrelBore", 0.0058, 0.002, _v3(Vector2(BARREL_FROM + BARREL_LENGTH + 0.0004, BORE_Y)), dark, 10)
	GunParts.slab(self, "FrontSight", _pts([[BARREL_FROM + BARREL_LENGTH - 0.016, BORE_Y + 0.006],
			[BARREL_FROM + BARREL_LENGTH - 0.004, BORE_Y + 0.006], [BARREL_FROM + BARREL_LENGTH - 0.005, BORE_Y + 0.0125],
			[BARREL_FROM + BARREL_LENGTH - 0.009, BORE_Y + 0.0135]]), 0.0014, steel, 0.0004)
	# The ejector rod's housing along the barrel's right underside, its stud screw and the rod's
	# crescent head at the front (the part that moves when you punch out a case).
	var housing_len := 0.14
	var hz := []
	for st in [[0.068, 0.0058], [0.072, 0.0058], [0.068 + housing_len - 0.004, 0.0056], [0.068 + housing_len, 0.0046]]:
		hz.append(_ring_z(st[0], 0.0285, st[1], st[1] * 0.92, 10, 0.0082))
	GunParts.lofted(self, "EjectorHousing", hz, steel)
	GunParts.tube(self, "HousingScrew", 0.0018, 0.002, Vector3(0.0145, 0.03, -0.17), steel, 8, Vector3(0, 0, 90))
	ejector = GunParts.pivot(self, "Ejector", Vector3(0.0082, 0.0285, -0.07 - housing_len))
	GunParts.slab(ejector, "EjectorHead", _pts([[-0.002, -0.004], [0.006, -0.0045], [0.0085, 0.0],
			[0.006, 0.0045], [-0.002, 0.004]]), 0.0034, steel, 0.0008, 0.0012)
	GunParts.tube(ejector, "EjectorRod", 0.0016, 0.012, Vector3(0, 0, 0.004), steel, 6)
	muzzle = Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, BORE_Y, -(BARREL_FROM + BARREL_LENGTH) - 0.004)
	add_child(muzzle)

	# The cylinder: six chambers, fluted between them, bevelled at the front; turns about its axis.
	cylinder = GunParts.pivot(self, "Cylinder", CYLINDER_AXIS)
	var cyl_rings := []
	var half := CYLINDER_LENGTH * 0.5
	for st in [[half, CYLINDER_RADIUS - 0.0012, 0.0], [half - 0.0015, CYLINDER_RADIUS, 0.0],
			[half - 0.010, CYLINDER_RADIUS, 0.0], [half - 0.0135, CYLINDER_RADIUS, 1.0],
			[-half + 0.0085, CYLINDER_RADIUS, 1.0], [-half + 0.0055, CYLINDER_RADIUS, 0.0],
			[-half + 0.003, CYLINDER_RADIUS, 0.0], [-half, CYLINDER_RADIUS - 0.0035, 0.0]]:
		cyl_rings.append(_fluted(st[0], st[1], st[2], 48))
	GunParts.lofted(cylinder, "Body", cyl_rings, steel)
	for i in 6:
		var a := deg_to_rad(i * 60.0)
		var p := Vector3(sin(a) * CHAMBER_RADIUS, cos(a) * CHAMBER_RADIUS, 0.0)
		var rim := GunParts.tube(cylinder, "Rim%d" % i, 0.0062, 0.002, p + Vector3(0, 0, half + 0.001), brass, 8)
		var primer := GunParts.tube(cylinder, "Primer%d" % i, 0.0022, 0.0022, p + Vector3(0, 0, half + 0.0015), GunParts.grid("primer", PixelArt.metal("primer", Color(0.55, 0.42, 0.28), 93)), 6)
		GunParts.tube(cylinder, "Mouth%d" % i, 0.0058, 0.002, p - Vector3(0, 0, half + 0.0005), dark, 8)
		_rims.append(rim)
		_primers.append(primer)

	# Loading gate on the right of the recoil shield, hinged at its bottom edge.
	gate = GunParts.pivot(self, "Gate", Vector3(0.0188, 0.018, -0.005))
	GunParts.slab(gate, "Flap", _pts([[-0.0055, 0.0], [0.0055, 0.0], [0.0055, 0.016], [0.002, 0.020],
			[-0.002, 0.020], [-0.0055, 0.016]]), 0.0012, frame_mat, 0.0005, 0.0005)
	gate_point = Marker3D.new()
	gate_point.name = "GatePoint"
	gate_point.position = Vector3(0.012, 0.037, 0.0)
	add_child(gate_point)

	# Hammer: pivots at the back of the frame; a stout body rising to the firing pin, the spur
	# curling back over the grip where your thumb pulls it.
	hammer = GunParts.pivot(self, "Hammer", Vector3(0, 0.03, 0.004))
	GunParts.slab(hammer, "Body", _pts([[0.003, -0.007], [0.0075, 0.004], [0.0075, 0.019], [0.006, 0.0265],
			[0.002, 0.029], [-0.006, 0.030], [-0.015, 0.032], [-0.024, 0.034], [-0.031, 0.0335],
			[-0.0325, 0.030], [-0.026, 0.0285], [-0.016, 0.025], [-0.009, 0.018], [-0.006, 0.006],
			[-0.004, -0.006]]), 0.0043, frame_mat, 0.0012)

	# Trigger: a curved blade.
	trigger = GunParts.pivot(self, "Trigger", Vector3(0, -0.004, -0.018))
	GunParts.slab(trigger, "Blade", _pts([[0.0025, 0.004], [0.0035, -0.006], [0.002, -0.014],
			[-0.002, -0.020], [-0.0055, -0.022], [-0.0045, -0.018], [-0.002, -0.012], [-0.0012, -0.004],
			[-0.002, 0.004]]), 0.0024, steel, 0.0007)

	# The brass trigger guard's bow, running on down the grip's front as its front strap.
	var bow := _curve([[0.046, 0.001], [0.040, -0.016], [0.028, -0.028], [0.013, -0.030], [0.001, -0.022],
			[-0.005, -0.008], [-0.009, -0.025], [-0.015, -0.048], [-0.021, -0.070], [-0.025, -0.086], [-0.027, -0.094]], 5)
	var bow3 := PackedVector3Array()
	for p in bow:
		bow3.append(_v3(p))
	GunParts.sweep(self, "Guard", bow3, 0.0042, 0.0022, brass, 8)

	# The grip: walnut, plum-shaped, swelling at the bottom, between the front strap and the
	# backstrap (brass, up to the hammer).
	var front := _curve([[-0.004, 0.002], [-0.008, -0.020], [-0.014, -0.045], [-0.020, -0.068], [-0.024, -0.085],
			[-0.0255, -0.093]], 5)
	var back := _curve([[-0.009, 0.026], [-0.020, 0.016], [-0.034, -0.002], [-0.046, -0.026], [-0.055, -0.052],
			[-0.061, -0.075], [-0.0635, -0.088], [-0.062, -0.096]], 4)
	var rings := []
	var stations := 14
	for i in stations:
		var t := float(i) / (stations - 1)
		var f := _along(front, t)
		var b := _along(back, t)
		var w := lerpf(0.0125, 0.0165, smoothstep(0.0, 0.75, t)) - 0.0015 * smoothstep(0.85, 1.0, t)
		rings.append(_grip_ring(f, b, w, 14))
	GunParts.lofted(self, "Grip", rings, GunParts.walnut())
	var strap := PackedVector3Array()
	for p in _curve([[-0.004, 0.044], [-0.008, 0.032], [-0.019, 0.019], [-0.033, 0.001], [-0.045, -0.024],
			[-0.054, -0.051], [-0.0605, -0.075], [-0.063, -0.089], [-0.0615, -0.097]], 4):
		strap.append(_v3(p + Vector2(-0.0012, 0.0)))
	GunParts.sweep(self, "Backstrap", strap, 0.0045, 0.0022, brass, 8)
	# The butt: the straps meet under the grip.
	var butt := PackedVector3Array([_v3(Vector2(-0.026, -0.095)), _v3(Vector2(-0.044, -0.099)), _v3(Vector2(-0.061, -0.098))])
	GunParts.sweep(self, "Butt", butt, 0.0145, 0.0022, brass, 8)


## A ring round the z axis at forward `u`, centred at height `y` (and `x`), radii `rx` across and
## `ry` up.
static func _ring_z(u: float, y: float, rx: float, ry: float, sides: int, x := 0.0) -> PackedVector3Array:
	var r := PackedVector3Array()
	for k in sides:
		var a := TAU * k / sides
		r.append(Vector3(x + cos(a) * rx, y + sin(a) * ry, -u))
	return r


## A ring of the cylinder in its own space (axis z) at `z`: round, with the six flutes between the
## chambers cut `flute` deep (0 none, 1 full).
static func _fluted(z: float, radius: float, flute: float, sides: int) -> PackedVector3Array:
	var r := PackedVector3Array()
	for k in sides:
		var a := TAU * k / sides
		# Flutes sit between chambers (chambers at 0, 60, ...: flutes at 30, 90, ...).
		var d := absf(wrapf(a - deg_to_rad(30.0), -PI / 6.0, PI / 6.0))
		var cut := maxf(0.0, 1.0 - d / deg_to_rad(13.0))
		var rad := radius - 0.0034 * flute * sqrt(cut)
		r.append(Vector3(sin(a) * rad, cos(a) * rad, z))
	return r


## The point `t` (0..1) of the way along a polyline by length.
static func _along(line: PackedVector2Array, t: float) -> Vector2:
	var total := 0.0
	for i in line.size() - 1:
		total += line[i].distance_to(line[i + 1])
	var want := total * clampf(t, 0.0, 1.0)
	for i in line.size() - 1:
		var seg := line[i].distance_to(line[i + 1])
		if want <= seg or i == line.size() - 2:
			return line[i].lerp(line[i + 1], clampf(want / maxf(seg, 1e-6), 0.0, 1.0))
		want -= seg
	return line[line.size() - 1]


## A cross-section of the grip between a point on the front strap and one on the back: rounded
## (a superellipse), `w` either side of the middle.
static func _grip_ring(f: Vector2, b: Vector2, w: float, sides: int) -> PackedVector3Array:
	var mid := (f + b) * 0.5
	var half := (b - f) * 0.5
	var r := PackedVector3Array()
	for k in sides:
		var a := TAU * k / sides
		var c := cos(a)
		var s := sin(a)
		var cx := signf(c) * pow(absf(c), 0.7)
		var sx := signf(s) * pow(absf(s), 0.7)
		var p := mid + half * cx
		r.append(Vector3(sx * w, p.y, -p.x))
	return r


## Show what's in each chamber: brass rim (loaded), rim with a struck primer (spent), nothing (empty).
func show_chambers(chambers: Array[int]) -> void:
	for i in _rims.size():
		var c: int = chambers[i] if i < chambers.size() else RevolverState.Chamber.EMPTY
		_rims[i].visible = c != RevolverState.Chamber.EMPTY
		_primers[i].visible = c != RevolverState.Chamber.EMPTY
		_primers[i].scale = Vector3.ONE * (0.6 if c == RevolverState.Chamber.SPENT else 1.0)


## World position of a chamber's rear (where a case comes out of the gate).
func chamber_rear(i: int) -> Vector3:
	return _rims[i].global_position
