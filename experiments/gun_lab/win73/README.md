# The Winchester Model 1873, built by script (#734 step 1)

Sean, 2026-11-09 (#734): the next gun, made the way the Colt was (`../saa/README.md`): a Blender
script from the real gun's dimensions, fitted to a real side photo part by part, shown in the game's
own light, painted only after Sean OKs the shape. **Nothing in the game changes in this step:** no
viewmodel, no arms, no game gun uses it. No maker's name, logo or stamping (the gun lab's rule).

```sh
python3.11 -m venv ~/bpyenv && ~/bpyenv/bin/pip install bpy==5.0.1 scipy   # Blender as a Python module
~/bpyenv/bin/python experiments/gun_lab/win73/win73_blender.py [--barrel=24|20] [--out=DIR] \
    [--preview=DIR --views=right,left,front34,rear34,top,under34,action_rear34,action_front34,action_left34,spur_top]
godot --headless --import
xvfb-run -a -s "-screen 0 1600x900x24" godot --path . --rendering-driver vulkan --resolution 1600x900 \
    -s res://experiments/gun_lab/win73/win73_views.gd -- --real --out=build/win73/views [--only=turntable,side,threeq,sunlit,close,mech]
python3 experiments/gun_lab/saa/sheets.py build/win73/views DIR      # the Colt's sheets script reads these views too
```

The build is ~8 s. The views need the native plugin built (`cargo build --release` in
`addons/saltcreek_native`, the `.so` into its `bin/`) and lavapipe (`mesa-vulkan-drivers`, xvfb):
~10 min to load the street under the real look, then ~50 s a pose.

## In the game (#777, step 2)

The 24" rifle's glb, its four jpgs and its rig json are the game's now: **`assets/weapons/win73_24.*`**
(`win73_views.gd` loads the 24" from there; a rebuild by `win73_blender.py`/`win73_paint.py` writes here,
so copy the glb, jpgs and json over the game's after one, and re-import). `win73_rig.gd`'s logic is
`Winchester73Model` (src/weapons); the gun in your hands is `Winchester73Viewmodel` (key 6) with
`Winchester73State` and `config/winchester73.tres` (`Winchester73Tuning`, every number proposed). The
feel numbers are in `tests/test_gun_feel.gd` (`winchester_*` in `config/feel_ranges.json`), the rules in
`tests/test_winchester.gd`. LAYOUT.md "src/weapons" has how it works.

What the step measured (`test_gun_feel.gd`, at 60 fps; proposed ranges):

| | measured | range |
|---|---|---|
| hip to the first shot down the sights | 0.37 s | 0.3-0.8 |
| shot to shot, the lever as fast as a hand works it | 0.52 s | 0.35-0.9 |
| a round through the gate | 0.82 s (the turn to the gate once in five) | 0.5-1.2 |
| the rope at 30 m, steady / rushed | 9 / 5 of 10 touch it | 0.6-1 / 0.1-0.6 |
| the rope at 60 m, steady / rushed | 7 / 3 of 10 | 0.3-0.8 / 0-0.4 |

The rope (`HangingRope`): 3/4" manila, a man's weight on it, hung from a roof's height 30 and 60 m off,
2.5 m below your eye. Steady: shouldered, settled 1.5 s, the trigger squeezed as the blade sits on the
rope (the shot breaks 0.1 s after). Rushed: winded from a run, fired as the blade first crosses it
once it's up. A hit is the ball touching it: one through its middle parts it, a graze frays it and a
second at the same place parts it. The first run hit nothing at 60 m (3 cm RMS misses): the shouldered
shake went 0.45 -> 0.3 of the revolver's and the rifle's cone 0.025 -> 0.02 degrees (2.4 MOA).

## Files

- `win73_blender.py`: the gun. Out: `win73_<barrel>.glb` (one node a part, its origin on its pivot) and
  `win73_<barrel>_rig.json` (pivots, axes, travel, markers; Godot space, metres). The mesh helpers
  (prism, lathe, sweep, the boolean that guards and retries, bevel, box UVs) are the Colt's, copied.
- `win73_rig.gd`: drives the parts from the rig file: `lever(t, closing)` (the bolt back on the toggle's
  curve, the hammer cocked in the first 45% and held, the carrier up in the last 30% of the opening and
  down in the last 15% of the closing), `hammer("rest"|"half"|"full"|deg)`, `trigger(pull)`, `fire()`,
  `cover(open)`, `gate(push)`, `carrier(up)`, and what each place holds: `chamber()`, `carrier_round()`,
  `tube_round()` (`"loaded"|"spent"|"empty"`).
- `win73_views.gd`: the gun over Main Street's road at 16:00 under the real look, a camera of its own:
  a 24-step turntable, the straight sides (with the bore's two points in json for `overlay.py --plain`),
  three-quarters, each side turned to the sun, close shots, the mechanism strip.
- `photo_mask.py`: the reference photo's rifle cut from its wood ground (the mask the overlap is
  measured on).
- `overlay.py`: the Colt's, adapted: the side render over the photo at the same scale from two points on
  the bore; `--crop=f0,f1,u0,u1` judges one part on its own; `--profile=f,...` prints the silhouette's
  top and bottom at each f in the photo and the render (how the outlines were fitted, in numbers).

## The parts

Each its own node under `Win73`, origin on its pivot:

| Part | Moves | Finish (placeholder now) |
|---|---|---|
| `Receiver` (front ring round the barrel and tube, side plates with their seams, the gate's window, the port, the hammer's slot, the dust cover's rail, upper and lower tangs following the wrist's round) | no | blued |
| `Barrel` (octagon, 1.00" across the flats at the receiver to 0.88" at the muzzle; shank, chamber, rim recess, six-groove bore, crowned) | no | blued |
| `MagTube` (under the barrel, its slotted plug at the front, open at the rear for the rounds) | no | blued |
| `Lever` (front loop round the trigger, long rear loop for the fingers, tongue up into the frame) | about its pin, 52° (est.) | case colours |
| `Hammer` (body to its low screw, the spur rising and curling back to a blunt round tip) | rest, half 13°, full 34° (est.) | case colours |
| `Trigger` | about its pin, pull −8° (est.) | case colours |
| `Bolt` (firing pin out of its back, extractor on top) | back 1.85" (est.) | in the white |
| `Carrier` (block with the round's trough) | straight up 0.75": the tube's line to the bore's | in the white |
| `DustCover` (curved plate over the port, ridged grip at its back) | back 1.45" (est.) | blued |
| `Gate` (the spring cover in the right side plate, a dimple to press) | in 16° about its front (est.) | blued |
| `RearSight` (buckhorn: base, elevator, horns round a V notch), `FrontSight` (blade on a dovetail base) | no | blued |
| `Forend` (walnut, wraps the tube and the barrel's lower flats), `ForendCap` (tapers to the tube), `MagBand` | no | walnut, blued |
| `Buttstock` (walnut), `Buttplate` (crescent, heel and toe horns) | no | walnut, blued |
| `Screw_*` (hammer and lever pins with their ends on the left, side plate ×2, spring, tangs ×2, forend cap, band, butt ×2) | no | fire blue |
| `CaseChamber`/`BulletChamber`; `CaseCarrier`/`BulletCarrier` (children of the carrier); `CaseTube`/`BulletTube` (the tube's first, child of the tube) | shown loaded / spent / empty | brass, lead |

Markers (empties): `Muzzle`, `ReceiverFront`, `BoreBreech`, `SightRear` (the notch's bottom),
`SightFront` (the blade's top), `Wrist`, `TriggerFace`, `Forend` (the left hand's place), `GatePoint`,
`Port`, `Butt`; `HammerSpur` on the hammer, `LeverLoop` on the lever. ~64,000 triangles (a game LOD
is for the step that puts it in the hand).

Not modelled (inside): the links, the mainspring, the springs, the sear, the follower and spring in the
tube. Not on this gun: the photo's tang sight (an accessory, cut out of the mask) and its folding leaf
rear sight (the brief asks for the buckhorn).

## The barrel: the 24" rifle

The lab builds both (`--barrel=24|20`) and picks **the 24" rifle**:
- **The rope shot:** the story's shot is a rope at 30–60 m from an elevated spot; the rifle's sight
  radius is ~20" against the carbine's ~15", so the same wobble in the hold moves the point of aim
  less, and the extra weight out front steadies it. That's the shot the brief says the sights make
  possible.
- **The magazine:** 15 rounds to the carbine's 12.
- **The reference:** the only good CC0 side photo found is a rifle, so the rifle's shape is the one
  measured; the carbine is the same receiver with a round 20" barrel, not fitted to a photo, and
  without its own furniture (barrel bands, saddle ring, carbine butt).
- **Against it:** 43" is long in first person (the carbine's 39" swings quicker and fits a saddle
  scabbard). If the first-person step finds the rifle unwieldy, the carbine's furniture is a short job.

## The reference

**`docs/concept/guns/ref/w73_hmaag_right.jpg`** (Wikimedia Commons, "Winchester 1873 Rifle", by Hmaag,
CC0; its source in that folder's `SOURCES.md`): the right side, nearly straight on, on a plain wood
table. The Met and the Smithsonian's hosts are blocked from this workspace, so Commons was searched:
of its 1873s this is the only CC0/public-domain side-on photo of a whole rifle (the others are CC BY-SA,
in cases, or close-ups).

```sh
~/bpyenv/bin/python experiments/gun_lab/win73/photo_mask.py docs/concept/guns/ref/w73_hmaag_right.jpg build/win73/mask.png
~/bpyenv/bin/python experiments/gun_lab/win73/win73_blender.py --preview=build/win73/ov/f --views=right --px=2400 --alpha=1
python3 experiments/gun_lab/win73/overlay.py docs/concept/guns/ref/w73_hmaag_right.jpg build/win73/ov/f/right.png OUT \
    --points=1834,180.1,26.25:852,169.0,2.25 --mask=build/win73/mask.png [--crop=f0,f1,u0,u1] [--profile=f,f,...]
```

- **The scale:** `--points` are the muzzle and the receiver's front face on the bore's axis
  (photo pixels, then design inches). Collectors measure an antique Winchester's barrel from the
  receiver's front face, and with that the photo agrees with the published 24" barrel and 43¼"
  overall at one scale, 40.92 px an inch: 24" from the receiver to the muzzle, 19¼" from it back to the
  butt, and the bore-to-tube spacing the right size for a 0.60" tube.
- **The breech:** the barrel's breech face sits at the side plate's front edge, 2.25" behind the
  receiver's face (the carrier, the gate and the tube's mouth all meet there), so in design space the
  muzzle is at f 26.25.
- **The outlines:** every outline was read off the photo straightened along the bore, then fitted by
  `--profile`: the receiver's top, rear and lower edges, the side plate's seam, the gate, the hammer
  and its spur, the trigger, both lever loops, the tangs and wrist, the comb and belly, the crescent,
  the forend and its tapering cap, the band, the sights.

**Overlap** (intersection over union of the two silhouettes; `results/2026-11-10_overlay/`):

| | first fit | now |
|---|---|---|
| whole gun | 0.930 | **0.961** |
| receiver (f −3.6 to 2.8) | | 0.968 |
| action (receiver's rear, hammer, lever, trigger, wrist) | 0.858 | 0.939 |
| hammer | | 0.875 |
| lever | | 0.904 |
| butt and crescent | | 0.967 |
| forend cap | | 0.965 |
| muzzle, band, tube's plug | | 0.970 |
| front sight | | 0.962 |
| rear sight | | 0.785 (a different sight: the photo's is a raised folding leaf) |

What's left:
- **The hammer's crop:** the photo's spur is a touch fuller at its root, and the receiver's rear edge
  behind it is soft in the photo.
- **The lever's crop:** the mask's edge on the case-coloured steel, which is close in colour to the
  table.
- **Not in the overlap, by eye:** the shape across the gun is estimated (no top view), and the three
  close three-quarter stills (`shape_action_blender.jpg`) were checked for the Colt's fault, an
  outline right side-on but wrong in 3D:
  - **The tangs:** they stood out of the wrist's round wood as flat fins. They're now cut to the
    stock's own outside.
  - **The spur:** a rounded strap tapering to a ball tip, no flat plate.

`results/2026-11-10_overlay/`:
- `whole_overlay.jpg` (the render's outline in red over the photo), `whole_side.jpg` (side by side,
  the same scale and crop), `whole_diff.jpg` (red: the photo's gun only; blue: the render's only) and
  `first_fit_diff.jpg`;
- `crops.jpg`: every part's crop, photo | render | outline over the photo, with its own overlap;
- `shape_action_blender.jpg`: the action's three-quarters and the spur from above (grey studio light:
  the shape only).

## The dimensions

Inches; f along the bore from the breech face, u up from the bore's axis. Sources:
- **Published:** the gun's and the cartridge's published figures. The online references
  (Wikipedia) can't be reached from this workspace, so these are the long-standing catalogue figures,
  not re-checked here.
- **Photo:** measured off the reference at 40.92 px an inch (±0.03").
- **Est.:** estimated from the mechanism's geometry.

| What | Value | Source |
|---|---|---|
| Barrel | 24" rifle (octagon), 20" carbine (round), from the receiver's face | published (the gun) |
| Overall | 43¼" with the 24" | published; the model 43.3" |
| Magazine | 15 rounds (rifle), 12 (carbine) | published |
| .44-40 cartridge | bullet .429", neck .443", base .471", rim .525" × .065", case 1.305", overall 1.592" | published: Wikipedia, ".44-40 Winchester" (its infobox), checked 2026-11-10 |
| Bore | .417" lands (est.), .429" grooves, six grooves | as the cartridge |
| Octagon barrel | 1.00" across the flats at the receiver, 0.88" at the muzzle | photo |
| Magazine tube | 0.60" across, its axis 0.75" under the bore | photo |
| Receiver | 2.25" ahead of the breech to its face; top 0.55" over the bore, the front section's bottom 1.56" under; the frame's rear and the tangs | photo |
| Side plate, loading gate (1.31" long, 0.60" tall, its centre 0.86" under the bore) | | photo |
| Hammer screw (−4.37, −1.90), lever pin (−2.00, −1.89), side plate screws | | photo |
| Lever: the front loop to 3.68" under the bore, the rear loop's end 6.8" behind the breech | | photo |
| Stock: the comb, belly and crescent (heel to toe 4.3", hollow 0.6"); length of pull ~12.7" | | photo |
| Forend to 11.85", its cap to 12.7", the band 4" from the muzzle, the rear sight's place 4.95", the front blade 1.15" from the muzzle, 0.62" over the bore | | photo |
| Widths across: the receiver 1.12", the wrist 1.12", the butt 1.56", the forend 1.0", the lever 0.32", the hammer 0.30" | | est. (no top view) |
| The buckhorn: 0.90" across the horns, its notch 0.72" over the bore | | est. (a buckhorn's usual shape; the photo's sight is a leaf) |
| Travel: the lever's 52°, the bolt's 1.85", the carrier's 0.75" (= the tube's drop, measured), the hammer's 13°/34°, the cover's 1.45", the gate's 16° | | est. |

## The surfaces (Sean's A on #767, 2026-11-10)

"Do the surfaces the way the Colt's were done (generated in Blender, no paid call, metal that reflects
the game's sky), with the finishes taken from period references, not memory." `win73_paint.py` (~6 min
at 2048): the Colt's recipes (`../saa/saa_paint.py`, copied):
- **Metals:** made from 3D noise in each part's own space, so nothing stretches along 43".
- **Walnut:** the Colt's free walnut painting (`../saa/surfaces/raw/walnut_1.jpg`), cut seamless here,
  by box projection.
- **Wear and grime:** edges rubbed to bare steel, hollows dark and duller.
- **Atlases:** two, each albedo + ORM: the action's parts (seen close in first person) and the long ones.
- **Metal as metal:** metallic 1, mirroring the game's sky.
- **The hammer's spur:** checkered, a 1.0 mm knurl, a touch lighter than the Colt's (Sean's note).

**The barrel (Sean's first note):**
- The photo's rifle has an octagonal barrel: its flats show at the muzzle and along it, 1.00" across at
  the receiver to 0.88" at the muzzle.
- The model was built octagonal from the start, so nothing changed.
- Wikipedia's "Winchester rifle" lists octagonal barrels among what Winchester made to order. Round was
  the plainer catalogue barrel, and octagon the iconic one: this gun's.

**The finishes and their evidence.** The written period sources are mostly out of reach here:
- the Met, the Smithsonian (it refuses automated requests), the Library of Congress, HathiTrust and
  Google Books are blocked;
- the Internet Archive's catalogue scans sit on storage hosts that are blocked;
- Rock Island Auction's lot pages sit behind a bot check.

What was reachable: Wikipedia, and photographs of original 1873s on Commons.

| Part | Finish | Evidence |
|---|---|---|
| Receiver, side plates | blued | Wikipedia, "Winchester rifle", Model 1873: colour case-hardened receivers were among what Winchester made to order, so the standard receiver was blued. The reference rifle's receiver is blued, worn to grey at the edges. |
| Barrel, magazine tube, forend cap, band | blued | the reference rifle (blue-black); the Buffalo Bill Center of the West's 1873 carbine on Commons (Gabon100's photos): its barrel blued |
| Loading gate | blued | the same carbine: its gate blued even on a plated, engraved gun; the reference rifle's matches its receiver |
| Dust cover | blued | the reference rifle's matches its receiver |
| Buttplate | blued | the reference rifle's crescent plate is grey-blue like its worn receiver, not warm like its lever |
| Hammer, lever, trigger | colour case-hardened, faded | **weakest:** the reference rifle's lever and hammer are a warmer grey-brown than its blued receiver, as faded case colours go; at the photo's 41 px an inch they're too thin to measure cleanly. No text source was reachable. |
| Stock and forend | plain walnut, oiled | Wikipedia, "Lever action": "fancy walnut stocks" marked the One of One Thousand grade, so the standard was plain; the Koblenz military collection's original carbine (Commons): red-brown walnut, low sheen, dark stains |
| Bolt, carrier | steel in the white | **not found:** inside the action, seen only with it open |
| Screws | fire blue | **not found** (as the Colt's) |

**Also checked:** Wikipedia's ".44-40 Winchester" confirms the cartridge figures used in "The
dimensions", except the bullet: .429" there, against the .427" used; .429" now.

### The paint rounds, judged in game light and first person

```sh
~/bpyenv/bin/python experiments/gun_lab/win73/win73_paint.py      # ~6 min; writes the glb, the rig json, surfaces/*.png
godot --headless --import
xvfb-run ... win73_views.gd -- --real --out=build/win73/views --only=turntable,side,threeq,sunlit,fp,close,mech
```

`win73_views.gd --only=fp` is first person in the hands: the rifle under the lab's camera at the
game's field of view (75°, 62° aiming), held by two of the game's own `HeldHand`s (the painted
Studio arms the coach gun is held in, used, not changed): the right round the wrist, the left under
the forend. Three holds (shouldered, the low ready, the action turned to you), each with the sun
behind you and to your right.

**Round 1:** fixed in game light:
- **The seams:** the side plates' seams wore bright both sides and read as a dotted white line. Wear
  now stops inside hollows (by the ambient occlusion).

**Round 3:** the cheap judge (`results/2026-11-10_painted/cheap_judge/`, blind, with the AAA
references read in place):
- **Verdicts:** one good indie (the action from behind, in sun), four cheap indie.
- **The rifle's own faults:**
  - the bluing too clean and too blue (royal blue in close-up);
  - little wear;
  - the walnut near black in shade.
- **The rest:** the street's (the posterised sky, cloned grass, faceted rocks) and the placeholder
  hands'.

**Round 4:** each of the rifle's faults fixed from the reference rifle, not by taste:
- **Bluing:** blue-black, near neutral; the reference's aged bluing measures RGB 38/38/35 on the
  receiver and 30/27/30 on the barrel.
- **Patina:** the bluing thinned in broad patches toward grey-brown, as the reference's receiver is.
- **Case colours:** the hammer, lever and trigger faded to a warm grey-brown, as the reference's are.
- **Wear:** the edges wear wider.
- **Walnut:** mid brown.

**Round 5:** the white blob on the receiver's front corner (rounds 1–4).
- **What it wasn't:** it didn't move with roughness. The exported normals are clean (read from the
  glb).
- **What it was:** the sun, behind the camera, mirrored in a sliver of the barrel's flat end face,
  peeping over the receiver's rounded front.
- **The fix:**
  - the receiver's top met the barrel's at 0.50"; the photo's profile has the front collar standing
    to 0.60" from f 1.8, fitted now;
  - the barrel starts 0.4" inside the receiver;
  - zero-area slivers from the booleans are dissolved (64k → 49k triangles);
  - overlap unchanged at 0.961.

`results/2026-11-10_painted_final/` (round 5):
- `turntable.mp4`/`.jpg`;
- `game_light.jpg`: three-quarters, whole, each side turned to the sun, the lever thrown;
- `close.jpg`, `mech.jpg`, `fp_sights.jpg`;
- `first_person.jpg` (and each hold alone);
- `side_by_side_real_look.jpg`, `action_side_by_side_real_look.jpg`: the game's side render beside
  the photo at its scale;
- `evidence_reference_rifle.jpg` is in round 3's folder;
- `cheap_judge/`: the second verdict on the same five shots:
  - **All five cheap indie** (round 3: one good indie, four cheap; the judge varies run to run).
  - **The rifle's faults it still names:**
    - the side plates' seams pale like stitching;
    - the screws too saturated a blue;
    - a mirror streak on the lever's inner edge;
    - no wear visible on the side in shade;
    - the walnut near black in shade.
  - **The rest:** the street's (the posterised sky, cloned grass, faceted rocks and pebbles, the
    canyon backdrop) and the placeholder hands'.

**Known, left for Sean's look:**
- **The shouldered hold:** the arms are placed by the coach gun's rules, not fitted to this rifle, so
  both come in over the action. The view down the sights works: `fp_sights` shows the front blade in
  the buckhorn's notch.
- **The barrel's glint:** in full sun the octagon's top edge throws a long glint (real geometry, not a
  broken face).
- **The checkering:** the hammer spur's is faint at the game's distances.

## Game light

`results/2026-11-10_views/` (placeholder materials, the 24" rifle, over Main Street's road at 16:00
under the real look, the game's sky to reflect; `win73_views.gd`, ~65 min here):
- `turntable.jpg`, `turntable.mp4`: 24 steps of 15°;
- `four_views.jpg`: both straight sides, the action's three-quarters (from behind on the left, from in
  front on the right), the whole gun three-quarter, each side turned to the sun, down the sights;
- `close.jpg`: right, left, the muzzle (octagon, crown, the tube's plug), the hammer from above, the
  gate pressed; `close_open.jpg` (the lever thrown, the cover back); `fp_sights.jpg` (the front blade's
  top in the buckhorn's notch);
- `mech.jpg`: rest, half cock, the lever at 35, 70 and 100% (the bolt out over the wrist, the hammer
  cocked), closing at 50%, closed and cocked, fired, the cover back, the gate in;
- `side_by_side_real_look.jpg` and `action_crop_real_look.jpg` (`overlay.py --plain`, the game's side
  render put to the photo's scale by where the muzzle and the receiver's front landed): the screws, both
  loops, the hammer and the frame's rear land within a few pixels of the photo's.

Found in game light and fixed:
- **The receiver's streaks:** the first run showed dark diagonal streaks across its flat sides. Their
  corner normals were shared with the bevels: 1,584 of 1,617 were bent more than 5°.
- **The fix:** normals weighted by face area (`finish()`), on every part; now none are bent.

Left for the surfaces pass (Sean's word first), as the Colt's first round was:
- the bluing reads too clean, near chrome, with a hard sun glint on the barrel;
- the lever and hammer are flat pale grey (the case colours to come);
- the walnut is flat orange in the sun and near black in shade.
