# Brief: a talking face for the Rodin men (the bold cowboy first)

Sean, 2026-10-16. Characters lane. Five steps; **1, 2 and 4 (sheet) done, the first pass's concerns worked; 3 and 4 (video) built and tested on a
stand-in take, waiting on Sean's Live Link Face take.** How it's laid out: `docs/LAYOUT.md` "The talking face".

1. **Audit** (done): `docs/style_test/face_rig_audit.png`. His in-game head (`bold_cowboy_layered`,
   12k triangles) is one closed painted skin: no lip line (MediaPipe's inner upper and lower lip
   land on one vertex), no mouth opening or inside, no teeth or tongue, no eyelids (eyes are paint
   on a bump, ~1 triangle tall, a UV seam between the lids), no jaw bone (head and neck only, every
   head vertex on `head`), no blend shapes. Rodin's own model is no finer (39k triangles, ~7 mm
   edges at the mouth), so the mouth and lids must be built, not found. The moustache covers his
   whole upper lip. At 1080p/75°: mouth 21 px wide at 2 m, 8 px at 5 m, 4 px at 10 m.
2. **A working face on a copy** (`bold_cowboy_talking`; `bold_cowboy_layered` is not touched).
   All CC0 MakeHuman data, our own scripts (`tools/faces/`), bpy only:
   - MakeHuman's `face-poseunits.bvh` (59 units: jaw, lips, lids, brows, cheeks, tongue) posed on
     its `default` skeleton with `default_weights.mhw` → one offset field per unit on its base mesh.
   - MakeHuman's face wrapped onto his: his 478 MediaPipe points (already in his head's `pts`) to
     the matching MakeHuman vertices, an RBF warp, then a fit to his surface.
   - Grafted: his face front (brows to chin) replaced by the wrapped MakeHuman face (its lips with
     their inner roll, mouth opening, eyelids), stitched to his mesh on a ring; his paint
     re-projected onto the new triangles (closest point on his old surface → his texel); a dark
     mouth bag; MakeHuman's helper eyes (his painted eyes laid on them), teeth and tongue, plain.
   - 12-15 blend shapes from sums of units: jaw open; AA, EE, OO, FV, MBP; blink L/R; squint;
     brows up; brows down; scowl; half smile L/R. The moustache rides the upper lip.
   - Godot: glTF morph targets carried through `body_mesh.gd`'s per-part meshes; a small face
     player sets the weights (its dials in a resource).
3. **Sean's Live Link Face take** (ARKit .csv + .mov): the 52 mapped to the shapes by a table
   (`jawOpen`→jaw, `mouthFunnel`/`mouthPucker`→OO, `mouthStretch`/`mouthSmile`→EE and half
   smile, `mouthRoll*`/`mouthPress*`→MBP/FV, `eyeBlink*`, `eyeSquint*`, `brow*`), played in Godot
   with the .mov's audio. Lip sync is the test. ElevenLabs voice changer optional: API ~$0.12 a
   minute (third-party figure; check their page), a 20 s line ~$0.04, but it needs an account and
   key (free tier: no commercial rights; Starter ~$6/month): Sean's call.
4. **Show:** an expression sheet (front and three-quarter, plain light) and a short video of him
   saying the line (Godot Movie Maker under xvfb).
5. **Report:** what worked, what didn't, and what `RECIPE.md` would need for every man.

Judged by Sean: the line reads as his speech at 2 m; blinks and brows read at 5 m; his paint holds.
Cost so far $0 (no paid calls). Step 2 is ~a day of work.

## Where it stands (2026-10-16)

- **2. Done:** `bold_cowboy_talking` (`assets/people/bold_cowboy_talking.*`; the layered man
  untouched). MakeHuman's face grafted on (5,609 triangles; 990 of his cut out; MakeHuman's mouth
  already has its inside, its throat capped dark), his paint carried over, 15 expressions as
  blend shapes (`talking_face.py` `EXPRESSIONS`; 19 since the second pass). In the game the shapes now survive the cut into
  pieces (`PeopleBodies._load`, `BodyMesh.split_pieces`; test `tests/test_face_rig.gd`).
- **4. The sheet:** `docs/style_test/bold_cowboy_talking_expressions.jpg`, drawn by the game's own
  materials (`face_lab.gd`), with rows at game size (1080p, 75°) at 2 m and 5 m.
- **3. The take:** `arkit_take.py` + `take_video.sh` run end to end on a stand-in (`synth_take.py`:
  espeak-ng's voice, its phonemes as ARKit values, written as Live Link Face writes them, the
  .mov's sound lined up by timecode). Waiting on Sean's take for the real test.

What worked: MakeHuman's pose units drive his face well once its teeth are set back and the pull
onto his surface is kept off the lids; his moustache rides his upper lip; his paint holds (the
lids painted from outside his painted eye).

**The concerns, worked (2026-10-16, second pass):** 19 expressions now (the eyes turn).
- *Under the moustache:* measured, not guessed (`tools/faces/readability.py`: pixels of his face
  that change at 1080p, 2 m, him held still; rest against itself 0). Against jaw open: smile 89%,
  aa 87%, oo 66%, ee 59%, half smiles 51-57%, scowl 49%, fv 48% (was 42%: the lower lip now tucks
  under his upper teeth), brows up 39%, mbp 26% (a shut mouth from a shut mouth: its work is
  closing between vowels), blinks and eye turns 6-11% (small, but the eye is where one looks).
  The smiles now lift his lower lids too, so they show in his eyes.
- *Teeth:* painted by rule (gum, a line between the front teeth, darker round the arch), set 4 mm
  behind his lip line; "mbp" remade as lips shut and pressed (stretched, they parted on his teeth).
  His upper teeth stay hidden under his moustache except in "fv", as a real man's would.
- *Eyes:* four turns (MakeHuman's eye units, about 19°, the lids following up and down); each
  eyeball mapped polar about its forward axis (every point its own texel) and painted white past
  his painted eye (his own whites' colour, warm as his paint is). ARKit's eyeLook* now drive them.
  The skin shader's wet-eye gloss (art's) greys the whites against a grey sky: as for every man.
- *The lid's crease:* the blinks' movement smoothed over the lid above its edge; it shuts fully, a
  small kink left in the closing line at very close range.
- *The neck:* not a gap. With his head turned 30° the join stays closed and matches the layered
  man's; what showed in the first video was his collar.

## What RECIPE.md would need (the characters session's change, with Sean's OK)

A step after "Into the game" (and for a layered man, after LAYERED.md's step 6):

1. Once per workspace: `~/bpyenv/bin/python tools/faces/mh_units.py --fetch` (needs
   `fetch_makehuman.py` first; `apt-get install libegl1` for MediaPipe).
2. `~/bpyenv/bin/python tools/faces/talking_face.py --man=<man> --out=<man>` (in place, or to a
   copy while he's judged) → his glb with the face and expressions, `<man>_head.png` doubled in
   width (his + the face's), `facerig` in his report. Needs his kept bust
   (`assets/people/heads/<head>_mesh.npz`, its MediaPipe `pts`) and his game glb's `body_head`.
3. `godot --headless --import`; `tests/test_face_rig.gd` (pointed at him); the sheet:
   `tools/faces/lab_run.sh LOG --id=<man> --out=DIR --turns=0,-40 --fov=12 --dist=1.4 --size=600x600`
   then `python3 tools/faces/face_sheet.py --out=<man> --lab=DIR`.
4. Check on the sheet: blinks shut clean, nothing pokes through the lips (`teeth_back_mm` in the
   report), the mouth's inside dark, his paint unbroken round the eyes and mouth.
Numbers a man may need changed: `EYE_FADE`, `PULL_OUT` (a man with a beard or bigger brows),
`TEETH_BEHIND`. A clean-shaven man will show the lip shapes far better than the bold cowboy.
Not yet in the game: something that drives the shapes (blinks, speech) on people in town; that's
gameplay's call (a FacePlayer on HumanBody, its dials in a resource).
