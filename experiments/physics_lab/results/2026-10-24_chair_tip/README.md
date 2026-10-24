# 2026-10-24: the chair falls, what was left (group U)

Sean's six (from the chair, brace and get-up rounds, `../2026-10-21_chair/`, `../2026-10-22_brace/`,
`../2026-10-22_get_up/`):

1. He drops instead of tipping: with both back legs gone the chair folds flat and he sinks before
   lying back. It should pivot back on its front legs, his head and shoulders leading.
2. A side sweep reads as the chair exploding (pieces fly sideways), and he falls as when kicked from
   behind. He should twist with the sweep.
3. His head lolls back for a beat as he goes over, like a man out cold, even with the brace.
4. Getting up: he ends stiff with dead arms, ignores his hat, holds too long on all fours, and
   sometimes kneels into the chair's wreckage.
5. A real kick: the kicker's foot should strike the chair and drive `KitProp.take_blow`, not legs
   broken by script; a man or the player kicks a chair's legs out.
6. A film of a saloon fight catching a man seated.

Measured with `chair_measure.py` (new: tip or drop, the head on the chest, the turn, the pieces, the
rise; from `chair.csv` and `man.csv`, which `lab_runner.gd` now writes for the kit chair). Runs:
`build/physics_lab/u_main10` (main, in a worktree) and `u_r3` (this branch), all of group U, 10 s;
`jit_main_N` / `jit_new_N` the falls under `--jitter=1..4`.

## What was wrong, and what changed

- **The chair lost its back.** A kick or a ball broke the whole back post (floor to crest), so the
  crest and spindles fell away with it: nothing was left to tip, and 13 pieces flew. Now a leg goes
  below the seat only (`KitProp.knock_out`, `Structure.cut_member`'s `chunk`: one stick), the post
  above held by its joints to the seat and crest (the support graph has no "hangs from", so as a
  hung prop's nailed members: held, not a foot). 5 pieces.
- **His pelvis rolled on the seat.** The seat tipped back 33 degrees under him while his pelvis
  turned 9: a capsule rolls on a box, a man's buttocks don't. His feet stayed planted, his legs'
  tone pushed his knees up and he folded forward and sank. Now he rides it over (`HumanBody.ride`):
  his pelvis held to the seat until it's past 50 degrees or 0.7 s. (Made the same tick as the
  chair's body, the hold put his pelvis 8 cm into the seat; a tick later, 3.4 cm, as he sat.)
- **His back was in the chair's.** Sat back, his chest was 3.6 cm inside the crest and spindles, so
  the ragdoll's first move was a shove forward out of them. The seat point 2 cm forward
  (`assets/props/kit/chair.json`): 1.7 cm, inside the engine's slop. (4 cm forward put his weight
  inside the three legs that are left when one back leg goes, and he sat on.)
- **The head and lumbar had almost no tone.** The tone's per-step limit is reckoned on the pair it
  joins: the neck (1 kg) and abdomen are light links, so the neck got 13 N·m/rad of the 40-90 asked
  and the lumbar 96 of 190, and a ball joint passes no turn on. `TONE_BRIDGE` also puts their tone
  across them, head on chest and chest on pelvis, where the heavy parts set the limit. The loll
  (head back on the chest) went from 36-42 deg to 0.
- **The brace curled him toward his knees** (right for a man shoved over on his feet); in his chair,
  with its back behind him, it folded him away from it. No curl while he rides. A seated man's legs
  aren't a stance column either (they were held 6 times harder: struts that pushed his knees up).
- **The sweep passed nothing into the chair.** Until it snaps, a leg is part of the chair and
  pushes it: the momentum the inelastic knock has passed when the wood's taken all it can (25 N·s of
  a 48 N·s kick to an oak leg) now goes into what's left where the boot met it. A sweep drags the
  chair's back sideways: he goes over twisting with it (head 0.35-0.6 m that way by 1 s, shoulders
  turned 12-22 deg; kicked from behind, 0.01 m and 2 deg).
- **Kicked-off sticks** fly clear of the rest of the chair (still under the seat, the chair and he
  held one by friction as if it were a leg), at 0.4 of the boot's speed, tumbling end over end.
- **A sway takes a three-legged chair over**: the kit's balance rule gives a seated man a sway's
  width; now the chair goes loose moving out over that edge, and he with it (`go_limp`'s push).
- **Getting up** (`HumanBody._rise`): a heading clear of what lies round him (`_rise_blocked`: small
  balls where his knees and feet go); on his back with his legs over the chair, he rolls off it onto
  his side and front and comes up the other way; face down with the wreck at his feet, he crawls on
  and comes up ahead. His hat, if it's lying within a shuffle of where he kneels, picked up from one
  knee (`kneel_reach`, `reach_to`), slapped on his thigh and put back on (`wear_hat`; it used to be
  hidden for good); else he brushes himself off. Shorter on all fours (0.8+1.0 s to 0.55+0.7). His
  arms swing on as he comes to his feet. Loose pieces are spared by the `rubble` group, not a
  64-hit shape query (in the saloon it missed the chair: it hit his foot and broke a board).
- **A real kick.** `HumanBody.kick(at, front|sweep)`: the knee drawn up, the boot snapped out to the
  target (worked from his hip's height and his leg) and back; struck through the clip's test
  (`_strike`, shared with `_clip_strikes`), so `KitProp.take_blow` decides. A front kick from the
  side goes through the near back leg into the far one (the blow's line a boot wide, level); a sweep
  from behind takes both; a front kick from behind goes through the back leg into the front one on
  that side. `kick_spot` says where to stand. The player: `PlayerKick` on E (your leg draws up and
  snaps out; a sweep at boot height ahead of you). The lab's `kicker` cause (groups
  `U_kicker_*`) and the chair scene use it: no leg is broken by script.

## Numbers (main -> this branch, 10 s runs)

| U | drops 15 cm (s) | head back then (m) | loll (deg) | pieces | head sideways at 1 s | legs in wreck rising (s) | hat back on |
|---|---|---|---|---|---|---|---|
| sit_back, back legs kicked from behind | 0.35 -> 0.35 | -0.13 -> **+0.07** | 42 -> **0** | 13 -> 5 | -0.06 -> 0.01 | 3.57 -> **0.63** | no -> no |
| sit_back, back legs kicked from the side | 0.33 -> 0.43 | -0.13 -> +0.02 | 37 -> 0 | 13 -> 5 | 0.10 -> **-0.56** | 3.37 -> 0.92 | no -> **yes** |
| sit_back, one sweep (80 N·s) | 0.33 -> 0.45 | -0.12 -> +0.03 | 37 -> 0 | 13 -> 5 | 0.05 -> **-0.34** | 3.32 -> 0.70 | no -> **yes** |
| sit_back, back legs shot out | 0.32 -> 0.35 | -0.11 -> +0.07 | 36 -> 0 | 13 -> 5 | -0.04 -> 0.01 | 3.17 -> 0.57 | no -> no |
| sit_back, one back leg kicked | 2.0 -> 1.55 | -0.43 -> -0.11 | 42 -> 0 | 4 -> 3 | 0.07 -> 0.29 | 1.65 -> 1.20 | no -> no |
| sit, front legs shot out (face down) | 0.50 -> 1.05 | -0.62 -> -1.01 | 61 -> 26 | 7 -> 7 | | 0.0 -> 0.02 | no -> no |
| a man's front kick from his side | | -0.04 | 1 | 5 | -0.50 | 0.25 | no |
| a man's sweep from behind | | -0.15 | 7 | 5 | 0.08 | **3.5** | yes |
| a man's front kick from behind (back and front right legs) | | -0.22 | 44 | 5 | -1.22 | 0.45 | no |

("Head back then": how far his head has gone back by the time his hips have dropped 15 cm: a tip
leads with the head, a drop doesn't. The face-down falls go forward, so theirs is negative.)

Under jitter (4 runs a fall, five falls, the fall only): joints more than 5 deg past their limits
1431 -> 832 part-ticks, twist 579 -> 521. The lab's per-tick flags over the whole run still read his
getting up as ragdoll motion (launch, discontinuity, bounce), as in the get-up round: not comparable.

## Blind judge

Two fresh sub-agents, each shown six pairs (main and this branch, X and Y in random order; keys
`key_round*_fall.json`, `key_round*_rise.json`) and the two kick runs alone.

- **Round 1** (`judge_round1.md`): **this branch 4, main 0, even 2**; the kicks 4 and 4 of 10. Its
  faults: getting up popped (legs flung up rolling off the chair), the kick barely visible and the
  kicker a statue, broken legs flying 1-2 m spinning, the brace's arms rigid and level. Round 2 took
  the first, third and fourth and part of the second (above).
- **Round 2** (`judge_round2.md`): **this branch 5, main 0, even 1** (all three falls; in two rises
  main's man ends with his shins inside the broken chair, this branch's rolls off it and crawls up;
  one picks his hat up); the kicks 4 and 3 of 10. Its faults, most first: bodies through things
  (main's shins in the chair; the swept-from-behind man's in it; the two men overlapping), the kick
  still hard to read and the kicker a mannequin who walks into the man falling, a fold forward in the
  front-legs and one-leg falls, posed arms (sat with his forearms out like a tray, the brace's flat
  hand, every run ending in an A-pose), a dip back to a kneel as he rises.

## Left

- **One back leg out:** he goes over at 1.5-2.8 s, his legs propping the chair (feet on the floor,
  knees held by tone, his hips held to the seat) until his tone fades. Main: 2.0 s.
- **Swept from behind by a man:** face down, both ways up blocked by the wreck: 3.5 s in it.
- **His hat:** picked up only when it lies within a shuffle (0.6 m) of where he kneels: in 3 of the
  9 falls above; further off he leaves it (a walk to it is the brain's, not the body's).
- **The kicker:** stands square and rigid as he kicks (no arms, no lean worth the name) and the
  lab's steps back blindly, into the man falling; in the game it's a brain's to do (`OutlawBrain`
  has no kick yet). The judges' worst left fault with the posed arms.
- **His arms:** sat back, his forearms are held out over his lap (`sit_back`); the brace still
  reads as a "whoa"; on his feet he ends in the stand pose.
- **Rising:** he dips back to a kneel once on the way up (the `kneel_reach`/`hands_knees` order).
- **The card cheat's no-clip path** still breaks the legs by script: Cody kicks backwards there, and
  `kick` does front kicks and sweeps.

## Getting up off his back by a clip (Sean: "go ahead", the Uthana takes)

Three takes of a get-up from his back made in the Studio (`motions/get_up/`, 3 Replicate runs; its
ledger's hand-set price $1.50) and retargeted (`assets/animations/get_up_back.json`, take 3; take 1
walks). On his back, `_rise` plays it (`_rise_on_clip`) in place of the staged poses: the rig made
where he lies, the clip's frame turned to his lie, its travel off (it walked him into the wreck and
onto the table). Before it plays, every thigh, shin and foot the clip puts down, at each half second,
is tested where he lies (`_clip_leg_spots`, `_legs_clear`); if any is in the chair, he slides along
his back toward his head (or aside) to the first spot where none is, over the clip's first second.
`U_table_back_legs_kicked`: legs in the wreck as he rises 0.38 s (staged poses 0.6-0.9 s; the clip
without the slide 2.5 s). On his back he no longer picks up his hat (the clip has no reach for it).
Film: `build/video/get_up_clip_clear.mp4` (sent to Sean).

## The proposed patch to human_body.gd

`human_body.patch` beside this file is the whole change to `src/bodies/human_body.gd` against main
(Sean: "changes to human_body.gd come to me as a proposed patch with sheets and footage before
merging").
