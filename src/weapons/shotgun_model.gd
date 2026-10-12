class_name ShotgunModel
extends Node3D
## A 12-bore side-by-side hammer gun with 20" barrels (a coach gun), built from parts in code:
## blued barrels with a rib and a brass bead, case-hardened action and lockplates, walnut stock and
## splinter forend. The barrels hinge open on the pin at the front of the action; the two hammers,
## two triggers and the top lever are separate moving parts; brass shell heads show in the
## chambers when it's open.
## Local space: barrels along -Z, top up +Y, origin at the wrist of the stock (where the right hand
## grips), like RevolverModel.

const BARREL_LENGTH := 0.51
const BARREL_RADIUS := 0.0105
## Barrel centres left and right of the rib (barrel 0 is the right).
const BARREL_X := [0.0107, -0.0107]
## The hinge pin, and where the barrels' breech ends sit in the hinge's space.
const HINGE := Vector3(0.0, -0.012, -0.1)
const BREECH_Z := 0.058
const BARREL_Y := 0.024

var barrels: Node3D
var hammers: Array[Node3D] = []
var triggers: Array[Node3D] = []
var lever: Node3D
## The comb and butt: under your cheek and against your shoulder when it's shouldered, so the
## viewmodel hides them then (you can't see them; drawn, they'd fill the bottom of the view).
var butt: Node3D
var muzzles: Array[Marker3D] = []
## Where each chamber's mouth is (a shell comes out and goes in here).
var chamber_points: Array[Marker3D] = []

var _heads: Array[MeshInstance3D] = []
var _primers: Array[MeshInstance3D] = []


func _ready() -> void:
	_build()


func _build() -> void:
	var steel := GunParts.blued()
	var frame_mat := GunParts.case_hardened()
	var wood := GunParts.walnut()
	var brass := GunParts.brass()
	var bore := GunParts.grid("bore", PixelArt.metal("bore", Color(0.04, 0.04, 0.05), 91))
	# The action from its side: the bar under the barrels to the hinge, the standing breech the
	# shells sit against, the top tang running back over the wrist and the trigger plate under it.
	GunParts.slab(self, "Action", _pts([[0.112, -0.004], [0.112, -0.016], [0.104, -0.023], [0.075, -0.026],
			[0.052, -0.027], [0.040, -0.031], [0.010, -0.033], [-0.030, -0.035], [-0.075, -0.037],
			[-0.078, -0.032], [-0.035, -0.027], [-0.012, -0.019], [-0.016, 0.006], [-0.030, 0.014],
			[-0.072, 0.017], [-0.074, 0.021], [-0.026, 0.023], [0.024, 0.028], [0.036, 0.033],
			[0.0425, 0.033], [0.0425, -0.001], [0.06, -0.004]]), 0.0225, frame_mat, 0.002)
	# A back-action lockplate on each side, the hammers' bearing on it.
	for side in [1.0, -1.0]:
		GunParts.slab(self, "Lockplate%s" % ("R" if side > 0 else "L"), _pts([[0.038, -0.018], [0.040, 0.008],
				[0.030, 0.016], [-0.012, 0.016], [-0.042, 0.012], [-0.054, 0.004], [-0.056, -0.006],
				[-0.046, -0.014], [-0.010, -0.020]]), 0.0012, frame_mat, 0.0006, 0.0236 * side)
		GunParts.tube(self, "LockScrew%s" % ("R" if side > 0 else "L"), 0.0024, 0.002, Vector3(0.0252 * side, 0.002, 0.03),
				steel, 8, Vector3(0, 0, 90))

	# Barrels, ribs, bead, lumps and forend: all hinge together.
	barrels = GunParts.pivot(self, "Barrels", HINGE)
	for i in 2:
		var x: float = BARREL_X[i]
		var rings := []
		for st in [[BREECH_Z, BARREL_RADIUS + 0.0016], [BREECH_Z - 0.06, BARREL_RADIUS + 0.0012],
				[BREECH_Z - 0.2, BARREL_RADIUS + 0.0004], [BREECH_Z - BARREL_LENGTH + 0.02, BARREL_RADIUS - 0.0004],
				[BREECH_Z - BARREL_LENGTH + 0.004, BARREL_RADIUS - 0.0002], [BREECH_Z - BARREL_LENGTH, BARREL_RADIUS - 0.0012]]:
			rings.append(_ring(-st[0], x, BARREL_Y, st[1], 16))
		GunParts.lofted(barrels, "Barrel%d" % i, rings, steel)
		GunParts.tube(barrels, "Bore%d" % i, 0.0092, 0.002, Vector3(x, BARREL_Y, BREECH_Z - BARREL_LENGTH - 0.0005), bore, 10)
		# The shell head at the breech: brass rim and primer; the dark chamber shows when it's empty.
		GunParts.tube(barrels, "Chamber%d" % i, 0.0098, 0.002, Vector3(x, BARREL_Y, BREECH_Z + 0.0005), bore, 10)
		_heads.append(GunParts.tube(barrels, "Head%d" % i, 0.0112, 0.003, Vector3(x, BARREL_Y, BREECH_Z + 0.0015), brass, 12))
		_primers.append(GunParts.tube(barrels, "Primer%d" % i, 0.0028, 0.002, Vector3(x, BARREL_Y, BREECH_Z + 0.0032), GunParts.grid("primer", PixelArt.metal("primer", Color(0.55, 0.42, 0.28), 93)), 6))
		var m := Marker3D.new()
		m.name = "Muzzle%d" % i
		m.position = Vector3(x, BARREL_Y, BREECH_Z - BARREL_LENGTH - 0.004)
		barrels.add_child(m)
		muzzles.append(m)
		var c := Marker3D.new()
		c.name = "ChamberPoint%d" % i
		c.position = Vector3(x, BARREL_Y + 0.01, BREECH_Z + 0.01)
		barrels.add_child(c)
		chamber_points.append(c)
	# The top rib in the valley between the barrels, the bead at its front; the rib under them.
	var top := BARREL_Y + 0.0075
	GunParts.slab(barrels, "Rib", _pts([[-BREECH_Z + 0.002, top], [-BREECH_Z + BARREL_LENGTH - 0.006, top - 0.002],
			[-BREECH_Z + BARREL_LENGTH - 0.006, top + 0.0045], [-BREECH_Z + 0.002, top + 0.0065]]), 0.0042, steel, 0.0008)
	GunParts.tube(barrels, "Bead", 0.0024, 0.004, Vector3(0, top + 0.0068, BREECH_Z - BARREL_LENGTH + 0.009), brass, 8, Vector3.ZERO)
	var under := BARREL_Y - 0.0075
	GunParts.slab(barrels, "Underrib", _pts([[-BREECH_Z + 0.07, under], [-BREECH_Z + BARREL_LENGTH - 0.01, under + 0.001],
			[-BREECH_Z + BARREL_LENGTH - 0.01, under - 0.0045], [-BREECH_Z + 0.07, under - 0.0065]]), 0.0042, steel, 0.0008)
	# The lumps that lock into the bar, under the breech.
	GunParts.slab(barrels, "Lumps", _pts([[-BREECH_Z, BARREL_Y - 0.008], [-BREECH_Z + 0.062, BARREL_Y - 0.008],
			[-BREECH_Z + 0.062, BARREL_Y - 0.018], [-BREECH_Z + 0.02, BARREL_Y - 0.03], [-BREECH_Z, BARREL_Y - 0.03]]),
			0.011, steel, 0.0012)
	# The splinter forend: walnut, rounded under, tapering to a schnabel tip, its iron behind.
	var fe := []
	for st in [[0.004, 0.015, 0.0105], [-0.006, 0.0185, 0.0135], [-0.06, 0.019, 0.014], [-0.12, 0.0175, 0.013],
			[-0.145, 0.015, 0.0115], [-0.152, 0.011, 0.008]]:
		fe.append(_ring(-st[0], 0.0, BARREL_Y - 0.021, st[1], 14, st[2]))
	GunParts.lofted(barrels, "Forend", fe, wood)
	GunParts.slab(barrels, "ForendIron", _pts([[-0.012, BARREL_Y - 0.031], [0.006, BARREL_Y - 0.032],
			[0.012, BARREL_Y - 0.026], [0.004, BARREL_Y - 0.022], [-0.012, BARREL_Y - 0.024]]), 0.0145, frame_mat, 0.0012)

	# Hammers: on the lockplates, a thick body rising from the tumbler to a nose that leans forward
	# onto the striker, and a spur curling back where the thumb pulls it.
	for i in 2:
		var x: float = 0.0205 * (1.0 if i == 0 else -1.0)
		var h := GunParts.pivot(self, "Hammer%d" % i, Vector3(x, 0.0, -0.008))
		GunParts.slab(h, "Body", _pts([[0.005, -0.006], [0.008, 0.004], [0.014, 0.014], [0.024, 0.021],
				[0.034, 0.025], [0.036, 0.029], [0.030, 0.031], [0.020, 0.029], [0.010, 0.027],
				[0.002, 0.031], [-0.006, 0.037], [-0.013, 0.041], [-0.0165, 0.038], [-0.011, 0.032],
				[-0.006, 0.024], [-0.006, 0.010], [-0.006, -0.004], [0.0, -0.008]]), 0.0033, frame_mat, 0.0009)
		hammers.append(h)
	# The top lever on the tang swings right to open the gun.
	lever = GunParts.pivot(self, "Lever", Vector3(0, 0.023, -0.012))
	GunParts.slab(lever, "Blade", _pts([[0.004, 0.0], [-0.03, 0.0005], [-0.042, 0.002], [-0.046, 0.0045],
			[-0.03, 0.0045], [0.004, 0.0035]]), 0.0055, frame_mat, 0.0008)

	# Two triggers (front fires the right barrel) and the bow of the guard.
	for i in 2:
		var t := GunParts.pivot(self, "Trigger%d" % i, Vector3(0, -0.022, -0.052 + i * 0.02))
		GunParts.slab(t, "Blade", _pts([[0.0025, 0.004], [0.0035, -0.008], [0.0015, -0.016], [-0.002, -0.022],
				[-0.0055, -0.024], [-0.0045, -0.019], [-0.0018, -0.012], [-0.0012, -0.003], [-0.0025, 0.004]]),
				0.0022, steel, 0.0006)
		triggers.append(t)
	var bow := PackedVector3Array()
	for p in [[0.078, -0.027], [0.074, -0.04], [0.062, -0.05], [0.04, -0.054], [0.012, -0.052],
			[-0.006, -0.046], [-0.014, -0.036]]:
		bow.append(Vector3(0.0, p[1], -p[0]))
	GunParts.sweep(self, "Guard", bow, 0.0045, 0.0022, steel, 8)

	# The stock from its side: a straight hand at the wrist, then the comb and butt dropping away
	# below the rib (about 4 cm at the comb, 6 at the heel), so the eye looks along the rib.
	var stock := GunParts.pivot(self, "Stock", Vector3.ZERO)
	var wr := []
	for st in [[-0.01, -0.006, 0.0215, 0.016], [0.03, -0.012, 0.0185, 0.0148], [0.08, -0.018, 0.0175, 0.0145],
			[0.11, -0.024, 0.019, 0.016]]:
		wr.append(_ring(-st[0], 0.0, st[1], st[3], 14, st[2]))
	GunParts.lofted(stock, "Wrist", wr, wood)
	butt = GunParts.pivot(stock, "ButtStock", Vector3.ZERO)
	# The butt as rings from the wrist back to the plate: top (comb) and bottom (toe) lines.
	var br := []
	for st in [[0.105, -0.010, -0.040, 0.017], [0.14, -0.022, -0.068, 0.0195], [0.2, -0.032, -0.106, 0.021],
			[0.28, -0.042, -0.136, 0.0215], [0.348, -0.050, -0.158, 0.021], [0.355, -0.051, -0.160, 0.0195]]:
		var mid: float = (st[1] + st[2]) * 0.5
		var half: float = (st[1] - st[2]) * 0.5
		br.append(_ring(-st[0], 0.0, mid, st[3], 16, half))
	GunParts.lofted(butt, "Butt", br, wood)
	GunParts.slab(butt, "Buttplate", _pts([[-0.355, -0.049], [-0.36, -0.05], [-0.362, -0.162], [-0.357, -0.161]]),
			0.0205, steel, 0.0008)


static func _pts(a: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in a:
		out.append(Vector2(p[0], p[1]))
	return out


## A ring round the z axis at forward `u` (z = -u), centred at (`x`, `y`), `rx` across and `ry` up
## (`ry` < 0: round).
static func _ring(u: float, x: float, y: float, rx: float, sides: int, ry := -1.0) -> PackedVector3Array:
	var r := PackedVector3Array()
	var h := rx if ry < 0.0 else ry
	for k in sides:
		var a := TAU * k / sides
		r.append(Vector3(x + cos(a) * rx, y + sin(a) * h, -u))
	return r


## Show what's in each barrel: brass head (loaded), head with a struck primer (spent or dud),
## the dark chamber (empty).
func show_barrels(states: Array[int]) -> void:
	for i in _heads.size():
		var b: int = states[i] if i < states.size() else ShotgunState.Barrel.EMPTY
		_heads[i].visible = b != ShotgunState.Barrel.EMPTY
		_primers[i].visible = b != ShotgunState.Barrel.EMPTY
		_primers[i].scale = Vector3.ONE * (0.6 if b == ShotgunState.Barrel.SPENT or b == ShotgunState.Barrel.DUD else 1.0)
