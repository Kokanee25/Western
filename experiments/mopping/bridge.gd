extends BridgeLab
## The mopping lab's dev bridge commands (README.md beside this file): the barkeep's mopping and
## what's on the saloon's floor, in the running game; a spill or mud to make him mop.

const HELP := {
	"mop": "mop -> the barkeep's mopping (step, why it last stopped, goes, stretches, waters changed), his mop and bucket, and what's on the floor round his post (dirt g, spilt ml, blood ml, stains)",
	"mop_do": "mop_do spill|mud|look -> a bottle of whiskey spilt in front of the bar, a trail of mud from the door, or have him look at the floor now",
}


func _mopping() -> MopFloor:
	var man := person("barkeep")
	var brain := man.get_node_or_null(^"Brain") as CivilianBrain if man else null
	for c: RefCounted in (brain.chores if brain else []):
		if c is MopFloor:
			return c
	return null


func _cmd_mop(_a: Array) -> Dictionary:
	var m := _mopping()
	if m == null:
		return {"ok": false, "error": "no barkeep with a mop"}
	var out := {"ok": true, "step": String(MopFloor.Step.keys()[m.step]).to_lower(), "stopped": String(m.stopped),
			"goes": m.goes, "stretches": m.stretches, "changes": m.changes}
	out.mop = {"water_ml": snappedf(m.mop.water_ml, 1), "dirt": snappedf(m.mop.dirt, 0.01), "blood": snappedf(m.mop.blood, 0.1),
			"standing": m.mop.state == MopProp.State.STANDING}
	out.bucket = {"litres": snappedf(m.bucket.water_ml / 1000.0, 0.01), "murk": snappedf(m.bucket.murk(), 0.01)}
	var marks := FloorMarks.find(m.body.get_tree())
	if marks:
		var mess := marks.mess(m.post, m.tuning.area)
		out.floor = {"dirt": snappedf(mess.dirt, 0.01), "spilt": snappedf(mess.liquid, 0.1), "blood": snappedf(mess.blood, 0.1),
				"stains": snappedf(mess.stain, 0.01)}
	return out


func _cmd_mop_do(a: Array) -> Dictionary:
	var m := _mopping()
	if m == null or a.is_empty():
		return {"ok": false, "error": "mop_do spill|mud|look (and a barkeep with a mop)"}
	var marks := FloorMarks.find(m.body.get_tree())
	var front := m.post + (m.body.global_basis.z * -1.0) * 1.8
	match String(a[0]):
		"spill":
			Events.liquid_spilled.emit(front, &"whiskey", 0.6, null)
		"mud":
			for i in 30:
				marks.add_dirt(front.lerp(m.post + Vector3(-4.0, 0.0, -2.5), i / 30.0) + Vector3(0.1 * (i % 3), 0, 0), 0.6, 0.7)
		"look":
			m.set(&"_look", 0.0)
			m.set(&"_rest", 0.0)
		_:
			return {"ok": false, "error": "mop_do spill|mud|look"}
	log_event("mop", String(a[0]))
	return {"ok": true}
