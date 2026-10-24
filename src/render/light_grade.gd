class_name LightGrade
## The light pass's colour grade (Sean, 2026-10-23: "looks too cheap"; issue #318): the street's
## Environment's colour correction, a 3D lookup built here from a few dials, applied after the
## tone map. Cool shadows and warm highlights (split toning), the colours pulled back, the oranges
## most (the street, the wood and the sky's gold all leaned orange), and a gentle S of contrast.
## The idea is the colourist's split tone and hue-targeted desaturation (as described in the
## DaVinci Resolve manual's colour chapters); no code from anywhere.
##
## Dials (LookPreset's `grade.<dial>`): strength 0 is off (no lookup, the environment's
## adjustments off as before). Set by the light looks (config/looks/light_*.json, LightLooks).

const SIZE := 16  # 16^3: ~17 ms to build here (32^3 was 133 ms, a hitch at each dusk step); the grade is smooth

## The dials and their "off" values.
const DEFAULTS := {
	"strength": 0.0,  # 0 off, 1 the grade in full
	"saturation": 1.0,  # every colour toward its grey
	"orange_pull": 0.0,  # extra toward grey for oranges (hue ~30 degrees), by their chroma
	"orange_hue": 32.0,  # degrees: the orange the pull centres on
	"orange_width": 28.0,  # degrees either side it reaches
	"contrast": 0.0,  # an S round mid grey: 0 none, 1 a smoothstep's worth
	"shadow_tint": Color(0.86, 0.94, 1.08),  # what the shadows lean toward (multiplied, grey-normalised)
	"shadow_amount": 0.0,
	"highlight_tint": Color(1.06, 1.0, 0.9),
	"highlight_amount": 0.0,
	"black": 0.0,  # lifts (+) or crushes (-) the blacks
}

static var dials := DEFAULTS.duplicate()
## While true, set_dial only stores (a look sets several dials; one lookup is built at its end:
## LookPreset.apply, LightLooks.blend).
static var batching := false
static var _built := {}  # the dials the lookup in force was built from
static var _lut: ImageTexture3D
## Lookups built before, by their dials (the game's light steps through a few as the sun goes down).
static var _cache := {}
const CACHE_MAX := 12


## Set one dial (LookPreset `grade.<name>`) and re-grade the street. False if there's no such dial.
static func set_dial(tree: SceneTree, name: String, value: Variant) -> bool:
	if not DEFAULTS.has(name):
		return false
	dials[name] = value
	if not batching:
		apply(tree)
	return true


## The street's environment graded by the dials (or left as it was with strength 0).
static func apply(tree: SceneTree) -> void:
	var env := LookPreset.environment(tree)
	if env == null:
		return
	var s: float = dials.strength
	if s <= 0.0:
		if env.adjustment_color_correction == _lut and _lut != null:
			env.adjustment_color_correction = null
			env.adjustment_enabled = false
		return
	if _lut == null or _built != dials:
		var key := str(dials)
		if not _cache.has(key):
			if _cache.size() >= CACHE_MAX:
				_cache.clear()
			_cache[key] = build(dials)
		_lut = _cache[key]
		_built = dials.duplicate()
	# The scene's own contrast and saturation (1.15, 1.12) were never switched on (adjustment_enabled
	# false): the grade's dials stand in for them.
	env.adjustment_brightness = 1.0
	env.adjustment_contrast = 1.0
	env.adjustment_saturation = 1.0
	env.adjustment_color_correction = _lut
	env.adjustment_enabled = true


## The lookup: SIZE^3 texels, input the tone-mapped colour (sRGB), output the graded one.
static func build(d: Dictionary) -> ImageTexture3D:
	var images: Array[Image] = []
	var n := SIZE - 1
	for b in SIZE:
		var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
		for g in SIZE:
			for r in SIZE:
				var c := grade(Color(r / float(n), g / float(n), b / float(n)), d)
				img.set_pixel(r, g, c)
		images.append(img)
	var tex := ImageTexture3D.new()
	tex.create(Image.FORMAT_RGB8, SIZE, SIZE, SIZE, false, images)
	return tex


static func luma(c: Color) -> float:
	return c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722


## One colour graded (sRGB in, sRGB out). Testable without a renderer.
static func grade(c: Color, d: Dictionary) -> Color:
	var src := c
	var l := luma(c)
	# Oranges toward grey first, by how orange and how strong they are.
	var pull: float = d.get("orange_pull", 0.0)
	if pull > 0.0:
		var chroma := maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))
		var dh := absf(fposmod(c.h * 360.0 - float(d.get("orange_hue", 32.0)) + 180.0, 360.0) - 180.0)
		var w := (1.0 - smoothstep(0.0, float(d.get("orange_width", 28.0)), dh)) * smoothstep(0.02, 0.25, chroma)
		c = _mix(c, Color(l, l, l), clampf(pull * w, 0.0, 1.0))
	var sat: float = d.get("saturation", 1.0)
	c = _mix(Color(l, l, l), c, sat)
	# Split toning: shadows lean to one tint, highlights to the other (each normalised to its own
	# grey so the tone stays where it was).
	var sh: Color = d.get("shadow_tint", Color.WHITE)
	var hi: Color = d.get("highlight_tint", Color.WHITE)
	var ws := (1.0 - smoothstep(0.05, 0.55, l)) * float(d.get("shadow_amount", 0.0))
	var wh := smoothstep(0.45, 0.95, l) * float(d.get("highlight_amount", 0.0))
	var shn := sh / maxf(luma(sh), 0.001)
	var hin := hi / maxf(luma(hi), 0.001)
	c = Color(c.r * lerpf(1.0, shn.r, ws) * lerpf(1.0, hin.r, wh),
			c.g * lerpf(1.0, shn.g, ws) * lerpf(1.0, hin.g, wh),
			c.b * lerpf(1.0, shn.b, ws) * lerpf(1.0, hin.b, wh))
	# An S round mid grey, on each channel.
	var k: float = d.get("contrast", 0.0)
	if k != 0.0:
		c = Color(_s(c.r, k), _s(c.g, k), _s(c.b, k))
	var black: float = d.get("black", 0.0)
	if black != 0.0:
		c = Color(_lift(c.r, black), _lift(c.g, black), _lift(c.b, black))
	var out := _mix(src, c, float(d.get("strength", 1.0)))
	return Color(clampf(out.r, 0.0, 1.0), clampf(out.g, 0.0, 1.0), clampf(out.b, 0.0, 1.0))


static func _mix(a: Color, b: Color, t: float) -> Color:
	return Color(lerpf(a.r, b.r, t), lerpf(a.g, b.g, t), lerpf(a.b, b.b, t))


static func _s(x: float, k: float) -> float:
	var y := clampf(x, 0.0, 1.0)
	return lerpf(y, y * y * (3.0 - 2.0 * y), k)


## +: the blacks lifted toward `amount`; -: crushed (values under -amount go to 0).
static func _lift(x: float, amount: float) -> float:
	if amount > 0.0:
		return amount + x * (1.0 - amount)
	var a := -amount
	return clampf((x - a) / (1.0 - a), 0.0, 1.0)
