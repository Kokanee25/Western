extends TestCase
## The flash at the muzzle of the gun in your hands (#1019): it shows on the shot, the flame gone in a
## few frames and the light a few more, timed in game time (so a stepped gun and a tool see it).

var flash: MuzzleFlash


func before_each() -> void:
	flash = MuzzleFlash.new()
	add_child(flash)


func after_each() -> void:
	flash.queue_free()


func _light() -> OmniLight3D:
	return flash.find_children("*", "OmniLight3D", false, false)[0]


func test_nothing_shows_before_a_shot() -> void:
	check(not flash.showing(), "no flame before the shot")
	check(not _light().visible, "no light before the shot")


func test_the_flame_goes_first_then_the_light() -> void:
	flash.fire()
	check(flash.showing() and _light().visible, "the shot lights it")
	var bright := _light().light_energy
	flash.step(1.0 / 60.0)
	check(flash.showing(), "the flame still there a frame on")
	check(_light().light_energy < bright, "the light already fading")
	flash.step(MuzzleFlash.FLAME_TIME)
	check(not flash.showing(), "the flame gone after FLAME_TIME")
	check(_light().visible, "the light still there after the flame")
	flash.step(MuzzleFlash.LIGHT_TIME)
	check(not _light().visible, "the light out after LIGHT_TIME")


func test_it_is_drawn_on_the_held_layer() -> void:
	for mi in flash.find_children("*", "MeshInstance3D", true, false):
		check((mi as MeshInstance3D).layers & Layers.VIS_HELD != 0, "%s on the held layer" % mi.name)
		check((mi as MeshInstance3D).layers & Layers.WORLD == 0, "%s off the world's layer (no decals)" % mi.name)
