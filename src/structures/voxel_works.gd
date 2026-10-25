class_name VoxelWorks
extends Node
## Collects carved members' meshes from the native plugin's worker threads (one of these per
## structure, made when one of its members is first carved). Only the swap runs here, on the main
## thread: the new mesh, the fresh-cut faces and the collision faces. It sleeps when nothing's
## being meshed. Under World.deterministic a carved member's mesh (and so its collision) is swapped
## in DUE_FRAMES after the carve, waited for if the worker isn't done: when the worker finishes
## depends on how busy the machine is, and a hole that lets a ball or a board through a frame
## sooner changes the fight.

const DUE_FRAMES := 3
var _waiting: Array[StructureMember] = []
var _due := {}  # StructureMember -> the physics frame its mesh is swapped in (deterministic only)


## Watch `m` until its voxels' mesh is ready (it's just been carved).
static func watch(m: StructureMember) -> void:
	var host := m.get_parent()
	if host == null:
		return
	var works := host.get_node_or_null(^"VoxelWorks") as VoxelWorks
	if works == null:
		works = VoxelWorks.new()
		works.name = "VoxelWorks"
		host.add_child(works, false, Node.INTERNAL_MODE_BACK)
	if not works._waiting.has(m):
		works._waiting.append(m)
		works._due[m] = Engine.get_physics_frames() + DUE_FRAMES
	works.set_process(true)


## Members still waiting for a mesh (tests).
func waiting() -> int:
	return _waiting.size()


## Everything carved so far meshed and swapped in, now (tests and tools; not the frame loop).
func finish() -> void:
	for m in _waiting:
		if is_instance_valid(m) and m.voxels != null:
			m.voxels.wait()
	_collect(true)


func _process(_delta: float) -> void:
	var t := Prof.start()
	_collect()
	Prof.stop(&"voxels", t)


## `now`: every one, due or not (finish()).
func _collect(now := false) -> void:
	var left: Array[StructureMember] = []
	var frame := Engine.get_physics_frames()
	for m in _waiting:
		if not is_instance_valid(m) or m.voxels == null:
			_due.erase(m)
			continue
		if World.deterministic:
			if frame < int(_due.get(m, 0)) and not now:
				left.append(m)
				continue
			m.voxels.wait()
		if m.voxels.poll():
			m.apply_voxel_mesh(m.voxels.take_mesh())
		if m.voxels.busy() and not World.deterministic:
			left.append(m)
		else:
			_due.erase(m)
	_waiting = left
	if _waiting.is_empty():
		set_process(false)
