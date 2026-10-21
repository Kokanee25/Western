extends Structure
## The lab's breakable railing (round 4, Sean 2026-10-21: "a hard push or shove into that 1 meter
## railing, make the railing break and the body fall"): the oak walkway's (art's OakStair: a 1.0 m
## rail over a lobby 2.47 below) built of the game's own members, so it breaks as the game's
## timber does. A deck 2.47 up on four posts, its front edge at z = -0.45 (the way he faces at yaw
## 0); along it newels every 1.2 m, balusters every 0.12 m and a 70 x 60 oak cap rail at 1.0 in
## spans from newel to newel, each bay the game's railing part (Railing). (OakStair's own
## balustrade is drawn boards with a static collision: it doesn't break.)

const DECK_TOP := 2.47
const EDGE_Z := -0.45
const RAIL_H := 1.0
const NEWELS := [-1.8, -0.6, 0.6, 1.8]


func build() -> void:
	var deck_t := 0.1
	for x: float in [-1.9, 1.9]:
		for z: float in [EDGE_Z + 0.08, 2.4]:
			add_member("deck_post_%d_%d" % [int(x * 10), int(z * 10)], &"post", &"framing",
					Vector3(0.15, DECK_TOP - deck_t, 0.15), Vector3(x, (DECK_TOP - deck_t) * 0.5, z))
	add_member("deck", &"floor_board", &"floor", Vector3(4.0, deck_t, 2.9),
			Vector3(0.0, DECK_TOP - deck_t * 0.5, EDGE_Z + 1.45))
	var z := EDGE_Z + 0.05
	for x: float in NEWELS:
		add_member("newel_%d" % int(x * 10), &"furniture_frame", &"dark_trim", Vector3(0.09, RAIL_H, 0.09),
				Vector3(x, DECK_TOP + RAIL_H * 0.5, z))
	# Between each pair of newels a bay of the game's railing part (Railing): balusters every 0.12,
	# the cap from newel to newel.
	for i in NEWELS.size() - 1:
		var a: float = NEWELS[i] + 0.045
		var b: float = NEWELS[i + 1] - 0.045
		Railing.build(self, "bay_%d" % i, Vector3(a, DECK_TOP, z), Vector3(b, DECK_TOP, z),
				{"height": RAIL_H, "spacing": 0.12, "rail": Vector2(0.07, 0.06), "overhang": 0.0})
