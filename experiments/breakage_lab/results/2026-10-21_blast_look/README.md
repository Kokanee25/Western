# The blast's look, 2026-10-21 (`docs/briefs/blast-look.md`)

`BlastCloud` (`src/effects/blast_cloud.gd`) in place of the old orange light, bursts and gun-smoke
puff, judged by eye against the road-blasting reference Sean picked (described in the brief; the
footage is not in this repo). A stick lying on the street, at the store front's foot and on the
saloon floor, the bold cowboy as the man; every frame drawn (xvfb, lavapipe), a shot at each moment:

    python3 experiments/breakage_lab/run.py --look=0,0.05,0.12,0.25,0.5,1,2,4,8 --jobs=3 \
        --bodies=bold_cowboy_s0 --scenario=ground_dynamite_0m,wall_dynamite_0m,floor_dynamite_0m --out=...
    python3 experiments/breakage_lab/sheets.py look ROOT OUT.jpg

- `sheets/round1.jpg`: the first cloud (stopped at 2 s): a narrow near-black column on the street,
  black chunks, and a lit board's whole sheet of flame at 0.05 s (a fireball, which the reference
  hasn't got).
- `sheets/round2.jpg`: fire 1–4 s after the flash (`ignite_delay`); the dust bigger, wider, the
  dirt's colour. Tan, dark at the root, gone by 8 s. A hard dark band at the cloud's foot.
- `sheets/round3_ground.jpg`: top row the dust on its own render layer (out of the scorch decal,
  which made the band), bottom row the try before it (the surge spread in height: no change).

Still off (the brief's "Still off"): the store front's dust is a faint haze under the porch roof; a
catching board's whole sheet of flame (the fire's look).
