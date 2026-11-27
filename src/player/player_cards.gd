class_name PlayerCards
extends Node
## Your hand at the card table (#1294; CardGame; dials config/card_game.json `hand`): sat in a chair at
## a game you're dealt into, your five cards lie face down before you till you lift them: hold aim
## (right-click, LT) or look down past `hand.look_down_deg`, and Harlan's right hand brings them up
## fanned (first person, on the held layer, as a drink is held in the left: PlayerDrink, so a glass and
## a hand of cards go together); let go and they're set back down. Nobody else sees them till the showdown turns them up.
##
## The keys at the table (only sat there, only on your turn or your draw; the nod, the shake and G's cheat
## work as ever): on your bet, jump (Space, A) calls or checks, crouch's toggle (C, B) folds, fire
## (click, RT) raises by your amount and forward/back (W/S, the stick) sets it within the round's limit;
## at your draw (the cards come up by themselves) left/right (A/D, the stick) picks a card, jump marks
## it to throw (it rides up out of the fan), fire draws. What they do is told in the table's prompts
## (PlayerWounds.say), not on a HUD.

var player: Player
var game: CardGame
## Which card your thumb's on at the draw (0..4, left to right).
var pick := 2

var _lift := 0.0
var _hold: Node3D
var _hand: HeldHand
var _cards: Array[MeshInstance3D] = []
var _was: CardGame


func _ready() -> void:
	_build()


func _d() -> Dictionary:
	return (CardGame.data_file() as Dictionary).get("hand", {})


func _n(k: String, dflt: float) -> float:
	return float(_d().get(k, dflt))


func _v(k: String, dflt: Vector3) -> Vector3:
	var a: Array = _d().get(k, [])
	return Vector3(float(a[0]), float(a[1]), float(a[2])) if a.size() == 3 else dflt


## The game whose chair you're sat in, you dealt in.
func _game() -> CardGame:
	if player == null or player.seat == null or not player.seat.seated() or not player.is_inside_tree():
		return null
	for n: Node in player.get_tree().get_nodes_in_group(&"card_game"):
		var g := n as CardGame
		if g.chairs.has(player.seat.chair) and g.you_in() and g.your_cards().size() == 5:
			return g
	return null


## Fire is the table's (a raise, a draw) on your turn: a drink in your hand doesn't take it.
func claims_fire() -> bool:
	return game != null and (game.your_turn() or game.you_drawing)


## Whether you're holding them up (aim, looking down, or your draw).
func wants_lift() -> bool:
	if game == null:
		return false
	if game.you_drawing:
		return true
	if player.input_enabled and Input.is_action_pressed(&"aim"):
		return true
	return player.get_pitch_degrees() < -_n("look_down_deg", 42.0) or force_lift


## Held up by the bridge or a test.
var force_lift := false


func _physics_process(delta: float) -> void:
	game = _game()
	if _was != null and _was != game and is_instance_valid(_was):
		_was.lift(false)
	_was = game
	var up := wants_lift()
	_lift = move_toward(_lift, 1.0 if up else 0.0, delta / maxf(_n("lift_s", 0.35), 0.01))
	if game:
		game.lift(_lift > 0.4)
		if player.input_enabled:
			_keys()
	_pose()


func _keys() -> void:
	if game.your_turn():
		if Input.is_action_just_pressed(&"jump"):
			game.you_call()
		elif Input.is_action_just_pressed(&"crouch_toggle"):
			game.you_fold()
		elif Input.is_action_just_pressed(&"fire"):
			game.you_raise()
		elif Input.is_action_just_pressed(&"move_forward"):
			game.you_more(1)
		elif Input.is_action_just_pressed(&"move_back"):
			game.you_more(-1)
	elif game.you_drawing:
		if Input.is_action_just_pressed(&"move_left"):
			pick = maxi(pick - 1, 0)
		elif Input.is_action_just_pressed(&"move_right"):
			pick = mini(pick + 1, 4)
		elif Input.is_action_just_pressed(&"jump"):
			game.you_mark(pick)
		elif Input.is_action_just_pressed(&"fire"):
			game.you_draw()


func _build() -> void:
	if _hold != null or player == null or player.camera == null:
		return
	_hold = Node3D.new()
	_hold.name = "CardHold"
	player.camera.add_child(_hold)
	for i in 5:
		var mi := MeshInstance3D.new()
		mi.name = "Card%d" % i
		mi.mesh = PlayingCards.card_mesh()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Layers.hold(mi)
		_hold.add_child(mi)
		_cards.append(mi)
	_hand = HeldHand.new(true)
	_hand.name = "CardHand"
	_hold.add_child(_hand)
	_hand.shoulder = ShotgunViewmodel.SHOULDER_R
	_hand.elbow_pole = ShotgunViewmodel.ELBOW_POLE_R
	_hand.build()
	# Palm to the cards' backs, fingers up behind them, the thumb (to your left) over the pivot in front.
	_hand.basis = Basis(Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, -1, 0))
	for f: String in HeldHand.FINGERS:
		_hand.curl(f, [0.0, 4.0, 2.0])
	_hand.thumb_pose(Vector3(0.0, 0.0, 30.0), 25.0, 20.0)
	for mi in _hand.find_children("*", "MeshInstance3D", true, false):
		Layers.hold(mi as MeshInstance3D)
	_hold.visible = false


## The fan where your hand has it: low out of sight, or up before you; fanned from a pivot at the
## cards' foot, the picked card a touch up, the ones you've marked to throw well up and shaded.
func _pose() -> void:
	if _hold == null:
		_build()
		if _hold == null:
			return
	var cards := game.your_cards() if game else []
	_hold.visible = _lift > 0.01 and cards.size() == 5
	if not _hold.visible:
		return
	var k := smoothstep(0.0, 1.0, _lift)
	var ride := player.motion.hand_pos if player.motion else Vector3.ZERO
	_hold.position = _v("down", Vector3(0.08, -0.4, -0.3)).lerp(_v("up", Vector3(0.03, -0.11, -0.27)), k) + ride
	_hold.rotation_degrees = Vector3(lerpf(-40.0, _n("tilt_deg", -22.0), k), 0.0, lerpf(-20.0, 0.0, k))
	var fan := _n("fan_deg", 15.0)
	var hh := PlayingCards.SIZE.z * 0.5
	var face_us := Basis(Vector3.RIGHT, PI * 0.5)
	for i in 5:
		var a := deg_to_rad(fan * (2.0 - float(i)))
		var turn := Basis(Vector3.BACK, a)
		var lift_by := 0.0
		var marked := game.you_marks.has(i)
		if game.you_drawing and i == pick:
			lift_by += 0.008
		if marked:
			lift_by += 0.026
		var centre := turn * Vector3(0.0, hh - 0.018 + lift_by, 0.0015 * i)
		var mi := _cards[i]
		mi.transform = Transform3D(turn * face_us, centre)
		mi.set_instance_shader_parameter(&"card", float(cards[i]))
		mi.set_instance_shader_parameter(&"shade", 0.72 if marked else 1.0)
	_hand.position = _v("hand_at", Vector3(0.004, -0.045, -0.045))
