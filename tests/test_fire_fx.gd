extends TestCase
## How a burning member's flames are drawn (the art session's ask, docs/briefs/fire-look.md): a
## few big tongues off its top that grow as it burns, and tongues out of the top of an opening.

var world: Node3D
var fire: FireSystem
var building: Structure


func before_each() -> void:
	world = Node3D.new()
	add_child(world)
	fire = FireSystem.new()
	world.add_child(fire)
	fire.set_physics_process(false)
	building = Structure.new()
	building.structure_id = &"shed"
	building.collapses = false
	world.add_child(building)
	await physics_frames(1)


func after_each() -> void:
	world.queue_free()
	await physics_frames(2)


func _flames(fx: FireFX) -> Array[GPUParticles3D]:
	var out: Array[GPUParticles3D] = []
	for e in fx._emitters:
		if is_instance_valid(e) and e.has_meta(&"flame"):
			out.append(e)
	return out


func test_the_tongues_grow_as_it_burns_and_stay_few() -> void:
	var wall := building.add_member("wall", &"board", &"weathered_pine", Vector3(3.0, 2.4, 0.025), Vector3(0, 1.2, 0))
	building.infer_supports()
	fire.ignite(wall)
	wall.burn_time = 0.0
	var fx := FireFX.new()
	fx.member = wall
	fire.add_child(fx)
	fx.refresh(true, fire.tuning, true)
	var flames := _flames(fx)
	check(not flames.is_empty(), "it has flames")
	if flames.is_empty():
		return
	var quad := flames[0].draw_pass_1 as QuadMesh
	check(quad.size.is_equal_approx(fire.tuning.flame_size_catching), "small when it catches (%s)" % quad.size)
	for f in flames:
		check(f.amount <= fire.tuning.flames_a_member, "few tongues to a member (%d)" % f.amount)
		check(f.position.y > 1.2, "off its upper half (%.2f m up its middle at 1.2)" % f.position.y)
	wall.burn_time = fire.tuning.growth_seconds * 2.0
	fx.refresh(true, fire.tuning, true)
	check(quad.size.is_equal_approx(fire.tuning.flame_size_alight), "big once it's fully alight (%s)" % quad.size)


func test_flames_pour_out_of_the_top_of_an_opening() -> void:
	var head := building.add_member("front/door/head", &"trim", &"dark_trim", Vector3(1.2, 0.1, 0.05), Vector3(0, 2.1, 0))
	building.infer_supports()
	fire.ignite(head)
	var fx := FireFX.new()
	fx.member = head
	fire.add_child(fx)
	fx.refresh(true, fire.tuning, true)
	var below := _flames(fx).filter(func(f: GPUParticles3D) -> bool: return f.position.y < 2.1)
	check(not below.is_empty(), "tongues from under the head, out of the opening")
