# Automated checks, so Sean reviews less

Sean, 2026-10-05: "Add automated checks so Sean reviews less, one merge each." The game should
catch its own breakage before a build reaches him: what a playtest, a soak or a replay can find,
a machine finds.

## Gameplay session (owns CI). One merge each, in this order

1. **Bug-report key** (F12; debug ignite keeps L). One press saves one file
   (`user://bug_reports/<date-time>.saltbug`, a zip): a screenshot, the last 30 s of inputs as a
   replayable recording (every action's presses and releases and the look by physics tick, from a
   snapshot taken 30 s before: the clock, where everyone is, the seeds), the log, the build number,
   your position and facing, the settings. `tools/replay.gd FILE` plays it back headless or drawn
   and says where it went differently. Done when a report made in a fight replays to the same
   outcome.
2. **Nightly soak test** (scheduled workflow): hours of game time at speed with the gang, the
   townsfolk and fights. Fails on any script error, memory that keeps growing, anyone stuck (not
   moving toward where his brain wants for minutes), anyone under the floor or flung off the map,
   or frame time that creeps. A report as a run artifact.
3. **Chaos tests:** random blasts, fires and shots on the street from a seed. Invariants hold
   (nothing under the ground, no NaN positions, every member either standing, rubble or gone, blood
   only falls, the dead stay dead, no orphaned nodes, the frame budget's worst frame), and the same
   seed gives the same result.
4. **Feel ranges:** the numbers that make the game feel right, measured by headless runs and kept
   in a data file with agreed ranges (`config/feel_ranges.json`): duel length, how often a man backs
   down, how fast fire spreads, the outlaw's hit rate at 5/15/30 m, body hits to stop a man, the
   shotgun's drop rate at 20 m. A number out of its range fails CI, and the range only moves with
   Sean's OK (written in the file with the date).
5. **Smoke test the exported builds:** each export (Linux, Windows, macOS) is launched on its own
   runner for 30 s; it must start, load the street, run without script errors and quit cleanly.
6. **Sound checks:** every synthesised sound (gunshots, cracks, ricochets, glass, blasts, fire)
   rendered and checked: no clipping, nothing below 40 Hz (Sean's monitor drops out on deep bass),
   no silence where a sound should be.

## Art session: the visual checks (please)

Write the checks as a script that judges renders already made, and gameplay wires it into CI on
every push (renders under lavapipe, as `tools/judge.py` does now):

- `python3 tools/visual_checks.py --from=DIR` reads the renders of `tools/screenshots.gd` (and the
  tour's frames, `build/tour/`, when they're there), prints a line per check per view and exits 1 on
  a failure. Per-view tolerances in a data file, like the golden images'.
- The checks: **blank frames** (all one colour, all black, NaN-black like the saloon at 23:40 was),
  **missing textures** (Godot's magenta/checker, or a grid material with no texture), **flicker**
  (two renders of a still camera that differ: `tools/flicker_probe.gd` can make them), **floating
  objects** (props and people not on what's under them), **clothes through bodies** (body skin
  showing through a garment), **feet in the floor** (a standing man's soles below the ground or
  floorboards).
- If a check needs the scene's data rather than pixels (where feet are, what a prop rests on), a
  Godot tool script that writes it next to the renders is fine; say what it writes.
- Gameplay adds the CI job once the script is on main and tells Sean which build first runs it.
