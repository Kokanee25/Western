class_name RevolverModel
extends Node3D
## A Colt Single Action Army with a 7½" barrel, built from parts in code: blued barrel and
## cylinder, case-hardened frame, brass trigger guard, walnut grip. The hammer, trigger, cylinder,
## loading gate and ejector rod are separate moving parts; the chambers show brass when loaded.
## Local space: barrel along -Z, top up +Y, origin where the grip meets the frame.

const CHAMBER_RADIUS := 0.0135
const CYLINDER_AXIS := Vector3(0.0, 0.03, -0.034)
const CYLINDER_LENGTH := 0.042

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


func _build() -> void:
	var steel := GunParts.blued()
	var frame_mat := GunParts.case_hardened()
	# Frame: the body the cylinder sits in, with top strap and recoil shield.
	GunParts.box(self, "Frame", Vector3(0.026, 0.034, 0.062), Vector3(0, 0.012, -0.03), frame_mat)
	GunParts.box(self, "TopStrap", Vector3(0.02, 0.008, 0.07), Vector3(0, 0.055, -0.03), frame_mat)
	GunParts.box(self, "RecoilShield", Vector3(0.03, 0.05, 0.01), Vector3(0, 0.03, -0.008), frame_mat)
	GunParts.box(self, "FrameFront", Vector3(0.022, 0.05, 0.01), Vector3(0, 0.03, -0.06), frame_mat)
	GunParts.box(self, "RearSightNotch", Vector3(0.004, 0.003, 0.006), Vector3(0, 0.0605, 0.0), steel)
	# Barrel, ejector housing and front sight.
	var barrel_len := 0.19
	GunParts.tube(self, "Barrel", 0.0085, barrel_len, Vector3(0, 0.04, -0.065 - barrel_len * 0.5), steel, 10)
	GunParts.tube(self, "BarrelBore", 0.0058, 0.002, Vector3(0, 0.04, -0.065 - barrel_len - 0.0005), GunParts.grid("bore", PixelArt.metal("bore", Color(0.04, 0.04, 0.05), 91)), 8)
	GunParts.box(self, "FrontSight", Vector3(0.003, 0.007, 0.012), Vector3(0, 0.051, -0.065 - barrel_len + 0.008), steel)
	var housing_len := 0.14
	GunParts.tube(self, "EjectorHousing", 0.0055, housing_len, Vector3(0.0085, 0.028, -0.07 - housing_len * 0.5), steel, 8)
	ejector = GunParts.pivot(self, "Ejector", Vector3(0.0085, 0.028, -0.07 - housing_len))
	GunParts.box(ejector, "EjectorHead", Vector3(0.008, 0.008, 0.01), Vector3(0, 0, 0.0), steel)
	muzzle = Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0.04, -0.065 - barrel_len - 0.004)
	add_child(muzzle)

	# The cylinder: six chambers; turns about its own axis.
	cylinder = GunParts.pivot(self, "Cylinder", CYLINDER_AXIS)
	GunParts.tube(cylinder, "Body", 0.021, CYLINDER_LENGTH, Vector3.ZERO, steel, 12)
	for i in 6:
		var a := deg_to_rad(i * 60.0)
		var p := Vector3(sin(a) * CHAMBER_RADIUS, cos(a) * CHAMBER_RADIUS, 0.0)
		# Bolt notches between chambers, for the look.
		var notch_a := a + deg_to_rad(30.0)
		GunParts.box(cylinder, "Notch%d" % i, Vector3(0.003, 0.003, 0.006), Vector3(sin(notch_a) * 0.021, cos(notch_a) * 0.021, 0.0), GunParts.grid("bore", PixelArt.metal("bore", Color(0.04, 0.04, 0.05), 91)))
		var rim := GunParts.tube(cylinder, "Rim%d" % i, 0.0062, 0.002, p + Vector3(0, 0, CYLINDER_LENGTH * 0.5 + 0.001), GunParts.brass(), 8)
		var primer := GunParts.tube(cylinder, "Primer%d" % i, 0.0022, 0.0022, p + Vector3(0, 0, CYLINDER_LENGTH * 0.5 + 0.0015), GunParts.grid("primer", PixelArt.metal("primer", Color(0.55, 0.42, 0.28), 93)), 6)
		GunParts.tube(cylinder, "Mouth%d" % i, 0.0058, 0.002, p - Vector3(0, 0, CYLINDER_LENGTH * 0.5 + 0.0005), GunParts.grid("bore", PixelArt.metal("bore", Color(0.04, 0.04, 0.05), 91)), 8)
		_rims.append(rim)
		_primers.append(primer)

	# Loading gate on the right of the recoil shield, hinged at its bottom edge.
	gate = GunParts.pivot(self, "Gate", Vector3(0.0155, 0.018, -0.005))
	GunParts.box(gate, "Flap", Vector3(0.003, 0.018, 0.012), Vector3(0, 0.009, 0), frame_mat)
	gate_point = Marker3D.new()
	gate_point.name = "GatePoint"
	gate_point.position = Vector3(0.012, 0.037, 0.0)
	add_child(gate_point)

	# Hammer: pivots at the back of the frame; the spur is what your thumb pulls.
	hammer = GunParts.pivot(self, "Hammer", Vector3(0, 0.03, 0.004))
	GunParts.box(hammer, "Body", Vector3(0.008, 0.03, 0.01), Vector3(0, 0.018, 0.002), frame_mat, Vector3(-12, 0, 0))
	GunParts.box(hammer, "Spur", Vector3(0.012, 0.006, 0.016), Vector3(0, 0.033, 0.009), frame_mat, Vector3(-25, 0, 0))

	# Trigger and brass guard.
	trigger = GunParts.pivot(self, "Trigger", Vector3(0, -0.004, -0.018))
	GunParts.box(trigger, "Blade", Vector3(0.005, 0.022, 0.004), Vector3(0, -0.01, 0.002), steel, Vector3(15, 0, 0))
	var guard := GunParts.brass()
	GunParts.box(self, "GuardFront", Vector3(0.006, 0.026, 0.004), Vector3(0, -0.014, -0.036), guard, Vector3(-10, 0, 0))
	GunParts.box(self, "GuardBottom", Vector3(0.006, 0.004, 0.038), Vector3(0, -0.027, -0.018), guard)
	GunParts.box(self, "GuardBack", Vector3(0.006, 0.02, 0.004), Vector3(0, -0.018, 0.002), guard, Vector3(12, 0, 0))

	# Walnut grip, raked back, with the brass backstrap.
	var grip := GunParts.pivot(self, "Grip", Vector3(0, -0.004, 0.012))
	grip.rotation_degrees = Vector3(22, 0, 0)
	GunParts.box(grip, "Panels", Vector3(0.03, 0.085, 0.032), Vector3(0, -0.042, 0.004), GunParts.walnut())
	GunParts.box(grip, "Backstrap", Vector3(0.012, 0.085, 0.004), Vector3(0, -0.042, 0.022), guard)
	GunParts.box(grip, "Butt", Vector3(0.03, 0.006, 0.036), Vector3(0, -0.086, 0.004), guard)


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
