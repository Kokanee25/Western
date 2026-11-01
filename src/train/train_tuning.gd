class_name TrainTuning
extends Resource
## The train's dials (docs/briefs/train.md; the train lab, experiments/train_lab/). Every number
## here is PROPOSED until Sean has played it (issue #543): the feel dials he sets are the start
## (0 to 25 km/h), the top speed and the stopping distance from 30 km/h. Values: config/train.tres.
##
## The engine is an 1882 narrow-gauge (3 ft) 2-8-0 Consolidation and tender, as the Denver & Rio
## Grande's class 70 (later C-16): ~16,000 lbf of rated tractive effort (~71 kN), ~25 t on the
## drivers, 37 in drivers. Sources for the numbers are in the brief's "Numbers and where they're
## from": the Davis equation (W. J. Davis, General Electric Review, 1926; the form in AREMA's
## Manual for Railway Engineering), curve resistance at ~0.8 lb/ton per degree of curve, adhesion
## of 0.2-0.3 for dry rail.

@export_group("The engine")
## Rated starting tractive effort, N (the class's 16,000 lbf is ~71 kN; at full regulator and full
## cutoff, before adhesion caps it).
@export var tractive_effort := 71000.0
## Weight on the drivers, kg (the 2-8-0's eight coupled wheels; the pony truck and tender carry the rest).
@export var adhesive_mass := 25000.0
## Rail adhesion (dry rail ~0.25, sanded ~0.3, wet ~0.15). The force the drivers can put down
## before they slip: adhesion x weight on drivers x g.
@export var adhesion := 0.22
## How the steam effort falls with speed: effort x (1 - v / effort_fade_speed) before the power
## cap. Piston speed: the cylinders fill less each stroke as he runs faster. m/s.
@export var effort_fade_speed := 12.5
## The boiler's power at the drawbar, W: the effort can't be more than power / speed.
@export var power := 260000.0
## How fast the regulator (the throttle) follows the engineer's hand: full open from shut, seconds.
## A real regulator is opened by degrees so the drivers don't slip.
@export var regulator_open_time := 8.0
## Steam into the cylinders lags the regulator: the effort follows it with this time constant, s.
@export var steam_lag := 1.5

@export_group("Brakes")
## Full brake as a share of the train's weight (g): the shoes' grip against the mass. Cast iron
## shoes on an 1882 train, braking ~ a third of the weight at a shoe friction of ~0.15.
@export var brake_g := 0.042
## Cast iron shoes grip harder as the wheel slows: the brake force times
## (1 + brake_low_speed_gain x e^(-v / brake_low_speed)). The lurch at the end of a stop.
@export var brake_low_speed_gain := 0.6
@export var brake_low_speed := 2.0
## How long the brakes take to come on and go off (the shoes setting along the train), s.
@export var brake_apply_time := 3.0
@export var brake_release_time := 5.0

@export_group("Resistance (the Davis form)")
## R = m g (davis_a + davis_b v) + davis_c v^2, N. davis_a: journals and rolling (a share of the
## weight), davis_b: flange, s/m, davis_c: air on the train's front and sides, N s^2/m^2.
@export var davis_a := 0.0016
@export var davis_b := 0.00006
@export var davis_c := 4.0
## Curve resistance: an equivalent grade per 1/m of curvature (0.8 lb/ton per degree of curve:
## 0.0004 per degree, and a degree of curve is 1746/R in metres: 0.70 x 1/R).
@export var curve_resistance := 0.70
## Breaking away from a stand takes more than keeping rolling (journals' oil squeezed out):
## an extra share of the weight below `breakaway_speed`, m/s.
@export var breakaway := 0.004
@export var breakaway_speed := 0.3
## Wheels, axles and rods spinning up: the mass a train seems to have over what it weighs.
@export var rotating_share := 0.06

@export_group("The consist")
## The train, front to back (step 2: Sean's six, #552: engine and tender, two ore cars, a boxcar,
## an express car and a coach). Each car: `name`, `kind` (engine, tender, ore, box, express, coach:
## how it's drawn and its solid shape), `length` (over the end sills, m), `mass` (empty, kg),
## `load` (what it carries, kg), `trucks` (Vector2: its two trucks from its front end, m),
## `width` and `height` (the body's box, above the rail top, m). Lengths and masses are period
## narrow-gauge cars' (the brief's "Numbers"), proposed.
@export var consist: Array = [
	{"name": &"engine", "kind": &"engine", "length": 9.4, "mass": 31000.0, "load": 0.0, "trucks": Vector2(1.4, 6.6), "width": 2.2, "height": 3.4},
	{"name": &"tender", "kind": &"tender", "length": 6.4, "mass": 24000.0, "load": 0.0, "trucks": Vector2(1.2, 5.2), "width": 2.1, "height": 2.3},
	{"name": &"ore1", "kind": &"ore", "length": 7.3, "mass": 4500.0, "load": 10000.0, "trucks": Vector2(1.2, 6.1), "width": 2.1, "height": 1.7},
	{"name": &"ore2", "kind": &"ore", "length": 7.3, "mass": 4500.0, "load": 10000.0, "trucks": Vector2(1.2, 6.1), "width": 2.1, "height": 1.7},
	{"name": &"boxcar", "kind": &"box", "length": 9.1, "mass": 7000.0, "load": 5000.0, "trucks": Vector2(1.3, 7.8), "width": 2.3, "height": 3.4},
	{"name": &"express", "kind": &"express", "length": 12.2, "mass": 11000.0, "load": 1000.0, "trucks": Vector2(1.8, 10.4), "width": 2.4, "height": 3.5},
	{"name": &"coach", "kind": &"coach", "length": 13.4, "mass": 12000.0, "load": 1500.0, "trucks": Vector2(2.2, 11.2), "width": 2.4, "height": 3.5},
]
## The gap between two cars' end sills with the coupler's slack in the middle of its play, m.
@export var coupler_gap := 0.6

@export_group("Couplers (slack)")
## Free play in each coupler: link-and-pin slack plus the draft gear's travel before it bites, m
## (the plan: ~50-75 mm a coupler). Over six couplers the engine moves ~0.4 m before the coach does.
@export var coupler_slack := 0.065
## The draft gear past its play: a stiff spring (N/m) and a damper (N s/m) on the gap's change.
@export var coupler_stiffness := 3.0e6
@export var coupler_damping := 6.0e4
## Steps of the couplers a physics tick (a stiff spring wants a short step).
@export var coupler_substeps := 4
## The least closing speed (m/s) at which a coupler running out or bunching is a bang worth
## logging (step 4's coupler sounds hang on these events).
@export var coupler_event_speed := 0.05
## The brakes come on car by car down the train (the air, or the brakemen at the wheels): each car
## after the engine starts setting this long after the one ahead, s.
@export var brake_propagation := 0.25
## The air's share on the leading car (the rest of the Davis C term spread down the train).
@export var air_lead_share := 0.5

@export_group("The engineer")
## The speed he runs at to time (the timetable's run times are his runs at this speed), km/h.
@export var schedule_kmh := 25.0
## The most he'll run to make up time, and the least he'll dawdle to keep it, km/h.
@export var max_kmh := 38.0
@export var min_kmh := 12.0
## The deceleration he brakes for a mark at, m/s^2 (a service stop, below what full brake gives:
## ~0.4 m/s^2 at speed, more as the wheels slow).
@export var service_decel := 0.22
## How far short of the mark he aims the braking curve's end (the last of it he takes by feel), m.
@export var stop_aim := 0.3
## Creeping up to a mark he's stopped short of, km/h.
@export var creep_kmh := 2.5
## Within this of the mark he calls it stopped on it, m.
@export var stop_tolerance := 0.6
## How hard he works the levers to the speed he wants: regulator (share per km/h off) and brake.
@export var throttle_gain := 0.15
@export var brake_gain := 0.25
## How often he reckons his time against the timetable, s.
@export var reckon_every := 5.0

@export_group("The track")
## Narrow gauge, 3 ft.
@export var gauge := 0.914
@export var tie_spacing := 0.6
@export var tie_size := Vector3(1.83, 0.15, 0.2)
## Rail head width and height (35 lb/yd iron of the time is ~8 cm tall).
@export var rail_size := Vector2(0.06, 0.08)
@export var ballast_top := 2.4
@export var ballast_depth := 0.3
## Rails are 30 ft (9.1 m): the clack timing in step 4.
@export var rail_length := 9.14

@export_group("Feel (what the lab reports)")
## The proposed ranges Sean is asked about (km/h, s, m).
@export var start_to_25_range := Vector2(20.0, 45.0)
@export var stop_from_30_range := Vector2(70.0, 120.0)
@export var top_speed_range := Vector2(30.0, 45.0)
