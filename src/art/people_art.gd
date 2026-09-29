class_name PeopleArt
## Pixel-art textures for people, painted in code: cloth by weave (plain, wool, denim twill,
## stripes, felt), leather, skin, and faces. Cloth tiles on a 64x64 grid laid out in metres
## (TEXELS_PER_METER, finer than buildings' 40 because people are looked at up close); the face is
## one texture wrapped round the head (u = angle, 0.5 = straight ahead; v = up the head).
## Every texture is cached by key and deterministic for a seed.

const TEXELS_PER_METER := 64.0
const SIZE := PixelArt.SIZE
const FACE_W := 96
const FACE_H := 64

static var _cache := {}
static var _mats := {}


## A material for UVs laid out in metres (people's cloth and skin), pixel-filtered.
static func material(key: String, tex: Texture2D, roughness := 0.9, cull_back := true) -> StandardMaterial3D:
	var k := "%s/%s" % [key, cull_back]
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_texture = tex
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		var t := TEXELS_PER_METER / SIZE
		m.uv1_scale = Vector3(t, t, 1.0)
		m.roughness = roughness
		if not cull_back:
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mats[k] = m
	return _mats[k]


## The face material: UVs already 0..1 round the head.
static func face_material(key: String, tex: Texture2D) -> StandardMaterial3D:
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_texture = tex
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		m.roughness = 0.75
		_mats[key] = m
	return _mats[key]


## `top` (RGBA, alpha = how much of it) laid over `base`, at `top`'s size (nearest: still pixels).
static func _over(base: Image, top: Image) -> Image:
	var out := base.duplicate() as Image
	out.convert(Image.FORMAT_RGBA8)
	out.resize(top.get_width(), top.get_height(), Image.INTERPOLATE_NEAREST)
	for y in top.get_height():
		for x in top.get_width():
			var t := top.get_pixel(x, y)
			if t.a > 0.0:
				var b := out.get_pixel(x, y)
				# Hard steps, not a soft blend: a pixel is the portrait's or it isn't (dithered edge).
				if t.a >= 0.75 or (t.a > 0.25 and (x + y) % 2 == 0):
					out.set_pixel(x, y, Color(t.r, t.g, t.b, 1.0))
				else:
					out.set_pixel(x, y, b)
	return out


## Shade a painted face with its head's baked occlusion: skin steps down its ramp a band at a time
## (so it stays pixel art), anything else (hair, eyes) just darkens.
static func _shade_with(img: Image, ao: Image, skin_sh: Array[Color]) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var a := ao.get_pixel(x * ao.get_width() / img.get_width(), y * ao.get_height() / img.get_height()).r
			var c := img.get_pixel(x, y)
			var k := clampi(int(round((1.0 - a) * 2.4 - 0.55)), 0, 2)
			var i := skin_sh.find(c)
			if i >= 0:
				img.set_pixel(x, y, skin_sh[maxi(i - k, 0)])
			elif k > 0:
				img.set_pixel(x, y, c.darkened(0.14 * k))


## Woven cloth. style: &"plain" (shirting), &"wool" (heavy, felted), &"denim" (diagonal twill),
## &"stripe" (thin vertical stripes in `accent`), &"felt" (hats), &"leather".
static func cloth(key: String, base: Color, seed: int, style := &"plain", accent := Color(0, 0, 0, 0)) -> ImageTexture:
	var ck := "cloth:%s" % key
	if _cache.has(ck):
		return _cache[ck]
	var shades := PixelArt.ramp(base, 5, 0.3 if style != &"leather" else 0.4)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var big := PixelArt._noise(x, y, 4, 4, seed)
			var mid := PixelArt._noise(x, y, 16, 16, seed + 1)
			var fine := PixelArt._hash(x, y, seed + 2)
			var v := 0.5
			match style:
				&"wool":
					v = big * 0.45 + mid * 0.35 + fine * 0.2
				&"denim":
					var twill := 1.0 if posmod(x + y, 4) < 2 else 0.0
					v = big * 0.35 + mid * 0.2 + twill * 0.3 + fine * 0.15
				&"felt":
					v = big * 0.6 + mid * 0.3 + fine * 0.1
				&"leather":
					var crease := PixelArt._noise(x, y * 3, 6, 24, seed + 3)
					v = big * 0.5 + mid * 0.2 + fine * 0.1 + (0.2 if crease > 0.72 else 0.0) - (0.25 if crease < 0.12 else 0.0)
				_:
					var weave := 0.06 if (x + (y % 2)) % 2 == 0 else 0.0
					v = big * 0.45 + mid * 0.25 + fine * 0.18 + weave
			# Soft folds running down the cloth (u across, v along the limb).
			if style != &"leather" and style != &"felt":
				var fold := PixelArt._noise(x, 0, 8, 1, seed + 5)
				v += (fold - 0.5) * 0.35
			var c := shades[PixelArt._band(v, shades.size())]
			if style == &"stripe" and accent.a > 0.0 and x % 8 == 0:
				c = c.lerp(accent, 0.7)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[ck] = tex
	return tex


## A gun belt: dark leather with a row of cartridge loops, brass rims showing (u round the waist,
## v across the belt: the belt is BELT_WIDTH metres wide).
static func cartridge_belt(key: String, leather: Color, seed: int) -> ImageTexture:
	var ck := "belt:%s" % key
	if _cache.has(ck):
		return _cache[ck]
	var shades := PixelArt.ramp(leather, 4, 0.35)
	var brass := PixelArt.ramp(Color(0.72, 0.56, 0.27), 3, 0.3)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var v := PixelArt._noise(x, y, 8, 8, seed) * 0.6 + PixelArt._hash(x, y, seed) * 0.4
			var c := shades[PixelArt._band(v, shades.size())]
			var row := y % 4  # the belt is 4 texels high at 64/m (6 cm)
			if row == 0:
				c = shades[0]  # stitched edge
			elif x % 3 == 0:
				c = shades[0]  # gap between loops
			elif row == 1:
				c = brass[1 + (x % 2)]  # cartridge rims above the loops
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[ck] = tex
	return tex


## Skin that isn't the face (hands, neck, bare arms): the tone with blotches and a little shine.
static func skin(key: String, tone: Color, seed: int) -> ImageTexture:
	var ck := "skin:%s" % key
	if _cache.has(ck):
		return _cache[ck]
	var shades := PixelArt.ramp(tone, 5, 0.2)
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y in SIZE:
		for x in SIZE:
			var v := PixelArt._noise(x, y, 8, 8, seed) * 0.55 + PixelArt._noise(x, y, 32, 32, seed + 1) * 0.3 + PixelArt._hash(x, y, seed) * 0.15
			img.set_pixel(x, y, shades[PixelArt._band(v * 0.7 + 0.2, shades.size())])
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[ck] = tex
	return tex


## A face and head, wrapped round the head mesh. `look` keys (all optional):
##   tone, hair (colour), eyes (colour), moustache (&"none" | &"walrus" | &"handlebar" | &"trim"),
##   beard (&"none" | &"stubble" | &"full"), brows (0..1 thickness), age (0..1: lines, grey),
##   hair_style (&"short" | &"long"), scar (bool: a pale scar down the left cheek), seed.
## Layout: u = 0.5 straight ahead, u = 0.5 ± 0.25 the ears; v = 0 at the bottom of the chin
## (HEAD_BOTTOM), v = 1 at the crown (HEAD_TOP), so heights map linearly.
static func face(key: String, look: Dictionary) -> ImageTexture:
	var ck := "face:%s" % key
	if _cache.has(ck):
		return _cache[ck]
	var seed: int = look.get("seed", 7)
	var tone: Color = look.get("tone", Color(0.72, 0.52, 0.4))
	var hair: Color = look.get("hair", Color(0.22, 0.15, 0.09))
	var age: float = look.get("age", 0.3)
	if age > 0.5:
		hair = hair.lerp(Color(0.6, 0.58, 0.55), (age - 0.5) * 1.2)
	var skin_sh := PixelArt.ramp(tone, 6, 0.32)
	var hair_sh := PixelArt.ramp(hair, 4, 0.4)
	var img := Image.create(FACE_W, FACE_H, false, Image.FORMAT_RGBA8)
	# Base: skin with blotches, lit from above (lighter forehead, darker under the jaw).
	for y in FACE_H:
		for x in FACE_W:
			var n := PixelArt._hash(x, y, seed) * 0.25 + PixelArt._noise(x % 64, y % 64, 8, 8, seed) * 0.35
			var lit := float(y) / FACE_H * 0.3 + cos(TAU * float(x - FACE_W / 2) / FACE_W) * 0.18
			img.set_pixel(x, FACE_H - 1 - y, skin_sh[PixelArt._band(0.28 + n + lit, skin_sh.size())])
	var f := FaceCanvas.new(img)
	var cx := FACE_W / 2
	# A sculpted head (a generated body) brings its own shading, baked in this layout: its eye
	# sockets, nose and ears are real, so none of that is painted, and the baked light and shadow
	# shade the skin a band at a time.
	var ao: Image = look.get("ao", null)
	var sculpted := ao != null
	# Heights on the head (metres) → rows.
	var eye_row := f.row(1.655)
	var brow_row := f.row(1.672)
	var nose_row := f.row(1.622)
	var mouth_row := f.row(1.598)
	var chin_row := f.row(1.556)
	var ear_row := f.row(1.635)
	var hair_row := f.row(1.712)
	# Sides of the face fall into shadow; the cheekbones catch light.
	for dx in ([] if sculpted else [7, 8, 9]):
		f.shade(cx - dx, nose_row + 1, 1)
		f.shade(cx + dx, nose_row + 1, 1)
	# Eye sockets in shadow under the brow, then the eyes.
	for dx in ([] if sculpted else range(3, 10)):
		f.shade(cx - dx, eye_row, -1)
		f.shade(cx + dx - 1, eye_row, -1)
		f.shade(cx - dx, eye_row + 1, -2)
		f.shade(cx + dx - 1, eye_row + 1, -2)
	var white := Color(0.86, 0.82, 0.74)
	var iris: Color = look.get("eyes", Color(0.25, 0.3, 0.35))
	for side in [-1, 1]:
		var ex: int = cx + side * 6 + (0 if side > 0 else -1)
		f.put(ex - 1, eye_row, white)
		f.put(ex, eye_row, iris.darkened(0.3))
		f.put(ex + 1, eye_row, white.darkened(0.2))
		for dx in range(-2, 3):
			f.put(ex + dx, eye_row + 1, skin_sh[0].darkened(0.35) if absi(dx) < 2 else skin_sh[1])  # lid and lashes
		f.put(ex, eye_row - 1, skin_sh[1])  # a shadow under the eye
	# Brows.
	var thick: float = look.get("brows", 0.6)
	for side in [-1, 1]:
		for i in range(2, 10):
			var x: int = cx + side * i + (0 if side > 0 else -1)
			var lift := 1 if i >= 5 and i <= 7 else 0
			f.put(x, brow_row + lift, hair_sh[0] if i > 2 else hair_sh[1])
			if thick > 0.5 and i > 2 and i < 8:
				f.put(x, brow_row + lift - 1, hair_sh[1])
	# Nose: a lit ridge, a shadowed side and dark nostrils.
	if not sculpted:
		for y in range(nose_row, eye_row):
			f.shade(cx, y, 1)
			f.shade(cx + 1, y, -1)
		f.put(cx - 1, nose_row, skin_sh[0].darkened(0.3))
		f.put(cx + 1, nose_row, skin_sh[0].darkened(0.3))
		for dx in range(-2, 3):
			f.shade(cx + dx, nose_row - 1, -2)
	# Mouth.
	for dx in range(-4, 4):
		f.put(cx + dx, mouth_row, skin_sh[0].darkened(0.2))
		f.shade(cx + dx, mouth_row - 1, 1)
	# Ears (the mesh adds a flap; this is the shadow round it).
	for side in ([] if sculpted else [-1, 1]):
		var ex: int = cx + side * (FACE_W / 4)
		for y in range(ear_row - 3, ear_row + 4):
			f.shade(ex, y, -1)
			f.shade(ex + side, y, -2)
	# Beard and stubble along the jaw and chin.
	var beard: StringName = look.get("beard", &"stubble")
	if beard != &"none":
		for y in range(chin_row - 2, mouth_row + 1):
			for dx in range(-17, 17):
				var x := cx + dx
				var jaw := y < mouth_row - 1 or absi(dx) > 5
				if not jaw or (y == mouth_row and absi(dx) < 5):
					continue
				if beard == &"full":
					f.put(x, y, hair_sh[PixelArt._band(PixelArt._hash(x, y, seed), 3)])
				elif PixelArt._hash(x, y, seed + 9) > 0.62:
					f.put(x, y, f.get_px(x, y).lerp(hair_sh[1], 0.3))
	# Moustache over the lip.
	var tache: StringName = look.get("moustache", &"walrus")
	match tache:
		&"walrus":
			for dx in range(-5, 5):
				f.put(cx + dx, mouth_row, hair_sh[1] if absi(dx) > 1 else hair_sh[2])
				f.put(cx + dx, mouth_row + 1, hair_sh[2] if (dx + 5) % 3 == 0 else hair_sh[1])
				f.put(cx + dx, mouth_row + 2, hair_sh[1] if absi(dx) < 4 else hair_sh[0])
				f.put(cx + dx, mouth_row + 3, hair_sh[0] if absi(dx) < 3 else f.get_px(cx + dx, mouth_row + 3))
			for dx in [-4, -3, 2, 3]:
				f.put(cx + dx, mouth_row - 1, skin_sh[0].darkened(0.3))  # the mouth's corners under it
			for side in [-1, 1]:
				f.put(cx + side * 5 + (0 if side > 0 else -1), mouth_row, hair_sh[0])
				f.put(cx + side * 5 + (0 if side > 0 else -1), mouth_row - 1, hair_sh[1])
				f.put(cx + side * 5 + (0 if side > 0 else -1), mouth_row - 2, hair_sh[1])
		&"handlebar":
			for dx in range(-4, 4):
				f.put(cx + dx, mouth_row + 1, hair_sh[0])
			for side in [-1, 1]:
				f.put(cx + side * 5 + (0 if side > 0 else -1), mouth_row + 2, hair_sh[1])
				f.put(cx + side * 6 + (0 if side > 0 else -1), mouth_row + 3, hair_sh[1])
		&"trim":
			for dx in range(-3, 3):
				f.put(cx + dx, mouth_row + 1, hair_sh[1])
	# Age lines: crow's feet and a line or two across the brow.
	if age > 0.35:
		for side in [-1, 1]:
			f.shade(cx + side * 10 + (0 if side > 0 else -1), eye_row, -2)
		for dx in range(-7, 7, 2):
			f.shade(cx + dx, brow_row + 3, -1)
	if look.get("scar", false):
		for i in 7:
			f.put(cx - 10 + (i % 2), nose_row + 3 - i, skin_sh[5])
	# Hair: back and sides above the ears, sideburns, and a fringe line at the forehead.
	var long: bool = look.get("hair_style", &"short") == &"long"
	for y in FACE_H:  # rows up from the chin
		for x in FACE_W:
			var around := absf(float(x - cx)) / (FACE_W / 2.0)  # 0 front .. 1 back
			var top := f.row_height(FACE_H - 1 - y)
			var h := false
			var jitter := (PixelArt._hash(x, 3, seed + 11) - 0.5) * 0.01
			if top > 1.715 + jitter:
				h = true
			elif around > 0.36 and top > (1.585 if long else 1.64) + jitter:
				h = around > 0.62 or top > 1.66 or (around > 0.4 and top > 1.63)
			if h:
				f.put(x, y, hair_sh[PixelArt._band(PixelArt._noise(x % 64, y % 64, 16, 32, seed + 4) * 0.8 + 0.1, hair_sh.size())])
	if sculpted:
		_shade_with(img, ao, skin_sh)
	# A face painted by the image model (tools/faces/paint_face.py, projected by the people
	# pipeline): over the front of the head; the painted hair, ears and back of the head round it.
	var portrait: Image = look.get("portrait", null)
	if portrait != null:
		img = _over(img, portrait)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[ck] = tex
	return tex


## Pixel painting on the face image, in rows counted up from the chin.
class FaceCanvas:
	var img: Image
	var shades := []

	func _init(i: Image) -> void:
		img = i

	func row(height: float) -> int:
		return clampi(int(round((height - BodyMesh.HEAD_BOTTOM) / (BodyMesh.HEAD_TOP - BodyMesh.HEAD_BOTTOM) * PeopleArt.FACE_H)), 0, PeopleArt.FACE_H - 1)

	func row_height(y_from_top: int) -> float:
		var r := PeopleArt.FACE_H - 1 - y_from_top
		return BodyMesh.HEAD_BOTTOM + (float(r) + 0.5) / PeopleArt.FACE_H * (BodyMesh.HEAD_TOP - BodyMesh.HEAD_BOTTOM)

	func put(x: int, r: int, c: Color) -> void:
		if r < 0 or r >= PeopleArt.FACE_H:
			return
		img.set_pixel(posmod(x, PeopleArt.FACE_W), PeopleArt.FACE_H - 1 - r, c)

	func get_px(x: int, r: int) -> Color:
		return img.get_pixel(posmod(x, PeopleArt.FACE_W), PeopleArt.FACE_H - 1 - clampi(r, 0, PeopleArt.FACE_H - 1))

	## Darken (negative) or lighten (positive) a pixel by steps of about 12%.
	func shade(x: int, r: int, steps: int) -> void:
		if r < 0 or r >= PeopleArt.FACE_H:
			return
		var c := get_px(x, r)
		c = c.darkened(-0.12 * steps) if steps < 0 else c.lightened(0.08 * steps)
		put(x, r, c)
