# More cores, step 4b: people ticked by distance (2026-10-26)

`docs/briefs/more-cores.md` "Step 4b" (issue #396). This workspace's VM (4 vCPUs; x0.65 for Sean's
core, as the brief scales), headless, `--fixed-fps 60`, one game at a time, nothing else running
for the timed runs. Every lab run is the lab's ten D fights:

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall --hours=golden --weapons=revolver \
    --styles=careful --bodies=studio --variant=D --seeds=1-10 --jobs=1 --out=build/gf/<run>
python3 experiments/gunfight_lab/same_fight.py build/gf/<a> build/gf/<b>
python3 experiments/gunfight_lab/results/2026-10-26_step4b/perf.py name=build/gf/<run> ...
python3 experiments/gunfight_lab/results/2026-10-26_step4b/normalise.py runs before_1 before_2 b4b_3 b4b_4
```

**before** is step 4's head (`claude/gameplay-perf-step4` at 318ba6b, what #409 merged), from its
own worktree; **b4b** this branch. Timed runs alternated (before_1, b4b_3, before_2, b4b_4).
`b4b_2` is the same build's first quiet run (the determinism pair), not timed. `runs/<name>/` has
every fight.

## What it is

**The bands** (`PeopleTick._bands`, `config/people_tick.tres`). Each tick, every man's distance to
the player and to everyone `in_trouble` (a fight, running, tending, hands up, getting down: the
brains say) puts him in a band: near (every tick), middle past 25 m (every 2nd), far past 60 m
(every 4th). He leaves a band only 3 m past its edge and comes back only 3 m inside it
(`tick_band`). His ticks are staggered by his index, so a band's men don't all tick on one tick in
four. In the camera's view he's one band nearer; within 8 deg of its middle (where the gun points)
he ticks every tick at any distance. The band is game state only: distances, the camera, the
tick count. No frame time.

**Skipped, he's skipped whole:** not in phase 1 (`begin_prepare`), not in phase 2 (`prepare`), no
tick of his own or his nodes'. He's owed the time (`tick_owed`), and his next tick's delta
(`tick_dt`) is the tick's own plus what he's owed: his physiology, stains, signs, pose, brain and
face all step with it, as each already took a delta.

**Never slowed** (`HumanBody.can_slow`): down (the ragdoll), prone, getting up, stumbling,
dragged, on a clip other than his own walk, or any of his nodes saying no (`can_slow`: an
`OutlawBrain` not calm, with a target, rescuing, breaking, fleeing a fire, or wary of anyone; a
`CivilianBrain` not calm, frightened, aimed at, getting down, running from a fire, in a bucket
line, or at a chore that has his hands, the bar cloth or the mop). **Woken** (`wake()`: a noise he
heard, a deed done to him) he ticks the next tick whatever his band. No player in the world (the
physics and body labs, most tests) or `Settings.people_bands` off (`-- --people-bands=off`):
everyone, every tick, as step 4.

**Two places that took a delta but not a long one:**
- **Walking.** `walk_to` steps `speed x delta` but arrives within 0.1 m, so a four-tick step went
  all the way to the point and lost what was left of the tick at every point on his road: a far
  gang reached the bar 13 frames late in 33 s. Now a slowed step stops where the one-tick steps
  would have put him, and the whole ticks left over are walked towards the next point on his next
  tick (`_walk_spare`; none at one tick a tick, and none once he stops). The gang is 4-6 frames
  behind now (below), the rest of it his decisions coming a quarter as often.
- **Looking.** `Senses` looks round every 0.12 s on its own clock, so ticking him less often didn't
  make him look less often. A far man's look interval is now 0.12 s times his band's (each look
  takes in the time since the last, as before; nearer again, he looks within 0.12 s).

## The gate

- **The lab twice: 10 of 10 the same** (`same_fight_b4b_3_vs_2.txt`, `same_fight_b4b_4_vs_3.txt`).
- **Against step 4, 9 of 10 event for event** (`same_fight_b4b_vs_step4.txt`): seed 5 parts at
  92.8 s of its 111 (74 % in: Brody sees you again 0.13 s sooner, and is down at the end instead of
  standing). The before's re-run is step 4's own record 10 of 10 (`same_fight_before_vs_step4.txt`).
  - The first build (bands, looks on the 0.12 s clock) was step 4's 10 of 10. Seed 5 moved when
    the far men's looks were slowed, through `SightLight`'s cache: one entry per man looked at
    (his light and the range he can be seen at), shared by everyone, renewed when it's asked for
    after 7 frames. Who asks first decides the frame it's renewed on. With the street's townsfolk
    looking a quarter as often, the gunmen renew the player's entry on other frames than before.
  - So this isn't the bands changing what a near man does. Any change to who looks when (4c's
    snapshot, a man added to the street) moves it the same way. A cache that's the same whoever asks
    re-baselines every fight, so it's left for the review to place (4c builds the per-tick sight
    from the snapshot, which is where it belongs).
- **A far man walks at the right speed:** `test_town_day`'s
  `test_far_off_the_gang_comes_in_on_time_with_the_bands`: you 130 m east, looking away; the gang
  in from the west at a brisk walk, a tick in four (6,465 man-ticks in the far band); at the bar at
  frames 2000 / 2075 / 2154 with the bands, 1995 / 2069 / 2150 without (the test allows 6); their
  road within 0.25 m every 2 s. `test_people_tick`: a man walking 12 m 100 m off arrives within 4
  frames and on the same road to 10 cm; six wounded men 100 m off bleed, hurt and breathe the same
  (blood within 1 % of what they lost); the bands, the margin, a man in trouble and his neighbour,
  woken, limp.
- **The physics lab and the body lab** have no player in the world, so the bands are off there by
  the rule above: every man every tick, step 4's code path (a slowed walk's and look's arithmetic
  is only taken when a man is slowed). Not re-run.
- **The suite:** see the PR (`test_perf`'s frame budgets fail in this container on main too).

## The numbers

The lab, D fights in `spec_hall`, means of ten fights (`perf.md`, `normalised.md`; scaled by
`player`, `structures`, `fire`, `horses`, which the step doesn't touch, against the befores' mean):

| | before (2 runs) | b4b (2 runs) | change |
|---|---|---|---|
| frame (scaled) | 24.72 | 20.24 | **-4.5** |
| frame p95 (raw) | 28.0 / 30.4 | 24.2 / 22.5 | -5.9 |
| people (scaled) | 13.06 | 9.12 | **-3.9** |
| people_body + prep (scaled) | 5.60 | 3.39 | -2.2 |
| people_skeleton | 0.90 / 0.95 | 0.45 / 0.42 | -0.5 |
| senses | 1.72 / 1.84 | 0.91 / 0.86 | -0.9 |
| civilian_brain | 0.84 / 0.92 | 0.63 / 0.58 | -0.3 |
| outlaw_brain | 3.06 / 3.30 | 3.04 / 2.88 | ~0 |
| the three gunmen | 4.69 / 4.86 | 5.53 / 5.06 | +0.5 |
| `people_bands` (the pass itself) | - | 0.24 / 0.22 | +0.23 |
| men ticked / owed a frame | 20 / 0 | 9.95 / 10.05 | |

The brief expected no gain in the saloon fight ("everyone is near"). In the lab's street everyone
isn't: the street dressing's eight and the town's townsfolk stand outside, most of them past 25 m
from you in the saloon, and while they're calm (they are, unless shooting's within 25 m of them)
they tick every 2nd or 4th tick: half the people a frame. The three gunmen cost ~0.5 more, most
likely the light cache above: the townsfolk asked for the player's and the gang's entries and
renewed them; now the gunmen do more of it.

`perf_bench`'s calm street with the town doubled (`--folk=2`: the townsfolk again, two streets off,
`tools/folk_copies.gd`): see `bench.md`.

## Not done, and why

- **The light cache made the same whoever asks** (above): a re-baseline of every fight, for the
  review to place (4c).
- **The sight batch (4c, #413)**: its own step, as the review of step 4 placed it.
- **`FaceSpeech`** isn't held at every tick while he talks: a far man talking is out of earshot and
  near enough to see his mouth is near. Anyone you're talking to is near (the talk range is a few
  metres).
- **The cost of a far man that's left:** a quarter of his tick, plus the near men's look loops
  passing over him and the band pass (~10 us a man). That's why `--folk=2` isn't flat (`bench.md`).

## What was read

CLAUDE.md; the brief's "The design" B and F, "The steps" 4 and 4b, "How a step is reviewed"; step
4's PR description and README and the handover on #396; `PeopleTick`, HumanBody's tick and walking,
`Senses`, `SightLight`, `CivilianBrain`'s and `OutlawBrain`'s ticks and moods, `TownLife`,
`perf_bench`, `test_town_day`.
