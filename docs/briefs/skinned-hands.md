# Brief: skinned hands (one hand, fingers bending inside the skin)

Characters session, 2026-10-15. Sean, on the layered cowboy's hands: "they're pretty ugly"; on the
fix: "Let's do the skinned hand". Touches gameplay's `src/bodies/human_body.gd` (more than a line
or two: Sean's OK, 2026-10-15).

## Why

The game builds a hand as a palm (part of the body's skin) and five fingers of three rigid pieces
each (`HumanBody._build_hand`), hung on finger nodes that curl (`curl_hand`) and come off
(`sever_finger`). Rigid pieces always read as a wooden doll's: steps at every joint, and a hand
cut from a real model into pieces comes out ragged (`docs/style_test/layered-2026-10-15/c4`-`c6`).
The fingers are also sized and placed by the anatomy: a slim, average hand, the thumb hung
parallel to the index from high on the palm.

## What to build

1. **One hand mesh per side:** MakeHuman's hand (CC0, `tools/blender/mh_hand.py`), palm and fingers
   in one piece, fitted to the game's hand (its knuckles on the anatomy's), a little chunkier
   than MakeHuman's, its thumb where MakeHuman has it, painted in his skin (`mh_hand.paint`).
2. **Skinned to finger bones:** 15 bones a hand (`finger_<finger>_<side>_<0..2>`), their rest
   where the game's finger nodes rest; each point weighted to its finger bone, blended across the
   joints, the palm to the hand. Exported in the fitter's armature as children of the hand.
3. **In the game:** when a model's skin has finger bones, `HumanBody` adds them to its
   `Skeleton3D` (after the anatomy's 17, parented to the hand) with their binds, and each frame
   poses them from the finger nodes (which still curl, grip and hold the gun). The drawn finger
   pieces are hidden. A finger shot off: its bones shrink to nothing at the knuckle (the stump
   bleeds as now) and the drawn piece flies off as now. `BodyMesh.split_pieces` puts a finger
   bone's triangles in the hand's piece.
4. Models without finger bones (every other man) are built exactly as now.

## Done looks like

The layered cowboy's hands from four sides, open, in a fist and holding the revolver: one smooth
hand, no seams, joints bending in the skin, his thumb where a thumb sits, painted like him; a
finger shot off leaves a stump. Tests pass; the people frame budget holds (30 bones more a man
with these hands).

## How it's judged

Sean's eye on the sheet beside the old hands (`c6_hands_clean.png`).
