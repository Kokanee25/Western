# Step 7: every direct `RenderingServer` call in `src`, checked for a same-frame assumption

`grep -rn 'RenderingServer\.' src` (16 files today; the brief counted twelve). Godot 4.7.2's
threaded server (`servers/server_wrap_mt_common.h`, `rendering_server_default.h`) has three kinds of
call: a **write** (`FUNCn`) is queued to the render thread with its arguments copied (a `Ref` is
copied as a reference, not the object; a packed array is copy-on-write); a **read** (`FUNCnR`/`RC`)
pushes and **waits** for the render thread to empty its queue (in a debug build Godot warns after
five frames in a row of it: "causing RenderingServer synchronizations on every frame"); a few are
plain virtual calls that don't touch the queue. `frame_pre_draw` is still emitted on the main thread
in `draw()`, before the frame is queued; `frame_post_draw` is **deferred** from the render thread to
the main thread's next message-queue flush (`RenderingServerDefault::_draw`), by when the next
frame may be queued.

| File | Call | Kind | Verdict |
|---|---|---|---|
| `src/autoload/settings.gd` | `global_shader_parameter_set` | write | Fine: in order with the frame's other writes, no read back. |
| `src/debug/look_preset.gd` | `global_shader_parameter_set` | write | Fine, as above. |
| `src/debug/debug_overlay.gd` | `viewport_get_measured_render_time_cpu/gpu` | **read, every frame F3 is up** | **Fixed:** with the thread it waited for the draw in flight twice a viewport a frame (main's code, thread on, F3 up: 60 warnings each in 20 s). Now read twice a second with the thread (`RENDER_READ_FRAMES`), every frame without. After: 0 warnings. |
| `src/debug/debug_overlay.gd` | `viewport_set_measure_render_time` | write | Fine. |
| `src/debug/dev_bridge.gd` | `await frame_post_draw`, then the viewport's `get_image()` | signal + read | A drawn, whole frame, but with the thread **one frame later** than the one that posted (the read waits for the draw in flight). The bridge's screenshots are the labs' and playtests': `tools/bridge.py start` draws on the main thread unless `--render-thread=on`. Documented. |
| `src/debug/bug_recorder.gd` | `await frame_post_draw`, `get_image()`; `get_video_adapter_name` | signal + read | F12's picture may be a frame later with the thread: fine for a bug report. The adapter name is one wait, on save. |
| `src/debug/smoke_test.gd` | `frame_post_draw` (first frame), `get_current_rendering_method` | signal; plain | The first frame's time is a frame later with the thread: it's a start-up time in seconds. The method is a plain call (`OS`). |
| `src/world/soft_body_draw.gd` | `frame_pre_draw` connections | signal | Unchanged: `frame_pre_draw` is still emitted on the main thread before the frame is queued. Only made with the physics thread (step 6). The cloth's vertex upload (`mesh_surface_update_vertex_region`) is a write with a copy-on-write buffer. |
| `src/props/prop_batch.gd` | `mesh_surface_get_format_vertex_stride`; `mesh_surface_update_vertex_region` | plain; write | Stride is plain maths (not on the queue); the region write copies its `PackedByteArray`. Fine. |
| `src/effects/gun_smoke.gd`, `src/render/depth_mosaic.gd`, `src/render/probe_mosaic.gd`, `src/render/outline.gd`, `src/world/static_batch.gd` | `get_current_rendering_method` | plain | Fine (answered by `OS`, not the render thread). |
| `src/effects/gun_smoke.gd`, `src/effects/blast_cloud.gd`, `src/fire/smoke_field.gd`, `src/structures/false_front_building.gd` | `FOG_VOLUME_SHAPE_*` | constants | Nothing called. |

**Reads through nodes** (not `RenderingServer.` in the text, the same wait): `Texture2D.get_image()`
in `facade_art`, `material_stand`, `pixel_art`, `road_stones`, `human_body` (the face's maps),
`cloth_prop` waits for the render thread, once each when a thing is built, not a frame: a hitch at
building time, the right image.

**At run time** (`tools/bridge.py run build/rt_audit.txt --render-thread=on`: the street at 17:36,
F3 up, the gang and a fight, a stick of dynamite; 73 s of play under lavapipe): **no "synchronizations
on every frame" warning**. Two engine errors only with the thread, neither ours:
- `Condition "p_image.is_null() || p_image->is_empty()"` in `_texture_2d_update`: Godot's font
  cache (`text_server_adv.cpp`, a glyph page's `Image` written on the main thread while the render
  thread copies it for the queued update). 1 in 20 s without F3, 8 with F3's text up, 11 in the
  fight. That page's upload is skipped once; the next glyph re-sends it. On screen: possibly a
  letter missing for a moment in new text. Nothing seen in the screenshots.
- `This function (finalize) can only be called from the render thread` at quit, with F3 shown: the
  game still exits 0.
