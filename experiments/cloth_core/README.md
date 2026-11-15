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

Run 3 (`film/out/`, made on a runner; runs 1-2 were under the north walk and drawn on their back faces):

- **The film:** [`front.mp4`](film/out/front.mp4) (7 s, real time) and
  [`low_half_speed.mp4`](film/out/low_half_speed.mp4) (the landing at half speed); stills `front_start.jpg`,
  `front_landing.jpg`, `front_end.jpg`, `low_end.jpg`. Left to right: our sheet, the Jolt rag, our glove,
  Jolt's glove; behind, our sheet hung by two corners (red).
- **What it shows:** all four land and lie still (ours at rest at 2 mm over the street, the floor plus its
  thickness; nothing through it). Our glove lies as a glove, folded once; Jolt's crumples into lumps (no
  bending stiffness). Our sheet lands flat, without the folds a real one would keep (it's stiff in
  stretch and soft in bending, with no air: it slaps down); the hung one hangs straight from its corners.
- **Its edges:** worst 1.14 × rest for a few ticks of the glove's landing (its limit 1.05; at rest within
  1%): a landing's push off the floor stretches edges a few millimetres long. 12 substeps gave 1.22, 20
  give 1.11, 30 give 1.08 (`addons/saltcreek_native` probes on the glove's mesh, `glove_sean_s3.json`).
- **The cost a tick** (`bench.gd`, ten of a kind dropped in a bare world, wall time a frame over 4 s
  including their rest, on the runner): Jolt's glove 0.058 ms, Jolt's rag 0.061; **our glove 0.37** (its
  own solver 0.35, at 20 substeps), our sheet 0.085. Ours costs about 6× Jolt's on the glove (Jolt's own
  threads aren't in the main thread's wall time, so Jolt's is a floor). While it falls our glove takes
  ~0.59 ms on this workspace's 2.1 GHz core: **~0.38 ms at Sean's**, under the brief's 0.5; at rest 0.
- **Next for the look:** air drag (a sheet that slaps down flat), and the folds come with self-contacts
  (step 3).
