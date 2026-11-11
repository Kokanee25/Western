extends BridgeLab
## The coach heist lab's dev bridge commands (README.md beside this file): the lab's site built in
## the running game beside you (the bank, the 2.5 m crib step with its flat top, the log on its
## deck, the coach coming up the road with its guards), the log let go, and what happened read back.

const HELP := {
	"ch_build": "ch_build [X Y Z] [ledge=M] [coach_z=M] [log_r=M] [guards=N] -> the heist's site there (default 30 m ahead of you), the coach driving; the log goes as it comes to the mark",
	"ch_release": "ch_release -> every hold on the log broken (as balls into the wedges and the chain's pin)",
	"ch_read": "ch_read -> the log's speeds (at the bank's foot, at the hit), the coach's lean and over, traces left, dents, guards",
	"ch_clear": "ch_clear -> the site taken away",
}

var _site: Node3D


func _cmd_ch_build(a: Array) -> Dictionary:
	_cmd_ch_clear([])
	var at := player.global_position - player.global_basis.z * 30.0 if player else Vector3.ZERO
	var opts := {"ledge": 0.6, "coach_z": 0.6}
	var nums: Array = []
	for w in a:
		var s := String(w)
		if s.contains("="):
			var kv := s.split("=")
			opts[kv[0]] = float(kv[1]) if kv[0] != "guards" else int(kv[1])
		else:
			nums.append(s)
	if nums.size() >= 3:
		at = vec(nums, 0)
	opts["release_at_x"] = 1.4 * 2.6
	opts["coach_x"] = 1.4 * 2.6 + 6.0
	_site = load("res://experiments/coach_heist/heist_site.gd").new()
	_site.name = "HeistSite"
	street.add_child(_site) if street else main.add_child(_site)
	_site.global_position = at
	_site.build(opts)
	return {"ok": true, "at": arr(at), "coach": String(_site.coach_id()), "log_kg": snappedf(_site.log_body.mass, 1.0)}


func _cmd_ch_release(_a: Array) -> Dictionary:
	if _site == null:
		return {"ok": false, "error": "no site (ch_build)"}
	_site.release_log()
	return {"ok": true}


func _cmd_ch_read(_a: Array) -> Dictionary:
	if _site == null:
		return {"ok": false, "error": "no site (ch_build)"}
	var r: Dictionary = _site.result()
	r.erase("events")
	r["ok"] = true
	return r


func _cmd_ch_clear(_a: Array) -> Dictionary:
	if _site and is_instance_valid(_site):
		_site.queue_free()
	_site = null
	return {"ok": true}
