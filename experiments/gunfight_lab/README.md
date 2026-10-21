# The gunfight lab

Roadmap 3.0's arena (`docs/briefs/labs.md` "Gunfight lab", `docs/briefs/three-gunmen.md`): you
against Brody, Lyle and the Kid on the existing street, fought hundreds of times headless with a
scripted player, with numbers that tell a dead fight from a tense one. Built on the ragdoll lab's
pattern (`experiments/physics_lab/`). **It changes nothing about how the game plays and claims no
improvement:** the men are the game's (`TownLife.GANG`'s tempers, nerve and pride; `OutlawBrain`,
`Senses`, `Cover`, untouched), the guns are yours as the keys work them. Only where everyone
stands, which bodies the three wear, the hour and the lamps are the lab's.

Everything is in this folder. Outputs go under `build/gunfight_lab/` (git-ignored). The baseline's
numbers and its contact sheet are in `baseline/`.

## Commands

```sh
# the baseline matrix: 3 arenas x golden/night x revolver/shotgun x 3 styles x seeds, one game each
python3 experiments/gunfight_lab/run.py --out=build/gunfight_lab/base --bodies=studio --seeds=1-10
python3 experiments/gunfight_lab/run.py --out=build/gunfight_lab/base --bodies=outlaw --seeds=1-5
python3 experiments/gunfight_lab/analyse.py build/gunfight_lab/base      # baseline.md, baseline.json, fights.csv
# a narrower set (any of --scenarios --hours --weapons --styles --bodies --seeds=1-4,7)
python3 experiments/gunfight_lab/run.py --scenarios=street --styles=cover --seeds=1-20 --out=build/gunfight_lab/try
python3 experiments/gunfight_lab/run.py --list ...                         # what it would run
# one fight, drawn, with a pair of frames every 1.5 s (overview + your eyes) for the contact sheet
xvfb-run -a -s "-screen 0 960x540x24" godot --path . --rendering-driver vulkan --resolution 960x540 --fixed-fps 60 \
    -- --dev-bridge --bridge-script=FILE   # FILE: "gf_fight street seed=2 style=cover out=/abs/f.json shots=/abs/shots every=1.5" and "quit"
python3 experiments/gunfight_lab/sheet.py /abs/f.json /abs/shots --out=sheet.png
```

The bridge commands (`bridge.gd`, `python3 tools/bridge.py help` lists them with the game running):

- `gf_fight SCENARIO [hour=golden|night|H] [weapon=revolver|shotgun] [style=hold|cover|push]
  [bodies=studio|outlaw] [seed=N] [max=S] [out=FILE.json] [shots=DIR every=S]`: one fight to its
  end; answers the headline, writes the whole record to `out`.
- `gf_cover X Y Z [EYE_X EYE_Y EYE_Z]`: is there cover within 1.5 m of a spot from that eye, by
  the gang's own test (`Cover.evaluate`). How the ambushers' spots were placed.
- `gf_coverwhy X Y Z EYE_X EYE_Y EYE_Z [TRAVEL] [levels]`: the gang's cover search from a spot:
  every candidate and why it was turned down, what the search picks and what it cost.
- `gf_map [X Z R]`: what stands round the arena (props, troughs, lamps, places).

`run.py` starts one game per fight with `gf_fight` as its `--bridge-script`, so a fight starts on
the same frame every time; `--jobs=N` games at once (the cores by default); a fight already
recorded is kept, so a run resumes. The 540-fight baseline took ~45 minutes on this workspace's 4
cores. A drawn fight (lavapipe) is drawn only round each capture
(`RenderingServer.render_loop_enabled` off between), ~8 minutes for a 7.5 s fight with a pair of
frames a second; `run.py --sheet=NAME` does it and makes the sheet.

## The arenas (`scenarios.json`)

| Scenario | Set-up | Start |
|---|---|---|
| `street` | You at the trough's street side (3.6, -5.2); Brody on the saloon porch at the door, Lyle by the porch's crates and barrel, the Kid on the street below the porch steps; 7–10 m apart, a tied horse between | A standoff: everyone in plain sight; the gang turns on you (the bridge's `fight`: `relations.provoke`) and you know where all three are |
| `saloon` | Every saloon lamp lit; you just in at the door; Brody at the bar, Lyle at the card table, the Kid at the back; 4–8 m | Standoff, as the street |
| `ambush` | You walk east down the street from (-2, -7.8), gun away; the Kid flat behind the trough, Lyle behind the porch rail's west end, Brody behind the tied horse, each in the spot `Cover.evaluate` finds from where you start, already turned | They open fire when it starts; you know nothing till a shot, a near miss or a man you pick out |

Each at **golden hour** (17.4; the clock runs as in the game, so a 90 s fight ends near 18.2,
when the lamps light) and **night** (22.0), with the **revolver** and the **shotgun**.

The clock isn't stopped: bodies bleed on the day clock's time (`physiology.step(delta *
time_scale)` in `PlayerWounds` and `HumanBody`), so a stopped clock stops every wound.

**Bodies:** `bodies=studio` dresses the three in the character studio's men from
`assets/people/` (Brody `bold_cowboy_s0`, Lyle `old_rancher_s1`, the Kid `young_drifter_s1`),
set on each `HumanBody.body_model` by the lab; the game's own gang (`TownLife.GANG`) isn't
touched (its models change in roadmap 2.1). `bodies=outlaw` is the gang as the game had it before the Studio's men
(Brody and Lyle the MakeHuman `outlaw`, the Kid `kid`), so earlier results still compare.
`bodies=game` follows whatever `TownLife.GANG` wears now (since #160/#162 Brody `bold_cowboy_s0`,
Lyle `hothead_lyle_s1`, the Kid `young_drifter_s1`); it isn't in the baseline.

**Seeds:** seed N gives the men `rng_seed` 200 + i + 10N (their aim, thinking and range
judgement), the scripted player his own, and Godot's global `seed()`. The same build gives the
same fight: the same seed in two processes, or headless and drawn, gave the same record event for
event (perf aside). Across machines or Godot builds, compare within a tolerance.

## The scripted player (`player_bot.gd`)

Plays you through the keys as the dev bridge does (aim, cock, fire, reload, crouch, move), so the
gun's own sway, kick and ball along the barrel decide where his shots go.

- **Eyes and ears: the gang's rules.** `Senses`' range by daylight (60 m day, 14 m at night),
  sharp ahead and dim to the side, nothing behind, a clear line to head, chest or pelvis,
  awareness built over a moment, a crouched or still man harder to pick out. He hears their shots
  roughly where they came from (10% of the range off, as `Senses.note`). Neither side sees by
  lamplight: `Senses` takes only the day's light.
- **His hand.** 0.25–0.45 s to take in that it's started; turns onto a man with a lag (0.08 s)
  and an error that settles (2.5° sd at first, gone in ~0.35 s); a per-shot aim error of 0.7° sd
  (0.5° up and down), drawn again each shot (where he thinks the man is); 0.2–0.6 s settled before
  each shot; cocks after each shot; reloads when empty (and when nobody's in sight with rounds
  spent, but not pushing); fires only at a man he can see and who's still in it (not one who's
  given up or is down).
- **Styles.** `hold`: stays on his spot, crouched, up to shoot when he can't see over it, up to
  look every 2.5–4.5 s when nobody's in sight. `cover`: as hold, and after 2–3 shots, a hit, three
  near misses in 4 s, a man with a line to him crouched for 1.5 s, or 12 s with nobody in sight,
  runs for the next spot (`Cover.find`, the gang's own finder, against where he last knew the
  nearest man) and shoots from its peek. `push`: walks at the nearest man he knows of, shooting as
  he goes, stops 4 m off, reloads where he stands.
- **In the ambush** he walks east, gun away, until a shot, a near miss, a hit or a man picked
  out; then he draws (about a second) and plays his style.

He's a fair, decent shot, not a test of the gang's limits: his hit rate is in the tables, to set
against Sean's.

## What's measured (each fight's record: `fights/<name>.json`)

The fight starts when the gang turns. It ends when you're out (unconscious or dead), when all
three are out of it (dead, down, given up, fled 4 s or 25 m, or calm again having lost you 3 s),
after 45 s with no shot from anyone (a lull), or at 180 s.

- **Fight length**; **who shot and who hit first** and when; **hits per side** (a shotgun charge
  counts once; pellets apart); **time before you're first hit**; **near misses a minute** on you
  (the game's `near_miss`: a ball passing within its radius); **longest quiet stretch** (the
  longest gap between shots, from the start to the end).
- **Per man:** shots, hits on you, hits taken, **cover changes** (his tactic into MOVING), peeks,
  **flanks** (his `flank` callout: a flanker calls it as he goes), **suppressing shots** (fired
  while covering a friend or without seeing you), times **pinned** (heads down from a near miss),
  reloads, every mood change, and how he ended; and since fix 1, each shot's error
  (`shot_errors`: time, how far his barrel was off where he meant in degrees, range, at your
  head, his fear); and since fix 2, why he was in the open (`open_searching`, `open_waiting`,
  `searches_empty`).
- **Situation changes:** **cover shot away** (a member broken within 2.5 m of a hidden man's
  spot, or of yours; once a second), **lamps hit** (an `OilLamp` broken), **fires started**,
  **dust on a line** (a ball into the ground within 1 m of your line of sight to a man still in
  it), **surrenders**, **flights**, hats shot, townsfolk hit.
- **What the three men cost a frame:** Prof's people timers (people_body, people_skeleton,
  senses, outlaw/civilian brains, player, town_life, blood) a frame through the fight, against the
  second before the gang came (you, the barkeep and the storekeeper); and the whole physics frame
  (headless, so no drawing). This workspace's core; x0.65 for Sean's (CLAUDE.md).
- A **timeline** (shots, hits, near misses, words, callouts, moods, cover runs, situations) and a
  **track** (everyone's place, tactic, mood and pose every 0.5 s), for the contact sheet's strip.

`analyse.py` pools them (several runs at once, `--where=scenario=street` to keep some): by bodies, by arena x hour x gun, by style, by arena x style, each man,
the situation changes, the frame, and the first half of the seeds against the second.

## Baseline (2026-10-21, source 4db0224)

Measured on 4db0224; after merging main (8a92fec: the Studio's men cast in town, no drawn
fingers on a whole man) eight of its fights, both bodies and every arena, replayed identically.

540 fights: the 36 setups x 10 seeds on the studio men, x 5 on the old bodies. Everything is in
`baseline/`: `baseline.md` (every table: by bodies, by arena x hour x gun, by style, by arena x
style, each man, situation changes, the frame, steadiness, diagnostics), `baseline.json`,
`fights.csv` (one row a fight), `manifest.json`, the contact sheet of a typical fight, the line-up
of the five bodies and the body check (`bodies.json`). `analyse.py experiments/gunfight_lab/baseline
NEW_ROOT` isn't a diff tool yet: run `analyse.py` on the new root and set the tables side by side.

### The table (studio men; the three styles pooled, 30 fights a row)

| arena | hour | gun | length s, median | in 45–90 s | gang hit first | you first hit at, s (never hit) | hits you / gang | near misses a min | longest quiet s | you down |
|---|---|---|---|---|---|---|---|---|---|---|
| street | golden | revolver | 7.3 | 7% | 43% | 0.9 (37%) | 1.9 / 0.9 | 27 | 2.3 | 13% |
| street | golden | shotgun | 9.8 | 3% | 50% | 1.0 (30%) | 1.7 / 1.2 | 21 | 4.0 | 23% |
| street | night | revolver | 9.6 | 10% | 10% | 2.4 (80%) | 2.2 / 0.2 | 25 | 3.7 | 7% |
| street | night | shotgun | 8.5 | 0% | 20% | 3.4 (60%) | 2.0 / 1.0 | 19 | 2.8 | 17% |
| saloon | golden | revolver | 2.0 | 0% | 100% | 0.7 (0%) | 1.1 / 3.2 | 97 | 0.9 | 70% |
| saloon | golden | shotgun | 1.9 | 0% | 100% | 0.7 (0%) | 1.1 / 3.1 | 100 | 0.8 | 50% |
| saloon | night | revolver | 2.4 | 0% | 100% | 0.7 (0%) | 1.2 / 2.5 | 69 | 1.0 | 70% |
| saloon | night | shotgun | 2.2 | 0% | 100% | 0.7 (0%) | 1.2 / 2.3 | 71 | 1.1 | 50% |
| ambush | golden | revolver | 11.7 | 0% | 40% | 2.6 (7%) | 1.9 / 1.8 | 24 | 4.7 | 53% |
| ambush | golden | shotgun | 13.6 | 3% | 50% | 2.6 (20%) | 1.7 / 1.9 | 26 | 5.8 | 50% |
| ambush | night | revolver | 4.5 | 0% | 97% | 2.5 (3%) | 0.6 / 2.4 | 43 | 2.5 | 93% |
| ambush | night | shotgun | 4.4 | 0% | 97% | 2.6 (0%) | 0.3 / 2.5 | 40 | 2.5 | 97% |

All 360: **median 5.1 s, 2% in 45–90 s, 83% under 15 s.** The gang hits first in 67%; you're
first hit at 0.9 s (median; never in 20%). How they end: you down 49%, the last man gives up 25%,
goes down wounded 11%, runs 10%, they lose you 4%, dead under 1%. The three styles end alike
(medians 4.6–5.6 s); the per-man, per-style and situation tables are in `baseline/baseline.md`.

Per man and fight (studio): shots 1.2–2.1, cover changes 0.3–0.8, peeks 0.3–1.2, suppressing
shots 0.5–1.1, pinned ~1, flanks ~0 (6 flank callouts in 360 fights). Situation changes a fight:
cover shot away 0.00–0.13, a lamp hit 0.13 (saloon only), fires 0, dust thrown across your sight
of a man 6.7 in the street (0.7–0.8 elsewhere; it hides nobody), dust round a man 0.6, surrenders
1–2, flights 0.1–0.6, a seated townsman hit 0.7 in the street (the bench man and the porch
loafer in the line of fire).

**What the three men cost a frame:** 1.36 ms headless here for the studio men, 1.37 for the old
bodies (people timers in the fight 3.8 ms against 2.4 the second before they came) = **~0.9 ms
on Sean's core**, inside the people budget (4.0 ms). People p95 6.4 ms here (a man going limp, a
cover search). The whole physics frame 6.9 ms here (~4.5 at Sean's). Drawing isn't measured.

**Steadiness:** a seed gives the same fight every time. The street, the main arena, run with 20
seeds more (`baseline/street_extra.md`): across three blocks of ten seeds each arena x hour x gun
row (30 fights) keeps its median length within 1–2 s and its rates within about 10 points, so
the 30-fight rows above are steady enough to measure a fix against; a single setup (10 fights)
is only an indication. All 360 street fights: median 8.5 s, the gang hits first in 27%, you go
down in 16%, 4% in 45–90 s.

**Sensitivity to the scripted player:** with his per-shot aim error at 0.7° (an earlier run of
the same matrix) he hit 81% of his shots against 76% at 1.0°, and the medians didn't move (5.1 s
both): at 2–10 m the opening decides the fight, not his aim.

### The contact sheet of a typical fight

`baseline/sheet_street_golden_revolver_hold_studio_s8.jpg`: the street at golden hour, revolver,
holding the trough, seed 8; 7.5 s, the street-golden-revolver median (7.3). A frame a second
(the overview, men labelled, above; your eyes below), and the strip of the whole fight above them.
Lyle fires first (0.85 s, dust kicked up short of you), Brody puts a ball through your left
forearm at 1.0 s; your first shot (1.6 s) takes Brody in the chest and he goes down and gives up;
your second hits Lyle's arm (2.5 s); after your third the Kid calls "fall back" (3.4 s) and he
and Lyle run; at 7.5 s it's over. Five times the dust of a ball crosses your sight of a man. The
tied horse stands between you and the porch.

### The five biggest reasons fights aren't 45–90 tense seconds

1. **The first hit decides it, and it's theirs.** The gang's first shot comes 0.85 s after they
   turn and hits you in 56% of fights; you go down in 68% of the fights where they hit first and
   11% where you do (in the street 38% against 8%, the ambush 92% against 29%; in the saloon they
   hit first every time). `OutlawBrain` fires 0.6–1.1 s after the fight starts (`_start_fight`'s
   `_next_shot`) through a 2.4° random cone (`spread_degrees`): nothing about drawing, turning
   or a gun settling, and at the arena's 2–10 m a 2.4° cone covers a chest. In the saloon you're
   hit at 0.7 s in every fight.
2. **A man quits on the first hit, or none.** Of 550 quits by the studio men, 152 came with no
   hit at all and 153 after one; fear per hit (0.25, +0.14 severe) against nerve (the Kid 0.3,
   Lyle 0.7, Brody 0.95), and a friend's fall or surrender frightens the rest
   (`FEAR_MATE_OUT`), so one breaks and the others follow. Brody, the cool one, gives up in 47%
   of fights. A man dead is under 1% of endings.
3. **One hit takes your gun.** In 21% of fights a ball in your right arm puts the revolver away
   (median 2.2 s in): `arm_disabled`, with no left-hand shooting, and the coach gun needs both
   arms. From then on you can't shoot back.
4. **They fight standing in the open.** While fighting, the men spend 45% of their time OPEN,
   16% hidden, 11% peeking, 4% moving: they shoot from where they stand while the cover search
   runs (`_combat`'s OPEN case fights), and change cover 0.3–0.8 times a fight. There's no
   back-and-forth from cover to make the fight last.
5. **Nothing changes the situation and there are no lulls.** Flanking waits for 10–18 s in cover
   or four peeks (`_flank_after`), so it almost never happens (6 flank callouts in 360 fights); cover is
   almost never shot away (0.00 a fight in the street); no fires; a lamp only in the saloon
   (0.13); dust crosses your sight 6.7 times a street fight but hides nobody (neither `Senses` nor
   your eyes look for it). The longest quiet stretch is 2 s (median); 19% of fights have a 5 s
   lull. Night barely changes the street (both sides see 14 m and the arena is inside it; lamps
   don't count for sight); the night ambush is you down in ~4.5 s in 93–97%.

### What doesn't work on the new men

From the body check (`gf_bodies`, `baseline/bodies.json`), the line-up (`gf_lineup`,
`baseline/lineup.jpg`: top guns up, bottom holstered; left to right `hothead_lyle_s1` (the
game's Lyle since #162), the old Kid and outlaw, then `young_drifter_s1`, `old_rancher_s1`,
`bold_cowboy_s0`) and the fights:

- **No gun belt or holster.** A whole man wears nothing of BodyMesh's (`PeopleBodies`), belts
  included, so the holstered revolver hangs at his right hip in the air; `hothead_lyle_s1` too.
  (The old outlaw and the Kid have theirs.)
- Their open hands: a second, drawn hand on theirs was fixed on main while this ran (#162); the
  line-up is drawn on the merged build.
- **What you see of them isn't all hittable.** The hitboxes are the anatomy's capsules, the same
  for every man; the new men's clothes are one skin round them. More than 3 cm outside every
  hitbox: `old_rancher_s1` 35% of his surface (3.6% more than 8 cm: coat and sleeves),
  `bold_cowboy_s0` 20%, `hothead_lyle_s1` 18%, `young_drifter_s1` 14%, against 2.6% on the old
  outlaw (the old Kid is 26% too). A ball through the rancher's flapping coat touches nothing.
- **Brody (`bold_cowboy_s0`) has no hat**, so no hat to shoot off his head (a hat shot is one of
  the situation changes). The other two have hats with hitboxes, and they come off.
- Otherwise the fights don't tell them apart: lengths, hits, endings and the frame cost (1.36
  against 1.37 ms) are within the seeds' noise. Their guns come up and point right (line-up).

### The first fix I'd make (not made)

**The gang's aim from the gun's state, starting with the draw and the first shot** (the brief's
gap 2): replace `spread_degrees`' random cone with the player's own sway model (the gun comes up
and has to settle after drawing, turning or moving; breathing, fear, pain and being shot at
shake it), so a man's first shot comes later and less sure. It goes at reason 1, which decides
two fights in three. Measured against this baseline: the gang's first-shot hit rate (56%), your
first hit (0.9 s), how often you go down when they hit first (68%), and fight length. It won't
make 45–90 s alone (reasons 2, 4 and 5 stay), but it gives you the moment to react that both
playtests asked for.

## Fixes measured against it

Each in `results/<date>_<name>/` (a README, `compare.md` from `analyse.py NEW --vs=BASE_ROOT
--where=bodies=studio`, and the new run's tables). The baseline above stays as it was.

- `2026-10-21_gun_hand/`: the gang's aim from the gun's state (`GunHand`, the player's `Sway`)
  and a moment to react. Their first shot 0.85 → 2.1 s and hitting first 67% → 33%, but fights
  5.1 → 6.5 s: the opening now goes to whoever's gun is up, and reasons 2, 4 and 5 stand.
- `2026-10-21_cover/`: cover first, by finding the cover that's there (spots up or down a step,
  the town's ways in at doors and round the bar, wide cover a few metres off). Their time in the
  open 42% → 22%, cover changes 0.42 → 0.97 a man, the street 7.1 → 12.7 s, fights 6.5 → 8.5 s;
  now men quitting on 0–1 hits ends most fights.

## Limitations

- Headless numbers aren't play: the brief's measure is Sean playing three fights and saying which
  was best. The numbers only catch dead fights.
- The scripted player is one model of a player; his hit rate and reaction are in the tables. His
  eyes are the gang's (no lamplight, no muzzle flash, no smoke or dust blocking sight: neither side
  has those today).
- "Dust on a line" counts dust thrown up across your sight of a man; it hides nobody today
  (`Senses` and the bot's eyes don't look for it). It measures how often it could.
- Hits on you come from `bullet_hit` (`PlayerWounds` doesn't name the shooter in `body_hit`).
- Frame times are headless (no drawing, no skinning on the GPU); render cost isn't measured.
