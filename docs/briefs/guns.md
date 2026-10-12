# Brief: the guns in your hands

Sean, 2026-10-12: "Can we fix the guns first? They look like shit."

## What's wrong (measured against the pictures, not guessed)

Side by side with `docs/concept/street-golden-hour.png` and the style pictures
`docs/concept/style/street-standoff-revolver-in-hand.png`, `prop-revolver-card-table.png`,
`prop-shotgun-at-the-bar.png` (the goldens `gun_hip_range`, `gun_aim_range`, `shotgun_hip_range`,
`shotgun_aim_range`, `gun_loading`, `shot_match_street`):

1. **The guns are boxes.** `RevolverModel` is ~20 `BoxMesh`es and plain tubes: a rectangular grip,
   a block frame, a block hammer, a plain cylinder with no flutes, a trigger guard of three
   sticks. `ShotgunModel` reads as a thin stick. The pictures' Colt reads at a glance from its
   outline: the plum-shaped walnut grip, the frame's curve into the trigger guard, the fluted
   cylinder, the hammer spur, the ejector rod under the barrel, the brass guard.
2. **The hand is a box, the arm a flesh slab.** `HandModel` is boxes; at the hip only a skin
   block and a slab of forearm show. The pictures: four fingers wrapped round the grip, a thumb,
   a brown coat sleeve with a cream cuff.
3. **The pose hides the gun.** At the hip the revolver is seen from behind and above, small, low
   on the right; aimed, it's a dark slab end-on. The pictures hold it out forward, barrel up and
   to the left, its left side to you (the fingers round the front strap, the thumb along the
   frame), a third of the frame's height.

## What done looks like

- The revolver and the coach gun modelled from their real side profiles (Colt Single Action Army
  7½", a 12-bore side-by-side hammer coach gun), extruded and bevelled, with lathed and fluted
  round parts; same local space, moving parts and markers as today (`hammer`, `trigger`,
  `cylinder`, `gate`, `ejector`, `muzzle`, `gate_point`, `show_chambers`, `chamber_rear`), so the
  viewmodels, reloads and tests work unchanged.
- A hand with shaped fingers, knuckles and a thumb, wrapped round the grip, a sleeve and cuff.
- The hip pose held out and turned so the gun's left side shows, as in the pictures. Where a shot
  goes doesn't change (the line of sight decides it, `_shot_line`), only what you see.
- Still on the held texel grid (`GunParts.grid`, 160 texels a metre): squares like the
  painting's, lit tile by tile.

## How it's judged

- `tools/gun_lab.gd`: the gun and hand alone in the game camera's view, in hip, aim and
  side views, under a golden-hour key, beside the style pictures (`docs/screenshots/guns/`).
- The goldens with the guns in them re-approved from two `--fresh` runs; judge v2 on the street
  shot (the revolver is in it); the blind critic.
- Every weapon test passes (revolver, shotgun, composure, drop, dev bridge).

## Files

Gameplay's, with Sean's ask (said in every commit): `src/weapons/revolver_model.gd`,
`shotgun_model.gd`, `hand_model.gd`, `gun_parts.gd`, and the pose constants in
`revolver_viewmodel.gd` / `shotgun_viewmodel.gd`. Art's: `tools/gun_lab.gd`, the goldens.
