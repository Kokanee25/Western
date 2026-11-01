extends Structure
## The saloon's gallery post on its own (experiments/building_lab/saloon.json "post": 8x8 in,
## chamfered, drawn in `int_timber`), floor to the gallery's beams, its foot at the origin.

const HEIGHT := 3.66


func build() -> void:
	var m := add_member("post", &"post", &"framing", Vector3(PostPose.POST_WIDTH, HEIGHT, PostPose.POST_WIDTH), Vector3(0.0, HEIGHT * 0.5, 0.0))
	PropKit.dress_member(m, {"shape": "profile", "profile": "chamfered", "along": "y", "up": "z", "args": [0.035]}, "wood:int_timber")
