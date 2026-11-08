extends SceneTree
## Expand a masonry structure file's walls into its elements and joints, written back into the file
## (config/destruction/structures/FORMAT.md, "The expander"; MasonryExpander). Commit the result:
## the expanded form is what carries to another engine.
##
##   godot --headless -s res://tools/masonry_expand.gd -- res://config/destruction/structures/wall_panel.json [--check]
##
## --check: write nothing; exit 1 if the file's expanded form isn't what its walls and seed give.


func _init() -> void:
	var paths: Array[String] = []
	var check := false
	for a in OS.get_cmdline_user_args():
		if a == "--check":
			check = true
		else:
			paths.append(a)
	var bad := 0
	for path in paths:
		var spec: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not spec is Dictionary:
			push_error("%s doesn't parse" % path)
			bad += 1
			continue
		var out: Dictionary = MasonryExpander.new().expand(spec, MasonryMaterials.data())
		var text: String = MasonryExpander.to_text(out)
		if check:
			if FileAccess.get_file_as_string(path) != text:
				print("%s: its expanded form is stale (run without --check)" % path)
				bad += 1
			else:
				print("%s: up to date (%d elements, %d joints)" % [path, out.elements.size(), out.joints.size()])
		else:
			var f := FileAccess.open(path, FileAccess.WRITE)
			f.store_string(text)
			f.close()
			print("%s: %d elements, %d joints" % [path, out.elements.size(), out.joints.size()])
	quit(1 if bad > 0 else 0)
