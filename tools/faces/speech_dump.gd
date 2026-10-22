extends SceneTree
## Every line the brains say (their LINES), as FaceSpeech plans them: JSON to --out (for
## tools/faces/speech_check.py, which holds them against espeak-ng's phonemes).
##   godot --headless -s res://tools/faces/speech_dump.gd -- --out=build/faces/speech_plans.json [--text="a line"]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "build/faces/speech_plans.json"
	var lines := []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--text="):
			lines.append(a.substr(7))
	if lines.is_empty():
		for path: String in ["res://src/bodies/outlaw_brain.gd", "res://src/people/civilian_brain.gd"]:
			var table: Dictionary = load(path).LINES
			for k: StringName in table:
				for l: String in table[k]:
					var t := l.format({"name": "Brody"})
					if not t in lines:
						lines.append(t)
		lines.append_array(["Hhhk— hhk—", "Nnngh! Nnnh!"])
	var fs = load("res://src/bodies/face_speech.gd")
	var res := []
	for l: String in lines:
		var p: Dictionary = fs.plan(l)
		var words := []
		var re := RegEx.create_from_string("[A-Za-z']+")
		for m in re.search_all(l):
			var w := m.get_string().to_lower().replace("'", "")
			var ws: Dictionary = fs.word_sounds(w)
			words.append({"word": w, "sounds": (ws.sounds as Array).map(func(s: Array) -> String: return String(s[0])), "stress": ws.stress})
		res.append({"text": l, "seconds": p.seconds, "voice": p.voice, "nods": p.nods, "words": words,
				"segs": (p.segs as Array).map(func(s: Array) -> Array: return [String(s[0]), s[1], s[2], s[3]])})
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(res, " "))
	f.close()
	print("speech_dump: %d lines -> %s" % [res.size(), out])
	quit()
