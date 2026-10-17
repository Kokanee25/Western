class_name GazeTuning
extends Resource
## How a man with a talking face (tools/faces/talking_face.py) looks at things: his eyes first, his
## head for the rest, as people do (eyes lead in tens of milliseconds, the head follows in a few
## hundred, the eyes counter-turning to stay on the target meanwhile; the head takes most of a
## large turn once it's held). Edit config/gaze.tres. Used by FaceGaze.

## Degrees his eyes turn at a look shape's full weight (MakeHuman's eye units: about 19).
@export var eye_range := 19.0
## Under this (degrees, from where his body faces) only the eyes move; past it his head starts.
@export var eye_comfort := 10.0
## The share of a held look his head ends up taking.
@export var head_share := 0.75
## How far his head turns over his pose (degrees): left/right, up/down.
@export var head_yaw_max := 65.0
@export var head_pitch_max := 30.0
## Time constants (seconds): his eyes to a new angle (a saccade), his head after them.
@export var eye_time := 0.035
@export var head_time := 0.18
## Small flicks while he holds a look (degrees), every so often (seconds, low..high).
@export var micro := 0.5
@export var micro_every := Vector2(0.6, 1.8)
## Blinks every so often (seconds, low..high), each this long; and one, with this chance, when his
## look jumps further than blink_on_shift degrees.
@export var blink_every := Vector2(2.5, 6.0)
@export var blink_time := 0.16
@export var blink_on_shift := 25.0
@export var blink_shift_chance := 0.6
