class_name WaterTrough
extends KitProp
## A plank water trough on two skids, full of water. Runs along +X from the origin. Its planks are
## the prop kit's trough (assets/props/kit/trough.json) fitted to its size: they break, burn and
## fall as any kit prop's.

@export var length := 2.0
@export var trough_width := 0.65
@export var height := 0.6

const T := 0.04


func build() -> void:
	add_to_group(&"water_source")  # a bucket can be filled here (BucketViewmodel)
	kit_id = &"trough"
	# The skids stand 5 cm out either side of its width.
	definition = PropKit.fit(PropKit.definition(&"trough"), Vector3(length, height, trough_width + 0.1))
	super.build()
	var water := MeshInstance3D.new()
	water.name = "Water"
	var plane := PlaneMesh.new()
	plane.size = Vector2(length - T * 2.0, trough_width - T * 2.0)
	water.mesh = plane
	water.material_override = WoodMaterials.water()
	water.position = Vector3(length * 0.5, height - 0.08, 0.0)
	add_child(water)
