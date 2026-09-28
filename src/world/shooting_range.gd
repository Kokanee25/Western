class_name TargetBoard
extends Structure
## A practice target: pine boards nailed to two posts (bullets go through, leaving holes you can
## see daylight through), painted with a black square, and a backstop of heavy timbers behind it
## that stops them. Front faces -Z.

@export var board_width := 1.6


func build() -> void:
	var w := board_width
	for i in 2:
		var x := -w * 0.5 + 0.1 if i == 0 else w * 0.5 - 0.1
		add_member("post%d" % i, &"post", &"framing", Vector3(0.1, 1.9, 0.1), Vector3(x, 0.95, 0.05))
	for r in 6:
		var y := 0.62 + r * 0.2
		add_member("board%d" % r, &"board", &"sign", Vector3(w, 0.195, 0.025), Vector3(0, y, -0.0125))
	add_member("bull", &"trim", &"dark_trim", Vector3(0.3, 0.3, 0.01), Vector3(0, 1.22, -0.03))
	# Backstop: stacked timbers a metre behind.
	add_member("stop0", &"sill", &"framing", Vector3(w + 0.6, 0.3, 0.3), Vector3(0, 0.15, 1.2))
	for i in range(1, 7):
		add_member("stop%d" % i, &"beam", &"framing", Vector3(w + 0.6, 0.3, 0.3), Vector3(0, 0.15 + i * 0.3, 1.2))
