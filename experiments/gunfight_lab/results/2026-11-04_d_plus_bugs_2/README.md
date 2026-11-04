# D+: the third playtest's bugs (#607, PR #628)

The third blind playtest of D+ (`docs/playtests/2026-11-03-gunfight-d-plus-3.md`) found what you're
told when hit wrong, the gang's hands through panes, and words that didn't fit. Before this: #595
(PR #603, build 3092), `../2026-11-03_d_plus_bugs/`.

## What changed

- **What you're told when hit** (`PlayerWounds.hit_words`): the wound that matters first (heart,
  great vessels, pumping, inside, cord, lung/gut/throat, organs, bones, fingers), up to two parts and
  two effects; "Your ear's shot off." (no ear finger), fingers named together; "It's pumping." only
  for a bleed out at 6 ml/s or more, "You're bleeding inside." for the iliac/liver; the bone that
  takes your gun is always said; your state reads "your", not "his"; pale with a wound says
  "bleeding inside"; out cold you don't press on a wound.
- **Why the gun won't** (`WeaponViewmodel.why_not`): reload/fire/cock with none loaded or none on
  the belt, or the gun put away, says so on the screen and in the bridge's `press`/`shoot`.
- **A hit isn't a near miss** for you (`Ballistics._impact`; for the gang the near miss is still how
  a man knows who shot him).
- **A hand through a pane breaks it** (`OutlawBrain.shot_origin`), and its back-spray spares him
  (`StructureMember.shatter(spare=)`).
- **Your barrel's line** (the crouched-bar shots): the gun is 11 cm under and right of your eye from
  the hip (1.6 cm aimed), so the frieze is real; the bridge's `look` says when the barrel's line
  is stopped though your eye's is clear.
- **Words and states**: one line a man every 1.5 s but for surrender, flight, threats and duels
  (`SAY_GAP`, `SAY_ALWAYS`); "watch it" at most every 20 s; no flanking talk from a man down;
  a man getting up isn't dragged or rescued; "I'm gone!" only when he can go (`_pick_flight`);
  "You damn fool!" only when you did something, "Now, boys!" when it's his idea (`turn_on`); a
  call for help fits the wound; a duel is his own (`duel_with`); the town's "lull" waits for 8 s
  with no shot (`RELIEF_QUIET`); surrendered men aren't shown armed.

## The 200-fight run against main (dcd768b)

`--scenarios=spec_hall,spec_stair,spec_gallery,spec_back,spec_front --hours=golden --weapons=revolver
--styles=careful --bodies=studio --variant=D --fixes=all+pain_fight+floor_fight+odds+flinch
--opening=,shoot --seeds=1-20`. `bugs.md` (`bugs.py`), `moves.md` (`moves.py`).

| | main | this |
|---|---|---|
| Hits on you also logged a near miss | 73 of 389 | 1 of 398 |
| Cut by his own pane | 49 | 7 |
| A second line within 1.5 s | 1,792 of 5,546 | 987 of 4,759 |
| Cussing a friend's shot | 245 | 159 |
| "I'm off" lines / then still within 4 m 10 s on | 43 / 26 | 10 / 2 |
| Drags of a man getting up | 1 | 0 |
| Gun hand through something (pose) | 292 of 2,138 shots | 282 of 2,026 |

The fights themselves (`quits.py`, `pairs.py`): shooting median 49.4 / 25.9 s -> 50.0 / 22.8 s
(they / you open), seed for seed -0.1 s (se 2.8), hits on you +0.04 (se 0.09); you down 58/44% ->
60/48%; anyone quits 28/21% -> 24/17%. Moves the same within noise (drops on arrival 86/31 -> 78/27).
Frame 13.3 -> 12.4 ms here (`perf.py`). D+'s difficulty is untouched (#349 is Sean's).

**Same fight** (`same_fight.py`, `--opening= --seeds=1-4`): this vs the first repeat 20 of 20, the
two repeats 20 of 20.

**Left**: the pose still puts the gun hand through studs, floor boards and doors in ~14% of their
shots (the ball's start was fixed in #595; the drawn arm wasn't): the next step, #633.

## The fourth blind playtest

`docs/playtests/2026-11-04-gunfight-d-plus-4.md`: won 1 of 10. The first run of it
(`playtest_4_first_run.md`) played a build where every hit man also got a near miss, which broke the
gang's turning on you in town (reverted); it was played again. Of its findings, the fingers ("told
of two, four gone"), the collarbone that took the gun untold, and "Pressing on the wound" while out
cold were fixed here. Its top three: the opening's over before you can act (out cold in 11-20 s in
six of ten, hit through walls and panes you didn't know they saw through); which arm is broken
(one stops the gun) and a black-out with no warning; `look` and the ball disagreeing (a post
"stops a ball" then not, "Hitbox", a blank answer, men "clear" missed because they'd moved).
