extends BridgeLab
## The realistic men's lab (#547 step 3): switch what of the game's drawing of them is on, live, so
## each change's before and after are shot in the same moment of the same game (the saloon's people
## and lamps don't move between them). Debug builds only, as the bridge is.

const HELP := {
	"real_off": "real_off [fringe+highlight+soft|none] -> leave those of #547 step 3's changes out of every realistic man drawn now (none: all in)",
}


func _cmd_real_off(a: Array) -> Dictionary:
	var off := PackedStringArray() if a.is_empty() or String(a[0]) == "none" else String(a[0]).split("+")
	var n := 0
	for node in bridge.get_tree().get_nodes_in_group(&"people"):
		for mi in node.find_children("*", "MeshInstance3D", true, false):
			var m := (mi as MeshInstance3D).material_override as ShaderMaterial
			if m != null and PeopleBodies.is_realistic(m):
				PeopleBodies.set_real_off(m, off)
				n += 1
	await physics_frames(2)
	return {"materials": n, "off": Array(off)}
