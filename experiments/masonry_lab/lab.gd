extends Node3D
## The masonry lab's scene (README; docs/briefs/masonry-lab.md): an empty slab of ground floating
## far from town, against the sky, with one masonry test piece on it (MasonryStructure from
## config/destruction/structures/). Built by the bridge's `masonry_lab`; `masonry_blast` sets a
## charge off at it.

## Where the slab is (out of town, high: nothing of the town in a view of it).
const AT := Vector3(-1500.0, 200.0, 0.0)
const SLAB := Vector3(40.0, 1.0, 40.0)
const PIECES := "res://config/destruction/structures/"

var piece: MasonryStructure
var slab: StaticBody3D
var piece_name := "wall_panel"
var seed_used := 1


## The piece built afresh (the same file and seed: the same wall). `seed_over` > 0: its walls
## expanded again with that seed instead of the file's committed elements (other walls of the same
## kind, for the lab's runs; never written back).
func build(name_: String, seed_over := 0) -> MasonryStructure:
	position = AT
	if piece != null:
		for rb in piece.rubble:
			if is_instance_valid(rb):
				rb.queue_free()
		piece.queue_free()
		piece = null
	for n in get_children():
		if n != slab:
			n.queue_free()
	if slab == null:
		slab = StaticBody3D.new()
		slab.name = "Slab"
		slab.collision_layer = Layers.WORLD
		slab.collision_mask = 0
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = SLAB
		cs.shape = box
		slab.add_child(cs)
		var mi := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = SLAB
		mi.mesh = mesh
		mi.material_override = WoodMaterials.get_material(&"stone", 7)
		slab.add_child(mi)
		slab.position = Vector3(0.0, -SLAB.y * 0.5, 0.0)  # its top the file's ground (y 0): the footing in it
		add_child(slab)
	piece_name = name_
	var path := PIECES + name_ + ".json"
	var s := MasonryStructure.from_file(path)
	seed_used = int(s.spec.get("seed", 1))
	if seed_over > 0 and seed_over != seed_used:
		s.spec.seed = seed_over
		s.spec = MasonryExpander.new().expand(s.spec, MasonryMaterials.data())
		seed_used = seed_over
	add_child(s)
	piece = s
	return s


## A point in the piece's own space (the file's: x along, y up, z in from the outer face) in the world.
func at(local: Vector3) -> Vector3:
	return piece.to_global(local) if piece != null else to_global(local)
