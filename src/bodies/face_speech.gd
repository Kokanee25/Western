class_name FaceSpeech
extends Node
## A talking man's mouth saying his lines (Sean, 2026-10-22: "when a man speaks a line, his mouth
## moves with it"). When Events.spoke fires for him, the line's letters become sounds (rules in the
## manner of Elovitz et al., NRL Report 7948, 1976), the sounds become mouth classes (visemes:
## many sounds look alike on the lips), each with its time at a conversational pace, and the
## classes pull his mouth shapes (tools/faces/talking_face.py: jaw_open, aa, lips_apart, ee, oo,
## fv, mbp) each toward its own, the stronger and nearer the more (Cohen and Massaro's dominance
## blend, "Modeling coarticulation in synthetic visual speech", 1993): an m shuts his lips, a t
## barely moves them. A stressed vowel opens wider, a shout wider still; his head dips on the word
## each phrase leans on (riding on FaceGaze's turn, `FaceGaze.nod`).
##
## His mouth only: his eyes, lids, brows and look are FaceLife's and FaceGaze's. A recorded line
## (DESIGN.md §9, none yet) times it instead: `say(text, {"audio": AudioStreamWAV})` (or its
## "loudness") fits the text's sounds to the voiced stretches between the audio's pauses and opens
## the mouth with the loudness; `{"phonemes": [[start, end, "AH1"], ...]}` (a forced aligner's
## ARPAbet) takes the sounds and times as they are. Numbers in config/speech.tres (SpeechTuning);
## brief docs/briefs/talking.md.
##
## HumanBody adds one beside FaceLife to a man whose model has a talking face (its report's
## "facerig"); his bandana's mask (tools/faces/mask_jaw.py) carries the same shapes and follows.

const SHAPES := [&"jaw_open", &"aa", &"lips_apart", &"ee", &"oo", &"fv", &"mbp"]
## The open shapes (the first OPEN of SHAPES): stress, shouting and loudness scale them.
const OPEN := 4
## Each mouth class: its shapes' weights (SHAPES' order), how hard it pulls the mouth (its
## dominance), how far either side it reaches (times SpeechTuning.spread), and a consonant's own
## length (s; a vowel's comes from the tuning). "_" is quiet (the mouth at rest).
const VISEMES := {
	&"_": [[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], 1.0, 1.5, 0.0],
	# lips: m b p shut and pressed; f v the lip on the teeth; w and oo rounded
	&"m": [[0.0, 0.0, 0.0, 0.0, 0.1, 0.0, 1.0], 14.0, 0.5, 0.075],
	&"f": [[0.0, 0.0, 0.05, 0.05, 0.0, 1.0, 0.0], 9.0, 0.6, 0.085],
	&"w": [[0.05, 0.0, 0.05, 0.0, 0.85, 0.0, 0.0], 5.0, 0.8, 0.06],
	&"sh": [[0.04, 0.0, 0.45, 0.05, 0.45, 0.0, 0.0], 3.0, 0.8, 0.09],
	&"r": [[0.03, 0.0, 0.2, 0.0, 0.4, 0.0, 0.0], 1.2, 1.0, 0.06],
	# the tongue's: they hardly hold the lips, so they take their vowels' shapes
	&"t": [[0.04, 0.05, 0.35, 0.15, 0.0, 0.0, 0.0], 0.5, 1.0, 0.06],
	&"s": [[0.0, 0.0, 0.25, 0.35, 0.0, 0.0, 0.0], 1.0, 0.8, 0.085],
	&"th": [[0.04, 0.05, 0.4, 0.1, 0.0, 0.0, 0.0], 0.8, 0.8, 0.07],
	&"l": [[0.07, 0.2, 0.3, 0.0, 0.0, 0.0, 0.0], 0.5, 1.0, 0.06],
	&"k": [[0.06, 0.15, 0.3, 0.0, 0.0, 0.0, 0.0], 0.3, 1.0, 0.065],
	&"h": [[0.1, 0.15, 0.35, 0.0, 0.0, 0.0, 0.0], 0.15, 1.0, 0.05],
	&"y": [[0.0, 0.0, 0.15, 0.6, 0.0, 0.0, 0.0], 1.0, 0.8, 0.05],
	# vowels: open (aa, ae, ao), spread (iy, ih, eh), rounded (uw, uh, ow, er), the slack schwa
	&"aa": [[0.15, 0.75, 0.05, 0.0, 0.0, 0.0, 0.0], 1.5, 1.0, 0.0],
	&"ao": [[0.12, 0.55, 0.05, 0.0, 0.3, 0.0, 0.0], 1.5, 1.0, 0.0],
	&"ae": [[0.08, 0.55, 0.1, 0.35, 0.0, 0.0, 0.0], 1.5, 1.0, 0.0],
	&"eh": [[0.06, 0.4, 0.1, 0.35, 0.0, 0.0, 0.0], 1.3, 1.0, 0.0],
	&"iy": [[0.0, 0.05, 0.15, 0.8, 0.0, 0.0, 0.0], 2.0, 1.0, 0.0],
	&"ih": [[0.03, 0.2, 0.15, 0.45, 0.0, 0.0, 0.0], 1.2, 1.0, 0.0],
	&"er": [[0.05, 0.2, 0.15, 0.0, 0.35, 0.0, 0.0], 1.3, 1.0, 0.0],
	&"ah": [[0.06, 0.35, 0.15, 0.0, 0.0, 0.0, 0.0], 0.8, 1.0, 0.0],
	&"uw": [[0.08, 0.0, 0.1, 0.0, 0.85, 0.0, 0.0], 3.0, 0.9, 0.0],
	&"uh": [[0.06, 0.2, 0.1, 0.0, 0.45, 0.0, 0.0], 1.5, 1.0, 0.0],
	&"ow": [[0.1, 0.4, 0.0, 0.0, 0.55, 0.0, 0.0], 2.0, 1.0, 0.0],
	# no words: a gasp (his jaw dropped, the breath pulled in), the catch that stops it, a groan
	# through his teeth
	&"gasp": [[0.45, 0.2, 0.4, 0.0, 0.0, 0.0, 0.0], 2.0, 1.0, 0.07],
	&"catch": [[0.12, 0.0, 0.25, 0.0, 0.0, 0.0, 0.0], 3.0, 0.6, 0.06],
	&"hum": [[0.02, 0.0, 0.12, 0.15, 0.0, 0.0, 0.0], 1.5, 1.0, 0.08],
}
const VOWELS := [&"aa", &"ao", &"ae", &"eh", &"iy", &"ih", &"er", &"ah", &"uw", &"uh", &"ow"]
## Words that carry no stress of their own (no nod, a smaller mouth).
const UNSTRESSED := ["the", "a", "an", "of", "to", "in", "on", "at", "and", "or", "but", "for", "from",
	"with", "by", "as", "is", "am", "are", "was", "were", "be", "been", "it", "its", "i", "me", "my",
	"you", "your", "youre", "he", "him", "his", "she", "her", "we", "us", "our", "they", "them",
	"their", "this", "that", "thats", "do", "does", "did", "so", "if", "than", "then", "will",
	"would", "can", "could", "should", "have", "has", "had", "im", "ive", "ill", "id", "em", "just",
	"there", "theres", "what", "whats", "who", "where", "some", "one", "let", "lets", "got", "get"]
## The words English spells worst, by sound ("a+b": one vowel gliding a to b; "'" marks the
## stressed syllable where it isn't the first).
const WORDS := {
	"the": "th ah", "a": "ah", "an": "ah t", "of": "ah f", "to": "t uw", "do": "t uw", "who": "h uw",
	"two": "t uw", "you": "y uw", "your": "y ow r", "youre": "y ow r", "yours": "y ow r s",
	"i": "aa+ih", "im": "aa+ih m", "ive": "aa+ih f", "ill": "aa+ih l", "id": "aa+ih t",
	"one": "w ah t", "once": "w ah t s", "said": "s eh t", "says": "s eh s", "was": "w ah s",
	"what": "w ah t", "whats": "w ah t s", "could": "k uh t", "would": "w uh t", "should": "sh uh t",
	"put": "m uh t", "push": "m uh sh", "pull": "m uh l", "full": "f uh l", "are": "aa r",
	"were": "w er", "there": "th eh r", "theres": "th eh r s", "their": "th eh r", "where": "w eh r",
	"wheres": "w eh r s", "whered": "w eh r t", "here": "h iy r", "have": "h ae f", "give": "k ih f",
	"live": "l ih f", "gone": "k ao t", "done": "t ah t", "come": "k ah m", "some": "s ah m",
	"something": "s ah m th ih k", "love": "l ah f", "none": "t ah t", "nothing": "t ah th ih k",
	"other": "ah th er", "another": "ah t 'ah th er", "mother": "m ah th er", "brother": "m r ah th er",
	"money": "m ah t iy", "does": "t ah s", "been": "m ih t", "eye": "aa+ih", "eyes": "aa+ih s",
	"aint": "ae+iy t t", "em": "ah m", "dont": "t ow t t", "wont": "w ow t t", "cant": "k ae t t",
	"alright": "ao l r 'aa+ih t", "almighty": "ao l m 'aa+ih t iy", "enough": "ih t 'ah f",
	"tough": "t ah f", "rough": "r ah f", "laugh": "l ae f", "through": "th r uw", "though": "th ow",
	"touch": "t ah sh", "young": "y ah k", "trouble": "t r ah m ah l", "friend": "f r eh t t",
	"friends": "f r eh t t s", "buy": "m aa+ih", "busy": "m ih s iy", "build": "m ih l t",
	"move": "m uw f", "lose": "l uw s", "whose": "h uw s", "whole": "h ow l", "great": "k r ae+iy t",
	"break": "m r ae+iy k", "door": "t ow r", "floor": "f l ow r", "four": "f ow r", "pour": "m ow r",
	"blood": "m l ah t", "sure": "sh uh r", "oh": "ow", "ah": "aa", "agh": "aa k", "own": "ow t",
	"known": "t ow t", "shown": "sh ow t", "grown": "k r ow t", "blown": "m l ow t", "bowl": "m ow l",
	"truly": "t r uw l iy", "obliged": "ah m l 'aa+ih sh t", "iron": "aa+ih er t", "whiskey": "w ih s k iy",
	"mister": "m ih s t er", "almost": "ao l m ow s t", "always": "ao l w ae+iy s",
	"anything": "eh t iy th ih k", "everybody": "eh f r iy m ah t iy", "everyone": "eh f r iy w ah t",
	"whatever": "w ah t 'eh f er", "whenever": "w eh t 'eh f er", "yellow": "y eh l ow",
	"figured": "f ih k y er t", "pleasure": "m l eh sh er", "business": "m ih s t ah s",
}
## Before a consonant then a vowel, a word's first syllable gives its stress to the second
## (again, alone, before, return).
const PREFIXES := ["be", "re", "de", "ex", "un", "a"]

## Off for a whole run (the fixed screenshot views hold every face at rest).
static var enabled := true
static var _default_tuning: SpeechTuning
static var _words_re: RegEx

var body: HumanBody
var tuning: SpeechTuning
## Stepped on its tick (PeopleTick: a fixed step); off: call step() yourself.
var auto := true
## Where the camera is for the near_camera rest (null: the viewport's; none: always near).
var camera: Node3D

var _faces: Array[MeshInstance3D] = []
var _index := []                      # per face, per SHAPES entry: its blend shape (-1: none)
var _gaze: FaceGaze
# The line's sounds, sorted by centre: centre, half length, pull, reach (s), weights (gain in).
var _c := PackedFloat32Array()
var _h := PackedFloat32Array()
var _a := PackedFloat32Array()
var _tau := PackedFloat32Array()
var _w: Array[PackedFloat32Array] = []
var _reach := 0.3                     # the furthest any sound's pull matters (s)
var _lo := 0
var _nods := []                       # [t, degrees]
var _open := PackedFloat32Array()     # a recorded line's loudness: opening, and quiet, per frame
var _gate := PackedFloat32Array()
var _env_rate := 100.0
var _t := 0.0
var _end := 0.0
var _talking := false
var _line := ""
var _out := PackedFloat32Array([0, 0, 0, 0, 0, 0, 0])
var _drawn := false                   # his shapes are off rest (they need writing back to 0)
var _nod := 0.0
var _own_nod := 0.0                   # with no FaceGaze: what this added to his head's offset


func _ready() -> void:
	set_physics_process(true)  # its switch (PeopleTick ticks it while on)
	if tuning == null:
		tuning = load("res://config/speech.tres")
	if body == null and get_parent() is HumanBody:
		body = get_parent()
	_find_faces()
	Events.spoke.connect(_on_spoke)


## Ticked by PeopleTick after his body, in his order (HumanBody.add_ticker); the engine calls no
## _physics_process here, and physics processing on is its switch, as before.
func _enter_tree() -> void:
	var man := get_parent() as HumanBody
	if man:
		man.add_ticker(self)


func _exit_tree() -> void:
	var man := get_parent() as HumanBody
	if man:
		man.remove_ticker(self)


func tick(delta: float) -> void:
	if auto and enabled and FaceLife.enabled:
		var t0 := Prof.start()
		step(delta)
		Prof.stop(&"faces", t0)


## Does he have a mouth to drive (a talking model's speech shapes)?
func has_face() -> bool:
	return not _faces.is_empty()


func _find_faces() -> void:
	_faces.clear()
	_index.clear()
	if body == null:
		return
	for c in body.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		var am := mi.mesh as ArrayMesh
		if am == null or am.get_blend_shape_count() == 0:
			continue
		var ids := []
		var any := false
		for s: StringName in SHAPES:
			var k := mi.find_blend_shape_by_name(s)
			ids.append(k)
			any = any or k >= 0
		if any:   # his head, and his bandana's mask when it carries the mouth's shapes
			_faces.append(mi)
			_index.append(ids)


func _on_spoke(speaker: Node, text: String) -> void:
	if speaker == body:
		say(text)


## He says `text` (from now): its plan, timed by `track` if given (see the top). Returns how many
## seconds he talks.
func say(text: String, track := {}) -> float:
	var p: Dictionary
	if track.has("phonemes"):
		p = plan_phonemes(track.phonemes, tuning)
	else:
		p = plan(text, tuning)
		if track.has("audio") and track.audio is AudioStreamWAV:
			p = fit(p, loudness(track.audio, 100.0), 100.0, tuning)
		elif track.has("loudness"):
			p = fit(p, track.loudness, float(track.get("rate", 100.0)), tuning)
	_load(p)
	_line = text
	return _end


## Stops talking now (his mouth eases to rest).
func hush() -> void:
	_talking = false


func speaking() -> bool:
	return _talking


## The line he's saying (or last said).
func line() -> String:
	return _line


## His mouth's weights now (SHAPES), for tests and the lab.
func mouth() -> Dictionary:
	var out := {}
	for i in SHAPES.size():
		out[SHAPES[i]] = _out[i]
	return out


func _load(p: Dictionary) -> void:
	var segs: Array = p.segs
	segs.sort_custom(func(x: Array, y: Array) -> bool: return float(x[1]) + float(x[2]) * 0.5 < float(y[1]) + float(y[2]) * 0.5)
	var n := segs.size()
	_c.resize(n)
	_h.resize(n)
	_a.resize(n)
	_tau.resize(n)
	_w.clear()
	var biggest := 0.0
	for i in n:
		var s: Array = segs[i]
		var v: Array = VISEMES.get(s[0], VISEMES[&"_"])
		_c[i] = float(s[1]) + float(s[2]) * 0.5
		_h[i] = float(s[2]) * 0.5
		_a[i] = float(v[1])
		_tau[i] = float(v[2]) * tuning.spread
		biggest = maxf(biggest, _tau[i])
		var w := PackedFloat32Array(v[0])
		var gain := float(s[3])
		for k in OPEN:
			w[k] = minf(w[k] * gain, 1.0)
		_w.append(w)
	# Beyond 7 reaches a sound's pull is under a thousandth of its own.
	_reach = biggest * 7.0
	_nods = p.get("nods", [])
	_open = p.get("open", PackedFloat32Array())
	_gate = p.get("gate", PackedFloat32Array())
	_env_rate = float(p.get("rate", 100.0))
	_lo = 0
	_t = 0.0
	_end = float(p.seconds)
	_talking = n > 0


func step(delta: float) -> void:
	if body == null or _faces.is_empty():
		return
	var p := body.physiology
	if _talking:
		_t += delta
		if not p.alive or not p.is_conscious() or _t > _end:
			_talking = false   # done, or dead or out cold mid-line: his mouth goes to rest
	if not _talking and not _drawn:
		return
	var goal := _blend(_t) if _talking else PackedFloat32Array([0, 0, 0, 0, 0, 0, 0])
	if _talking and p.jaw_broken:
		goal[0] *= tuning.jaw_broken_open
		goal[1] *= tuning.jaw_broken_open
	var k := 1.0 - exp(-delta / maxf(tuning.settle, 0.001))
	var rest := true
	for i in SHAPES.size():
		_out[i] = lerpf(_out[i], goal[i], k)
		if _out[i] < 0.002 and goal[i] == 0.0:
			_out[i] = 0.0
		rest = rest and _out[i] == 0.0
	_nod = _nod_at(_t) if _talking else move_toward(_nod, 0.0, delta * 20.0)
	_apply_nod()
	if _near() or rest:
		for f in _faces.size():
			var ids: Array = _index[f]
			for i in ids.size():
				if ids[i] >= 0:
					_faces[f].set_blend_shape_value(ids[i], _out[i])
		_drawn = not rest


# The sounds' pulls on his mouth at time t, blended (with a recorded line's loudness on them).
func _blend(t: float) -> PackedFloat32Array:
	var acc := PackedFloat32Array([0, 0, 0, 0, 0, 0, 0])
	var n := _c.size()
	while _lo < n - 1 and _c[_lo] + _h[_lo] + _reach < t:
		_lo += 1
	var sum := 0.0
	var j := _lo
	while j < n:
		var d := absf(t - _c[j]) - _h[j]
		if d > _reach:
			if _c[j] > t:
				break
			j += 1
			continue
		var dom := _a[j] * exp(-maxf(d, 0.0) / _tau[j])
		var w := _w[j]
		for k in acc.size():
			acc[k] += dom * w[k]
		sum += dom
		j += 1
	if sum > 0.0:
		for k in acc.size():
			acc[k] /= sum
	if not _open.is_empty():
		var o := _sample(_open, t)
		var g := _sample(_gate, t)
		for k in acc.size():
			acc[k] *= (o if k < OPEN else 1.0) * g
	return acc


func _sample(a: PackedFloat32Array, t: float) -> float:
	var x := clampf(t * _env_rate, 0.0, a.size() - 1.0)
	var i := int(x)
	return lerpf(a[i], a[mini(i + 1, a.size() - 1)], x - i)


func _nod_at(t: float) -> float:
	var deg := 0.0
	for nd: Array in _nods:
		var u := (t - float(nd[0])) / tuning.nod_time
		if u > 0.0 and u < 1.0:
			# down quickly (the first quarter), back up slowly
			var b := smoothstep(0.0, 0.25, u) if u < 0.25 else 1.0 - smoothstep(0.25, 1.0, u)
			deg = maxf(deg, float(nd[1]) * b)
	return deg


# His head dips by the nod: on his FaceGaze's turn when he has one (it writes his head's offset),
# else on his head's offset itself.
func _apply_nod() -> void:
	if _gaze == null:
		var life := body.get_node_or_null(^"FaceLife")
		if life != null and life.get("gaze") is FaceGaze:
			_gaze = life.gaze
	if _gaze != null:
		_gaze.nod = Vector3(-_nod, 0.0, 0.0)
		return
	if _nod == 0.0 and _own_nod == 0.0:
		return
	var o: Vector3 = body.pose_offsets.get(&"head", Vector3.ZERO)
	body.pose_offsets[&"head"] = o + Vector3(_own_nod - _nod, 0.0, 0.0)
	_own_nod = _nod


func _near() -> bool:
	var cam := camera
	if cam == null and is_inside_tree():
		cam = get_viewport().get_camera_3d()
	return cam == null or cam.global_position.distance_to(body.global_position) <= tuning.near_camera


## How long a subtitle for `text` stays up: as long as he says it, and a little more.
static func subtitle_seconds(text: String) -> float:
	var tu := _tuning()
	return maxf(float(plan(text, tu).seconds) + tu.subtitle_hold, tu.subtitle_min)


static func _tuning() -> SpeechTuning:
	if _default_tuning == null:
		_default_tuning = load("res://config/speech.tres")
	return _default_tuning


# ---- text to timed sounds ----

## A line as timed sounds: {"segs": [[class, start, length, gain], ...], "nods": [[t, degrees]],
## "pauses": [[from, to], ...] (between phrases), "voice": [first sound, last sound],
## "seconds": how long he talks}.
static func plan(text: String, tu: SpeechTuning = null) -> Dictionary:
	if tu == null:
		tu = _tuning()
	if _words_re == null:
		_words_re = RegEx.create_from_string("[A-Za-z']+|\\.\\.\\.|…|—|–|--|[,;:.!?]")
	var re := _words_re
	var phrases := []      # {words: [[word, caps]], end: kind}
	var cur := {"words": [], "end": &""}
	var lead := 0.0
	for m in re.search_all(text):
		var tok := m.get_string()
		var kind := _pause_kind(tok)
		if kind == &"":
			(cur.words as Array).append([tok.to_lower().replace("'", ""), tok.length() > 1 and tok == tok.to_upper() and tok != tok.to_lower()])
			continue
		if (cur.words as Array).is_empty():
			if phrases.is_empty():
				lead = maxf(lead, _pause_seconds(kind, tu) * 0.6)   # "...Gone.": he hesitates first
			else:
				(phrases[-1] as Dictionary).end = _stronger((phrases[-1] as Dictionary).end, kind)   # "!?", "—!"
			continue
		cur.end = kind
		phrases.append(cur)
		cur = {"words": [], "end": &""}
	if not (cur.words as Array).is_empty():
		phrases.append(cur)
	var segs := []
	var nods := []
	var pauses := []
	var t := 0.03 + lead
	var first := -1.0
	var last := 0.0
	for pi in phrases.size():
		var ph: Dictionary = phrases[pi]
		var end: StringName = ph.end
		# A phrase ending "!" is shouted, one trailing off ("...") quieter and slower.
		var shout := end == &"shout"
		var trail := end == &"ellipsis"
		var rate := tu.rate * (tu.shout_rate if shout else (tu.trail_rate if trail else 1.0))
		var open := tu.shout_open if shout else (tu.trail_open if trail else 1.0)
		# The phrase's sounds, each [class, kind (0 consonant, 1 a syllable's vowel, 2 its glide),
		# its own length or -1, stressed, caps, its word].
		var sounds := []
		var words: Array = ph.words
		for wi in words.size():
			var ws := word_sounds(String(words[wi][0]))
			var stress: int = ws.stress
			var syl := -1
			for s: Array in ws.sounds:
				if int(s[1]) == 1:
					syl += 1
				sounds.append([s[0], s[1], s[2], stress >= 0 and int(s[1]) != 0 and syl == stress, words[wi][1], wi])
		# Nobody says a phrase with no stress in it: its last word's first vowel takes it.
		var any := false
		for s: Array in sounds:
			any = any or bool(s[3])
		if not any:
			for i in sounds.size():
				if int(sounds[i][5]) == words.size() - 1 and int(sounds[i][1]) == 1:
					sounds[i][3] = true
					if i + 1 < sounds.size() and int(sounds[i + 1][1]) == 2:
						sounds[i + 1][3] = true
					break
		var last_vowel := -1
		var stressed := []
		var syllables := 0
		for i in sounds.size():
			if int(sounds[i][1]) == 1:
				last_vowel = i
				syllables += 1
				if sounds[i][3]:
					stressed.append(i)
		for i in sounds.size():
			var s: Array = sounds[i]
			var cls: StringName = s[0]
			var kind := int(s[1])
			var on: bool = s[3]
			var caps: bool = s[4]
			var r := rate * (tu.shout_rate if caps and not shout else 1.0)
			var o := open * (tu.shout_open if caps and not shout else 1.0)
			var d: float
			if float(s[2]) > 0.0:
				d = float(s[2])
			elif kind == 0:
				d = float(VISEMES[cls][3]) * tu.consonant
			else:
				d = tu.vowel if on else tu.vowel_weak
				var glide := kind == 1 and i + 1 < sounds.size() and int(sounds[i + 1][1]) == 2
				if glide or kind == 2:
					d *= tu.diphthong * (0.6 if kind == 1 else 0.4)
				if i == last_vowel or (kind == 2 and i - 1 == last_vowel):
					d *= tu.final_lengthen
			d /= r
			var gain := o * (1.0 if cls in [&"gasp", &"catch"] else tu.open)   # a gasp is as wide as it is
			if kind != 0:
				gain *= tu.stress_open if on else tu.weak_open
			if first < 0.0:
				first = t
			# The phrase leans on its last stressed word (a nod), a long one on its first too.
			if kind == 1 and on and (i == stressed[-1] or (i == stressed[0] and syllables > 6)):
				nods.append([t, tu.shout_nod_deg if shout or caps else tu.nod_deg])
			segs.append([cls, t, d, gain])
			t += d
		last = t
		if pi < phrases.size() - 1 or end == &"dash" or end == &"ellipsis":
			var pz := _pause_seconds(end, tu)
			if pz > 0.0:
				if pi < phrases.size() - 1:
					pauses.append([t, t + pz])
				segs.append([&"_", t, pz, 1.0])
				t += pz
	# Quiet either side: the mouth comes from rest and goes back to it.
	if first < 0.0:
		return {"segs": [], "nods": [], "pauses": [], "voice": [0.0, 0.0], "seconds": 0.0}
	segs.append([&"_", 0.0, first, 1.0])
	segs.append([&"_", t, 0.4, 1.0])
	return {"segs": segs, "nods": nods, "pauses": pauses, "voice": [first, last], "seconds": t + 0.12}


static func _pause_kind(tok: String) -> StringName:
	match tok:
		",", ";", ":":
			return &"comma"
		".", "?":
			return &"stop"
		"!":
			return &"shout"
		"...", "…":
			return &"ellipsis"
		"—", "–", "--":
			return &"dash"
	return &""


static func _stronger(a: StringName, b: StringName) -> StringName:
	if a == &"shout" or b == &"shout":
		return &"shout"
	return a if b == &"comma" else b


static func _pause_seconds(kind: StringName, tu: SpeechTuning) -> float:
	match kind:
		&"comma":
			return tu.pause_comma
		&"stop", &"shout":
			return tu.pause_stop
		&"ellipsis":
			return tu.pause_ellipsis
		&"dash":
			return tu.pause_dash
	return 0.0


## One word's sounds: {"sounds": [[class, kind, length or -1], ...], "stress": its stressed
## syllable (-1: none)}. kind: 0 a consonant, 1 a syllable's vowel, 2 the glide it ends on.
static func word_sounds(w: String) -> Dictionary:
	var sounds := []
	var stress := -2
	if WORDS.has(w):
		var syl := 0
		for part: String in String(WORDS[w]).split(" "):
			var mark := part.begins_with("'")
			part = part.trim_prefix("'")
			var bits := part.split("+")
			if StringName(bits[0]) in VOWELS:
				if mark:
					stress = syl
				syl += 1
				sounds.append([StringName(bits[0]), 1, -1.0])
				if bits.size() > 1:
					sounds.append([StringName(bits[1]), 2, -1.0])
			else:
				sounds.append([StringName(part), 0, -1.0])
	elif not _has_vowel(w):
		sounds = _no_vowels(w)
	else:
		sounds = _letters(w)
	var syllables := 0
	for s: Array in sounds:
		if int(s[1]) == 1:
			syllables += 1
	if w in UNSTRESSED:
		stress = -1
	elif stress == -2:
		stress = 0
		if syllables >= 2 and w.length() >= 5:
			for p: String in PREFIXES:
				if w.begins_with(p) and not _is_vowel(w[p.length()]) and _is_vowel(w[p.length() + 1]) \
						and not (p == "a" and w[1] == w[2]):
					stress = 1
					break
	return {"sounds": sounds, "stress": stress}


static func _is_vowel(ch: String) -> bool:
	return ch.length() == 1 and "aeiou".contains(ch)


static func _has_vowel(w: String) -> bool:
	for ch in w:
		if "aeiouy".contains(ch):
			return true
	return false


# A word with no vowels: a groan ("Nnngh"), a choke ("Hhhk"), a hum ("Mmm"), a hush ("Shh").
static func _no_vowels(w: String) -> Array:
	var out := []
	var i := 0
	var first := true
	while i < w.length():
		var ch := w[i]
		var run := 1
		while i + run < w.length() and w[i + run] == ch:
			run += 1
		var cls := &""
		var each := 0.0
		match ch:
			"h":
				cls = &"gasp"
				each = 0.07
			"n":
				cls = &"hum"
				each = 0.08
			"m":
				cls = &"m"
				each = 0.09
			"k", "g", "c", "q":
				cls = &"catch"
				each = 0.06
			"s", "z":
				cls = &"s"
				each = 0.09
			"t", "d":
				cls = &"t"
				each = 0.06
		if ch == "h" and i > 0 and w[i - 1] in ["n", "g", "s", "c"]:
			cls = &""   # "ngh", "sh": no breath of its own
		if ch == "h" and i > 0 and w[i - 1] == "s":
			out[-1] = [&"sh", out[-1][1], out[-1][2]]
		if cls != &"":
			# The first long sound is the word's syllable (it can take the stress).
			var kind := 1 if first and cls in [&"gasp", &"hum", &"m"] else 0
			if kind == 1:
				first = false
			out.append([cls, kind, minf(each * run, 0.35)])
		i += run
	return out


# English letters to sounds, longest match first, with the contexts that change them (a final e
# that lengthens the vowel before it and is itself silent, a soft c or g, -ed, -es, -tion).
static func _letters(w: String) -> Array:
	var out := []
	var n := w.length()
	var i := 0
	while i < n:
		var c := w[i]
		var prev := w[i - 1] if i > 0 else ""
		if _is_vowel(c) or (c == "y" and i > 0 and not _is_vowel(prev)):
			i += _vowel(w, i, out)
			continue
		var r := w.substr(i)
		var nx := w[i + 1] if i + 1 < n else ""
		if c == prev:
			i += 1   # a doubled letter: one sound
			continue
		if r.begins_with("tch") or r.begins_with("dge"):
			out.append([&"sh", 0, -1.0])
			i += 3
			continue
		if r.begins_with("tion") or r.begins_with("sion"):
			out.append_array([[&"sh", 0, -1.0], [&"ah", 1, -1.0], [&"t", 0, -1.0]])
			i += 4
			continue
		var two := r.substr(0, 2)
		var took := 2
		match two:
			"ch", "sh":
				out.append([&"sh", 0, -1.0])
			"th":
				out.append([&"th", 0, -1.0])
			"ph":
				out.append([&"f", 0, -1.0])
			"wh":
				out.append([&"w", 0, -1.0])
			"ck":
				out.append([&"k", 0, -1.0])
			"ng":
				out.append([&"k", 0, -1.0])
			"nk":
				out.append_array([[&"t", 0, -1.0], [&"k", 0, -1.0]])
			"qu":
				out.append_array([[&"k", 0, -1.0], [&"w", 0, -1.0]])
			"gh":
				if i == 0:
					out.append([&"k", 0, -1.0])
			_:
				took = 0
		if took == 0 and i == 0 and two in ["wr", "kn", "gn", "ps", "pn"]:
			out.append([{"wr": &"r", "kn": &"t", "gn": &"t", "ps": &"s", "pn": &"t"}[two], 0, -1.0])
			took = 2
		if took == 0 and i + 2 == n and two in ["mb", "mn"]:
			out.append([&"m", 0, -1.0])
			took = 2
		if took > 0:
			i += took
			continue
		match c:
			"b", "m", "p":
				out.append([&"m", 0, -1.0])
			"f", "v":
				out.append([&"f", 0, -1.0])
			"t", "d", "n":
				out.append([&"t", 0, -1.0])
			"s", "z":
				out.append([&"s", 0, -1.0])
			"c":
				out.append([&"s" if nx in ["e", "i", "y"] else &"k", 0, -1.0])
			"k", "q":
				out.append([&"k", 0, -1.0])
			"g":
				out.append([&"sh" if nx in ["e", "i", "y"] and i > 0 and i + 2 < n else &"k", 0, -1.0])
			"j":
				out.append([&"sh", 0, -1.0])
			"x":
				out.append_array([[&"k", 0, -1.0], [&"s", 0, -1.0]])
			"l":
				out.append([&"l", 0, -1.0])
			"r":
				out.append([&"r", 0, -1.0])
			"w":
				if _is_vowel(nx) or nx == "y":
					out.append([&"w", 0, -1.0])
			"h":
				if _is_vowel(nx) or nx == "y":
					out.append([&"h", 0, -1.0])
			"y":
				out.append([&"y", 0, -1.0])
		i += 1
	return out


# The vowel at w[i] (with the letters after it that it takes): appends its sounds, returns how
# many letters it used.
static func _vowel(w: String, i: int, out: Array) -> int:
	var n := w.length()
	var r := w.substr(i)
	var c := w[i]
	var prev := w[i - 1] if i > 0 else ""
	var nx := w[i + 1] if i + 1 < n else ""
	var nx2 := w[i + 2] if i + 2 < n else ""
	var at_end := func(k: int) -> bool: return i + k == n
	var v := func(a: StringName, b := &"") -> void:
		out.append([a, 1, -1.0])
		if b != &"":
			out.append([b, 2, -1.0])
	var cons := func(a: StringName) -> void: out.append([a, 0, -1.0])
	for pat: Array in [["eigh", &"ae", &"iy"], ["igh", &"aa", &"ih"], ["ough", &"ao", &""], ["augh", &"ao", &""]]:
		if r.begins_with(pat[0]):
			v.call(pat[1], pat[2])
			return String(pat[0]).length()
	if r.begins_with("ear") or r.begins_with("eer") or (r == "ere"):
		v.call(&"iy")
		cons.call(&"r")
		return 3
	if r.begins_with("air") or r == "are":
		v.call(&"eh")
		cons.call(&"r")
		return 3
	if r.begins_with("oor"):
		v.call(&"ow")
		cons.call(&"r")
		return 3
	if r.begins_with("our"):
		v.call(&"aa", &"uw")
		cons.call(&"r")
		return 3
	if r.begins_with("ire"):
		v.call(&"aa", &"ih")
		cons.call(&"r")
		return 3 if at_end.call(3) or w[i + 3] in ["d", "s"] else 2
	if r.begins_with("ure"):
		v.call(&"uh")
		cons.call(&"r")
		return 3 if at_end.call(3) or w[i + 3] in ["d", "s"] else 2
	match r.substr(0, 2):
		"oo":
			v.call(&"uw")
			return 2
		"ou":
			v.call(&"aa", &"uw")
			return 2
		"ow":
			if nx2 in ["n", "l", "d"] or r.begins_with("ower") or (at_end.call(2) and n <= 3):
				v.call(&"aa", &"uw")
			else:
				v.call(&"ow")
			return 2
		"oi", "oy":
			v.call(&"ow", &"iy")
			return 2
		"oa":
			v.call(&"ow")
			return 2
		"oe":
			if at_end.call(2):
				v.call(&"ow")
				return 2
		"ee":
			v.call(&"iy")
			return 2
		"ea":
			if nx2 == "d" or r.begins_with("eath") or r.begins_with("ealth") or r.begins_with("eavy") or r.begins_with("eapon"):
				v.call(&"eh")
			else:
				v.call(&"iy")
			return 2
		"ie":
			if at_end.call(2) or (r == "ied" and n <= 5) or (r == "ies" and n <= 4):
				v.call(&"aa", &"ih")
			else:
				v.call(&"iy")
			return 2
		"ei":
			v.call(&"iy")
			return 2
		"ai", "ay":
			v.call(&"ae", &"iy")
			return 2
		"au", "aw":
			v.call(&"ao")
			return 2
		"ue", "ui":
			v.call(&"uw")
			return 2
		"ey":
			if not at_end.call(2) or n <= 4:
				v.call(&"ae", &"iy")
			else:
				v.call(&"iy")
			return 2
		"ar":
			if prev == "w" or (prev == "u" and i > 1 and w[i - 2] == "q"):
				v.call(&"ao")
			elif _is_vowel(nx2):
				v.call(&"eh")
			else:
				v.call(&"aa")
			cons.call(&"r")
			return 2 if nx2 != "r" else 3
		"or":
			v.call(&"er" if prev == "w" else &"ow")
			cons.call(&"r")
			return 2 if nx2 != "r" else 3
		"er", "ir", "ur", "yr":
			if nx2 == "r":
				v.call(&"er")
				cons.call(&"r")
				return 3
			if _is_vowel(nx2) and not (nx2 == "e" and at_end.call(3)):
				v.call({"e": &"eh", "i": &"aa", "u": &"uh", "y": &"ih"}[c])
				cons.call(&"r")
				return 2
			v.call(&"er")
			return 2
	# A single vowel: long before one consonant and a silent e ("time", "home", "makes"), else short.
	if c in ["a", "e", "i", "o", "u"] and nx != "" and not _is_vowel(nx) and not nx in ["r", "w", "x", "y"] \
			and nx2 == "e" and i + 1 < n:
		var tail := w.substr(i + 3)
		if tail in ["", "s", "d", "ly", "ness", "ful", "r"]:
			match c:
				"a":
					v.call(&"ae", &"iy")
				"e":
					v.call(&"iy")
				"i":
					v.call(&"aa", &"ih")
				"o":
					v.call(&"ow")
				"u":
					v.call(&"uw")
			return 1
	match c:
		"a":
			if r.begins_with("all") or r.begins_with("alk") or r.begins_with("alt") or r.begins_with("alm"):
				v.call(&"ao")
			elif (prev == "w" or (prev == "u" and i > 1 and w[i - 2] == "q")) and not nx in ["g", "k", "x"]:
				v.call(&"ao")
			elif n == 1:
				v.call(&"ah")
			elif at_end.call(1):
				v.call(&"aa")
			else:
				v.call(&"ae")
		"e":
			var vowel_before := false
			for k in i:
				vowel_before = vowel_before or "aeiouy".contains(w[k])
			if at_end.call(1) and vowel_before:
				# silent; after a consonant and an l, a syllable ("little", "bottle")
				if prev == "l" and i > 1 and not _is_vowel(w[i - 2]) and out.size() > 0:
					out.insert(out.size() - 1, [&"ah", 1, -1.0])
				return 1
			if at_end.call(1):
				v.call(&"iy")   # he, me, we, be, she
			elif r == "ed" and vowel_before:
				if prev in ["t", "d"]:
					v.call(&"ah")
			elif r == "es" and vowel_before:
				if prev in ["s", "x", "z", "h", "c", "g"]:
					v.call(&"ah")
			else:
				v.call(&"eh")
		"i":
			if (r.begins_with("ind") or r.begins_with("ild")) and at_end.call(3):
				v.call(&"aa", &"ih")
			else:
				v.call(&"ih")
		"o":
			if at_end.call(1):
				v.call(&"ow")
			elif r.begins_with("old") or r.begins_with("olt") or r.begins_with("oll") or (r.begins_with("ost") and prev in ["m", "p", "h"]):
				v.call(&"ow")
			else:
				v.call(&"aa")
		"u":
			if at_end.call(1):
				v.call(&"uw")
			else:
				v.call(&"ah")
		"y":
			var others := false
			for k in i:
				others = others or "aeiou".contains(w[k])
			if at_end.call(1):
				if others:
					v.call(&"iy")
				else:
					v.call(&"aa", &"ih")
			else:
				v.call(&"ih")
	return 1


# ---- timing from a recording ----

## A sound's loudness, `rate` frames a second, 0 (quiet) to 1 (its loud level: the 95th
## percentile of its frames' RMS). 8- and 16-bit PCM; anything else gives an empty envelope.
static func loudness(stream: AudioStreamWAV, rate := 100.0) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	if stream == null or not stream.format in [AudioStreamWAV.FORMAT_8_BITS, AudioStreamWAV.FORMAT_16_BITS]:
		return out
	var data := stream.data
	var bytes := 2 if stream.format == AudioStreamWAV.FORMAT_16_BITS else 1
	var channels := 2 if stream.stereo else 1
	var frames := data.size() / (bytes * channels)
	var per := maxi(int(stream.mix_rate / rate), 1)
	var n := frames / per
	out.resize(n)
	for f in n:
		var sum := 0.0
		var count := 0
		var at := f * per * bytes * channels
		# every other sample is plenty for an envelope
		for s in range(0, per, 2):
			var b := at + s * bytes * channels
			var x := float(data.decode_s16(b)) / 32768.0 if bytes == 2 else float(data.decode_s8(b)) / 128.0
			sum += x * x
			count += 1
		out[f] = sqrt(sum / maxi(count, 1))
	var sorted := out.duplicate()
	sorted.sort()
	var loud := maxf(sorted[int(sorted.size() * 0.95)] if sorted.size() > 0 else 0.0, 1e-5)
	for f in n:
		out[f] = minf(out[f] / loud, 1.0)
	return out


## The text's plan fitted to a recording's loudness (`env`, `rate` frames a second): its sounds
## spread over the recording's voiced stretch, phrase by phrase where the recording's pauses
## match the text's, and its loudness kept with it (the mouth opens with it, shuts in the quiet).
static func fit(p: Dictionary, env: PackedFloat32Array, rate: float, tu: SpeechTuning = null) -> Dictionary:
	if tu == null:
		tu = _tuning()
	if env.is_empty() or (p.segs as Array).is_empty():
		return p
	# The recording's voiced stretch, and its pauses.
	var on := PackedByteArray()
	on.resize(env.size())
	var v0 := -1
	var v1 := -1
	for f in env.size():
		on[f] = 1 if env[f] > tu.loud_gate else 0
		if on[f] == 1:
			if v0 < 0:
				v0 = f
			v1 = f
	if v0 < 0:
		return p
	var gaps := []
	var f0 := -1
	for f in range(v0, v1 + 1):
		if on[f] == 0 and f0 < 0:
			f0 = f
		elif on[f] == 1 and f0 >= 0:
			if (f - f0) / rate >= tu.loud_gap:
				gaps.append([f0 / rate, f / rate])
			f0 = -1
	var voice: Array = p.voice
	var pauses: Array = p.pauses
	var anchors := [[float(voice[0]), v0 / rate]]
	if gaps.size() == pauses.size():
		for k in gaps.size():
			anchors.append([float(pauses[k][0]), float(gaps[k][0])])
			anchors.append([float(pauses[k][1]), float(gaps[k][1])])
	anchors.append([float(voice[1]), (v1 + 1) / rate])
	var warp := func(t: float) -> float:
		if t <= float(anchors[0][0]):
			return float(anchors[0][1]) + t - float(anchors[0][0])
		for k in anchors.size() - 1:
			var a: Array = anchors[k]
			var b: Array = anchors[k + 1]
			if t <= float(b[0]):
				var u := (t - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-4)
				return lerpf(float(a[1]), float(b[1]), u)
		return float(anchors[-1][1]) + t - float(anchors[-1][0])
	var segs := []
	for s: Array in p.segs:
		var a: float = warp.call(float(s[1]))
		var b: float = warp.call(float(s[1]) + float(s[2]))
		segs.append([s[0], maxf(a, 0.0), maxf(b - a, 0.005), s[3]])
	var nods := []
	for nd: Array in p.nods:
		nods.append([warp.call(float(nd[0])), nd[1]])
	# The mouth's opening with the loudness, and a gate that shuts it in the quiet (slow, so the
	# hush of a stop's closure inside a word doesn't).
	var open := PackedFloat32Array()
	var gate := PackedFloat32Array()
	open.resize(env.size())
	gate.resize(env.size())
	var wide := maxi(int(rate * 0.08), 1)
	for f in env.size():
		open[f] = lerpf(tu.loud_floor, 1.0, clampf(env[f], 0.0, 1.0))
		var m := 0.0
		for g in range(maxi(f - wide, 0), mini(f + wide + 1, env.size())):
			m = maxf(m, env[g])
		gate[f] = smoothstep(tu.loud_gate * 0.5, tu.loud_gate * 1.5, m)
	return {"segs": segs, "nods": nods, "pauses": [], "voice": [v0 / rate, (v1 + 1) / rate],
			"seconds": (v1 + 1) / rate + 0.12, "open": open, "gate": gate, "rate": rate}


## A forced aligner's phonemes ([[start, end, "AH1"], ...], ARPAbet, a digit its stress; "sil",
## "sp" or "" quiet) as a plan: their own sounds at their own times.
static func plan_phonemes(list: Array, tu: SpeechTuning = null) -> Dictionary:
	if tu == null:
		tu = _tuning()
	const ARPA := {"AA": "aa", "AE": "ae", "AH": "ah", "AO": "ao", "AW": "aa+uw", "AY": "aa+ih", "B": "m",
		"CH": "sh", "D": "t", "DH": "th", "EH": "eh", "ER": "er", "EY": "ae+iy", "F": "f", "G": "k", "HH": "h",
		"IH": "ih", "IY": "iy", "JH": "sh", "K": "k", "L": "l", "M": "m", "N": "t", "NG": "k", "OW": "ow",
		"OY": "ow+iy", "P": "m", "R": "r", "S": "s", "SH": "sh", "T": "t", "TH": "th", "UH": "uh", "UW": "uw",
		"V": "f", "W": "w", "Y": "y", "Z": "s", "ZH": "sh"}
	var segs := []
	var nods := []
	var first := -1.0
	var last := 0.0
	var best := [-1.0, 0.0]   # this phrase's longest stressed vowel: [start, length]
	for e: Array in list:
		var a := float(e[0])
		var b := float(e[1])
		var ph := String(e[2]).to_upper()
		var stressed := ph.ends_with("1")
		ph = ph.rstrip("012")
		if not ARPA.has(ph):
			if b - a >= 0.15 and best[0] >= 0.0:
				nods.append([best[0], tu.nod_deg])
				best = [-1.0, 0.0]
			segs.append([&"_", a, b - a, 1.0])
			continue
		if first < 0.0:
			first = a
		last = b
		var parts := String(ARPA[ph]).split("+")
		var vowel := StringName(parts[0]) in VOWELS
		var gain := ((tu.stress_open if stressed else tu.weak_open) if vowel else 1.0) * tu.open
		if ph == "AH" and stressed:
			parts[0] = "aa"   # a stressed AH is "cup", open
		if parts.size() > 1:
			segs.append([StringName(parts[0]), a, (b - a) * 0.6, gain])
			segs.append([StringName(parts[1]), a + (b - a) * 0.6, (b - a) * 0.4, gain])
		else:
			segs.append([StringName(parts[0]), a, b - a, gain])
		if vowel and stressed and b - a > float(best[1]):
			best = [a, b - a]
	if best[0] >= 0.0:
		nods.append([best[0], tu.nod_deg])
	if first < 0.0:
		return {"segs": [], "nods": [], "pauses": [], "voice": [0.0, 0.0], "seconds": 0.0}
	segs.append([&"_", 0.0, first, 1.0])
	segs.append([&"_", last, 0.4, 1.0])
	return {"segs": segs, "nods": nods, "pauses": [], "voice": [first, last], "seconds": last + 0.12}
