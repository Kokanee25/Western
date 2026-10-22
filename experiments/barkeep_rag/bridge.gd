extends BridgeLab
## The barkeep's rag's dev bridge commands (README.md beside this file): what his chore is doing and
## where his cloth is, in the running game; knock it off him, drop it, set it alight.

const HELP := {
	"rag": "rag -> the barkeep's chore (step, why it last stopped, goes, stretches, cups) and his cloth (held/free, where, burning, blood)",
	"rag_do": "rag_do knock|drop|ignite|wipe -> knock the cloth off him, drop it where it is, set it alight, or start his chore now",
}


func _barkeep() -> HumanBody:
	return person("barkeep")


func _cmd_rag(_a: Array) -> Dictionary:
	var man := _barkeep()
	if man == null:
		return {"ok": false, "error": "no barkeep"}
	var brain := man.get_node_or_null(^"Brain") as CivilianBrain
	var out := {"ok": true, "mood": String(CivilianBrain.Mood.keys()[brain.mood]).to_lower() if brain else ""}
	var chore: WipeBar = brain.chore if brain else null
	if chore == null:
		out.chore = "none"
		return out
	out.chore = {"step": String(WipeBar.Step.keys()[chore.step]).to_lower(), "stopped": String(chore.stopped),
			"goes": chore.cycles, "stretches": chore.wiped, "cups": chore.cups}
	var c := chore.cloth
	if c != null and is_instance_valid(c):
		out.cloth = {"held": ["free", "hand", "shoulder"][c.held] if not c.burnt else "burnt away",
				"at": arr(c.centre()) if not c.burnt else [], "burning": c.burning, "blood_ml": snappedf(c.blood_ml, 0.1)}
	return out


func _cmd_rag_do(a: Array) -> Dictionary:
	var man := _barkeep()
	var brain := man.get_node_or_null(^"Brain") as CivilianBrain if man else null
	if brain == null or brain.chore == null or a.is_empty():
		return {"ok": false, "error": "rag_do knock|drop|ignite|wipe (and a barkeep with a cloth)"}
	var c := brain.chore.cloth
	match String(a[0]):
		"knock":
			c.knock((Vector3.UP - man.global_basis.z) * c.soft.total_mass * 2.0)
		"drop":
			c.let_go()
		"ignite":
			c.ignite()
		"wipe":
			brain.chore.set(&"_rest", 0.0)
			brain.chore.set(&"_idle", brain.chore.tuning.idle_before)
		_:
			return {"ok": false, "error": "rag_do knock|drop|ignite|wipe"}
	log_event("rag", String(a[0]))
	return {"ok": true}
