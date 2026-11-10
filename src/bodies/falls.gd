class_name Falls
extends RefCounted
## Falls from height (issue #759): the rules shared by a falling man (HumanBody._step_fall) and
## the player (PlayerWounds.take_fall). Dials in config/falls.tres (FallTuning).

static var tuning: FallTuning


static func t() -> FallTuning:
	if tuning == null:
		tuning = load("res://config/falls.tres")
	return tuning


## The landing's energy that hurts (J): `mass` kg coming down at `v_in`, going on at `v_out`.
static func hurt_energy(mass: float, v_in: float, v_out: float, ft: FallTuning = null) -> float:
	ft = ft if ft else t()
	var stopped := 0.5 * mass * (v_in * v_in - minf(maxf(v_out, 0.0), v_in) ** 2)
	return maxf(stopped, 0.0) * ft.injury_share


## How he landed, by the parts that stopped first (segment ids) and where his pelvis was against
## them: &"head" (head or neck first, his middle over it), &"feet" (a foot or shin first, his middle
## over it), else &"flat".
static func landing_kind(first: Array, pelvis_y: float, heights: Dictionary) -> StringName:
	for sid: StringName in first:
		var s := String(sid)
		if (s == "head" or s == "neck") and pelvis_y > float(heights[sid]) + 0.3:
			return &"head"
	for sid: StringName in first:
		var s := String(sid)
		if (s.begins_with("foot") or s.begins_with("shin")) and pelvis_y > float(heights[sid]) + 0.3:
			return &"feet"
	return &"flat"


## The blows: `energy` J (already the hurting share) over the parts, `stops` part -> how hard it
## stopped over the landing (N*s), `first` the parts down first (those touching the ground as it
## began) -> how hard each stopped then. Head first they take `lead_share` between them (the first
## part down carries the body behind it: a head first takes a man's fall), feet first
## `feet_lead_share` (his legs give), the rest the remainder by their stops (all of it to the first
## when nothing else stopped); flat (`kind`), every part its own stop. Returns part -> J.
static func share_out(energy: float, stops: Dictionary, first: Dictionary, ft: FallTuning = null, kind := &"head") -> Dictionary:
	ft = ft if ft else t()
	if kind == &"flat":
		first = {}  # nothing stacked over the first parts: each its own stop
	var share := ft.feet_lead_share if kind == &"feet" else ft.lead_share
	var lead_sum := 0.0
	var rest_sum := 0.0
	for k: Variant in first:
		lead_sum += float(first[k])
	for k: Variant in stops:
		if not first.has(k):
			rest_sum += float(stops[k])
	var lead := share if rest_sum > 0.0 else 1.0
	if lead_sum <= 0.0:
		lead = 0.0
	var out := {}
	for k: Variant in first:
		out[k] = energy * lead * float(first[k]) / maxf(lead_sum, 1e-6)
	if rest_sum > 0.0:
		for k: Variant in stops:
			if not first.has(k):
				out[k] = energy * (1.0 - lead) * float(stops[k]) / rest_sum
	return out
