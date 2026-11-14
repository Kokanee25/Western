# The threading review's measurements (Fable, 2026-10-25)

Behind `docs/briefs/more-cores.md` "The review". This workspace's 2.1 GHz core, headless,
`--fixed-fps 60`, one game at a time, the code at `claude/perf-threading` (main as of PR #372
plus `claude/gameplay-saloon-cover`; the blast-freeze merge #375 isn't in the base runs, so
`fire` here is still the old whole-building settle).

The lab command, each set run twice (`_a`, `_b`) so `same_fight.py` can say whether the
configuration is deterministic:

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall --hours=golden --weapons=revolver \
    --styles=careful --bodies=studio --variant=D --seeds=1-3 --jobs=1 --max=120 --out=build/mc/<run>
python3 experiments/gunfight_lab/same_fight.py build/mc/base_a build/mc/base_b
```

- `base`: the game as it is.
- `phys`: physics on its own thread (`override.cfg`: `[physics] 3d/run_on_separate_thread=true`).
- `probe`: the base code with temporary sub-timers and query counters (not committed; the patch
  is described in `probe.md`), one run.

Files: `base.txt`, `phys.txt`, `probe.txt` (the per-fight `perf` summaries), `same_fight.txt`
(the comparisons), `phys_errors.txt` (where the space state was asked for outside the physics
window), `probe.md` (what the sub-timers say).
