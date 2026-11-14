class_name GameReset
## Backspace: the game back as it started, without quitting (Sean, 2026-10-23, issue #318): the
## main scene loaded again (the town rebuilt, the men back, the player at the spawn, the clock at
## its start), as Settings' look switches already do. What lives outside the scene and would make
## the second start differ from the first is put back first: the props' per-id counters (each
## prop's id, variant, glass and seed come from them) and SightLight's lamp list (it would read a
## freed lamp). The settings, the look in force and the caches of materials and sounds stay.
##
## The story (StoryState; review A5, #864): a reload is a fresh start and wipes it, so No Law's
## murder plays again after Backspace; a mission's retry (`retry`) puts back the story as it stood
## when that mission began. A save's load (after the slice) will be the retry's shape: the world's
## statics cleared (`clear_world`), then the saved story put back, never wiped.


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


## A mission tried again (Enter after a lost try, or held): the game reloaded as `reload_scene`, but
## the story as it stood when the mission began (StoryState.checkpoint), not wiped: what earlier
## missions set still holds, what this try set is gone.
static func retry(tree: SceneTree, what := "the mission's retry") -> void:
	CrashReports.begin_load(what)
	clear_for_retry()
	tree.reload_current_scene.call_deferred()


## A fresh start: everything static a new game would have empty, the story too.
static func clear_statics() -> void:
	clear_world()
	StoryState.wipe()


## A retry: the world's statics cleared, the story put back to the mission's checkpoint.
static func clear_for_retry() -> void:
	clear_world()
	StoryState.restore(StoryState.checkpoint)


## The world's statics (not the story): what a fresh start, a retry and a load all clear.
static func clear_world() -> void:
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
