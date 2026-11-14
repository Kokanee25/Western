# The guns in your hands, posed by eye (gun lab, gameplay; art judges)

Sean, 2026-10-24, after the painted guns and arms (#322 onward, `docs/briefs/gun-remake.md`): "that
shotgun hold still looks like shit - is this typically how games are made ... or do they just draw
it how they want it", then "going with 1": a first-person rig posed by eye, as shooters make theirs.

## Why

Today the hold is computed: `HeldHand` cuts the Studio man's real arm from his model, and code
curls each finger until it touches the wood (`views.gd --fit`) and solves the elbow by two-bone IK
(`_arm_to_shoulder`). That makes a physically plausible hold, not a good-looking one. It stays
stiff, and every fix moves the fault. Shooters build first-person arms and gun as their own rig,
posed and animated by eye through the game's camera, with anatomy cheated freely (arms stretched,
wrists bent, the gun scaled or pulled in): it only has to look right from one camera.

## Goal

The revolver and the coach gun held, cocked, aimed, fired and reloaded by a rig whose poses were
set by eye from the player's camera. Painted as now (`held_arm_skin.png`, the Blender guns), the
way a good shooter's hands look, judged against Sean's photos and the men's sheet.

## How

1. **References first:** Sean's 3–4 phone photos from his own eye, holding something long at the
   hip and shouldered (and a revolver-sized object), plus one from the side
   (`docs/concept/guns/ref/`), and the 13 first-person holds found in public GitHub repos (links
   and what each shows in `docs/concept/guns/ref/SOURCES.md`; looked at, never copied in). What
   they share: the long gun big in the lower right, angled in from the corner towards the centre;
   the left hand far forward on the fore-end with the forearm showing to the elbow; the right hand
   low at the grip, often only its cuff in frame; aimed, the gun runs straight up the middle from
   the bottom edge with the hands at the two lower corners.
   **The targets in the game's own framing** (2026-10-24, Nano Banana Pro, $0.42): three game frames
   (`docs/concept/guns/hold_game_{hip,aim,rev}_base.png`) with only the arms and hands repainted
   holding the guns right: `assets/textures/guns/hold_game_{hip,aim,rev}.jpg`. Pose the rig until
   its render from the game camera matches these (the hip: the right hand round the pistol grip
   with the thumb over, the left forearm in from the lower left, its hand cradling the fore-end
   from under and beside; the revolver: the hand high under the hammer, the wrist in line). Drawn
   without a base, the same model's holds (`hold_coach_hip`, `_aim`, `hold_revolver`) have good
   hands and the guns in the wrong places: hands only.
2. **One Blender scene a gun** (`experiments/gun_lab/blender/viewmodel_rig.py`, headless): the
   camera matched to the game's (its FOV, near plane, where the viewmodel hangs in camera space);
   the two arms from Sean's man (his armature's arm and finger bones, the painted `held_arm_skin`,
   normals smoothed); the Blender gun (`assets/weapons/<gun>.glb`) with each moving part (hammers,
   triggers, cylinder, gate, ejector, barrels on the hinge, lever) on a bone of the same rig.
3. **Poses by eye:** each key pose set by bone rotations in a data file
   (`experiments/gun_lab/blender/poses/<gun>.json`), rendered from the game's camera, looked at,
   adjusted, rendered again. Cheating allowed (the arm's length, the gun's scale and distance).
   Poses: hip, aim (down the sights), cock, fire (the hand's part only: the kick stays procedural,
   `GunKick`), the reload's steps (revolver: gate, eject, insert, close; coach gun: lever, open,
   shells out and in, close), draw and put away.
4. **Into the game:** exported as one glb a gun with its actions; a `ViewmodelRig` plays them on
   an `AnimationPlayer`, driven by the weapon states as today (`RevolverState`, `ShotgunState`;
   the timings stay theirs). Sway, bob, kick and recoil stay procedural on top (CLAUDE.md
   "Motion"). `HeldHand`'s fitting and IK leave the viewmodels (kept for men's hands later).
5. **Every node the tests and other code use stays** (muzzles, chamber points, the models' parts
   for `show_barrels` and the state's poses), or the tests are moved with them, said so.

## Done when

- Both guns' poses rendered from the game camera beside Sean's photos; Sean says the hold reads.
- A blind judge, given the men's sheet, Sean's photos and the old and new first-person sheets
  (`run.py --job=fp`), prefers the new and finds the hands CLOSE to the photos' hold.
- Tests green; goldens with a gun re-approved (art's files, said so); a film for Sean.

## Cost

No paid art (the paint is done). The work is the posing.
