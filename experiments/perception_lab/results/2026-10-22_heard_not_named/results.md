# Fix 1: a sound doesn't name its maker (2026-10-22)

Sean's OK on #240. Problem 1 of the baseline (`../../baseline/baseline.md`): every man who heard a
shot knew who had fired, seen or not, and a shot or a hit anywhere in town was judged against the
shooter by every outlaw.

## The change

- `Senses._on_noise`: a sound is filed under the man who made it only if the listener sees him, or
  has him in view as he makes it (`_in_view`: in his eye's reach, a clear line, light enough).
  Otherwise it goes in `sounds` (`{at, kind, time}`, the last 8; `last_sound(kinds, within)`) and
  `heard` is sent with `who` null.
- `OutlawBrain._on_deed`: a shot's deed (`shoot_at`, `hit`, `kill`) against someone else, by a man
  he can't see, is judged only if the shot he heard (within 1.5 s) came from where that man could
  be: within 3 m of where he last knew him plus 2 m a second since (`_could_be`, `MAN_SPEED`). At
  him, as before: the ball tells him which way.
- `OutlawBrain._on_heard`: hunting a man he can't see, a man's sound (steps, a shot, a voice) where
  that man could have got to he takes for his, unless one of his friends is right there; so he can
  be fooled (a sound another man makes there). Calm, an unplaced shot unsettles him a little
  (`STARTLE_FEAR` 0.04) and turns his head its way for 2.5 s (`_social`).
- `CivilianBrain._on_deed`: he credits the player with running off the men who troubled him only
  for what he saw.
- Tests: `test_senses` (a shot behind him: heard and roughly where, not who; a shot from a man in
  front of him names him, the same behind a wall doesn't; footsteps behind him are somebody's),
  `test_gang` (a far man isn't set against a shooter he didn't see; a hunter takes steps where you
  could be for yours, not steps 40 m off). Both new tests fail on the old code.

## Measured (the whole lab, before and after, the same lab and seed, each run twice: the same)

| group | judged | as expected | missed | false | slow | leaks |
|---|---|---|---|---|---|---|
| sight | 50 | 33 → 33 | 4 → 4 | 5 → 5 | 8 → 8 | – |
| hearing | 41 | 28 → **36** | 4 → 4 | 9 → **1** | 0 | – |
| search | 8 | 6 → 6 | 2 → 2 | 0 | 0 | 5 → 5 |
| news | 12 | 7 → **10** | 2 → 2 | 3 → **0** | 0 | 0 |
| leaks | 6 | 0 → **3** | 0 | 6 → **3** | 0 | – |
| **all** | **117** | **74 → 88** | 12 → 12 | **23 → 9** | 8 → 8 | 5 → 5 |

Exactly the 14 judged results the fix was for changed, all false → as expected: the 8 listeners
who couldn't see the shooter no longer know who fired (the one in the saloon who had him in his eye
still does, rightly); the storekeeper, deputy and passer-by no longer know who from the sound; the
far outlaw holds nothing against the player (IGNORE, no pressure, no grudge, doesn't know who),
turns toward the shot instead. Nothing else moved: sight, the searches (to the metre and the
second) and every other verdict are the same. At night the hunter still follows the player's
footsteps 1–4 m off; the lab's log now reads them as "couldn't tell whose", taken for the
player's.

`before_tables.md` / `after_tables.md`: every case.

## Still open from the baseline

The other 9 falses: smoke and dust (4), the dark saloon with its lamps out (1), steps on dirt heard
at 5 m (1), a friend's fall known through a wall (2), the call-out's true position (1). The 12
missed and 8 slow are untouched (night sight, windows, news, the cocked hammer, the 60 m shout,
45 m by day). The gunfight lab (branch `claude/gunfight-lab-arena-measures-ifll1r`, not merged)
should run its baseline again once it's merged with this: its gang knew a hidden shooter by name.
