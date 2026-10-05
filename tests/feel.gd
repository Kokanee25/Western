## The feel ranges (config/feel_ranges.json): a test measures a number and asks here whether it's
## in the range Sean agreed. Out of range is a failure that says so; every number measured is also
## written to user://feel_measured.json, which CI prints after the tests.

const PATH := "res://config/feel_ranges.json"
const OUT := "user://feel_measured.json"

static var _ranges := {}
static var _started := false  # the first number this run starts the file afresh


static func range_of(key: String) -> Dictionary:
	if _ranges.is_empty():
		_ranges = (JSON.parse_string(FileAccess.get_file_as_string(PATH)) as Dictionary).ranges
	return _ranges.get(key, {})


## Check `value` against the range named `key`; true when inside it.
static func within(test: TestCase, key: String, value: float) -> bool:
	var r := range_of(key)
	if r.is_empty():
		return test.check(false, "no feel range named %s in %s" % [key, PATH])
	_record(key, value, r)
	var ok := value >= float(r.min) and value <= float(r.max)
	print("    feel %s: %.3f (agreed %s to %s)" % [key, value, r.min, r.max])
	return test.check(ok, "%s is %.3f, outside the range agreed with Sean (%s to %s, %s): if the change is meant, it needs his OK in %s" % [
			key, value, r.min, r.max, r.unit, PATH])


static func _record(key: String, value: float, r: Dictionary) -> void:
	var all := {}
	if _started and FileAccess.file_exists(OUT):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OUT))
		if parsed is Dictionary:
			all = parsed
	_started = true
	all[key] = {"value": snappedf(value, 0.001), "min": r.min, "max": r.max}
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(all, "  "))
