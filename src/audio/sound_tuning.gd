class_name SoundTuning
extends Resource
## How sounds are placed in the world (GameAudio; the sound lab, docs/briefs/sound-lab.md). The
## lab's runs measure these against its baseline; Sean's ears decide.

@export_group("Gunshots")
## The report (its blast, close): full within `report_unit_size` metres, then falling 6 dB a
## doubling (Godot's inverse distance: unit_size / distance, capped at max_db).
@export var report_unit_size := 3.0
@export var report_db := 6.0
## The roll (the boom that carries, the hills sending it back): far quieter close, falling slowly,
## so a far shot is mostly its roll.
@export var roll_unit_size := 100.0
@export var roll_db := -20.0
@export var roll_max_db := -14.0
## Each slap off a front: the share of the report a timber wall throws back.
@export var slap_db := -8.0

@export_group("Dynamite")
## The blast: full within this many metres for one stick (more for a bigger charge, by the cube
## root of the weight), then −6 dB a doubling; the roll falls slowly, so a far blast is its thunder.
@export var blast_unit_size := 8.0
@export var blast_roll_unit_size := 150.0
@export var blast_roll_db := -14.0
@export var blast_roll_max_db := -4.0
## Clods and splinters landing round it after (one stick's worth; more by the cube root).
@export var debris_count := 10

@export_group("Passes and strikes")
## A ball going by snaps only if it's faster than sound (buckshot near the muzzle; a black-powder
## .45's ball, ~270 m/s, doesn't: it whirrs). True: every true pass snaps, as before the lab (Sean's
## earlier rule, from modern rounds).
@export var subsonic_snaps := false

@export_group("How many at once")
## Placed sounds at once (playing or on their way); past it the quietest at the ears gives way.
@export var max_voices := 32
## Of one breaking sound (a member's crack, rubble's crash, a pane) at once.
@export var breaking_limit := 4

@export_group("Air, walls and rooms")
## The air's loss of highs: the high shelf's corner at 20 kHz / (1 + distance / this).
@export var air_metres := 25.0
## Through a wall: a low-pass at this and this much quieter.
@export var wall_cutoff_hz := 700.0
@export var wall_db := -6.0
## A timber room (AudioEffectReverb): its size, damping and how much of it is heard.
@export var room_size := 0.6
@export var room_damping := 0.45
@export var room_wet := 0.5
