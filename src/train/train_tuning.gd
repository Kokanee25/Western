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
## The train, front to back (Sean, #552: engine and tender, two ore cars, a boxcar, an express car
## and a coach). Each car: kind, length (m, end to end over the bodies), mass (kg, as it runs:
## loaded), trucks (Vector2: its two trucks, or axle groups, from its front, m). PROPOSED (#551):
##   - engine 9.4 m / 31 t, tender 6.4 m / 24 t loaded (step 1: the D&RG class 70 and its tender);
##   - ore cars 24 ft (7.3 m), ~4 t empty and 10 t of ore: 14 t (the D&RG's narrow-gauge drop-bottom
##     gondolas carried 10 t);
##   - the boxcar 30 ft (9.1 m), ~7 t empty, 5 t of freight: 12 t;
##   - the express car 34 ft (10.4 m), ~10 t, with the strongbox, mail and the guard: 11 t;
##   - the coach 42 ft (12.8 m), ~12 t empty, with twenty aboard: 13.5 t.
@export var consist: Array = [
	{"kind": "engine", "length": 9.4, "mass": 31000.0, "trucks": Vector2(1.4, 6.6)},
	{"kind": "tender", "length": 6.4, "mass": 24000.0, "trucks": Vector2(1.2, 5.2)},
	{"kind": "ore", "length": 7.3, "mass": 14000.0, "trucks": Vector2(1.0, 6.3)},
	{"kind": "ore", "length": 7.3, "mass": 14000.0, "trucks": Vector2(1.0, 6.3)},
	{"kind": "box", "length": 9.1, "mass": 12000.0, "trucks": Vector2(1.3, 7.8)},
	{"kind": "express", "length": 10.4, "mass": 11000.0, "trucks": Vector2(1.5, 8.9)},
	{"kind": "coach", "length": 12.8, "mass": 13500.0, "trucks": Vector2(1.6, 11.2)},
]
## The gap between cars' ends at the middle of the couplers' free play, m.
@export var coupler_gap := 0.6
## The car bodies' sizes as drawn (width, height above the rail), m.
@export var car_width := 2.3
@export var car_height := 3.1

@export_group("Couplers (step 2)")
## Free play in each coupler, m: the link-and-pin's slop. Inside it the cars don't pull or push each
## other; at its ends the draft gear's spring takes it. Slack runs out car by car on a start and
## bunches on a stop. PROPOSED: 65 mm (the plan's 50-75).
@export var coupler_slack := 0.065
## The draft gear's spring past the free play, N/m (3 MN/m: 100 kN squeezes it 33 mm).
@export var draft_stiffness := 3.0e6
## Its damping, as a share of critical for two of the cars on it.
@export var draft_damping := 0.35
## A coupler's slack running out (or bunching) faster than this, m/s, is logged as a bang (step 4's
## clank hangs on it); slower is a nudge, logged too but marked soft.
@export var coupler_bang_speed := 0.15
## The couplers are stiff against a 60 Hz tick: the train steps this many times a tick.
@export var substeps := 6
## The brake comes on car by car down the train (the signal travelling back), s a car: the rear cars
## run in on the front ones, and the slack bunches.
@export var brake_propagation := 0.35

@export_group("The engineer (step 2)")
## How hard he means to brake for a stop, as a share of what full brake would do on that grade at
## that speed: the rest is his margin (the shoes take seconds to set, and longer down the train).
@export var service_brake := 0.6
## How far ahead of the brakes he looks: the seconds the shoes take to set along the train, s.
@export var brake_lead := 2.5
## The last metres: below this speed (m/s) he eases the brake off as he comes onto the mark, so it
## doesn't hold him short, and closes it again for the stand.
@export var creep_speed := 1.2
## He stops with the engine's front within this of the mark, m (the proof: within 1 m).
@export var stop_tolerance := 0.5
## Holding a speed: regulator per m/s he's short of it, and brake per m/s he's over it downhill.
@export var throttle_gain := 0.6
@export var hold_brake_gain := 0.25
## The least time he stands at a stop even when late, s (he still loads; a set dwell can be longer).
@export var dwell_min := 60.0

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
