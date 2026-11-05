class_name GameReset
## Backspace: the game back as it started, without quitting (Sean, 2026-10-23, issue #318): the
## main scene loaded again (the town rebuilt, the men back, the player at the spawn, the clock at
## its start), as Settings' look switches already do. What lives outside the scene and would make
## the second start differ from the first is put back first: the props' per-id counters (each
## prop's id, variant, glass and seed come from them) and SightLight's lamp list (it would read a
## freed lamp). The settings, the look in force and the caches of materials and sounds stay.


## The overlay says so once the new scene is up.
static var just_reset := false


static func reset(tree: SceneTree) -> void:
	just_reset = true
	reload_scene(tree, "the game reset")


## Every reload of the running scene comes through here (Backspace, the gunfight lab's Y/X/Z, the
## look's I and M; issue #671): what lives outside the scene is put back first, and the freeze
## watchdog waits for the load (its first frames drawn end it), as at the start.
static func reload_scene(tree: SceneTree, what := "the scene's reload") -> void:
	CrashReports.begin_load(what)
	clear_statics()
	tree.reload_current_scene.call_deferred()


## Everything static that a fresh start would have empty.
static func clear_statics() -> void:
	PropKit._made.clear()
	PropLibrary._made.clear()
	SightLight._lamps.clear()
	SightLight._lamps_frame = -1
	SightLight._cache.clear()
	Blood.clear()
	Blood._dry_owed = 0.0
	GunSmoke._clouds.clear()
	StructureMember._chips.clear()
	GlassProp._shards.clear()
