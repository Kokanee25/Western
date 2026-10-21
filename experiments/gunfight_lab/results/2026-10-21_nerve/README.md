# Fix 3: shaken, not broken (2026-10-21)

Sean: "Yea", to "their nerve next: a hit man fights on from cover, and a friend falling doesn't
make the rest quit". The baseline's reason 2: men quit on no hit or one.

## What the lab found first

The lab now keeps a fear ledger for each man (`men.<id>.fear_from`: every rise in his fear put
down to what caused it that tick, the strongest when several land at once) and, when he quits,
what he'd been through (`men.<id>.quit`: when, how, his fear and nerve, hits, the ledger, and his
tactic the tick before). On the 360 studio fights before the change:

- **Brody and Lyle quit on hits** (77% and 73% of their fear): one ball adds ~0.8 fear (median),
  so a single good hit puts the cool leader (nerve 0.95) past his nerve on the spot, median 1.9 s
  into the fight. When he gives up, his "throw 'em down" carries the frightened ones with him.
- **The Kid quits with no hit** in 182 of his 287 quits: his nerve is 0.3, and a friend going down
  (0.12, 0.19 for the leader) plus "it's going badly" (0.15) and a near miss or two is past it.
- Nobody gets their nerve back: fear settles 0.01 a second, so it only ever climbs.

`body_hits_to_stop` (Sean's range 1.2–2.3, "he can take too many gunshots") measures a man in the
open at 8 m; whatever changed had to leave him as he is.

## What changed in the game (`OutlawBrain`)

- **Shaken first** (`_shaken_holds`): past his nerve behind cover, on his way to it, or looking for
  new cover when you've come round his, with his gun in his hand, he goes to ground rather than
  quit on the spot: head right down, no peeking or shooting, no going round on you, no going
  looking for you; he says so ("Stay down... stay down..."). He breaks after all if it hasn't
  passed in `shaken_seconds` (6), or once he's `shaken_margin` (0.5) past his nerve. In the open,
  down, or with no gun he breaks at once, as before; so does a man told to drop it up close.
- **His breath back behind cover**: hidden with nothing cracking past him, his fear settles
  `fear_settle_in_cover` (0.08) a second, not 0.01. Your gun kept on his spot frightens him 0.045
  a second (the game's `aim_at`, as before), so covering his spot keeps him down longer. When it's
  under his nerve again he's back in it ("Still here, mister!").
- Friends' orders are as they were: the leader's "throw 'em down" still carries a frightened man,
  "fall back" a shaky one.

Tests: `test_outlaw_tactics` gets three (shaken behind cover he gets his nerve back; kept at it he
breaks in the end, not on the spot; far past his nerve cover doesn't hold him). The rest pass
unchanged, `body_hits_to_stop` at 1.54 as before; 440 tests pass.

Three turns to get here (each on the same 360 fights): with a 0.3 margin and fear settling only
when you'd stopped shooting at anyone, fights went 7.2 → 8.7 s and most shaken men still broke
within a second; the ledger showed why: a hit put them past the margin, and a man with his head
down lost sight of you and went looking (not cover, so he broke), or broke in the one tick between
his cover being come round and his looking for more.

## Measured (`compare.md`: the same 360 studio fights before and after)

"Before" is this branch on today's main (ef65876) just before the change. Frame cost is the same:
the three men 3.11 → 2.99 ms a frame here, the people's p95 14.6 → 13.7 ms.

| | before | after |
|---|---|---|
| fight length, median s | 7.2 | 10.1 |
| the street | 12.7 | 16.9 |
| the saloon | 3.3 | 5.8 |
| the ambush | 11.2 | 11.7 |
| in 45–90 s (the street) | 3% (3%) | 5% (10%) |
| quits a fight on 0 / 1 / 2+ hits | 0.53 / 0.57 / 0.90 | 0.34 / 0.54 / 1.02 |
| shaken / rallied a fight | – | 0.72 / 0.33 |
| longest quiet, median s (the street) | 3.3 (5.0) | 4.0 (7.6) |
| you down | 27% | 31% |

Of 259 times a man went to ground shaken: 104 rallied, 26 tended a wound, 19 were still down at
the end, 14 broke after the six seconds, 89 broke sooner (a hit or near miss past the margin, a
friend's order) and 7 went down. The Kid rallies most (81 times).

A street fight from the run (golden hour, revolver, holding the trough, seed 7; 54.6 s): Brody's
hit in the arm and belly running for cover at 0.9 s. Before, that was his surrender on the spot,
and the fight was over at 3.1 s (Lyle and the Kid each hit once and giving up). Now he goes to ground ("Lord, get me out of this one"), and at 3.3 s he's back
("Still here, mister!"), tends the wound twice, fights on, and gives up only when a second ball
takes him in the chest at 21.5 s. The Kid goes to ground at that, holds six seconds while Lyle
reloads, then calls "fall back" and runs; Lyle hunts you for another 25 s and loses you.

## What it means

Fights have a middle now: a hit man drops behind his cover, you don't know if he's done, and he
comes back up. The street, where they can get to cover, gains most (a third longer, three times
as many in 45–90 s, lulls half again as long). The ambush hardly moves: there they hit first and
it's you who goes down (63 → 68%). Still only 5% reach 45–90 s; what ends fights now is the
first good hit (a man hit hard in the chest is past the margin, and that's Sean's 1–2 good hits)
and the leader's give-up carrying the rest.

Not done, for Sean: the dials (`shaken_seconds`, `shaken_margin`, `fear_settle_in_cover` on
`OutlawBrain`), and whether the leader's surrender should carry a man who's got his nerve back.
The new lines (shaken, rally) are text; they'd need recording with the rest.
