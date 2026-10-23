class_name RevolverModel
extends Node3D
## A Colt Single Action Army with a 7½" barrel, built from parts in code, each in its own profile
## (GunParts.profile/turned/stroke: docs/briefs/gun-remake.md): blued barrel and cylinder,
## case-hardened frame, brass trigger guard and backstrap, walnut grip; its side painting laid over
## them where there is one (GunParts.paint_gun). The hammer, trigger, cylinder,
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
	var guard := GunParts.brass()
	var bore := GunParts.grid("bore", PixelArt.metal("bore", Color(0.04, 0.04, 0.05), 91))
	# The frame in profile (the gun's (z, y), extruded across it): under and in front of the
	# cylinder, the top strap over it, the recoil shield behind it (rounder and wider, rising to the
	# hammer), with the cylinder's window between.
	GunParts.profile(self, "Frame", _pts([[-0.062, 0.013], [-0.062, 0.004], [-0.058, -0.003], [-0.05, -0.006],
			[-0.014, -0.006], [-0.004, -0.004], [0.003, 0.001], [0.004, 0.013]]), 0.013, frame_mat)
	GunParts.profile(self, "FrameFront", _pts([[-0.0625, 0.012], [-0.0625, 0.053], [-0.055, 0.053], [-0.055, 0.012]]), 0.011, frame_mat)
	GunParts.profile(self, "TopStrap", _pts([[-0.0625, 0.051], [-0.0625, 0.057], [-0.045, 0.0595], [-0.004, 0.0595],
			[0.004, 0.0565], [0.004, 0.051]]), 0.0095, frame_mat)
	GunParts.profile(self, "RecoilShield", _pts([[-0.0135, 0.002], [-0.0135, 0.056], [-0.004, 0.058], [0.003, 0.055],
			[0.008, 0.045], [0.009, 0.03], [0.007, 0.014], [0.003, 0.003]]), 0.0165, frame_mat)
	GunParts.profile(self, "RearSightNotch", _pts([[-0.004, 0.0595], [0.003, 0.0595], [0.003, 0.061], [-0.004, 0.061]]), 0.002, steel)
	# Barrel (crowned at the muzzle, a shoulder at the frame), ejector housing along its right, the
	# front sight's blade.
	var barrel_len := 0.19
	var mz := -0.065 - barrel_len
	GunParts.turned(self, "Barrel", _pts([[0.0, mz], [0.0072, mz], [0.0085, mz + 0.0015], [0.0085, -0.07],
			[0.0095, -0.066], [0.0095, -0.061], [0.0, -0.061]]), steel, 16, Vector3(0, 0.04, 0))
	var b := GunParts.tube(self, "BarrelBore", 0.0058, 0.002, Vector3(0, 0.04, mz - 0.0005), bore, 8)
	b.set_meta(&"own_paint", true)
	GunParts.profile(self, "FrontSight", _pts([[mz + 0.004, 0.047], [mz + 0.016, 0.047], [mz + 0.013, 0.0535],
			[mz + 0.007, 0.0535]]), 0.0015, steel, Vector3.ZERO, Vector3.ZERO, 0.0004)
	var housing_len := 0.14
	GunParts.turned(self, "EjectorHousing", _pts([[0.0, -0.07 - housing_len], [0.0042, -0.07 - housing_len],
			[0.0052, -0.068 - housing_len], [0.0052, -0.075], [0.006, -0.07], [0.0, -0.07]]), steel, 12, Vector3(0.0085, 0.028, 0))
	ejector = GunParts.pivot(self, "Ejector", Vector3(0.0085, 0.028, -0.07 - housing_len))
	GunParts.turned(ejector, "EjectorHead", _pts([[0.0, -0.005], [0.0045, -0.005], [0.0045, 0.004], [0.0, 0.004]]), steel, 10)
	muzzle = Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0.04, mz - 0.004)
	add_child(muzzle)

	# The cylinder: six chambers; turns about its own axis. Its ends chamfered.
	cylinder = GunParts.pivot(self, "Cylinder", CYLINDER_AXIS)
	var h := CYLINDER_LENGTH * 0.5
	GunParts.turned(cylinder, "Body", _pts([[0.0, -h], [0.019, -h], [0.021, -h + 0.002], [0.021, h - 0.002],
			[0.0195, h], [0.0, h]]), steel, 24)
	for i in 6:
		var a := deg_to_rad(i * 60.0)
		var p := Vector3(sin(a) * CHAMBER_RADIUS, cos(a) * CHAMBER_RADIUS, 0.0)
		# Bolt notches between chambers.
		var notch_a := a + deg_to_rad(30.0)
		var notch := GunParts.box(cylinder, "Notch%d" % i, Vector3(0.003, 0.003, 0.006), Vector3(sin(notch_a) * 0.0205, cos(notch_a) * 0.0205, 0.004), bore)
		notch.set_meta(&"own_paint", true)
		var rim := GunParts.tube(cylinder, "Rim%d" % i, 0.0062, 0.002, p + Vector3(0, 0, CYLINDER_LENGTH * 0.5 + 0.001), guard, 8)
		rim.set_meta(&"own_paint", true)
		var primer := GunParts.tube(cylinder, "Primer%d" % i, 0.0022, 0.0022, p + Vector3(0, 0, CYLINDER_LENGTH * 0.5 + 0.0015), GunParts.grid("primer", PixelArt.metal("primer", Color(0.55, 0.42, 0.28), 93)), 6)
		GunParts.tube(cylinder, "Mouth%d" % i, 0.0058, 0.002, p - Vector3(0, 0, CYLINDER_LENGTH * 0.5 + 0.0005), bore, 8)
		_rims.append(rim)
		_primers.append(primer)

	# Loading gate on the right of the recoil shield, hinged at its bottom edge.
	gate = GunParts.pivot(self, "Gate", Vector3(0.0165, 0.018, -0.005))
	GunParts.profile(gate, "Flap", _pts([[-0.006, 0.0], [0.006, 0.0], [0.0065, 0.017], [-0.0065, 0.019]]), 0.0012, frame_mat, Vector3.ZERO, Vector3.ZERO, 0.0004)
	gate_point = Marker3D.new()
	gate_point.name = "GatePoint"
	gate_point.position = Vector3(0.012, 0.037, 0.0)
	add_child(gate_point)

	# Hammer: pivots at the back of the frame, its body rising behind the shield and the spur
	# sweeping back over the grip (what your thumb pulls).
	hammer = GunParts.pivot(self, "Hammer", Vector3(0, 0.03, 0.004))
	GunParts.profile(hammer, "Body", _pts([[-0.004, -0.004], [0.005, -0.004], [0.007, 0.012], [0.009, 0.022],
			[-0.001, 0.03], [-0.004, 0.012]]), 0.0045, frame_mat)
	GunParts.profile(hammer, "Spur", _pts([[0.009, 0.022], [0.017, 0.029], [0.026, 0.031], [0.027, 0.036],
			[0.016, 0.0375], [0.004, 0.035], [-0.001, 0.03]]), 0.0055, frame_mat)

	# Trigger (a curved blade) and the brass guard round it.
	trigger = GunParts.pivot(self, "Trigger", Vector3(0, -0.004, -0.018))
	GunParts.profile(trigger, "Blade", _pts([[-0.0025, 0.002], [0.0025, 0.002], [0.003, -0.008], [0.0055, -0.016],
			[0.004, -0.022], [0.0005, -0.021], [0.0015, -0.014], [-0.0005, -0.006]]), 0.0025, steel, Vector3.ZERO, Vector3.ZERO, 0.0006)
	GunParts.stroke(self, "Guard", _pts([[-0.04, -0.005], [-0.042, -0.016], [-0.036, -0.026], [-0.022, -0.029],
			[-0.009, -0.026], [-0.002, -0.016], [0.0, -0.005]]), 0.004, 0.0032, guard)

	# Walnut grip in the Colt's plough-handle shape, raked back (its butt behind the frame: a turn
	# about X takes -Y towards +Z when negative), with the brass backstrap round its back and butt.
	var grip := GunParts.pivot(self, "Grip", Vector3(0, -0.004, 0.012))
	grip.rotation_degrees = Vector3(-22, 0, 0)
	GunParts.profile(grip, "Panels", _pts([[-0.012, 0.002], [-0.0135, -0.03], [-0.0115, -0.06], [-0.006, -0.08],
			[0.004, -0.086], [0.014, -0.083], [0.0185, -0.06], [0.0205, -0.03], [0.0195, -0.004], [0.017, 0.012],
			[0.012, 0.02], [0.004, 0.012]]), 0.016, GunParts.walnut())
	# The backstrap rises behind the hammer to the top strap, as on the Colt.
	GunParts.stroke(grip, "Backstrap", _pts([[0.006, 0.034], [0.014, 0.026], [0.0195, 0.012], [0.0215, -0.004],
			[0.022, -0.03], [0.0205, -0.06], [0.016, -0.084]]), 0.004, 0.0065, guard)
	GunParts.stroke(grip, "Butt", _pts([[0.016, -0.084], [0.006, -0.0885], [-0.004, -0.087]]), 0.003, 0.0065, guard)
	GunParts.paint_gun(self, "revolver")


static func _pts(a: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Array in a:
		out.append(Vector2(p[0], p[1]))
	return out


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
