# The hands in the men's painted style, and the gun metals painted (2026-10-23, issue #274)

The gun lab's first fix, measured against `baseline/` (main fd7fe08). Sheets in `sheets/`
(`fp_revolver*.jpg`, `fp_shotgun*.jpg`, a man's gun `men_sean_s2.jpg`), beside the baseline's.
Sean, 2026-10-22: "spend the cash to draw" (#249, $0.90) and "the hand also needs work: it needs to
match the art style of the new characters".

## What changed

- **The hand** (`src/weapons/held_hand.gd`): no longer primitives. A Character Studio man's own
  skinned, painted forearm and hand (`tools/faces/hands.py`: MakeHuman's hand grafted on, painted
  into his skin, 15 finger bones a hand), cut out of his model when first needed: every triangle on
  his arm, hand or finger bones, his skin's painted texture in the men's own shader
  (`BodyInterior.skin_material`). Sean's man (`sean_s3_talking`): the palest and least orange of
  the eight with hands. Every one's forearm is bare skin to the elbow (the graft), so there's no
  shirt cuff to be had at the wrist.
- **The revolver's hand** (`HandModel`): palm on the right panel, middle, ring and little fingers
  round the front strap onto the left panel, the index's pad on the trigger, the thumb along the
  left of the frame (on the spur to cock). Each joint fitted by `views.gd --fit`: closed until the
  finger past it touches the walnut.
- **The coach gun's two hands** (`ShotgunViewmodel`, `R_*`/`L_*`): the right round the stock's
  wrist, its index swung forward onto the front trigger (`HeldHand.pose_finger`: a plain curl can't
  reach it), its thumb over the top for the hammers; the left under the forend, its fingers up the
  right side. From the hip the gun sits forward and up (`Pose.HIP` (0.10, -0.17, -0.33), 5/6
  degrees) so both hands are in view (baseline item 1). Shouldered, the right forearm runs out to
  the side and down, clear of the action.
- **The metals** (texture factory, art's `materials.json`): `gun_blued` (dark blue-black, worn grey
  on a few edges) and `gun_case` (swirled blue, plum and straw), painted in the men's hand on
  GitHub (run 115; run 114's takes came back as folded cloth and were retaken); the brass is
  `prop_brass`, the stock `walnut`. `GunParts` lays each at its own 512 texels a metre. Spent $0.88
  of $0.90.
- **Your body** (`PlayerBody`): shirt, vest and skin in Sean's man's painted colours (the medians
  of his texture over his upper arm, chest and hand), as the arms you hold the guns with (item 3).

## Numbers

Each finger bone's skin against what it holds (`views.gd` detail views, `GAP`, mm; negative = into
the wood):

| Hand | index | middle | ring | little | thumb |
| --- | --- | --- | --- | --- | --- |
| Revolver | +1 / +1 / +1 (trigger) | -2 / +1 / +1 | 0 / +2 / +2 | 0 / +6 / 0 | -1 / 0 / +20 |
| Coach gun, right | -1 / +2 / +2 (trigger) | 0 / -1 / +2 | +7 / +1 / +1 | +16 / +9 / +2 | +6 / +13 / +26 |
| Coach gun, left (forend) | -1 / +4 / +1 | -4 / +1 / +1 | -1 / +3 / 0 | -1 / +4 / +2 | +6 / +18 / +28 |

The baseline's boxes had no bones to measure. The coach gun's right little finger hangs under the
stock's wrist (+16 at its knuckle): the wrist is 3.4 cm deep.

Framing (`fp_*.json`): both of the coach gun's hands on screen in every state (rest, walk, run,
cocked, aim, shot, the reload); the baseline's from the hip had none (item 1).

Handling (`run.py --job=handling`, `--compare` with the baseline): draw, cock, rhythm and reload
times unchanged; the accuracy figures moved within their noise (walking from the hip, 2-4 cm).

## The blind judge

A fresh sub-agent given only `docs/concept/targets/9_studio_men.png` and the old and new
first-person sheets, labelled A (new) and B (old) at random:

- Hands: new **CLOSE** on both guns ("smooth with soft painted blotches of tone, the same family as
  the men's faces"); old **DIFFERENT** ("stacks of voxel cubes").
- Metals and wood: new **CLOSE**; old **DIFFERENT**.
- Holding: the new revolver hand "mostly yes, palm on the grip and the fingers wrap it"; the coach
  gun's "yes in rest, walk and reload". The old coach gun "floats on its own" from the hip.
- Its five for the new, and what was done: (1) the coach gun shouldered, the forearm over the
  action: fixed (out to the side); (2) the arms too orange, no cuff: Sean's paler man (no Studio man
  has a cuff); (3) the revolver aimed, the hand over the frame and no trigger finger in view: from
  behind the index is behind the frame, as it is on a real gun; left as is; (4) the reload with one
  hand: the next step (the period reload); (5) the case-hardened frame reads pale grey and the
  coach gun's stock is a box: for art (the frame's case colours lighter than the painting's; the
  stock's shape is the model's).

## Next

The revolver's period reload step by step with a left hand, then the coach gun's; a man's grip on
`HeldHand` with the gunfight lab's `GunHand`.
