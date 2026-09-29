class_name RangeCover
extends Structure
## Things to hide behind round the outlaw's corner of the range, so a fight there has some shape:
## a woodpile, a couple of barrels, crates stacked chest high to a crouching man, and a stretch of
## plank fence. Built from members like everything else: bullets go through the thin stuff, the
## logs stop them, dynamite scatters the lot. Positions are in world space round the range
## (this node sits at the origin).


func build() -> void:
	# Woodpile: split logs stacked 1.1 m high, 2.2 m long, north of where he stands.
	for row in 4:
		for k in 3 - (row % 2):
			var z := -14.6 + k * 0.28 + (0.14 if row % 2 == 1 else 0.0)
			add_member("woodpile/r%d_%d" % [row, k], &"beam", &"framing", Vector3(0.26, 0.26, 2.2), Vector3(22.4, 0.13 + row * 0.26, z + 0.4), Basis(Vector3.UP, PI * 0.5))
	# Two barrels by the lane.
	for i in 2:
		add_member("barrel%d" % i, &"furniture_frame", &"weathered_pine", Vector3(0.6, 0.9, 0.6), Vector3(23.8 + i * 0.7, 0.45, -10.2 - i * 0.15))
	# Crates, two high.
	for i in 2:
		add_member("crate%d" % i, &"furniture_frame", &"weathered_pine", Vector3(1.0, 0.6, 1.0), Vector3(27.2, 0.3 + i * 0.6, -15.4))
	# A stretch of plank fence: posts and three rails of boards.
	for p in 3:
		add_member("fence/post%d" % p, &"post", &"framing", Vector3(0.1, 1.7, 0.1), Vector3(20.2, 0.85, -17.5 + p * 1.5))
	for b in 7:
		add_member("fence/board%d" % b, &"board", &"weathered_pine", Vector3(0.025, 0.22, 3.1), Vector3(20.14, 0.2 + b * 0.22, -16.0))
