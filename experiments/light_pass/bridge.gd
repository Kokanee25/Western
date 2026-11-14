extends BridgeLab
## The light pass's dev bridge commands (issues #318, #321): which lamps cast shadows, and switching
## a kind of lamp's shadows or a kind of mesh's shadow casting, to find what draws a shadow.

const HELP := {
	"lp_lamps": "lp_lamps [X Y Z R] -> every OilLamp (within R m): where, its group, lit, energy, range, shadows, the meshes within 0.4 m of its light that cast",
	"lp_lamp_shadows": "lp_lamp_shadows GROUP on|off -> shadows on or off for the lamps whose lamp_group meta is GROUP (sconce, hung, back_bar, all)",
	"lp_casters": "lp_casters NAME_PART on|off -> cast_shadow for every mesh whose name or parent's name holds NAME_PART",
}


func _lamps() -> Array:
	return get_tree().root.find_children("*", "OilLamp", true, false)


func _cmd_lp_lamps(a: Array) -> Dictionary:
	var near := a.size() >= 4
	var at := vec(a, 0) if near else Vector3.ZERO
	var r := float(a[3]) if near else 0.0
	var out := []
	for n in _lamps():
		var lamp := n as OilLamp
		var light: OmniLight3D = lamp._light
		if light == null or (near and light.global_position.distance_to(at) > r):
			continue
		var casters := []
		for mi in get_tree().root.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.visible and m.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF \
					and m.global_position.distance_to(light.global_position) < 0.4:
				casters.append("%s/%s" % [m.get_parent().name, m.name])
		out.append({"at": arr(light.global_position), "group": String(lamp.get_meta(&"lamp_group", "")),
				"parent": String(lamp.get_parent().name), "lit": lamp.lit, "energy": light.light_energy,
				"range": light.omni_range, "shadows": light.shadow_enabled, "casters": casters})
	return {"lamps": out}


func _cmd_lp_lamp_shadows(a: Array) -> Dictionary:
	if a.size() < 2:
		return {"ok": false, "error": "lp_lamp_shadows GROUP on|off"}
	var n := 0
	for l in _lamps():
		var lamp := l as OilLamp
		if lamp._light and (a[0] == "all" or String(lamp.get_meta(&"lamp_group", "")) == a[0]):
			lamp._light.shadow_enabled = a[1] == "on"
			n += 1
	return {"lamps": n}


func _cmd_lp_casters(a: Array) -> Dictionary:
	if a.size() < 2:
		return {"ok": false, "error": "lp_casters NAME_PART on|off"}
	var n := 0
	for mi in get_tree().root.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if String(m.name).contains(a[0]) or String(m.get_parent().name).contains(a[0]):
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if a[1] == "on" else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n += 1
	return {"meshes": n}
