# The people after a blast (#495)

Sean's F12s of 2026-10-28 (build 2736; on #435 and #487): the people ~8 ms a physics tick after
a stick against ~4 before. The question (#492's round 2): do the distance bands (more-cores step
4b, `PeopleTick`) stop slowing far men once a blast puts everyone in trouble?

## The command

```sh
godot --headless --fixed-fps 60 -s res://tools/people_after_blast.gd -- [--spec] [--before=5] [--after=15] [--out=FILE.json]
python3 experiments/people_after_blast/summary.py FILE.json [more.json]   # before / 0-6 s / 7 s on, side by side
```

The game's street as the game loads it (22 people, the gang in), each second of 60 ticks before
and after the stick(s): men ticked a tick, men in a slowed band, why each unslowed man wasn't
(`PeopleTick`'s `n_full_*` counts while Prof is on: his `HumanBody.slow_reason`, `near_player`,
`near_trouble`, `woken`, `seen`/`aimed`), the people's timers, and each man's tick by his state
(`PeopleTick.time_by_why`, the lab's switch). Street: perf_bench's two sticks (store, saloon), the
player in the street. `--spec`: the spec saloon in the desert, the player in its hall, a stick 7 m
off (the blast-freeze lab's spot), the townsfolk ~100 m and more away.

## Results (`results/2026-11-01/`, `summary.txt`; ms a tick here, x0.65 for Sean's)

**What it was:** a townsman who hears a blast within 60 m cowers for 7 s (`CivilianBrain`
`_scared_by_shooting`), then stands shaken and frightened for ~8 s more. `can_slow` was false
for all of it (not CALM, `_cower`, `fear` > 0.05) and `in_trouble` true while he cowered, so
neither he nor anyone within 25 m of him was slowed, however far from you and from any fight.

**The change:** a man cowering or shaken where he stands can slow (the bands then place him by
his distance from you and from anyone in trouble, their own rule), and cowering isn't trouble of
his own. Hands up, aimed at, flinching from a deed, fleeing a fire, a bucket line, a shout or a
busy chore still tick every tick; the outlaws' rules are unchanged (near a fight is near).

| Scene (two runs each) | Window | Men ticked a tick, before → after | Slowed | People ms a tick, before → after (Sean's) |
|---|---|---|---|---|
| Spec hall | before the stick | 8.3 → 8.3 | 21 | 3.2 → 3.1 (2.1 → 2.0) |
| Spec hall | 0–6 s after | **15.3 → 8.3** | 13 → 21 | **6.0 → 3.7 (3.9 → 2.4)** |
| Spec hall | 7–14 s after | 9.4 → 8.3 | 18.7 → 21 | 3.9 → 3.6 |
| Street | before the stick | 19.6 → 19.6 | 4.7 | 6.7 → 6.3 |
| Street | 0–6 s after | 21.6 → 20.6 | 1 → 2.9 | 9.0 → 8.3 (5.8 → 5.4) |
| Street | 7–14 s after | 21.5 → 20.5 | 1 → 3 | 8.5 → 7.2 (5.5 → 4.7) |

On Main Street most men stand within the near band (25 m) of you anyway (12 of 22 before the
stick), so the bands can't buy much there. What's left of the street's rise is work, not the
bands (split by timing `_physics_step`'s statements, a temporary patch, not kept): the three men
the blast knocks down (their ragdoll tick, ~0.4 ms), the wound signs of the men it hurt (+0.27),
the pose (+0.45, cowering and two more men ticking), the carry (+0.17), the senses (+0.5).

**The dusk frames (#514's comment):** `tools/dusk_frame.gd` on the street, clock x30 and x1
(four runs at x1, 30 s from 17.6 h): no `fire_route` frame any more (#510 made routes cheap); one
run of four had three frames 24–30 ms at Sean's (`people_body` or `civilian_brain` 26–28 ms in one
frame), not repeated in the other three (worst 11.3–12.4 ms at Sean's), and no single man's tick
over 8 ms in a run that watched for it (`dusk.txt`). The spec hall at 18:00 x1: one 107 ms frame
(Sean's) on the ninth frame after the saloon is built, the fire's load analysis (`fire_loads`),
a load-time cost, not dusk.

## The gate (2026-11-01)

- **The gunfight lab** (`run.py --scenarios=spec_hall --hours=golden --weapons=revolver
  --styles=careful --bodies=studio --variant=D --seeds=1-10 --jobs=1`): two runs on the change,
  `same_fight.py` 10 of 10 the same; and 10 of 10 the same as the old rule (no fight changed).
- **The perception lab** (`run.py`, every group): 82 of 117 as expected on the change and on the
  old rule, the tables identical line for line.
- **`perf_bench --scene=fire --no-ablate`:** people 5.07 -> 5.05 ms at Sean's (unchanged): that
  scene still lights three buildings directly (`FireSystem.ignite`; only the lamp's spill is behind
  `in_play`), so ~7 townsfolk are running from the fire on a route (`n_full_fleeing` 7.4), which
  rightly ticks every tick; trouble 10.0 -> 7.6 men, slowed 1.0 -> 1.6. The game has no such fire
  now (#508); this lab's two scenes are the blast without it.
- The suite: 831 passed, 0 failed (with the new `test_town_day::
  test_far_off_the_street_cowers_from_a_blast_and_still_ticks_slowly`).
