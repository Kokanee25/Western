# Playtest: a man at your side (Joe)

You are a playtester. You have **not** read the game's code and mustn't: don't open anything under
`src/`, `experiments/` (but this file), `tests/`, `config/`, `DESIGN.md` or `docs/briefs/`. Play the
way a player would and report what you find.

The game is a first-person Western, Salt Creek, 1882. This build has a **companion**: Joe, a man
who rides with you. He's meant to walk with you at a sensible distance, wait when you tell him and
come when you call, fight beside you when it comes to shooting, call out what he sees, keep out of
your line of fire, and leave the men you're shooting at to you. He isn't meant to die in an
ordinary fight: badly hit he goes down and gets up after. What he says comes up as a subtitle
(`events` shows it as words).

You play through a command line (the "dev bridge"); every command answers with one line of JSON.

## Starting and stopping

```sh
python3 tools/bridge.py start --headless --game-args=--joe     # the town, Joe beside you (a minute to start)
python3 tools/bridge.py "COMMAND" "COMMAND" ...                 # any number of commands, run in order
python3 tools/bridge.py stop
```

## The commands

- `read all` (where you are, who's near: distance, side, armed, mood), `read people`, `events 20`
  (what was said and done: **people's words are your best clue**).
- `walk X Z` / `walk X Z run` (metres; `read all` gives yours), `walk PLACE` (`read places`),
  `look NAME` (turn to face a man), `turn DEGREES [PITCH]`, `wait SECONDS`.
- `weapon revolver` draws, `weapon none` puts it away; `shoot N` cocks and fires N times where
  you face; `hold aim` / `release aim` (the sights up); `press reload SECONDS`;
  `press crouch_toggle`.
- **Talking to Joe:** `look joe`, then `press shout` (the shout key with him in the middle of your
  view) tells him to wait; the same again tells him to come.
- `joe state` (only this one of the `joe` commands) says where he is and what he's doing, if you
  can't tell from the rest.

## What to do

1. **Walk with him** (in town, `--joe`): walk the street, run a stretch, turn back, stop. Where does
   he keep himself? Does he get in your way or in front of you? Tell him to wait, walk off 30 m,
   look back; call him.
2. **Fight beside him: four fights.** Each fight is its own game: `bridge.py stop`, then
   `bridge.py start --headless` (no `--joe`), then
   `gf_play SETUP seed=N joe=1 fixes=all+pain_fight+floor_fight+odds+flinch` (it answers once
   they're in, ~20 s). Three gunmen, Brody, Lyle and the Kid; Joe beside you. Your gun starts
   away; it starts when you shoot or after 6 s. Play `spec_front seed=1`, `spec_front seed=2`,
   `spec_hall seed=1`, `spec_back seed=1`. `gf_result` says whether it's over, how long it's run and
   each man's state. Play each for real until it's over or you're down. Vary what you do (shoot
   first, wait; stand, crouch, move). Watch Joe: did he help, where was he, did he shoot the man
   you were shooting, did he walk in front of your gun, did they shoot at him, did he go down, what
   did he call and was it useful?

## The report

Write `docs/playtests/<today>-joe.md` in plain English for the game's director (not a programmer):

- **What I did**: a short story of the session, in order.
- **Joe on the walk**: where he kept, waiting and coming, anything odd.
- **Joe in the fights**: a few lines a fight (how long, who won, what Joe did that helped or got in
  the way, what he said).
- **What broke**: anything that went wrong; exactly what you did before it.
- **What was flat or confusing**, **What was fun**.
- **The top three things to fix about Joe**, most important first.

Be honest and specific. Short sentences. Don't guess at causes in the code.
