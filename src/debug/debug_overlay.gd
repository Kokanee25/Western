extends CanvasLayer
## Developer overlay drawn at full window resolution (the game itself has almost no HUD).
## F1 shows the controls, F3 shows clock/speed/resolution readouts.

const HELP := """SALT CREEK — test street
Guns (you start holstered; H draws): cock Q / wheel down / RB, fire LMB / RT, aim RMB / LT, reload R / X (hold), holster H / LB     Revolver 1, shotgun 2, dynamite 3, next wheel up / Y
Dynamite: Q lights the fuse, hold LMB and let go to throw (longer = harder), RMB sets it down; don't hold it lit too long
Move: WASD / left stick     Look: mouse / right stick
Run: hold Shift / click left stick     Crouch: hold Ctrl, or C / B
Jump: Space / A     Time speed: T     Debug readout: F3 / View
Pixel size: F2 (last = native)     Pixel shading: F6     Texel size: F7     Tiles off/square/ragged: P     Jump to next place (street, store, saloon, range): F5 / D-pad up     Bullet traces: F8
The outlaw (range, F5): shoot at him and he fights back.  Shout "Drop it!": G / D-pad left
Press on your wounds (hold for a belt): B / D-pad down     New outlaw: F9 / D-pad right     Bring the gang into town: U     Call a man out: G with your gun holstered     X-ray (see the anatomy): F10     Break the timber you're looking at: K (or F11)     Set it alight: L (or F12)     Tear a wound open: J     Reduced gore: F4
Release mouse: Esc     This help: F1"""

var _help: Label
var _readout: Label
var _help_timer := 14.0
var _toast: Label
var _corner: Label
var _toast_timer := 0.0


## The native plugin (addons/saltcreek_native): its version and threads, or that it isn't loaded
## (the web build, or a build made without it).
static func native_label() -> String:
	if not ClassDB.class_exists(&"NativeBench"):
		return "native plugin: not loaded"
	var bench: Object = ClassDB.instantiate(&"NativeBench")
	var label := "native plugin: %s, %d threads" % [bench.version(), bench.threads()]
	bench.free()
	return label


## "build 23 (ad725f2)" from build_info.json, written by CI at export; "dev build" otherwise.
static func build_label() -> String:
	var text := FileAccess.get_file_as_string("res://build_info.json")
	var info: Variant = JSON.parse_string(text) if text != "" else null
	if info is Dictionary:
		return "build %s (%s)" % [info.get("number", "?"), info.get("commit", "?")]
	return "dev build"


func _ready() -> void:
	_help = _label(Vector2(16, 16))
	_help.text = ("SALT CREEK  %s\n" % build_label().to_upper()) + HELP.replace("SALT CREEK — test street\n", "")
	# Always in the corner, small, so it's obvious which build is running.
	_corner = _label(Vector2.ZERO)
	_corner.text = build_label()
	_corner.add_theme_font_size_override(&"font_size", 12)
	_corner.modulate = Color(1, 1, 1, 0.55)
	_readout = _label(Vector2(16, 16))
	_readout.visible = false
	# Flash the look settings whenever F2 / F6 / F7 / P change them.
	_toast = _label(Vector2(16, 16))
	_toast.visible = false
	_toast.add_theme_font_size_override(&"font_size", 22)
	Settings.changed.connect(_show_look)
	if DisplayServer.is_touchscreen_available():
		_help.text = ("SALT CREEK  %s\n" % build_label().to_upper()) + "Left thumb: move   Right thumb: look\nButtons: cock, fire, load, aim, jump, crouch, run, time, gun (swap)"


func _label(pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override(&"font_size", 16)
	l.add_theme_color_override(&"font_color", Color(1.0, 0.95, 0.85))
	l.add_theme_color_override(&"font_outline_color", Color(0.05, 0.03, 0.02))
	l.add_theme_constant_override(&"outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _show_look() -> void:
	_toast.text = Settings.look_description()
	_toast.visible = true
	_toast_timer = 3.0


func _process(delta: float) -> void:
	var vp_size := get_viewport().get_visible_rect().size
	_corner.position = Vector2(vp_size.x - _corner.size.x - 8.0, vp_size.y - _corner.size.y - 4.0)
	if _toast_timer > 0.0:
		_toast_timer -= delta
		_toast.visible = _toast_timer > 0.0
		var vp := get_viewport().get_visible_rect().size
		_toast.position = Vector2((vp.x - _toast.size.x) * 0.5, vp.y - _toast.size.y - 40.0)
	if Input.is_action_just_pressed(&"debug_help"):
		_help.visible = not _help.visible
		_help_timer = -1.0
	if Input.is_action_just_pressed(&"debug_overlay"):
		_readout.visible = not _readout.visible
		_measure(_readout.visible)
	if Input.is_action_just_pressed(&"debug_xray"):
		HumanBody.xray_all = not HumanBody.xray_all
		get_tree().call_group(&"people", &"set_xray", HumanBody.xray_all)
		_toast.text = "X-ray %s: bones, arteries (red), veins (blue), organs, nerves (yellow); damage in orange" % ("on" if HumanBody.xray_all else "off")
		_toast_timer = 3.0
		_toast.visible = true
	if _help_timer > 0.0:
		_help_timer -= delta
		if _help_timer <= 0.0:
			_help.visible = false
	_readout.position.y = _help.position.y + (_help.size.y + 8.0 if _help.visible else 0.0)
	if _readout.visible:
		Prof.frame()
		_readout.text = _readout_text()


func _readout_text() -> String:
	var lines: PackedStringArray = []
	var clock := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	if clock:
		lines.append("Day %d  %s  x%s time" % [clock.day, clock.get_clock_text(), str(clock.time_scale)])
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player:
		var state := "crouching" if player.is_crouching else ("running" if player.is_running else "walking")
		var p := player.global_position
		lines.append("%.1f m/s %s   pos %.1f, %.1f, %.1f" % [player.get_horizontal_speed(), state, p.x, p.y, p.z])
		if player.wounds:
			lines.append(player.wounds.describe())
		if player.composure and player.weapon:
			lines.append("Hands: %s; gun %.2f° off line" % [player.composure.describe(), player.weapon.sway.length()])
	for n in get_tree().get_nodes_in_group(&"people"):
		var brain := n.get_node_or_null(^"Brain")
		if brain and brain.has_method(&"describe"):
			lines.append(brain.describe())
			for w in (n as HumanBody).describe_wounds():
				lines.append("  " + w)
	lines.append("%d fps   look: %s   %s" % [Engine.get_frames_per_second(), Settings.look_description(), build_label()])
	lines.append(native_label())
	lines.append_array(frame_lines())
	return "\n".join(lines)


var _viewports: Array[RID] = []


## Timing on while the readout's up: render times per viewport, and Prof's timers.
func _measure(on: bool) -> void:
	Prof.on = on
	_viewports.clear()
	if not on:
		return
	for vp in [get_tree().root] + get_tree().root.find_children("*", "SubViewport", true, false):
		var rid: RID = (vp as Viewport).get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(rid, true)
		_viewports.append(rid)


## Where the frame goes (for Sean to read off): the frame, what scripts and physics take of it,
## the renderer's CPU and GPU time, what it drew, and the systems that cost most.
func frame_lines() -> PackedStringArray:
	var render_cpu := 0.0
	var render_gpu := 0.0
	for rid in _viewports:
		render_cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		render_gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	var fps := maxf(Engine.get_frames_per_second(), 1.0)
	var out: PackedStringArray = []
	out.append("frame %.1f ms: process %.1f, physics %.1f, render cpu %.1f, gpu %.1f" % [1000.0 / fps,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, render_cpu, render_gpu])
	out.append("draws %d  objects %d  tris %dk  nodes %d  bodies awake %d" % [
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000,
			Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)])
	if not Prof.per_frame.is_empty():
		out.append("ms a frame: " + "  ".join(Prof.top(8)))
	return out
