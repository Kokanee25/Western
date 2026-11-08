class_name TunnelPortal
extends FramedStructure
## A timbered tunnel portal (the valley's west portal, where the main line leaves the map; G3,
## docs/briefs/valley-plan.md §4): two posts on sills either side of the track, a header across
## them at `height` over the rail, and lagging boards nailed across the posts above it, up to
## `face` more; behind the opening a dark mouth (not a member: the hill's ground is a height field,
## which can't have a hole, so the tunnel is a darkness the train runs into).
##
## A greybox: members as any building's (a charge splinters the posts; lose both and the header and
## lagging come down), the inside of the tunnel not made.
##
## Space: its own node's; `frame` is the rail top's middle at the portal, -Z into the tunnel, +Y up
## (TrackLine.transform_at in the node's space). `ground(x, z)` the ground's height in that space.

var frame := Transform3D.IDENTITY
## The clear opening: wide across, high over the rail top (a narrow-gauge tunnel, 15 x 18 ft).
var opening := Vector2(4.6, 5.4)
## Lagging over the header, m.
var face := 2.4
var post_size := 0.35
var ground: Callable = func(_x: float, _z: float) -> float: return 0.0

const TIMBER := &"framing"

var posts: Array[StructureMember] = []
var header: StructureMember
var lagging: Array[StructureMember] = []


func _level() -> Basis:
	var fwd := -frame.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right := fwd.cross(Vector3.UP).normalized()
	return Basis(right, Vector3.UP, -fwd)


func build() -> void:
	super.build()
	posts.clear()
	lagging.clear()
	var b := _level()
	var o := frame.origin
	var half := opening.x * 0.5 + post_size * 0.5
	var head_bottom := o.y + opening.y
	var top := head_bottom + post_size + face
	var sills: Array[StructureMember] = []
	for side in [-1.0, 1.0]:
		var p: Vector3 = o + b.x * side * half
		var g := float(ground.call(p.x, p.z))
		var sill_top := g + 0.15
		var sill := timber("sill%s" % ("l" if side < 0 else "r"), &"sill", TIMBER, Vector3(p.x, g - 0.15, p.z) - b.z * 0.6, Vector3(p.x, g - 0.15, p.z) + b.z * 0.6, 0.6, 0.3, Vector3.UP)
		var post := timber("post%s" % ("l" if side < 0 else "r"), &"post", TIMBER, Vector3(p.x, sill_top, p.z), Vector3(p.x, top, p.z), post_size, post_size, b.z)
		framed(post, sill, Vector3(p.x, sill_top, p.z))
		sills.append(sill)
		posts.append(post)
	var hc := o + Vector3.UP * (opening.y + post_size * 0.5) + b.z * post_size
	header = timber("header", &"beam", TIMBER, hc - b.x * (half + 0.4), hc + b.x * (half + 0.4), post_size, post_size, Vector3.UP)
	for p in posts:
		framed(header, p, Vector3(p.position.x, head_bottom, p.position.z))
	# Lagging across the posts' faces, from the header up.
	var board := 0.3
	var n := maxi(1, int(floor(face / board)))
	for k in n:
		var y := head_bottom + post_size + (k + 0.5) * board
		var c := Vector3(o.x, y, o.z) + b.z * (post_size * 0.5 + 0.04)
		var m := timber("lagging%02d" % k, &"board", TIMBER, c - b.x * (half + 0.6), c + b.x * (half + 0.6), board - 0.01, 0.08, b.z)
		for p in posts:
			framed(m, p, Vector3(p.position.x, y, p.position.z))
		lagging.append(m)


## The dark mouth behind the opening: a quad facing out of the tunnel, `back` m in from the posts.
func make_mouth(back := 0.6) -> MeshInstance3D:
	var b := _level()
	var mi := MeshInstance3D.new()
	mi.name = "Mouth"
	var q := QuadMesh.new()
	q.size = Vector2(opening.x + 0.1, opening.y + 1.2)
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.02, 0.018, 0.016)
	mi.material_override = m
	# QuadMesh faces +Z: turned to face back out of the tunnel (toward +b.z).
	mi.transform = Transform3D(b, frame.origin + Vector3.UP * (opening.y * 0.5 - 0.6) - b.z * back)
	return mi
