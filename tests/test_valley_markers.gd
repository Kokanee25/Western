extends TestCase
## The valley's greybox markers (docs/briefs/valley-plan.md §12 G4, #720): every place in
## config/valley.json on its ground, from the file: the marks on the ground (ValleyMarks: pads,
## roads, fords, beds), a block for each building volume, Bridge A on its log crib and the town
## bridge over the creek, the roads' grades over the bake within the plan's rules, and the dev
## bridge's `goto` and `valley_view` reaching every place and viewpoint.

const TEST_PORT := 18747

var holder: Node
var valley: ValleyWorld
var bridge: DevBridge


## The valley built once for the file (it's freed with the case, after its last test).
func before_each() -> void:
	if holder != null:
		return
	holder = Node.new()
	holder.name = "Main"
	add_child(holder)
	valley = load("res://scenes/valley.tscn").instantiate()
	holder.add_child(valley)
	await physics_frames(3)


func after_each() -> void:
	pass


func _markers() -> ValleyMarkers:
	return valley.markers


func test_the_marks_on_the_ground() -> void:
	var m := ValleyMarks.main()
	var lay := ValleyLayout.main()
	check_eq(m.kinds.size(), ValleyTerrain.main().width * ValleyTerrain.main().depth, "a kind for every bake point")
	check(m.build_ms < 2000.0, "painted in %.0f ms" % m.build_ms)
	check_eq(m.at(0.0, 0.0), ValleyMarks.STREET, "the crossroads is street")
	check_eq(m.at(-60.0, 8.0), ValleyMarks.STREET, "Main Street across its width")
	check_eq(m.at(1200.0, 270.0), ValleyMarks.WAGON, "the East Road")
	check_eq(m.at(200.0, 250.0), ValleyMarks.LANE, "Harlan's lane")
	for f: Dictionary in ValleyMarks.fords(lay):
		var c: Vector2 = f.at
		check_eq(m.at(c.x, c.y), ValleyMarks.FORD, "the ford on %s" % f.road)
	# Every pad outlined: its edge is outline, its middle pad (or a road through it).
	for p: Dictionary in lay.places():
		var pad: Dictionary = p.get("pad", {})
		if pad.is_empty() or pad.has("heading"):
			continue
		var c := ValleyLayout.xz(p.at)
		for e: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			var half := (float(pad.w) if e.x != 0.0 else float(pad.d)) * 0.5
			var found := false
			for k in 4:
				var q := c + e * (half - 0.3 - 0.6 * k)
				found = found or m.at(q.x, q.y) == ValleyMarks.OUTLINE
			check(found, "%s's pad outlined on its %s edge" % [p.id, e])
	var census := m.census()
	for k in ["pad", "water", "street", "wagon", "lane", "track", "path", "ford", "outline"]:
		check(int(census.get(k, 0)) > 0, "some %s (%s)" % [k, census.get(k, 0)])
	# The valley's drawn ground takes them.
	var ground := valley.get_node(^"Ground") as Ground
	check(ground.valley.marks == m, "the drawn ground tinted by them")


func test_a_block_for_every_building_volume() -> void:
	var mk := _markers()
	var lay := ValleyLayout.main()
	var want := 0
	for l: Dictionary in lay.town_buildings():
		if not l.has("spec"):
			want += 1  # (a lot with its building's spec has that building, not a block: #765)
	for ex: Dictionary in lay.town().get("extras", []):
		if ex.has("w"):
			want += 1
	for p: Dictionary in lay.places():
		if p.has("block"):
			want += 1
	for hp: Dictionary in lay.heights():
		want += (hp.get("blocks", []) as Array).size()
	check_eq(mk.blocks.size(), want, "a block each (the town's buildings, the extras with a size, the places with a block, the heights' blocks)")
	check_eq(mk.body.get_child_count(), want, "each a box in the blocks' body")
	var front := 20.1 * 0.5
	for b: Dictionary in mk.blocks:
		var c: Vector3 = b.centre
		var size: Vector3 = b.size
		for p in ValleyMarkers._footprint(b.map, b.wd, float(b.heading)):
			var g := ValleyTerrain.main().height(p.x, p.y)
			# (A height's low blocks, a log deck or a stock tank, stand their own `h` over it: #736 B.)
			check(c.y < g and c.y + size.y > g + (0.5 if b.kind == "height" else 4.0), "%s stands from under the ground to over it at its corner (%.1f..%.1f, ground %.1f)" % [b.id, c.y, c.y + size.y, g])
		if b.kind == "lot":
			# Off Main Street and the North-South Street: fronts on the street's edge.
			check(absf(c.z) - size.z * 0.5 >= front - 0.01, "%s behind the fronts" % b.id)
			check(absf(c.x) - size.x * 0.5 >= 7.6 - 0.01, "%s off the North-South Street" % b.id)
	# None stands on a road: every road's strip (its width, the town's streets too) clear of them.
	var roads: Array = lay.roads().duplicate()
	roads.append_array(ValleyMarks.town_streets(lay))
	for r: Dictionary in roads:
		var half := float(r.get("width", 2.0)) * 0.5
		var line := ValleyLayout.xz_line(r.line)
		for b: Dictionary in mk.blocks:
			var inv := ValleyMarkers._block_basis(float(b.heading)).inverse()
			var size: Vector3 = b.size
			var hit := ""
			for i in range(1, line.size()):
				var n := ceili(line[i - 1].distance_to(line[i]))
				for k in n + 1:
					var q := line[i - 1].lerp(line[i], float(k) / maxi(n, 1))
					var l := inv * (Vector3(q.x, 0.0, q.y) - (b.centre as Vector3))
					if absf(l.x) < size.x * 0.5 + half - 0.05 and absf(l.z) < size.z * 0.5 + half - 0.05:
						hit = "(%.0f, %.0f)" % [q.x, q.y]
			check(hit == "", "%s's block is off %s (crossed at %s)" % [b.id, r.id, hit])
	# A ray down onto a block meets its roof.
	var saloon: Dictionary = mk.blocks.filter(func(b: Dictionary) -> bool: return b.id == "saloon")[0]
	var top: Vector3 = saloon.centre + Vector3(0.0, saloon.size.y, 0.0)
	var hit := valley.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(top + Vector3.UP * 20.0, top - Vector3.UP * 5.0, Layers.WORLD))
	check(not hit.is_empty() and absf(hit.position.y - top.y) < 0.05, "the saloon's block is solid (its roof at %.2f)" % top.y)


func test_bridge_a_on_its_crib_and_the_town_bridge() -> void:
	var mk := _markers()
	var ter := ValleyTerrain.main()
	var lay := ValleyLayout.main()
	for id in ["bridge_a", "bridge_t"]:
		var br: RoadBridge = mk.road_bridges().get(id)
		check(br != null and br.member_count() > 30, "%s built as members (%d)" % [id, br.member_count() if br else 0])
		if br == null:
			continue
		var b := lay.bridge(id)
		check_near(br.deck_from.y, float(b.deck_y), 0.001, "%s's deck at the plan's %.1f" % [id, float(b.deck_y)])
		var mid := (br.deck_from + br.deck_to) * 0.5
		check(Vector2(mid.x, mid.z).distance_to(ValleyLayout.xz(b.at)) < 4.0, "%s where the plan has it (%.0f, %.0f)" % [id, mid.x, mid.z])
		check(absf(br.length() - float(b.span)) < 4.0, "%s about its %.0f m span (%.1f)" % [id, float(b.span), br.length()])
		var low := INF
		for k in 9:
			var p := br.deck_from.lerp(br.deck_to, (k + 1) / 10.0)
			low = minf(low, ter.height(p.x, p.z))
		check(br.deck_from.y - low > 2.5, "%s over the creek: %.1f m to its bed" % [id, br.deck_from.y - low])
		var along := (br.deck_to - br.deck_from)
		along.y = 0.0
		along = along.normalized()

		check(br.members_without_load_path().is_empty(), "%s stands: every member has its load path" % id)
	print("    ", mk.report())
	# Every road bridge (Bridge B's too) meets its approaches within a step at both ends, across its
	# width: a man walks onto the planks (Player steps 0.3 m at most).
	for id: String in mk.road_bridges():
		var br: RoadBridge = mk.road_bridges()[id]
		var along := br.deck_to - br.deck_from
		along.y = 0.0
		along = along.normalized()
		var across := along.cross(Vector3.UP)
		for e: Array in [[br.deck_from, -1.0], [br.deck_to, 1.0]]:
			for x in [-1.5, 0.0, 1.5]:
				var q: Vector3 = (e[0] as Vector3) + along * float(e[1]) * 0.75 + across * x
				var step := (e[0] as Vector3).y - ter.height(q.x, q.z)
				check(absf(step) < 0.3, "%s's approach meets its deck within a step (%.2f m, %+.1f across)" % [id, step, x])
	var a: RoadBridge = mk.bridge_a
	check_eq(a.cribs.size(), 1, "Bridge A's two spans on one log crib")
	if not a.cribs.is_empty():
		# Its two spans: the crib in the middle, the next support each way 8 m off (a bent at the
		# bank, or the end sill).
		var dc := float(a.cribs[0].d)
		check_near(dc, a.length() * 0.5, 2.0, "the crib in the middle (%.1f of %.1f)" % [dc, a.length()])
		var ds: Array[float] = [0.0, a.length()]
		for b: Dictionary in a.bents:
			ds.append(float(b.d))
		var near_w := INF
		var near_e := INF
		for d in ds:
			if d < dc:
				near_w = minf(near_w, dc - d)
			elif d > dc:
				near_e = minf(near_e, d - dc)
		check_near(near_w, 8.0, 2.0, "about an 8 m span west of the crib (%.1f)" % near_w)
		check_near(near_e, 8.0, 2.0, "about an 8 m span east of the crib (%.1f)" % near_e)
		var crib: Dictionary = a.cribs[0]
		var foot: StructureMember = (crib.logs as Array)[0]
		var bed := ter.height(foot.global_position.x, foot.global_position.z)
		check(absf(foot.global_position.y - bed) < 0.5, "its bottom course bedded in the creek (%.2f over the bed)" % (foot.global_position.y - bed))


func test_the_roads_keep_to_the_plan_s_grades() -> void:
	var g := _markers().road_grades()
	var lay := ValleyLayout.main()
	for r: Dictionary in lay.roads():
		check(g.has(String(r.id)), "%s measured" % r.id)
	var notes := []
	for id: String in g:
		var r: Dictionary = g[id]
		if r.class == "path":
			continue
		# valley-plan.md §11: every wagon road to 10 % but the mine road's one 5 m pitch; the
		# Baron's drive a short pitch onto its rise; horse tracks under 15 %. On the bake as graded
		# (valley_plan.py's roads) a short pitch is a run over the limit of 20 m or less.
		for run: Dictionary in r.runs:
			check(float(run.to) - float(run.from) <= GRADE_RUN_ALLOWED, "%s: %.1f %% from %d to %d m (at %s) is a short pitch" % [id, run.grade, run.from, run.to, run.at])
			notes.append("%s %.1f%% at %s" % [id, run.grade, run.at])
		check(float(r.steepest) <= float(r.limit) + 3.0, "%s's steepest %.1f %% (its limit %.0f)" % [id, r.steepest, r.limit])
	if not notes.is_empty():
		print("    over the limit, short: ", ", ".join(notes))


## A run over a road's limit no longer than this (m: the grade's 20 m window and a pitch onto a pad).
const GRADE_RUN_ALLOWED := 40.0


func test_every_place_has_a_point_to_stand_at() -> void:
	var mk := _markers()
	var lay := ValleyLayout.main()
	var ids: Array[String] = []
	ids.append_array(Array(lay.place_ids()))
	for b: Dictionary in lay.bridges():
		ids.append(String(b.id))
	for v: Dictionary in lay.viewpoints():
		ids.append(String(v.id))
	for side in ["north", "south"]:
		for l: Dictionary in lay.lots(side):
			ids.append(String(l.id))
	for id in ids:
		check(mk.places.has(StringName(id)), "%s is a place" % id)
	for id in ids:
		if not mk.places.has(StringName(id)):
			continue
		var p := mk.places.at(StringName(id))
		for b: Dictionary in mk.blocks:
			var local := ValleyMarkers._block_basis(float(b.heading)).inverse() * (p - (b.centre as Vector3))
			var size: Vector3 = b.size
			check(absf(local.x) > size.x * 0.5 or absf(local.z) > size.z * 0.5, "%s isn't inside %s's block" % [id, b.id])
		# On the ground there (or a town walk's planks: G5), or on a bridge's deck.
		var g := mk.surface(p.x, p.z)
		check(absf(p.y - 0.05 - g) < 0.01 or id.begins_with("bridge_"), "%s on the ground (%.2f over it)" % [id, p.y - g])


func test_goto_reaches_every_place_and_valley_view_every_viewpoint() -> void:
	bridge = DevBridge.new()
	bridge.main = holder
	bridge.port = TEST_PORT
	holder.add_child(bridge)
	await process_frames(2)
	var mk := _markers()
	var player := valley.get_node(^"Player") as Player
	var lay := ValleyLayout.main()
	var names: Array[String] = []
	for n: StringName in mk.places.points:
		names.append(String(n))
	check(names.size() >= lay.places().size() + lay.bridges().size() + lay.viewpoints().size(), "places, bridges and viewpoints (%d)" % names.size())
	for n in names:
		var want := mk.places.at(StringName(n))
		var out: Dictionary = await bridge._cmd_goto([n])
		check(not out.has("error"), "goto %s answered (%s)" % [n, out.get("error", "")])
		await physics_frames(4)
		var at := player.global_position
		check(at.distance_to(want) < 0.6, "goto %s: stood there (%.2f m off, at %s)" % [n, at.distance_to(want), at])
	for v: Dictionary in lay.viewpoints():
		var lab := bridge._lab_commands.get("valley_view") as BridgeLab
		check(lab != null, "the valley lab's valley_view")
		if lab == null:
			break
		var out: Dictionary = await lab.call("_cmd_valley_view", [String(v.id), "trestle_mid"])
		check(out.has("eye") and not out.has("error"), "valley_view %s (%s)" % [v.id, out.get("error", "")])
	var r: Dictionary = await bridge._cmd_read(["places"])
	check(r.get("places", {}).has("widow_homestead"), "read places lists the valley's")


func test_the_road_network_is_the_plan_s() -> void:
	# docs/briefs/valley-tables.md "F. Travel from the crossroads", "By road (m)": the plan's own
	# shortest ways, which ValleyRoads builds the same network for.
	var table := {"harlan_homestead": 713, "opening_site": 553, "widow_homestead": 2620, "bridge_a": 1016,
		"vp_trestle_overlook": 1314, "ore_works": 1587, "mine": 2756, "timber_camp": 1701, "baron_ranch": 2023,
		"baron_town_house": 244, "ute_community": 1899, "hideout": 2118, "cemetery": 243, "depot": 123, "east_exit": 3158}
	var lay := ValleyLayout.main()
	var roads := ValleyRoads.make(lay)
	for id: String in table:
		var j := roads.journey(Vector2.ZERO, ValleyLayout.xz(lay.entry(id).at))
		check(not j.is_empty(), "a way to %s" % id)
		if not j.is_empty():
			check_near(float(j.length), float(table[id]), maxf(5.0, float(table[id]) * 0.01), "%s %.0f m by road (the plan's %d)" % [id, j.length, table[id]])
