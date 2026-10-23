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

The gang fights as the game's does (variant D since 2026-10-23: fights that commit). Z plays the
same setup with the others, shown: **A** as the game was when Sean played it, **B** aims by the
hand on the gun and finds the cover that's there, **C** is B and goes to ground before breaking,
**D** is C and commits (noise pins them but doesn't break them, the hothead holds early, Brody
holds the rest while he's in it, the Kid's running barely shakes them, and they'll take the long
way round the bar to get behind it).

## The keys

- **Y**: the next setup (the hall, the stair, the galleries, the back, out front, then round again
  on the next seed).
- **X**: this run again (same setup, variant and seed: the men's dice the same).
- **Z**: this setup and seed with the next variant (A, B, C, D), shown.
- **F3**: what each man's thinking: his tactic, fear against nerve, and his last decision and why
  ("run for cover: in the open, 5 m", "hold on: Brody told him to stay in it").

Each run is saved (the path shows at the end of the fight): one JSON a run and a line in
`runs.csv`, in `%APPDATA%\Godot\app_userdata\Salt Creek\gunfight_runs\` on Windows.

## What to look for

- Do they **fight back** when you shoot first, or fold? Who quits, when, and was it earned (he was
  hit, a friend went down, he was the last one up, you had him cornered)?
- Do they **use the room**: behind the bar, up the stair, along the galleries, through the doors?
- Does it **last** (the brief's target: most fights a tense 45–90 seconds)?
- **The Kid** should break first and his running shouldn't take the others with him; **Lyle**
  shouldn't quit early; **Brody** should hold them ("Hold, damn it! Stay in it!") while he's up.
- Anything **unfair** (a man who knew where you were when he couldn't have).

## The sheet

| Run | Setup | Variant | Fun | They fought | Quits earned | Used the room | Notes |
|---|---|---|---|---|---|---|---|
| 1 | the hall | D | | | | | |
| 2 | the stair | D | | | | | |
| 3 | the galleries | D | | | | | |
| 4 | the back | D | | | | | |
| 5 | out front | D | | | | | |

Then, if you like, Z on one you liked to play it as A (the game you first played) and say which
was the fight.
