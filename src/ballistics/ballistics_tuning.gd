class_name BallisticsTuning
extends Resource
## How hard materials are to shoot through: energy a bullet loses per centimetre of material.
## A .45 Colt black-powder round carries ~475 J and goes through roughly 10–12 cm of pine.

## wood id -> joules per cm
@export var resistance_by_wood := {
	&"weathered_pine": 42.0, &"painted_ochre": 42.0, &"painted_rust": 42.0, &"sign": 42.0,
	&"floor": 48.0, &"framing": 55.0, &"dark_trim": 70.0, &"glass": 8.0,
	&"iron": 4000.0,  # a safe's plate: a ball flattens on it
}
@export var default_resistance := 120.0
## Bullets slower than this are spent and drop.
@export var min_speed := 40.0
@export var max_age := 3.0
@export var gravity := 9.8
## Share of the bullet's momentum pushed into loose objects it hits.
@export var impulse_transfer := 0.6
## A bullet passing this close to someone's head is a near miss (they hear it crack past).
@export var near_miss_distance := 2.5
@export_group("Air")
## Where the town is and how warm it is: the air's thinner high up and when it's hot (less drag),
## and sound is faster in warm air. Sea level and 15 °C until Salt Creek's place is settled.
@export var elevation_m := 0.0
@export var air_temperature_c := 15.0
## Drag slows a projectile by 0.5·ρ·Cd·A·v²/m, and Cd changes with its speed against the speed of
## sound (Mach). A round ball (buckshot, a ball, a fragment) follows a sphere's curve: its drag
## nearly doubles as it nears the speed of sound. A conical bullet follows the G1 standard
## projectile's curve times its form factor (heavier blunter bullets more). [Mach, Cd] pairs.
@export var sphere_drag := PackedVector2Array([Vector2(0.0, 0.47), Vector2(0.4, 0.48), Vector2(0.5, 0.49),
		Vector2(0.6, 0.52), Vector2(0.7, 0.57), Vector2(0.8, 0.64), Vector2(0.9, 0.74), Vector2(1.0, 0.86),
		Vector2(1.1, 0.94), Vector2(1.2, 0.98), Vector2(1.5, 1.01), Vector2(2.0, 1.0)])
@export var g1_drag := PackedVector2Array([Vector2(0.0, 0.2629), Vector2(0.3, 0.2214), Vector2(0.5, 0.2032),
		Vector2(0.55, 0.2020), Vector2(0.6, 0.2034), Vector2(0.7, 0.2165), Vector2(0.75, 0.2313),
		Vector2(0.8, 0.2546), Vector2(0.85, 0.2901), Vector2(0.9, 0.3415), Vector2(0.95, 0.4084),
		Vector2(1.0, 0.4805), Vector2(1.05, 0.5427), Vector2(1.1, 0.5883), Vector2(1.2, 0.6393),
		Vector2(1.3, 0.6589), Vector2(1.4, 0.6625), Vector2(1.6, 0.6481), Vector2(2.0, 0.6044)])


## How thick the air is (kg/m³): the standard atmosphere's pressure at `elevation_m`, at the
## temperature given.
func air_density() -> float:
	var pressure := 101325.0 * pow(maxf(1.0 - 2.25577e-5 * elevation_m, 0.01), 5.25588)
	return pressure / (287.05 * (air_temperature_c + 273.15))


## The speed of sound in this air (m/s).
func speed_of_sound() -> float:
	return 20.05 * sqrt(air_temperature_c + 273.15)


## The drag coefficient at `speed`: a round ball's (`form` 0) or a conical bullet's (G1 × `form`).
func drag_cd(speed: float, form: float) -> float:
	var mach := speed / speed_of_sound()
	return form * _on_curve(g1_drag, mach) if form > 0.0 else _on_curve(sphere_drag, mach)


static func _on_curve(table: PackedVector2Array, x: float) -> float:
	if x <= table[0].x:
		return table[0].y
	for i in range(1, table.size()):
		if x <= table[i].x:
			return lerpf(table[i - 1].y, table[i].y, (x - table[i - 1].x) / (table[i].x - table[i - 1].x))
	return table[table.size() - 1].y

@export_group("Ricochets")
## The steepest a ball can strike each kind of surface and still glance off (degrees between its
## path and the surface). Lead is soft: it skips off dirt and stone at a shallow angle, and digs
## into wood unless it barely touches. A surface's kind: its `surface` meta, else stone and wood
## members by their wood, else level ground or (anything upright) wood.
@export var ricochet_angle := {&"ground": 14.0, &"stone": 22.0, &"metal": 28.0, &"wood": 6.0}
## The speed it keeps glancing off: at a grazing touch, and at the steepest angle that glances.
@export var ricochet_keep_speed := Vector2(0.8, 0.5)
## It leaves flatter than it came in (this share of the angle), thrown sideways up to this many
## degrees, flattened (diameter ×) and tumbling. Most a ball glances off before it's spent.
@export var ricochet_exit_share := 0.5
@export var ricochet_scatter := 6.0
@export var ricochet_flatten := 1.4
@export var max_ricochets := 3
