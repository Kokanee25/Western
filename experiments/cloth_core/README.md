# Our own cloth's lab (#973, `docs/briefs/garment-cloth.md` step 1: the core)

`ClothCore` (the native plugin's `cloth.rs`, its face `SolverCloth`) beside Jolt's soft body, in the
game's real look. In a row, dropped from a metre at once, left to right: **our sheet**, **the Jolt
rag** (a ClothProp of the same size, 16×16 points and 50 g), **our glove** (the long glove's own mesh,
made from `sean_s3_talking`'s skin by `WornGarment`, SHAPED bending), **Jolt's glove** (the same
points as `GarmentCloth`, 35 g); behind them **our sheet hung by two corners**.

## The film (made on a runner)

This workspace can't build the native plugin (crates.io is blocked here) or download CI's artifacts
(their storage host is blocked too), so the film is made on a GitHub runner: `film/request.txt` is
the dev bridge's commands; pushing a change to it on a `claude/` branch runs
`.github/workflows/lab_film.yml` (`tools/lab_film.py`), which builds the plugin, renders under
software Vulkan and commits `film/out/` back to the branch (`git pull` after ~25 min). The answers of
every command are in `film/out/replies.jsonl`.

Bridge commands (`bridge.gd`): `cc_set X Y Z [MODEL]`, `cc_cam front|low|top`,
`cc_film DIR [SECONDS]`, `cc_clear`, `cc_cost X Y Z [FRAMES] [MODEL]` (each cloth dropped alone, the
physics frame's ms against none: our script's tick and Jolt's step; ours' own solver time).

The MetaHuman's files can't be in this repository and the runner has no Studio, so the glove is made
from the Studio man CI's tests use; on the MetaHuman the same code makes the same kind of glove.

## Results (2026-11-15)

RESULTS
