# Movement that feels good (issue #301, from Sean's play in #257)

Sean, 2026-10-22: "the movement isn't fun, it moves like a dumpy first person". Before this the
player reached full speed in a tenth of a second and stopped as fast, the head bobbed on its own
beat (a dip every 1.43 m, a footstep every 0.75 m), and nothing else gave him weight.

**What's in the game now** (`src/player/player_motion.gd`, `Player._momentum`, every number a dial
in `PlayerTuning`'s groups "Speed", "Steps", "Head bob", "Lean", "The gun with the body"):

- **Momentum:** quick to a walk, slower building on to a full run (`run_build`), a stop that
  carries you a little, pushing back against your way harder (`reverse_decel`), and boots that grip
  a turn (`turn_grip`): turn hard at a run and you carry wide a step.
- **Steps:** one footfall per step (`step_walk`, `step_run`, `step_crouch`). The footstep's sound
  and the noise people hear land on it (`Player._footsteps`; the sound lab's sounds as they were),
  and so do the head's low, a thud on top (`step_thud`), the side-to-side over the planted foot and
  the legs you see looking down.
- **Lean:** a roll into a strafe and into a turn at speed, a pitch into a push off and back on a
  stop, on a spring (`lean_hz`, `lean_damping`).
- **Landing:** a dip by how fast you came down (`land_dip`, `land_dip_max`).
- **Crouch and stand:** a spring, not a slide; heavier is slower and sinks past a touch.
- **Winded** (`PlayerComposure.winded`): past half winded the run sags (`winded_slow`), and his
  breath heaves the view (`breath_heave`).
- **The gun with the body:** it lags your turns, rides your steps, drops on a landing and swings
  back on a push off; on the sights a third as much (`aim_motion`). The lag is part of the sway,
  so the shot goes where the barrel points.

**Presets:** `config/movement/light.tres`, `middle.tres`, `heavy.tres` (only the movement dials;
the gun's hold stays the game's). The game's own `config/player_tuning.tres` is middle. **F** in
the game switches light -> middle -> heavy (a toast says which; F3's readout too); the bridge's
`read player` gives `movement`.

```sh
godot --headless --fixed-fps 60 -s res://experiments/movement_feel/measure.gd   # -> results.md
experiments/movement_feel/film.sh build/movement_films                          # the three films
godot --headless --fixed-fps 60 -s res://tests/run_tests.gd -- --only=movement  # the rules
```

`film.txt` is the walk each film takes (the street, then F5's eighth stop, the new saloon): walk
and stop, run and stop, strafe left and right, turns walking, a jump, a crouch, walking on the
sights; in the saloon a walk, a turn, a short run, a crouched walk.

Results: `results.md` (the numbers), `results/2026-10-23/` (the films).
