class_name WipeTuning
extends Resource
## The barkeep's chore's dials (WipeBar; config/wipe.tres): how he wipes his bar, in numbers, not
## keyframes (CLAUDE.md "Motion"). Seconds, metres, hertz.

@export_group("When")
## Calm, free and nobody at the bar this long before he takes the cloth off his shoulder.
@export var idle_before := 5.0
## Having put it back, this long (a range) before he starts again.
@export var rest_between := Vector2(15.0, 45.0)
## Stretches of bar wiped in a go (a range).
@export var stretches := Vector2i(2, 4)
## A cup within reach after a stretch: the chance he picks it up and wipes it.
@export var glass_chance := 0.4

@export_group("Where")
## His side of the bar he works, each way from his post (m), and how far he moves along it.
@export var span := 1.3
@export var stretch := 0.55
## The bar top is looked for this far ahead of him (m), between these heights over his feet.
@export var bar_ahead := Vector2(0.2, 1.1)
@export var bar_height := Vector2(0.75, 1.3)
## How far out over the bar from its near edge he wipes (m: the middle of the stretch is half way).
@export var reach_out := 0.34
## Someone this near (m), more than `customer_ahead` past his front (across the bar), is a customer.
@export var customer_near := 2.6
@export var customer_ahead := 0.3

@export_group("The hands")
## Seconds to take his hand to his shoulder, to the bar, to a cup.
@export var reach_seconds := 0.55
## The palm's middle over the bar top, wiping (m: the hand's own thickness and the cloth's).
@export var palm_above := 0.03
## Lifted to move along, or to lay it down (m).
@export var carry_above := 0.07
## Circles: their radius (m), turns a second, and how far they drift across the stretch.
@export var circle_radius := 0.065
@export var circle_hz := 1.15
@export var circle_drift := 0.14
## Long strokes along the bar: their length (m), strokes a second (there and back is one), and the
## share of a stretch's time spent on them (the rest is circles).
@export var stroke_length := 0.34
@export var stroke_hz := 0.6
@export var stroke_share := 0.45
## A stretch takes this long (a range).
@export var wipe_seconds := Vector2(4.0, 7.0)
## A cup: held this long, the cloth turned in its mouth this fast (turns a second), this wide (m).
@export var glass_seconds := Vector2(3.0, 5.0)
@export var glass_hz := 1.6
@export var glass_radius := 0.022
## Where he holds the cup, in front of his chest (his space: right, up, back).
@export var glass_held := Vector3(-0.06, 1.18, -0.3)
## His fingers round the cloth: wiping (a loose pad under the flat hand), carrying, round a cup.
@export var grip_wipe := 0.3
@export var grip_carry := 0.65
@export var grip_cup := 0.5
## He leans in for the far side of a stretch: degrees a metre past `lean_from` from his shoulder.
@export var lean_from := 0.38
@export var lean_per_m := 60.0
@export var lean_max := 16.0
## Fetching it from across the bar, he leans in up to this (degrees).
@export var lean_across := 40.0

@export_group("Moving and looking")
## Stepping along behind the bar (m/s).
@export var step_speed := 0.7
## A cloth he's lost within this of his post (m) he goes and gets; he gives up after this long (s).
@export var fetch_reach := 5.0
@export var fetch_give_up := 15.0
## Bending for one on the floor: his trunk forward by these (degrees) on top of a crouch.
@export var stoop := Vector2(-30.0, -28.0)
## Trouble: the cloth tossed down this fast (m/s).
@export var toss_speed := 1.3
## His head turns this share of the way to what he's watching (no FaceGaze to do it), this fast.
@export var head_share := 0.7
@export var head_rate := 4.0
