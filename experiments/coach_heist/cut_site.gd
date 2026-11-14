extends Node3D
## The coach heist lab's coach cut (#794; heist_runner's `cut` mode): the valley's bake round the cut
## (config/valley.json `heights` coach_cut, 120 m square) laid as a 1 m height field, and the game's
## CoachCut on it: the ram over the South Road, the Baron's coach driven up the grade from 40 m back,
## its pin let go `release_lead` m short of the ram's line (the swing's 1.28 s at the team's walk,
## and the seed's shift). The whole valley, its draws and its people, isn't here: the bridge's
## `ch_cut` runs it in the game.

const SPAN := 120

var cut: CoachCut
var watch: DentWatch
var drive: CoachDrive
var t := 0.0
var opts := {}


func build(o: Dictionary) -> void:
	opts = o
	var layout := ValleyLayout.main()
	var terrain := ValleyTerrain.main()
	var a: Array = layout.height(CoachCut.CUT).get("at", [400, 805])
	var c := Vector2(float(a[0]), float(a[1]))
	_ground(terrain, c)
	cut = CoachCut.new()
	cut.layout = layout
	cut.height_at = func(x: float, z: float) -> float: return terrain.height(x, z)
	cut.start_back = float(o.get("start_back", 40.0))
	cut.release_lead = float(o.get("release_lead", -1.0))
	cut.guards_n = int(o.get("guards", 4))
	add_child(cut)
	cut.begin()
	watch = cut.watch
	drive = cut.drive


func _physics_process(delta: float) -> void:
	t += delta


## The bake as a height field, SPAN m square round `c`, a cell a metre.
func _ground(terrain: ValleyTerrain, c: Vector2) -> void:
	var n := SPAN + 1
	var data := PackedFloat32Array()
	data.resize(n * n)
	var x0 := c.x - SPAN * 0.5
	var z0 := c.y - SPAN * 0.5
	for j in n:
		for i in n:
			data[j * n + i] = terrain.height(x0 + i, z0 + j)
	var hm := HeightMapShape3D.new()
	hm.map_width = n
	hm.map_depth = n
	hm.map_data = data
	var sb := StaticBody3D.new()
	sb.name = "Ground"
	sb.collision_layer = Layers.WORLD | Layers.WALK
	var cs := CollisionShape3D.new()
	cs.shape = hm
	sb.add_child(cs)
	add_child(sb)
	sb.global_position = Vector3(c.x, 0.0, c.y)


func result() -> Dictionary:
	return cut.result()
