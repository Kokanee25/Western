# The wince (on trial, 2026-10-23)

Sean: "If ai shot give them a wince and a temp hide to evaluate their wound." Variant D's `wince`
(`OutlawBrain._start_wince`, `_wince_step`, `_seen_wound`), not yet in `D_FIXES`: the lab's
`fixes=all+wince`. When a man is hit and stays on his feet:

1. He stops shooting and gets out of your sight: back behind his cover, or to cover within 6 m, or
   down low where he is if there's none.
2. Once he's there, he looks at the wound (his eyes on it through `FaceLife.attend_to(…, true)`,
   hunched over it behind a wall: HumanBody's `wince` pose). He looks for 2 s times 1–1.6 by how
   green he is, less 45% of it for a hothead, ×1.5 for a severe wound, ×0.5 for a graze.
3. He judges it. **Light** (no bone, not bleeding past clotting at 4 ml/s, his gun arm holds): it
   frightens him half as much as it did, he says so ("Just a scratch."), and he's back up soon.
   **Bad**: he says so ("Oh God, it's bad...", "My arm! Can't hold the damn thing!"), and what
   happens next is up to his fear and his blood.

## The numbers

Each column is 100 fights (5 setups × 2 styles × seeds 1–5 × both openings), on today's main.

| | opening | shooting s (med) | 20 s+ | 45–90 s | anyone quits | hits on you | you down |
|---|---|---|---|---|---|---|---|
| D (`base_now.md`) | they | 17.1 | 40% | 12% | 80% | 1.1 | 24% |
| D + wince (`wince.md`) | they | 15.3 | 38% | 14% | 78% | 1.2 | 22% |
| D | you | 14.7 | 36% | 8% | 84% | 0.6 | 8% |
| D + wince | you | 16.3 | 46% | 10% | 80% | 0.8 | 16% |

At 50 fights a row, every difference here is within noise: **the wince doesn't lengthen fights.**

- 176 winces started, and 95 were judged: 33 light, 62 bad. The rest ended in a second hit, a fall
  or breaking.
- Most wounds judged bad bled past clotting: a .45 ball through flesh bleeds more than 4 ml/s.

## Why it can't lengthen them yet

**A hit man almost never shoots again**, with the wince or without it. Of 459 hits on men (one
ball can make two hits: forearm and chest), the man fired again after only 45–48, about 4 s
later. Every other hit man was out of the fight.

The reason is pain. A ball through a bone is 0.55 of pain on its own, plus the muscle and the
track. Adrenaline hides 45% of it (`config/physiology.tres`), and Brody's arm in the film is still
at 1.17 against the 0.9 at which "he can't do anything but hold the wound" (`pain_disabling`).
Above that, `_peek` ducks him back and `_fight` has him clutching it. So the wince only overlaps
time he was already spending out of it.

Gunfights of the period had men fight on hit. At the O.K. Corral, Virgil Earp was shot through the
calf and Morgan Earp across both shoulders, and both kept shooting. Frank McLaury was shot in the
belly, walked his horse across the street and kept firing. The lever for longer fights here is the
pain a fight lets a man fight through, not the wince.

## The film

`brody_hit_arm.mp4` (9 s). The lab's sure shot (`gf_hit`) puts a ball through Brody's left arm and
breaks the bone. He shouts "He got me!", goes round behind the bar, gets down low over it, and says
"Oh God, it's bad...". The follow camera (`gf_watch`) ends up too close once he's down.

Lab commands added: `gf_hit`, `gf_aim`, `gf_watch`, `gf_minds`, and `fixes=all+x`.
