class_name BlastSounds
## Dynamite's sound from recordings (issue #596, step 1; Sean, 2026-11-02: real recordings, no
## synthesis for the blast's layers). A blast is layers, each placed by GameAudio as any sound is
## (late by distance, the air, rooms, walls, slaps off the fronts):
##   crack   the shock's snap, heard close only;
##   boom    the body of it;
##   sub     the thump you feel, falling slowly;
##   roll    its thunder coming back off the fronts and the hills (what's heard far off);
##   debris_dirt / debris_wood / debris_glass   what it threw, pattering down for 1-3 s after;
##   groan   a building's timbers groaning as it settles.
## The recordings are sets (`assets/audio/blast/sets.json`; every file's source and licence in
## CREDITS.md); `SoundTuning.blast_set` picks one (0: the synthesised blast, the fallback), and
## `-- --blast-set=N` overrides it (the sound lab's blind clips).

const DIR := "res://assets/audio/blast/"
const LAYERS: Array[StringName] = [&"crack", &"boom", &"sub", &"roll", &"debris_dirt", &"debris_wood",
	&"debris_glass", &"groan"]

static var _sets := {}
static var _loaded := false
static var _streams := {}
static var _override := -2


## The set in play: 0 for the synthesised blast.
static func active() -> int:
	if _override == -2:
		_override = -1
		for a: String in OS.get_cmdline_user_args():
			if a.begins_with("--blast-set="):
				_override = int(a.get_slice("=", 1))
	var n := _override if _override >= 0 else GameAudio.t().blast_set
	return n if n > 0 and _set_of(n).size() > 0 else 0


## For tests and the lab: play set `n` from now on (-1: back to the dials).
static func use(n: int) -> void:
	_override = n


## The files of layer `layer` in set `n` (paths under DIR), [] if the set has none.
static func files(n: int, layer: StringName) -> Array:
	var layers: Dictionary = _set_of(n).get("layers", {})
	return layers.get(String(layer), [])


## One recording of `layer` in set `n`, the `pick`th (wrapped), or null.
static func stream(n: int, layer: StringName, pick := 0) -> AudioStream:
	var f := files(n, layer)
	if f.is_empty():
		return null
	var path := DIR + String(f[posmod(pick, f.size())])
	if not _streams.has(path):
		_streams[path] = load(path) if ResourceLoader.exists(path) else null
	return _streams[path]


## For tests: set `n` made of these streams ({layer: AudioStream}), without files.
static func inject(n: int, layers: Dictionary) -> void:
	_load()
	var names := {}
	for layer: StringName in layers:
		var path := "test_%d_%s" % [n, layer]
		names[String(layer)] = [path]
		_streams[DIR + path] = layers[layer]
	_sets[str(n)] = {"name": "test", "layers": names}


static func sets() -> Dictionary:
	_load()
	return _sets


static func _set_of(n: int) -> Dictionary:
	_load()
	return _sets.get(str(n), {})


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var path := DIR + "sets.json"
	if not FileAccess.file_exists(path):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if d is Dictionary:
		_sets = d.get("sets", {})
