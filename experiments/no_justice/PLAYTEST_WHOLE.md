# Playtest: No Justice, played whole (the doctor's to the cabin)

You are a playtester. You have **not** read the game's code and mustn't: don't open anything under
`src/`, `experiments/` (but this file), `tests/`, `config/`, `DESIGN.md`, `docs/scripts/`,
`docs/story/` or `docs/briefs/`. Play the way a player would and report what you find.

The game is a first-person Western, Salt Creek, 1882. You are Harlan, the deputy of a sheriff who
died last night. It's the morning after, on Main Street, by the doctor's. This is one story in
several scenes, played from its start to its end in one go: what happens in one scene should carry
into the next (who's with you, who's hurt, the time of day, what you chose). Nothing tells you what
to do except what people say (subtitles: `events` shows them as words) and a line on screen now
and then. Riding isn't built yet: a ride is a black card with a line of text, and you arrive.

Known and not this test's: this machine's renderer may draw the ground as a flat brown sheet over
floors and men's legs near them; say if it stops you seeing what's going on, but don't spend a run
on it. Some people are grey stand-in figures.

You play through a command line (the "dev bridge"); every command answers with one line of JSON.
The game is drawn slowly here (about one frame a second): a whole run takes a while, so use `wait`
generously and don't take a screenshot every step.

## Starting and stopping

```sh
python3 tools/playtest.py start --game-args=--world=valley,--mission=no_justice   # a minute or two
python3 tools/bridge.py "COMMAND" "COMMAND" ...                                    # in order
python3 tools/playtest.py shot NAME     # a screenshot for the report (prints its path)
python3 tools/playtest.py stop
```

## The commands

- `read all` (where you are, which way you face, who's near), `read people`, `events 20` (what was
  said and done: **people's words are your best clue**), `story` (what the game has recorded).
- `walk X Z` / `walk X Z run`, `walk NAME` (to a person), `look NAME`, `turn DEGREES [PITCH]`,
  `wait SECONDS`.
- `kick` (a kick at what's in front of you, about 1 m), `shove`.
- `nod` and `shake`: nod or shake your head (it's how Harlan answers; he doesn't speak).
- `press shout`: to a man by you, "wait here" / "come on"; with a man who's given up in front of
  you, bind his hands.
- `weapon revolver` / `weapon none`, `shoot N`.

## What to do

Play it **twice** from the start (stop and start again between runs). In each, go in to the
doctor's, listen, say yes when you're asked to come, and follow it through to its end.

1. **Run 1:** play it as a lawman would. At the end, when you're asked something, answer the way
   you'd mean "yes", and see it through to wherever it takes you.
2. **Run 2:** play it however you like (a different way into the fight, a different answer at the
   end, or an answer by what you *do*).

Take a few screenshots in each run: the doctor's, the camp, the hideout from above, the fight, the
shack's door, the end. Note the time of day and the light when you arrive at each place.

## The report

Write `docs/playtests/<today>-nojustice-whole.md` in plain English for the game's director (not a
programmer):

- **What I did**: a short story of each run, in order, scene by scene.
- **The joins**: going from one scene to the next (each ride, each arrival). Did it make sense
  where you were, who was with you, and what time it was? Did anyone or anything vanish, appear,
  stand in the wrong place, or repeat?
- **Joe**: did he stay with you the whole way, keep what happened to him, and behave like the same
  man from scene to scene?
- **Each scene**: was it clear what to do? Anything that stopped you?
- **The end**: what it was, what you saw, and whether it felt earned by what came before.
- **What broke**: anything that went wrong; exactly what you did before it.
- **What was flat or confusing**, **What worked**.
- **The top three things to fix**, most important first.

Be honest and specific. Short sentences. Don't guess at causes in the code.
