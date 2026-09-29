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
	var bore := GunParts.material("bore", PixelArt.metal("bore", Color(0.04, 0.04, 0.05), 91))
	# The action: the standing breech the shells sit against, the bar the barrels lie on, and a
	# lockplate each side carrying a hammer.
	GunParts.box(self, "Breech", Vector3(0.046, 0.042, 0.02), Vector3(0, 0.0, -0.03), frame_mat)
	GunParts.box(self, "Bar", Vector3(0.044, 0.02, 0.066), Vector3(0, -0.012, -0.073), frame_mat)
	for side in [1.0, -1.0]:
		GunParts.box(self, "Lockplate%s" % ("R" if side > 0 else "L"), Vector3(0.004, 0.032, 0.08), Vector3(0.024 * side, -0.004, -0.004), frame_mat)
	GunParts.box(self, "Tang", Vector3(0.016, 0.005, 0.07), Vector3(0, 0.019, 0.01), frame_mat)

	# Barrels, rib, bead and forend: all hinge together.
	barrels = GunParts.pivot(self, "Barrels", HINGE)
	var mid_z := BREECH_Z - BARREL_LENGTH * 0.5
	for i in 2:
		var x: float = BARREL_X[i]
		GunParts.tube(barrels, "Barrel%d" % i, BARREL_RADIUS, BARREL_LENGTH, Vector3(x, BARREL_Y, mid_z), steel, 10)
		GunParts.tube(barrels, "Bore%d" % i, 0.0092, 0.002, Vector3(x, BARREL_Y, BREECH_Z - BARREL_LENGTH - 0.0005), bore, 8)
		# The shell head at the breech: brass rim and primer; the dark chamber shows when it's empty.
		GunParts.tube(barrels, "Chamber%d" % i, 0.0098, 0.002, Vector3(x, BARREL_Y, BREECH_Z + 0.0005), bore, 8)
		_heads.append(GunParts.tube(barrels, "Head%d" % i, 0.0112, 0.003, Vector3(x, BARREL_Y, BREECH_Z + 0.0015), GunParts.brass(), 10))
		_primers.append(GunParts.tube(barrels, "Primer%d" % i, 0.0028, 0.002, Vector3(x, BARREL_Y, BREECH_Z + 0.0032), GunParts.material("primer", PixelArt.metal("primer", Color(0.55, 0.42, 0.28), 93)), 6))
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
	GunParts.box(barrels, "Rib", Vector3(0.008, 0.005, BARREL_LENGTH - 0.02), Vector3(0, BARREL_Y + 0.011, mid_z - 0.01), steel)
	GunParts.box(barrels, "Underrib", Vector3(0.008, 0.006, BARREL_LENGTH - 0.14), Vector3(0, BARREL_Y - 0.012, mid_z - 0.06), steel)
	GunParts.tube(barrels, "Bead", 0.0022, 0.004, Vector3(0, BARREL_Y + 0.0155, BREECH_Z - BARREL_LENGTH + 0.008), GunParts.brass(), 6, Vector3.ZERO)
	GunParts.box(barrels, "Lumps", Vector3(0.02, 0.018, 0.05), Vector3(0, BARREL_Y - 0.024, BREECH_Z - 0.03), steel)
	GunParts.box(barrels, "Forend", Vector3(0.036, 0.024, 0.15), Vector3(0, BARREL_Y - 0.026, -0.07), wood)
	GunParts.box(barrels, "ForendIron", Vector3(0.03, 0.006, 0.03), Vector3(0, BARREL_Y - 0.036, 0.0), frame_mat)

	# Hammers: on the lockplates, leaning forward onto the strikers; the spurs are what the thumb pulls.
	for i in 2:
		var x: float = 0.018 * (1.0 if i == 0 else -1.0)
		var h := GunParts.pivot(self, "Hammer%d" % i, Vector3(x, 0.0, -0.008))
		GunParts.box(h, "Body", Vector3(0.006, 0.03, 0.01), Vector3(0, 0.014, -0.006), frame_mat, Vector3(-28, 0, 0))
		GunParts.box(h, "Spur", Vector3(0.008, 0.006, 0.016), Vector3(0, 0.03, 0.002), frame_mat, Vector3(-10, 0, 0))
		hammers.append(h)
	# The top lever on the tang swings right to open the gun.
	lever = GunParts.pivot(self, "Lever", Vector3(0, 0.023, -0.012))
	GunParts.box(lever, "Blade", Vector3(0.01, 0.005, 0.045), Vector3(0, 0, 0.02), frame_mat)

	# Two triggers (front fires the right barrel) and the guard.
	for i in 2:
		var t := GunParts.pivot(self, "Trigger%d" % i, Vector3(0, -0.022, -0.052 + i * 0.02))
		GunParts.box(t, "Blade", Vector3(0.005, 0.022, 0.004), Vector3(0, -0.011, 0.002), steel, Vector3(15, 0, 0))
		triggers.append(t)
	GunParts.box(self, "GuardBottom", Vector3(0.008, 0.004, 0.07), Vector3(0, -0.047, -0.035), steel)
	GunParts.box(self, "GuardFront", Vector3(0.008, 0.026, 0.004), Vector3(0, -0.034, -0.07), steel, Vector3(-10, 0, 0))
	GunParts.box(self, "GuardBack", Vector3(0.008, 0.022, 0.004), Vector3(0, -0.036, 0.0), steel, Vector3(20, 0, 0))

	# The stock: a straight hand at the wrist, then the comb and butt dropping away below the line
	# of the rib (about 4 cm at the comb, 6 at the heel), so the eye looks along the rib.
	var stock := GunParts.pivot(self, "Stock", Vector3(0, 0.0, 0.0))
	GunParts.box(stock, "Wrist", Vector3(0.03, 0.034, 0.13), Vector3(0, -0.014, 0.058), wood, Vector3(-9, 0, 0))
	butt = GunParts.pivot(stock, "ButtStock", Vector3.ZERO)
	GunParts.box(butt, "Butt", Vector3(0.04, 0.1, 0.24), Vector3(0, -0.078, 0.23), wood, Vector3(-6, 0, 0))
	GunParts.box(butt, "Comb", Vector3(0.034, 0.02, 0.2), Vector3(0, -0.032, 0.21), wood, Vector3(-6, 0, 0))
	GunParts.box(butt, "Buttplate", Vector3(0.042, 0.106, 0.006), Vector3(0, -0.094, 0.35), steel, Vector3(-6, 0, 0))


## Show what's in each barrel: brass head (loaded), head with a struck primer (spent or dud),
## the dark chamber (empty).
func show_barrels(states: Array[int]) -> void:
	for i in _heads.size():
		var b: int = states[i] if i < states.size() else ShotgunState.Barrel.EMPTY
		_heads[i].visible = b != ShotgunState.Barrel.EMPTY
		_primers[i].visible = b != ShotgunState.Barrel.EMPTY
		_primers[i].scale = Vector3.ONE * (0.6 if b == ShotgunState.Barrel.SPENT or b == ShotgunState.Barrel.DUD else 1.0)
