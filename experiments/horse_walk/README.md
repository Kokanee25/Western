# The horse's walk (an experiment)

One convincing walk on the game's horse, made in Blender from real footage and the published
gait, as the reference for the game's later procedural gait (issue #470, brief `docs/briefs/horse.md`).
**Nothing in the game changes:** `assets/creatures/horse/`, `tools/blender/horse.py` and
`src/creatures/` are only read. Everything here works on its own copy of the horse.

Films: `films/walk_side.mp4|.gif` (from his left, a little above, 3 strides at 30 fps, the ground
chequered in 25 cm squares so a sliding hoof would show) and `films/walk_threeq.mp4|.gif`. Matched
pairs against the clip: `compare/pairs_sheet.jpg` and `compare/pair_*.jpg`; one stride of the side
film as a contact sheet beside the clip's: `films/walk_side_sheet.jpg` (`film_sheet.py`).

## How to run it

```sh
python3.11 -m venv ~/bpyenv && ~/bpyenv/bin/pip install bpy==5.0.1 "numpy<2" pillow scipy
python3.11 -m venv ~/cvenv && ~/cvenv/bin/pip install opencv-python-headless numpy pillow   # kept apart: it needs numpy 2, bpy needs 1
mkdir -p build/horse_walk/ref build/horse_walk/frames                                      # the clip (Sean attaches it) to build/horse_walk/ref/clip.mov
ffmpeg -i build/horse_walk/ref/clip.mov -vsync 0 build/horse_walk/frames/f%03d.png

# the reference
python3 experiments/horse_walk/pan.py                      # the camera's pan, from the ground
~/cvenv/bin/python experiments/horse_walk/legmask.py       # legs by colour, laid on the ground: the space-time picture
python3 experiments/horse_walk/contacts.py                 # stances found in it
~/cvenv/bin/python experiments/horse_walk/speed.py         # his speed over the ground
python3 experiments/horse_walk/sheet.py --frames=90,136,2  # contact sheets, to check by eye
python3 experiments/horse_walk/slit.py --clean=5           # the first space-time picture (by darkness; legmask.py's is cleaner)

# the walk (Cycles on the CPU; ~1.5 s a still, ~5 s a film frame)
~/bpyenv/bin/python experiments/horse_walk/blender/rig_check.py          # the rig, bones drawn on
~/bpyenv/bin/python experiments/horse_walk/blender/bend_test.py [-- --fix]  # every near joint flexed
~/bpyenv/bin/python experiments/horse_walk/blender/walk_build.py         # the walk: build/horse_walk/walk.blend, walk.glb, walk_report.json
~/bpyenv/bin/python experiments/horse_walk/blender/render.py -- --phases=0,0.12,0.30,0.5,0.62,0.61,0.80,0.92 --name=pairs   # compare.py's EVENTS
python3 experiments/horse_walk/compare.py                  # the matched pairs (reference/crops/ without the clip)
./experiments/horse_walk/make_films.sh                     # the films
python3 experiments/horse_walk/film_sheet.py               # one stride of the side film, as the clip's sheet
# try a number without editing: walk_build.py -- --tag=try --set=hock_fold=50,lift.H=0.11 (walk_try.blend,
# walk_report_try.json; render.py -- --tag=try); --no-fore leaves the fores' game weights;
# render.py -- --phases=0.25,0.92 --cam=shoulder: close on the near fore's shoulder
```

## 1. The reference clip

Pexels, "Video of a walking horse" (credited in `CREDITS.md`; the clip itself isn't in the repo,
only crops). 13.9 s, 30 fps, 970×512: a saddled chestnut walking left to right along a ridge, his
left side to the camera, which pans with him for ~2 s and then holds.

**How it was measured** (all numbers in `reference/measurements.json`):
- **The pan** (`pan.py`): phase correlation between consecutive frames on a strip of ground. It's a
  pure pan (the hills and the ground shift alike), −1.1 px a frame for 2 s, then ~0.
- **The legs on the ground** (`legmask.py`): a pixel is leg when it's red-brown (R/G > 1.55) or near
  black (the hooves); each frame's hoof band (rows 452–492) is laid on the ground's columns. Stacked
  a frame a row, that's a gait diagram (`reference/gait_diagram.png`): a planted hoof is a vertical
  bar, a swing a thin slanting line.
- **Stances** (`contacts.py`): runs in each ground column, joined across neighbouring columns.
  Checked by eye against the diagram; where a swing crosses a planted hoof, the run splits in two and
  was joined by hand (the README's numbers are the joined ones).
- **Which leg is which:** by occlusion where one leg passes the other (`build/horse_walk/occl.jpg`):
  the planted hind with the white heel is drawn over the swinging one, so it's the near (left) hind;
  the same for the fores.

**What it shows** (the clean stride, frames 106–232; `reference/stride_sheet.jpg`):

| | the clip | the literature | ours |
|---|---|---|---|
| footfall order | LH 106, LF 135, RH 144, RF 172, LH 185 | lateral sequence LH, LF, RH, RF | LH 0, LF 0.30, RH 0.5, RF 0.80 |
| stride | ~80 frames = 2.7 s **at the clip's rate** | 1.0–1.3 s at a working walk | 1.1 s |
| duty factor | 0.60–0.69, mean 0.67 | 0.60–0.65 | 0.62 set; 0.66–0.67 read off the toes (5 mm) |
| LH → LF (share of the stride) | 0.31–0.37, mean 0.33 | 0.25 (evenly spaced) | 0.30 |
| stride length / speed | 145 px ≈ 1.34 m; ≈0.47 m/s at the clip's rate | 1.5–1.9 m; 1.4–1.8 m/s | 1.5 m; 1.36 m/s |
| hoof lift in swing | ~8–12 cm (by eye) | low at a walk | toe 7 cm |

**The clip is slowed.** A stride of 2.7 s at 0.47 m/s isn't a walk any horse keeps. Stock footage is
often shot at 60 fps and played at 30; at 2× the stride is 1.33 s at 0.94 m/s, at 2.5× 1.07 s.
Either is a slow, relaxed walk. The clip can't say which, so **the timing comes from the literature**;
from the clip come only the shares (duty factor, phase), the order and the poses.

**Where the clip and the literature disagree:** the clip's left fore lands 0.33 of a stride after
its left hind, where the published walk is evenly spaced (0.25); slow, relaxed walks drift that way.
The issue said the literature wins over a clip that might be AI-made; Sean's comment on #470 (real
footage, Pexels) made the clip the main reference and the literature the check. Both blind judges
flagged our 0.25 as the fores running early. Ours is **0.30**: still a lateral-sequence walk, on the
clip's side of the published spread. The clip's duty factor (0.67) is a touch above the published
range, as a slow walk's is.

**Poses by eye** (`reference/crops/`, ±10°): the fore at contact straight and reaching (+15° from
vertical), upright at mid-stance with the fetlock sunk, slanted back with the heel up at lift-off
(−20°), the knee folded ~45° in mid-swing; the hind's cannon +10–20° at contact, vertical at
mid-stance, −25° at lift-off, the hock folded in swing; hooves lifted ~8–12 cm.

**Muybridge** (the issue's check) couldn't be fetched: Wikimedia Commons is outside this
workspace's network policy. Asked for on the review issue.

## 2. The rig

`blender/rig_check.py` draws the bones over the horse (`rig/rest.png`); `blender/bend_test.py`
flexes each near joint through a walk's range (`rig/bend_game.png`, `rig/bend_fixed.png`).

- **The fore** sits right: shoulder 1.08 m, elbow 0.90, knee 0.50, fetlock 0.18, the bones at the
  joints of the mesh. It folds cleanly at the knee and fetlock; a 15° turn of the scapula opens a
  thin crease at the elbow (the game's own weights).
- **The hind is wrong in the game's file** (`horse_rodin.py`'s measurement): the left hip is at x 1.05,
  *behind the buttock*, its stifle in the tail; on both sides the stifle sits straight above the
  hock (x 0.67–0.93), where a horse's tibia runs down and back from a stifle well forward at the
  flank. `horse_rodin.py` puts the stifle on the gaskin's line run on up from the hock, and on the
  left that line caught the tail. With it, flexing the left hind **tears the tail** (its hair follows
  the thigh) and opens the buttock (`rig/bend_game.png`).
- **The tail's lower hair has no tail weight** in the game's file (in one tail island, 47 of 76
  vertices): the legs claim it.

- **The seams' weights disagree** in the game's glb: copies of a vertex at a UV seam (exact, or a
  millimetre or two apart after decimation) carry different weights, up to 0.26 on the neck, head and
  forearm (23 exact pairs, and ~460 near ones). Wherever they differ, the seam opens as the joint
  moves: the elbow's crease and the throat's, and (after a first hind fix) the stifle's zigzag.

**Fixed in this experiment's copy only** (`blender/rigtools.py`; for `horse.py` later, see "What's
left"): the hips at (0.74, 1.04) and stifles at (0.55, 0.82), anatomically placed (the hip joint at
~0.63 of the withers' height; the stifle below and forward, just under the belly's line); each hind
leg re-weighted hip to hoof by distance to its bones (power 2, smoothed 12 times over the mesh); the
tail's hair (dark in the coat's paint, near the midline, nearer the tail's bones than any leg's)
weighted to the tail's bones only; then every group of seam copies within 3 mm given one weighting
(`weld_weights`). After it the bend test is clean at every joint (`rig/bend_fixed.jpg`), the elbow's
crease included.

**The fores re-weighted** (round 5, Sean on the films, #474: "the kinda abrupt stop at the base
where his leg meets the body with the forward step"): the game's weights put a hard edge between the
leg and the chest, so at full reach the top of the leg hinged under the chest at the elbow.
`rigtools.reweight_fore`: withers to mid-forearm, among the trunk (to its bones, or to the barrel's
axis at the elbow's height), scapula, upperarm and forearm, power 2 inverse distance, smoothed 12
times, blended into the game's weights over the region's edges (the knee down and the neck keep
theirs); and the scapula may slide ±22° (was ±16; its preference's key was never read: it now is,
light). **Smoothed in space, not over the mesh:** smoothed over the edges as the hinds are, it opened
a hole at the elbow's back. Most of the shoulder's UV seams don't meet vertex to vertex (a vertex on
one side lies on an edge of the other, 3–20 mm from any twin: 59 of 325 seam vertices there), so
weights smoothed island by island differ across a seam. Each pass now averages over every vertex
within 3 cm, any island. In the close render (`--cam=shoulder`) the elbow's crease at reach is a
soft fold with a small notch left at its front; the breast's holes at lift-off are gone
(`rig/shoulder_reweight.jpg`: the game's weights above, the new below). Not fixed:
the coat shows through the saddle pad's front edge as the shoulder moves (the game's weights too).

## 3. The walk

`blender/gait.py` (pure numpy/scipy, so it can be ported) and `blender/walk_build.py` (Blender).

- **Hooves by phase:** each leg lands at its offset (LH 0, LF 0.30, RH 0.5, RF 0.80), stays planted
  for 0.62 of the stride (the toe fixed on the ground), the heel rising about the toe over the
  stance's last part (breakover: 45° fore from 0.67 of the stance, 50° hind from 0.58). The swing
  carries the toe one stride forward on a minimum-jerk path, lifted 9 cm (fore, peak at 0.32 of the
  swing) and 10 cm (hind, 0.36): the clip's 8–12. **The hoof hangs** from the folded leg through
  mid-swing (`Walk.hang`): turned with the cannon plus 8° of flex, solved again three times, so it
  hangs sole-back in line with the cannon as the clip's do; at its ends it follows `Walk.turns`
  (flipped early, a touch toe-up, flat to land). A hoof turned by the clock alone read as a dancer's
  toe where the cannon was upright (round 4).
- **Each leg solved in its own plane** by least squares: the coronet must meet its target; every
  joint is bounded to the range a horse's leg has (no knee or hock past straight, no fetlock folded
  forward: the bounds are in `gait.py`); within that, it keeps near what the gait wants. The knee is
  locked straight in stance and folds up to 55° in swing, peaking at 0.3 of it (the elbow flexing
  18° with it); the hock folds to 50°, peaking at 0.4, and closes 12° over the stance's last part
  (the hind leaves angled); the fetlock sinks 18° (fore) / 15° (hind)
  at mid-stance; the stifle and hock move together as the reciprocal apparatus makes them; the
  elbow stays near rest. The preferences blend across lift-off (a step makes the solve jump between
  keys, and the keys' blend then dips the hoof into the ground: seen and fixed).
- **The body:** the trunk rises and falls 2 cm each way twice a stride, highest at withers and croup
  over their limbs' mid-stances, and pitches with the difference; the walk's carriage lowers the
  neck 34° and puts the nose forward 24° over the model's standing pose (head up, alert; a horse
  walking on a loose rein carries it low and long); the neck nods 5° twice a
  stride, lowest just after each fore lands; the tail sways and lifts with a lag down its bones.
- **The hind stance** is centred on the hind's rest toe (was 3 cm behind), the fore's 2 cm ahead of its own.
- **One stride length** (1.35 m, the clip's measured 1.34; was 1.5) and the root speed from it
  (1.23 m/s), so planted hooves don't slide.
  The action (`walk`, 66 keys = 1.1 s at 60 a second, the game's rate) is in place; the previews
  move the armature forward at the walking speed. Keying at 30 a second dipped the toe 11 mm at
  breakover (the blend cuts the hoof's arc about the toe); at 60 it's under a millimetre.
- **The stride length is the hind leg's reach.** (Round 5 shortened it to 1.35 m for the trailing
  hind: the judge then saw the hind land too far back. Both ends want the hip to travel.) At 1.7 m (the clip's ratio) the hind can't reach
  where the stride asks: from hip to coronet it's ~1.1 m; it fell 10 cm short at landing, then at
  lift-off. 1.5 m (a relaxed walk, inside the published range) with the hind stance a little behind
  its rest, and the stifle allowed 30° past standing, reaches everywhere it stands.

## 4. The checks (from `build/horse_walk/walk_report.json`)

Measured from the bones of the evaluated pose (Blender's own, between keys too), with the root
moving at the walking speed:

| | LF | RF | LH | RH | needed |
|---|---|---|---|---|---|
| planted hoof's slide (max) | 1.4 mm | 1.4 mm | 0.2 mm | 0.2 mm | < 1 cm |
| toe below the ground (max) | 0.3 mm | 0.3 mm | 0.4 mm | 0.2 mm | |
| duty factor (toe within 5 mm of the ground) | 0.67 | 0.67 | 0.66 | 0.66 | 0.60–0.65 published; the clip 0.67 |
| landing (share of the stride after LH) | 0.30 | 0.80 | 0 | 0.50 | lateral sequence |
| toe lift | 9.0 cm | 9.0 cm | 10.0 cm | 10.0 cm | the clip 8–12 by eye |
| the solve's miss on the ground | 0 | 0 | 0 | 0 | |
| knee/hock fold at its most (at share of swing) | 55° (0.29) | 55° (0.29) | 35° (0.40) | 40° (0.40) | the clip ~45° fore |
| cannon behind vertical / hoof turned, mid-swing | 37° / 40° | 33° / 39° | 0° / −3° | 4° / −4° | the clip ~35° fore, ~30° hind |
| at lift-off: hoof turned (heel up); toe behind hip or shoulder | 44°; 0.27 m | 44°; 0.27 m | 51°; 0.31 m | 51°; 0.29 m | |

Round 5's numbers (round 4's: slides ≤ 0.8 mm, lift 7 cm, fold 42° at 0.4, the hind's toe ~0.36 m
behind the hip at lift-off). The report's `swing` block holds the swing a tenth at a time.

- **Hoof order:** LH, LF, RH, RF, the fore 0.30 of a stride after its hind: the lateral sequence.
  **Pass.**
- **Duty factor:** set 0.62; read off the toes it's 0.67 because the toe skims within 5 mm of the
  ground for a moment at each end of the swing. Within the clip's measure; a touch above the
  published 0.60–0.65 by that reading. **Pass, near the edge.**
- **No joint bends backwards:** every joint stays inside its bounds by construction, and the ranges
  used are (degrees from standing) fore knee −55..0, fetlock −20..+15, elbow −4..+17, shoulder −24..+28, scapula −19..+22; hind stifle −34..+30, hock −13..+40, fetlock −46..+22, hip −27..+15. The
  hip's extension (−35) and the stifle's (+30) are at their bounds at push-off, the coffin joint
  (pastern to hoof) at its −40° in the fore's swing. **Pass.**
- **The mesh doesn't fold:** a triangle counts as folded when it has turned more than 90° away from
  where its own bone turned it. Worst frame: fore legs 3 (round 4: 5), hind legs 10, trunk/neck/head 11 of 2,900
  (single triangles at the stifle, the elbow and the throat as the neck lowers). Checked by eye in the
  bend test, a close render of the hind at push-off and the films: no cracks or inside-out surfaces
  after the weld. **Pass.**
- **The hind's mid-swing cannon is upright** (the clip's ~30° back): the hock's fold peaks at 0.4
  but the hoof's path forward brings the cannon round by mid-swing; a stronger hock preference
  (to 60°) didn't move it (tried with `--set`). It wants the hip to protract more.
- **The hinds in the air** fall short of their path by up to 2.1 cm (LH) late in the swing, the leg
  at its reach: airborne, not seen; on the ground they meet it.

## 5. The blind judge

Each round a fresh agent that had seen no code and no reasoning, given only the eight matched pairs
(`compare/`) and told to ignore background, paint, tack, framing and polygon count:

- `judge/round1.md`, our first walk: head high and stiff, the fore prancing, the hind stiff, lift-off
  early, the body level. All five changed (listed there).
- `judge/round2.md`: head still high, the fore still too high, the hind "en pointe", the fores early
  against the hinds (the lateral phase: 0.25 -> 0.30), legs stiff. Changed; and the seam weld.
- `judge/round3.md`: head high, the hind's stance too far back ("a sawhorse"), the swing now too low,
  no tracking up, the tail off the buttocks. Changed what the reach allows; the rest reported.
- `judge/round4.md`, round 4's walk: 4/10. Its top three, as they were then:
  1. **Head and neck still too high.** Four rounds rank it first. The bones have lowered the neck 34
     degrees; lower wasn't tried (the model is built with a high, upright neck: the bones may not take
     it far without the neck's mesh or rig).
  2. **The swing legs too straight, the hoof toe-down and skimming.** The fold has swung between
     "prancing" (round 2) and "shuffling" (rounds 3, 4) on stills; it needs judging on the films,
     and a fore fold that peaks early with the hoof carried level.
  3. **The trailing hind too far back and flat at lift-off.** The hind can't reach both ends of a
     1.5 m stride at duty 0.62 (README, "The stride length"); a shorter stride or a pelvis that tips.
- `judge/round5.md`, **round 5 (the swing, the hind, the fores re-weighted): 5/10**, judged on the
  pairs and a contact sheet of the side film beside the clip's. Its top three: the head (waiting on
  Sean, #473); the hind's reach forward now short (the stride's other end); lift-off without a
  visible roll over the toe. The toe-down swing and the trailing hind are off its list.

## What was checked by eye, and what wasn't

- By eye: the gait diagram's stances and which leg is which (contact sheets, the occlusion crops),
  the poses at the key moments (±10°), the bend test, the films' first and last strides, the pairs.
- Not by eye: the slide, order, duty factor, joint ranges and folds are measured, not judged.
- Not checked: Muybridge (blocked); the game (nothing here is in it); a real GPU's look (Cycles CPU).

## What's left

- **Round 5's top three** (`judge/round5.md`): the head's carriage (Sean's choice on #473: lower by
  bones, or the neck rebuilt); the hind's reach both ways (the hip's travel: a lumbosacral bone, or the
  pelvis tipping with each hind); the toe's roll at lift-off (the toe held down over the stance's last
  tenth while the heel goes past 60°). Also the forearm's reach (the elbow's protraction), the trunk's
  give and the pastern's sink (18° is too little to see), the saddle pad's front edge.

- **For the game's horse** (`horse.py`, `horse_rodin.py`; gameplay/characters to decide): the hind's
  hip and stifle placed anatomically (as `rigtools.HIND_FIX`), the tail's hair weighted to the tail
  only, weights smoothed across UV-seam copies. As it is, the game's idle doesn't move the left hind
  enough to show the torn tail; a walk would.
- **The stride is short for the clip's horse** (1.5 m against its ~1.3 m slowed, 1.7 m by its
  proportions): our hind legs are short for his trunk. A longer walk needs the pelvis to tip and
  the hip joint to travel (lumbosacral flexion), which this skeleton doesn't have (`pelvis` is one
  bone with the trunk).
- **The clip's lateral phase (0.33)** isn't ours (0.25); if Sean prefers the clip's slower, more
  "couplet" rhythm, it's one number (`Walk(lateral=0.33)`).

## The procedural gait, later

This is the reference, not the game's walk. The game's will need:
- the same hoof-by-phase schedule, but with the stride length and frequency from the speed (walk
  stride grows with speed, its frequency a little; duty factor falls from ~0.67 slow to ~0.58 fast);
- each planted hoof placed by a ray to the ground (`World.space`) at the predicted landing, held
  where it lands, and the swing's path from there to the next; a leg solve like `gait.Leg` (a
  dozen least-squares iterations a leg; or an analytic two-bone solve with the knee/hock rules,
  cheaper in GDScript), on the people's worker pool (`PeopleTick`);
- the trunk's height and pitch from the four hooves' heights (on a slope or a step), its rise and
  fall and the nod on top;
- turning (the inside legs' strides shorter, the hooves crossing a little), stopping (a last stride
  shortened, the hinds brought under), starting (the first stride from the hind);
- the hind rig fixed first (above), or the hind legs can't bend as the gait asks.

## Sources

- Hildebrand, M. (1965). Symmetrical gaits of horses. *Science* 150: 701–708 (the lateral-sequence
  walk; limb phase).
- Clayton, H. M. (2004). *The Dynamic Horse.* Sport Horse Publications (stride, duty factor, joint
  ranges at the walk; the reciprocal apparatus).
- Back, W. & Clayton, H. M., eds. (2013). *Equine Locomotion*, 2nd ed. Saunders (walk kinematics:
  limb protraction and retraction, fetlock extension at mid-stance, the stifle–hock coupling).
- Buchner, H. H. F., Savelberg, H. H. C. M., Schamhardt, H. C. & Barneveld, A. (1996). Head and trunk
  movement adaptations in horses with experimentally induced fore- or hindlimb lameness. *Equine
  Veterinary Journal* 28: 71–76 (two rises of the trunk and two nods of the head a stride).
- Getty, R., ed. (1975). *Sisson and Grossman's The Anatomy of the Domestic Animals*, 5th ed. Saunders
  (where the hip, stifle and hock sit).
- Muybridge, E. (1887). *Animal Locomotion*, the walk plates (public domain): not reached from here.
