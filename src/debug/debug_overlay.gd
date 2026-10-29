extends CanvasLayer
## Developer overlay drawn at full window resolution (the game itself has almost no HUD).
## F1 shows the controls, F3 shows clock/speed/resolution readouts.

const HELP := """SALT CREEK — test street
Guns (you start holstered; H draws): cock Q / wheel down / RB, fire LMB / RT, aim RMB / LT, reload R / X (hold), holster H / LB     Revolver 1, shotgun 2, dynamite 3, next wheel up / Y
Dynamite: Q lights the fuse, hold LMB and let go to throw (longer = harder), RMB sets it down; don't hold it lit too long
Move: WASD / left stick     Look: mouse / right stick
Run: hold Shift / click left stick     Crouch: hold Ctrl, or C / B     Shove: tap E / click right stick (hold and let go: kick)
Jump: Space / A     Time held / running / faster: T     Noon / afternoon / golden hour / night: 7     Light look (today, A, B, C): 8     Start again: Backspace     Debug readout: F3 / View     Movement light / middle / heavy: F
Pixel size: F2 (last = native)     Pixel shading: F6     Texel size: F7     Tiles off/square/ragged: P     Jump to next place (street, store, saloon, range): F5 / D-pad up     Bullet traces: F8
The outlaw (range, F5): shoot at him and he fights back.  Shout "Drop it!": G / D-pad left
Press on your wounds (hold for a belt): B / D-pad down     New outlaw: F9 / D-pad right     Bring the gang into town: U     Three gunmen in the saloon (A/B/C playtest): Y next run, X this run again, Z free play     Call a man out: G with your gun holstered     X-ray (see the anatomy): F10     Break the timber you're looking at: K (or F11)     Set it alight: L     Save a bug report: F12 / Back + Y     Tear a wound open: J     Reduced gore: F4     Look panel (sliders for the light and squares): N / Back + Start
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
	Events.time_scale_changed.connect(_show_time)
	if GameReset.just_reset:
		GameReset.just_reset = false
		toast.call_deferred("Started again (Backspace)")
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


## T and 7: the clock held or running, and the hour.
func _show_time(_scale: float) -> void:
	var clock := get_tree().get_first_node_in_group(&"day_cycle") as DayCycle
	if clock == null:
		return
	toast(clock.describe_speed())


## A line at the bottom of the screen for a few seconds.
func toast(text: String, seconds := 3.0) -> void:
	_toast.text = text
	_toast.visible = true
	_toast_timer = seconds


## F: which way of moving you've switched to (Player.next_movement).
func _show_movement(preset: StringName) -> void:
	var about := {&"light": "quick on your feet", &"middle": "the game's own", &"heavy": "a big man in boots"}
	_toast.text = "Movement: %s (%s)   F for the next" % [String(preset).to_upper(), about.get(preset, "")]
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
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player and not player.movement_changed.is_connected(_show_movement):
		player.movement_changed.connect(_show_movement)
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
		lines.append("%.1f m/s %s   pos %.1f, %.1f, %.1f   moving %s" % [player.get_horizontal_speed(), state, p.x, p.y, p.z, player.movement])
		if player.wounds:
			lines.append(player.wounds.describe())
		if player.composure and player.weapon:
			lines.append("Hands: %s; gun %.2f° off line" % [player.composure.describe(), player.weapon.sway.length()])
	# Gunmen first (their state and last decision), then the townsfolk.
	var people := get_tree().get_nodes_in_group(&"people")
	var gunman := func(n: Node) -> bool: return n.get_node_or_null(^"Brain") is OutlawBrain
	people = people.filter(gunman) + people.filter(func(n: Node) -> bool: return not gunman.call(n))
	for n in people:
		var brain := n.get_node_or_null(^"Brain")
		if brain and brain.has_method(&"describe"):
			lines.append(brain.describe())
			for w in (n as HumanBody).describe_wounds():
				lines.append("  " + w)
	lines.append("%d fps   look: %s   %s" % [Engine.get_frames_per_second(), Settings.look_description(), build_label()])
	lines.append(native_label() + ("   physics on its own thread" if Settings.physics_thread else "   physics on the main thread")
			+ ("   render on its own thread" if Settings.render_thread else "   render on the main thread"))
	lines.append_array(frame_lines())
	return "\n".join(lines)


var _viewports: Array[RID] = []
var _render_cpu := 0.0
var _render_gpu := 0.0
var _render_read := 0
## With the render thread, asking for a viewport's render time waits for the draw in flight (Godot
## warns of a sync every frame): the readout would take away what the thread gives. So it asks
## twice a second then, and shows the last answer between.
const RENDER_READ_FRAMES := 30


## Whether Prof was on before the readout opened (the gunfight lab's Y play turns it on itself).
var _prof_was_on := false


## Timing on while the readout's up: render times per viewport, and Prof's timers. Opening it
## starts the sums afresh (#435: with Prof already on for a lab, the first frame read everything
## they'd held since the start, `rest` 7,449 ms); closing it leaves Prof as it found it.
func _measure(on: bool) -> void:
	_viewports.clear()
	if not on:
		Prof.on = _prof_was_on
		return
	_prof_was_on = Prof.on
	Prof.reset()
	Prof.on = true
	for vp in [get_tree().root] + get_tree().root.find_children("*", "SubViewport", true, false):
		var rid: RID = (vp as Viewport).get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(rid, true)
		_viewports.append(rid)


## Where the frame goes (for Sean to read off): the frame, what scripts and physics take of it (the
## last second's means of each frame's own, from the bug report's ring: Godot's TIME_PROCESS and
## TIME_PHYSICS_PROCESS are a second's worst frame and worst single tick, #435), the renderer's CPU
## and GPU time, what it drew, and the systems that cost most.
func frame_lines() -> PackedStringArray:
	if not Settings.render_thread or Engine.get_frames_drawn() - _render_read >= RENDER_READ_FRAMES:
		_render_read = Engine.get_frames_drawn()
		_render_cpu = 0.0
		_render_gpu = 0.0
		for rid in _viewports:
			_render_cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
			_render_gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	var render_cpu := _render_cpu
	var render_gpu := _render_gpu
	var fps := maxf(Engine.get_frames_per_second(), 1.0)
	var out: PackedStringArray = []
	var sec := _ring_second()
	if sec.is_empty():
		out.append("frame %.1f ms: render cpu %.1f, gpu %.1f" % [1000.0 / fps, render_cpu, render_gpu])
	else:
		out.append("frame %.1f ms: process %.1f, physics %.1f (%.1f ticks), render cpu %.1f, gpu %.1f" % [
				sec.frame_ms, sec.process_ms, sec.physics_ms, sec.ticks, render_cpu, render_gpu])
	out.append("draws %d  objects %d  tris %dk  nodes %d  bodies awake %d" % [
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000,
			Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)])
	if not Prof.per_frame.is_empty():
		out.append("ms a frame: " + "  ".join(Prof.top(8)))
	return out


var _recorder: BugRecorder


## The bug report's ring's last second (BugRecorder's PerfRing), {} without one.
func _ring_second() -> Dictionary:
	if _recorder == null or not is_instance_valid(_recorder):
		_recorder = get_tree().root.find_child("BugRecorder", true, false) as BugRecorder
	if _recorder == null or not _recorder.perf_on:
		return {}
	return _recorder.perf.last_second()
