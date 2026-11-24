extends TestCase
## The town's script (townsfolk step 8, #1144; docs/scripts/town.json, the game's copy
## config/town_script.json; TownScript):
## - the game's copy is the script, word for word;
## - every line the game reads (the runner's, the news's) is there with words, and no wording holds a
##   slot the game doesn't fill;
## - a man's news line has every slot filled, for a full version and an empty one, every kind, every
##   how, to Harlan's face and not;
## - men with the same news don't all say it the same way (the 2026-11-21 playtest's "Three shots, I
##   counted." three times).

const READ := ["run_doc", "run_law", "runner", "runner.shot", "runner_dead", "runner_dead.shot", "runner_you",
		"runner_you.shot", "news.killing", "news.killing.you", "news.killing.nobody", "news.shooting",
		"news.shooting.you", "news.shooting.nobody", "news.down", "news.shots", "news.first.saw",
		"news.first.heard", "news.first.told", "news.count", "news.count.told", "news.told_by"]
const SLOTS := ["who", "Who", "whom", "where", "at", "shots", "teller"]

var news: TownNews


func before_each() -> void:
	StoryState.clear("news.")
	news = TownNews.new()


func after_each() -> void:
	StoryState.clear("news.")


func test_the_game_s_copy_is_the_script() -> void:
	var game := FileAccess.get_file_as_string(TownScript.PATH)
	check(game != "", "config/town_script.json is there")
	var doc := FileAccess.get_file_as_string("res://docs/scripts/town.json")
	if doc == "":
		return  # an export has no docs/
	check(game == doc, "config/town_script.json is a copy of docs/scripts/town.json (cp the script over)")


func test_every_line_the_game_reads_has_words_and_only_known_slots() -> void:
	for id: String in READ:
		check(TownScript.words(id).size() >= 2 or id in ["runner_you", "runner_dead"], "%s has a few wordings (%s)" % [id, TownScript.words(id)])
	var re := RegEx.create_from_string("\\{([a-z_]+)\\}")
	for id: String in TownScript.lines():
		for w: String in TownScript.words(id):
			for m: RegExMatch in re.search_all(w):
				check(m.get_string(1) in SLOTS, "%s: a slot the game fills (%s)" % [id, w])


func _version(pid: StringName, v: Dictionary) -> int:
	var r := news._new_record(&"shot", Vector3.ZERO)
	var mine := news._version(pid, r, StringName(v.get("how", "saw")))
	for k: String in v:
		mine[k] = v[k]
	return int(r.id)


func _clean(line: String, what: String) -> void:
	check(line != "", "%s: a line" % what)
	check(not line.contains("{") and not line.contains("}"), "%s: every slot filled (%s)" % [what, line])
	check(line.substr(0, 1) == line.substr(0, 1).to_upper(), "%s: starts with a capital (%s)" % [what, line])


func test_every_slot_is_filled_full_and_empty() -> void:
	var full := {"who": &"cody", "whom": &"earl", "first": &"earl", "shots": 3, "down": true, "where": "the saloon", "by": &"barkeep"}
	var kinds := [{"dead": true}, {"dead": false}, {"dead": false, "shots": 0}, {"down": false, "whom": &"", "first": &""}]
	var n := 0
	for k: Dictionary in kinds:
		for how: String in ["saw", "heard", "told"]:
			for who: StringName in [&"cody", TownNews.HARLAN]:
				var v := full.duplicate()
				v.merge(k, true)
				v.how = StringName(how)
				v.who = who
				var rid := _version(StringName("p%d" % n), v)
				_clean(news.line_of(StringName("p%d" % n), rid, TownNews.HARLAN), "full %s %s %s" % [k, how, who])
				_clean(news.line_of(StringName("p%d" % n), rid, &"townsman"), "full, told to a townsman")
				n += 1
	# Empty: what a man has when he only heard something, or found a man and no more.
	for e: Dictionary in [{"shots": 1}, {"down": true}, {"down": true, "dead": true}, {"down": true, "shots": 2, "how": &"told"}]:
		var rid := _version(StringName("e%d" % n), e)
		var line := news.line_of(StringName("e%d" % n), rid, TownNews.HARLAN)
		_clean(line, "empty %s" % e)
		n += 1


func test_to_harlan_s_face_it_s_you() -> void:
	var rid := _version(&"p1", {"who": TownNews.HARLAN, "whom": &"badman", "first": &"badman", "shots": 2, "down": true, "dead": true, "where": "the store"})
	var line := news.line_of(&"p1", rid, TownNews.HARLAN)
	check(line.begins_with("You "), "to his face (%s)" % line)
	check(not line.contains("new man"), "not 'the new man' to his face (%s)" % line)
	var other := news.line_of(&"p1", rid, &"townsman")
	check(other.contains("new man") or other.contains("New man"), "to another, the new man (%s)" % other)


func test_men_with_the_same_news_say_it_their_own_ways() -> void:
	var said := {}
	for i in 6:
		var rid := _version(StringName("folk_%d" % i), {"who": &"cody", "whom": &"earl", "shots": 3, "down": true, "where": "the saloon", "how": &"heard"})
		said[news.line_of(StringName("folk_%d" % i), rid, TownNews.HARLAN)] = true
	check(said.size() >= 3, "six men, at least three ways of saying it (%s)" % [said.keys()])
	# And one man says his the same way each time he's asked.
	var rid := _version(&"folk_x", {"who": &"cody", "whom": &"earl", "shots": 3, "down": true, "where": "the saloon"})
	check_eq(news.line_of(&"folk_x", rid, &""), news.line_of(&"folk_x", rid, &""), "the same man, the same words")


func test_the_runner_s_lines_are_the_script_s() -> void:
	var f := FetchHelp.new()
	var off := f.off_line(&"doctor", "folk_1")
	check(TownScript.words("run_doc").has(off), "his start line is the script's (%s)" % off)
	check(TownScript.words("run_law").has(f.off_line(&"harlan", "folk_1")), "and for the law")
	var t := TownScript.pick(["runner_you.shot", "runner_you"], 7, {"where": "the store"})
	check(t.begins_with("Deputy!") and t.contains("the store"), "the runner to Harlan (%s)" % t)
