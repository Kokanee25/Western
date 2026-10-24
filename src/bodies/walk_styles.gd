class_name WalkStyles
extends RefCounted
## Who walks how (Sean, 2026-10-24: five ways of walking for the town's people, all real): a man's
## walk clip by his person id, else by his body model, from `config/walks.json`
## (`{"people": {"barkeep": "walk_old"}, "models": {"old_rancher_s3_talking": "walk_old"}}`). A man
## with one plays it looped while he walks (HumanBody.walk_clip, play_clip with the clip's travel
## off: his walking moves him, the clip's rate follows his speed); a man without keeps the swinging
## gait, or the CMU walk when that experiment's on.

static var _table := {}
static var _loaded := false


static func clip_for(person_id: StringName, model: StringName) -> StringName:
	if not _loaded:
		_loaded = true
		var path := "res://config/walks.json"
		if FileAccess.file_exists(path):
			var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if d is Dictionary:
				_table = d
	var people: Dictionary = _table.get("people", {})
	if people.has(String(person_id)):
		return StringName(people[String(person_id)])
	var models: Dictionary = _table.get("models", {})
	if models.has(String(model)):
		return StringName(models[String(model)])
	return &""
