class_name JoeLost
extends Node
## No Justice over with Joe lost to you (#1125: you shot at Joe, he turned on you, shot you down,
## and in the black-out he'd gone: "he's long gone", the mission over with no word). Watching an
## act (NoJusticeCamp, NoJusticeHideout, NoJusticeCabin) while it plays: once Joe has turned on you
## and is gone from the world or dead, or is dead of your balls, and you're awake, the act ends
## (`joe_lost`) with a card that says what happened, the story's `nojustice.ending` = joe_lost, and
## Enter starts that act again (on the valley's next load: `restart`, as the hideout's retry).

## The act to start again on the valley's next load (ValleyWorld), or &"".
static var restart := &""

var act: Act
var joe: HumanBody
var brain: CompanionBrain
## He turned on you; your balls went at him (CompanionBrain's `_from_you`).
var turned := false
var shot_at := false
var over := false
var what := ""
var _told_t := -1.0


## Watch `act`'s Joe (a child of the act: it goes with it).
static func watch(a: Act, j: HumanBody, b: CompanionBrain) -> JoeLost:
	StoryState.mark_checkpoint()  # Enter starts it again from the story as it is now
	var w := JoeLost.new()
	w.name = "JoeLost"
	w.act = a
	w.joe = j
	w.brain = b
	a.add_child(w)
	return w


func _physics_process(_delta: float) -> void:
	if act == null or not is_instance_valid(act):
		return
	if over:
		if _told_t >= 0.0 and act.t - _told_t > 1.0 and Input.is_action_just_pressed(&"mission_retry"):
			again()
		return
	if act.done:
		return  # it ended its own way
	var here := joe != null and is_instance_valid(joe) and not joe.is_queued_for_deletion()
	if here and brain != null and is_instance_valid(brain):
		turned = turned or brain.turned
		shot_at = shot_at or not brain._from_you.is_empty()
	var dead := here and not joe.physiology.alive
	if not ((turned and (not here or dead)) or (dead and shot_at)):
		return
	var p := act.player()
	if p == null or p.wounds == null or not p.wounds.physiology.is_conscious():
		return  # told once you're awake
	_end(dead)


func _end(dead: bool) -> void:
	over = true
	if dead:
		what = "Joe's dead, and by your hand. Nobody rides after Kett now."
	else:
		what = "Joe turned on you, shot you down and rode off alone. He won't ride with you again."
	act.fact("nojustice.ending", "joe_lost")
	act.fact("nojustice.joe", "dead" if dead else "gone")
	act.card(what + "\n\nNo Justice is over.", 6.0)
	act.prompt("Enter: start it again.", 30.0, true)
	_told_t = act.t
	act._note("joe lost (%s): the mission's over" % ("dead" if dead else "gone"))
	act._finish(&"joe_lost")


## Enter: the act again from the story as it was when it began (its checkpoint).
func again() -> void:
	restart = act.moment_name
	GameReset.retry(get_tree(), "No Justice again (Joe lost)")
