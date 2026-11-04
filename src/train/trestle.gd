class_name Trestle
extends TrackChunk
## A timber viaduct carrying the line over a gorge (the trestle lab, #623; docs/briefs/trestle.md):
## the tallest structure in the game, one Structure of members with one support graph, at rest as
## any building's members are (batched, each its body alone) until something touches it.
##
## It's a TrackChunk over its stretch of the line, so its ties and rails are the line's (the track's
## state reads them, a charge splinters a tie or tears a rail loose, a train over a gap derails), and
## under them, built from the route's crossing and the ground under it (TrestleTuning, all proposed):
##
##   - a **bent** across the line every panel (`bent_spacing`), from the ground under it up to the
##     deck: a stone **pier**, a **mud sill** on it, then **stories** of posts counted down from the
##     **cap** (so a story's top is at the same height in every bent and the girts run level), an
##     **intermediate sill** between stories; the outer posts battered (the bent widens toward the
##     ground), the inner pair plumb under the rails, more plumb lines where the bent is wide;
##     **X sway bracing** on both faces of every story;
##   - **girts** and **longitudinal X braces** bent to bent along the outer post lines, every story;
##   - on the caps, **stringers** in two chords a rail, each two panels long, the chords' joints a
##     panel apart (lose one bent and half the stringers over it span it, twice as far; lose two side
##     by side and none do); stone **abutments** at the rims under their ends;
##   - the line's **ties** on the stringers, its **rails** on the ties, a **guard timber** over the
##     ties' ends each side.
##
## The links are known from how it's framed (what bears on what, and where), so the support graph
## isn't searched (thousands of members by pairs); StructuralAnalysis works the loads down it as
## any building's: posts in compression and buckling, caps, sills, stringers and girts in bending,
## a member left on one support held only by its nails.
##
## The train loads it (`carry`): each truck's share of its car's weight on the rails under its
## axles (StructureMember.extra_points), worked out again every `load_every` ticks where it changed.
## When the deck goes from under any truck on it, the train leaves the rails there (Train.leave_rails,
## kind `fell`: TrainWreck hands the cars to Jolt with their momentum, no derail kick).
##
## Space: the TrackLine's, as every chunk's. `crossing_id`: the route's name for it.

var tt: TrestleTuning
var crossing_id := ""
## The panel points along the line: s of the abutment, each bent, the far abutment.
var panel_s: PackedFloat64Array = PackedFloat64Array()
## Each bent: {s, cap, mud, pier, stories: [{top, bottom, posts: [member], lines: [x]}], height}.
var bents: Array[Dictionary] = []
## The abutments' members (start, end).
var abutments: Array[StructureMember] = []
## The stringers: {member, side, chord, u, v (panel indices)}.
var stringers: Array[Dictionary] = []
var guards: Array[StructureMember] = []
## Members by what they are, for the lab and the tests.
var counts := {}
## [member, support, point (structure space)] as framed, and [member, member] touching too.
var _links: Array = []
var _touch: Array = []
## The loads the train put on the rails last: rail id -> PackedVector2Array.
var _loaded := {}
var _load_tick := 0
## What it cost to work the train's loads out: us, analyses, members re-worked.
var load_cost := {"us": 0, "updates": 0, "settles": 0}

const PIER_WOOD := &"stone"
const TIMBER := &"framing"


func setup_crossing(on_line: TrackLine, t: TrainTuning, tune: TrestleTuning, n: int, a: float, b: float, id: String) -> void:
	setup(on_line, t, n, a, b)
	tt = tune
	crossing_id = id
	name = "Trestle_%s" % id
	build_seed = 623 + n


func _ready() -> void:
	super._ready()
	# Its rubble lands on the gorge's floor, far below the town's ground.
	var lowest := 0.0
	for b in bents:
		lowest = minf(lowest, float(b.ground))
	lost_below = to_global(Vector3(0.0, lowest - 10.0, 0.0)).y
	Events.member_broken.connect(func(id: StringName) -> void:
		if String(id).begins_with(String(structure_id) + "/"):
			_intact_stale = true)


func build() -> void:
	_intact_stale = true
	super.build()  # the ties and rails, along the line as any chunk's
	if tt == null:
		tt = load("res://config/trestle.tres")
	_links.clear()
	_touch.clear()
	_by_chord.clear()
	bents.clear()
	abutments.clear()
	stringers.clear()
	guards.clear()
	counts = {}
	var n := maxi(1, roundi((to_s - from_s) / tt.bent_spacing))
	var sp := (to_s - from_s) / n
	panel_s.resize(n + 1)
	for i in n + 1:
		panel_s[i] = from_s + sp * i
	# The caps' tops (the stringers' bottoms) at each panel point.
	var caps: Array[StructureMember] = []
	caps.resize(n + 1)
	abutments.append(_abutment(0))
	caps[0] = abutments[0]
	for i in range(1, n):
		var bent := _bent(i)
		bents.append(bent)
		caps[i] = bent.cap
	abutments.append(_abutment(n))
	caps[n] = abutments[1]
	for i in range(0, bents.size() - 1):
		_tie_bents(bents[i], bents[i + 1], i + 1)
	_deck(caps)
	for m: StructureMember in _order:
		counts[m.kind] = int(counts.get(m.kind, 0)) + 1


# --- Geometry ------------------------------------------------------------------------------------

## The frame of a panel point: origin on the line's middle at the rail top, x across (level), z along
## (level, toward the line's start: the bent's faces), y up.
func _frame(s: float) -> Transform3D:
	var f := line.transform_at(s)
	var across := Vector3(f.basis.x.x, 0.0, f.basis.x.z).normalized()
	var along := across.cross(Vector3.UP).normalized()
	return Transform3D(Basis(across, Vector3.UP, along), f.origin)


## The stringers' tops (the ties' bottoms) at s, structure space y.
func _deck_y(s: float) -> float:
	return line.transform_at(s).origin.y - train_tuning.rail_size.y - train_tuning.tie_size.y


func _ground_at(p: Vector3) -> float:
	return float(line.ground_y.call(p.x, p.z))


## A squared timber from a to b (structure space), `width` across and `depth` toward `up_hint`.
func _timber(path: String, kind: StringName, wood: StringName, a: Vector3, b: Vector3, width: float, depth: float, up_hint := Vector3.UP) -> StructureMember:
	var dir := b - a
	var length := dir.length()
	dir /= maxf(length, 1e-6)
	var y := (up_hint - dir * up_hint.dot(dir))
	if y.length() < 1e-4:
		y = Vector3.FORWARD - dir * Vector3.FORWARD.dot(dir)
	y = y.normalized()
	var x := y.cross(dir).normalized()
	return add_member(path, kind, wood, Vector3(width, depth, length), (a + b) * 0.5, Basis(x, y, dir))


func _framed(m: StructureMember, support: StructureMember, at: Vector3) -> void:
	_links.append([m, support, at])


# --- The bents -----------------------------------------------------------------------------------

## The outer posts' half spread at height y, for a bent whose posts' tops are at `top`.
func _half(top: float, y: float) -> float:
	return tt.top_width * 0.5 + tt.batter * maxf(top - y, 0.0)


func _bent(i: int) -> Dictionary:
	var s := panel_s[i]
	var f := _frame(s)
	var across := f.basis.x
	var along := f.basis.z
	var at := func(x: float, y: float) -> Vector3: return Vector3(f.origin.x, y, f.origin.z) + across * x
	var tag := "bent%03d" % i
	var cap_top := _deck_y(s) - tt.stringer.y
	var top := cap_top - tt.cap.y  # the posts' tops
	var ground := _ground_at(f.origin)
	var pier_top := ground + tt.pier_above
	var foot := pier_top + tt.sill.y  # the bottom posts' feet, on the mud sill
	var height := top - foot
	var bent := {"s": s, "index": i, "stories": [], "height": cap_top - ground, "ground": ground}
	var half_top := _half(top, top)
	bent.cap = _timber("%s/cap" % tag, &"cap", TIMBER, at.call(-half_top - tt.overhang, cap_top - tt.cap.y * 0.5),
			at.call(half_top + tt.overhang, cap_top - tt.cap.y * 0.5), tt.cap.x, tt.cap.y, Vector3.UP)
	if height < 0.3:
		# Too short for posts: the cap is on the pier (raised to meet it).
		pier_top = top
		bent.mud = null
		bent.pier = _pier(tag, at, ground, pier_top, half_top, along)
		_framed(bent.cap, bent.pier, at.call(0.0, pier_top))
		return bent
	# The stories, counted down from the cap: each `story` high with a sill between, the last one
	# taking what's over (at least `min_story`).
	var per := tt.story + tt.sill.y
	var n := maxi(1, int(floor((height + tt.sill.y) / per)))
	var heights: Array[float] = []
	for k in n:
		heights.append(tt.story)
	var left := height - (n * tt.story + (n - 1) * tt.sill.y)
	if left >= tt.min_story + tt.sill.y:
		heights.append(left - tt.sill.y)
	else:
		heights[n - 1] += left
	var y := top
	var above: StructureMember = bent.cap
	var above_lines: Array = []
	for k in heights.size():
		var h: float = heights[k]
		var bot := y - h
		var lines := _post_lines(top, y)
		var posts: Array[StructureMember] = []
		for x: float in lines:
			var x_top := x
			var x_bot := x
			if absf(absf(x) - _half(top, y)) < 0.01:
				x_bot = signf(x) * _half(top, bot)  # the outer posts lean out
			var p := _timber("%s/s%02d/post%+.1f" % [tag, k, x], &"post", TIMBER, at.call(x_bot, bot), at.call(x_top, y), tt.post, tt.post, along)
			posts.append(p)
			# What's above bears on it at its top.
			_framed(above, p, at.call(x_top, y))
		var story_d := {"top": y, "bottom": bot, "posts": posts, "lines": lines}
		# The sill under this story: on the next story's posts (or the pier, at the bottom).
		var sill_y := bot - tt.sill.y * 0.5
		var half_bot := _half(top, bot)
		var sill := _timber("%s/s%02d/sill" % [tag, k], &"bent_sill" if k < heights.size() - 1 else &"sill", TIMBER,
				at.call(-half_bot - tt.overhang, sill_y), at.call(half_bot + tt.overhang, sill_y), tt.sill.x, tt.sill.y, Vector3.UP)
		story_d.sill = sill
		for p in posts:
			_framed(p, sill, p.transform * Vector3(0.0, 0.0, -p.size.z * 0.5))
		# X sway bracing on both faces, outer post top to the opposite outer post's foot.
		var braces: Array[StructureMember] = []
		for face in [-1.0, 1.0]:
			var off: Vector3 = along * face * (tt.post * 0.5 + tt.brace.x * 0.5)
			for d in [-1.0, 1.0]:
				var a: Vector3 = at.call(-d * _half(top, y) , y - 0.2) + off
				var b: Vector3 = at.call(d * half_bot, bot + 0.2) + off
				var br := _timber("%s/s%02d/brace%s%s" % [tag, k, "f" if face > 0 else "b", "r" if d > 0 else "l"], &"brace", TIMBER, a, b, tt.brace.y, tt.brace.x, along)
				braces.append(br)
				# On the posts it's bolted to: the outer pair at its ends.
				_framed(br, posts[0] if d > 0 else posts[posts.size() - 1], a)
				_framed(br, posts[posts.size() - 1] if d > 0 else posts[0], b)
		story_d.braces = braces
		(bent.stories as Array).append(story_d)
		above = sill
		above_lines = lines
		y = bot - tt.sill.y
	bent.mud = above
	bent.pier = _pier(tag, at, ground, pier_top, _half(top, foot), along)
	_framed(above, bent.pier, at.call(0.0, pier_top))
	return bent


## The post lines across a story whose top is at y: the outer pair (battered), the inner pair (plumb),
## and plumb lines every `post_gap` out where there's room. Ordered left to right.
func _post_lines(top: float, y: float) -> Array:
	var half := _half(top, y)
	var xs := [tt.inner_x]
	var x := tt.inner_x + tt.post_gap
	while x < half - tt.post_gap * 0.5:
		xs.append(x)
		x += tt.post_gap
	xs.append(half)
	var out := []
	for i in range(xs.size() - 1, -1, -1):
		out.append(-float(xs[i]))
	for v in xs:
		out.append(float(v))
	return out


func _pier(tag: String, at: Callable, ground: float, top: float, half: float, along: Vector3) -> StructureMember:
	var w := half * 2.0 + tt.overhang * 2.0 + tt.pier_margin * 2.0
	var bottom := ground - tt.pier_depth
	var p := _timber("%s/pier" % tag, &"pier", PIER_WOOD, at.call(-w * 0.5, (top + bottom) * 0.5), at.call(w * 0.5, (top + bottom) * 0.5),
			tt.sill.x + tt.pier_margin * 2.0, top - bottom, Vector3.UP)
	return p


## Girts and longitudinal braces between bents a and b (panel `i` the second's), story by story along
## the outer post lines, where both have that story.
func _tie_bents(a: Dictionary, b: Dictionary, i: int) -> void:
	var sa: Array = a.stories
	var sb: Array = b.stories
	for k in mini(sa.size(), sb.size()):
		var ka: Dictionary = sa[k]
		var kb: Dictionary = sb[k]
		var pa: Array = ka.posts
		var pb: Array = kb.posts
		for side in [0, 1]:
			var post_a: StructureMember = pa[0] if side == 0 else pa[pa.size() - 1]
			var post_b: StructureMember = pb[0] if side == 0 else pb[pb.size() - 1]
			var out_a := _outward(post_a, a)
			var out_b := _outward(post_b, b)
			# The girt just under the story's top (the sill above it), on the posts' outside faces.
			var y_a: float = float(ka.top) - 0.25
			var y_b: float = float(kb.top) - 0.25
			var ga := _on_post(post_a, y_a) + out_a * (tt.post * 0.5 + tt.brace.x + tt.girt.x * 0.5)
			var gb := _on_post(post_b, y_b) + out_b * (tt.post * 0.5 + tt.brace.x + tt.girt.x * 0.5)
			var g := _timber("girt%03d/s%02d/%s" % [i, k, "l" if side == 0 else "r"], &"girt", TIMBER, ga, gb, tt.girt.x, tt.girt.y, Vector3.UP)
			_framed(g, post_a, ga)
			_framed(g, post_b, gb)
			if not tt.long_braces:
				continue
			var bot := maxf(float(ka.bottom), float(kb.bottom)) + 0.3
			for d in [0, 1]:
				var p0 := _on_post(post_a, y_a if d == 0 else bot) + out_a * (tt.post * 0.5 + tt.brace.x * 0.5)
				var p1 := _on_post(post_b, bot if d == 0 else y_b) + out_b * (tt.post * 0.5 + tt.brace.x * 0.5)
				var br := _timber("girt%03d/s%02d/x%s%d" % [i, k, "l" if side == 0 else "r", d], &"brace", TIMBER, p0, p1, tt.brace.y, tt.brace.x, out_a)
				_framed(br, post_a, p0)
				_framed(br, post_b, p1)


## The point on a post's axis at height y.
func _on_post(p: StructureMember, y: float) -> Vector3:
	var ax := p.transform.basis.z.normalized()
	var o := p.transform.origin
	return o + ax * ((y - o.y) / maxf(ax.y, 1e-4))


## Out from the bent's middle toward the post's side, level.
func _outward(p: StructureMember, bent: Dictionary) -> Vector3:
	var f := _frame(float(bent.s))
	var x := (p.transform.origin - f.origin).dot(f.basis.x)
	return f.basis.x * signf(x)


# --- The ends and the deck -----------------------------------------------------------------------

func _abutment(i: int) -> StructureMember:
	var s := panel_s[i]
	var f := _frame(s)
	var top := _deck_y(s) - tt.stringer.y
	var half := maxf(tt.top_width * 0.5 + tt.overhang, train_tuning.tie_size.x * 0.5 + 0.3)
	var c := Vector3(f.origin.x, top - tt.abutment.y * 0.5, f.origin.z)
	# Its body reaches back onto the rim, away from the gorge.
	c += f.basis.z * (tt.abutment.x * 0.5 if i == 0 else -tt.abutment.x * 0.5)
	return _timber("abutment%d" % (0 if i == 0 else 1), &"pier", PIER_WOOD, c - f.basis.x * half, c + f.basis.x * half,
			tt.abutment.x, tt.abutment.y, Vector3.UP)


func _deck(caps: Array[StructureMember]) -> void:
	var n := panel_s.size() - 1
	var t := train_tuning
	var rail_x := t.gauge * 0.5 + t.rail_size.x * 0.5
	var chords: Array[float] = []
	for side in [-1.0, 1.0]:
		for c in [-1.0, 1.0]:
			chords.append(side * rail_x + c * tt.stringer.x * 0.5)
	var by_chord: Array = []
	for q in chords.size():
		var list: Array[Dictionary] = []
		var x: float = chords[q]
		# Joints broken: every other chord starts a panel in.
		var u := 0
		var first := tt.stringer_panels - 1 if q % 2 == 1 else tt.stringer_panels
		var len_now := mini(first, n) if first > 0 else mini(tt.stringer_panels, n)
		while u < n:
			var v := mini(u + len_now, n)
			var sa := panel_s[u]
			var sb := panel_s[v]
			var fa := _frame(sa)
			var fb := _frame(sb)
			var ya := _deck_y(sa) - tt.stringer.y * 0.5
			var yb := _deck_y(sb) - tt.stringer.y * 0.5
			var a := Vector3(fa.origin.x, ya, fa.origin.z) + fa.basis.x * x - fa.basis.z * (0.005 if u > 0 else -0.3)
			var b := Vector3(fb.origin.x, yb, fb.origin.z) + fb.basis.x * x + fb.basis.z * (0.005 if v < n else -0.3)
			var m := _timber("str/%d/%03d" % [q, u], &"stringer", TIMBER, a, b, tt.stringer.x, tt.stringer.y, Vector3.UP)
			for w in range(u, v + 1):
				var fw := _frame(panel_s[w])
				_framed(m, caps[w], Vector3(fw.origin.x, _deck_y(panel_s[w]) - tt.stringer.y, fw.origin.z) + fw.basis.x * x)
			var d := {"member": m, "chord": q, "x": x, "u": u, "v": v, "a": sa, "b": sb}
			list.append(d)
			stringers.append(d)
			u = v
			len_now = tt.stringer_panels
		by_chord.append(list)
	# The ties on the stringers under them.
	for pair: Array in ties:
		var tie: StructureMember = pair[0]
		var s: float = pair[1]
		var f := _frame(s)
		for list: Array in by_chord:
			for d: Dictionary in list:
				if s >= float(d.a) - 0.001 and s <= float(d.b) + 0.001:
					var at := Vector3(f.origin.x, _deck_y(s), f.origin.z) + f.basis.x * float(d.x)
					_framed(tie, d.member, at)
					break
	# Guard timbers over the ties' ends, a panel each, each side.
	for i in n:
		for side in [-1.0, 1.0]:
			var sa := panel_s[i] + 0.01
			var sb := panel_s[i + 1] - 0.01
			var fa := line.transform_at(sa)
			var fb := line.transform_at(sb)
			var up_a := fa.basis.y
			var a: Vector3 = fa.origin + fa.basis.x * side * tt.guard_x + up_a * (-t.rail_size.y + tt.guard.y * 0.5)
			var b: Vector3 = fb.origin + fb.basis.x * side * tt.guard_x + fb.basis.y * (-t.rail_size.y + tt.guard.y * 0.5)
			var g := _timber("guard/%s/%03d" % ["l" if side < 0 else "r", i], &"guard", TIMBER, a, b, tt.guard.x, tt.guard.y, Vector3.UP)
			guards.append(g)
			for pair: Array in ties:
				var ts: float = pair[1]
				if ts >= sa and ts <= sb:
					var ft := line.transform_at(ts)
					_framed(g, pair[0], ft.origin + ft.basis.x * side * tt.guard_x + ft.basis.y * (-t.rail_size.y))


## The links as framed (no search): supports, the members resting on each, touching both ways; the
## rails on their ties and joint to joint as any chunk's; the piers and abutments on the ground;
## stack order by how many supports down to the ground each is.
func infer_supports() -> void:
	invalidate_analysis()
	_by_stack.clear()
	for m in _order:
		m.supported_by.clear()
		m.dependents.clear()
		m.support_points.clear()
		m.support_boxes.clear()
		m.touching.clear()
		m.analysis_cache = {}
		m.grounded = m.kind == &"pier"
	for l: Array in _links:
		var m: StructureMember = l[0]
		var s: StructureMember = l[1]
		if s == null or m == null:
			continue
		if not m.supported_by.has(s.member_id):
			m.supported_by.append(s.member_id)
			s.dependents.append(m.member_id)
			m.support_points[s.member_id] = l[2]
			m.touching.append(s.member_id)
			s.touching.append(m.member_id)
	for l: Array in _touch:
		(l[0] as StructureMember).touching.append((l[1] as StructureMember).member_id)
		(l[1] as StructureMember).touching.append((l[0] as StructureMember).member_id)
	# Rails on the ties under them (TrackChunk's rule), joint to joint.
	var t := train_tuning
	var by_side := {-1: [], 1: []}
	for r: Dictionary in rails:
		var m: StructureMember = r.member
		(by_side[r.side] as Array).append(m)
		for pair: Array in ties:
			var ts: float = pair[1]
			if ts < float(r.a) - 0.001 or ts > float(r.b) + 0.001:
				continue
			var tie: StructureMember = pair[0]
			var at := line.transform_at(ts) * Vector3(float(r.side) * (t.gauge * 0.5 + t.rail_size.x * 0.5), -t.rail_size.y, 0.0)
			m.supported_by.append(tie.member_id)
			tie.dependents.append(m.member_id)
			m.support_points[tie.member_id] = at
			m.touching.append(tie.member_id)
			tie.touching.append(m.member_id)
	for side in by_side:
		var list: Array = by_side[side]
		for i in list.size() - 1:
			(list[i] as StructureMember).touching.append((list[i + 1] as StructureMember).member_id)
			(list[i + 1] as StructureMember).touching.append((list[i] as StructureMember).member_id)
	# Stack order: a member after everything it rests on.
	var depth := {}
	for m in _order:
		_depth_of(m, depth)
	for m in _order:
		m.stack_key = float(depth[m.member_id]) + m.position.y * 1e-4


func _depth_of(m: StructureMember, depth: Dictionary) -> int:
	var id := m.member_id
	if depth.has(id):
		return int(depth[id])
	# (Iterative down long chains would be safer; the deepest is ~40 links.)
	depth[id] = 0
	var d := 0
	for s in m.supported_by:
		var o := get_member(s)
		if o:
			d = maxi(d, _depth_of(o, depth) + 1)
	depth[id] = d
	return d


# --- The train on it -----------------------------------------------------------------------------

## The train's weight on the deck under its trucks' axles now (called each physics tick by the
## train; worked out every `load_every`). Returns true if the loads changed.
func carry(train: Train) -> bool:
	_load_tick += 1
	if _load_tick % maxi(1, tt.load_every) != 0:
		return false
	# While the fire's queue is bringing it down a slice a frame (a blast's collapse), or its first
	# look isn't done, the loads wait (they're put on next time).
	var fire := FireSystem.find(get_tree()) if is_inside_tree() else null
	if fire and (fire.settling(self) or not _analysis_valid or (last_analysis != null and last_analysis.left() > 0)):
		if not _analysis_valid:
			fire.queue_check(self)
		return false
	var u := Time.get_ticks_usec()
	var want := {}
	var sim := train.sim
	if sim != null and train.derail.is_empty():
		var g := 9.81
		for i in sim.cars.size():
			var car: Dictionary = sim.cars[i]
			var half: float = tt.engine_axle_half if String(car.kind) in ["engine", "tender"] else tt.axle_half
			for w in 2:
				var truck := sim.truck_s(i, w)
				var each := float(car.mass) * g * 0.5 / 4.0  # a truck's share, on two axles, two rails
				for ax in [-half, half]:
					_put(want, truck + float(ax), each)
					_rails_give(truck + float(ax))
	elif train.wreck != null:
		# Off the rails: the cars still on the deck weigh on it where they lie (a car's weight at a
		# quarter of its length either side of its middle, half on each rail).
		var w := train.wreck
		var inv := line.global_transform.affine_inverse()
		for i in w.bodies.size():
			var rb := w.body(i)
			if rb == null:
				continue
			var local := inv * rb.global_position
			if local.y < line.lowest - 3.0:
				continue  # gone down (the curve's nearest point is ~1-2 ms a body)
			var s := line.curve.get_closest_offset(local)
			if s < from_s or s > to_s:
				continue
			var p := line.point_at(s)
			if local.y < p.y - 3.0 or local.y > p.y + 4.0 or Vector2(local.x - p.x, local.z - p.z).length() > 2.5:
				continue  # fallen off it, or not on it
			var car: Dictionary = train.sim.cars[int(w.bodies[i].car)]
			var quarter := float(car.length) * (0.25 if w.bodies[i].part == "whole" else 0.12)
			var each := rb.mass * 9.81 / 4.0
			for d in [-quarter, quarter]:
				_put(want, s + float(d), each)
				_rails_give(s + float(d))
	Prof.add(&"trestle_want", Time.get_ticks_usec() - u)
	var changed := false
	for id in _loaded:
		if not want.has(id):
			var m := get_member(id)
			if m and not m.broken:
				m.extra_points = PackedVector2Array()
				mark_dirty(id)
			changed = true
	for id in want:
		var m := get_member(id)
		if m == null or m.broken:
			continue
		if _loaded.has(id) and _same(_loaded[id], want[id]):
			continue  # (standing still: nothing to work out again)
		m.extra_points = want[id]
		mark_dirty(id)
		changed = true
	var leaving := not _loaded.is_empty() and want.is_empty()
	_loaded = want
	if changed:
		load_cost.updates += 1
		# A load-only change: the deck and the caps worked out again, not the bents under caps with
		# nothing broken in them (an intact bent works at a few per cent under the engine: the
		# test holds it); once the train's off the bridge, everything it moved over is caught up.
		if not leaving:
			closure_stop = _intact_caps()
		var broke := _settle_load()
		closure_stop = {}
		if leaving:
			for b in bents:
				if not _intact.has((b.cap as StructureMember).member_id):
					mark_dirty((b.cap as StructureMember).member_id)
			settle_soon()
		if not broke.is_empty():
			load_cost.settles += 1
	load_cost.us += Time.get_ticks_usec() - u
	return changed


## A load-only change settled here and now, round by round (an update of the few dozen members
## under the train), not through the fire's queue (it would throw its job away at every update);
## once something's coming down, the rest goes to the queue a slice a frame.
func _settle_load() -> Array[StringName]:
	var changed: Array[StringName] = []
	if not is_inside_tree() or not collapses:
		return changed
	for round_ in 6:
		var t_a := Prof.start()
		var a := start_analysis()
		Prof.stop(&"trestle_start", t_a)
		var t_v := Prof.start()
		a.advance(a.left())
		Prof.stop(&"trestle_advance", t_v)
		Prof.stop(&"trestle_analyse", t_a)
		load_cost["set"] = maxi(int(load_cost.get("set", 0)), a.last_set)
		load_cost["seeds"] = maxi(int(load_cost.get("seeds", 0)), a.last_seeds)
		var t_r := Prof.start()
		var more := apply_round(a, changed)
		Prof.stop(&"trestle_apply", t_r)
		if not more:
			return changed
	settle_soon()
	return changed


## `newtons` on each rail at s (an axle's share of a rail), straight onto the two stringer chords
## under that rail where they're still there (the rail and its ties spread it a tie or two: the
## stringers' usual load for sizing them; the ties and rails aren't checked themselves).
func _put(want: Dictionary, s: float, newtons: float) -> void:
	if s < from_s or s > to_s:
		return
	if only_weak and not _weak_panels().has(_panel_of(s)):
		return  # sound: the train can't break it there (test_a_crossing_breaks_nothing holds it)
	var p := line.transform_at(s).origin
	for side in [0, 1]:
		var under: Array[StructureMember] = []
		for q in [side * 2, side * 2 + 1]:
			var m := _stringer_at(q, s)
			if m != null:
				under.append(m)
		for m in under:
			var t_along := (p - m.position).dot(m.axis())
			var list: PackedVector2Array = want.get(m.member_id, PackedVector2Array())
			list.append(Vector2(t_along, newtons / under.size()))
			want[m.member_id] = list


## Chord q's standing stringer over s, or null.
func _stringer_at(q: int, s: float) -> StructureMember:
	if _by_chord.is_empty():
		for d: Dictionary in stringers:
			(_by_chord.get_or_add(int(d.chord), []) as Array).append(d)
	for d: Dictionary in _by_chord.get(q, []):
		if s >= float(d.a) - 0.001 and s <= float(d.b) + 0.001:
			var m: StructureMember = d.member
			if not m.broken:
				return m
	return null


var _by_chord := {}


## A rail over s with no ties under it for `rail_span` m about s (the deck gone from under it) can't
## carry a wheel there: the iron bows down and tears off its spikes (TrackChunk.tear_loose), so
## whatever's on it goes down with it. Empty, it hangs on its joints as any chunk's.
func _rails_give(s: float) -> void:
	if s < from_s or s > to_s:
		return
	var half := tt.rail_span * 0.5
	var i := _tie_index(s - half)
	var any := false
	while i < ties.size() and float(ties[i][1]) <= s + half:
		var tie: StructureMember = ties[i][0]
		if is_instance_valid(tie) and not tie.broken:
			return  # held there
		any = true
		i += 1
	if not any:
		return
	for side in [-1, 1]:
		var r := rail_at(side, s)
		if r != null and not r.broken:
			tear_loose(r, Vector3.DOWN)


## The first tie at or after s.
func _tie_index(s: float) -> int:
	var lo := 0
	var hi := ties.size()
	while lo < hi:
		var mid := (lo + hi) / 2
		if float(ties[mid][1]) < s:
			lo = mid + 1
		else:
			hi = mid
	return lo


## The panel s is in (0: abutment to the first bent).
func _panel_of(s: float) -> int:
	var i := panel_s.bsearch(s)
	return clampi(i - 1, 0, panel_s.size() - 2)


## Damaged at all: broken, holed, carved, charred.
static func _hurt(m: StructureMember) -> bool:
	return m.broken or not m.holes.is_empty() or m.voxels != null or m.char_depth > 0.001


## The panels where the deck is weakened: either side of a bent with anything in it damaged (two
## either side: a two-panel stringer over it), and those a damaged stringer or cap spans. Only
## there does the train's weight go into the analysis (`only_weak`); on a sound deck it can't break
## anything (worked out at the engine's worst place by the test), so nothing's worked out.
var only_weak := true
var _weak := {}


func _weak_panels() -> Dictionary:
	if _intact_stale:
		_intact_caps()
	return _weak


## The caps of the bents with nothing in them damaged (kept till something is), and the weakened panels.
var _intact := {}
var _intact_stale := true


func _intact_caps() -> Dictionary:
	if not _intact_stale:
		return _intact
	_intact_stale = false
	_intact = {}
	_weak = {}
	var n := panel_s.size() - 1
	var mark := func(a: int, b: int) -> void:
		for p in range(maxi(a, 0), mini(b, n - 1) + 1):
			_weak[p] = true
	for b in bents:
		var whole := not _hurt(b.cap)
		if whole:
			for st: Dictionary in b.stories:
				for p: StructureMember in st.posts:
					if _hurt(p):
						whole = false
						break
				if not whole or _hurt(st.sill):
					whole = false
					break
				for br: StructureMember in st.braces:
					if br.broken:
						whole = false
						break
				if not whole:
					break
		if whole:
			_intact[(b.cap as StructureMember).member_id] = true
		else:
			var i := int(b.index)
			mark.call(i - 2, i + 1)
	for d: Dictionary in stringers:
		if _hurt(d.member):
			mark.call(int(d.u) - 1, int(d.v))
	return _intact


func _on_member_damaged(m: StructureMember) -> void:
	super._on_member_damaged(m)
	_intact_stale = true


static func _same(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if not a[i].is_equal_approx(b[i]):
			return false
	return true


## The deck gone from under a truck on it: the stretch (the track's state's) at s, or {}.
func gone_under(s: float) -> Dictionary:
	if s < from_s or s > to_s or line.state == null:
		return {}
	for st: Dictionary in line.state.at(s):
		if st.kind == &"broken":
			return st
	return {}


# --- Falling in sections -------------------------------------------------------------------------

## A tall piece (a bent's tower above a cut) can't stand on what's left under it: `fold_after` s
## after it starts to fall (about a story's drop) it goes over as a unit, its bracing holding it
## together as it falls, turning about its foot one way (seeded by what it is) and gravity doing the
## rest; it comes apart in sections when it lands lying (or hits the next bent, and breaks that).
## Left alone, it would land on the stubs and rubble under its feet and sleep there standing, a 60 m
## stack of sections with the deck on it.
func _enter_rubble(rb: RigidBody3D) -> void:
	# A piece falls a hair smaller than it was framed (each box 2 cm less each way): framed face to
	# face with what still stands beside it, it wedged there at deck height, was held still by
	# RubbleSleep, and the engine came to rest on it over a 19 m hole.
	for c in rb.get_children():
		if c is CollisionShape3D and (c as CollisionShape3D).shape is BoxShape3D:
			var box := BoxShape3D.new()
			box.size = ((c as CollisionShape3D).shape as BoxShape3D).size - Vector3(0.02, 0.02, 0.02)
			box.size = box.size.max(Vector3(0.01, 0.01, 0.01))
			(c as CollisionShape3D).shape = box
	super._enter_rubble(rb)
	if tt == null:
		return
	var ids: Array = rb.get_meta(&"members", [])
	if ids.size() <= tt.section_members:
		return
	var lo := INF
	var hi := -INF
	for id in ids:
		var m := get_member(id)
		if m:
			lo = minf(lo, m.global_position.y)
			hi = maxf(hi, m.global_position.y)
	if hi - lo > tt.story * 1.5 and is_inside_tree():
		get_tree().create_timer(tt.fold_after, false, true).timeout.connect(_topple.bind(rb))


## The piece's shapes' lowest and highest points, world y, and their middle.
static func _extent(rb: RigidBody3D) -> Array:
	var lo := INF
	var hi := -INF
	var mid := Vector3.ZERO
	var n := 0
	for c in rb.get_children():
		if c is CollisionShape3D:
			var p := (c as CollisionShape3D).global_position
			lo = minf(lo, p.y)
			hi = maxf(hi, p.y)
			mid += p
			n += 1
	return [lo, hi, mid / maxf(n, 1)]


## Over it goes (once), across the line, one way or the other by a seed: turning about the edge of
## its foot with `fold` times the turn it needs to tip past it (a tower 60 m high and ~20 m wide at
## its foot stands on its stumps without; along the line it would lean on the next bent, which
## stands: a falling tower pushing its neighbours over is for later). Gravity does the rest.
func _topple(o: Variant) -> void:
	# (Untyped: the timer can fire after the piece has broken up and been freed.)
	if not is_instance_valid(o) or not o is RigidBody3D:
		return
	var rb := o as RigidBody3D
	if rb.is_queued_for_deletion() or rb.get_meta(&"toppled", false) or rb.get_meta(&"broken_up", false):
		return
	rb.set_meta(&"toppled", true)
	var e := _extent(rb)
	var mid: Vector3 = e[2]
	var local := line.global_transform.affine_inverse() * mid
	var f := line.global_transform.basis * line.transform_at(line.curve.get_closest_offset(local)).basis
	var across := Vector3(f.x.x, 0.0, f.x.z).normalized()
	var ids: Array = rb.get_meta(&"members", [])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(ids[0]) if not ids.is_empty() else "piece")
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	var d := across * side
	# Its half width across (to the shapes' middles) and its middle's height over its foot.
	var b := 0.5
	for c in rb.get_children():
		if c is CollisionShape3D:
			b = maxf(b, absf(((c as CollisionShape3D).global_position - mid).dot(across)))
	var hc := maxf(mid.y - float(e[0]), 0.5)
	var pivot := Vector3(mid.x, float(e[0]), mid.z) + d * b
	# Just enough to bring its middle over the edge: the rise sqrt(b^2 + hc^2) - hc, against its
	# turning about the edge (a block's: k^2 = (4 hc^2 + 4 b^2) / 3).
	var rise := sqrt(b * b + hc * hc) - hc
	var k2 := (4.0 * hc * hc + 4.0 * b * b) / 3.0
	var w_min := sqrt(2.0 * 9.81 * rise / k2)
	var w := Vector3.UP.cross(d) * (w_min * tt.fold)
	rb.sleeping = false
	rb.angular_velocity += w
	rb.linear_velocity += w.cross(mid - pivot)


## A falling piece of it that lands hard comes apart into sections of at most `section_members`
## members (by where they are in it: a story of a bent, a span of the deck), never every timber.
func _break_up(rb: RigidBody3D) -> void:
	if not is_instance_valid(rb) or rb.get_meta(&"broken_up", false):
		return
	if tt and not rb.get_meta(&"toppled", false):
		var ex := _extent(rb)
		if float(ex[1]) - float(ex[0]) > tt.story * 1.5 and (rb.get_meta(&"members", []) as Array).size() > tt.section_members:
			_topple(rb)  # standing: it goes over first, and breaks up where it lands lying
			return
	var ids: Array = rb.get_meta(&"members", [])
	var limit := maxi(1, tt.section_members if tt else 24)
	if ids.size() <= limit:
		rb.set_meta(&"broken_up", true)  # small enough: it stays one piece
		return
	var rest := RubbleRest.for_node(rb)
	if rest:
		rest.release(rb)
	rb.set_meta(&"broken_up", true)
	var v := rb.linear_velocity
	var w := rb.angular_velocity
	var meshes: Array[MeshInstance3D] = []
	var shapes: Array[CollisionShape3D] = []
	for c in rb.get_children():
		if c is MeshInstance3D:
			meshes.append(c)
		elif c is CollisionShape3D:
			shapes.append(c)
	var n := mini(meshes.size(), shapes.size())
	# Cells of a story by a panel, in the piece's own space, members kept together in each.
	var cell := Vector3(maxf(tt.bent_spacing, 4.0), maxf(tt.story, 4.0), maxf(tt.bent_spacing, 4.0))
	var groups := {}
	for i in n:
		var p := shapes[i].position
		var key := Vector3i(floori(p.x / cell.x), floori(p.y / cell.y), floori(p.z / cell.z))
		(groups.get_or_add(key, []) as Array).append(i)
	var keys := groups.keys()
	keys.sort()
	for key in keys:
		var list: Array = groups[key]
		var k := 0
		while k < list.size():
			var part := list.slice(k, k + limit)
			k += limit
			var part_ids: Array[StringName] = []
			for i: int in part:
				part_ids.append(ids[i] if i < ids.size() else &"")
			var piece := _new_rubble(part_ids)
			piece.set_meta(&"broken_up", true)
			piece.global_transform = shapes[part[0]].global_transform
			var mass := 0.0
			for i: int in part:
				meshes[i].reparent(piece, true)
				shapes[i].reparent(piece, true)
				var m := get_member(ids[i] if i < ids.size() else &"")
				mass += maxf(m.weight(tuning) / 9.81, 0.3) if m else 1.0
			piece.mass = maxf(mass, 0.3)
			piece.linear_velocity = v + w.cross(piece.global_position - rb.global_position)
			piece.angular_velocity = w
	rubble.erase(rb)
	rb.queue_free()


## How it stands, for the lab: members by kind, bents, the tallest, panels.
func report() -> Dictionary:
	var tallest := 0.0
	var stories := 0
	for b in bents:
		tallest = maxf(tallest, float(b.height))
		stories += (b.stories as Array).size()
	return {"id": crossing_id, "members": member_count(), "kinds": counts, "bents": bents.size(),
		"panels": panel_s.size() - 1, "length": to_s - from_s, "tallest": snappedf(tallest, 0.01),
		"stories": stories, "stringers": stringers.size()}


# --- Saving the wreck ----------------------------------------------------------------------------

## The crossing's frame in the world: its middle on the line (the save keeps the rubble in it, so a
## re-laid route's bridge has its wreck where its own gorge is).
func crossing_frame() -> Transform3D:
	return line.global_transform * line.transform_at((from_s + to_s) * 0.5)


## What a save keeps of it (CLAUDE.md "Saving": the difference from the authored town): the members
## broken (by their paths, not the chunk's number, so a re-laid route finds them), and where its
## rubble lies, in the crossing's frame.
func save_dict() -> Dictionary:
	var prefix := String(structure_id) + "/"
	var d := to_dict()
	var broken := []
	for id: String in d.broken:
		broken.append(id.trim_prefix(prefix))
	var inv := crossing_frame().affine_inverse()
	var pieces := []
	for rb in rubble:
		if not is_instance_valid(rb):
			continue
		var ids := []
		for id in rb.get_meta(&"members", []):
			ids.append(String(id).trim_prefix(prefix))
		var t := inv * rb.global_transform
		pieces.append({"members": ids, "origin": [t.origin.x, t.origin.y, t.origin.z],
			"basis": [t.basis.x.x, t.basis.x.y, t.basis.x.z, t.basis.y.x, t.basis.y.y, t.basis.y.z, t.basis.z.x, t.basis.z.y, t.basis.z.z]})
	return {"crossing": crossing_id, "broken": broken, "rubble": pieces}


## A save put back on a freshly built viaduct: each saved piece of rubble made again of its members
## where it lay, asleep; the members broken and lost (no piece) taken away; nothing thrown or heard.
## A member snapped in two lies whole where its first half lay. Returns the members it couldn't find.
func restore_dict(d: Dictionary) -> int:
	var prefix := String(structure_id) + "/"
	var missed := 0
	var frame := crossing_frame()
	var placed := {}
	var laid: Array = []  # [body, transform]
	for p: Dictionary in d.get("rubble", []):
		var ids: Array[StringName] = []
		for path in p.members:
			var id := StringName(prefix + String(path))
			var m := get_member(id)
			if m == null:
				missed += 1
				continue
			if placed.has(id) or m.broken:
				continue
			placed[id] = true
			ids.append(id)
		if ids.is_empty():
			continue
		var before := rubble.size()
		_drop(ids)
		var o: Array = p.origin
		var b: Array = p.basis
		var t := frame * Transform3D(Basis(Vector3(b[0], b[1], b[2]), Vector3(b[3], b[4], b[5]), Vector3(b[6], b[7], b[8])), Vector3(o[0], o[1], o[2]))
		for k in range(before, rubble.size()):
			var rb := rubble[k]
			if is_instance_valid(rb):
				rb.global_transform = t
				rb.linear_velocity = Vector3.ZERO
				rb.angular_velocity = Vector3.ZERO
				rb.set_meta(&"broken_up", true)
				rb.sleeping = true
				laid.append([rb, t])
	# Broken and lost: gone.
	var gone: Array[StringName] = []
	for path in d.get("broken", []):
		var id := StringName(prefix + String(path))
		var m := get_member(id)
		if m == null:
			missed += 1
		elif not m.broken and not placed.has(id):
			gone.append(id)
	if not gone.is_empty():
		var before := rubble.size()
		_drop(gone)
		for k in range(rubble.size() - 1, before - 1, -1):
			var rb := rubble[k]
			rubble.remove_at(k)
			if is_instance_valid(rb):
				rb.queue_free()
	invalidate_analysis()
	settle_soon()
	# (`_drop` wakes what's near and wakes it again a frame on: laid back where they lay, asleep.)
	_lay_asleep.call_deferred(laid)
	return missed


func _lay_asleep(laid: Array) -> void:
	for pair: Array in laid:
		var rb := pair[0] as RigidBody3D
		if is_instance_valid(rb):
			rb.global_transform = pair[1]
			rb.linear_velocity = Vector3.ZERO
			rb.angular_velocity = Vector3.ZERO
			rb.sleeping = true
