extends BridgeLab
## The sound lab's dev bridge commands (README.md beside this file). One scenario a game (the street
## keeps what a blast or a fire did), so run.py starts a fresh game for each, under Movie Maker.

const Runner := preload("res://experiments/sound_lab/runner.gd")

const HELP := {
	"sound": "sound SCENARIO [seed=N] [out=DIR] [picture] -> one sound lab scenario (it clears the town first): what the player hears as DIR/heard.wav (the end of the Master bus), every sound that began and how it was placed, voices and frame time; run under --write-movie for a game-time mix",
	"sound_list": "sound_list -> the sound lab's scenarios",
	"sound_find": "sound_find WOOD|KIND [X Y Z] -> the members of that wood (stone, iron...) or kind (glass...) nearest a point: where, how big (for placing scenarios)",
	"sound_inventory": "sound_inventory -> every AudioStreamPlayer in the tree now: its sound, owner, bus and how it's placed; the buses and their effects",
}


## run.py starts the game with `--sound-lab-dark`: nothing drawn from the start (the mix doesn't need
## it, and lavapipe takes most of a second a frame); a scenario draws one frame of its view.
func _ready() -> void:
	if "--sound-lab-dark" in OS.get_cmdline_user_args():
		RenderingServer.render_loop_enabled = false


func _cmd_sound(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": "sound SCENARIO [seed=N] [out=DIR] [picture]"}
	var r: Node = Runner.new()
	r.name = "SoundRunner"
	r.lab = self
	r.scenario = String(a[0])
	r.seed_value = int(Runner.data().get("seed", 1))
	for w: String in a.slice(1):
		var kv := w.split("=", true, 1)
		match kv[0]:
			"seed": r.seed_value = int(kv[1])
			"out": r.out_dir = kv[1]
			"picture": r.picture = true
	if r.out_dir == "":
		r.out_dir = "build/sound_lab/bridge/%s_s%d" % [r.scenario, r.seed_value]
	if not r.out_dir.is_absolute_path():
		r.out_dir = ProjectSettings.globalize_path("res://").path_join(r.out_dir)
	DirAccess.make_dir_recursive_absolute(r.out_dir.get_base_dir())
	if not FileAccess.file_exists(r.out_dir.get_base_dir().path_join(".gdignore")):
		FileAccess.open(r.out_dir.get_base_dir().path_join(".gdignore"), FileAccess.WRITE).close()
	add_child(r)
	var out: Dictionary = await r.run()
	r.queue_free()
	RenderingServer.render_loop_enabled = true  # a game left dark never finishes quitting under Movie Maker
	if not out.get("ok", true):
		return out
	log_event("sound", "%s: %.1f s heard, %d sounds began" % [r.scenario, out.seconds, out.started.size()])
	return {"wav": r.out_dir.path_join("heard.wav"), "seconds": out.seconds, "began": out.started.size(),
			"voices_max": out.voices_max, "marks": out.marks}


func _cmd_sound_find(a: Array) -> Dictionary:
	if a.is_empty():
		return {"ok": false, "error": "sound_find WOOD|KIND [X Y Z]"}
	var near := vec(a, 1) if a.size() >= 4 else Vector3.ZERO
	var found := []
	for n in street.find_children("*", "StructureMember", true, false):
		var m := n as StructureMember
		if String(m.wood) == a[0] or String(m.kind) == a[0]:
			var box := m.world_aabb()
			found.append({"id": String(m.member_id), "centre": arr(box.get_center()), "size": arr(box.size),
					"d": snappedf(box.get_center().distance_to(near), 0.01)})
	found.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x.d < y.d)
	return {"found": found.slice(0, 8), "count": found.size()}


func _cmd_sound_list(_a: Array) -> Dictionary:
	return {"scenarios": Runner.names()}


func _cmd_sound_inventory(_a: Array) -> Dictionary:
	var players := []
	for n in get_tree().root.find_children("*", "", true, false):
		if n is AudioStreamPlayer or n is AudioStreamPlayer2D or n is AudioStreamPlayer3D:
			var d := {"node": String(n.get_path()), "sound": _sound_id(n.stream), "bus": String(n.bus),
					"volume_db": n.volume_db, "playing": n.playing, "autoplay": n.autoplay}
			if n is AudioStreamPlayer3D:
				d.merge({"unit_size": n.unit_size, "max_db": n.max_db, "max_distance": n.max_distance,
						"model": n.attenuation_model, "filter_hz": n.attenuation_filter_cutoff_hz,
						"filter_db": n.attenuation_filter_db, "doppler": n.doppler_tracking, "max_polyphony": n.max_polyphony})
			players.append(d)
	var buses := []
	for b in AudioServer.bus_count:
		var fx := []
		for i in AudioServer.get_bus_effect_count(b):
			fx.append(AudioServer.get_bus_effect(b, i).get_class())
		buses.append({"name": String(AudioServer.get_bus_name(b)), "volume_db": AudioServer.get_bus_volume_db(b), "effects": fx})
	var areas := 0
	for n in get_tree().root.find_children("*", "Area3D", true, false):
		areas += 1 if (n as Area3D).reverb_bus_enabled or (n as Area3D).audio_bus_override else 0
	return {"players": players, "buses": buses, "reverb_or_bus_areas": areas, "mix_rate": AudioServer.get_mix_rate(),
			"speaker_mode": AudioServer.get_speaker_mode()}


func _sound_id(s: AudioStream) -> String:
	for k: StringName in SynthSounds._cache:
		if SynthSounds._cache[k] == s:
			return String(k)
	return s.resource_path if s else ""
