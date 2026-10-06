class_name FireTuning
extends Resource
## How fire behaves (config/fire.tres). Time is real seconds at normal game speed; fire runs faster
## than real timber burns (about 0.7 mm a minute) so a building goes up in minutes, not an
## afternoon, but slow enough to fight (Sean, 2026-10-05: "it would be cool if you could actually
## have time to put it out"): the heating, cooling, growth and charring rates are all a quarter of
## what they were, so it burns as before, four times slower. Two boards lit on the store's back
## wall: 5 burning at ~35 s, 20 at ~75 s, its framing alight at ~50 s, its roof in at ~8.5 min
## (it was 10 s, 20 s, 12 s and 2 min). `tools/fire_timeline.gd` measures it.

## Degrees C. Wood catches around here (dry pine lights at 250–300 °C with a flame near).
@export var ignition_temperature := 290.0
@export var ambient_temperature := 20.0
## Materials that never burn (they still get hot, and glass cracks).
@export var fireproof := [&"stone", &"glass", &"iron"]
## Glass cracks and falls out of its frame this hot.
@export var glass_cracks_at := 240.0

## Heat from a burning member into what it touches, and what's near it (radiant, fading to nothing
## at `reach` metres), in °C per second for a 1 cm thick member (thicker ones heat slower).
@export var contact_heating := 30.0
@export var radiant_heating := 4.5
@export var reach := 1.3
## Flames lick up this far above a burning member: what's straight over it, within this, is
## heated as if touching the flames.
@export var flame_height := 0.6
## Flames climb: heat going up is at full strength, sideways at this much, downward at this much.
@export var sideways := 0.45
@export var downward := 0.12
## Hot things lose heat to the air: this share of the difference from ambient per second.
@export var cooling := 0.0055
## A fire takes this long to get going on a member before it's at full heat.
@export var growth_seconds := 32.0

## Water (a bucket thrown, `FireSystem.douse`): a burning member goes out with this many litres
## for each square metre of its broadest face (less knocks it back a while); water left over soaks
## in, and a wet member takes `water_per_degree` litres of drying per degree its heat would have
## warmed a 1 cm board before it can warm at all, and dries in the air at `evaporation` litres a
## second. So a doused wall beside a fire stays out of it for a minute or two.
@export var quench_litres := 0.25
@export var water_per_degree := 0.0007
@export var evaporation := 0.002

## How fast burning timber turns to char, metres per second, from each face.
@export var char_rate := 0.0000625
## Burnt down to less than this (m) and a board is gone to ash.
@export var ash_thickness := 0.004

## How often the fire's rules run (s), and how often burning buildings recheck their loads.
@export var tick := 0.25
@export var settle_every := 1.0
## Limits on what gets drawn: members with flames, and fire lights.
@export var max_flames := 40
## A member's flames (FireFX): each tongue's size (m, wide × tall) when the member catches and
## once it's fully alight (`growth_seconds` in), so a burning wall's tongues overlap into a sheet;
## and at most this many tongues a member, so the count doesn't climb as they grow.
@export var flame_size_catching := Vector2(0.35, 0.6)
@export var flame_size_alight := Vector2(1.0, 1.7)
@export var flames_a_member := 8
@export var max_lights := 6
## People within this of flames get burnt, at this rate (burn severity per second, per flame).
@export var scorch_reach := 0.5
@export var scorch_rate := 0.35
## A lamp's spilt oil: burns this long, heating what's within `spill_radius`.
@export var spill_seconds := 25.0
@export var spill_radius := 0.9
@export var spill_heating := 90.0

## Smoke that knows the buildings (docs/briefs/smoke.md; `SmokeField`, the native `SmokeGrid`):
## a box of cells round each burning building, `smoke_cell` metres a side, `smoke_margin` metres
## past it on every side and `smoke_above` over its top. A burning member puts `smoke_per_m2`
## a second for each square metre of its broadest face (a full cell holds 1), and heat that makes it
## rise faster, into the open cells beside it.
@export_group("Smoke")
@export var smoke_cell := 0.5
@export var smoke_margin := 3.0
@export var smoke_above := 9.0
@export var smoke_per_m2 := 25.0
@export var smoke_heat := 1.0
## The grid's own rules (SmokeGrid.tune): rising (cold, and per unit of heat), the ceiling jet
## toward the nearest way up, spreading under a ceiling and everywhere, thinning indoors and in the
## open, cooling.
@export var smoke_rise := 1.0
@export var smoke_rise_hot := 1.0
@export var smoke_jet := 2.5
@export var smoke_ceiling_spread := 0.8
@export var smoke_mix := 0.1
@export var smoke_fade := 0.01
@export var smoke_fade_open := 0.02
## How it's drawn (the art session's to judge): fog of this density where a cell is full, and its
## colour.
@export var smoke_draw_density := 10.0
@export var smoke_colour := Color(0.42, 0.39, 0.36)
## At most this many buildings' smoke at once (each is its own box); past it, the old particle smoke.
@export var smoke_fields := 6
