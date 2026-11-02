class_name Ladder
extends Node3D
## A ladder you climb (train step 3: the boxcar's end ladders to its roof walk; any building's
## too). The node stands at the ladder's foot, on the face it's fixed to, its +Z pointing out
## from that face (the side you climb on), its rungs going up `height` metres to the top it gets
## you onto (a roof, a loft: whatever is solid behind its top, -Z).
##
## The player gets on by walking into it from below (or, at its top, walking out over the edge
## it's on) and climbs with forward and back (forward is up from below, down from the top: you
## face the way you got on); at the top he steps over onto what's behind it, at the foot he
## steps off; jump lets go. While on it he's carried with it (`Player._ladder_step`): a ladder on a
## moving car keeps him on the car. Found by group (`ladders`), few in the world.

const GROUP := &"ladders"

## Its rise, foot to top, m.
@export var height := 2.0
## Its width between the stiles, m.
@export var width := 0.45
## How fast he climbs, m/s.
@export var climb_speed := 0.9


func _ready() -> void:
	add_to_group(GROUP)


## Where a point (world) is in the ladder's frame.
func local(p: Vector3) -> Vector3:
	return global_transform.affine_inverse() * p


## The ladder to get on for someone with his feet at `feet` moving `along` (world, flat, unit),
## or null: from below, at its foot facing it; from above, at its top walking out over it.
## `from_top` is set in the returned dictionary: {ladder, from_top}.
static func reach(tree: SceneTree, feet: Vector3, along: Vector3) -> Dictionary:
	for n in tree.get_nodes_in_group(GROUP):
		var l := n as Ladder
		var p := l.local(feet)
		if absf(p.x) > l.width * 0.5 + 0.25:
			continue
		var out := l.global_basis.z
		var facing := along.dot(out)
		# At its foot: in front of it, low, walking into it.
		if p.z > -0.05 and p.z < 0.75 and p.y > -0.5 and p.y < l.height * 0.5 and facing < -0.6:
			return {"ladder": l, "from_top": false}
		# At its top: on what's behind it, near the edge, walking out over it.
		if p.z > -0.8 and p.z < 0.15 and absf(p.y - l.height) < 0.35 and facing > 0.6:
			return {"ladder": l, "from_top": true}
	return {}
