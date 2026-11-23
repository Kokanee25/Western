# Playtest: the cabin (No Justice, step 4)

You are a playtester. You have **not** read the game's code and mustn't: don't open anything under
`src/`, `experiments/` (but this file), `tests/`, `config/`, `DESIGN.md`, `docs/scripts/`,
`docs/story/` or `docs/briefs/`. Play the way a player would and report what you find.

The game is a first-person Western, Salt Creek, 1882. You are Harlan, the dead sheriff's deputy.
With Joe, a Southern Ute man whose camp was raided, you have tracked the raiders to their line
shack under the rimrock and fought them. The scene starts after that fight: the gang lie dead about
their fire, and the man Joe wants (in a faded red shirt) is somewhere near. Nothing tells you what
to do except what people say (subtitles: `events` shows them as words) and a line on screen now
and then. Riding isn't built yet: a ride is a black card with a line of text.

Known and not this scene's: this machine's renderer may draw the ground as a flat brown sheet over
the shack's floor and the men's legs near it; say if it stops you seeing what's going on, but don't
spend a run on it.

You play through a command line (the "dev bridge"); every command answers with one line of JSON.
The game is drawn slowly here (about one frame a second).

## Starting and stopping

```sh
python3 tools/playtest.py start --game-args=--world=valley,--mission=no_justice_cabin   # a minute or two
python3 tools/bridge.py "COMMAND" "COMMAND" ...                                          # in order
python3 tools/playtest.py shot NAME     # a screenshot for the report (prints its path)
python3 tools/playtest.py stop
```

A run where the red shirt was shot down outside instead: `--game-args=--world=valley,--mission=no_justice_cabin,--down`.

## The commands

- `read all` (where you are, which way you face, who's near), `read people`, `events 20` (what was
  said and done: **people's words are your best clue**), `story` (what the game has recorded).
- `walk X Z` / `walk X Z run`, `walk NAME` (to a person), `look NAME`, `turn DEGREES [PITCH]`,
  `wait SECONDS`.
- `kick` (a kick at what's in front of you, about 1 m), `shove`.
- `nod` and `shake`: nod or shake your head (it's how Harlan answers; he doesn't speak).
- `press shout` with a man who has given up in front of you: bind his hands (again: "walk"/"wait").
- `weapon revolver` / `weapon none`, `shoot N`.

## What to do

Play it **three times** (stop and start again between runs):

1. **Run 1:** find the red shirt and get to him. Listen. When you're asked something, answer the
   way you'd mean "yes". Then do what follows from that.
2. **Run 2:** the same, but answer the other way. Stay and watch what happens.
3. **Run 3 (`--down`):** answer however you like, or answer by what you *do* rather than your head.

Take screenshots: the shack's door, getting in, the man inside, Joe when he asks, what follows the
answer, and wherever it ends.

## The report

Write `docs/playtests/<today>-cabin.md` in plain English for the game's director (not a programmer):

- **What I did**: a short story of each run, in order.
- **Getting in**: was it clear what to do at the door, and how hard was it?
- **The scene inside**: was it clear who was who, what Joe meant to do and what he was asking?
  Did the lines land?
- **The answer**: did the nod and the shake work, did the game take your answer the way you
  meant, and what did doing (not nodding) do?
- **What followed**: each run's ending, what you saw, and whether it felt earned.
- **What broke**: anything that went wrong; exactly what you did before it.
- **What was flat or confusing**, **What worked**.
- **The top three things to fix**, most important first.

Be honest and specific. Short sentences. Don't guess at causes in the code.
