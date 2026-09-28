class_name Physiology
extends RefCounted
## One person's body state, not hit points: blood, bleeds, broken bones, torn organs, lost fingers,
## breathing, pain, shock and adrenaline. Wounds come in from `Anatomy.trace()` results; `step()`
## runs it forward on a fixed timestep (real seconds at normal game speed). Pure rules, no nodes,
## so it's tested headless. Serialisable with to_dict()/from_dict().

var tuning: PhysiologyTuning
var anatomy: Anatomy

var blood_ml := 5000.0
## {id, source, segment, rate (ml/s untreated), clots, clot (0..1 of the bleed left), pressure,
## tourniquet}. `source` is the structure id, or &"flesh" for the wound track.
var bleeds: Array[Dictionary] = []
var broken := {}  ## bone id -> true
var torn := {}  ## organ id -> true
var cut := {}  ## artery id -> true
var lost_fingers := {}  ## finger id -> true
var severed_segments := {}  ## segment id -> true (the whole part is gone)
var wound_pain := 0.0  ## what the wounds deserve
var pain := 0.0  ## what's arrived so far (before adrenaline)
var adrenaline := 0.0
var oxygen := 1.0
var lung_damage := {}  ## lung id -> seconds since holed
var gut_seconds := -1.0  ## seconds since the gut was holed, -1 if not
var neck_seconds := -1.0
var brain_dead := false
var alive := true
var cause_of_death := &""
var wounds := 0


func _init(t: PhysiologyTuning = null, a: Anatomy = null) -> void:
	tuning = t if t != null else load("res://config/physiology.tres")
	anatomy = a if a != null else Anatomy.shared()
	blood_ml = tuning.blood_ml


## Take a bullet's path through one segment (an `Anatomy.trace()` result). Returns the ids of
## the bleeds it opened (so the wound can show its own blood).
func apply_trace(tr: Dictionary) -> Array:
	var first := bleeds.size()
	wounds += 1
	adrenaline = minf(adrenaline + tuning.adrenaline_per_wound, 1.0)
	var track: float = tr.track_cm
	var seg: StringName = tr.segment
	if track > 0.5:
		_add_bleed(&"flesh", seg, track * tuning.flesh_bleed_per_cm)
		wound_pain += track * tuning.pain_per_cm
	for h: Dictionary in tr.hits:
		var st := anatomy.structure(h.id)
		match h.kind:
			&"bone":
				if h.effect == &"broken":
					broken[h.id] = true
					wound_pain += tuning.pain_bone
					if st.get(&"spine", "") == "cervical":
						neck_seconds = 0.0
				else:
					wound_pain += tuning.pain_bone * 0.4
			&"artery":
				cut[h.id] = true
				_add_bleed(h.id, seg, float(st.get(&"bleed", 5.0)))
			&"organ":
				torn[h.id] = true
				wound_pain += tuning.pain_organ
				_add_bleed(h.id, seg, float(st.get(&"bleed", 0.5)))
				match StringName(st.get(&"organ", "")):
					&"brain":
						brain_dead = true
					&"lung":
						lung_damage[h.id] = 0.0
					&"gut":
						if gut_seconds < 0.0:
							gut_seconds = 0.0
							wound_pain += tuning.pain_gut
			&"finger":
				lost_fingers[h.id] = true
				wound_pain += tuning.pain_finger
				_add_bleed(h.id, seg, float(st.get(&"bleed", 0.4)))
	if brain_dead:
		_die(&"brain")
	return range(first, bleeds.size())


## Bleeding from where a part came off (a finger, a hand...).
func sever(segment: StringName) -> void:
	for s in anatomy.segments_below(segment):
		severed_segments[s] = true
	var parent: StringName = anatomy.segments[segment].parent
	_add_bleed(&"stump", parent, 6.0)
	wound_pain += tuning.pain_bone


func _add_bleed(source: StringName, segment: StringName, rate: float) -> void:
	bleeds.append({"id": bleeds.size(), "source": source, "segment": segment, "rate": rate,
			"clots": rate <= tuning.clot_max_rate, "clot": 1.0, "pressure": false, "tourniquet": false, "lost": 0.0})


func step(dt: float) -> void:
	if not alive:
		return
	# Bleeding.
	var loss := 0.0
	for b in bleeds:
		var ml := bleed_rate(b) * dt
		b.lost += ml
		loss += ml
		if b.clots:
			b.clot *= exp(-dt / tuning.clot_time)
	var bleeding := loss > 0.0001
	blood_ml = maxf(blood_ml - loss, 0.0)
	if not bleeding and blood_ml < tuning.blood_ml:
		blood_ml = minf(blood_ml + tuning.blood_regen * dt, tuning.blood_ml)
	# Breathing: holed lungs collapse, oxygen follows.
	for lung: StringName in lung_damage:
		lung_damage[lung] += dt
	var capacity := breath_capacity()
	if neck_seconds >= 0.0:
		neck_seconds += dt
		capacity = 0.0
	var circulating := clampf(1.0 - blood_loss() / tuning.death_at_loss, 0.0, 1.0)
	var target := clampf(capacity * 2.0 - tuning.oxygen_need * 2.0 + 1.0, 0.0, 1.0) * sqrt(circulating)
	oxygen = move_toward(oxygen, target, tuning.oxygen_rate * dt * (2.0 if target > oxygen else 1.0))
	# Pain arrives over a few seconds; adrenaline fades.
	pain = move_toward(pain, wound_pain, maxf(wound_pain - pain, 0.05) * dt / tuning.pain_onset * 3.0)
	adrenaline *= exp(-dt / tuning.adrenaline_fade)
	if gut_seconds >= 0.0:
		gut_seconds += dt
	# Death.
	if blood_loss() >= tuning.death_at_loss:
		_die(&"blood_loss")
	elif neck_seconds >= tuning.neck_death_time:
		_die(&"broken_neck")
	elif oxygen <= 0.0:
		_die(&"broken_neck" if neck_seconds >= 0.0 else &"suffocation")
	elif gut_seconds >= tuning.gut_death_game_hours * tuning.game_hour_seconds:
		_die(&"gut_wound")


## Current ml/s from one bleed, with clotting and treatment.
func bleed_rate(b: Dictionary) -> float:
	var r: float = b.rate * b.clot
	if b.tourniquet:
		r *= tuning.tourniquet_factor
	elif b.pressure:
		r *= tuning.pressure_factor
	return r


## Blood lost so far from some bleeds (by id), for how far a wound's stain has spread.
func blood_lost_from(ids: Array) -> float:
	var ml := 0.0
	for i: int in ids:
		if i < bleeds.size():
			ml += bleeds[i].lost
	return ml


func total_bleed_rate() -> float:
	var r := 0.0
	for b in bleeds:
		r += bleed_rate(b)
	return r


## Tighten a tourniquet on a limb segment: every bleed at or below it stops. Returns how many.
func apply_tourniquet(segment: StringName) -> int:
	var below := anatomy.segments_below(segment)
	var n := 0
	for b in bleeds:
		if below.has(b.segment):
			b.tourniquet = true
			n += 1
	return n


## Hold pressure on (or pack) the bleeds in one segment.
func apply_pressure(segment: StringName, on := true) -> void:
	for b in bleeds:
		if b.segment == segment:
			b.pressure = on


func _die(cause: StringName) -> void:
	if alive:
		alive = false
		cause_of_death = cause


# --- What the body can do ---------------------------------------------------------------------

func blood_loss() -> float:
	return 1.0 - blood_ml / tuning.blood_ml


## 0 = fine, 1 = deep shock (grey, cold, can't stand).
func shock() -> float:
	return clampf((blood_loss() - tuning.shock_at_loss * 0.5) / (tuning.unconscious_at_loss - tuning.shock_at_loss * 0.5), 0.0, 1.0)


func felt_pain() -> float:
	return pain * (1.0 - adrenaline * tuning.adrenaline_masks)


func breath_capacity() -> float:
	var c := 1.0
	for lung: StringName in lung_damage:
		c -= tuning.lung_capacity_lost * clampf(lung_damage[lung] / tuning.lung_collapse_time, 0.0, 1.0)
	return maxf(c, 0.0)


func is_conscious() -> bool:
	return alive and not brain_dead and neck_seconds < 0.0 \
			and blood_loss() < tuning.unconscious_at_loss \
			and oxygen > tuning.faint_oxygen and felt_pain() < tuning.pain_faint


func legs_paralysed() -> bool:
	for bone: StringName in broken:
		var spine := String(anatomy.structure(bone).get(&"spine", ""))
		if spine == "thoracic" or spine == "lumbar" or spine == "cervical":
			return true
	return false


func leg_ok(side: String) -> bool:
	for bone in [&"femur_", &"tibia_"]:
		if broken.has(StringName(bone + side)):
			return false
	return not severed_segments.has(StringName("shin_" + side)) and not severed_segments.has(StringName("foot_" + side))


func can_stand() -> bool:
	return is_conscious() and not legs_paralysed() and not broken.has(&"pelvis_bone") \
			and leg_ok("r") and leg_ok("l") and shock() < 0.85


func can_run() -> bool:
	return can_stand() and breath_capacity() >= tuning.run_breath and shock() < 0.4 \
			and felt_pain() < tuning.pain_disabling


## Can this hand ("r"/"l") hold a gun?
func can_hold(side: String) -> bool:
	if not is_conscious() or severed_segments.has(StringName("hand_" + side)):
		return false
	for bone in [&"humerus_", &"forearm_bones_", &"hand_bones_", &"clavicle_"]:
		if broken.has(StringName(bone + side)):
			return false
	var fingers := 0
	for f in ["thumb_", "index_", "middle_", "ring_", "little_"]:
		if not lost_fingers.has(StringName(f + side)):
			fingers += 1
	return fingers >= 3


## Which finger works the trigger on this hand: index, else middle, else none.
func trigger_finger(side: String) -> StringName:
	for f in ["index_", "middle_"]:
		if not lost_fingers.has(StringName(f + side)):
			return StringName(f + side)
	return &""


## Whether the bullet is still inside anywhere is kept per wound by the caller; this just says
## how it looks from outside, for the doctor and the player.
func describe() -> String:
	if not alive:
		return "Dead (%s)." % String(cause_of_death).replace("_", " ")
	var parts: PackedStringArray = []
	if not is_conscious():
		parts.append("Out cold")
	var s := shock()
	if s > 0.7:
		parts.append("grey and cold, pulse thready")
	elif s > 0.3:
		parts.append("pale and sweating")
	var r := total_bleed_rate()
	if r > 6.0:
		parts.append("blood pumping out bright")
	elif r > 1.0:
		parts.append("bleeding steady")
	elif r > 0.1:
		parts.append("bleeding a little")
	if breath_capacity() < tuning.run_breath:
		parts.append("short of breath, bubbling cough")
	if gut_seconds >= 0.0:
		parts.append("gut-shot")
	if not broken.is_empty():
		parts.append("bone broken")
	if not lost_fingers.is_empty():
		parts.append("%d finger%s gone" % [lost_fingers.size(), "" if lost_fingers.size() == 1 else "s"])
	if parts.is_empty():
		return "Unhurt." if wounds == 0 else "Hurt, but steady."
	var text := ", ".join(parts)
	return text.substr(0, 1).to_upper() + text.substr(1) + "."


func to_dict() -> Dictionary:
	return {"blood_ml": blood_ml, "bleeds": bleeds.duplicate(true), "broken": broken.keys(),
			"torn": torn.keys(), "cut": cut.keys(), "lost_fingers": lost_fingers.keys(),
			"severed": severed_segments.keys(), "wound_pain": wound_pain, "pain": pain,
			"adrenaline": adrenaline, "oxygen": oxygen, "lung_damage": lung_damage.duplicate(),
			"gut_seconds": gut_seconds, "neck_seconds": neck_seconds, "brain_dead": brain_dead,
			"alive": alive, "cause_of_death": cause_of_death, "wounds": wounds}


func from_dict(d: Dictionary) -> void:
	blood_ml = d.blood_ml
	bleeds.assign(d.bleeds.duplicate(true))
	broken = _set_of(d.broken)
	torn = _set_of(d.torn)
	cut = _set_of(d.cut)
	lost_fingers = _set_of(d.lost_fingers)
	severed_segments = _set_of(d.severed)
	wound_pain = d.wound_pain
	pain = d.pain
	adrenaline = d.adrenaline
	oxygen = d.oxygen
	lung_damage = d.lung_damage.duplicate()
	gut_seconds = d.gut_seconds
	neck_seconds = d.neck_seconds
	brain_dead = d.brain_dead
	alive = d.alive
	cause_of_death = d.cause_of_death
	wounds = d.wounds


static func _set_of(keys: Array) -> Dictionary:
	var out := {}
	for k in keys:
		out[StringName(k)] = true
	return out
