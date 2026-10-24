class_name MoonWindows
## Moonlight through a building's front door and windows at night (the light pass, round 2; Sean,
## #321: "a deliberate cool blue through the saloon's windows and doors at night, against the warm
## lamps"). The moon itself is low and its shadowed light hardly gets past the porch roof, so each
## opening gets a cool spot just inside it, angled down onto the floor: a pale blue pool under each
## window and across the doorway. Unshadowed (cheap: no shadow maps). Their strength follows the
## moon's (DayCycle sets it with the moon's light: DayCycleConfig moon_window_*), none by day.

const GROUP := &"moon_windows"


## The spots for building `s` (FalseFrontBuilding): the door and, if it has them, the two front
## windows, as its front wall cuts them.
static func add(s: FalseFrontBuilding) -> void:
	var holder := Node3D.new()
	holder.name = "MoonWindows"
	s.add_child(holder)
	var openings: Array[Rect2] = [s.door_rect]
	if s.front_windows:
		var w := s.width
		var f := s.floor_top
		openings.append_array([Rect2(0.55, f + 0.67, 1.1, 1.35), Rect2(w - 1.65, f + 0.67, 1.1, 1.35)])
	for o in openings:
		var spot := SpotLight3D.new()
		spot.name = "Moon%d" % holder.get_child_count()
		spot.add_to_group(GROUP)
		spot.shadow_enabled = false
		spot.light_energy = 0.0
		spot.visible = false
		spot.light_specular = 0.2
		spot.light_volumetric_fog_energy = 0.6  # a shaft in the room's haze
		# Just inside the opening's top, looking in and down, the way a low moon falls through it.
		spot.position = Vector3(o.get_center().x, o.end.y - 0.1, FalseFrontBuilding.STUD_D + 0.05)
		spot.rotation = Vector3(deg_to_rad(-38.0), PI, 0.0)
		spot.set_meta(&"width", o.size.x)
		holder.add_child(spot)


## DayCycle: every opening's spot to the moon's strength now (`share`: the moon's light over its
## full), coloured and reaching as the config says.
static func apply(tree: SceneTree, cfg: DayCycleConfig, share: float) -> void:
	var on := cfg.moon_window_energy > 0.0 and share > 0.001
	for n in tree.get_nodes_in_group(GROUP):
		var spot := n as SpotLight3D
		spot.visible = on
		if not on:
			continue
		spot.light_energy = cfg.moon_window_energy * share
		spot.light_color = cfg.moon_window_colour
		spot.spot_range = cfg.moon_window_reach
		# Wide enough for the opening at about the floor's distance.
		spot.spot_angle = clampf(rad_to_deg(atan2(float(spot.get_meta(&"width", 1.1)) * 0.6, 2.0)) + 34.0, 15.0, 80.0)
		spot.spot_attenuation = 0.8
		spot.spot_angle_attenuation = 5.0  # a soft-edged pool, not a stage spot's disc (the critic: a disc read as a bug)
