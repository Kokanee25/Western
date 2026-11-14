class_name DentTuning
extends Resource
## Dents in iron and steel (issue #770, Sean's "dents OK" on #784): how deep a blow pushes a plate
## in. Edit config/dents.tres, not code.
##
## The rule (Dents.depth_for): bending a plate into a dish of depth d takes about
## E = pi x yield x thickness x d^2 (a plastic hinge round the dish's rim, the work over its depth:
## Jones, "Structural Impact", the rigid-plastic plate under a mass, simplified to its leading term).
## Twice as deep takes four times the energy. For 8 mm wrought iron at 190 MPa: ~0.48 kJ for 1 cm,
## 1.9 kJ for 2 cm, 7.6 kJ for 4 cm. Only a share of a blow's lost energy goes into the plate
## (`share`): the rest goes into the oak behind it and what struck it (a pine log crushes too).

## The iron's yield stress (Pa): wrought iron ~190 MPa (period plate; mild steel ~250).
@export var yield_pa := 190.0e6
## The share of a blow's lost energy that goes into bending the plate (#784: 30%).
@export var share := 0.3
## ... of a ball's spent energy (the lead splashes: it takes nearly all of it). A .45 ball's
## ~620 J at 5% is a dimple ~2.5 mm deep.
@export var ball_share := 0.05
## Past this depth (m) the rivets tear and the plate comes off (#784: ~8 cm, ~30 kJ into one plate).
@export var tear_depth := 0.08
## Shallower than this (m) leaves no dent worth drawing or saving.
@export var least_depth := 0.001
## A dent this near (m, a share of its radius) an earlier one on the same side deepens it (their
## energies add) instead of making a second.
@export var merge_within := 0.5
## The dented plate's mesh: its faces in squares this big (m).
@export var cell := 0.025
## A blow's least energy (J) for it to count at all (a coach rocking on its wheels, a log resting).
@export var least_joules := 40.0
## How wide a dent is when nothing says (m): a corner, a hub, the ground.
@export var default_radius := 0.12
## A blow's contact (Dents.Watch) ends when the pair haven't touched for this long (s).
@export var contact_gap_s := 0.05
