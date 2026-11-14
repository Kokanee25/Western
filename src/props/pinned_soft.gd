class_name PinnedSoft
## A soft body with pinned points (the mop's head on its handle, the rag in a hand) and what falls
## on it. Pinned points are moved by the prop each tick (Jolt doesn't hold them), so to the physics
## they're points of no give: a falling body that meets them takes an impulse the solver can't
## settle, and goes NaN or is flung off the map (test_chaos found it: rubble from a blast landing on
## the barkeep's mop). Loose things that move (rubble, glass shards and pieces, chips) pass through
## the soft body instead; it still lies on the floor, the bar and its bucket, and on people.


## From now on, every moving loose body that comes into the tree passes through `soft` (owned by
## `owner`; its own bodies are left alone).
static func keep_clear(soft: SoftBody3D, owner: Node) -> void:
	var tree := owner.get_tree()
	if tree == null or soft == null:
		return
	var take := func(n: Node) -> void:
		if not is_instance_valid(soft) or not soft.is_inside_tree():
			return
		if _falls(n, owner):
			soft.add_collision_exception_with(n as PhysicsBody3D)
	for n in tree.get_nodes_in_group(&"rubble") + tree.get_nodes_in_group(&"glass_shards"):
		take.call(n)
	tree.node_added.connect(take)
	owner.tree_exiting.connect(func() -> void:
		if tree.node_added.is_connected(take):
			tree.node_added.disconnect(take), CONNECT_ONE_SHOT)


static func _falls(n: Node, owner: Node) -> bool:
	if not (n is RigidBody3D) or owner.is_ancestor_of(n):
		return false
	var rb := n as RigidBody3D
	if rb.freeze or (rb.collision_layer & (Layers.WORLD | Layers.DEBRIS)) == 0:
		return false  # a prop standing (frozen), a man's parts (BODY_PARTS): it meets those
	var p := rb.get_parent()
	return not (p != null and (p.is_in_group(&"mop_buckets") or p.is_in_group(&"mops")))
