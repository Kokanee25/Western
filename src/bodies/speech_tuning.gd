class_name SpeechTuning
extends Resource
## How a talking man's mouth says a line (FaceSpeech, config/speech.tres): his pace, his pauses,
## how wide he opens, the nod on the word he leans on. Brief: docs/briefs/talking.md.

## The whole pace (1: about 155 words a minute, conversational; checked against espeak-ng by
## tools/faces/speech_check.py).
@export var rate := 1.0
## A vowel's seconds: stressed, unstressed; a diphthong (ay, ow, oy) this share longer.
@export var vowel := 0.13
@export var vowel_weak := 0.07
@export var diphthong := 1.3
## The consonants' own lengths (FaceSpeech.VISEMES) times this.
@export var consonant := 1.0
## A phrase's last syllable is drawn out this much (people slow into a pause).
@export var final_lengthen := 1.35
## Pauses (seconds): a comma (; :), a full stop (! ?), an ellipsis, a dash (a line cut off).
@export var pause_comma := 0.2
@export var pause_stop := 0.35
@export var pause_ellipsis := 0.5
@export var pause_dash := 0.25
## A phrase ending "!" (or a word in capitals): faster by `shout_rate`, his jaw and lips this much
## wider; one trailing off ("..."): slower and smaller.
@export var shout_rate := 1.1
@export var shout_open := 1.3
@export var trail_rate := 0.82
@export var trail_open := 0.75
## How wide he talks, all in all (the open shapes: 1 is VISEMES' own, about a shout). Calm speech
## opens the jaw ~1 cm on an "ah".
@export var open := 0.6
## How wide he opens on a stressed syllable, and on an unstressed one (the open shapes only:
## jaw_open, aa, lips_apart, ee).
@export var stress_open := 1.15
@export var weak_open := 0.75
## How far each sound's pull on his mouth reaches either side of it (seconds; each sound's own
## reach is this times its `tau` in VISEMES): the coarticulation (Cohen and Massaro 1993).
@export var spread := 0.05
## The mouth follows the blend with this much lag (seconds): no steps between frames.
@export var settle := 0.025
## A nod (his head dips this many degrees and comes back over `nod_time` s) on the word each phrase
## leans on (its last stressed one), and a long phrase's first; shouted, this much.
@export var nod_deg := 1.8
@export var shout_nod_deg := 3.2
@export var nod_time := 0.38
## A broken jaw: what's left of his jaw's opening (he talks through his teeth).
@export var jaw_broken_open := 0.15
## The subtitle stays up this long after he stops, and at least this long in all.
@export var subtitle_hold := 0.7
@export var subtitle_min := 1.5
## Timing from a recorded line's loudness (FaceSpeech.loudness): under `loud_gate` (of the line's
## loud level) is quiet, a gap this long between words is a pause, and his mouth opens between
## `loud_floor` and all of the shapes' opening with the loudness.
@export var loud_gate := 0.12
@export var loud_gap := 0.12
@export var loud_floor := 0.35
## Further from the camera than this (m) his mouth isn't drawn (his line still runs its time).
@export var near_camera := 25.0
