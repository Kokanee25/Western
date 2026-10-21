# 2026-10-21: a man in the kit chair, its legs shot or kicked out (group U)

Sean (2026-10-21): bodies in the prop lab's chairs, one to three legs kicked or shot out; "if both
back legs are kicked off or removed I want the seated person to fall backwards with the chair and
end on their back". Then: "have his upper shoulders and head lean back more?"

The chair is the prop kit's (`KitProp`, on main since #202): its members, its balance and footing,
`sit`, `take_blow`. The lab's `kit_chair` fixture turns it to face the way he does and puts its
seat point (`seat_position`) over his origin. He sits (`KitProp.sit`) 10 ticks before the cause.
Two causes: `remove` breaks each named member and knocks it clear (shot out), and `kick` gives each
member the chair's own blow (`take_blow`, 48 N·s from a kicking leg of ~8 kg, 0.12 m up). Runs:
`build/physics_lab/u6`, `u7`, `u7r` (rendered) in the session's worktree; old_rancher_s1.

## Sat back (`sit_back`, the new pose)

The upright `sit` leans his trunk over his thighs, so a chair going out from under him puts him on
his face. `sit_back` sits him back in the chair: abdomen 6, chest 12, neck and head tipped back to
keep his eyes level, hands in his lap. Sean asked for it and approved it from the scene video.

| U, rancher | the kick did | he ends | his chest's front up |
|---|---|---|---|
| sit, back legs shot out | | on his back, 0.55 m behind | 0.97 |
| sit, back legs kicked from behind | broke the left; the chair went loose | face down, 0.93 m in front | -0.66 |
| sit, one back leg shot out | | on his side, 1.1 m in front | -0.10 |
| sit, front legs shot out | | on his side, in front and to the right | 0.24 |
| sit, three legs shot out | | on his back | 0.97 |
| **sit_back, back legs kicked from behind** | broke the left; the chair went loose | **on his back**, 0.6 m behind, his legs over the chair | 0.97 |
| sit_back, back legs kicked from the side | broke the left; the chair went loose | on his back | 0.96 |
| sit_back, one back leg kicked | broke it; the chair went loose | on his back | 0.97 |
| sit_back, back legs shot out | | on his back, 0.6 m behind | 0.95 |
| sit_back, a front leg kicked from in front | broke it; the chair went loose | slumped in the chair, which stands on three legs | 0.09 |

- **One kick breaks one leg.** It breaks the back leg it meets, and the rest of its momentum sends
  what's left of the chair loose under him (`take_blow`). The other back leg goes with it, still
  joined, so the chair stands on three legs for 1-2 s before it tips. A sweep that took both legs
  would need the blow to carry on to the next leg in its path (the prop lab's `take_blow`; asked).
- **The front-leg kick looks wrong.** His weight is back, so the chair stands on its other three
  legs. But a chair that goes loose sends its man limp (`KitProp._unseat`), so he slumps in it as
  if knocked cold. That's the prop lab's ask of gameplay: a conscious man who loses his seat
  catches himself or staggers. It's not fixed here.
- **His pelvis sits 3 cm into the seat.** While he's seated his pelvis is 3 cm into the seat
  (`ground_penetration` 0.03-0.04 m once he's limp, easing out over ~10 ticks). It was the same
  before the kit chair reached main (0.029); it reads as a flag only at the line.
- **Test:** `tests/test_seated_falls.gd`: sat back, back legs kicked out from behind, he ends on his
  back behind where he sat. It fails with the upright `sit` (face down, 1.08 m in front).

## The scene (Sean's ask)

`scenes/chair_kick_shot.gd`, played by `scenes/play.gd`: a man sat back in the chair; another kicks
out both its back legs (the kick pose; the legs broken by script, since one `take_blow` breaks only
the leg it meets, below); he goes over with it; the kicker draws, walks over and shoots him in the head with a ball through
`Ballistics`. Footage sent to Sean, not in git.

## A blind critic (one fresh sub-agent; the two sat-back kicked sheets)

It scored the kick from behind 4 and the kick from the side 2. In both he ends on his back with his
legs over the chair. Its top three:

1. **The chair stands too long.** It stays level on three legs with a man leaning back, for 1 s
   (from behind) and 2 s (from the side). This is the one-leg kick above.
2. **He goes limp instead of reacting.** His head drops back and his arms hang like a man passed
   out; a man taken by surprise would grab the seat and tuck his chin. This is the prop lab's ask
   (a conscious man who loses his seat catches himself).
3. **Kicked from behind, he rolls face-down on the way.** The chair tips back and to the left, the
   way the broken leg was, so he twists hat-first before coming onto his back.
