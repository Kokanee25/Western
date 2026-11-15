class_name PaintedDrop
extends Node3D
## A painted cloth drop on a stage's back wall (#902, saloon B: Salt Creek as the Baron promises
## it): canvas hung from a batten, a wooden roller along its hem keeping it straight. `art` is the
## painting (a texture's path); without it, or until the painting exists, plain sized canvas a
## little stained. It falls as a fitting (the building's Fittings) when its batten goes.
##
## In its own space: the drop runs along x from -width/2 to +width/2, its top at y 0, hanging down
## to -height, its painted face toward +z.

@export var width := 4.6
@export var height := 2.3
@export var art := ""
## Plain canvas, before it's painted: sized cotton duck, yellowed.
@export var canvas := Color(0.78, 0.73, 0.62)
@export var seed := 902

var _cloth: MeshInstance3D
var _roller: MeshInstance3D


func _ready() -> void:
	_build()


## True once its painting is hung (the art's texture loaded), false while it's plain canvas.
func painted() -> bool:
	return art != "" and ResourceLoader.exists(art)


func _build() -> void:
	for c in get_children():
		c.free()
	_cloth = MeshInstance3D.new()
	_cloth.name = "Cloth"
	_cloth.mesh = _sheet()
	var m := StandardMaterial3D.new()
	m.roughness = 0.95
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	if painted():
		m.albedo_texture = load(art)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	else:
		m.albedo_color = Color.WHITE
	_cloth.material_override = m
	add_child(_cloth)
	# The roller along the hem: a plain turned pole a little longer than the drop.
	_roller = MeshInstance3D.new()
	_roller.name = "Roller"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.025
	cyl.bottom_radius = 0.025
	cyl.height = width + 0.06
	cyl.radial_segments = 10
	cyl.rings = 1
	_roller.mesh = cyl
	_roller.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, -height, 0.01))
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.36, 0.27, 0.18)
	rm.roughness = 0.8
	_roller.material_override = rm
	add_child(_roller)


## The canvas: a grid hanging in soft vertical waves (deeper toward the hem, flat at the batten), a
## faint tide of stains and dust in its colour when it's plain (the painting's own colour when not).
func _sheet() -> ArrayMesh:
	var cols := 33
	var rows := 9
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var phase := rng.randf() * TAU
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colours := PackedColorArray()
	var idx := PackedInt32Array()
	var tint := Color.WHITE if painted() else canvas
	for j in rows:
		var v := float(j) / (rows - 1)
		var sag := 0.015 * v  # waves let in under the batten, out to 1.5 cm at the hem
		for i in cols:
			var u := float(i) / (cols - 1)
			var w := sin(u * TAU * 3.5 + phase) + 0.4 * sin(u * TAU * 7.0 + phase * 2.0)
			var z := sag * w
			var dz := sag * (cos(u * TAU * 3.5 + phase) * TAU * 3.5 + 0.4 * cos(u * TAU * 7.0 + phase * 2.0) * TAU * 7.0) / width
			verts.append(Vector3((u - 0.5) * width, -v * height, z))
			norms.append(Vector3(-dz, 0.0, 1.0).normalized())
			uvs.append(Vector2(u, v))
			# Darker low down (damp, boots, smoke) and in two broad old tide marks.
			var stain := 1.0 - 0.08 * v * v - 0.05 * maxf(0.0, sin(u * 5.0 + phase)) * v
			colours.append(Color(tint.r * stain, tint.g * stain, tint.b * stain))
	for j in rows - 1:
		for i in cols - 1:
			var a := j * cols + i
			var c := (j + 1) * cols + i
			# Clockwise seen from +z (its painted face): top-left, top-right, bottom-left.
			idx.append_array([a, a + 1, c, a + 1, c + 1, c])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colours
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
