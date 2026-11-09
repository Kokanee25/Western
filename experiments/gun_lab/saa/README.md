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

## The dimensions

Inches; f along the bore from the cylinder's rear face, u up from the bore's axis.

| What | Value | Source |
|---|---|---|
| Barrel lengths | 7½" Cavalry (built first), 5½" Artillery, 4¾" Civilian; `--barrel=` | Wikipedia, "Colt Single Action Army" |
| Overall length | 11" with the 5½" (279 mm); 12½–13" with the 7½" | Wikipedia; Gunsopedia; dealers' listings |
| Height, width | 137 mm, 38 mm (a third party's measured model) | Sketchfab, "Colt SAA" disassembly model's listing |
| Weight | 2.31 lb with the 7½" (not used: no density yet) | Wikipedia |
| Cylinder length | 1.608" | The Firing Line forum, SAA blueprints thread |
| .45 Colt cartridge | bullet .454", case 1.285", rim .512" × .060", mouth .480", overall 1.600" | the cartridge's published (SAAMI) dimensions |
| Bore | .445" lands, .454" grooves, six grooves | as the cartridge |
| Cylinder diameter 1.650", chambers on a .520" circle | est. | sized round the chamber walls and the bolt notches; the bore over the top chamber |
| Barrel OD .700" at the frame, .686" at the muzzle | est. | |
| Frame front .555" ahead of the cylinder, top strap .33–.52" over the bore, frame bottom −1.56" | est. | fitted to the cylinder and the height |
| Grip: plow handle, toe −4.64", heel −3.30" behind the cylinder face | est. | fitted to the height and overall length above |
| Ejector housing 4.10" long, rod .22", stroke 1.78" | est. | the stroke clears a case from a 1.608" chamber |
| Loading gate at 70° clockwise from the top (seen from behind) | est. | where the ejector rod meets the barrel's side |

The model against the published sizes: overall length 12.4" with the 7½" (0.315 m; 13" quoted,
12½" by some), height 5.5" with the hammer down (5.4" measured on a 5½" by the third party), width
1.72" at the ejector head (the cylinder 1.65"). **Estimates are marked est.:** the travel numbers too
(hammer notches 9/21/47°, trigger 3–6°, gate 95°) in the rig file. A Colt in the hand or a measured
drawing would settle them; none was found free online.

## The surfaces (waiting on Sean: no paid call made)

The parts carry placeholder materials (`saa_case`, `saa_blued`, `saa_fire_blue`, `saa_bright`,
`saa_walnut`, `saa_bore`, `saa_brass`, `saa_lead`, `saa_primer`) and box-projected UVs, a tile every
40 mm, so tiling surfaces drop straight on. The proposal is in #693.

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

What's off in the shape, from these and the judge (for the next round, after Sean's word): the
spur too tall and hooked; the guard's bow thin; the frame's sides flat slabs (no swell at the
recoil shield's back, no flats and radii where the frame steps); the gate reads as a short round
boss; the backstrap's top a squared fin from above; the walnut's top shows behind the hammer from
the shooter's eye.
