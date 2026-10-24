class_name ShotgunModel
extends Node3D
## A 12-bore side-by-side hammer gun with 20" barrels (a coach gun), built from parts in code:
## each in its own profile (GunParts.profile/turned/stroke; its side painting over them where there
## is one: GunParts.paint_gun), blued barrels with a rib and a brass bead, case-hardened action and
## lockplates, walnut stock with
## a pistol grip (as the Colt 1878 and Remington 1882 hammer doubles had: the hand holds it as it
## holds a revolver, the wrist straight; Sean, 2026-10-23, after the straight hand bent the wrist)
## and splinter forend. The barrels hinge open on the pin at the front of the action; the two hammers,
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
## The pistol grip: the right hand's (it holds it as RevolverModel's Grip is held).
var grip: Node3D
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
	var bore := GunParts.grid("bore", PixelArt.metal("bore", Color(0.04, 0.04, 0.05), 91))
	# The action in profile: the bar the barrels lie on and the standing breech the shells sit
	# against, rounded at the fences; a lockplate each side carrying a hammer; the tang behind.
	GunParts.profile(self, "Breech", _pts([[-0.106, -0.004], [-0.106, -0.019], [-0.099, -0.024], [-0.045, -0.024],
			[-0.03, -0.027], [-0.006, -0.027], [-0.002, -0.012], [-0.003, 0.012], [-0.01, 0.019], [-0.03, 0.0215],
			[-0.04, 0.021], [-0.042, 0.0], [-0.06, -0.003]]), 0.022, frame_mat, Vector3.ZERO, Vector3.ZERO, 0.003)
	for side in [1.0, -1.0]:
		GunParts.profile(self, "Lockplate%s" % ("R" if side > 0 else "L"), _pts([[-0.046, -0.02], [0.026, -0.02],
				[0.036, -0.012], [0.034, 0.004], [0.02, 0.01], [-0.046, 0.008]]), 0.0018, frame_mat,
				Vector3(0.0235 * side, 0, 0), Vector3.ZERO, 0.0008)
	GunParts.profile(self, "Tang", _pts([[-0.004, 0.019], [0.06, 0.009], [0.06, 0.013], [-0.004, 0.023]]), 0.007, frame_mat, Vector3.ZERO, Vector3.ZERO, 0.0015)

	# Barrels (thicker at the breech, a step at the chambers), rib, bead and forend: all hinge together.
	barrels = GunParts.pivot(self, "Barrels", HINGE)
	var mid_z := BREECH_Z - BARREL_LENGTH * 0.5
	var mz := BREECH_Z - BARREL_LENGTH
	for i in 2:
		var x: float = BARREL_X[i]
		GunParts.turned(barrels, "Barrel%d" % i, _pts([[0.0, BREECH_Z], [0.0118, BREECH_Z], [0.0118, BREECH_Z - 0.06],
				[0.0108, BREECH_Z - 0.2], [0.0105, mz + 0.002], [0.0095, mz], [0.0, mz]]), steel, 16, Vector3(x, BARREL_Y, 0))
		GunParts.tube(barrels, "Bore%d" % i, 0.0092, 0.002, Vector3(x, BARREL_Y, mz - 0.0005), bore, 8)
		# The shell head at the breech: brass rim and primer; the dark chamber shows when it's empty.
		GunParts.tube(barrels, "Chamber%d" % i, 0.0098, 0.002, Vector3(x, BARREL_Y, BREECH_Z + 0.0005), bore, 8)
		var head := GunParts.tube(barrels, "Head%d" % i, 0.0112, 0.003, Vector3(x, BARREL_Y, BREECH_Z + 0.0015), GunParts.brass(), 10)
		head.set_meta(&"own_paint", true)
		_heads.append(head)
		_primers.append(GunParts.tube(barrels, "Primer%d" % i, 0.0028, 0.002, Vector3(x, BARREL_Y, BREECH_Z + 0.0032), GunParts.grid("primer", PixelArt.metal("primer", Color(0.55, 0.42, 0.28), 93)), 6))
		var m := Marker3D.new()
		m.name = "Muzzle%d" % i
		m.position = Vector3(x, BARREL_Y, mz - 0.004)
		barrels.add_child(m)
		muzzles.append(m)
		var c := Marker3D.new()
		c.name = "ChamberPoint%d" % i
		c.position = Vector3(x, BARREL_Y + 0.01, BREECH_Z + 0.01)
		barrels.add_child(c)
		chamber_points.append(c)
	GunParts.profile(barrels, "Rib", _pts([[BREECH_Z - 0.008, BARREL_Y + 0.009], [mz + 0.004, BARREL_Y + 0.0085],
			[mz + 0.004, BARREL_Y + 0.0128], [BREECH_Z - 0.008, BARREL_Y + 0.0142]]), 0.004, steel, Vector3.ZERO, Vector3.ZERO, 0.0008)
	GunParts.box(barrels, "Underrib", Vector3(0.008, 0.006, BARREL_LENGTH - 0.14), Vector3(0, BARREL_Y - 0.012, mid_z - 0.06), steel)
	var bead := GunParts.tube(barrels, "Bead", 0.0022, 0.004, Vector3(0, BARREL_Y + 0.0155, mz + 0.008), GunParts.brass(), 6, Vector3.ZERO)
	bead.set_meta(&"own_paint", true)
	GunParts.box(barrels, "Lumps", Vector3(0.02, 0.018, 0.05), Vector3(0, BARREL_Y - 0.024, BREECH_Z - 0.03), steel)
	# The splinter forend: tapered to its tip, rounded under.
	GunParts.profile(barrels, "Forend", _pts([[0.005, 0.01], [0.005, -0.012], [-0.01, -0.017], [-0.12, -0.015],
			[-0.145, -0.006], [-0.145, 0.01]]), 0.018, wood, Vector3.ZERO, Vector3.ZERO, 0.005)
	GunParts.box(barrels, "ForendIron", Vector3(0.03, 0.006, 0.03), Vector3(0, BARREL_Y - 0.036, 0.0), frame_mat)

	# Hammers: on the lockplates, their bodies rising and the spurs sweeping back for the thumb.
	for i in 2:
		var x: float = 0.018 * (1.0 if i == 0 else -1.0)
		var h := GunParts.pivot(self, "Hammer%d" % i, Vector3(x, 0.0, -0.008))
		GunParts.profile(h, "Body", _pts([[-0.004, -0.004], [0.004, -0.004], [0.007, 0.014], [0.008, 0.024],
				[-0.003, 0.03], [-0.006, 0.012]]), 0.003, frame_mat, Vector3.ZERO, Vector3.ZERO, 0.0008)
		GunParts.profile(h, "Spur", _pts([[0.008, 0.024], [0.016, 0.031], [0.025, 0.032], [0.026, 0.037],
				[0.014, 0.039], [0.002, 0.036], [-0.003, 0.03]]), 0.004, frame_mat, Vector3.ZERO, Vector3.ZERO, 0.001)
		hammers.append(h)
	# The top lever on the tang swings right to open the gun.
	lever = GunParts.pivot(self, "Lever", Vector3(0, 0.023, -0.012))
	GunParts.profile(lever, "Blade", _pts([[0.0, -0.0025], [0.045, -0.0025], [0.05, 0.0], [0.045, 0.0025], [0.0, 0.0025]]), 0.005, frame_mat, Vector3.ZERO, Vector3.ZERO, 0.001)

	# Two triggers (front fires the right barrel) and the guard round them.
	for i in 2:
		var t := GunParts.pivot(self, "Trigger%d" % i, Vector3(0, -0.022, -0.052 + i * 0.02))
		GunParts.profile(t, "Blade", _pts([[-0.0025, 0.002], [0.0025, 0.002], [0.003, -0.008], [0.0055, -0.016],
				[0.004, -0.022], [0.0005, -0.021], [0.0015, -0.014], [-0.0005, -0.006]]), 0.0025, steel, Vector3.ZERO, Vector3.ZERO, 0.0006)
		triggers.append(t)
	GunParts.stroke(self, "GuardBottom", _pts([[-0.072, -0.022], [-0.07, -0.036], [-0.06, -0.046], [-0.03, -0.05],
			[-0.012, -0.046], [-0.002, -0.036], [0.004, -0.028]]), 0.004, 0.004, steel)

	# The stock in one profile: the wrist from the action, down into the pistol grip under it (as
	# the Colt 1878 and Remington 1882 hammer doubles had), the comb and butt dropping away below
	# the rib (about 4 cm at the comb, 6 at the heel) so the eye looks along it, the belly from the
	# grip back to the toe.
	var stock := GunParts.pivot(self, "Stock", Vector3(0, 0.0, 0.0))
	GunParts.profile(stock, "Wrist", _pts([[-0.004, 0.013], [0.06, 0.004], [0.11, -0.011], [0.345, -0.034], [0.35, -0.036],
			[0.35, -0.14], [0.13, -0.106], [0.092, -0.097], [0.084, -0.104], [0.07, -0.112], [0.055, -0.111],
			[0.04, -0.086], [0.025, -0.058], [0.012, -0.036], [0.004, -0.029], [-0.004, -0.024]]), 0.017, wood, Vector3.ZERO, Vector3.ZERO, 0.005)
	# The pistol grip's frame for the right hand, raked back (a negative turn about X takes its
	# butt towards +Z), and its steel cap.
	grip = GunParts.pivot(stock, "PistolGrip", Vector3(0, -0.026, 0.022))
	grip.rotation_degrees = Vector3(-30, 0, 0)
	GunParts.profile(grip, "Cap", _pts([[-0.014, -0.093], [0.022, -0.093], [0.022, -0.089], [-0.014, -0.089]]), 0.0155, steel, Vector3.ZERO, Vector3.ZERO, 0.001)
	butt = GunParts.pivot(stock, "ButtStock", Vector3.ZERO)
	GunParts.stroke(butt, "Buttplate", _pts([[0.351, -0.034], [0.355, -0.08], [0.351, -0.141]]), 0.006, 0.019, steel)
	if not GunParts.blender_meshes(self, "shotgun"):
		GunParts.paint_gun(self, "shotgun")


static func _pts(a: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Array in a:
		out.append(Vector2(p[0], p[1]))
	return out


## Show what's in each barrel: brass head (loaded), head with a struck primer (spent or dud),
## the dark chamber (empty).
func show_barrels(states: Array[int]) -> void:
	for i in _heads.size():
		var b: int = states[i] if i < states.size() else ShotgunState.Barrel.EMPTY
		_heads[i].visible = b != ShotgunState.Barrel.EMPTY
		_primers[i].visible = b != ShotgunState.Barrel.EMPTY
		_primers[i].scale = Vector3.ONE * (0.6 if b == ShotgunState.Barrel.SPENT or b == ShotgunState.Barrel.DUD else 1.0)
