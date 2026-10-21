extends Structure
## The lab's breakable railing (round 4, Sean 2026-10-21: "a hard push or shove into that 1 meter
## railing, make the railing break and the body fall"): the oak walkway's (art's OakStair: a 1.0 m
## rail over a lobby 2.47 below) built of the game's own members, so it breaks as the game's
## timber does. A deck 2.47 up on four posts, its front edge at z = -0.45 (the way he faces at yaw
## 0); along it newels every 1.2 m, balusters every 0.12 m and a 70 x 60 oak cap rail at 1.0 in
## spans from newel to newel. (OakStair's own balustrade is drawn boards with a static collision:
## it doesn't break.)

const DECK_TOP := 2.47
const EDGE_Z := -0.45
const RAIL_H := 1.0
const SPAN := 1.2
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
	for i in NEWELS.size() - 1:
		var a: float = NEWELS[i]
		var b: float = NEWELS[i + 1]
		var n := int(round((b - a) / 0.12))
		for k in range(1, n):
			add_member("baluster_%d_%02d" % [i, k], &"trim", &"dark_trim", Vector3(0.035, RAIL_H - 0.06, 0.035),
					Vector3(a + (b - a) * k / n, DECK_TOP + (RAIL_H - 0.06) * 0.5, z))
		add_member("cap_%d" % i, &"trim", &"dark_trim", Vector3(b - a - 0.09, 0.06, 0.07),
				Vector3((a + b) * 0.5, DECK_TOP + RAIL_H - 0.03, z))
