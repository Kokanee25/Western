# The body lab

Roadmap 3.1b (`docs/briefs/labs.md`, "Body lab"): a bench for wounds. Shots and blasts go into a
standing man at fixed spots. What the anatomy does is checked against published trauma medicine.
**It changes nothing in the game.** It calls the production `HumanBody`, `Anatomy`, `Physiology`,
`Ballistics` and `Blast` untouched, and measures today's game so that later fixes can be measured
against this baseline.

Outputs go under `build/body_lab/` (git-ignored). The committed baseline is in `baseline/`.

## Commands

```sh
# every scenario on every man (the three studio men and the outlaw), one Godot process each (~3 min on 4 cores)
python3 experiments/body_lab/run.py --out=build/body_lab/base
python3 experiments/body_lab/run.py --scenario=group:revolver,dynamite_1m --model=old_rancher_s1 --out=...
python3 experiments/body_lab/run.py --scenario=list
# every artery, vein and organ cut on its own, each treatment (no scene; a second)
python3 experiments/body_lab/run.py --vessels --out=build/body_lab/base
# ten wounded men against the people budget (nothing else on the CPU; `mixed` = the three studio men in turn)
python3 experiments/body_lab/run.py --perf --model=mixed --out=build/body_lab/perf
# pictures: every spot from 5 m (revolver and shotgun), the dynamite and each man's check (xvfb + lavapipe, ~30 min)
python3 experiments/body_lab/run.py --render --out=build/body_lab/render     # then RUN/sheet_<model>.png
# the tables again, from a run
python3 experiments/body_lab/report.py gather RUN      # RUN/baseline.md, RUN/baseline.json
python3 experiments/body_lab/report.py vessels RUN     # RUN/vessels.md
python3 experiments/body_lab/report.py sheets RUN      # RUN/sheet_<model>.png
# one run straight from Godot (what run.py calls)
godot --headless --fixed-fps 60 -s res://experiments/body_lab/lab.gd -- --scenario=revolver_05m_thigh --model=young_drifter_s1 --out=DIR
```

`lab.gd` also takes `--seed=N`, `--render` and `--size=WxH`. **The man is the lab's choice:**
`--model=ID` is any `assets/people/<id>.glb`, comma-separated for several. It is never the game's
default. `run.py` runs the four in `scenarios.json` (`models`): `bold_cowboy_s0`,
`old_rancher_s1`, `young_drifter_s1` and `outlaw`. The outlaw is there so that earlier results
(the ragdoll lab's) still compare.

**Dev bridge** (`bridge.gd`, loaded by the bridge from this folder, `src/debug/bridge_lab.gd`):
- `body_spawn MODEL X Y Z [YAW]` puts a man of that model in the street, with no brain.
- `body_shoot PERSON SPOT [revolver|shotgun] [RANGE]` fires a perfect aim at a marked spot from in
  front of him.
- `body_blast PERSON [DIST]` puts a stick on the ground that far in front of him.
- `body_treat PERSON tourniquet|packing|doctor` treats him now.
- `body_read PERSON` reports his wounds, what they crossed, what he can do, and his blood run
  forward from now under each treatment.

```sh
python3 tools/bridge.py start --headless
python3 tools/bridge.py "body_spawn old_rancher_s1 0 0 8" "body_shoot body1 thigh revolver 15" "body_read body1" \
    "body_treat body1 tourniquet" "body_read body1"
python3 tools/bridge.py stop
```

## Files

- `scenarios.json` holds the axes the lab expands into scenarios:
  - weapons, ranges and spots;
  - the dynamite distances;
  - the treatments and their times;
  - the models;
  - the perf run;
  - the seed, the live seconds and the horizon.

  Edit it to add a spot, range or treatment; no code change is needed. The scenarios are:
  - `revolver_05m_thigh` … `shotgun_30m_hand` (2 guns × 3 ranges × 6 spots);
  - `dynamite_1m`, `dynamite_3m` and `dynamite_6m`;
  - `check`, the man's own body;
  - `same_tick`, a ball fired on the tick a man goes limp (the bug below);
  - `perf`.
- `wound_bench.gd` is the bench. The command line and the bridge share it. It covers:
  - aiming and firing with the game's loads and sights;
  - sampling the aim;
  - what a wound crossed;
  - what he can still do;
  - the treatments;
  - running the blood forward.
- `lab.gd` is the command line. It extends the ragdoll lab's `lab.gd` for its arguments and git SHA.
- `lab_runner.gd` runs one scenario on one man. It extends the ragdoll lab's runner for its ground,
  light and stats.
- `run.py` runs one process per run, as the ragdoll lab does. It borrows that lab's argument reader.
- `report.py` makes the tables and sheets. It borrows the ragdoll lab's tile label.
- `bridge.gd` holds the dev bridge commands.
- `baseline/` is the committed baseline:
  - `baseline.md` and `baseline.json` (every run);
  - `vessels.md` and `vessels.json`;
  - `perf_*.json`;
  - `sheet_<model>.jpg`, the wound sheets.
- `tests/test_body_lab.gd` checks that the bench aims, fires and treats as it says, and that the bridge
  file loads as a lab.

### What a run does

1. **The man.** The production `HumanBody` with `body_model` set to the chosen man and no gun. He
   stands half a second on level ground and is shot or blasted. Then he has 3 s live: he falls,
   bleeds, loses what he loses, and is drawn if `--render`.
2. **The shot.**
   - The shooter's eye is `range` m in front of him at 1.5 m.
   - He is sighted on the spot's point inside the man as he stands. The sights are regulated for the
     gun's zero, as `WeaponViewmodel.zeroed` does, with the muzzle at the eye.
   - The ball is fired through the game's `Ballistics` with the game's load (`config/revolver.tres`,
     `config/shotgun.tres`): its drop and drag, the garments, `HumanBody.take_bullet`, and
     `Anatomy.trace`.
   - The shotgun fires a real charge, with the pattern drawn from the lab's seeded rng.
3. **The aim.** Before the shot, 200 aimed shots are sampled without touching him. Each has the
   game's aimed wobble (`spread_aim_degrees`) and buckshot's pattern pellet by pellet. Each is a ray
   to the part it meets, then `Anatomy.trace` on a copy of the rng to see what it would cross. The
   result is what an aimed shot gets: the share reaching the marked part and the share crossing what
   the spot aims for.
4. **The blast.** One stick (`BlastTuning.tnt_per_stick`, 0.2 kg) lies on the ground `range` m in
   front of him and goes off through `Blast.detonate`, with its gravel.
5. **The blood forward.** After the live seconds his physiology is copied (`Physiology.to_dict`).
   Each treatment then runs it forward to 2 h at 0.1 s steps. Bleeding runs in real seconds, as the
   game's does.
   - **None.**
   - **Tourniquet at 30 s**: a belt high on the limb above every limb bleed too fast to clot, as
     `OutlawBrain._tend` and `PlayerWounds._tend` decide. It is *n/a* off the limbs.
   - **Packing at 30 s**: pressure and a binding on every outside bleed, the game's "packed and bound".
   - **The doctor at 10 min, after packing at 30 s**: every bleed tied off, the lungs sealed and the
     gut sewn. This is `PlayerWounds._patch_up`'s surgery, with no blood given back. No NPC doctor
     exists yet, so this is the lab's.

   *Dead first* means he died before that treatment's time.
6. **The check** (`check`, one run per man) uses four men:
   - **A revolver ball into the chest.** Is the wound open? Is the inside built? Does every chest
     piece's material show it?
   - **A ball through the hat's crown**, 1.5 cm below its top. Is the hat off and flying? Did it
     wound his head? Also measured: the crown's clearance over his skull's capsule.
   - **His right forearm, then 1 s later his left shin**, taken off with the production `sever_limb`.
     Is the joint freed? Did the limb fly? Does the skin's bone follow the part? How much open rim
     (edges used by one triangle, within 8 cm of the joint in the rest pose) do the stump and the
     limb end show?
   - **A stick 1 m off.** Is he thrown, and does the hat stay on?
7. **Perf.**
   - Ten men 1.5 m apart (`mixed` cycles the three studio men) stand for 2 s.
   - Each is then shot with the revolver from 5 m, the spots in turn, and the frame is measured for
     10 s.
   - The measure is the people timers `Prof` keeps (`people_body`, `people_skeleton`, `blood`) per
     frame, and the whole frame (wall clock, headless, unpaced).
   - The men have **no brains**: the budget's people row also counts senses and brains, so add those
     from the perf bench.

### Measures and their limits

- **The hitboxes are the anatomy's, not the mesh.** Every man shares the same 1.78 m anatomy
  (`config/anatomy.json`) and the same 17 capsule parts. So every shot and blast came out **the same
  on all four men** (the `same` column), number for number. What differs between men is how a wound,
  a stump and a hat look, so the check and the sheets are where the new men are judged.
- One perfect shot per scenario is one draw. The aim columns (200 shots) are the spread.
- The aim's ray is straight from the eye to where the zeroed ball lands. The arc's angle at arrival
  differs by well under a degree at these ranges.
- No brains and no tending: these are the body's numbers. In the game a man tends himself (pressure,
  then a belt after 4 s) when his brain lets him.
- Game seconds are real seconds for bleeding. The gut's death is in game hours (30 h, a game day
  being 45 real minutes), so a gut wound kills in 56 real minutes.
- Frame times are this workspace's core (a 4-thread Xeon, `baseline/manifest.json`), ×0.65 for
  Sean's as CLAUDE.md's frame budget scales it.
- Rendering is lavapipe (no GPU here). Sean's eye on a real GPU is still the judge of how wounds look.

### Determinism

- Seeded throughout: the lab's rng (pattern and aim samples, from `seed`), each man's
  `rng_seed = seed + i`, and the blast's own seed (by where it went off).
- Two runs of the same build gave the same numbers: the four men agree exactly, and the rendered run
  repeats the headless one's deaths to the tenth of a second.
- One process per run, as the ragdoll lab found it must (its README, "Determinism").

## Baseline (2026-10-21, source 4db0224 + this lab)

The full tables are in `baseline/baseline.md` (shots, dynamite, the checks) and
`baseline/vessels.md` (every vessel alone). The wound sheets are `baseline/sheet_<model>.jpg`.

### Bleed-out per vessel (cut alone, no wound track; `baseline/vessels.md`)

| vessel | ml/s | untreated: out / dead | packed 30 s | tourniquet 30 s | doctor 10 min | medicine |
|---|---|---|---|---|---|---|
| heart | 110 | 23 s / 32 s | 36 s | n/a | dead first | ~80–90% of penetrating heart wounds die before treatment [5]; out 4–21 s once the circulation stops [6] |
| aorta (chest) | 90 | 28 s / 38 s | 1:04 | n/a | dead first | ~85% of aortic tears die at once [7] |
| abdominal aorta | 80 | 32 s / 43 s | 1:23 | n/a | dead first | |
| carotid | 18 | 2:21 / 3:12 | 11:20 | n/a | lives | resting flow 415 ml/min a side [4] (game 1,080) |
| iliac | 15 | 2:50 / 3:51 | 13:54 | n/a | lives | |
| subclavian | 14 | 3:02 / 4:07 | 15:00 | n/a | lives | |
| femoral | 12 | 3:32 / 4:48 | 17:45 | lives (−319 ml) | lives (−1.7 L) | resting flow ~300 ml/min [3] (game 720); no peer-reviewed bleed-out time found (the "about 3 min" figure is folklore and a model [3]) |
| femoral + femoral vein (the thigh shot) | 18 | 2:19 / 3:09 | 11:13 | lives (−0.5 L) | lives (−2.3 L) | |
| brachial | 7 | 6:04 / 8:15 | 31:30 | lives (−177 ml) | lives (−1.0 L) | resting flow 65–130 ml/min [4] (game 420) |
| liver / spleen (a ball) | 8 / 5 | 5:19 / 7:13; 8:30 / 11:33 | 27:22; 44:42 | n/a | lives | |
| radial, ulnar, tibial, kidney, lung | 2–4 | clot; lives | | | | a single holed lung usually lives (chest drain alone treats 69–90%) [14] |
| gut (stomach, bowel, bladder) | 0.2–0.3 | dies of the gut at 56 min real (30 game h) | the same | n/a | lives | Civil War penetrating belly wounds ~88% fatal, deaths at ~5–9 days [8] |

Death is at 50% blood lost, out cold at 40% and shock at 20% (`PhysiologyTuning`). ATLS calls more
than 40% class IV and life-threatening [1], and a man of 80 kg has about 5.6 L [1].

### Shots (perfect aim; the same on all four men; `baseline/baseline.md`)

| spot | revolver: crossed | can't | untreated | tourniquet / packed / doctor | aimed shots on target 5 / 15 / 30 m |
|---|---|---|---|---|---|
| thigh | femoral artery and vein, femur broken | stand (down) | 3:09 | lives / 11:13 / lives | 72 / 34 / 22% |
| neck | carotid, jugular | nothing | 2:02 | n/a / 6:42 / dead first | 57 / 19 / 12% |
| upper arm | brachial, humerus broken | grip that hand | 8:07 | lives / 31:18 / lives | 84 / 44 / 26% |
| chest | heart, left lung, a rib | run | 31 s | n/a / 33 s / dead first | 100 / 66 / 28% |
| belly | abdominal aorta, gut, lumbar spine broken (cord whole) | run (down) | 43 s | n/a / 1:21 / dead first | 100 / 99 / 47% |
| hand | hand bones broken, thumb off | grip that hand | lives (−71 ml) | | 98 / 40 / 19% |

- The revolver carries 612 J at 5 m and 580 J at 30 m. It lands within 2 cm of the mark at every
  range with its sights at 25 yards.
- Buckshot carries 233 J a pellet at 5 m, 190 J at 15 m and 150 J at 30 m.
  - At 5 m about 7–9 pellets reach him.
  - At 30 m 2–3 do, anywhere on him: one aimed at the neck took the left femoral.
  - Charges at 5 m into the chest, belly, neck or upper arm left him out cold at once (no grip, no
    speech) or dead within seconds to minutes.
  - At 30 m most charges only graze or lodge.

### Bones and what they stop

| bone | the game | medicine |
|---|---|---|
| femur | can't stand, goes down (`leg_ok`); no blood from the break itself | a closed femoral shaft fracture loses ~1.2–1.3 L into the thigh [9] |
| humerus | that hand can't hold a gun | radial nerve palsy in ~10–12% of humeral shaft fractures [10] (the game has the nerve; a ball that misses it still takes the grip by the bone) |
| hand bones | that hand can't hold a gun; a finger in the path comes off | |
| lumbar spine | can't run; legs fine unless the cord is cut | |
| pelvis | can't stand | |

### Limbs lost

- **None from any gun, at any range.** A shotgun at 5 m takes fingers at most. The game only severs
  limbs by blast.
- **None from dynamite at 1, 3 or 6 m.** Severing needs 1,500 kPa at a hand or foot (2,600 for a
  forearm or shin, 4,500 for an upper arm or thigh), side-on. One stick reaches that only within
  ~0.35 m of the part.
- **Where the cut falls:** always at the joint above the part. In `sever_limb` the stump wound is
  0 cm from the joint. Blast amputations happen through the bone shaft, the shock wave breaking it
  and the wind taking the limb [12]. Through-joint ones were 1.3% in survivors' series and 22% in
  post-mortem CT [12].

### Dynamite (0.2 kg on the ground)

| | chest, side-on | what happened | gravel that left toward him |
|---|---|---|---|
| 1 m | 103 kPa | both eardrums, thrown off his feet. **No wound, no blood** | 4 (none hit: see below) |
| 3 m | 24 kPa | nothing | 2 |
| 6 m | 9 kPa | nothing | 0 |

- Eardrums burst from ~35 kPa, half at ~100 kPa [11]. The game bursts all of them by 140.
- Lung injury starts at ~100 kPa for a long wave [11], and much higher for a few-millisecond one
  like a stick's [11]. The game's 250 kPa is in that range.

### Ten wounded men (`baseline/perf_*.json`; two runs each, mean (p99) ms a frame, this workspace)

| men | standing: frame / people | wounded, 10 s after: frame / people (body, skeleton, blood) | people at Sean's | budget |
|---|---|---|---|---|
| 10 studio men | 3.6–3.8 / 1.7–1.8 | 3.3–3.5 (6.3) / 2.2–2.3 (4.1–4.2) (1.5, 0.2, 0.5) | **1.4–1.5** | 4.0 |
| 10 outlaws | 3.5–3.6 / 1.6–1.7 | 3.2–3.6 (6.7–7.6) / 2.1–2.4 (4.6) (1.4–1.7, 0.2, 0.5) | 1.35–1.55 | 4.0 |

- Ten wounded men's own bodies take a little over a third of the people budget at Sean's. Blood
  (jets and sprays) is 0.5 ms of it.
- The studio men cost no more than the outlaw.
- Two of the ten were down at the end; the rest were still on their feet (a man shot through the
  heart stays standing until he passes out at 23 s: `revolver_05m_chest`).
- Brains aren't counted (see the limits above).

### Each man's check (`baseline/baseline.md`, "Each man's check"; sheets in `baseline/`)

| | bold_cowboy_s0 | old_rancher_s1 | young_drifter_s1 | outlaw |
|---|---|---|---|---|
| loaded, pieces | yes, 17 (one skin piece a part) | yes, 20 (+ hat) | yes, 20 (+ hat) | yes, 52 (clothes their own) |
| a chest wound shows | 1 of 1 pieces | 1 of 1 | 1 of 1 | 4 of 4 |
| stumps (open rim, cm) | forearm 48, shin 53 | forearm 28, shin 22 | forearm 46, shin 49 | forearm 94 (+ shirt 118), shin 63 (+ trousers 60) |
| limb flies, skin follows its bone | yes | yes | yes | yes |
| hat | none (his model has none) | shot off and flies | shot off and flies | shot off and flies |
| crown over the skull | – | **1.0 cm** | 2.3 cm | 2.7 cm |
| a ball through the crown | – | **wounds his head** | misses his head | misses his head |
| hat when a blast throws him | – | stays on | stays on | stays on |

No stump on any man is capped: every cut leaves an open rim of skin. What fills it is the wound
opening (`BodyInterior`, the insides drawn through the 2,200 J opening `sever_limb` makes). The sheets
show how that reads.

## Where the game is furthest from the medicine

1. **Packing never stops an artery.**
   - Pressure keeps a quarter of the bleed (`pressure_factor` 0.25).
   - An arterial bleed was marked as one that doesn't clot when it opened, so packing only slows it.
   - A packed femoral still kills in 18 min (11 with the vein). A packed carotid kills in 11.
   - In the standard swine femoral model, gauze and three minutes of pressure stop the bleeding in a
     third to seven in ten [13], and direct pressure is the first thing taught.
   - Only a belt (factor 0, total) or the doctor saves an arterial wound in the game.
2. **A ball's heart, liver and spleen bleed "outside"**, so packing presses them.
   - A ball through the heart, liver, spleen or kidney opens an ordinary bleed (`_add_bleed`'s
     default kind), which packing slows. A packed heart lasts 36 s instead of 32; a packed liver
     27 min instead of 7.
   - That blood goes into the chest and belly, where no outside pressure reaches it.
   - Only the blunt burst organ (`Physiology.blow`) bleeds `internal`.
3. **Dynamite at a man's feet does almost nothing.**
   - At 1 m: two eardrums and a fall, no wound.
   - People take side-on pressure with no ground reflection, and severing needs 1.5–4.5 MPa.
   - The gravel and splinters that would wound him miss: **a bug, below.**
   - The design's rule (dynamite at close range can take limbs) holds only within about a third of a
     metre.
4. **Limbs come off at the joint.** Blast amputations go through the bone shaft; through-joint ones
   are the rare case [12]. Every stump in the game is at a wrist, elbow, shoulder, ankle, knee or hip.
5. **A broken femur costs no blood.** The game gives pain and takes his leg; the break itself
   should be ~1.2 L lost into the thigh [9].
6. **The arteries bleed several times their resting flow** [3][4]: femoral 2.4×, carotid 2.6×,
   brachial 3–6×. A cut artery's open end isn't its resting flow, so this is the least certain
   gap. No peer-reviewed bleed-out time was found for any one artery. The game's times agree with
   the folk "a femoral kills in about three minutes".
7. **The gut kills in 1.25 game days.** The Civil War's belly wounds were about 88% fatal, mostly
   from peritonitis at about 5–9 days [8]. That is four to seven times longer.

What's close:
- The share of blood at which he goes into shock, out cold and dead, against ATLS [1].
- The heart and aorta's seconds [5][6][7].
- A belt saving a limb wound when it goes on before shock [2]: Kragh, 90% survival before shock and
  10% after.
- A single holed lung living [14].
- The eardrum thresholds [11].
- Grip lost with a broken humerus or hand.

## What doesn't work on the new men

- **The ball passes through the man who goes down on its tick** (all men, the new ones too).
  - When a man goes limp, `go_limp()` builds new rigid parts. Until the physics server next steps, a
    ray can't find them.
  - The lab's `same_tick` scenario, on all four men: a ball into his thigh hits him standing, and
    hits him fired the tick after he goes limp. Fired on the tick he goes limp, it passes clean
    through.
  - So a blast's gravel and splinters, fired on the tick the blast throws him, never wound the man
    it throws: 4 left toward him at 1 m and none hit.
  - So does every pellet of a charge after the one that knocks him down (`shotgun_05m_belly`: one
    pellet dropped him, 6 hit where 8.9 are expected).
- **The rancher's hat sits on his skull.** Its crown clears his head capsule by 1 cm, so a ball
  through the crown wounds him. The drifter's and the outlaw's clear by 2–3 cm.
- **No hat comes off in a blast** that throws a man down (all three hatted men).
- **Stumps aren't capped on any man, the outlaw included.** The opening's insides are what show.
  The studio men's single skin piece per part leaves a rim one to two forearm-rounds long (28–53 cm).
  On the sheets the cut ends read as wounds: a red cup with the bone's end in it, on the stump and
  on the limb.
- **One limb off and every joint cracks open** (all men; worst on the studio men, whose clothes are
  their skin):
  - `sever_limb` → `_stop_skinning_across_joints` swaps *every* piece to its rigid mesh, not only
    the lost limb's.
  - As the ragdoll's joints bend, the seams open at the neck, shoulders and waist.
  - The sheets (`check stumps`) show it on the drifter, the rancher and the cowboy: a pointed flap of
    the shoulder standing up by his head, a gap at the neck, and ragged edges round the vest's waist.
- **`bold_cowboy_s0` has no hat** (his model doesn't carry one), so there's no hat check for him.
- Otherwise everything works on all three: wounds open and show on their one skin piece, the inside
  is built, limbs come off and fly, the skin follows the bones, and the hats are shot off and fall.

## The first fix (not made)

**A ball that arrives on the tick a man goes limp should still hit him.** This is the bug above. It
is a correctness fault, not a tuning one: it silently drops a blast's fragments and a charge's
later pellets.

The likely smallest fix:
- in `Ballistics._physics_step`, hold back a projectile for a tick when a man it could reach went
  limp this tick; or
- have `go_limp()` keep the standing parts' shapes in the space until the rigid ones are in.

Measure it against this baseline with `dynamite_1m` (gravel wounds should appear) and the 5 m
shotgun charges (pellets hit against the aim's expected count).

HumanBody is the falls session's right now, which is why this lab only reports it.

After that, the medicine's first gap: let packing stop an artery some of the time (1 above). It is
one tuning change in `Physiology` and is measured by the vessel table.

## Sources

Figures are paraphrased; none of their text is copied. Some could only be checked through
abstracts and secondary sources (marked). Read the originals before building a hard test on any.

1. American College of Surgeons, *ATLS Student Course Manual*, 10th ed., 2018: blood volume
   ~70 ml/kg; haemorrhage classes I <15%, II 15–30%, III 30–40%, IV >40%. Seen through StatPearls
   (NCBI Bookshelf NBK535393).
2. Kragh JF et al., "Survival with emergency tourniquet use to stop bleeding in major limb trauma",
   *Annals of Surgery* 2009;249(1):1–7: 90% survival with a tourniquet on before shock, 10% after.
   Kragh JF et al., "Practical use of emergency tourniquets to stop bleeding in major limb trauma",
   *J Trauma* 2008;64(2 Suppl):S38–49. Volunteer ultrasound studies (*Prehospital and Disaster
   Medicine*) find flow past a tourniquet even once the pulse is gone (secondary).
3. Femoral artery resting flow ~300 ml/min (a small duplex ultrasound series, Saarland University
   thesis; weak). No peer-reviewed bleed-out time: the "under 3–5 minutes" figure is folklore, and
   one modelled table (US patent application 20100234877) puts 3 L from the common femoral at ~10 min
   at rest and ~3 min active.
4. Common carotid flow 415 ± 87 ml/min, colour M-mode ultrasound in 174 volunteers, *Radiology*
   1997;205(2), doi:10.1148/radiology.205.2.9356614. Brachial artery resting flow ~65–130 ml/min,
   flow-mediated dilation studies (secondary).
5. Rhee PM et al., "Penetrating cardiac injuries: a population-based study", *J Trauma* 1998: 19%
   of 212 survived; series put 80–90% dead before treatment.
6. Pana R et al., scoping review of time to unconsciousness after circulatory arrest, *Canadian
   Journal of Neurological Sciences*, doi:10.1017/cjn.2015.154: 4–21 s. Rossen R, Kabat H,
   Anderson JP, "Acute arrest of cerebral circulation in man", *Archives of Neurology and
   Psychiatry* 1943: ~6–7 s.
7. Parmley LF et al., "Nonpenetrating traumatic injury of the aorta", *Circulation*
   1958;17:1086–1101, doi:10.1161/01.cir.17.6.1086: ~85% die at once.
8. *The Medical and Surgical History of the War of the Rebellion* (1870–88): 3,717 penetrating
   abdominal wounds, 444 recovered (~88% fatal); case records show deaths from peritonitis at ~5–9
   days (secondary, through 19th-century reviews and transcriptions).
9. Lieurance R, Benjamin JB, Rappaport WD, "Blood loss and transfusion in patients with isolated
   femur fractures", *J Orthop Trauma* 1992;6(2):175–9: mean ~1.2–1.3 L.
10. Shao YC et al., "Radial nerve palsy associated with fractures of the shaft of the humerus",
    *J Bone Joint Surg Br* 2005;87(12):1647–52: 11.8% of 4,517. A 2020 review in *Archives of
    Orthopaedic and Trauma Surgery*, doi:10.1007/s00402-020-03446-y: ~10%.
11. Glasstone S, Dolan PJ, *The Effects of Nuclear Weapons*, 1977: eardrum rupture from ~35 kPa,
    half at ~100 kPa; lung injury from ~100 kPa for a long wave. Bowen IG, Fletcher ER, Richmond DR,
    "Estimate of man's tolerance to the direct effects of air blast", DASA-2113, 1968: lethality
    depends on the wave's duration as well as its peak, so short waves need far higher peaks.
12. Hull JB, Cooper GJ, "Pattern and mechanism of traumatic amputation by explosive blast",
    *J Trauma* 1996;40(3 Suppl):S198–205: the shock wave fractures the shaft and the blast wind
    takes the limb; through-joint rare. Hull JB, "Traumatic amputation by explosive blast: pattern
    of injury in survivors", *Br J Surg* 1992;79(12):1303–6, doi:10.1002/bjs.1800791220. The 22%
    through-joint in fatalities is from later post-mortem CT (secondary).
13. Kheirabadi BS et al., swine 6 mm femoral arteriotomy, haemostatic gauze with 3 min compression,
    *J Trauma* 2011 (details unverified): bleeding stopped in about a third; another study in the
    same model, 5 of 7 survived. Groups of 5–8 animals.
14. Penetrating chest wounds: a chest drain alone treats ~69–90% across series (secondary).
    Leigh-Smith S, Harris T, "Tension pneumothorax — time for a re-think?", *Emerg Med J*
    2005;22(1):8–16, doi:10.1136/emj.2003.010421.
