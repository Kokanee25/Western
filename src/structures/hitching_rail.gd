class_name HitchingRail
extends Structure
## Two posts and a rail. Runs along +X from the origin.

@export var length := 2.4
@export var height := 1.05


func build() -> void:
	for i in 2:
		var x := 0.06 if i == 0 else length - 0.06
		add_member("post%d" % i, &"post", &"framing", Vector3(0.12, height, 0.12), Vector3(x, height * 0.5, 0.0))
	add_member("rail", &"beam", &"weathered_pine", Vector3(length + 0.1, 0.09, 0.09), Vector3(length * 0.5, height + 0.045, 0.0))
