# The perception lab's fix 1 in the gunfight (2026-10-22)

The perception lab (issue #240; on its branch when this ran, since merged as #263, build 2103)
asked for the gunfight lab to be run again with its fix 1: a heard sound tells a man where, not
who; a man hunting you takes a sound where you could have got to for yours. Here: today's main
against main with that branch merged in locally (a scratch branch, never pushed). The same 240
fights, variant C: the street (120: golden and night, revolver and shotgun, the bot holding,
moving cover to cover and pushing, 10 seeds) and the saloon with your opening (120, guns away).

## The fairness check, widened

`fight.gd` now also flags a man who, with no line from his eyes to you and nobody telling him
(no friend's shout naming you, no ball of yours past him), places you further than you could have
walked since he last knew where you were. "Could have walked" is the perception lab's own
reckoning: 3 m plus 2 m a second. Every flag records what each ray from his eyes to you hits.

Two false alarms were taken out of it on the way:
- A man shouting the moment he came round into sight (the line was sampled every 0.1 s): each flag
  now also tests the line at that moment.
- A friend's shout landing later in the same tick than the check: a flag is now held 0.2 s.

## What changed

| | street before | street after | saloon before | saloon after |
|---|---|---|---|---|
| fight length, median s | 17.3 | 20.3 | 8.3 | 8.6 |
| in 45–90 s | 9% | 17% | – | – |
| you down | 12% | 8% | 37% | 30% |
| the gang hits first | 7% | 3% | 32% | 32% |
| longest quiet, median s | 7.7 | 9.6 | – | – |
| re-placed you unseen (all) | 2157 | 2572 | 433 | 445 |
| looking for you: found / gave up | 66 / 130 | 63 / 101 | 20 / 14 | 20 / 16 |
| cover given up the moment he got there | 47 | **95** | – | – |
| time stuck on the way to cover, s a fight | 0.21 | 0.44 | – | – |
| unfair (knew where you were with nothing to tell him) | 0 | 1 (borderline) | 0 | 0 |

`street_compare.md` and `saloon_compare.md` are the full tables. Their "unfair" row (0 and 9) is
from before the 0.2 s hold. Re-running the 9 flagged fights with it leaves one: Lyle, behind the
saloon's front wall, places you 7 m from where he saw you 2.2 s before, right at the edge of the
3 m + 2 m/s reckoning, from your steps. That's the fix working as designed.

## What it means

- **No leak, before or after.** In a three-man gunfight you're the only enemy, so any shot is
  plausibly yours. The leak the perception lab fixed (a far bystander set against you by a shot he
  never saw) doesn't happen here, and the gang never knew where you were by magic in 480 fights.
- **In the street, fights run longer and you go down less.** The men give up looking for you less
  often (130 → 101) because they follow your sounds. Longer lulls, more decisions, fewer quick
  hits on you. That is a side effect of the hunting change, not a fairness fix; nobody played it.
- **A new interaction for the perception session.** Cover dropped on arrival doubles (47 → 95) and
  time stuck doubles. A man judges whether his spot hides him from where he *thinks* you are.
  Taking sounds for you moves that guess more often, so a spot he chose goes stale before he
  reaches it. It's the cover-on-arrival fault already listed in `../2026-10-22_abc/`, made worse.
  Suggested fix (gunfight lab's, next): choose and check cover against the same guess, and leave a
  spot only on a seen threat or a ball, not a re-guessed sound.
- **The saloon is unchanged:** still the quick draw.

Tests on the merged scratch branch: `test_senses`, `test_gang`, `test_perception_lab`,
`test_outlaw_tactics` and `test_feel` all pass.
