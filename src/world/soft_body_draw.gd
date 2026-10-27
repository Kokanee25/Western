class_name SoftBodyDraw
extends Node
## Soft bodies (the barkeep's rag, the mop's head: `SoftBody3D`) drawn inside the physics frame
## when physics is on its own thread (more-cores step 6). Godot's SoftBody3D copies its points into
## its mesh at `RenderingServer.frame_pre_draw`, outside the physics frame: there, with the thread,
## the copy is queued to the physics thread and runs after the mesh's write buffer has been closed,
## so the physics thread writes through a null pointer and the game crashes (4.7.2:
## `SoftBody3D::_draw_soft_mesh`, `SoftBodyRenderingServerHandler::close`; the drawn smoke test found
## it). Each physics tick this takes every soft body's `frame_pre_draw` connection (the engine makes
## it again whenever a soft body re-enters the world) and calls it here, where the copy is a direct
## call on the main thread. Added by Settings only with the thread on and a window that draws: without
## a window nothing is drawn and the engine never makes the copy, so the headless game is untouched.

var _draws: Array[Callable] = []


func _ready() -> void:
	process_physics_priority = -1000  # before the props move their pins: the points as the last step left them


func _physics_process(_delta: float) -> void:
	for c: Dictionary in RenderingServer.frame_pre_draw.get_connections():
		var draw: Callable = c.callable
		if draw.get_object() is SoftBody3D:
			RenderingServer.frame_pre_draw.disconnect(draw)
			if not draw in _draws:
				_draws.append(draw)
	var kept: Array[Callable] = []
	for draw in _draws:
		if draw.is_valid() and (draw.get_object() as SoftBody3D).is_inside_tree():
			draw.call()
			kept.append(draw)
	_draws = kept
