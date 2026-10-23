# 2026-10-22: getting up after a fall (`HumanBody.get_up`)

Sean (2026-10-22): a man knocked down but not hurt gets back up. Before this, going limp was one
way: the ragdoll freed the standing rig and nothing ever made it again.

## What it does

**When.** Only after a fall he braced for (`brace`, PR #238): his chair went from under him, or a
shove put him down. He must be alive, awake, able to stand, in little shock and with nothing
severed. He gets up once he has been down 1.6 s and lain still for 0.6 s. A man shot, killed,
blasted or fainting stays down, as before.

**How.**
- **The rig comes back.** `_rebuild_rig` is go_limp backwards: the pivots and animated parts are
  made again, each ragdoll body's shapes, meshes and decals move back onto its part, and the
  joints and ragdoll bodies are freed.
- **Nothing jumps.** Each joint starts at the angle it lies at (a ragdoll joint's rest is its pose,
  in the poses' own degrees: checked), and the rig is set so his pelvis is where the ragdoll's lay.
- **Stages.** He rises through them, each blending his pose and the rig's lie together over its
  time, with his lowest point kept on the ground:
  - **on his back:** sit up (hands behind him), tuck a leg under, up onto one knee, hands on
    knees, stand;
  - **face down:** hands and knees, up onto his knees, one foot under him, hands on knees, stand.
- **Out of the wreck.** He ends standing over his feet, not where his hips lay (out of the
  wrecked chair).
- **No kicked debris.** Loose pieces round him (the chair he went over with) stop colliding with
  his rising body. They lay where his animated parts appear, and the engine flung them at him:
  5 kJ broke his shin as he rose (`_spare_rubble`).
- **The brains.** An outlaw back on his feet goes back to fighting (or calm); a civilian is shaken.

## Proof

- **Tests** (`tests/test_get_up.gd`):
  - kicked over in his chair, he's up within 10 s with his head above 1.4 m;
  - shoved down, he's up again;
  - a man who simply goes limp stays down.
- **Three blind critic rounds** on the two chair falls (back legs kicked: on his back; front legs
  out: face down):
  - round 1, 3 and 4 of 10: a V-sit sit-up with his legs in the air, rising out of the wrecked
    chair as if still seated, from a pike straight to upright;
  - round 2, 3 and 5;
  - round 3, 4 and 5: on his back he rose, sank back to a kneel, and rose again; his hands never
    took his weight; his boots floated.
  - Each round's top faults were fixed in the next: stages blend with the rig, the crouch moves
    over his feet, kneeling stages, a tucked leg.
- **Left:** he stands up stiff and still at the end, doesn't pick up his hat, and on all fours
  holds a while. The lab's per-tick ragdoll flags don't know about rising, so some read the rise
  as a discontinuity.
- **Videos:** sent to Sean.
