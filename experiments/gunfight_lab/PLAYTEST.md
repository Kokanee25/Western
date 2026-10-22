# The three gunmen: the A/B/C playtest

The question: **is fighting the same three men more fun when they make believable tactical and
survival decisions, and can we show why?** The lab's numbers (the scripted player) can show what
the men do and catch faults; only people playing can say whether it's fun. This sheet is for that.

## The fight

The saloon, golden hour, every lamp lit. Brody (cool, steady, leads) at the bar, Lyle (a
hothead) at the card table, the Kid (green, nervous) at the back. You're just in at the door with
your revolver away. They go for their guns when you go for yours (H), or after 3 seconds. The same
men, room, guns and starting spots every run.

| | What the gang does |
|---|---|
| **A** | The game as it plays on main today: their shots land in a random cone round their aim; they look for cover within a step of where they stand; past their nerve they give up or run on the spot. |
| **B** | A, but they aim by the hand on the gun (it wanders, lags onto you, jerks when rounds crack past; no dice), take a moment to react, and find the cover that's there (behind the bar, round a table, a doorway). |
| **C** | B, and past their nerve behind cover they go to ground first; they come back up if it passes, break if it doesn't. |

## The keys

- **Y**: the next run of the playtest. Nine runs: each variant once on each of three seeds, in
  an order that puts each variant first, second and third once. The variant is hidden (`?`) until
  the fight's over.
- **X**: this run again (same variant, same seed).
- **Z**: free play: the next variant on this seed, shown.
- **F3**: what each man's thinking: his tactic, fear against nerve, and his last decision and why
  ("run for cover: in the open, 5 m", "look for you: lost sight of you 4 s ago").

Quitting the game starts the playtest again at run 1. Each run is saved (the path shows at the
end of the fight): one JSON a run and a line in `runs.csv`, in
`%APPDATA%\Godot\app_userdata\Salt Creek\gunfight_runs\` on Windows.

## How to play it

1. Play the nine runs in order (Y each time). Don't look at F3 for the first three: play it as
   a fight.
2. Right after each run, before Y, score it below (1 bad, 5 great) and write a line or two. The
   notes matter more than the numbers.
3. If a friend can play: they start at run 1 too (quit and restart the game), and fill their own
   sheet without seeing yours.
4. Send the sheet and the `gunfight_runs` folder (or just `runs.csv`).

What to write about: what changed your plan; when you were bored; what surprised you; why you
died or won; anything that felt unfair (did a man know where you were when he couldn't have?).

## The sheet

| Run | Variant (shown at the end) | Fun | Tactical variety | Fair and readable | Believable men | Want to play it again | Notes |
|---|---|---|---|---|---|---|---|
| 1 | | | | | | | |
| 2 | | | | | | | |
| 3 | | | | | | | |
| 4 | | | | | | | |
| 5 | | | | | | | |
| 6 | | | | | | | |
| 7 | | | | | | | |
| 8 | | | | | | | |
| 9 | | | | | | | |

After all nine: which three runs were best, and why? Which variant would you keep?

## What we'll do with it

Nine runs from one player can't prove one variant better; they can show which one changes how
the fight goes and how it feels, and point at the next thing to fix. The report puts each score
next to that run's record (what each man decided and why, who hit whom, when) so the notes can be
read against what really happened.
