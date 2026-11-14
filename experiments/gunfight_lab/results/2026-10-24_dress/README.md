# The saloon dressed for cover (2026-10-24, not finished)

Sean: "What if we added more tables and chairs and other stuff for cover?" The lab's `--dress=cover`
(`experiments/gunfight_lab/dressing.json`) adds two card tables with four chairs each, the piano,
two whiskey barrels and two spittoons to the spec saloon's hall (`gf_ways dress=cover`: 52 of 52
links walk). D+ (`--fixes=all+pain_fight+floor_fight+odds+flinch`), the careful player, seeds 1-10,
both openings.

- **G_dress**: 100 fights, done.
- **G_base** (the same without the dressing): 77 of 100 when the session stopped. Resume with
  `python3 experiments/gunfight_lab/run.py --styles=careful --seeds=1-10 --opening=,shoot
  --fixes=all+pain_fight+floor_fight+odds+flinch --out=build/gf/G_base` (it skips fights it has;
  `build/` doesn't survive the session, so a fresh one runs all 100).

So far (`tactics.md`, `wounded.md`, `cover_runs.md`):
- the gang hidden 11% -> 16% of their fighting time, in the open 39% -> 31%;
- runs for cover as quick (median 0.7-0.8 s, 2 m), a third still seen there within 2 s;
- hit men fire again a little less (49% -> 42%).

`quits.md` pools both runs (quits.py groups by variant, and both are D); split it by root before
comparing fight length. Not judged yet: whether the shooting lasts longer, or whether Y should
play the dressed hall.
