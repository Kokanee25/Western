# Playtest: the sheriff on the road

Read `tools/playtest.md` first (how to start the game, the commands, the report). This brief
replaces its "What to try" and its opening paragraph about the town: play **one mission**, the
game's opening, in a new, unfinished part of the game: a whole valley, with the town still a
greybox (grey blocks where buildings will be, boardwalks, posts with names on them). There are no
townsfolk and no gang here yet: don't look for them.

**Start it like this** (not plain `start`):

```sh
python3 tools/playtest.py start --game-args=--world=valley,--mission=sheriff
```

**The mission.** You're Thomas Harlan, a homesteader. It's dawn and you're at your own place in the
hills south-east of town. Nobody tells you what's happened: find out by playing. There's a path
from your place down to the road to town (it runs roughly north from where you start; `read player`
says where you are). Walk it as a player would; `goto` is fine to save time once you know where
you're going.

**Things this mission uses that the rest of the game doesn't:**
- **Answering people with your head.** When someone asks you something, nod or shake your head:
  `nod` and `shake` (they move your view down-up-down, or left-right-left, as a player would with
  the mouse).
- **E held** does things here: `press shove SECONDS` holds E that long (e.g. `press shove 3`),
  `press shove 1` is a short press. A line on screen and in `events` says what E does where you are.
- When the scene's over, `press mission_retry 1` (Enter) starts it again from dawn.
- `moment_result` is a status readout of the mission (use it at the end of each try to see how it
  went; don't use it to decide what to do).
- `story` shows what the game remembers from your choices.

**Play it three times, a different way each time:**
1. Help as well as you can.
2. Help, but carelessly (or slowly).
3. Don't help.

**What to report**, besides `tools/playtest.md`'s questions:
- Did you understand what was happening, what was asked of you, and how to answer? Where were you
  confused?
- The wounded man: did he seem hurt, frightened, alive? Did what he said change with how he was?
- Did how well you helped make a difference you could see or hear?
- The typed cards (a black screen with text): did they read well, or break the spell?
- What was fun, what was flat, what broke.

Write the report to `docs/playtests/<date>-sheriff.md`, screenshots in `docs/playtests/<date>/`.
