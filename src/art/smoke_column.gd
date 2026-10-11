class_name SmokeColumn
extends MeshInstance3D
## A burning building's smoke column over its roofline (smoke_sheet.gdshader): the simulated smoke
## (SmokeField) can't be drawn against the sky, so above the roof this draws it. Each SmokeField
## that can draw makes one (`over`). Twice a second it looks at the building's burning members:
## the column stands over where they burn, as wide as they spread, as tall and thick as there are
## of them, and leans with the wind; it eases toward that, and fades out when the fire's out.

const SHEET := preload("res://src/fire/smoke_sheet.gdshader")
## How often it looks at the fire (s).
const LOOK_EVERY := 0.5
## Burning members for a full column.
const FULL := 30.0
## How fast it eases toward what the fire asks for (a share a second).
const EASE := 0.6
## Metres sideways a metre up, a metre a second of wind (smoke climbing at about 1.2 m/s).
const LEAN := 0.45

static var _mat: ShaderMaterial
static var _quad: QuadMesh

var field: SmokeField
var _top := 0.0
var _wind := Vector3.ZERO
var _look := 0.0
var _want := Vector4.ZERO  # x, z of its foot, its width, its strength
var _have := Vector4.ZERO
var _started := false


## A column over `f`'s building, made its child.
static func over(f: SmokeField) -> SmokeColumn:
	var c := SmokeColumn.new()
	c.field = f
	c.name = "SmokeColumn"
	f.add_child(c)
	return c


func _ready() -> void:
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = SHEET
		_quad = QuadMesh.new()
		_quad.size = Vector2.ONE
	mesh = _quad
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	top_level = true
	var gun_smoke: Resource = load("res://config/smoke.tres")
	_wind = gun_smoke.get(&"wind") if gun_smoke else Vector3.ZERO
	_top = _roofline()
	set_instance_shader_parameter(&"lean", Vector2(_wind.x, _wind.z) * LEAN)
	set_instance_shader_parameter(&"strength", 0.0)
	visible = false


func _process(delta: float) -> void:
	_look -= delta
	if _look <= 0.0:
		_look = LOOK_EVERY
		_want = _from_fire()
		if not _started and _want.w > 0.0:
			# The first look sets it at once (a fire seen for the first time is already burning).
			_have = _want
			_started = true
	var k := clampf(EASE * delta, 0.0, 1.0)
	# Where it stands follows the fire quickly; how much there is, slowly.
	_have = Vector4(lerpf(_have.x, _want.x, k * 2.0), lerpf(_have.y, _want.y, k * 2.0),
			lerpf(_have.z, _want.z, k), lerpf(_have.w, _want.w, k))
	visible = _have.w > 0.02
	if not visible:
		return
	global_position = Vector3(_have.x, _top, _have.y)
	var tall := 6.0 + 14.0 * _have.w
	set_instance_shader_parameter(&"size", Vector2(_have.z, tall))
	set_instance_shader_parameter(&"strength", _have.w)
	var r := _have.z * 2.0 + tall * 1.5 + 2.0
	custom_aabb = AABB(Vector3(-r, -1.0, -r), Vector3(2.0 * r, tall + 2.0, 2.0 * r))


## Where the building's fire is (x, z), how far it spreads (the column's width) and how much
## of it there is (0 to 1).
func _from_fire() -> Vector4:
	if field == null or not is_instance_valid(field.structure) or field.fire == null:
		return Vector4(_have.x, _have.y, _have.z, 0.0)
	var n := 0
	var sum := Vector2.ZERO
	var sum2 := Vector2.ZERO
	for m in field.fire.burning_members():
		if m.get_parent() != field.structure:
			continue
		var p := m.global_position
		sum += Vector2(p.x, p.z)
		sum2 += Vector2(p.x * p.x, p.z * p.z)
		n += 1
	if n == 0:
		return Vector4(_have.x, _have.y, _have.z, 0.0)
	var mean := sum / n
	var spread := (sum2 / n - mean * mean).max(Vector2.ZERO)
	var width := clampf(1.6 * sqrt(maxf(spread.x, spread.y)) + 1.0, 1.0, 8.0)
	return Vector4(mean.x, mean.y, width, clampf(sqrt(n / FULL), 0.15, 1.0))


## The building's roofline: the top of what still stands of it.
func _roofline() -> float:
	var top := -INF
	if field != null and is_instance_valid(field.structure):
		for m: StructureMember in field.structure.get_members():
			if not m.broken and not m.consumed:
				top = maxf(top, m.world_aabb().end.y)
	return top if top > -INF else field.box().end.y - field.tuning.smoke_above
