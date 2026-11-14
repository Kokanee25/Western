# Playtest: the doctor's office and the camp (No Justice, step 2)

You are a playtester. You have **not** read the game's code and mustn't: don't open anything under
`src/`, `experiments/` (but this file), `tests/`, `config/`, `DESIGN.md`, `docs/scripts/`,
`docs/story/` or `docs/briefs/`. Play the way a player would and report what you find.

The game is a first-person Western, Salt Creek, 1882. You are Harlan, a homesteader made the
sheriff's deputy this morning, the day the sheriff died of a gunshot. This scene starts on Main
Street near the doctor's. Something is waiting for you there. Nothing tells you what to do except
what people say (subtitles: `events` shows them as words) and a line on screen now and then.
Riding isn't built yet: a ride is a black card with a line of text.

You play through a command line (the "dev bridge"); every command answers with one line of JSON.
The game is drawn slowly here (about one frame a second).

## Starting and stopping

```sh
python3 tools/playtest.py start --game-args=--world=valley,--mission=no_justice   # a minute or two
python3 tools/bridge.py "COMMAND" "COMMAND" ...                                     # in order
python3 tools/playtest.py shot NAME     # a screenshot for the report (prints its path)
python3 tools/playtest.py stop
```

A second run, as a player who earlier followed the killer out of the saloon:
`--game-args=--world=valley,--mission=no_justice,--followed`.

## The commands

- `read all` (where you are, which way you face, who's near), `read people`, `events 20` (what was
  said and done: **people's words are your best clue**), `story` (what the game has recorded).
- `walk X Z` / `walk X Z run`, `walk PLACE` (`read places`), `walk NAME` (to a person), `look NAME`,
  `turn DEGREES [PITCH]`, `wait SECONDS`, `goto PLACE` (a jump, to save time only).
- `nod` and `shake`: nod or shake your head (it's how Harlan answers; he doesn't speak).
- `look joe`, then `press shout`: tell Joe to wait; the same again to come (once he's with you).
- `weapon revolver` / `weapon none`.

## What to do

1. **Run 1:** find what's waiting at the doctor's; go in; listen; answer how you like. Go where
   you're asked to. At the camp, watch and listen; stay back when asked, or don't. Look at Joe a
   while after he's changed. When he's done, walk off and see whether he comes.
2. **Run 2 (`--followed`):** play it again and answer the other way (if you nodded, shake; then do
   what a player who changed his mind would do).
3. Take screenshots: the office, the card, the camp on arrival, the damage close up, Joe in his
   new hat, Joe reading the ground.

## The report

Write `docs/playtests/<today>-camp.md` in plain English for the game's director (not a programmer):

- **What I did**: a short story of each run, in order.
- **The office**: was it clear who these people were and what was asked? Did the lines land?
- **The answer**: did the nod or shake work, and did the game take your answer the way you meant?
- **The ride and the camp**: what you saw, what you understood had happened there, what Joe did.
- **What broke**: anything that went wrong; exactly what you did before it.
- **What was flat or confusing**, **What worked**.
- **The top three things to fix**, most important first.

Be honest and specific. Short sentences. Don't guess at causes in the code.
