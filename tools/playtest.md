# Playtest: play Salt Creek and say what it's like

You are a playtester. You have **not** read the game's code and shouldn't: play it the way a
player would and report what you find. The game is a first-person Western set in a small frontier
town, Salt Creek, in 1882: a dusty street of false-front buildings, a general store, a saloon, a
few townsfolk, and a gang of three riders (Brody, Lyle and the Kid) who come into town and may
make trouble. Nobody is an enemy by default: people react to what you do. Guns are a single-action
revolver (cock it, then fire; one cartridge at a time to reload) and a double-barrelled shotgun;
there's dynamite, and the timber buildings burn and break.

You play through a command line (the "dev bridge"), not a keyboard. Every command answers with
one line of JSON; screenshots are PNG files you can open and look at. The game runs in real time,
slowly drawn (about one frame a second here), so a screenshot shows what's on screen at that
moment.

## Starting and stopping

```sh
python3 tools/playtest.py start          # the game, drawn, at 960x540 (a minute to start)
python3 tools/bridge.py "COMMAND" "COMMAND" ...   # any number of commands, run in order
python3 tools/playtest.py shot NAME      # a screenshot saved for the report; prints its path
python3 tools/playtest.py stop
```

Screenshots for the report go in the folder `playtest.py start` prints
(`docs/playtests/<date>/`). Open them (they're images) to see what a player would see. Take one
whenever something is worth showing: good or bad.

## The commands

- `read all` — where you are and which way you face (degrees: 0 north, 90 east), what's under
  your sights, everyone near you (distance, which side, armed or not, mood, how they feel about
  you), your health and wounds, what's in your hands. `read people`, `read player`, `read look`,
  `read places` (named spots you can walk to) for one part.
- `events 20` — the last things that happened: who said what, shots, hits, falls, deaths,
  timber breaking, explosions. People talk: their words are the best clue to what they think.
- `walk PLACE` (from `read places`), `walk NAME` (to a person), `walk X Z`, add `run` to run.
- `look NAME` / `look PLACE` / `look X Y Z` — turn to face it. `turn DEGREES [PITCH]`.
- `goto PLACE` — jump straight there (use it to save time, not instead of walking everywhere).
- `weapon revolver` / `weapon shotgun` / `weapon dynamite` / `weapon none` — draw or put away.
  Drawing a gun is something people notice.
- `shoot N` — cock and fire what's in your hands N times, wherever you're facing.
- `press ACTION [SECONDS]` — a key: `aim` (raise the sights; hold it with a duration), `reload`
  (hold ~3 s to load the revolver a round at a time), `holster`, `shout` (shout "Drop it!" with a
  gun out; with your gun holstered and facing an armed man, call him out to a duel), `crouch_toggle`,
  `jump`, `tend_wounds` (press on your wounds; hold to tie a belt), `debug_overlay` (frame-rate
  readout on screen), `debug_help` (the key list on screen). For dynamite: `press cock` lights
  the fuse, `press fire 1` throws (hold longer to throw harder), `press aim` sets it down.
- `wait SECONDS` — let time pass (things happen while you wait: watch the events).
- `gang` — the gang rides in from the west end of the street (they come anyway after a while).
- `time HOUR` — set the clock (17.5 golden hour, 23 night).
- `ignite` — set fire to the timber you're looking at (a stand-in for a dropped lamp or a torch).

Don't use the other commands in `help` (spawn, fight, dynamite X Y Z, set, camera): they're
for testing, not playing, unless you're stuck and say so in your report.

## What to try

Play for real: decide what you want to do and do it. Cover at least these, in any order:

1. Walk the street. Look around. Who's here, what are they doing? Go into the general store and
   the saloon.
2. Provoke someone: draw on a man, aim at him, shout at him. What does he do? What do others do?
3. Wait for the gang (or `gang`) and follow them; see what they get up to. Stand up to them,
   or call one out.
4. Get into a fight with the gang. Use cover (crouch, walk behind things). Get hurt; tend your
   wounds.
5. Use dynamite on a building.
6. Set a fire and watch it spread.
7. (Talking a man down isn't in the game yet; skip it.)

## The report

Write `docs/playtests/<date>.md` (the date `playtest.py start` printed), in plain English, for
the game's director (not a programmer), with your screenshots linked as
`![what it shows](<date>/name.png)`:

- **What I did** — a short story of the session, in order.
- **What broke** — anything that went wrong: a command that did nothing, people stuck or
  walking through walls, a gun that wouldn't fire, things in the wrong place, error-looking
  screens. Say exactly what you did before it.
- **What was flat or confusing** — moments where nothing happened when something should have,
  people who didn't react, things you couldn't tell or work out.
- **What was fun** — moments that felt alive, surprising or Western.
- **The top three things to fix**, most important first.

Be honest and specific. Short sentences. Don't guess at causes in the code.
