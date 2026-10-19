# The whole man's head and neck (2026-10-19): the bold cowboy only

Branch `claude/characters-whole-man-face`. Paid calls: **$0** (no Rodin, no training; try C, a
new Rodin head at $1.60, not run: it waits on Sean's call). The talking face waits on Sean's OK of
the face and neck.

Sean: "his face for sure needs work" and "his neck needs work too, it looks off". Sheet:
`sheet.jpg` (his portrait | today | try A | try B: the card table at night, plain front, 3/4 and
side, the street at golden hour, and 2x crops of the eyes, moustache, hair under the brim, neck
front and side). Both tries are separate men (`bold_cowboy_whole_a`, `bold_cowboy_whole_b`):
`bold_cowboy_whole` on main is untouched until Sean picks.

## What was wrong, measured

Against his front portrait (MediaPipe, in eye spans, left plus right so its small turn cancels) the
Oct 14 head matches down to his lower lip; below it **his chin is 1.1-1.3 cm short** (lower lip to
chin 0.44 eye spans against the portrait's 0.64) and **his lower jaw a quarter narrow** (at chin
level 1.18 against 1.50). That's the "small, narrow face under the hat". His neck: the body was cut
flat at his chin's height right across, so his jaw sat on a white band with **12 mm** from chin to
collar (the profile portrait: about 0.20 of eye to chin, ~22 mm), his vest's back rose straight
into his hair with no nape, and his collar and tie stood as far forward as his chin.

| | eye to chin | lip to chin | jaw at chin level | chin to collar | neck / jaw width | ear ahead of shoulder joint |
|---|---|---|---|---|---|---|
| his portraits | 1.86 | 0.64 | 1.50 | ~0.20 | ~0.85 | - |
| today | 1.64 | 0.44 | 1.18 | 0.12 (12 mm) | (no neck) | 35 mm |
| try A | 1.86 | 0.66 | 1.42 | 0.18 (21 mm) | 0.96 | 35 mm |
| try B | 1.72 | 0.58 | 1.30 | (its own collar) | (its own) | 26 mm |

(eye spans; `head_neck.py measure`.)

## Try A: the Oct 14 head, repainted smooth, with a built neck (no paid calls)

- **The chin and jaw** moved to the portrait's (a thin-plate warp on the landmarks under his lower
  lip, 75% of the jaw's width since the portrait's outline has his sideburns in it; everything
  above his lip and behind his ears held). His eyes stay exactly on the anatomy's.
- **The neck**: his ragged underside cut cleanly along his jaw; a neck lofted from that edge: the
  underside of his jaw back to his throat, his sides, and under his hair in to his nape, then
  straight down into his collar. 0.35 m round; his nape ~3 cm in under the back of his skull,
  his throat ~4.5 cm behind his chin.
- **The collar** as in Sean's arms-out pictures: a turned-down shirt collar (a stand round his
  neck, the fall folded over it, its points spread over his shirt with his tie's knot between),
  not a flat band. The body is cut round it lower in front (under his throat) and lower behind,
  and its edge stood round the neck. Inside the collar the neck takes the body's own weights, so
  it moves with the collar.
- **The paint**: projected from his five portraits by the recipe's projection, but **smooth**
  (the portraits' squares blurred out, his eyes kept from the sharp portrait), **de-lit fully**
  (the portraits' lamp light divided out by the surface's angle), his **skin muted** (saturation
  0.6 of the portraits'), his eyes' whites lifted. Under the brim, where the portraits show their
  hat (the game's hat sits higher), his own paint is carried on up (hair at his temples, skin on
  his forehead) instead of one flat colour: that was the light patch at his temple and the grey
  clump. The hair behind his ears smoothed into a mass (it was Rodin's ragged spikes). His neck's
  paint: skin, eased into his hair at the nape (his portrait from behind: hair to the collar).
- **Ready for the face rig**: his MediaPipe points kept (moved with the warp), the mouth, lids and
  eyes untouched by the warp and the neck.
- **His own hat** unchanged, on his head bone; it still comes off when shot (works check).

## Try B: Rodin run 89's own head and neck (no paid calls)

Run 89 (the arms-out dressed model) has its own head with a natural neck and a high collar round it
(`twin_vs_whole.png`). But that head is **15% bigger at the eyes** (eye span 69.7 mm against
60.4) and sits **1.4 cm high and 5.8 cm forward** of the anatomy's eyes. To keep his eyes on the
anatomy (tests/test_bodies.gd) it is scaled to 0.87 and moved back, eased down its neck so it
stays joined to the body: the neck leans back 2.5 cm and folds under the chin. Its face isn't
the portrait man's shape (the portraits land 5-8 mm off its landmarks against 1.4-2.5 mm on the
Oct 14 head), so his moustache and eyes come out smaller and softer. Its fuller hair had to be
drawn in under the hat, and its own paint kept under his chin. **Its neck is not better than A's**
once it is put where the game needs his eyes: that decides A over B.

## The works check (`tools/characters/works_check.gd --ref=` Test 1)

Every triangle's stretch in the game's HumanBody, judged against **Test 1** (`bold_cowboy_whole`,
today's head on the same body), stretched-sheet area in cm² (head and neck sheets in brackets):

| | stand, walk, run | hands up | aim | sit | crouch | ragdoll | hat off | wounds |
|---|---|---|---|---|---|---|---|---|
| Test 1 (today) | 0 | 695 | 12 | 20 | 30 | 37 (9 neck) | yes | yes |
| try A | 0 | 695 | 12 | 20 | 30 | 38 (23 head/neck) | yes | yes |
| try B | 0 | 695 | 12 | 20 | **70** (19) | **473** (83) | yes | yes |

Try A passes every check; its head and neck add no stretch in aim, hands up, sit or crouch, and in
the ragdoll fall 1 cm² more than Test 1 (within the 1.25x allowed). Try B fails crouch and the fall:
its neck, eased back to put its eyes on the anatomy's, stretches when he folds. Numbers in
`works/`. **All tests: 401 passed, 0 failed.**

## What I chose, and why

1. **Try A**, for the reasons above; B is on the sheet for comparison.
2. **The portrait's chin**: the biggest single difference between his face and the portraits;
   without it a neck under his jaw made him look weak-chinned.
3. **His eyes stay on the anatomy's.** From the side his ear is still ~3.5 cm ahead of his
   shoulder joint (as today); with a nape and the collar lowered behind he reads as set on his
   neck. If Sean still sees him forward, his head can go back up to 1.5 cm (the eye test's
   limit) or the anatomy's eyes move (gameplay's).
4. **A turned-down collar** from Sean's arms-out pictures, not a band (he turned down a flat
   band twice).
5. **Smooth paint, not squares**: the game's own pixel pass gives "a bit of square"; the portraits'
   chunky squares were what made the face read as blocks beside his smooth clothes.

## Left for Sean / other sessions

- **His eyes** still read a little narrow under the brim: the Oct 14 head has no lids (paint on a
  bump); the talking face's MakeHuman lids are the real fix.
- **For art:** the white glint on his cheek at the card table (his wet-eye gloss); the saloon
  lamp still turns his skin orange; the game's light steps make flat patches on his face.
- **Try C** (one new Rodin head, $1.60) only if Sean wants a different face shape.
