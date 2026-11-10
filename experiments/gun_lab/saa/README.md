# The Colt Single Action Army, built by script (#693 step 1)

Sean, 2026-11-07 (#693): build the gun, don't buy it. The 1873 Colt Single Action Army made in
Blender by script from its real dimensions, every part the game drives its own object, shown in the
game under the real look. **Nothing in the game changes in this step:** the player's revolver is
still `RevolverModel`; the arms and animations are untouched. No maker's name, logo or stamping
(the gun lab's rule).

```sh
python3.11 -m venv ~/bpyenv && ~/bpyenv/bin/pip install bpy==5.0.1      # Blender as a Python module
~/bpyenv/bin/python experiments/gun_lab/saa/saa_blender.py [--barrel=7.5|5.5|4.75] [--out=DIR] \
    [--preview=DIR --views=right,left,front34,rear34,top,under34]      # ~8 s; Cycles stills of the shapes
godot --headless --import
xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver vulkan --resolution 1600x900 \
    -s res://experiments/gun_lab/saa/saa_views.gd -- --real --out=build/saa/views [--only=turntable,close,mech] [--hour=16]
python3 experiments/gun_lab/saa/sheets.py build/saa/views experiments/gun_lab/saa/results/<date>   # sheets + film
```

The views need the native plugin built (`cargo build --release` in `addons/saltcreek_native`, the
`.so` into its `bin/`) and lavapipe (`mesa-vulkan-drivers`, xvfb). Here: ~10 min to load the
street under the real look, then ~50 s a pose (each held 14 frames for FSR2 to settle); the whole
set ~45 min.

## Files

- `saa_blender.py`: the gun. Out: `saa_<barrel>.glb` (one node a part, its origin on its pivot) and
  `saa_<barrel>_rig.json` (pivots, axes, travel, markers; Godot space, metres).
- `saa_rig.gd`: drives the parts from the rig file: `hammer("rest"|"safety"|"half"|"full"|deg)`
  (the trigger and bolt follow), `trigger(pull)`, `cylinder(steps)`, `to_gate(k)`, `gate(open)`,
  `ejector(push)`, `chamber(k, "loaded"|"spent"|"empty")`.
- `saa_views.gd`: the gun over Main Street's road at 16:00 under the real look, a camera of its own:
  a 24-step turntable, close shots (right, left, muzzle, hammer from above, loading, cocked, down
  the sights) and the mechanism strip driven through `saa_rig.gd`.
- `sheets.py`: the contact sheets and the turntable film from a views folder.
- `overlay.py`: the side render over the reference photo at the same scale (README "The reference").
- `surfaces.py`, `surfaces/`, `saa_paint.py`, `.github/workflows/gun_surfaces.yml`: the painted surfaces ("The surfaces").

## The parts

Each its own node under `ColtSAA`, origin on its pivot:

| Part | Moves | Finish (placeholder now) |
|---|---|---|
| `Frame` (frame front, top strap and rear-sight groove, recoil shield, rear frame) | no | case colours |
| `Barrel` (crowned muzzle, six-groove bore, half-moon front blade) | no | blued |
| `Cylinder` (six chambers through, six flutes, a bolt notch over each chamber with its lead, ratchet, bushing) | turns 60° an index, clockwise seen from behind | blued |
| `Case0..5`, `Bullet0..5` (children of the cylinder) | shown loaded / spent / empty | brass, lead |
| `Hammer` (body, spur, firing pin) | rest, safety, half, full cock | case colours |
| `Trigger`, `Bolt` | turn on their screws | blued |
| `Gate` (the flap of the recoil shield over the loading chamber) | swings out about an axis along the bore | case colours |
| `Ejector` (rod and crescent head) | slides back by its stroke | bright / blued |
| `EjectorHousing` (slot, web to the barrel) | no | blued |
| `BasePin` (knurled head) | no (comes out to strip) | fire blue |
| `Backstrap` (tang behind the hammer, round the butt), `TriggerGuard` (tang, bow, front strap) | no | blued |
| `Grip` (one-piece walnut) | no | walnut |
| `Screw_*` (hammer, bolt, trigger with their ends on the right; base pin; gate catch; guard front and rear; ejector tube; backstrap ×2; butt) | no | fire blue |

Markers (empties, in the gun's space): `Muzzle`, `SightRear`, `SightFront`, `GripWeb`, `TriggerFace`,
`GatePoint`, `BoreBreech`; `HammerSpur` on the hammer, `EjectorHead` on the rod. 72,000 triangles in
all (the cylinder 29k with its rounds); a game LOD is for the step that puts it in the hand.

Not modelled (inside the frame): the hand, the mainspring, the springs, the recoil plate. The spur's
checkering is for the surfaces pass (a normal map): cut as geometry the exact boolean dropped a
third of the grooves.

## The reference

The shape is fitted to a real Colt (Sean's review, 2026-11-09: "the shapes aren't a Single Action
Army yet"): the Met's serial no. 4519, an 1874 7½" (CC0; `docs/concept/guns/ref/saa_met_59-143-4_left.jpg`,
its source in that folder's `SOURCES.md`), side on. Its silhouette was cut from the plain ground
and put in the model's inches by three numbers that agree: 13" overall and 7½" from the muzzle to
the cylinder's face (the Met's figures), and the barrel 0.685" across (the published 0.686"), all at
132.8 px an inch. Every outline behind the barrel was then read off it: the frame's front face and
foot, its lower edge sloping to the guard, the guard's tang, bow and opening, the trigger, the three
screws on the left (the hammer's low on the frame), the hammer's top and slim spur, the backstrap's
one curve from under the hammer to the heel, the front strap, the flat butt, the tall front blade,
the ejector housing and its button.

```sh
~/bpyenv/bin/python experiments/gun_lab/saa/saa_blender.py --preview=build/saa/ov/r --views=left --px=2000 --alpha=1
python3 experiments/gun_lab/saa/overlay.py docs/concept/guns/ref/saa_met_59-143-4_left.jpg build/saa/ov/r/left.png \
    build/saa/ov --points=86,467.5,9.114:1080,467.5,1.608 --name=r --mask=MASK.png
```

`--points` are the muzzle and the cylinder's front face on the bore's axis in the photo's pixels;
MASK is the photo's gun cut from its ground (dark under the ground's median less 45, the largest
piece, holes under 3,000 px filled: the guard's opening kept). Overlap (intersection over union of
the two silhouettes): **0.666 before the fit, 0.952 after**; what's left is mostly the photo's glare
on the frame's lower edge (holes in its mask) and the thin gap round the cylinder.
`results/2026-11-09_overlay/`: `before_overlay.jpg`, `after_overlay.jpg` (the render's outline in red
over the photo), `before_after.jpg`, `after_side.jpg` (side by side, the same scale and crop),
`before_diff.jpg`/`after_diff.jpg` (red: the photo's gun only; blue: the render's only);
`after_side_real_look.jpg` (the game's render under the real look beside the photo, put to its scale
by where the muzzle and breech landed: `saa_views.gd --only=side`, `overlay.py --plain=1`),
`side_right_real_look.jpg`, and the refitted gun's `turntable.mp4`/`.jpg` and `close.jpg`.
Placeholder materials still: no paint, no paid call.

## The dimensions

Inches; f along the bore from the cylinder's rear face, u up from the bore's axis.

| What | Value | Source |
|---|---|---|
| Barrel lengths | 7½" Cavalry (built first), 5½" Artillery, 4¾" Civilian; `--barrel=` | Wikipedia, "Colt Single Action Army" |
| Overall length | 13" with the 7½" | the Met, 59.143.4 |
| Cylinder length | 1.608" | The Firing Line forum, SAA blueprints thread |
| .45 Colt cartridge | bullet .454", case 1.285", rim .512" × .060", mouth .480", overall 1.600" | the cartridge's published (SAAMI) dimensions |
| Bore | .445" lands, .454" grooves, six grooves | as the cartridge |
| Barrel .700" at the frame, .686" at the muzzle | the photo: .685" | |
| Every side outline behind the barrel (frame, hammer, trigger, guard, grip, front blade, ejector), the three screws | measured | the Met gun's photo (above) |
| Cylinder diameter 1.650", chambers on a .520" circle | est. | sized round the chamber walls and the bolt notches |
| Widths across the gun (frame .90", top strap .54", grip 0.72"–1.32", hammer .31") | est. | no top view of the Met gun |
| Loading gate at 75° clockwise from the top (seen from behind) | est. | where the ejector rod sits beside the barrel (its housing's bottom measured) |

The model's size (its bounds in Godot): 13.0" overall with the 7½" (the Met: 13"), 5.4" tall with
the butt screw's head (the photo: 5.3"), 1.65" across at the cylinder. **Estimates are marked est.:** the travel numbers too (hammer notches 4/10/24° about the low
hammer screw, trigger 3–6°, gate 95°) in the rig file.

## The surfaces

Sean's yes on #740 (2026-11-09): paint them, cap $2.50; the grip frame blued steel (as built).
The image model paints only flat tiling surfaces, never the shape. **Since Sean's second review the
metals are made in the bake from noise (below, step 4); of the seven paintings only walnut_1 is used.**

```sh
# GitHub Actions (gun_surfaces.yml, the key a secret there): runs when a claude/colt-* branch pushes a
# changed surfaces/request.json; commits surfaces/raw/ and spent.json back
python3 experiments/gun_lab/saa/surfaces.py --paint
python3 experiments/gun_lab/saa/surfaces.py --cut              # here, free: seamless, 1024, 2x2 checks
~/bpyenv/bin/python experiments/gun_lab/saa/saa_paint.py --pick=case_2,blued_1,walnut_1 [--size=2048]
```

- **The calls:** FLUX.2 [max] on OpenRouter through the texture factory's own call
  (`tools/textures/paint_textures.ask`, used, not changed). Seven 2048 px paintings: case colours ×3,
  worn bluing ×2, walnut ×2, **$0.16 each, $1.12 of the $2.50 cap** (`surfaces/spent.json`; the run
  holds $0.35 back before each call). Raw paintings in `surfaces/raw/`; the seamless cuts, checks and
  atlases are made here, free, and not kept (`surfaces/.gitignore`).
- **The picks:**
  - **case_2:** blue, violet and straw iridescence over grey;
  - **blued_1:** even, with fine polish lines. It came back grey and is tinted to blue-black in the
    bake;
  - **walnut_1:** clean straight grain.
  - The others: case_0 is too beige, case_1 reads as marbled stone, blued_0 has bright streaks, and
    walnut_0 is blotchy across its seams.
- **The bake** (`saa_paint.py`, Cycles on the CPU, a few minutes at 2048):
  - Every part is on one smart-projected atlas (UV `bake`).
  - The tiling paintings sit on the box UVs (one every 50–70 mm; polish lines and grain run along
    the gun).
  - **Wear:** edges rub to grey steel, the case colours silver and the walnut lightens, wherever the
    Bevel node's rounded normal parts from the face (0.6 mm, broken up by noise).
  - **Grime:** dark and rough in the hollows (ambient occlusion within 4 mm).
  - Baked as emission into `saa_albedo` and `saa_orm` (glTF's occlusion, roughness and metal),
    exported as JPEG in the glb (3.8 MB); Godot extracts `saa_75_saa_albedo.jpg` and
    `saa_75_saa_orm.jpg` beside it.
  - The rounds keep their solid brass and lead.
  - The fire-blued screws and base pin are the bluing tinted blue.
- **Not yet:** the spur's checkering and the screws' slots as normal maps; a game LOD.

`results/2026-11-09_painted/`:
- `turntable.mp4` / `.jpg`, `close.jpg`, `mech.jpg`: under the real look, Main Street at 16:00.
- `side_by_side_real_look.jpg`: beside the Met gun at its scale.
- `side_right_real_look.jpg`.
- `surfaces_tiled.jpg`: all seven paintings tiled 2×2, the picks marked.
- `cheap_judge/`: the cheap judge on the same five close shots as round 1.
  - **Two good indie, three cheap indie** (round 1: five cheap indie), ranked d, a, b, c, e.
  - The gun's faults left:
    - the case colours read as camouflage or lichen: one even mottle at one scale, no bright edges;
    - the bluing too clean and chrome-like, with a blown sun glint on the barrel;
    - the hammer spur a flat slab;
    - the muzzle a plain tube end-on.
  - The rest are the street's: identical pebbles, twin horses, the backdrop's squares.

## Sean's second review (2026-11-09): four steps, each judged in game light

"It still doesn't read as real, and another paint run isn't the fix." Each step's side and
three-quarter views are under the real look on Main Street at 16:00, with the game's sky to reflect
(`saa_views.gd --only=side,threeq`; `sheets.py VIEWS SHEET.jpg`). In `results/2026-11-09_review2/`:

1. **Shape, against the photos** (`step1_overlay.jpg`, `step1_diff.jpg`, `step1_side_by_side.jpg`,
   `step1_views.jpg`). Two things made the box and the fin:
   - **The box:** the side plate ran up over the recoil shield.
   - **The fin:** the hammer's front stood up as a second prong beside the spur.

   The Smithsonian's three-quarter photos (CC0, looked at) show the real arrangement:
   - **Recoil shield:** a near half-ellipsoid dome (`dome_profile`: 0.80" radius, 0.62" deep)
     bulging past the frame's flat sides.
   - **Side plate:** cut back to below and behind the dome.
   - **Ears:** behind the top strap, two thin ears either side of the hammer slot carry the Met
     gun's measured top line.
   - **Hammer:** its front sits low inside the ears, so only the slim spur rises (0.23" across,
     was 0.33").
   - **Strap and edges:** the strap is narrowed to 0.48", and the frame's edges rounded (0.045").

   Overlap with the Met gun's silhouette stays at 0.951.
2. **Metal as metal** (`step2_metal.jpg`). Metallic 1, with the base colour the metal's own
   reflectance:
   - **Bluing:** a dark blue-grey that still mirrors (0.17–0.25, roughness 0.16–0.18);
   - **Case colours:** 0.40 at roughness 0.22;
   - **Walnut:** a dielectric at 0.40;
   - **Rounds:** brass, lead and copper as metals.

   The game's sky is the reflection (its environment reflects the sky shader).
3. **UVs and the grip's outline** (`step3_uv_checker.jpg`):
   - **The stripes:** the bluing painting repeating every 70 mm along the barrel.
   - **The fix:** the metal finishes are now made from 3D noise in each part's own space, so nothing
     stretches or repeats.
   - **The atlas:** smart-projected at 45° (under 8% stretch across a strip). A checker baked
     through it is square and even on every part.
   - **The straps:** thin metal, 0.06" deep (were 0.13" and 0.12"); the butt 0.06".
4. **The surfaces** (`step4_surfaces.jpg`), in `saa_paint.py`; no paid call:
   - **Case hardening:** fine swirls (two layers of distorted noise, ~3–8 mm) of blue and violet
     with thin straw bands on a dark steel base. Round 4a read as rust spots, so straw was thinned.
   - **Bluing:** deep blue-black with fine polish lines along the gun and slow unevenness; edges worn
     to bare steel, browned where thin.
   - **Walnut:** the walnut painting by box projection, its seams blended.
   - **Wear and grime:** as before.

## Sean's third review (2026-11-09)

"The metal reads as metal now. Keep the subtle case colours." In `results/2026-11-09_review3/`:
- `four_views.jpg`: the side and three-quarter views in game light.
- `sunlit_sides.jpg`: each side of the gun turned to the sun.

1. **The ears were horns:** the frame's sides behind the strap stood up beside the hammer. The Met
   photo shows the strap running level back to the hammer, the hammer's own top falling from strap
   height to the spur's root, and the frame's sides a band below that.
   - The ears now sit under the hammer's top line.
   - The hammer's top front is back at strap height (0.44) and falls smoothly into the spur.
   - The spur's tip is at strap height (0.46–0.50).
   - Overlap with the Met gun's silhouette: 0.951.
2. **The dark grip panel:** it was the shadow side. Turned to the sun (`saa_views.gd --only=sunlit`),
   each panel is walnut brown with grain. Wood doesn't mirror the sky the way the steel does, so in
   shade it goes dark. No change.
3. **The guard read as wire:** its bow is now a flat strap, 0.32" across by 0.11" thick. The section
   is a superellipse (`sweep(..., square=6)`), blued.

## Sean's fourth review (2026-11-09): the spur

"The horn is still there... the 0.951 is whole-gun overlap; the hammer is a few pixels of it."
The hammer is judged on its own now: `overlay.py --crop=0.3,-2.0,-0.9,0.75` (the hammer and the
frame's back, design inches) gives photo | render | outline over the photo and the crop's own
overlap. `--plain=1 --crop=` does the same for the game's render. In `results/2026-11-09_review4/`:
- `hammer_crop_before.jpg`, `hammer_crop.jpg`, `hammer_crop_game_light.jpg`;
- `spur_before_after.jpg` (the three-quarter view, cropped);
- `four_views.jpg`.

The outline was never the fault: the crop's overlap was 0.956 before and after. The 3D shape was.
- **Before:** a flat plate the same thin width all the way up, its top-back point kept as a hard
  corner. From three-quarter angles that read as a horn.
- **Now:**
  - **Outline:** the spur's outline is the Met gun's, its end blunt and round (no corners).
  - **Thumb rest:** along its top, a broad crowned thumb rest swept as a rounded strap, 0.42"
    across against the spur's 0.20". It flares out past the spur's sides and leans back toward the
    grip.
  - **Checkering:** the pad keeps its own material through the union (`boolean(..., transfer=True)`,
    `saa_checker`). The bake cuts a 1.2 mm diamond knurl into it. Close up it shows; at the game
    views' distance it's faint, dark on dark.

**Approved** (Sean, 2026-11-10): "the spur reads as a thumb rest now, close enough. Leave the shape."
For later, not now: the checkering a touch lighter in the next surfaces pass; Sean judges it in first
person, in the hand. The Winchester (#734) copies this method (script from real dimensions, the photo
overlay with per-part crops, game-light views, then paint).

## Results

`results/2026-11-09/` (round 1, placeholder materials, 7½", Main Street at 16:00, real look):

- `turntable.jpg`, `turntable.mp4`: 24 steps of 15°.
- `close.jpg`: right, left, muzzle, hammer from above, loading (half cock, gate open, a spent case
  on the ejector), cocked, down the sights (`fp_sights.jpg`: at full cock the front blade's top
  sits in the rear groove's bottom, as on the Colt, whose hammer hides the groove at rest).
- `mech.jpg`: rest, safety, half, half→full with the cylinder turning, full, fired, gate, eject.
- `cheap_judge/`: the cheap judge (`critic.py cheap`, with the Studio's AAA references read in
  place) on the five close shots, a fresh agent told only that the gun is held in the air on
  purpose. **All five cheap indie**, ranked d, a, c, e, b. The gun's reasons: placeholder materials
  (flat beige frame, plastic-black cylinder, blue-dot screws, a grip with no grain), a blown sun
  highlight on the barrel and cylinder (roughness 0.30), and the shape: "the hammer spur a big
  horn, the guard a thin wire, the frame a slab, the cylinder big against the frame". The rest is
  the street's (pebbles alike, the canyon backdrop's squares, twin horses).

Sean's review of round 1's side view (2026-11-09): "the shapes aren't a Single Action Army yet" (the
grip, hammer, cylinder and frame, guard, ejector, front sight): refitted to the Met gun (above).
