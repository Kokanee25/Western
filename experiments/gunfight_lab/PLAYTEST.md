# The three gunmen in the new saloon: the playtest

The question (Sean's first play, issue #257: "the bad guys just kept quitting, wouldn't even really
fight"): **do they fight now?** Do they take cover, shoot back, go round on you and come at you,
and give up only when they've been hurt, seen friends go down or been left alone? The lab's
numbers (the scripted player) catch the faults; only people playing can say whether it's a fight.

## The fight

The new saloon (the building lab's: out in the desert west of town, F5's eighth stop builds it;
you don't need to go there, Y takes you), golden hour, every lamp lit. Brody (cool, steady, leads
them), Lyle (a hothead) and the Kid (green, nervous), and you with your revolver away. **Drawing
doesn't start it**: they'll warn you off, as men do in town. **Your first shot starts it**, or they
go for their guns when the count's out (6 s). Five setups, Y plays them in turn:

| Setup | You | Brody | Lyle | The Kid |
|---|---|---|---|---|
| **the hall** | just in at the batwings | at the bar | by the middle card table | by the far table |
| **the stair** | in the hall by the door | behind the bar | at the foot of the hall stair | a third of the way up it |
| **the galleries** | in the middle of the hall | at the bar | up on the west gallery, at its rail | on the back gallery over the tables |
| **the back of the hall** | between the far tables | by the back room's door | behind the bar's far end, by the kitchen | at the back gallery's rail above |
| **out front** | in the desert by the boardwalk's steps | up on the street balcony | along the boardwalk | at the batwings |

**Y plays the trial** (2026-10-24, "D+": the game's D and four fixes on trial, measured in
`results/2026-10-23_expAB/README.md`):

- **A hit man fights on hurt.** The pain comes in bouts: he clutches it, then fights on, slower and worse.
- **Shot off his feet but still with it**, he comes to on his belly and fights from the floor.
- **Past his nerve, he weighs it** rather than giving up on the spot:
  - Brody mostly lies low;
  - Lyle fights it out when he's cornered;
  - the Kid runs or gives up;
  - a man too hurt to run backs off at a walk.
- **A ball close past him** throws his aim off.
- **The back rooms' doors** open into the rooms now, not across the gallery.

**Z** plays the same setup and seed with the others in turn: A (as it was when you first played),
B, C, D (the game's now, without the trial), then D+ again.

## The keys

- **Y**: the next setup (the hall, the stair, the galleries, the back, out front, then round again
  on the next seed).
- **X**: this run again (same setup, variant and seed: the men's dice the same).
- **Z**: this setup and seed with the next variant (A, B, C, D, D+), shown.
- **F3**: what each man's thinking: his tactic, fear against nerve, and his last decision and why
  ("run for cover: in the open, 5 m", "hold on: Brody told him to stay in it").

Each run is saved (the path shows at the end of the fight): one JSON a run and a line in
`runs.csv`, in `%APPDATA%\Godot\app_userdata\Salt Creek\gunfight_runs\` on Windows.

## What to look for

- **Is it a fight?** Do hit men keep at you: clutching it, then shooting again, firing from the
  floor? Does it feel earned, or like they won't go down?
- **How they go:** does Brody lie low, Lyle fight it out cornered, the Kid run? Does a hurt man
  backing off read as one?
- **Is it too hard?** The lab's careful player goes down in about half these fights (three men,
  each hit ~20% of their shots, about two balls on you a fight). How often do you?
- **Does it last?** In the lab it's 36 s of shooting at the median with a careful player; a third
  of fights 45–90 s.
- **Then Z to D** (the game's now) on the same setup: which is the better fight?
- **Anything unfair or odd** (a man who knew where you were when he couldn't have, a man stuck,
  a man coming to on the floor oddly).

## The sheet

| Run | Setup | Variant | Fun | They fought | Quits earned | Used the room | Notes |
|---|---|---|---|---|---|---|---|
| 1 | the hall | D+ | | | | | |
| 2 | the stair | D+ | | | | | |
| 3 | the galleries | D+ | | | | | |
| 4 | the back | D+ | | | | | |
| 5 | out front | D+ | | | | | |

Then, if you like, Z on one you liked to play it as D (the game's now) and say which was the fight.
