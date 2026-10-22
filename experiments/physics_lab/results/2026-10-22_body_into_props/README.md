# 2026-10-22: a body thrown into the prop kit's furniture (BodyImpacts -> KitProp.take_blow)

Sean (2026-10-22): bodies breaking furniture. A falling man struck the kit's chairs and tables by
the timber rule meant for walls and rails (`impact_toughness` × a member's volume). A chair's spindles
snapped at a brush, and a chair struck hard held rigid until a member broke.

## What it does

A kit prop (KitProp: anything with `take_blow`) takes him as a blow on its own terms. Each tick:

- **What he brings:** every part of him moving into it at `QUIET_SPEED` (0.6 m/s) or more adds its
  momentum. Together they are one blow from the weight of those parts.
- **What the prop does:** the kit decides, from its wood, its weight and what's on it. It breaks
  where struck, slides, or goes over (a loose prop is physical).
- **Once per strike:** a prop he has just struck takes nothing more from him for 0.25 s. He's on
  it, not hitting it.

No prop lab file changed.

## Proof

New group Y in the saloon fixture (the card table and its chairs), plus group P's four saloon falls.
Rancher, `build/physics_lab/y_main` vs `y_kit`:

| fall | main | kit path |
|---|---|---|
| charged into the table (640 J) | he lands on it; it holds | the table breaks under him |
| shoved back over the chair behind him | its back breaks, he hangs arched over it | it goes over with him |
| shot from behind beside the table | the chair he drops onto stays rigid | it shifts and turns under him |
| fainting back onto the chair | holds | goes over (a man falling at ~2 m/s into 5 kg) |

- **A blind pairwise judge** (`judge.md`, key `key_blind.json`): **kit 7, main 1, even 2.**
  - Main's faults: chairs "stay rigid while he sits into it"; "the chair's back slats snap and fly
    off from what looks like a light graze"; "the back breaks into pieces but he stays hanging,
    arched over it, in mid-air".
  - Main's one win: he faints back into a chair and stays slumped in it.
  - Left in both: the round table doesn't budge when he's charged face-down onto it, and his head
    clips into a chair seat now and then.
- **Tests** (`tests/test_body_impacts.gd`):
  - a man thrown into a kit chair at 3 m/s sends it over (main's timber rule does too, by breaking
    a leg);
  - a part drifting into it at 0.4 m/s brings it nothing, and at 3 m/s it is a blow that sends the
    chair over or breaks its leg.
- **Cost:** none in the open: kit props are only read when he's near timber, as before.
