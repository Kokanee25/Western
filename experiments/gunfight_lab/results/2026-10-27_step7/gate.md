# Step 7's gate, run by run (logs in the session's `build/gate/`, summarised here)

This VM: 4 vCPUs at ~2.1 GHz, lavapipe for anything drawn. "On" is the render thread asked for
by name (Godot's `--render-thread separate`) or, for the smoke test, by the game's own setting
file (`XDG_DATA_HOME` with `[rendering] driver/threads/thread_model=2`: the path Sean's build takes).

## The suite

| run | thread | result | hung? | failures |
|---|---|---|---|---|
| off 1 | off | 753 passed, 3 failed | no | `test_perf`'s three street budgets (main fails them the same in this container: 16.7 / 19.4 / 34.1 ms against 16 / 16 / 30; CI passes) |
| on 1 | on | 750 passed, 13 failed | no | `test_perf`; `test_openings` (54 ms); the dummy race in `test_chaos`, `test_dev_bridge`, `test_project` |
| on 2 | on | 749 passed, 13 failed | no | `test_perf`; `test_openings` (41 ms); the dummy race in `test_barrel_contents`, `test_pixel_art`, `test_settle_incremental` |
| on 3 | on | 751 passed, 11 failed | no | `test_perf`; `test_openings` (53 ms); the dummy race in `test_gun_range` |
| on 4 | on | 751 passed, 56 failed | no | `test_perf`; `test_openings` (49 ms); the dummy race in `test_prop_factory` (one empty mesh read, then cached: 53 of its checks) |
| on 5 | on | 752 passed, 7 failed | no | `test_perf`; `test_openings` (45 ms); the dummy race in `test_chaos`, `test_town_day` |

**No hang in five runs with the thread on** (step 6's physics thread: 2 of 5). Every script error
in the five runs is in Godot's headless renderer's storage (`servers/rendering/dummy/...`, the
dependency tracker, the scene cull's base type) or follows from one (an empty mesh read back);
none in ours.

**The dummy race (Godot's, headless only).** `--headless` draws with the dummy renderer, whose
mesh and texture stores aren't thread-safe (`RID_Owner<DummyMesh>`, `RID_PtrOwner<DummyTexture>`;
the real renderer's are `RID_Owner<Mesh, true>`). With the render thread a mesh is allocated on the
main thread while the render thread looks another up in the same store, and the lookup can come
back empty ("Parameter "m" is null", "unimplemented base type"). It falls on a different test each
run. It doesn't happen drawn (Vulkan): the drawn runs below have none. So **the headless suite can't
be green under the thread** whatever our code does; what it does test is the hang, and the thread
didn't hang it.

**`test_openings` was ours: fixed.** The chest's first opening builds the body's inside, a
material copy a shell; `ShaderMaterial.duplicate()` asks the RenderingServer for the shader's
uniforms each copy, a wait on the render thread (0.08 -> 1.2 ms a copy): `BodyInterior.build` 9
-> 38-47 ms. `BodyInterior.copy_material` asks once a shader: 10 ms with the thread, 6.4 without.
After: `test_openings`, `test_bodies`, `test_body_lab`, `test_wound_signs`, `test_body_impacts`
all pass with the thread on and off.

**Drawn, the tests the race hit** (`xvfb-run`, Vulkan on lavapipe, `--render-thread separate`):

| test file | result | the dummy race | what failed |
|---|---|---|---|
| `test_project` | 10 passed, 6 failed | none | one test, the main scene loaded: 6 font-cache upload errors |
| `test_gun_range` | 9 passed, 2 failed | none | one test: 2 `particles_set_view_axis` (a shot's smoke ending) |
| `test_barrel_contents` | 12 passed | none | |
| `test_pixel_art` | 15 passed, 4 failed | none | one test, the main scene loaded: 4 font-cache upload errors |
| `test_dev_bridge` | 3 passed, 3 failed | none | 1 `particles_set_view_axis` each |

Every check of ours passed; each failure is a test that counts engine errors meeting one of
Godot's two errors below.

## The lab (10 D fights in the spec hall, `--jobs=1`, headless)

- `main` (main at bc8d5d2, its own worktree, as it is) vs `off_a`: **10 of 10 the same**.
- `on_a` vs `on_b` (the thread on twice): **10 of 10**.
- `off_a` vs `on_a`: **10 of 10**; `main` vs `on_b`: **10 of 10**.
- 2 of `on_a`'s 10 logs carry the dummy race's errors, and the fights are still the same.
- After the merge with main at 55a510b1 (host 2): main there (`main3`) against this branch with
  the thread on (`on_e`): **10 of 10**; frame 14.66 -> 15.21 ms (p95 17.70 -> 18.44). The suite with
  the thread off on the merged branch: **775 passed, 0 failed**.

## The drawn smoke test (two cores, `taskset -c 0,1`, 640x360, the thread on from the setting file)

| run | exit | time | verdict |
|---|---|---|---|
| on 1-5 | 1, 1, 1, 1, 1 | 333, 134, 132, 136, 279 s | **exited every time**; the whole course played (gang, stick, fire, shot); FAILED only on Godot's errors: 26 font-cache lines and 5 particles lines over the five |
| off 1 | 0 | 107 s | ok: 43 s, 20 people, the native plugin loaded |

The two engine errors, only with the thread, neither in our code:
- `_texture_2d_update`: `p_image` empty. Godot's font cache (`text_server_adv.cpp`) writes a glyph
  page's `Image` on the main thread while the render thread copies it for the queued upload.
  That upload is skipped; the next glyph resends the page.
- `particles_set_view_axis`: `particles` null. The scene cull, during the draw, queues a call for
  each particles instance back onto the render thread (`call_on_render_thread`); a particles node
  freed by the main thread meanwhile (an effect ending) is gone when it runs. It returns at once.
  Any `GPUParticles3D` freed while on screen can do it.
- And at quit, with text drawn: `This function (finalize) can only be called from the render
  thread`. The game exits 0 anyway.

## The soak (`--minutes=240`, `--render-thread separate`, headless)

- First run: the container restarted 55 game minutes in (nothing wrong before it: no problem,
  frame 7.8 ms, 1241 MB).
- Second run: **210 game minutes, no freeze**, stopped by the 3-hour cap this session put on it
  (the golden render beside it slowed it for an hour, then was paused). The clock file moved every
  600 frames to the end (757,800 frames); memory flat at ~1306 MB from 120 minutes on; nodes
  ~26,500; orphans fell 14,000 -> 321; frame 7-8 ms in the quiet windows. Step 6's physics thread
  froze the soak at 121. The one problem: the dummy race's empty mesh at start, while the saloon
  was built (headless, as above). No `soak.md` (written only at 240).

## The goldens (`python3 tools/golden_check.py --render`, the thread off as the tools are)

**This branch renders what main renders; main's goldens don't hold on this machine.** The full
render: 77 views, 23 over their tolerance. main (bc8d5d2, its own worktree) rendering the same 23:
20 over (`porch_dusk`, the night views, the range views...). Branch against main, render for render:
19 of the 23 within 0.02-0.33 mean (noise); the rest explained:
- `outlaw_back`, `shotgun_open`, `outlaw_blast` (~7 apart): the golden render draws its views in
  batches, one game a batch, and what an earlier view leaves behind moves a later one; main's
  23-view render batched them differently. Rendered alone, `outlaw_back` is 6.94 from its golden
  on both, 0.15 between them.
- `porch_collapse` (the collapse's rubble): two runs of the same code differ by 6.2-8.8; branch
  against main 6.5-7.6, inside that.
- `gun_smoke_saloon`: its tolerance is noise-set (16.8); 2.3 between branch and main, 63 from the
  golden on both.

Nothing re-approved. Nothing this step changes runs in a tool's render: the tools draw on the main
thread (the lamps' every-frame flicker and F3 as before), and `copy_material` gives a wound's inside
the same values as `duplicate()`.
