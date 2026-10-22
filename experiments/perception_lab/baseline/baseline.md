# The perception lab's baseline (2026-10-22)

Main at `fd7fe08` (#233). 5 groups, 76 runs, 117 judged expectations, on the Studio's three men
(`bold_cowboy_s0`, `old_rancher_s1`, `young_drifter_s1`), seed 1, headless. Run twice on the same
seed: every verdict and delay the same. Every case and its numbers: `tables.md`; every summary:
`baseline.json`. How it's measured and judged: `../README.md`. **Nothing in the game was changed.**

**Re-measured the same day** on main at `2a93f77` (#246) with the lab's own corrections (its leak
monitor excuses a man facing a sound he heard, "knows he's lost him" is judged only if he was
watching as the player went, and the saloon-room listener, who has the shooter in his eye, is
expected to know who fired): the tables and `baseline.json` are that run; the first run's counts
were 73 / 12 / 24 / 8. The first fix measured against it: `../results/2026-10-22_heard_not_named/`.

## The table

| group | runs | judged | as expected | missed | false | slow (> 1 s to notice) | leaks sampled |
|---|---|---|---|---|---|---|---|
| sight (15 cases × 4 lights) | 60 | 50 | 33 | 4 | 5 | 8 | – |
| hearing (7 sounds, 27 listeners) | 7 | 41 | 28 | 4 | 9 | 0 | – |
| search (4) | 4 | 8 | 6 | 2 | 0 | 0 | 5 |
| news (2) | 2 | 12 | 7 | 2 | 3 | 0 | 0 |
| leaks (3) | 3 | 6 | 0 | 0 | 6 | 0 | – |
| **all** | **76** | **117** | **74** | **12** | **23** | **8** | **5** |

The headline numbers:

| measure | result |
|---|---|
| Reaction delay, a man in plain view, by day | 0.47 s at 10 m, 0.73 s at 25 m, never in 6 s at 45 m |
| ... at night (lamps lit or out, the same) | 5.5 s at 10 m walking; never in 6 s at 25 m; never under the lit porch lanterns at 19 m |
| ... across the saloon at night, lamps lit / every lamp out | 4.7 s / 4.7 s (the same) |
| ... walking past 7 m to his side, by day | 3.5 s |
| ... through four shots' gun smoke / a stick's dust, by day | 0.73 s / 0.73–0.87 s (should be never) |
| ... through a window (a lit saloon at night) | never: the glass stops his eye |
| Who hears a shot | everyone, town-wide (reach 350 m, halved through any number of walls) |
| ... and knows who made it, unseen | **every one**: 8 of 8 who heard a shot and couldn't see the shooter, 4 of 4 a shout, 6 of 6 footsteps |
| Where he thinks it came from | 0.3–6.1 m off (≤ 6°), through walls as well as in the open |
| Footsteps heard | to 6 m walking, 13 m running, 2 m crouched: the same on boards and on dirt |
| A hammer cocked | heard by nobody (no noise) |
| Losing a man round a corner | knows at once (within 0.1 s), last-known 0.4 m off, goes to 1.5–2.2 m of it, finds him 13 s later |
| Losing him into the store | goes to 3.7 m of the door, doesn't go in, gives up after 27 s |
| News: the deputy learns of a shooting in the saloon / a hold-up in the store | **never** (90 s; there is no way for news to pass) |
| Acting on what he couldn't know | 5 sampled leaks + 6 failed leak cases (below) |

## The five biggest problems, by what a player would notice

**1. A shot names its shooter to everyone who hears it.** `Senses._on_noise` files every noise
under the person who made it (`known[source].heard_pos`), so a man who hears a shot now *knows*
the shooter, by name and to within a few metres, without ever having seen him: 8 of 8 listeners who couldn't see him,
from the room the shot was in to 53 m down the street through the telegraph's corner. On top of
that `OutlawBrain._on_deed` takes the loud deeds (`shoot_at`, `hit`, `kill`) as perceived by every
man in town at any distance, and judges them against the actor: an outlaw 50 m off at the west end,
facing away, who never saw the player, goes to **WARNING** against him (pressure 0.4, a grudge of
0.4) when the player shoots a man inside the saloon. The townsfolk get the same (the storekeeper,
the deputy and a passer-by all "know who" from the sound). *A player notices* every time he shoots
from hiding: the far end of town turns on him, and men who couldn't see him turn straight to him.
It also undercuts the gunfight lab: a hidden shooter is never hidden.

**2. Smoke and dust hide nothing from them.** Four shots' black-powder cloud between two men 8 m
apart, and a stick's dust between two 12 m apart: spotted in 0.73–0.87 s by day, as if the air
were clear (4 false). Senses' line of sight is a ray against the world's solid layer; the clouds
are drawn, not solid. *A player notices* in every gunfight: his own view is a white wall, theirs
isn't, and they shoot him through it. This is the gunfight lab's fairness, and it waits on a way to
ask how thick the smoke is along a line (the unmerged `claude/gameplay-smoke` has
`GunSmoke.transmittance()`).

**3. At night the only light is the sky's; lamps light nobody.** Senses takes its light from
`DayCycle.get_daylight()` alone (sight 60 m by day, 14 m at night) and no lamp counts. A man
walking 10 m ahead at night takes 5.5 s to be noticed (0.47 s by day); a man standing between the
saloon's two lit porch lanterns isn't seen from 19 m in 6 s (missed); across the lamp-lit saloon at
night 4.7 s, and *the same 4.7 s with every lamp out* (false). In the night search the gunman never
once saw the player 6 m in front of him in 40 s; he fought him on the one position his brain filled
in (problem list item 7). *A player notices* that at night men are half-blind even in a bright
saloon, and that putting the lamps out (or shooting them) changes nothing.

**4. Windows are walls to the eye.** Every pane is a `StructureMember` on `Layers.WORLD`, the layer
Senses' ray stops on, so nobody sees through a window: a man a step behind the saloon's front
window, the room lit at night, is never seen from the street 9.5 m off (missed). *A player
notices* in the saloon and the store: men inside don't see him standing at the window, and he can
shoot them through the glass without being seen; once a pane is shot out they can.

**5. Nobody passes news on.** No man ever tells another anything: the barkeep who watched the
player shoot a man across the saloon, the storekeeper held up over his counter, both calm again in
90 s, and the deputy (at the jail across the street) never learns of either (2 missed). The one
place the game reaches for news, `OutlawBrain._call_out` ("he asks round town; somebody tells
him"), uses the player's true position: an outlaw who has never seen or heard him walks to a spot
laid off exactly 12 m from where he really is. *A player notices* the absence once the law
matters: a daylight hold-up across from the jail has no consequence at all.

## Everything else it found

6. **A friend's fall is known through walls.** `OutlawBrain._saw_mate_out` counts a friend going
   down as seen if he's within 15 m, whatever's between: a gang man 13.5 m off, a porch post and the
   store's front between them, knows his friend fainted inside (fear +0.23).
7. **A fight fills in where you are.** `_start_fight` runs every second of a fight (the retarget
   loop) and `_join` on a friend's shout; each notes the target's *true* position whenever
   `Senses.knows()` is false, and `knows()` turns false the moment a man he saw (and hasn't heard)
   is out of sight, because awareness fades from 1. So once each fight, about a second in, he's
   handed where you are (all four searches, 0.5 m off). `_duel` does the same ("he knows where he
   is").
8. **Footsteps don't know the ground.** `Player._footsteps` is 6 m walking, 13 running, 2 crouched,
   boards or dirt alike: missed on the boardwalk at 9 m, false on dirt at 5 m. Men make no
   footsteps at all (only the player's are a noise).
9. **A cocked hammer is silent to men** (missed at 1.5 and 4 m): the click is the player's sound
   only.
10. **A shout carries 45 m** (`DeedWatch.SHOUT`); missed at 60 m down an empty street at night.
11. **Far sight is slow by day:** a man walking 45 m down the street isn't seen in 6 s (2 missed);
    7 m to the side, 3.5 s; crouched in the open at 15 m, 1.5 s.
12. **The store is a dead end for the hunt:** he follows to 3.7 m of the door, doesn't go in, and
    gives up after 27 s (the corner searches go well: to the last-known spot, a look round, found).
    One `faces_unseen` sample there (13 s, facing within 7° of the player through the telegraph's
    door jamb, 31° off his last-known): too few to call.
13. **The townsfolk can't hold a deed against the player:** `CivilianBrain._troubled` skips the
    player, so the held-up storekeeper's `troubled_by` stays empty.

What works: walls, the store's front and a corner block sight; nobody sees behind his back; the
batwings and an open door let a man be seen; hearing places a sound well (≤ 6°) and tells a shot
from a shout; a shot in the saloon is heard everywhere; a man lost round a corner is known lost at
once, searched for where he was last seen, and found.

Case notes: `round_the_corner`'s line meets a street barrel before the saloon's corner (both stand
between them). The search's hunter is told to hold his fire (`_next_shot`) and his fight is started
by the lab (`_provoked`); everything else he does is his own.

## The first fix I'd make (made 2026-10-22 on Sean's OK, #240: `../results/2026-10-22_heard_not_named/`)

**Hearing a sound is not knowing who made it** (problem 1). One change, in three places:

- `Senses._on_noise`: a noise is filed under the man who made it only if the listener can see him
  as it happens; otherwise it's kept as a sound (`kind`, a guess of where, when), with its own
  signal, so a brain can turn to it, go and look, or be afraid of it.
- `OutlawBrain._on_deed`: a loud deed by a man he neither sees nor already knows to be there isn't
  judged against that man (no pressure, no stance, no grudge); it's a shot over there: fear, a
  turn to look, and a reason to go and see. A ball past *him* still tells him which way it came
  from (`_on_near_miss`, as now).
- `CivilianBrain._on_deed`: `helped_by` only for a deed he saw.

Measured against this baseline: hearing's 8 "knows who" falses to 0, the far outlaw's 3 to 0,
news' 3 "who from the sound only" to 0, sight and search unchanged; then the gunfight lab's
baseline run again, because its gang has been leaning on the shooter's name: a man shooting from
hiding should now be searched for where the shot was heard, not found.
