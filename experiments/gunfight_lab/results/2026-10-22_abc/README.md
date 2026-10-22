# A/B/C: the three gunmen, playable, and what the bot shows (2026-10-22)

Sean's work order ("Gunfight fun prototype", 2026-10-21): can we show, not claim, that the same
three men are more fun when they make believable tactical and survival decisions? This round
builds the comparison and runs the technical half of it. **No one has played it yet; nothing here
says which variant is more fun.** That is `PLAYTEST.md`'s job.

## What was built

- **The variants** (`OutlawBrain.Variant`, `default_variant` A everywhere in the game):
  - A: the game as it plays on main. Shots go into a random cone round his aim, he looks for
    cover within a step of where he stands, and past his nerve he gives up or runs on the spot.
  - B: fixes 1 and 2. His aim comes from the hand on the gun (`GunHand`), he takes a moment to
    react, and he finds the town's cover.
  - C: B and fix 3 (shaken first).

  A replays main's numbers exactly: the outlaw hit-rate feel test gives 100 / 31 / 13% at
  5 / 15 / 30 m, as before the lab. B is held to the same ranges by a test of its own
  (89 / 20 / 21%).
- **Playable** (`play.gd`, keys Y X Z): the saloon, the same men, room, guns and spots every run.
  Your gun starts away; they go for theirs when you draw, or after 3 s.
  - Y: the next of nine blind runs (each variant once on each of three seeds, a Latin square).
  - X: this run again.
  - Z: free play (the next variant, shown).
  - Each run reloads the scene and is recorded to `user://gunfight_runs/` (a JSON and a CSV line).
- **Why a man did what he did:** `OutlawBrain.decision` ("run for cover: in the open, 5 m", "look
  for you: lost sight of you 4 s ago", "go to ground: past his nerve..."), on F3 and in every
  record. The lab also counts:
  - flanks made and failed;
  - searches for you that found you, and ones he gave up;
  - time stuck on the way to cover;
  - cover given up the moment he got there;
  - **unfair**: a man firing at you, or calling he's spotted you, with no line from his eyes to
    you for over half a second.
- **The bot with your opening** (`opening=draw`): its gun away, the gang turns at the count, the
  bot takes it in (0.3 s) and draws.

## What the bot shows (720 saloon fights, `--bodies=game`, 10 seeds)

Two openings, 120 fights a variant each. `draw` is the playable one: guns away, they turn at 3 s.
`standoff` is the lab's usual: your gun up from the start. The lengths include the 3 s count.

| draw opening | A | B | C |
|---|---|---|---|
| fight length, median s (after the count) | 5.5 (2.5) | 8.2 (5.2) | 8.4 (5.4) |
| the gang hits first | 100% | 32% | 32% |
| you down | 72% | 28% | 37% |
| the gang's hits a shot | 80% | 56% | 60% |
| near misses on you a minute | 41 | 18 | 19 |
| their fighting time in the open | 88% | 67% | 60% |
| decisions a man a fight | 1.9 | 2.5 | 2.9 |
| quits a fight on 0 / 1 / 2+ hits | 0.28 / 0.26 / 0.60 | 0.68 / 0.58 / 0.95 | 0.50 / 0.60 / 0.98 |
| shaken / rallied a fight | – | – | 0.45 / 0.17 |
| flanks made (all 120) | 0 | 0 | 1 |
| looking for you: found / gave up | 5 / 2 | 14 / 14 | 14 / 14 |
| cover given up the moment he got there | 27 | 31 | 32 |
| **unfair incidents** | **0** | **0** | **0** |

The standoff opening tells the same story faster. A: they hit first in 100% of fights, you're
down in 58%, 2.0 s. B: you hit first in 100%, down in 24%, 1.9 s. C: 4.3 s, down in 28%.

Frame cost under the run's load (4 games at once on this workspace's cores), the three men a
frame: A 2.31, B 3.13, C 3.41 ms (×0.65 at Sean's: 1.5, 2.0, 2.2). The people's worst frames
(p95): 13.8, 15.5, 17.0 ms. B and C cost ~0.5–0.7 ms more at Sean's for three men (the hand each
tick, the town's cover search). The perf bench hasn't measured it on a quiet machine.

## What it means (technical findings, not fun)

1. **In the saloon as it stands the fight is a quick draw, not a tactical fight.** All three start
   4–8 m from you in plain sight, and the commonest decision in every variant is "fight from where
   he is: no cover he can reach". Whoever's gun comes up first wins:
   - A: they shoot at once with no aim to settle; you take three balls in 0.65 s (seed 2).
   - B and C: they react and settle, so the bot shoots first and it's over in under two seconds.

   The variants change who wins the draw and not much else. Flanking never happens: 1 flank
   in 720 fights.
2. **The saloon lost its cover.** Since the card table and chairs became kit props (thin top on
   legs), a crouching man isn't hidden behind them, and the gang's search rightly turns them down.
   From Lyle's spot it finds nothing at all (`gf_coverwhy`). Fix 2's notes had Lyle and the Kid
   behind tables. Only the bar is left.
3. **A real fault in every variant: cover dropped on arrival.** 27–32 times in 120 fights a man
   reaches the spot his search picked and leaves it within half a second ("you can see him
   there now"). The search's test and the hiding check's disagree.
4. **Nobody cheated.** 0 unfair incidents in 720 fights: no man fired at you or called he'd seen
   you without a line from his eyes to you.
5. B and C do what they were for: fewer near-instant hits, more decisions, men looking for you
   when they lose you. In C a fifth of shaken men come back up. Whether that's more fun is
   untested.

## What would make the comparison worth playing

The variants differ in how the men fight from cover and how they break. The saloon start gives
them almost no cover and no time, so most of that never shows. Before Sean's nine runs mean much,
the room has to offer the choices the work order asks for:
- something to get behind (a table knocked over, the bar's end, the stair, the back door);
- an opening that isn't three men in plain sight at duelling range.

The street (the lab's main arena) has cover. There C's street fights were a third longer than B's,
with longer lulls (fix 3's results), but it isn't the playable encounter yet.

## The playtest agent (`docs/playtests/2026-10-22.md`)

An automated tester (no code read) played six runs through the dev bridge at about a frame a
second, about 5 s of game time to draw and fire. Its scores aren't a human's. It never hit a man.
- **Same as the bot:** in every variant, staying in the saloon, all three fired within a second of
  its draw.
- **Its best moment (C):** Brody held the doorway ("I know you're there") and dropped it when it
  stepped into line.
- **Its liveliest run (A):** Brody came out after it, called "Reloading! Cover me!", the others
  answered, and he gave up past his nerve.
- **Faults in what this round built, fixed in the same merge:**
  - the first "next run" after being knocked out often lost;
  - the range's lone outlaw joining in;
  - F3 naming the variant and listing the town before the gang;
  - an empty first few seconds;
  - the count starting a fight over a duel it had called.
- **Faults it found in the game, not fixed here:**
  - after being knocked out, men stood still for 30 s "searching" and gave up;
  - with a broken arm the revolver kept going back into the holster, with nothing saying why;
  - a stuck step at the saloon's porch;
  - lines that don't fit ("Easy, friend" from the man who just shot you; "Hey! That was me!" from
    the man who fired);
  - ten townsfolk shouting the same words at once.
