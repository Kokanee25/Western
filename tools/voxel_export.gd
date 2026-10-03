extends SceneTree
## The voxel trial, step 1 (docs/screenshots/voxel_trial/): the saloon shot's props as they are
## built in code (PropModels: the mug, the lamp's foot, collar and prongs, the bottle, and the
## shot's ashtray), each part written out as an OBJ for tools/blender/voxelise.py to cut into
## cubes. Parts keep their names (the material each wears is looked up by name again in the game).
##   godot --headless -s res://tools/voxel_export.gd -- [--out=build/voxel]

const PARTS := {
	"cup": ["Outside", "Inside", "Bottom", "Lip", "HandleTop", "HandleSide", "HandleFoot"],
	"lamp": ["Foot", "Collar", "Prong", "Prong2", "Prong3", "Prong4"],
	"bottle": ["Glass", "Base", "Cork", "Label"],
	"ashtray": ["Ashtray"],
}


func _initialize() -> void:
	var out := "build/voxel"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + out) if not out.begins_with("/") else out)
	var props := {}
	var cup := Node3D.new()
	PropModels.cup(cup)
	props["cup"] = cup
	var lamp := Node3D.new()
	PropModels.lamp(lamp)
	props["lamp"] = lamp
	var bottle := Node3D.new()
	PropModels.bottle(bottle, 0)
	props["bottle"] = bottle
	var ash := Node3D.new()
	var t := CylinderMesh.new()
	t.top_radius = 0.06
	t.bottom_radius = 0.055
	t.height = 0.025
	t.radial_segments = 10
	var ami := MeshInstance3D.new()
	ami.name = "Ashtray"
	ami.mesh = t
	ami.position = Vector3(0, 0.012, 0)
	ash.add_child(ami)
	props["ashtray"] = ash
	var manifest := {}
	for prop: String in props:
		var root: Node3D = props[prop]
		var parts := {}
		var k := 0
		# Parts are numbered in the order the prop builds them (the game matches them back by
		# that order: a duplicate like the lamp's four prongs gets no stable name).
		for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
			if mi.name == "Chimney":
				continue  # stays smooth glass
			var base := String(mi.name).trim_prefix("@MeshInstance3D@")
			if base != String(mi.name):
				base = "Dup"
			var part := "p%02d_%s" % [k, base]
			k += 1
			var path := "%s/%s_%s.obj" % [out, prop, part]
			_write_obj(mi, ProjectSettings.globalize_path("res://" + path) if not path.begins_with("/") else path)
			parts[part] = {"obj": path, "material": (mi.material_override.resource_name if mi.material_override else "")}
		manifest[prop] = parts
	var f := FileAccess.open(ProjectSettings.globalize_path("res://%s/manifest.json" % out) if not out.begins_with("/") else out + "/manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, " "))
	f.close()
	print("wrote %d props to %s" % [manifest.size(), out])
	quit()


## The mesh's triangles in the prop's space (the part's transform applied), as an OBJ.
static func _write_obj(mi: MeshInstance3D, path: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	var xf := mi.transform
	var n := 0
	for s in mi.mesh.get_surface_count():
		var arrays := mi.mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if idx.is_empty():
			for i in verts.size():
				idx.append(i)
		for v in verts:
			var p := xf * v
			f.store_line("v %f %f %f" % [p.x, p.y, p.z])
		for i in range(0, idx.size(), 3):
			f.store_line("f %d %d %d" % [n + idx[i] + 1, n + idx[i + 1] + 1, n + idx[i + 2] + 1])
		n += verts.size()
	f.close()
