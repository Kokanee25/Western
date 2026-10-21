# Fix 1: the gang's aim from the gun's state, and a moment to react (2026-10-21)

The baseline's first fix (README "The first fix", the brief's gap 2), as Sean asked: "start with
same sway, can we slow their reaction, not just immediate shooting".

## What changed in the game

- **One sway model for everyone** (`src/weapons/sway.gd`, `Sway`): the player's drift, breathing,
  shake and jerks, moved out of `WeaponViewmodel` unchanged, so the gang's guns wander by the same
  rules as yours.
- **A hand on every gang member's gun** (`src/bodies/gun_hand.gd`, `GunHand`; its dials in
  `config/gun_hand.tres`, `GunHandTuning`): where his barrel really points. It swings onto you
  with a hand's lag (0.1 s, at most 240°/s), so a running man is shot behind. It wanders by
  `Sway`, bigger held low or just come up (2.5 times, settling over a second of holding still),
  crouched less, moving more, and more with fear, pain, shock and rounds cracking past. A hurt
  arm shakes it, his own shot kicks it (the revolver's kick), and a near miss or a ball into him
  jerks it. `OutlawBrain` fires along `hand.barrel()`; `spread_degrees` and its random cone are
  gone.
- **He squeezes when his sights are on you** (`OutlawBrain._sights_on`): when the barrel's
  within his patience of what he's shooting at (your chest, or your head when that's all that
  shows over cover), or once he's held as long as he can. A hothead (Lyle) holds 0.7 s and takes
  a looser sight; a cool man (Brody) waits up to 2 s for a good one; fear rushes him. The squeeze
  itself jerks the gun ("rushed trigger inputs disturb the alignment"), more for a hothead or a
  frightened man, and the shot breaks 0.1 s later. Covering a friend, or shooting at where you
  were, he doesn't wait for a sight.
- **A moment to react** (`OutlawBrain._reaction`): a fight he didn't start, he takes it in
  before his hand moves: 0.3 s for a hothead to 0.6 s for a cool man, up to 0.45 s more for a
  man of no nerve, plus up to 0.25 s. Then the draw (0.5 s), then the settle. Rounds cracking past
  or a hit cut it short. The duel's draw is his own idea, so no pause there.
- **Range judged once a shot**, not every tick (`_judge_range`), so his aim doesn't jitter.

Against a calm man standing in the open (the feel test, Sean's ranges) he's as good as before:
5 m 88% (was 100%, range 60–100%), 15 m 30% (31%, 15–60%), 30 m 21% (13%, 3–30%). 404 tests pass.

## Measured (`compare.md`: the baseline's 360 studio fights against the same 360 after)

| | before | after |
|---|---|---|
| the gang's first shot, median s | 0.85 | 2.08 |
| the gang hits first | 67% | 33% |
| you're first hit at, median s (never) | 0.9 (20%) | 2.0 (34%) |
| a hit takes your gun arm | 21% | 14% |
| the gang's hits a shot | 40% | 34% |
| near misses on you a minute | 47 | 26 |
| fight length, median s | 5.1 | 6.5 |
| in 45–90 s | 2% | 3% |
| you down | 49% | 34% |

By arena:
- **The saloon** has flipped. You start gun in hand 4–8 m from three men whose guns are holstered;
  they now take in, draw and settle (~1.4 s) and you hit first every time. Still ~2 s, now ending
  in their surrender (46%).
- **In the street** you hit first in 92% and they're rarely dangerous (8% of their shots hit, was
  14%; you're never hit in 76%). They fire unsettled: at the shot their barrels are a median
  3.2° off where they meant (8 m: 45 cm), more when frightened.
- **The ambush**, where they start it from cover, is longer (6.0 → 10.2 s) and still theirs (they
  hit first in 92%).

Why they miss (the lab now logs each gang shot's error: `men.<id>.shot_errors` in a fight's
record): the barrel's median error at the shot is 2.4° for a man with little fear, 4.2° for a
frightened one (fear ≥ 0.3); 2.6° (Lyle) to 3.0° (the Kid) by man.

## What it means

It does what it was for. They no longer shoot before you can move, and every miss has a reason
you could see (he'd just come up, he was frightened, a ball had just cracked past him, he
snatched it). But it doesn't make fights longer: the opening now goes to whoever has his gun up,
and the baseline's other reasons are untouched. Men still quit after 0–1 hits (58% of quits),
stand in the open (42% of their fighting time), never flank, and there are no lulls. In the
standoffs that's you, so the street and saloon got easier, not tenser.

Not done, for Sean: the balance. With these dials the street is easy and the ambush is still
theirs. The dials are all in `config/gun_hand.tres` (`sway_aim`, `squeeze_jerk`, `patience_*`,
`hold_*`, `react_*`).
