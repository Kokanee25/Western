# MetaHumans at town scale (#889), 2026-11-13

What it costs to fill the valley with Sean's MetaHuman (`sean_metahuman_s3`, the Studio's build of
the private `sean-metahuman` export: joints only, no blend shapes yet), against today's Studio men,
and what cuts it back. The bench is the valley's (`docs/reviews/2026-11-valley-bench.md`, #865), run
by `tools/characters/metahuman_bench.py` with the townsfolk all one man:

- **today**: the bench's Studio men (twelve of them, in turn);
- **mh**: Sean's MetaHuman as exported (LOD0) for every townsman;
- **levels**: his lighter levels by band (lod1 near, lod3 down the street) and re-dressed (a hat
  colour, or none, and a vest tint a man).

Headless 10 s a run, 0/5/10/15/25 townsfolk, day, night and the gunfight; one drawn lavapipe run a
scene and config with 15. **Sean's ms = this core × 0.65.** This workspace is ~10% quicker than the
one the valley review ran on, so its "today" numbers are a little lower; the comparisons below are
always against this run's own "today".

## Him, per man

| Level (cut at load, `config/metahuman.yaml` in the Studio) | Triangles (hat) | Vertices | Meshes | For |
|---|---|---|---|---|
| LOD0, as exported | 157,141 (124,747) | 133,896 | 12 | the camera close up |
| lod1: 35% of skin/head/vest, half the eyes, one groom card in 2, no teeth | 56,313 (40,263) | 58,534 | 11 | near, 4–25 m |
| lod2: 12–15%, one card in 4, no lashes or brows | 25,384 (17,432) | 25,802 | 9 | down the street, 25–60 m |
| lod3: 4–6%, no grooms at all | 3,970 (4,168) | 3,238 | 6 | far, past 60 m |
| *a Studio man (the doctor, the miner), for comparison* | *43,618* | *~42,000* | *2* | |

Every level is built by HumanBody as the game builds any man: the game's 57-bone skeleton (his
DeformRig on the fuller skeleton), the 17 hitboxes and ragdoll parts, the people shader in the real
look (each shape's base colour, the grooms drawn with a coverage cut, not as solid strips). His
hair goes under a hat (BodyMesh's, re-dressed by colour).

Looked at (the game's distance lab, his hat on, 1.5 m and 6 m): the hat sits, the beard and brows
draw as strands through the cut, and each level holds his look at its own distance. lod2 shows a
light fleck at the vest at 1.5 m (it's for 25 m and more); lod3 is clean-shaven, which only reads
past 60 m. The renders stay local (MetaHuman: none in this repo).

Where his triangles are, LOD0: body skin 55.8k, **hair 32.6k, beard 13.6k, mustache 7.9k, brows
5.7k** (the grooms: 60k triangles and 76k of his 134k vertices), head 22.0k, vest 9.9k, teeth 7.0k,
eyes 1.4k, lashes 1.2k. A hat takes the hair away.

## The frame (Sean's ms; budget in brackets)

People's part (4.0), headless:

| Scene | Townsfolk | today | mh | levels |
|---|---|---|---|---|
| day | 0 / 5 / 10 / 15 / 25 | 0.74 / 1.63 / 2.26 / 2.97 / **4.42** | 0.74 / 1.57 / 2.39 / 3.17 / **5.58** | 0.74 / 1.64 / 2.18 / 2.84 / **4.85** |
| night | 0 / 5 / 10 / 15 / 25 | 1.08 / 1.97 / 2.36 / 3.16 / **4.40** | 1.08 / 1.77 / 2.62 / 3.33 / **4.94** | 1.08 / 2.10 / 2.50 / 3.20 / **4.48** |
| gunfight | 0 / 5 / 10 / 15 / 25 | 3.12 / **4.16 / 5.34 / 5.87 / 7.97** | 3.12 / **4.24 / 5.77 / 6.94 / 8.39** | 3.12 / **4.41 / 5.58 / 6.82 / 8.10** |

The whole frame by day at 15 / 25: today 5.43 / 7.21, mh 5.92 / 9.68, levels 5.25 / 8.11.

At 25 by day the MetaHuman's extra goes to people_body (1.66 → 2.11) and the skeleton (0.97 →
1.33): HumanBody's per-piece work grows with his twelve meshes and 134k vertices (the per-frame
pose and piece updates, not the GPU's skinning). The levels take most of it back (1.83, 1.06).

Drawn under lavapipe, 15 townsfolk (render CPU at Sean's; lavapipe's GPU time is on the CPU, so
only relative):

| Scene | Config | Render CPU (4.0) | Draws | Primitives | Lavapipe GPU ms | Video MB | Textures MB |
|---|---|---|---|---|---|---|---|
| day | today | 2.46 | 3,607 | 25.0 M | 3,336 | 2,133 | 1,437 |
| day | mh | 2.65 | 3,777 | 27.3 M | 3,696 | 2,398 | 1,585 |
| day | levels | 2.60 | 3,725 | **24.7 M** | **3,313** | 2,258 | 1,581 |
| night | today | 1.71 | 2,121 | 12.9 M | 2,795 | 1,945 | 1,241 |
| night | mh | 1.90 | 2,465 | 16.8 M | 3,163 | 2,155 | 1,340 |
| night | levels | 1.93 | 2,469 | **13.0 M** | **2,878** | 2,024 | 1,336 |
| gunfight | today / mh / levels | 13.0 / 9.0 / 10.1 | 5,189 / 5,370 / 5,328 | 36.1 / 38.4 / 35.9 M | 3,946 / 4,083 / 3,887 | 2,224 / 2,489 / 2,348 | 1,487 / 1,635 / 1,631 |

The MetaHuman adds ~11 draws a man (his twelve meshes against a Studio man's two: the body in one, the head) and ~150k
primitives a man as exported (shadow passes included); his levels bring the primitives and
lavapipe's GPU time back to today's men's, and the draws stay ~8 a man up. Render CPU stays ~0.15–0.2 over today's men at 15, well
under its 4.0. The gunfight's drawn runs are a few frames straight after the first shots (new
smoke and impact materials compiling), as in the valley review: noise, not him.

## The townsfolk the slice can afford

**Per townsman** (people's part, day; the slope between 0 and 15, and 0 and 25): today **0.147–0.149**,
mh **0.162–0.194**, levels **0.140–0.164**. At night: today 0.133–0.139, mh 0.150–0.154, levels
0.136–0.141.

| | People's 4.0 holds, day | At night | In the gunfight |
|---|---|---|---|
| today's Studio men (this run) | **~22** | ~22 | over with any (as the valley review found) |
| Sean's MetaHuman as exported | **~17** | ~19 | over |
| with his levels and re-dressed | **~20** | ~21 | over |

In the valley review's own terms (18 today's men on its slower workspace): **~15 MetaHumans as
exported, ~18 with the levels**, the same as today's men. The render CPU isn't what limits him:
~0.2 ms over today's men at 15 by day, 2.6 of its 4.0. The gunfight is over its 4.0 with no townsfolk at all (the gang's own minds, 3.1
before anyone else), as the valley review found; its cuts (far men at a quarter, senses that don't
grow with the square) are what lets the brief's 24 in, MetaHumans or not.

## Memory and load

- **Video memory: ~150 MB a distinct MetaHuman**, the game's people-shader textures: his ten shapes'
  base colours (2048², the teeth 1024), uncompressed and without mipmaps (as the Studio men's are; a Studio man is
  ~40 MB: the doctor, 41). The 15 copies of one man share them (+265 MB video at 15, +148 MB textures, against
  today). **Fifteen different MetaHumans at 2048 would be ~2.2 GB**: the cut that matters if the
  town is all MetaHumans is the textures, not the triangles (1024² is a quarter; VRAM compression
  another 4–8×; both the art lane's call for the look, see below).
- **Static memory:** +230 MB at 25 (mh), +110 MB with the levels (day 2351 / 2578 / 2462 MB).
- **Load:** laying 15 townsfolk takes 3.6 s (today), 6.9 s (mh), 8.0 s (levels) here (× 0.65 at
  Sean's). The first build of each level of him costs ~2.2–3.5 s (his GLB read, and Godot's
  simplifier for the levels); a copy after that ~0.5–0.7 s, against ~0.24 for a Studio man. The
  levels add a one-off ~3 s each; if that matters at the valley's load, the Studio can bake them
  into the GLB once instead (the same cuts).

## What Sean should do in MetaHuman Creator

To keep each one cheap (the Studio's PLAYBOOK §4b has the export steps):

1. **Export LOD0 only**, with **Joints and Blend Shapes**. The game cuts its own lighter levels
   from it when it loads him (35%, 12%, 4%): MetaHuman's own LODs would only add download and
   memory.
2. **Grooms as cards with their atlases, never strands.** Strands can't be drawn at all here;
   cards are already more than half his vertices.
3. **Short hair, or a hat.** The hair is his single biggest groom (32.6k triangles): a hat drops
   it (157k → 125k). A cropped or receding cut is a fraction of that.
4. **Stubble or a short beard rather than a full one** where the man allows (beard and mustache
   are 21.6k together); brows and lashes are small and go by lod2 anyway.
5. **Clothes over skin:** his body skin is 55.8k triangles, the biggest single mesh. A man in a
   shirt, coat and trousers hides most of it; a later step could drop the skin hidden under them.
6. **One texture size down for townsfolk** (1024 if Creator offers it, else the Studio downsizes
   on the way in, once art has seen the look): the video memory, not the frame, is what a town of
   different MetaHumans runs out of first.

## How it was measured

    tools/metahuman_to_game.sh sean_metahuman_s3       # in the Studio: his files into the game's git-ignored private/
    python3 tools/characters/metahuman_bench.py --out=build/mh_bench   # today, mh, levels (~4 h, one game at a time)
    godot --headless -s res://tools/characters/private_people.gd -- --model=private/sean_metahuman_s3 --out=FILE

Read for this: the valley review (above), `tools/valley/bench_runs.py`, `tools/perf_bench.gd`,
`tools/valley/valley_townsfolk.gd`, `src/bodies/people_bodies.gd`, `src/bodies/human_body.gd`
(`_build_skin`), the Studio's `docs/PLAYBOOK.md` and `docs/METAHUMAN.md`.
