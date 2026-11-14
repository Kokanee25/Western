class_name DryGrass
extends Node3D
## Dry bunch grass, as the street painting has it: gold and straw tufts thick along the edges of
## the road, in the gaps between buildings, round posts and rails, thinning out on the open ground
## past town. Each tuft is three crossed quads with blades painted in code (a few straw shades,
## one texel a blade, alpha cut out), all of them one MultiMesh (one draw call). Deterministic
## from the seed. Nothing grows where there's a floor, a boardwalk or a roof overhead, nor down the
## middle of the road; the grass has no collision.

## The road's half width (its middle: TownLayout.street_z).
const ROAD_HALF := 6.0
## How many tufts to try placing, and the area they're scattered over (x0, z0, x1, z1).
const TRIES := 32000
const AREA := Rect2(-80.0, -45.0, 110.0, 80.0)
## Tuft size in metres (width, height) and texels in its picture. 156 x 108 since 2026-10-16
## (docs/briefs/match-the-man.md): at 26 x 18, one texel a blade and drawn nearest, every blade was
## a big square beside the painted man; now thin tapering strokes, filtered smooth.
const SIZE := Vector2(0.85, 0.55)
const TEXELS := Vector2i(156, 108)

@export var grass_seed := 1876

## Where each tuft stands (the multimesh's transforms; kept here too, as a headless renderer
## doesn't keep them).
var tufts: Array[Transform3D] = []

var _texture: ImageTexture


func _ready() -> void:
	# Placed on the first physics frame: the buildings' floors and boardwalks must be in the
	# physics space to keep grass from under them.
	await get_tree().physics_frame
	_grow()


func _grow() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = grass_seed
	var space := World.space(self)
	var ray := PhysicsRayQueryParameters3D.new()
	ray.collision_mask = Layers.WORLD
	var noise := FastNoiseLite.new()
	noise.seed = grass_seed
	noise.frequency = 0.18
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	for i in TRIES:
		var p := Vector3(rng.randf_range(AREA.position.x, AREA.end.x), 0.0, rng.randf_range(AREA.position.y, AREA.end.y))
		p.y = TownLayout.ground_height(p.x, p.z)
		var keep := _density(p, noise)
		if rng.randf() > keep:
			continue
		# Anything overhead or underfoot that isn't the ground (floors, boardwalks, sills, props)?
		ray.from = p + Vector3.UP * 6.0
		ray.to = p + Vector3.UP * 0.03
		if not space.intersect_ray(ray).is_empty():
			continue
		var s := rng.randf_range(0.6, 1.6)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.8, 1.25), s))
		transforms.append(Transform3D(basis, p))
		# Some tufts paler and more bleached, some greener-gold, some burnt brown.
		colours.append(Color(1, 1, 1).lerp([Color(1.15, 1.08, 0.95), Color(0.95, 1.0, 0.82), Color(0.92, 0.8, 0.68)][rng.randi() % 3],
				rng.randf() * 0.7))
	tufts = transforms
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = tuft_mesh()
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colours[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Tufts"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


## How likely a tuft is at `p` (0..1): thick along the road's edges and in clumps, none down the
## middle where the wheels go, sparser on the open ground.
func _density(p: Vector3, noise: FastNoiseLite) -> float:
	var dz := absf(p.z - TownLayout.street_z(p.x))
	var clump := clampf(noise.get_noise_2d(p.x, p.z) * 0.9 + 0.5, 0.0, 1.0)
	if dz < ROAD_HALF - 1.6:
		return 0.0
	if dz < ROAD_HALF + 1.4:
		# The edge of the road: thickest where the wheels never go, in clumps with bare dirt between
		# (the painting's grass by the walks is a tuft here and a clump there, not a hedge).
		return lerpf(0.25, 1.0, smoothstep(ROAD_HALF - 1.6, ROAD_HALF - 0.2, dz)) * smoothstep(0.28, 0.58, clump)
	return 0.28 * clump


## Three crossed quads standing on the ground, their normals up (lit like the ground they grow
## from), the blade picture on both sides.
func tuft_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		var a := PI * k / 3.0
		var across := Vector3(cos(a), 0.0, sin(a)) * SIZE.x * 0.5
		var q := [-across, across, across + Vector3.UP * SIZE.y, -across + Vector3.UP * SIZE.y]
		var uv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3.UP)
			st.set_uv(uv[idx])
			st.add_vertex(q[idx])
	var mesh := st.commit()
	mesh.surface_set_material(0, material())
	return mesh


func material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = blades()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	m.metallic_specular = 0.1
	return m


## The tuft's picture: blades as thin painted strokes rising from the bottom, two or three texels
## wide at the root tapering to one at the tip, curving out from the middle, the tallest in the
## middle; straw, gold, pale and a few brown, darker at the root, a little lighter along one side
## (the man's painted hand: a few tones a stroke, no noise). Mipmapped, so far tufts soften.
func blades() -> ImageTexture:
	if _texture:
		return _texture
	var img := Image.create(TEXELS.x, TEXELS.y, false, Image.FORMAT_RGBA8)
	# Transparent straw, not black: the mipmaps blend what's round a blade into its edge.
	img.fill(Color(0.82, 0.67, 0.4, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var shades := [Color(0.85, 0.68, 0.38), Color(0.93, 0.79, 0.48), Color(0.76, 0.59, 0.32),
			Color(0.98, 0.88, 0.6), Color(0.64, 0.48, 0.27), Color(0.82, 0.73, 0.45)]
	var w := float(TEXELS.x)
	var hgt := float(TEXELS.y)
	for b in 150:
		var x0 := rng.randf_range(w * 0.25, w * 0.75)
		var out := (x0 - w * 0.5) / (w * 0.5)
		var lean := out * rng.randf_range(0.15, 0.6) + rng.randf_range(-0.12, 0.12)
		var bend := out * rng.randf_range(0.2, 0.9) + rng.randf_range(-0.2, 0.2)
		var middle := 1.0 - absf(out)
		var h := hgt * rng.randf_range(0.35, 0.6 + 0.38 * middle)
		var c: Color = shades[rng.randi() % shades.size()]
		var root_w := rng.randf_range(1.6, 2.8)
		var steps := int(h * 1.5)
		for k in steps:
			var t := float(k) / steps
			var y := t * h
			# The blade curves out more as it rises (bend), leaning from its root.
			var x := x0 + lean * y + bend * y * t * 0.6
			var half := root_w * (1.0 - t * 0.75) * 0.5
			var shade := c.darkened((1.0 - t) * (1.0 - t) * 0.35)
			for dx in range(int(floor(x - half)), int(ceil(x + half)) + 1):
				if dx < 0 or dx >= TEXELS.x:
					continue
				var cover := clampf(half + 0.5 - absf(float(dx) - x), 0.0, 1.0)
				if cover <= 0.0:
					continue
				var py := TEXELS.y - 1 - int(y)
				if py < 0:
					continue
				var lit := shade.lightened(0.12) if float(dx) < x else shade
				var was := img.get_pixel(dx, py)
				var a := maxf(was.a, cover)
				img.set_pixel(dx, py, Color(lit.r, lit.g, lit.b, a))
	img.generate_mipmaps()
	_texture = ImageTexture.create_from_image(img)
	return _texture
