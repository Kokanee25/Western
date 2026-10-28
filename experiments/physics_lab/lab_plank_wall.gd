extends Structure
## The lab's thin plank wall (issue #446, Sean 2026-10-28: "I had a great one of a guy break a wall
## when he was shot and kept moving and went through it as he fell"): an inside partition as the
## game's buildings frame theirs (FalseFrontBuilding: 2x4 studs on a sill under a plate, 1 in boards
## on one face), of the game's own members, so it breaks as the game's timber does. Across his way
## (x), its board face toward him at z = FACE_Z; 2.4 m wide, 2.6 high, studs every 0.6
## (FalseFrontBuilding's 0.05 x 0.1), boards 0.2 high and 0.025 thick in rows from stud to stud.

const FACE_Z := -2.5
const WIDTH := 2.4
const HEIGHT := 2.6
const STUD_W := 0.05
const STUD_D := 0.1
const BOARD_T := 0.025
const BOARD_H := 0.2
const STUD_EVERY := 0.6


func build() -> void:
	var zc := FACE_Z - BOARD_T - STUD_D * 0.5  # the studs' middle, behind the boards
	add_member("sill", &"sill", &"framing", Vector3(WIDTH, 0.05, STUD_D), Vector3(0.0, 0.025, zc))
	add_member("plate", &"plate", &"framing", Vector3(WIDTH, 0.05, STUD_D), Vector3(0.0, HEIGHT - 0.025, zc))
	var studs: Array[float] = []
	var x := -WIDTH * 0.5 + STUD_W * 0.5
	while x < WIDTH * 0.5:
		studs.append(x)
		x += STUD_EVERY
	studs.append(WIDTH * 0.5 - STUD_W * 0.5)
	for i in studs.size():
		add_member("stud_%02d" % i, &"stud", &"framing", Vector3(STUD_W, HEIGHT - 0.1, STUD_D),
				Vector3(studs[i], HEIGHT * 0.5, zc))
	# Boards in rows, each from stud to stud (as the siding's spans: FalseFrontBuilding._wall_member).
	var row := 0
	var y := 0.05
	while y < HEIGHT - 0.05:
		var y1 := minf(y + BOARD_H, HEIGHT - 0.05)
		for i in studs.size() - 1:
			var a := studs[i] - STUD_W * 0.5 if i == 0 else studs[i]
			var b := studs[i + 1] + STUD_W * 0.5 if i == studs.size() - 2 else studs[i + 1]
			add_member("board_r%02d_%d" % [row, i], &"board", &"weathered_pine", Vector3(b - a, y1 - y, BOARD_T),
					Vector3((a + b) * 0.5, (y + y1) * 0.5, FACE_Z - BOARD_T * 0.5))
		y = y1
		row += 1
