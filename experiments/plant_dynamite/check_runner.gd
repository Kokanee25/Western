extends Node
## The body of check.gd (a -s script compiles before the autoloads exist, so it loads this).

signal done

var SPOTS := 8
const STEP := 0.5
var FIRST := -1.0  # m along the wall from its middle board, toward the front
const TALLS := [0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9]
## A man walks through upright at this clear height; stoops through at 1.3.
const WALK := 1.7
const STOOP := 1.3

var side := "inside"
var out_path := ""
var rows: Array = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--side="):
			side = a.substr(7)
		elif a.begins_with("--spots="):
			SPOTS = int(a.substr(8))
		elif a.begins_with("--first="):
			FIRST = float(a.substr(8))
		elif a.begins_with("--out="):
			out_path = a.substr(6)
	_run.call_deferred()


func _run() -> void:
	Prof.on = true
	for k in SPOTS:
		rows.append(await _one(k))
	var walk := rows.filter(func(r: Dictionary) -> bool: return r["clear"] >= WALK).size()
	var stoop := rows.filter(func(r: Dictionary) -> bool: return r["clear"] >= STOOP).size()
	var lines := PackedStringArray()
	lines.append("side %s: walk-through (>= %.1f m) %d of %d, stoop-through (>= %.1f m) %d of %d" % [side, WALK, walk, SPOTS, STOOP, stoop, SPOTS])
	for r: Dictionary in rows:
		lines.append("  along %+.1f  stick %s  clear %.1f m  blast frame %.0f ms  top %s%s" % [r["along"], r["stick"], r["clear"], r["blast_ms"], r["top"], ("  in the way: " + r["blocking"]) if r.has("blocking") else ""])
	print("\n".join(lines))
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(JSON.stringify({"side": side, "walk": walk, "stoop": stoop, "rows": rows}, "  "))
	done.emit()


func _one(k: int) -> Dictionary:
	var along := FIRST - STEP * k
	var world := Node3D.new()
	get_tree().root.add_child(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	ground.add_child(shape)
	ground.position.y = -0.5
	world.add_child(ground)
	world.add_child(Ballistics.new())
	var store := FalseFrontBuilding.new()
	store.structure_id = &"store"
	store.build_seed = 7
	world.add_child(store)
	await _frames(3)
	var board := _side_board(store)
	var z := board.global_position.z + along
	var player: Player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	await _frames(3)
	var d := player.dynamite()
	player.select_weapon(d)
	for i in 200:
		if d.is_ready_in_hand():
			break
		await get_tree().physics_frame
	d.needs_captured_mouse = false
	if side == "inside":
		player.global_position = Vector3(0.9, store.floor_top + 0.05, z)
		player.rotation.y = PI * 0.5
	else:
		player.global_position = Vector3(-0.9, 0.05, z)
		player.rotation.y = -PI * 0.5
	player.add_look(Vector2(0.0, -35.0 - player.get_pitch_degrees()), false)
	await _frames(10)
	var row := {"along": along, "stick": "-", "clear": 0.0, "blast_ms": 0.0, "top": ""}
	_key(true)
	for i in int(Blast.t().plant_time * 60.0) + 20:
		if d.planted != null:
			break
		await get_tree().physics_frame
	var s := d.planted
	if s == null:
		push_error("nothing planted at %.1f (spot %s)" % [along, d.plant_at])
		_key(false)
		world.queue_free()
		await _frames(2)
		return row
	await _frames(10)
	row["stick"] = "(%.2f, %.2f)" % [s.global_position.x, s.global_position.y]
	_key(false)
	await _frames(2)
	# Off round the corner (out of the way of the hole's measure).
	player.global_position = Vector3(6.0 if side == "inside" else -8.0, player.global_position.y, z + 4.0)
	var went := [false]
	s.went_off.connect(func() -> void: went[0] = true)
	Prof.reset()
	var last := Time.get_ticks_usec()
	while not went[0]:
		await get_tree().process_frame
		Prof.frame()
		last = Time.get_ticks_usec()
	# The frame it went off in (detonate runs in that physics tick): this one's whole wall clock.
	await get_tree().process_frame
	var now := Time.get_ticks_usec()
	Prof.frame()
	row["blast_ms"] = (now - last) / 1000.0
	var top := PackedStringArray()
	for i in 5:
		if Prof.frame_top_names[i] != &"":
			top.append("%s %.0f" % [Prof.frame_top_names[i], Prof.frame_top_ms[i]])
	row["top"] = ", ".join(top)
	await _frames(120)
	# From the floor's height either side: from outside a man steps over the sill (which a blast
	# leaves bedded: `Blast._bedded`).
	var base := store.floor_top + 0.07
	for tall: float in TALLS:
		if _way_through(world, z, base, tall):
			row["clear"] = tall
	if row["clear"] < STOOP:
		row["blocking"] = _blocking(world, z, base, STOOP)
	world.queue_free()
	await _frames(3)
	return row


## What stands in the way of a stooping man at the hole's middle (the measure's own box).
func _blocking(world: Node3D, z: float, base: float, tall: float) -> String:
	var q := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, tall, 0.5)
	q.shape = box
	q.collision_mask = Layers.WORLD
	q.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, base + tall * 0.5, z))
	var names := PackedStringArray()
	for h: Dictionary in world.get_world_3d().direct_space_state.intersect_shape(q, 8):
		if not h.collider is RigidBody3D:
			var c: Node = h.collider
			var m: Variant = c.get_meta(&"member", null) if c.has_meta(&"member") else null
			names.append("%s%s" % [c.name, "(%s)" % m.member_id if m is StructureMember else (" <- " + str(c.get_parent().name) if c.get_parent() else "")])
	return ", ".join(names)


func _way_through(world: Node3D, z: float, base: float, tall: float) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, tall, 0.5)
	q.shape = box
	q.collision_mask = Layers.WORLD
	for k in range(-10, 11):
		q.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, base + tall * 0.5, z + k * 0.05))
		var standing := world.get_world_3d().direct_space_state.intersect_shape(q, 8).filter(
				func(h: Dictionary) -> bool: return not h.collider is RigidBody3D)
		if standing.is_empty():
			return true
	return false


func _side_board(store: FalseFrontBuilding) -> StructureMember:
	var boards: Array[StructureMember] = []
	for m in store.get_members():
		if String(m.member_id).contains("left/siding"):
			boards.append(m)
	return boards[boards.size() / 2] if not boards.is_empty() else null


func _key(down: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = &"shove"
	ev.pressed = down
	ev.strength = 1.0 if down else 0.0
	Input.parse_input_event(ev)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
