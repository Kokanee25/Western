extends TestCase
func test_probe() -> void:
	var cfg: DayCycleConfig = load("res://config/day_cycle.tres")
	var d := DayCycle.new()
	d.config = cfg
	var eye := StreetMatch.camera_transform()
	print("eye ", eye.origin, " look ", StreetMatch.look())
	var f := -eye.basis.z
	print("look bearing ", fposmod(rad_to_deg(atan2(f.x, -f.z)), 360.0), " pitch ", rad_to_deg(asin(f.y)))
	for h in [17.6, 17.75, 17.9, 18.0]:
		var s := d.get_sun_direction(h)
		print("hour ", h, " sun bearing ", fposmod(rad_to_deg(atan2(s.x, -s.z)), 360.0), " elev ", rad_to_deg(asin(s.y)))
	print("centre ", Backdrop.CENTRE)
	d.free()
