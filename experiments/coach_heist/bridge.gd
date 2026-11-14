extends BridgeLab
## The coach heist lab's dev bridge commands (README.md beside this file): the lab's site built in
## the running game beside you (the bank, the ram over the road, or `striker=roll`: the log on its
## deck over the crib step; the coach coming up the road with its guards), the log let go, and what
## happened read back; and the valley's coach cut (CoachCut, `-- --world=valley`).

const HELP := {
	"ch_build": "ch_build [X Y Z] [striker=ram|roll] [pull_up=M] [coach_z=M] [log_r=M] [guards=N] -> the heist's site there (default 30 m ahead of you), the coach driving; the log goes as it comes to the mark",
	"ch_cut": "ch_cut [auto] [back=M] [seed=N] [here] -> the valley's coach cut started again (the ram held, the coach `back` m down the South Road, 40); auto: the pin let go as it comes; here: you at the high spot",
	"ch_fight": "ch_fight -> the fight after the hit (CoachFight.result): the guards, each man's phase, mood, order; the box; won or lost",
	"ch_fight_run": "ch_fight_run seed=N [max=S] [aim=DEG] [take=papers|box] [auto] [out=FILE] -> one scripted run of the heist (coach_bot.gd): the cut started again at the high spot, the pin shot, the guards fought, the box taken, out by the rimrock trail; till won or lost",
	"ch_cut_go": "ch_cut_go -> the coach cut's pin let go (as a ball through it)",
	"ch_cut_read": "ch_cut_read -> the coach cut: let go, struck, over, lean, dents, the deepest, traces, strongbox, the ram",
	"ch_release": "ch_release -> every hold on the log broken (as balls into the wedges and the chain's pin)",
	"ch_read": "ch_read -> the log's speeds (at the bank's foot, at the hit), the coach's lean and over, traces left, dents, guards",
	"ch_clear": "ch_clear -> the site taken away",
}

var _site: Node3D


func _cmd_ch_build(a: Array) -> Dictionary:
	_cmd_ch_clear([])
	var at := player.global_position - player.global_basis.z * 30.0 if player else Vector3.ZERO
	var opts := {}
	var nums: Array = []
	for w in a:
		var s := String(w)
		if s.contains("="):
			var kv := s.split("=")
			opts[kv[0]] = kv[1] if kv[0] == "striker" else (float(kv[1]) if kv[0] != "guards" else int(kv[1]))
		else:
			nums.append(s)
	if nums.size() >= 3:
		at = vec(nums, 0)
	var roll := String(opts.get("striker", "ram")) == "roll"
	if roll:
		opts.merge({"ledge": 0.6, "coach_z": 0.6})
	opts["release_at_x"] = 1.4 * (2.6 if roll else 1.28)
	opts["coach_x"] = float(opts.release_at_x) + 6.0
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


func _cmd_ch_cut(a: Array) -> Dictionary:
	var v := main.find_children("*", "ValleyWorld", true, false) if main else []
	if v.is_empty():
		return {"ok": false, "error": "not the valley (-- --world=valley)"}
	var world := v[0] as ValleyWorld
	var lead := -1.0
	var back := 40.0
	var sd := 815
	for w in a:
		var s := String(w)
		if s == "auto":
			lead = 1.4 * 1.28
		elif s.begins_with("back="):
			back = float(s.substr(5))
		elif s.begins_with("seed="):
			sd = int(s.substr(5))
	var cut := world.start_coach_cut(lead, back, sd)
	if "here" in a:
		cut.place_player(player)
	return {"ok": true, "middle": arr(cut.middle), "pin": arr(cut.ram.pin_position()), "road": [snappedf(cut.road_from, 0.1), snappedf(cut.road_to, 0.1)]}


func _cmd_ch_cut_go(_a: Array) -> Dictionary:
	var cut := _cut()
	if cut == null:
		return {"ok": false, "error": "no coach cut (ch_cut)"}
	cut.ram.release()
	return {"ok": true}


func _cmd_ch_cut_read(_a: Array) -> Dictionary:
	var cut := _cut()
	if cut == null:
		return {"ok": false, "error": "no coach cut (ch_cut)"}
	var r := cut.result()
	r["ok"] = true
	return r


func _cmd_ch_fight(_a: Array) -> Dictionary:
	var cut := _cut()
	if cut == null or cut.fight == null:
		return {"ok": false, "error": "no coach cut (ch_cut)"}
	var r := cut.fight.result()
	r["ok"] = true
	return r


const CoachBot := preload("res://experiments/coach_heist/coach_bot.gd")


func _cmd_ch_fight_run(a: Array) -> Dictionary:
	var opts := {}
	for w in a:
		var kv := String(w).split("=")
		opts[kv[0]] = kv[1] if kv.size() == 2 else "1"
	var seed_value := int(opts.get("seed", "1"))
	var max_s := float(opts.get("max", "300"))
	var v := main.find_children("*", "ValleyWorld", true, false) if main else []
	if v.is_empty():
		return {"ok": false, "error": "not the valley (-- --world=valley)"}
	seed(seed_value)
	StoryState.clear("coach.")
	var auto := opts.has("auto")
	var cut := (v[0] as ValleyWorld).start_coach_cut(1.4 * 1.28 if auto else -1.0, float(opts.get("back", "40")), seed_value)
	cut.place_player(player)
	await physics_frames(5)
	var bot = CoachBot.new()
	bot.setup(player, cut, seed_value, float(opts.get("aim", "1.0")), String(opts.get("take", "papers")), auto)
	var t := 0.0
	var tail := -1.0
	var ms: Array[float] = []
	var spikes: Array = []
	var last := Time.get_ticks_usec()
	var f := cut.fight
	var prof_was := Prof.on
	Prof.on = true
	while t < max_s:
		await get_tree().physics_frame
		var now := Time.get_ticks_usec()
		var frame := (now - last) / 1000.0
		last = now
		if f.hit_t >= 0.0 and f.state == CoachFight.State.ON:
			ms.append(frame)
			if frame > 40.0:
				var top: Array = []
				for k: StringName in Prof._sum:
					if not String(k).begins_with("q_") and not String(k).begins_with("n_") and int(Prof._sum[k]) > 3000:
						top.append("%s %.1f" % [k, int(Prof._sum[k]) / 1000.0])
				spikes.append([snappedf(f.t, 0.01), snappedf(frame, 0.1), top])
		Prof._sum.clear()
		var dt := get_physics_process_delta_time()
		t += dt
		bot.tick(dt, t)
		if f.state in [CoachFight.State.WON, CoachFight.State.LOST]:
			if tail < 0.0:
				tail = t
			if t - tail > 1.0:
				break
	Prof.on = prof_was
	bot.bot.release_all()
	bot.teardown()
	var r := f.result()
	r.seed = seed_value
	r.bot = bot.stats
	r.bot_phase = bot.phase
	r.player_at = arr(player.global_position)
	r.player_how = player.wounds.physiology.describe()
	r.story = StoryState.to_dict().facts
	ms.sort()
	r.frames = {"ticks": ms.size(), "mean_ms": snappedf(ms.reduce(func(x: float, y: float) -> float: return x + y, 0.0) / maxf(ms.size(), 1), 0.01),
			"p95_ms": snappedf(ms[int(ms.size() * 0.95)] if not ms.is_empty() else 0.0, 0.01), "max_ms": snappedf(ms.back() if not ms.is_empty() else 0.0, 0.01)}
	r.frames.spikes = spikes.slice(0, 30)
	if r.outcome == "":
		r.outcome = "timeout"
	if opts.has("out"):
		var fh := FileAccess.open(String(opts.out), FileAccess.WRITE)
		fh.store_string(JSON.stringify(r))
	r.ok = true
	return r


func _cut() -> CoachCut:
	var v := main.find_children("*", "CoachCut", true, false) if main else []
	return v[0] as CoachCut if not v.is_empty() else null
