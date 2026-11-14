class_name Act
extends Moment
## A mission's scene, the first cut of "acts" (roadmap 3.5; docs/missions/BUILD_ORDER.md's 0.1,
## started by the sheriff on the road, issue #746): a Moment (a situation from data, played by the
## systems) with what a story scene needs on top:
## - lines chosen by a man's state: `lines.<beat>.<band>` in the data, the band by his blood loss
##   (`bands`: clear, weak, fading; out when he's not conscious), a list taken in turn;
## - typed cards (a black screen and a line: the stand-ins for what isn't built, a ride, a wait);
## - prompts on screen (what a key does here);
## - the story facts it sets (StoryState), stamped with the clock.
## Small on purpose: the next mission grows it, and when two have used it it's tidied into a system.

## The blood-loss bands by default (`bands` in the data overrides): under each share lost, that band.
const BANDS := {"clear": 0.22, "weak": 0.32, "fading": 0.5}

var _said := {}  # beat -> how many of its lines have been said
var _card_layer: CanvasLayer
var _card_label: Label
var _card_left := 0.0
var _player: Player


func player() -> Player:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Player
	return _player


func clock() -> DayCycle:
	return street.find_child("DayCycle", true, false) as DayCycle if street else null


## A man's band by his body: out (not conscious), else by blood lost (`bands`).
func band_of(p: Physiology) -> String:
	if p == null or not p.alive:
		return "dead"
	if not p.is_conscious():
		return "out"
	return band_for_loss(p.blood_loss(), data.get("bands", BANDS))


static func band_for_loss(loss: float, bands: Dictionary = BANDS) -> String:
	var best := ""
	var best_at := INF
	for k: String in bands:
		var at := float(bands[k])
		if loss < at and at < best_at:
			best = k
			best_at = at
	return best if best != "" else "fading"


## The beat's next line for this band (`lines.<beat>.<band>`, else `lines.<beat>.any`); "" if none.
## A list is said in turn and its last line kept; a string is the line.
func line(beat: String, band := "any") -> String:
	var all: Dictionary = data.get("lines", {})
	var by: Variant = all.get(beat, {})
	var l: Variant = (by as Dictionary).get(band, (by as Dictionary).get("any", "")) if by is Dictionary else by
	if l is Array:
		var arr := l as Array
		if arr.is_empty():
			return ""
		var k := "%s.%s" % [beat, band]
		var i := mini(int(_said.get(k, 0)), arr.size() - 1)
		_said[k] = i + 1
		return String(arr[i])
	return String(l)


## A man says it (his mouth, FaceSpeech; the subtitle, PlayerWounds; DeedWatch hears it).
func speak(man: Node, text: String) -> void:
	if text != "" and man != null and is_instance_valid(man):
		Events.spoke.emit(man, text)


## A line on screen for the player (what a key does here).
func prompt(text: String, seconds := 2.0, hold := false) -> void:
	var p := player()
	if p and p.wounds and text != "":
		p.wounds.say(text, seconds, hold)


## A typed card: the screen goes black with a line for `seconds` (a stand-in for what isn't built:
## a ride, a wait, a time later).
func card(text: String, seconds := 4.0) -> void:
	if _card_layer == null:
		_card_layer = CanvasLayer.new()
		_card_layer.layer = 90
		add_child(_card_layer)
		var black := ColorRect.new()
		black.color = Color(0.03, 0.025, 0.02, 0.96)
		black.set_anchors_preset(Control.PRESET_FULL_RECT)
		black.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_card_layer.add_child(black)
		_card_label = Label.new()
		_card_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_card_label.add_theme_color_override(&"font_color", Color(0.93, 0.88, 0.78))
		_card_label.add_theme_font_size_override(&"font_size", 26)
		black.add_child(_card_label)
	_card_label.text = text
	_card_layer.visible = true
	_card_left = seconds
	_note("card: " + text)


func card_up() -> bool:
	return _card_layer != null and _card_layer.visible


## The card's own clock (call each tick).
func card_step(delta: float) -> void:
	if _card_left > 0.0:
		_card_left -= delta
		if _card_left <= 0.0 and _card_layer:
			_card_layer.visible = false


## Set a story fact, stamped with the clock's day and hour.
func fact(key: String, value: Variant) -> void:
	var c := clock()
	StoryState.set_fact(key, value, c.day if c else 1, c.time_of_day if c else -1.0)
	_note("fact %s = %s" % [key, str(value)])


## What happened when (game seconds since it started), for the bridge and the runs.
var timeline: Array = []


func _note(what: String) -> void:
	timeline.append([snappedf(t, 0.01), what])
