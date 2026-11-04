# The second D+ playtest's bugs (2026-11-03; issue #595, PR #603; branch `claude/gameplay-d-plus-bugs-l6b180`)

The blind playtest `docs/playtests/2026-11-03-gunfight-d-plus-2.md` found five things. What each
was, what changed, and how it was measured. The third blind playtest, on this branch:
`docs/playtests/2026-11-03-gunfight-d-plus-3.md`.

## 1. Their shots and yours: partly real

"My sights on a man's middle were on a stud, post, joist, batwing or balcony board, while they kept
hitting me from the same spot." Both sides fire through the same `Ballistics` with the same
cartridge (`config/revolver.tres`); batwings and balustrade boards are ordinary members to both; the
gang's ball excludes only his own parts, yours only you. Two real differences:

- **His ball could start past what his gun hand was through.** The lab now records, for every gang
  shot, what stands between his eye (and his chest, his gun shoulder) and the muzzle
  (`muzzle_probe`, `fight.gd`). On main 16% of their shots left a muzzle with a floor board, a pane, a
  wall board, a stud or a door between it and his own eye: men fighting from the floor with the gun
  hand through the boards, men at a window or a wall with it through the glass or the siding. A ball
  that starts inside a board isn't stopped by it, and 35 of the 406 hits on you came from those
  shots. Your shot has always been guarded against this (`WeaponViewmodel._shot_line`: the camera
  to the muzzle); now his is the same (`OutlawBrain.shot_origin`: the ball leaves where the line
  from his eye meets it). Left: his own hat (skipped by the fix, not by the probe). Test: "his ball
  meets what his gun hand is through" (`test_outlaw_tactics`).
- **The bridge's `look NAME` aimed at his chest only**, while the gang aims at your head when
  that's all they can see (`_aim_point`). `look NAME [PART]` now faces any part of him and says
  what's in the line (`in_the_way`, with whether a ball goes through it as Ballistics charges it)
  and which of him you can see (`clear_to`). Test: "look at a man says what you can see of him".

Not changed: their aim, their cover, their speed (D+'s difficulty is Sean's, #349).

The deeper fault under the first: men's hands and guns pass through walls, panes and floors in
their poses. Fixing the shot keeps the rules the same; a man whose gun hand is through a pane now
breaks it and can be cut by its glass (GlassCuts throws a fifth of the shards back), which the third
playtest read as "Lyle's own shot wounded Lyle".

## 2. The Kid stuck "rescuing" Brody

Under `rescue_way` a man gave a rescue up after 8 s (or stuck 2 s), waited 12 s, and went again:
"Hold on, I got you!" every 20 s. Now a friend he ran for and couldn't reach, or took hold of and
couldn't move (stuck with him moved under a metre), he doesn't go for again while the friend lies
there, unless his way to him is now half as long (`_unreachable`); his decisions say "give up on
Brody: can't get to him" / "can't get him out". Test: "a friend he can't get to he gives up on"
(`test_gang`; fails without the fix: a second "Hold on").

What repeats are left are drags that worked: one fight traced (spec_hall seed 10), every repeat's
friend had been moved 2-6 m or hidden at once, and went for again only once you'd moved and he
lay in the open again; the one that couldn't move him gave up and didn't go back.

## 3. Your gun lost without a word

A broken right upper arm puts the revolver away (`Physiology.can_hold`). Now the screen says why
when it goes ("You can't hold the gun: a broken upper arm.") and again when you try to draw, fire,
aim or reload (`PlayerWounds._tell_gun`, `Physiology.why_cant_hold`,
`WeaponViewmodel.why_not_usable`); the bridge's `weapon`/`shoot` answers and `read`'s weapon line
say it; the screen's lines are in `events` (`screen`). Shooting left-handed isn't added. Tests:
`test_gun_arm`, `test_dev_bridge` "a gun you can't hold says why".

## 4. Dead, then up

The physiology was right ("Dead (brain)"); the game brings a dead player round at the doctor's
on purpose (DESIGN.md §3, `test_killed_you_still_wake`), and the lab let it, 4 s after its fight
had ended. Now the lab holds you as you fell once its played fight is over
(`PlayerWounds.stays_down`), and `gf_result` says how you are (`you`). Test: "held down you stay
down" (`test_come_round`).

## 5. The small ones

- Out cold isn't backing down: the stand-down lines ("That's better.", "Smart.", "Go on, then.")
  aren't said over you (`_social`). Test: "out cold you haven't backed down" (`test_standoff`).
- "Hey! That was me!" is "Hey! Mind where you're aiming!" (two lines still: the dice draw the
  same). How often they cuss a friend's shot is main's (2.3 a fight here, 2.6 on the branch).
- A run lets go of the keys in time to stop on the spot (its stopping distance at
  `ground_decel`) and answers once you've stopped, with `crouching`; the walk help says a run
  stands you up from a crouch, as the run key does. Test: "a run stops where it was sent" (on main
  you slid on after the answer).

## The runs

400 fights: the five `spec_*` setups, golden hour, the revolver, the careful player, Studio bodies,
D+ (`all+pain_fight+floor_fight+odds+flinch`), seeds 1-20, both openings. Base is main (8d22859)
with the lab's `muzzle_probe`; fix is this branch. Each from its own copy of the tree, side by side,
two jobs each (part of it beside the playtest's game). None failed.

```sh
python3 experiments/gunfight_lab/run.py --scenarios=spec_hall,spec_stair,spec_gallery,spec_back,spec_front \
    --hours=golden --weapons=revolver --styles=careful --bodies=studio --variant=D \
    --fixes=all+pain_fight+floor_fight+odds+flinch --opening=,shoot --seeds=1-20 --jobs=2 --port_base=9050 --out=build/gf/fix
python3 experiments/gunfight_lab/results/2026-11-03_d_plus_bugs/bugs.py build/gf/base build/gf/fix --out=bugs.md
python3 experiments/gunfight_lab/moves.py build/gf/base build/gf/fix --out=moves.md
python3 experiments/gunfight_lab/quits.py build/gf/<run> --out=quits_<run>.md
python3 experiments/gunfight_lab/results/2026-11-01_posts/pairs.py build/gf/base build/gf/fix   # pairs.txt
python3 experiments/gunfight_lab/perf.py build/gf/base build/gf/fix                             # perf.txt
python3 experiments/gunfight_lab/same_fight.py build/gf/fix build/gf/same_b                    # same_fight.txt
```

| Measure | Base | Fix |
|---|---|---|
| Gang shots from past something (eye to muzzle) | 347 of 2,113 (16.4%) | 14 of 2,140 (0.7%, his hat) |
| ...of them hit you | 35 (of 406 hits) | 2 (of 389) |
| Rescues ("drag") | 154 | 130 |
| The same friend 3+ times | 23 | 12 |
| Shooting s (median), they draw / you first | 49.5 / 26.4 | 49.4 / 25.9 |
| Hits on you | 2.2 / 1.9 | 2.1 / 1.8 |
| You down | 62% / 49% | 58% / 44% |
| Runs to the time limit | 2 | 8 |
| Frame (perf.py) | 13.2 ms | 12.1 ms |

- **Seed for seed** (`pairs.txt`): shooting 1.9 s longer (SE 2.2), hits on you 0.09 fewer (SE
  0.07): inside the noise. You go down a little less with the balls through boards gone.
- **Moves** (`moves.md`) and **quits** (`quits_*.md`): as base (stays, drops on arrival, posts,
  climbs; quit rates and first quits within the noise).
- **The frame**: the gang's brains 1.52 -> 1.44 ms here; one more ray a shot.
- **Determinism**: `same_fight.py`, the fix run's 20 fights (seeds 1-4, every setup, they draw)
  against the same 20 run again from the same tree: 20 of 20 the same (`same_fight.txt`).
