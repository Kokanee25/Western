# 2026-10-28: bodies that keep moving (issue #446)

Sean, 2026-10-28: "what i really want is bodies reacting to the environment around them, falling
into chairs, over rails, through bannisters and stuff like that - I believe if a guy is running and
gets killed his body keeps moving so we need to find a way to get that more often". No bigger
impulses: he keeps what he had. Judged by how far he travels and what he falls into, not how he
folds. The review page with the films (not in git): https://claude.ai/artifact/7SiaxZJMD2FNrPj9Zrck6Y

Runs are in `build/` of the session's worktree (not in git): `build/gf/base`, `build/gf/on`
(fights), `build/physics_lab/x_off`, `x_on` (headless), `xr_off`, `xr_on` (drawn).

## Step 1: how often it happens in a fight (`falls_base_vs_on.md`)

The gunfight lab logs every man down (`gf_fight ... falls=1`, `fall_log.gd`; `falls.py ROOT...`):
his speed and heading as he goes limp (his centre of mass), what a sphere cast along that meets
within 2 m (knee, hip, chest height), his travel once limp (level, his centre of mass, to rest or
4 s), what his parts touched (contacts) and what broke within 0.8 m of him while he fell.

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall,spec_stair,spec_gallery,spec_back,spec_front \
    --hours=golden --weapons=revolver --styles=careful --bodies=studio --variant=D \
    --fixes=all+pain_fight+floor_fight+odds+flinch --seeds=1-10 --jobs=4 --falls=1 [--momentum=on] --out=build/gf/<run>
python3 experiments/gunfight_lab/falls.py build/gf/base build/gf/on --each
```

D+ (the trial's fixes), the careful player, the five saloon setups, seeds 1-10: 50 fights.

| | before | keep_stride on |
|---|---|---|
| men down | 47 | 50 |
| moving (>= 0.8 m/s) as he went limp | 9 | 10 |
| of them stumbling (a ball on the move) | 6 | 6 |
| speed of the movers (median) | 1.4 m/s | 1.67 |
| something solid within 2 m ahead | 5 | 5 |
| travel once limp (median, all) | 0.53 m | 0.52 |
| travel (median, movers) | 1.08 m | 1.06 |
| travel max | 1.40 m | 1.57 |
| hit something not the floor at >= 0.5 m/s | 25 | 28 |
| broke something | 0 | 0 |

**The headline: four men in five go down standing.** The gang is moving in 30% of the half-second
samples of the fights (6% faster than 2.5 m/s), but only 19% of the falls are on the move and none
at a run before the switch (the stumble braked the runners to ~2.1 m/s). What they hit is mostly
the wall or the bar they stood at (cover). Nothing broke in 97 falls: nobody fell into anything
with speed.

## Step 2: keep the speed (`HumanBody.keep_stride`, off)

- The stumble keeps his speed (it braked him to 0.6 of it over the step).
- Each stumbling tick, two spheres (0.2 m, at 0.6 and 1.0 m over his feet: a chair's seat or a
  table top; a rail, a banister, a chair's back; not low steps or the floor) are cast along his
  heading a step at his speed (0.25 s, 0.35-0.9 m) past his walking sphere, on `Layers.WORLD`
  (not men, not the walkers' ramps). Meeting anything, he goes limp then and there (`_fall_now`),
  so the ragdoll takes his full speed into it rather than `_slide` steering him along it.
- Nothing's added to him. `run.py --momentum=on` (gunfight lab), `--momentum=on` (ragdoll lab).

In the fights it changes little, because it only acts on the stumbles (6 of ~50): those now go limp
at 3.5-3.8 m/s rather than ~2.1, and travel up to 1.57 m. The rest is step 4.

## Step 3: group X at fight speeds (`x_tone.txt`, `x_tally.txt`)

16 scenarios (`scenarios.json`, group X): walking (1.4) and running (3.5) at a kit chair (its back to
him), the kit's card table, a thin plank wall of the game's members (`lab_plank_wall.gd`: 1 in boards
on 2x4 studs 0.6 apart), the breakable railing over 2.47 m (`rail_break`), and running down the
game's saloon stair and angled into its banister; shot in the back (and from the side running), as
the game's ball that drops him (`_knocked`). The Studio cowboy (`bold_cowboy_s3_talking`).

```sh
python3 experiments/physics_lab/run.py --scenario=group:X --model=bold_cowboy_s3_talking --momentum=on --out=...
python3 experiments/physics_lab/tone.py build/physics_lab/x_off build/physics_lab/x_on --each
```

| run, shot in the back | before: speed, travel, broke | on |
|---|---|---|
| into the chair | 1.99 m/s, 1.42 m, the chair loose | 3.27, 1.39, the chair loose |
| into the card table | 0.06, 0.59, nothing (the walk stopped him at it) | 3.27, 1.26, the table loose |
| into the railing | 0.85, 0.84, a baluster; on the deck | 3.30, 2.50, cap + 5 balusters; over, 2.3 m down |
| angled into the stair's banister | 2.18, 0.92, nothing | 2.67, 1.55, 8 balusters |
| down the stair | 1.70, 1.40, nothing | 2.99, 2.05, nothing |
| into the plank wall | 1.98, 0.77, nothing | 3.27, 0.83, 2 boards (not through) |

All 16: travel 0.84 -> **1.42 m** (mean), falls that broke something 7 -> **13**. All three railing
falls go over with it on (none before). The wall cracks but holds: one running man's ~430 J doesn't
burst 1 in boards between studs (Sean's wall in the game had more in it; not chased).

**Flags 94 -> 393**, nearly all `joint_pulled_apart` (46 -> 284: joints parting 3-6 cm for a few
ticks as he strikes at 3.3 m/s; the worst gap 0.13 -> 0.17 m, down the stair) and
`swing_past_limit` (20 -> 58). Harder impacts, not new faults; to be judged by eye on the films.
Frame: the lab's collapse 11.2 -> 12.0 ms headless here (the harder falls' contacts); the probe is
two shape casts a tick while a man stumbles.

## Step 4 (proposed, not built): more men dying on the move

From step 1: they're moving 30% of the time but 19% of the falls, never at a run, because the
careful player (and the bot's settle before each shot) hits still men. A human leads a runner
less well still. What would put more deaths on the move, in the gang's brain (`OutlawBrain`):

1. **Cover runs at a run, across the open.** `MOVING` samples are 84% moving; a dash between cover
   past the player's line is when he's hit running. A cover search that accepts a shorter route
   across open ground when the player is reloading or pinned (how the routes go today: to measure).
2. **Charging on a reload** (`press`, D's fixes) at `run_speed` (3.8), straight at the player
   through the tables.
3. **Backing off while shooting** (the hurt man's retreat) at a walk, facing the player, toward
   cover behind him: shot then, he falls back into a chair or over a rail.
4. The scripted player: a moving target already slows his aim (lag 0.08 s, settle 0.2-0.6 s); a
   `snap` style that fires at movers would show what Sean's own play gives.

Measure each by `falls.py`: share of falls moving, at a run, into something, and broke something.
