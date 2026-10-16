# Brief: a talking face for the Rodin men (the bold cowboy first)

Sean, 2026-10-16. Characters lane. Five steps; **step 1 done, the rest wait on Sean's yes.**

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
