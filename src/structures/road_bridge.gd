class_name RoadBridge
extends FramedStructure
## A timber stringer bridge carrying a wagon road over a gap (the valley's Bridge B over the railway's
## cutting, G3; docs/briefs/valley-plan.md §4, §6): the deck's middle line from `deck_from` to
## `deck_to` (the deck's top), `width` wide; a **bent** at each distance in `bents_at` (posts on stone
## footings on the ground under them, a cap across), an end **sill** on the ground at each end;
## **stringers** span support to support (`stringers` lines across), **planks** across them every
## `plank_width`, a **guard** timber along each edge. The bents' lines run along `bent_dir` (a skew
## bridge's bents stand parallel to what it crosses: the track, so every post is as far from the
## rails); the end sills square across the road.
##
## A greybox: the members are real (shot, blown, burnt and analysed as any building's; a lost bent
## drops the spans it carried), the sizes plain period timber (12 x 12 in posts and caps, 8 x 16 in
## stringers, 3 in planks), no bracing or railings yet.
##
## Space: its own node's (set the node at the origin to frame it in world space). `ground(x, z)` is
## the ground's height in that space.

var deck_from := Vector3.ZERO
var deck_to := Vector3(0.0, 0.0, -20.0)
var width := 5.0
## Distances along the deck (from deck_from) of the bents.
var bents_at: Array[float] = []
## The bents' line (horizontal); zero: square across the road.
var bent_dir := Vector3.ZERO
var ground: Callable = func(_x: float, _z: float) -> float: return 0.0
var stringers := 5
var plank_width := 0.5
var plank_t := 0.08
var stringer_size := Vector2(0.2, 0.4)  # across, deep
var post_size := 0.3
var cap_size := 0.3
var footing := Vector3(0.8, 0.6, 0.8)  # across, high (half of it in the ground), along
var guard_size := Vector2(0.2, 0.2)
## Posts no further apart than this along a bent.
var post_gap := 2.6

const TIMBER := &"framing"
const STONE := &"stone"

## Built: {d, u (the bent's line), cap, posts: [member], footings: [member]} each bent; the end sills.
var bents: Array[Dictionary] = []
var sills: Array[StructureMember] = []
var stringer_list: Array[Dictionary] = []  # {member, x, a, b (d along the deck)}
var planks: Array[StructureMember] = []


func _along() -> Vector3:
	var v := deck_to - deck_from
	v.y = 0.0
	return v.normalized()


func _across() -> Vector3:
	return _along().cross(Vector3.UP).normalized()


func length() -> float:
	var v := deck_to - deck_from
	v.y = 0.0
	return v.length()


## The deck's top at d along it.
func deck_y(d: float) -> float:
	return lerpf(deck_from.y, deck_to.y, clampf(d / maxf(length(), 0.001), 0.0, 1.0))


## A point at d along the deck, x across it (+ to its right), at height y.
func at(d: float, x: float, y: float) -> Vector3:
	var p := deck_from + _along() * d + _across() * x
	p.y = y
	return p


## Where the stringer line x across meets the support line through d along u: its d.
func _meet(d: float, u: Vector3, x: float) -> float:
	var ua := u.dot(_across())
	if absf(ua) < 0.05:
		return d
	return d + x * u.dot(_along()) / ua


func _under(d: float) -> float:
	return deck_y(d) - plank_t - stringer_size.y


func build() -> void:
	super.build()
	bents.clear()
	sills.clear()
	stringer_list.clear()
	planks.clear()
	var along := _along()
	var across := _across()
	var total := length()
	var half_w := width * 0.5
	var xs: Array[float] = []
	for k in stringers:
		xs.append(lerpf(-half_w + 0.4, half_w - 0.4, float(k) / maxf(stringers - 1, 1)))
	# Supports, in order along the deck: the end sills square across, the bents along bent_dir.
	var stations: Array[Dictionary] = []
	stations.append({"d": 0.0, "u": across, "end": true})
	var ds := bents_at.duplicate()
	ds.sort()
	for d: float in ds:
		var u := bent_dir
		u.y = 0.0
		u = across if u.length() < 1e-4 else u.normalized()
		if u.dot(across) < 0.0:
			u = -u
		stations.append({"d": d, "u": u, "end": false})
	stations.append({"d": total, "u": across, "end": true})
	# Each support's member (the cap or the sill) carries the stringers.
	for i in stations.size():
		var st: Dictionary = stations[i]
		var d: float = st.d
		var u: Vector3 = st.u
		var under := _under(d)
		if st.end:
			var g := float(ground.call(at(d, 0.0, 0.0).x, at(d, 0.0, 0.0).z))
			var bottom := minf(g - 0.2, under - 0.3)
			var c := at(d + (0.25 if i == 0 else -0.25), 0.0, (bottom + under) * 0.5)
			var sill := timber("sill%d" % (0 if i == 0 else 1), &"sill", TIMBER, c - across * (half_w + 0.3), c + across * (half_w + 0.3), 0.5, under - bottom, Vector3.UP)
			sills.append(sill)
			st.member = sill
			continue
		var ua := absf(u.dot(across))
		var half := (half_w + 0.3) / maxf(ua, 0.2)
		var cy := under - cap_size * 0.5
		var mid := at(d, 0.0, cy)
		var cap := timber("bent%d/cap" % i, &"cap", TIMBER, mid - u * (half + 0.3), mid + u * (half + 0.3), cap_size, cap_size, Vector3.UP)
		var n := maxi(3, ceili(2.0 * half / post_gap) + 1)
		var bent := {"d": d, "u": u, "cap": cap, "posts": [], "footings": []}
		var top := under - cap_size
		for k in n:
			var p := mid + u * lerpf(-half, half, float(k) / (n - 1))
			var g := float(ground.call(p.x, p.z))
			var foot_top := g + footing.y * 0.5
			var fc := Vector3(p.x, g, p.z)
			var fm := timber("bent%d/footing%d" % [i, k], &"pier", STONE, fc - u * footing.x * 0.5, fc + u * footing.x * 0.5, footing.z, footing.y, Vector3.UP)
			var post := timber("bent%d/post%d" % [i, k], &"post", TIMBER, Vector3(p.x, foot_top, p.z), Vector3(p.x, top, p.z), post_size, post_size, u)
			framed(post, fm, Vector3(p.x, foot_top, p.z))
			framed(cap, post, Vector3(p.x, top, p.z))
			(bent.posts as Array).append(post)
			(bent.footings as Array).append(fm)
		bents.append(bent)
		st.member = cap
	# Stringers, support to support, each line across.
	for i in stations.size() - 1:
		var s0: Dictionary = stations[i]
		var s1: Dictionary = stations[i + 1]
		for k in xs.size():
			var x := xs[k]
			var a := _meet(float(s0.d), s0.u, x)
			var b := _meet(float(s1.d), s1.u, x)
			var ya := _under(a) + stringer_size.y * 0.5
			var yb := _under(b) + stringer_size.y * 0.5
			var m := timber("span%d/stringer%d" % [i, k], &"stringer", TIMBER, at(a, x, ya), at(b, x, yb), stringer_size.x, stringer_size.y, Vector3.UP)
			framed(m, s0.member, at(a, x, _under(a)))
			framed(m, s1.member, at(b, x, _under(b)))
			stringer_list.append({"member": m, "x": x, "a": a, "b": b})
	# Planks across, on every stringer under them.
	var n_planks := maxi(1, int(floor(total / plank_width)))
	var pw := total / n_planks
	for j in n_planks:
		var d := (j + 0.5) * pw
		var y := deck_y(d) - plank_t * 0.5
		var plank := timber("plank%03d" % j, &"floor_board", TIMBER, at(d, -half_w, y), at(d, half_w, y), pw - 0.01, plank_t, Vector3.UP)
		planks.append(plank)
		for sd: Dictionary in stringer_list:
			if d >= minf(sd.a, sd.b) - pw * 0.5 and d <= maxf(sd.a, sd.b) + pw * 0.5:
				framed(plank, sd.member, at(d, float(sd.x), deck_y(d) - plank_t))
	# Guards along each edge, a few metres each, on the planks under them.
	var seg := 5.0
	for side in [-1.0, 1.0]:
		var x: float = side * (half_w - guard_size.x * 0.5)
		var d0 := 0.0
		var g := 0
		while d0 < total - 0.01:
			var d1 := minf(d0 + seg, total)
			var y0 := deck_y(d0) + guard_size.y * 0.5
			var y1 := deck_y(d1) + guard_size.y * 0.5
			var gm := timber("guard%s%02d" % ["l" if side < 0 else "r", g], &"guard", TIMBER, at(d0, x, y0), at(d1, x, y1), guard_size.x, guard_size.y, Vector3.UP)
			for j in planks.size():
				var dj := (j + 0.5) * pw
				if dj >= d0 and dj <= d1:
					framed(gm, planks[j], at(dj, x, deck_y(dj)))
			d0 = d1
			g += 1


## The lowest underside of anything over the point (x, z) (the clearance under it), or INF.
func underside_over(p: Vector3, reach := 0.5) -> float:
	var low := INF
	for m in get_members():
		if m.kind == &"pier" or m.kind == &"post" or m.kind == &"sill":
			continue
		var box := m.structure_aabb()
		if p.x >= box.position.x - reach and p.x <= box.end.x + reach and p.z >= box.position.z - reach and p.z <= box.end.z + reach:
			low = minf(low, box.position.y)
	return low
