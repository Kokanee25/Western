# Train step 5 (#616): breakable track, derails and the repair crew

Everything here runs in the train lab (`experiments/train_lab/`, its README's "Step 5"); nothing in
the town changed. Every number is a proposed dial in `config/train.tres` (the brief's "Numbers and
where they're from (step 5)").

## The derail table (`table.md`, every run's numbers in `runs/`)

Eighteen runs, each in a fresh headless game at a fixed 60 fps step (`derail_runs.py`). The break
is the left rail torn out at 380 m (the end of the first straight) or at 560 m (the middle of the
120 m left-hand bend), unless the row says otherwise. Six passengers ride in the coach, and the
engineer's body is in the cab.

| run | km/h | light | what's wrong | who's driving | seen at | outcome | men thrown |
|---|---|---|---|---|---|---|---|
| straight, walking | 5 | day / night | rail gone | engineer | 55 m (where it started) | stops 54 m short | 0 |
| straight | 20 | day | rail gone | engineer | 220 m | stops 171 m short | 0 |
| straight | 20 | night | rail gone | engineer | 64 m (the headlight) | stops 15 m short | 0 |
| straight | 40 | day | rail gone | engineer | 220 m | stops 46 m short | 0 |
| straight | 40 | night | rail gone | engineer | 64 m | **derails** at 35 km/h: the engine 12 m on, 2.1 m off, on its side; 5 of 7 cars over | 7 |
| bend | 20 | day | rail gone | engineer | 132 m (**the fireman**) | stops 82 m short | 0 |
| bend | 20 | night | rail gone | engineer | never | **derails** at 19 km/h, 0.7 m off, upright | 7 |
| bend | 40 | day | rail gone | engineer | 131 m (the fireman) | **derails** at 20 km/h (braked from 40), 0.5 m off | 7 |
| bend | 40 | night | rail gone | engineer | never | **derails** at 37 km/h, 2.2 m off, 3 of 7 cars over | 7 |
| nobody watching | 5 | day | rail gone | none | - | lurches off the rail, drops onto the ties, leans 4 degrees, stops within 2 m | 0 |
| nobody watching | 20 | day | rail gone | none | - | derails: the engine 2 m off, on its side; 4 cars over | 0 |
| nobody watching | 40 | day | rail gone | none | - | derails: the engine 13 m on, 3.8 m off; 2 cars over | 6 |
| three sticks on the ties | 40 | night | broken: 3 ties gone in a row | engineer | 63 m | derails: the engine 20 m on, on its side; 6 cars over | 7 |
| a bent rail (12 cm) | 40 | night | bent | engineer | 64 m | derails: 14 m on, on its side | 7 |
| a crate | 20 | day | blocked | none | - | the pilot throws it aside, runs through | - |
| a man down across the rails | 20 | day | blocked | none | - | run over: both shins and an arm off (gore on) | - |
| a 2 t block | 20 | day | blocked | none | - | derails, 0.5 m off, upright | 0 |

What it shows:

- **By day on the straight the engineer always stops in time** (he sees a broken rail at 220 m
  and needs ~180 m from 40 km/h). **At night the headlight shows it at 64 m:** that's enough from
  20 km/h (stopped 15 m short) but not from 40 km/h, which derails at 35 km/h.
- **The left-hand bend is blind to the engineer:** he sits on the right, and the boiler, dome and
  stack hide the inside of the curve from him even 22 m out. That's true of a real cab, and it's
  why a fireman watched the left side. So the fireman is a second pair of eyes, watching less
  (`fireman_watch` 0.6 of the engineer's reach, his shout 0.6 s later). By day he catches the
  break at ~130 m: enough from 20 km/h, not from 40. At night nobody sees it on the bend, because
  the headlight points along the engine and lights the outside of the curve.
- **Walking pace doesn't tip the engine over.** It lurches off the broken rail, its wheels drop
  onto the ties, it leans 4 degrees and stands within ~2 m. That's what a slow derail does; it
  isn't the "tips into the ballast" the issue asked for. Going over at walking pace would need
  more push than the physics gives it.
- **At 20-40 km/h it's a wreck:** the engine runs off toward the broken side and often onto its
  side, the cars behind pile into it, jackknife through the coupler slack and tip.
- **No coupler tore and no car broke into sections in any run at these speeds** (the dials: a
  coupler strained 0.35 m, a car stopped by 6 m/s inside 0.15 s). The section break is exercised
  directly by `test_a_car_stopped_hard_breaks_into_big_sections`: front, back and roof, each its
  own body with its shapes and boards.
- **Men are thrown in the hard derails** (their car jolting past 0.8 g, or tipping past 35
  degrees): all seven in the 40 km/h and bend wrecks, none in the gentler ones.

## The frame cost of a derail, against #492's gate

The gate: one hitch under ~100 ms at Sean's, and back over 50 fps within half a second. Measured
headless here: the CPU side only, with no rendering. Sean's numbers are here x 0.65, the frame
budget's `clock_scale`.

- **Every run passes.** The worst frame of any run was **67 ms here (44 ms at Sean's)**: 40 km/h,
  nobody driving, six men thrown. The longest spell under 50 fps at Sean's was 0.08 s. Most
  derails' worst frame was 25-45 ms here (16-29 at Sean's).
- **What it took to pass:** in the first round, seven men went limp on the same tick in the
  40 km/h bend wreck, a **215 ms frame here (140 at Sean's)**, and the gate failed. Making a ragdoll
  costs ~30 ms here. Now one man goes limp a tick, the rest a tick or two later as their car keeps
  jolting them. What the player sees doesn't change: the car's still throwing them.
- **The idle line** (`idle_members.jsonl`, `idle_drawn.jsonl`): the 1.5 km line as members (2,933
  more nodes, its ties and rails at rest in their chunks' batches) against step 1's drawn track,
  four samples each. Physics 3.9-4.6 ms against 3.9-4.3, process 0.63-0.68 against 0.62-0.67:
  within this machine's noise. Draw calls weren't measured: headless draws nothing.

## The rest of the proof (`tests/test_track.gd`, 12 tests)

- The track is members that stand under their own weight, every member at rest. One stick on a
  tie bends the rail or breaks the line; three break it; no rail is ever cut or snapped.
- The track's state is keyed by the route's section id and the distance along it. The save puts
  it back on the same route, and on a **re-laid route** (another origin and heading, an 80 m
  approach section in front) the damage lands in its same section, past the new approach.
- The wheels run over a man lying across the rails (a limb off with gore on), and he goes limp.
- The engineer: the same seed gives the same sighting and the same stop. By night he sees the
  break later, and at 40 km/h it derails.
- Off screen, the 1D train derails in numbers: no bodies, ploughing to a stand past the break.
- The hand-off keeps the momentum (the bodies at the 1D train's speed).
- **The wreck and the track's damage survive a save and load:** every body laid again within
  5 cm of where it lay, the same stretches.
- **The repair crew** (with short work times) clears a crate off the line, lays the chunk again
  and walks off. The line is whole again and the next train runs through.

## Films (`films/`)

The scripts are in `experiments/train_lab/films/step5/`; each was rendered in a game under xvfb
with the software renderer. **Stop short** (noon, 20 km/h). **The slow derail** (walking pace,
nobody watching). **The wreck at speed** (40 km/h, six in the coach; lineside, then alongside the
coach). **A crate struck**. **A man run over** (gore on).

## Not done, or not as asked

- At walking pace it doesn't tip into the ballast (above).
- No coupler tears and no car breaks at 40 km/h with these dials; it takes a harder wreck.
- The repair crew is proven by the test only, with no film: with the proposed times, mending a
  torn-out rail is ~10 minutes of game time.
- Fire on the ties: fire is out of play (#458), so it wasn't tried. The ties are timber, so the
  fire system reaches them when it's back on.
- The frame costs are headless (the CPU side). The render cost of a wreck isn't measured.
