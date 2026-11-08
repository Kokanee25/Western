# The fuller skeleton (issue #696)

Sean, 2026-11-07: yes to a fuller game skeleton (clavicles, twist bones, skinned fingers), the
ragdoll unchanged. The MetaHuman test (#692) showed the cost of 17 segments: shoulders stuck
shrugged (nothing lowers or rolls them), a hands-up that can only swing from one point (#694), no
grip for guns (#693), his upper arms stretched 1.11x to fit fixed bone lengths.

## What it is

- **Every man's skin skeleton**: his 17 segment bones, then 30 finger bones
  (`finger_<finger>_<side>_<0..2>`, the drawn fingers' ids), then 10 deform bones
  (`clavicle_r/l`, `upper_arm_twist_<side>_0/1`, `forearm_twist_<side>_0/1`; `DeformRig`,
  `src/bodies/deform_rig.gd`), then a Studio man's shoulder helpers. 57 bones (59 with helpers).
- **The ragdoll, hitboxes, anatomy, wounds, gore and dismemberment stay on the 17 segments.** The
  new bones only shape the skin; nothing they do moves a part. The pieces a limb comes off in are
  cut as before (by the 17 bones' own weights).
- **Driven**, each tick after the 17 bones follow the parts:
  - the clavicles by the upper arm's raise and reach in the chest's frame: rise 0.15 degree a degree
    of raise past 20 (Ludewig et al. 2009: ~11 degrees over 120 of elevation), forward 15 degrees a
    unit of forward reach, back a little as it rises; held to 26 up / 6 down / 18 forward / 14 back
    (`config/skeleton.tres`). A pose adds its own lift (POSES' `clavicle_r`/`clavicle_l`: hands_up
    +5, Sean's "clavicles lifted a little"); a clip with a `clavicle_r`/`clavicle_l` channel (a
    quaternion in the chest's frame) leads it; old clips without one still play, the clavicle driven.
  - the twists by a swing-twist split of the limb's roll: the upper arm's twist bones take 0.15 (at
    the shoulder) and 0.55 (halfway) of its roll from the chest, the forearm's 0.5 (halfway) and 1.0
    (at the wrist) of the hand's roll, so a turned wrist twists the forearm along its length (the
    radius over the ulna) instead of wringing the skin at the joint.
  - the fingers as before (`curl_hand`, the grip, a shot-off finger), now in every man's skeleton.
- **Skin weights**: a model without its own for the deform bones (BodyMesh's men, MakeHuman's, the
  Studio's Rodin men) gets them at load (`DeformRig.spread`): the chest's over each shoulder to that
  clavicle, each arm segment's along its length to its twists. A model with its own (the Studio's
  MetaHuman route: his clavicles and fingers) keeps them. The Studio's shoulder helpers turn from
  the clavicle now.
- **A man's own proportions**: his report's `proportions` (each segment's ends at his joints, his
  clavicles') give him the shared anatomy fitted to him (`Anatomy.for_model`, `fitted`): each
  segment moved, turned and stretched along its length, held to 0.82-1.22 of its length, 8 cm and
  15 degrees; its capsules (the hitboxes) and the structures inside go with it. Everyone else keeps
  the shared anatomy (`Anatomy.shared()`, the same object).

## The films

`bridge.gd` (lab commands `sk_man`, `sk_rig`, `sk_cam`, `sk_film`, `sk_cost`): one man, no brain,
on the street at 16:12 under the real look (`--game-args=--real`). "Before" is MetaHuman Sean as
the Studio made him for the 17-bone skeleton (`sean_metahuman_s1`: stretched onto the game's bone
lengths, his clavicles and fingers summed into his chest and hands, the shoulder helpers) with the
deform rig off (`sk_rig off`: each deform bone moves as its segment, the 17-bone skin); "after" is
`sean_metahuman_s2` (the Studio's build on the fuller skeleton: his own lengths, clavicle and
finger weights) with it on. Both drawn with his GLB's own materials (as the Studio's test scene
draws a MetaHuman; the game's people shaders expect the painted men). His GLBs are the Studio's
(`Kokanee25/saltcreek-characters`, builds `sean_metahuman_s1`/`_s2`), copied into
`assets/people/` locally for the films, not committed.

```sh
python3 tools/bridge.py start --size=720x720 --fps=60 --game-args=--real
while IFS= read -r l; do python3 tools/bridge.py "$l"; done < experiments/skeleton/results/2026-11-08/films.txt
python3 tools/bridge.py stop
experiments/skeleton/films.sh build/sk_films experiments/skeleton/results/2026-11-08
python3 experiments/skeleton/sheet.py build/sk_films experiments/skeleton/results/2026-11-08/sheet.jpg \
    --thumb=<his thumbnail> --capture=<the Studio's handsup.jpg>
```

(One `bridge.py` call a line: a long film outlasts one client's 600 s.)

## Results (2026-11-08, `results/2026-11-08/`)

- **MetaHuman Sean's own lengths** (Studio build `sean_metahuman_s2`, his report's `proportions`,
  his against the game's): upper arms 0.90 (the 17-bone fit stretched them 1.11), forearms 1.03,
  hands 0.97-0.98, thighs and shins 1.03, belly and chest 0.87, neck and head 1.22 (his shoulders
  sit 2.6 cm lower; the game holds it at its 1.22 limit), feet the game's moved with his ankles.
  His hitboxes and what's inside follow them; nobody else's anatomy changes.
- **The D+ fight unchanged**: the 20 fights of #607's same-fight set (`--scenarios=spec_hall,
  spec_stair,spec_gallery,spec_back,spec_front --hours=golden --weapons=revolver --styles=careful
  --bodies=studio --variant=D --fixes=all+pain_fight+floor_fight+odds+flinch --opening= --seeds=1-4`)
  on main and on this branch: `same_fight.py` **20 of 20 the same**, event for event.
- **The body lab unchanged**: `experiments/body_lab/run.py` (all 61 scenarios, the four models: 244
  runs) on main and on this branch: **244 of 244 summaries identical** (every wound, bleed, ability
  and death). (Both runs end on run.py's own `KeyError: 'check'` after the last scenario, main too.)
- **The cost a man** (`sk_cost 2000`, MetaHuman Sean hands up, this VM): his bones posed 26.4 µs
  a tick with the deform rig off, 32.9 µs on (+6.5 µs; ~4 µs at Sean's 3.25 GHz by the 0.65 scale);
  the rig's own pose 11.7 µs. Thirty men in town: ~0.13 ms of the people's 4 ms at Sean's.
- **Tests**: the whole suite passes (1,059; `tests/test_skeleton.gd` new, `test_bodies` counts the
  new bones, `test_studio_shoulders` measures the helpers from the clavicle).

**The films** (before | after, each real time then half speed; `sheet.jpg` the stills beside his
MetaHuman thumbnail and CMU 79_74, a real capture of the arms coming up):
`handsup_front/side/three.mp4`, `aim_front/three.mp4`, `reach_three/side.mp4`, `wrist.mp4` (his
hand rolled 80 degrees each way), `grip.mp4` (drawing and aiming the revolver).

- **At rest**: his shoulders slope down from a longer neck (his own; before, his chest was lifted to
  the game's shoulder joints and his arms stretched 1.11 to its elbows).
- **Hands up**: the clavicles rise with the arms (+5 the pose's own), his own shorter upper arms put
  his hands a little under the old height; the fingers open (a fifth of the relaxed curl hands up;
  his report's `finger_rest_curl` 0: MetaHuman's bind hand is already curled, the game's relaxed
  curl on top of it made a claw, fixed after the first take).
- **Aim and reach**: the clavicle forward with the arm; the shoulder's top stays round.
- **Wrist**: before, the rolled hand wrings the wrist thin; after, the forearm twists along its
  length and keeps its volume.
- **Grip**: before, his fingers stay as modelled (summed into his hand); after, they close round the
  revolver's grip (the game's curl through his own finger weights).

**Left, seen in the films**: the vest's armholes still spike in the hands-up (the Studio's open
fault from s1: its arm weights; both takes); the revolver sits a little high in his fist (the grip
point is the shared anatomy's, mapped by his hand); the fingers don't spread (the finger bones bend
only); his GLB's own materials in the films (the people shaders don't take a PBR man yet: #692).
No real capture of an aim or a reach was at hand: those two have none beside them.
