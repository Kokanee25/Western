# Brief: drawn faces on a shared base head (a test)

Sean, 2026-10-10. The characters session's. One head, judged against `stranger2s`. It doesn't
replace the Rodin route unless Sean says so after seeing the result.

## Goal

Find out whether a face whose small features are *decided* (modelled big, shaded per square,
stamped as glyphs) reads better at our square size than a face whose features are *averaged*
out of a scanned model's colour, as `stranger2s`'s are.

Why the features vanish today: at ~8 mm squares a face is ~20 squares across. An ear is ~7x4
squares, a nose 4-6 long, a nostril 1, the lip line 1 row, an eyelid less than 1. Our bake
averages each square (a low-pass filter), so anything under about two squares goes into the
skin round it. Rodin's and Tripo's men carry their small features in a normal map and the photo
colour; the game's men have no normal map at all (the fitted glb carries no tangents or normal
texture: only Rodin's source glb has one), so only the colour and the decimated shape are left.
Every man also has his own topology and UVs, so nothing drawn on one carries to the next.

## The test head

- **Shape (big forms, 4+ squares):** MakeHuman's base mesh (CC0, v1.2.0, as `make_people.py`
  uses), its topology kept, with one stylised edit: ears flared off the skull with a thicker rim
  and a deeper hollow, the nose 10-20 % bigger with a hard change of plane from bridge to side,
  a heavier brow, firmer lip planes; a moustache as its own shell 5-10 mm proud of the lip with
  an overhang, so it casts a shadow. Fitted to our skeleton and head hitbox, his drawn eyes on
  the anatomy's eyes.
- **UVs:** a house layout, skin at exactly 8 mm a square; the lip parting on one row of
  squares, each eyelid on a row, the nostrils centred on squares, each ear flat on its own
  island, the moustache on its own island; the eyes on a finer grid that nests in the 8 mm one.
- **Paint (by script, in UV space, no image model):** a skin ramp of 5-7 tones, cavity and AO
  stepped into it, a one-step jitter, region tints (nose, ears, cheeks redder; jaw cooler for
  stubble; sockets darker), then the glyph stamps (nostril, lip line, mouth corners, ear hollow
  and canal, the moustache's dark underside and lighter top, the nose tip's light), then the
  eyes as `stranger2s`'s are drawn (white, iris, pupil, glint, lid). Colours sampled from
  `stranger2s` and the painting's man.
- **Light (medium forms, 2-4 squares):** one normal a square, baked from an exaggerated copy of
  the head (rims inflated, hollows deepened), nearest-filtered; no fine normal map. The skin
  shader already lights each square at its centre; reading a normal a square needs a few lines
  in `body_skin.gdshaderinc` (the art session's file), off unless a man asks for it.
- **The rest of him** is `stranger2s` as he is: his body, coat and collar, and his hat cut from
  his own head, so the comparison changes the face and nothing else.

## Step 1 first: the normal-map convention

Before any of it: a hemisphere bump baked onto a flat quad in Blender with default settings,
exported to glTF with tangents and lit from above in Godot, to check Blender, glTF and Godot
agree (OpenGL +Y, MikkTSpace); Khronos's NormalTangentTest if it can be fetched; and
`stranger2s`'s head (Rodin's source) with and without its normal map under a raking light. The
bump test stays as a check.

## What done looks like

- `assets/people/faces_test.glb` (+ textures and report), worn in the saloon shot with
  `--model=faces_test` and in `tools/people_lineup.gd`, no game code changed but the shader's
  gated lines.
- Pictures `docs/screenshots/tripo/faces_test_*.png`: test head | `stranger2s` | the painting's
  man, the face at 3x, at the card table and in plain light; then the numbers.
- A status entry with a view: does the drawn face read better, and which parts carry to the
  Rodin men without the shared base (the stamps, bigger ears and nose, the moustache shell)?

## How it's judged

- Each stamped feature's OKLab lightness against the squares round it in the lit render, aiming
  for 0.08-0.10 or more in at least two of three lights (warm lamp, golden-hour sun, deep shade
  with fill).
- MediaPipe's face landmarker finds his eyes, nose tip and lip line in the renders.
- Every face texel in exactly one square; the eye grid nests in the skin grid.
- Shrunk to a quarter size, his ears still stand off his cheek and the moustache sits in front
  of his lip.
- `tools/characters/judge_man.py` and judge v2 on the shot; the art session's blind critic
  (asked for, not run by this session).
- Sean's eye decides.

## Limits

One head; no roster, no wardrobe. No paid calls (no Tripo, Rodin or fal) without asking Sean
with the cost. MakeHuman's assets are CC0 and may go in the repo; MPFB2's addon code (GPL) and
MakeHuman's program code (AGPL) stay out. The numbers above are the research's starting points,
tuned by eye.
