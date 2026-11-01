# The train: the build plan

Sean, 2026-11-01, from the master planning chat (issue #542; copied here by step 1, #543). Each
step is one session (or two), ends with its proof, and stops for Sean (CLAUDE.md). The lab is
`experiments/train_lab/` (its README); the parts are `src/train/`.

## What Sean wants

- A **real working train on real tracks** that runs **daily** across the map and makes **one or two stops** (e.g. a load at the mine).
- **It feels heavy:** it starts slow, speeds up, slows down, and takes a long way to stop.
- **Good sound.**
- **It's the same train** that is blown up on the trestle near the end of the game (#466).
- **If the player breaks the track, it gets fixed:** the railroad sends a repair crew. Dynamite only comes later in the game (the miner, midgame); early damage is minor.

## How it works (the approach)

- **The track is a curve** (`Curve3D`/`Path3D`) laid on the ground; rails, ties and ballast are generated along it.
- **The train is simulated in one dimension:** distance along the track and speed, with real forces:
  - tractive effort limited by adhesion at low speed and by power at speed (the slow, heavy start);
  - rolling and air resistance (the Davis form) and gravity on grades;
  - brakes weak against the mass (a long stop: about 70–120 m from 30 km/h, a proposed dial).
- **Mass:** an 1882 narrow-gauge 2-8-0 and tender (~55 t) plus its cars.
- **Each car rides two trucks** sampled on the curve, so it swings through bends.
- **Couplers have slack** (a 1D spring-damper): slack runs out car by car on starting and bunches on braking, which drives both the motion and the clank sounds.
- **In the world** each car is a moving solid (an animatable body): it shoves props and men, the player can stand on it and ride it, and bullets hit it.
- **On a derail or a collapse** it hands off to full Jolt rigid bodies, like animation to ragdoll.
- **Far from the player** it's only the 1D numbers running to the timetable: almost free.
- **Reuse first** (`docs/PARTS.md`): the smoke and steam system, the sound lab, kit props and members, the moments/Acts data for the timetable, NPC sight for the engineer, and the persistent rubble.

## The steps

| # | Step | Done when (the proof) |
|---|---|---|
| 1 | **Track and the 1D train** in a lab (`experiments/train_lab/`): a test line of ~1.5 km with one curve, a grade of ~2–3% and two stop marks. The track is built from the curve, the cars are boxes on trucks, with throttle and brake (bridge commands plus a debug cab key). | A speed/time and speed/distance graph and a film: 0 to 25 km/h takes a believable time; the stop from 30 km/h falls in the proposed range; it slows on the climb and gathers speed downhill; no jitter on the curve; the frame cost is measured. The dials are listed as *proposed* for Sean. |
| 2 | **Couplers, riding, and stops to a timetable:** coupler slack; the cars as moving solids; an engineer NPC driving to a timetable written as data (depot and mine, dwell times, stopping on a mark). | Films: the slack running out on a start; the player riding on a car and jumping off; a crate shoved off the line; ten runs stopping on the mark within ±1 m; a late start recovering over the run. |
| 3 | **The models:** a Blender-script 2-8-0 Consolidation (D&RG narrow gauge, 1882) and tender; an ore car, a boxcar and a coach as kit props of boards. Wheels and rods turn exactly with distance travelled; steam puffs sync to the strokes (four a wheel turn); smoke from the stack through the existing smoke system. | A sheet (golden hour and night) and the critic's top three; a film of the rods at a start; the frame cost with the whole train in view. |
| 4 | **Sound, driven by the sim:** a chuff per stroke (slow and heavy at a start, blurring at speed; loudness by throttle); a rail clack per truck crossing a joint (~9 m rails, timed from distance); coupler bangs from the slack; brake squeal, steam hiss, bell, whistle, Doppler; through the sound lab. Sources: CC0 recordings (each licence checked, entered in `CREDITS.md`); ElevenLabs SFX only to fill gaps, cost asked first. | A film with sound, the train passing at three distances and a start and stop up close. Sean's ears decide. |
| 5 | **Breakable track, derails and the repair crew:** track as members (wooden ties splinter and burn, iron rails bend or tear loose); damage marks a stretch broken, bent or blocked. The engineer sees it (NPC sight, light, curves) and brakes; if he can't stop, the train hands off to rigid bodies and derails; the wreck persists; the repair crew comes and fixes it. Off-screen: the train is taken to stop at the break. | Breakage-lab-style runs: breaks at three speeds by day and night (who stops in time, who derails), the frame cost of a derail, the wreck still there after a save and load, and a repair done. |
| 6 | **Into the world** (needs the valley map #467 and Sean's canon call below): the route, a depot in town, the mine's loading spot, the daily timetable, the town's life reacting (freight, mail, payday). | A day watched from town: the train arrives, loads and leaves on time; a missed train changes the next day. |

The trestle and the last act stay with #466, after step 5.

## Sean's decisions (asked as `waiting on Sean` issues when a step reaches them)

- **Canon:** DESIGN.md has the railroad still *coming* (the first train on day 30). A daily train means the line already runs. A possible middle: the line runs to the mine and a depot, and an extension through the valley is what's fought over. (By step 6.)
- **The feel dials:** top speed, start time and stopping distance, after playing step 1.
- **The train:** its length and what it hauls.
- **The look:** the engine's colours and how clean it is (step 3).
- **Sounds:** whether they pass (step 4).

## Where it sits

The gameplay lane, beside or after the explosion fixes (#492, #538). Not in front of them: the derail and the trestle need the blast frame fixed first. Sean moves the roadmap's ▶ Now when he wants it started. Related issues: #466 (the trestle), #467 (the valley map).

## Numbers and where they're from (step 1)

Every dial is in `config/train.tres` (`TrainTuning`, `src/train/train_tuning.gd`), all *proposed*
until Sean has played it.

- **The engine:** the Denver & Rio Grande's 3 ft gauge 2-8-0s of 1880–82 (class 70, later C-16):
  ~16,000 lbf rated tractive effort (the class's name; ~71 kN), ~25 t on the drivers, 37 in
  drivers. Engine ~31 t and tender ~24 t loaded: the plan's ~55 t.
- **Adhesion:** 0.2–0.3 on dry rail (0.22 here); the drivers can't pull harder than adhesion ×
  weight on them, so the start is adhesion-bound up to ~10 km/h (the S in the speed curve).
- **Effort with speed:** the steam effort falls with speed as the cylinders fill less each stroke
  (a straight line to nothing at `effort_fade_speed`, 45 km/h), and never more than the boiler's
  power over speed (260 kW). That's what sets the top speed (~43 km/h level, full regulator) and
  the climb's settling speed (27 km/h on 2.5 %).
- **Resistance:** the Davis equation (W. J. Davis, *General Electric Review*, 1926; the form AREMA's
  manual keeps): R = W (A + B v) + C v²; curve resistance ~0.8 lb/ton a degree of curve (0.04 % of
  the weight a degree; a degree of curve is 1746/R m); a stand's breakaway more than the rolling.
- **Brakes:** 1882 cast iron shoes braking about a third of the weight at a shoe friction of
  ~0.15: ~0.04 g in all (`brake_g`), gripping harder as the wheels slow (the end-of-stop lurch);
  set over 3 s along the train. 30 km/h to a stand in ~94 m (the plan's 70–120).
- **What a real engine would do:** with three loaded box cars (106 t in all) the real class has
  far more pull than a level line needs (7 % regulator holds 25 km/h). The start's 22.6 s to
  25 km/h is the real engine's at full regulator; a slower one is a dial (`regulator_open_time`,
  `adhesion`), Sean's call.

## Numbers and where they're from (step 2, #551)

All in `config/train.tres`, all *proposed*; the timetable's in `experiments/train_lab/timetable.json`.

- **The six cars** (#552): ore cars as the D&RG's narrow-gauge drop-bottom gondolas (24 ft, ~4 t
  empty, 10 t of ore), a 30 ft boxcar (~7 t, 5 t of freight), a 34 ft express car (~10 t, the
  strongbox and mail), a 42 ft coach (~12 t, twenty aboard): with the engine and tender 119.5 t,
  66 m. Against step 1's three boxes (106 t): 0-25 km/h 22.6 -> 24.7 s, the stop from 30 km/h
  94 -> 99 m, top 43 km/h level (unchanged), 25 on 2.5 % (was 27).
- **Couplers:** link-and-pin with 65 mm of free play a coupler (the plan's 50-75 mm; real
  link-and-pin had more, 75-150 mm); past it a draft gear spring of 3 MN/m (100 kN takes 33 mm),
  damped at 0.35 of critical. A start takes the slack up front to back, the coach moving 1.9 s
  after the engine; the run-in on a stop reaches 0.38 m/s at the rear coupler (a bang: over
  `coupler_bang_speed`, 0.15 m/s).
- **Brakes down the train:** 0.35 s a car (the signal back along an 1882 train), so the rear runs
  in on the front.
- **The engineer:** plans to use 0.6 of full brake (`service_brake`), looks 2.5 s ahead
  (`brake_lead`), stands at least 60 s when late (`dwell_min`); the timetable allows the measured run
  at 22 km/h plus 20 % and lets him run 32 km/h to make up time. Ten runs stop within 0.46 m of the
  mark; a 3-minute late start is 84 s late at the mine and on time back at the depot.
