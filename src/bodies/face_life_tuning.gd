class_name FaceLifeTuning
extends Resource
## What a man with a talking face (tools/faces/talking_face.py) looks at and how his face answers
## what happens to him: FaceLife's numbers (config/face_life.tres). The looking itself, eyes first
## and the head after, and the ordinary blinks, are FaceGaze's (config/gaze.tres).

## How often he weighs what to look at (seconds), and how near the camera his face is worth it (m:
## further off nobody can see his eyes).
@export var pick_every := 0.25
@export var near_camera := 25.0
## How long he holds a look at someone before he may look elsewhere (seconds, low..high).
@export var hold := Vector2(1.2, 3.5)
## The chance, when a hold ends, that he glances off at nothing for a moment (seconds, low..high).
@export var glance_away := 0.3
@export var glance := Vector2(0.4, 1.1)
## With nobody to look at: his eyes wander ahead (degrees left/right, up/down), a new spot every so often.
@export var wander_yaw := 35.0
@export var wander_pitch := 8.0
@export var wander_every := Vector2(1.5, 4.0)
## Who draws his look: someone closer (per metre less, out to `interest_range`), the player, someone
## moving, someone just seen, and less the longer he's looked.
@export var interest_range := 15.0
@export var player_bonus := 2.0
@export var moving_bonus := 1.0
@export var new_bonus := 2.5
@export var bored_per_second := 0.4
## What looking at nothing scores (with up to 0.5 more by chance): once he's looked his fill at
## someone (his score under this), he looks off a moment.
@export var nothing_score := 1.0
## A loud noise he hears (a shot, breaking glass or timber; a blast within twice this, m): he looks
## to it at once and starts (his brows up, a blink), and keeps looking there this long (seconds,
## low..high); a ball past his head (Events.near_miss) the same, at the shooter. A quieter sound
## (footsteps, a splash) only draws a look, when he's not holding one.
@export var startle_range := 40.0
@export var startle_look := Vector2(1.0, 2.2)
@export var startle_brows := 0.7
@export var startle_fade := 0.9
## Hurt: his felt pain (Physiology.felt_pain() over pain_faint, 0..1) drawn on his face, his eyes
## screwed up, brows down, a scowl, this much at the most. No wince on the hit itself (Sean,
## 2026-10-18: a ball that doesn't drop him gives no flinch or wince): pain arrives over a few
## seconds, and so does this.
@export var pain_grimace := 0.7
## Afraid (his brain's fear 0..1): wide eyes (brows up this much at full fear), blinks this many
## times as often, his look held this share as long (darting).
@export var fear_brows := 0.45
@export var fear_blink := 2.0
@export var fear_hold := 0.35
## Aiming: his eyes narrowed along the barrel, this much.
@export var aim_squint := 0.35
## Dead: his lids this far closed (they don't shut on their own), set over this long (seconds);
## out cold, this far.
@export var dead_lids := 0.65
@export var out_lids := 0.85
@export var lids_time := 0.6
## How fast an expression eases in and out (seconds).
@export var ease_time := 0.12
