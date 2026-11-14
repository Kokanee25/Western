class_name SkyModel
extends RefCounted
## The real look's atmosphere (#918): the numbers and the CPU half of the physically based sky
## (src/render/real_sky.gdshader draws it; RealSky lights the world from it). Pure maths, no nodes,
## so the tests can ask it what colour the sun is at any hour.
##
## Methods, from published work (no code copied):
## - Single scattering by air (Rayleigh) and dust (Mie) with ozone absorption, the coefficients and
##   density profiles of Hillaire 2020 ("A Scalable and Production Ready Sky and Atmosphere
##   Rendering Technique", EGSR) and Bruneton 2017's reference model ("Precomputed Atmospheric
##   Scattering: a New Implementation"): Rayleigh scale height 8 km, Mie 1.2 km, ozone a tent
##   at 25 km, 30 km wide. Ozone is what keeps the twilight sky overhead blue (Hulburt 1953).
## - The transmittance to the sun precomputed into a small table by altitude and sun angle
##   (Bruneton & Neyret 2008, "Precomputed Atmospheric Scattering"), so a sample along a view ray
##   reads the light reaching it with one lookup; below the horizon it is the Earth's shadow.
## - Multiple scattering approximated as an isotropic share of the single (the idea of Hillaire
##   2020's multiple-scattering term, reduced to one dial: `multi`).
## - The Mie phase function of Cornette & Shanks 1992; Rayleigh's own.
## - The moon's brightness by phase angle from Allen's Astrophysical Quantities (the magnitude
##   law m(a) = 0.026|a| + 4e-9 a^4, a in degrees).
##
## Units: metres; the planet's centre is the origin of the maths, the camera at `altitude` metres
## above its surface plus its own height in the world. Radiance is relative to a sun of
## illuminance 1, scaled for the screen by `gain`.

const R_GROUND := 6360000.0
const R_TOP := 6460000.0
const RAYLEIGH := Vector3(5.802e-6, 13.558e-6, 33.1e-6)
const RAYLEIGH_H := 8000.0
const MIE_SCATTER := 3.996e-6
const MIE_EXTINCT := 4.440e-6
const MIE_H := 1200.0
const OZONE := Vector3(0.650e-6, 1.881e-6, 0.085e-6)
const OZONE_CENTRE := 25000.0
const OZONE_HALF := 15000.0
## The moon's mean synodic month (days).
const SYNODIC := 29.530589

## The transmittance table's size (u: the sun's angle, v: altitude); see `lut_uv`.
const LUT_W := 128
const LUT_H := 32
const LUT_STEPS := 40

## The sky's dials (config/looks/real_sky.json "sky" overrides them). `turbidity` scales the dust
## (Mie; the high desert's dry air is clear but dusty near the ground), `altitude` the town's height
## above the sea (valley.json: about 2,070 m).
var turbidity := 1.0
var mie_g := 0.8
var altitude := 2070.0
var multi := 0.35
var gain := 24.0

var _lut: Image
var _lut_key := -1.0


## The table of transmittance from a point at radius r looking at cos-zenith mu to the top of the
## air (0 where the ray meets the ground): RGB float, LUT_W x LUT_H, built once per turbidity.
func lut() -> Image:
	if _lut != null and is_equal_approx(_lut_key, turbidity):
		return _lut
	_lut = Image.create_empty(LUT_W, LUT_H, false, Image.FORMAT_RGBF)
	for j in LUT_H:
		for i in LUT_W:
			var rm := lut_inverse(Vector2((i + 0.5) / LUT_W, (j + 0.5) / LUT_H))
			var t := transmittance_exact(rm.x, rm.y)
			_lut.set_pixel(i, j, Color(t.x, t.y, t.z))
	_lut_key = turbidity
	return _lut


## The table's texture (for the shader).
func lut_texture() -> ImageTexture:
	return ImageTexture.create_from_image(lut())


## Where (r, mu) sits in the table: u packs mu by sqrt either side of the horizon (fine steps where
## the sun sets), v the altitude by its square root (the air is thick low down).
static func lut_uv(r: float, mu: float) -> Vector2:
	var h := clampf(r - R_GROUND, 0.0, R_TOP - R_GROUND)
	var u := 0.5 + 0.5 * signf(mu) * sqrt(absf(clampf(mu, -1.0, 1.0)))
	var v := sqrt(h / (R_TOP - R_GROUND))
	return Vector2(u, v)


## (r, mu) from a table position (lut_uv's inverse).
static func lut_inverse(uv: Vector2) -> Vector2:
	var s := 2.0 * uv.x - 1.0
	var mu := signf(s) * s * s
	var h := uv.y * uv.y * (R_TOP - R_GROUND)
	return Vector2(R_GROUND + h, mu)


## Air, dust and ozone densities (relative) at height h above the ground.
static func densities(h: float) -> Vector3:
	var oz := maxf(0.0, 1.0 - absf(h - OZONE_CENTRE) / OZONE_HALF)
	return Vector3(exp(-h / RAYLEIGH_H), exp(-h / MIE_H), oz)


## Extinction (per metre, RGB) at height h.
func extinction(h: float) -> Vector3:
	var d := densities(h)
	return RAYLEIGH * d.x + Vector3.ONE * (MIE_EXTINCT * turbidity * d.y) + OZONE * d.z


## The distance along (r, mu) to the top of the air, or to the ground if it meets it first
## (negative return of `hits_ground`).
static func ray_length(r: float, mu: float) -> Vector2:
	var disc_g := r * r * (mu * mu - 1.0) + R_GROUND * R_GROUND
	if mu < 0.0 and disc_g >= 0.0:
		return Vector2(-r * mu - sqrt(disc_g), 1.0)  # (distance, hits the ground)
	var disc_t := r * r * (mu * mu - 1.0) + R_TOP * R_TOP
	return Vector2(-r * mu + sqrt(maxf(disc_t, 0.0)), 0.0)


## Transmittance from (r, mu) to the top of the air by a march (LUT_STEPS); 0 if the ray meets the
## ground (the Earth's shadow).
func transmittance_exact(r: float, mu: float) -> Vector3:
	var rl := ray_length(r, mu)
	if rl.y > 0.5:
		return Vector3.ZERO
	var dt := rl.x / LUT_STEPS
	var od := Vector3.ZERO
	for k in LUT_STEPS:
		var t := (k + 0.5) * dt
		var rr := sqrt(r * r + t * t + 2.0 * r * mu * t)
		od += extinction(rr - R_GROUND) * dt
	return Vector3(exp(-od.x), exp(-od.y), exp(-od.z))


## Transmittance read from the table (bilinear), as the shader reads it.
func transmittance(r: float, mu: float) -> Vector3:
	var img := lut()
	var uv := lut_uv(r, mu)
	var x := clampf(uv.x * LUT_W - 0.5, 0.0, LUT_W - 1.0)
	var y := clampf(uv.y * LUT_H - 0.5, 0.0, LUT_H - 1.0)
	var i := mini(int(x), LUT_W - 2)
	var j := mini(int(y), LUT_H - 2)
	var fx := x - i
	var fy := y - j
	var a := img.get_pixel(i, j).lerp(img.get_pixel(i + 1, j), fx)
	var b := img.get_pixel(i, j + 1).lerp(img.get_pixel(i + 1, j + 1), fx)
	var c := a.lerp(b, fy)
	return Vector3(c.r, c.g, c.b)


## The radius of a point `height` metres over the world's ground (the town's altitude under it).
func radius_at(height := 0.0) -> float:
	return R_GROUND + altitude + maxf(height, 0.0)


## The sunlight reaching a point `height` metres up, with the sun toward `light_dir` (RGB, the
## sun's illuminance being 1). Zero once the sun is under that point's horizon.
func light_at(light_dir: Vector3, height := 0.0) -> Vector3:
	return transmittance(radius_at(height), light_dir.y)


static func phase_rayleigh(c: float) -> float:
	return 3.0 / (16.0 * PI) * (1.0 + c * c)


static func phase_mie(c: float, g: float) -> float:
	var g2 := g * g
	return 3.0 / (8.0 * PI) * (1.0 - g2) * (1.0 + c * c) / ((2.0 + g2) * pow(1.0 + g2 - 2.0 * g * c, 1.5))


## The sky's radiance toward `d` (a unit direction, y up) lit by one light toward `light_dir` of
## illuminance 1: the same single-scattering march the shader makes (fewer steps), times `gain`.
func radiance(d: Vector3, light_dir: Vector3, steps := 12) -> Vector3:
	var r0 := radius_at()
	var rl := ray_length(r0, d.y)
	var tmax := rl.x
	var cam := Vector3(0.0, r0, 0.0)
	var c := d.dot(light_dir)
	var pr := phase_rayleigh(c)
	var pm := phase_mie(c, mie_g)
	var od := Vector3.ZERO
	var sum := Vector3.ZERO
	var t_prev := 0.0
	for k in steps:
		# Samples crowd near the eye, where the air is thick (t ~ s^2).
		var s := (k + 1.0) / steps
		var t := tmax * s * s
		var dt := t - t_prev
		var tm := t_prev + dt * 0.5
		t_prev = t
		var p := cam + d * tm
		var r := p.length()
		var h := r - R_GROUND
		var dens := densities(h)
		od += extinction(h) * dt
		var tv := Vector3(exp(-od.x), exp(-od.y), exp(-od.z))
		var tl := transmittance(r, (p / r).dot(light_dir))
		var sr := RAYLEIGH * dens.x
		var sm := MIE_SCATTER * turbidity * dens.y
		var single := sr * pr + Vector3.ONE * sm * pm
		var ms := (sr + Vector3.ONE * sm) * (multi / (4.0 * PI))
		sum += tv * tl * (single + ms) * dt
	return sum * gain


## The moon's phase on a day (0 new, 0.5 full; `full_day`: the day number of a full moon), with
## the hour carrying it on through the day.
static func moon_phase(day: int, hour: float, full_day := 1.0) -> float:
	return fposmod(0.5 + (float(day) - full_day + (hour - 12.0) / 24.0) / SYNODIC, 1.0)


## How far the moon's hour trails the full moon's path (hours: DayCycle's moon is full, opposite
## the sun; a waxing moon rides with the sun, ~50 minutes later each night).
static func moon_hour_lag(phase: float) -> float:
	return (phase - 0.5) * 24.0 * (1.0 + 1.0 / SYNODIC)


## The share of a full moon's light at this phase (Allen's phase law; 0 at new, 1 at full).
static func moon_brightness(phase: float) -> float:
	var a := absf(phase - 0.5) * 360.0  # the phase angle, degrees (0 full, 180 new)
	return pow(10.0, -0.4 * (0.026 * a + 4e-9 * pow(a, 4.0)))


## The direction the sun lights the moon from, for drawing its phase: `elong` from the moon toward
## the real sun in their common plane (the moon's arc is not the sun's, so the real angle between
## them doesn't say the phase; this does, with the bright limb toward the sun).
static func moon_lit_from(moon_dir: Vector3, sun_dir: Vector3, phase: float) -> Vector3:
	var elong := (1.0 - absf(phase - 0.5) * 2.0) * PI  # 0 new, PI full
	var side := sun_dir - moon_dir * sun_dir.dot(moon_dir)
	if side.length_squared() < 1e-8:
		side = Vector3.UP - moon_dir * moon_dir.y
	side = side.normalized()
	# elong is the moon's angle from the sun: the sun stands `elong` from the moon, so seen at the
	# moon the light comes from -moon_dir rotated toward `side` by (PI - elong).
	var back := -moon_dir
	return (back * cos(PI - elong) + side * sin(PI - elong)).normalized()


## The celestial pole for the stars' turn: `lat` degrees up, on the side of the sky away from the
## noon sun (north of the arc, whichever way the world's sun runs).
static func pole(noon_sun: Vector3, lat_deg: float) -> Vector3:
	var away := -Vector3(noon_sun.x, 0.0, noon_sun.z)
	if away.length_squared() < 1e-8:
		away = Vector3.BACK
	away = away.normalized()
	var lat := deg_to_rad(lat_deg)
	return (away * cos(lat) + Vector3.UP * sin(lat)).normalized()


## The stars' frame at an hour of a day: turned round the pole once a sidereal day.
static func star_basis(pole_dir: Vector3, day: int, hour: float) -> Basis:
	var turns := hour / 24.0 + float(day) / 365.2422
	return Basis(pole_dir, -turns * TAU * 1.0027379)


static func luminance(c: Vector3) -> float:
	return c.x * 0.2126 + c.y * 0.7152 + c.z * 0.0722
