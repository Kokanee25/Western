extends SceneTree
## Every train sound as TrainSynth makes it (step 4's synthesis), written as WAVs for
## experiments/train_lab/recordings.py to match the recordings' loudness to (train sound 2, #586).
##   godot --headless -s res://tools/train_synth_dump.gd -- [--out=build/train_rec/synth]


func _init() -> void:
	var out := "build/train_rec/synth"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	FileAccess.open(out.path_join(".gdignore"), FileAccess.WRITE)  # not the game's: no imports
	for id: StringName in TrainSynth.IDS:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(id)
		var wav: AudioStreamWAV = SynthSounds.make_train_synth(id, rng)
		wav.save_to_wav("%s/%s.wav" % [out, id])
	print("train_synth_dump: %d sounds in %s" % [TrainSynth.IDS.size(), out])
	quit()
