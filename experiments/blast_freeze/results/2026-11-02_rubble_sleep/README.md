# Rubble that won't sleep after dynamite (2026-11-02, issue #585)

Branch `claude/gameplay-rubble-sleep-9n8wlb`. Main at 4bcf7e5 in a worktree, the same native build,
run alternately with the branch on this VM (4 cores, Xeon 2.1 GHz, headless, `--fps=60`, no fire).
The JSON runs aren't kept (~3 MB each); the tables are theirs.

```sh
printf 'bf_blast fire=0 fuse=1 seconds=60 in=street sticks=3 gap=0.4 out=build/bf/st.json\nquit\n' > /tmp/st.txt
printf 'bf_blast fire=0 fuse=1 seconds=60 in=farm sticks=6 gap=1.5 out=build/bf/farm.json\nquit\n' > /tmp/farm.txt
printf 'bf_blast fire=0 fuse=1 seconds=40 in=farm sticks=6 gap=1.5 awake=2 out=build/bf/why.json\nquit\n' > /tmp/why.txt  # the census
python3 tools/bridge.py run /tmp/st.txt --headless --fps=60
```

`in=farm`: a stick thrown at each of the farmhouse's walls 1.5 s apart, the mission not started.
The tables below the first used this branch's own (front, west, east, back, lean-to west and east,
0.4 m out, the player 20 m out front); since #590 merged the lab's is #590's (its `walls=` order,
0.6 m out, the player 12 m off the front), so the last table's broken counts are another scene's. `awake=S`
(new): a census of the awake rubble every S s (`awake_log`).

## Why they stay awake

Jolt puts a body to sleep only with its whole island (everything touching it, through contacts),
and only when every body in it has kept each of three points within ~1.5 cm for 0.5 s (the
project's sleep threshold, 0.03 m/s x 0.5 s). The census (street, three sticks, main, five runs):

- 30-60 s after the stick, **~680-770 rubble bodies awake in 3 of 5 runs** (the others slept at
  ~25 s), and **all but one or two of them moving under 1 cm/s** at their farthest point. Not
  creeping: still. They lie in ~30-50 piles by contact, the biggest 450-740 pieces.
- What keeps an island awake is one restless body in it: a board wedged and **spinning in place at
  ~3 rad/s for four minutes** (its middle going nowhere, 0.07 m/s); a **fallen fitting** or a
  **glass prop's body** jiggling (0.06 m/s, 1.4 rad/s); a blasted man's **bone fragments
  twirling at ~10 rad/s** on the boards for 10 s and more; a board rocking on another. The dead
  men's ragdolls lying on the piles were held awake with them, and slept with them.
- Nothing kept waking them: no structure wakes, no break; 0-2 wakes a census once the collapse
  was over. Contact monitors and CCD don't matter to Jolt's sleep.
- At the farmhouse (the knoll in the hills) it's worse: **~900-1,130 awake a minute after the last
  stick, every run**, and Jolt's step for them ~110-130 ms a frame here. That is Sean's slow
  motion (#584): ~150 ms frames at two ticks a frame.

## What changed

`RubbleSleep` (`src/structures/rubble_sleep.gd`, LAYOUT.md "src/structures"): every 0.5 s (the
look spread over the ticks between) it looks at the awake rubble, fallen fittings, debris (bone
fragments, shards, chips, spent cases) and loose glass props. A piece whose middle has stayed
within 3 cm for 1.5 s, with nothing given way within its wake radius + 2 m and no blast within
20 m (x cube root of its kg) for 2 s, that still moves faster than 0.01 m/s at some point
(turning or jiggling where it lies), is **frozen static where it lies**. Jolt then sleeps the rest
of its pile itself. A piece kept asleep keeps its still spell, so if holding its neighbour wakes
its pile and it's restless again, it's held at the next look. A held piece is let go (a body
again, awake) when struck, shot, blasted or shoved (`RubbleRest.let_go`), its member touched,
rubble lands on it, the ground is dug under it, or something near it gives way.

## Tried and not kept

1. **Putting whole piles to sleep** (piles by the contact monitor's reports): ~17,000 piles put
   to sleep in 20 s, nearly all woken the next step. The monitor reports four contacts a body, so
   the piles seen are pieces of Jolt's islands (2.4 bodies on average), and the island's awake
   rest wakes them. Without RubbleRest's shape swap on them, the same.
2. **Damping the restless piece to a stop** (its type unchanged): its pile stayed awake (~1,000
   at 14 s, 320 held).
3. Freezing (kept) wakes the sleeping pile beside a held piece once; with the still spells kept
   through sleep a wave settles at the next look (one farmhouse run before that took 37 s).

## The numbers (ms here; each run 60 s after the last stick)

`settled`: from this second after the last stick on, every second's median frame is under 33 ms
(`-`: some later second wasn't); `< 50 awake`: from this second on, under 50 rubble bodies awake
(held ones aren't awake: frozen, the physics doesn't step them).

| | runs | broken | settled (s) | < 50 awake (s) | frame median, 10-60 s | Jolt's step, 10-60 s | awake at 60 s |
|---|---|---|---|---|---|---|---|
| farmhouse, main | 3 | 723, 859, 877 | never | never | 131-154 | 112-132 | 911-1,131 |
| farmhouse, branch (final, 6-8) | 3 | 720, 724, 724 | 9-17 | 8-16 | 17.0-18.5 | 2.2-2.3 | 0 |
| farmhouse, branch (earlier rounds, 1-5) | 5 | 709-723 | 10-38 | 9-37 | 15.5-49.7 | 2.1-33.4 | 0 |
| street, main | 3 | 912, 913, 913 | 12-18 or - | 11-18 | 23.3-25.6 | 2.6-2.8 | 0-1 |
| street, branch (final, 6-7) | 2 | 910, 913 | 7-9 | 7-8 | 23.0-24.8 | 2.4-2.6 | 0 |
| street, branch (earlier rounds, 1-5) | 5 | 912-913 | 9-19 or - | 7-18 | 22.7-25.3 | 2.5-2.7 | 0 |

Before the sticks the frame is ~19 ms (street) and ~15 ms (farmhouse) here on both. In the
seconds the house is still coming down (3-8 s after the last stick) both are ~55-65 ms (street)
and ~90-160 ms (farmhouse): that's the rubble actually moving, and isn't this change's.
With the mission on (`mission=1`: the gang in the house, the rovers; one branch run): broken 736,
settled 25 s after the last stick (the men moving about the wreck keep some piles stirring),
then ~19 ms frames. Not measured on main with the mission (#584's).
In this series main's street slept on its own in all three runs (11-18 s); in the census runs it
didn't in 3 of 5 (680-770 awake at 60 s, frames ~60 ms, Jolt's step ~30 ms).

**Broken counts.** The street: branch 910-913, main 912-913 (and 911-918 in the census runs).
The farmhouse: main is two-moded, ~715-725 or ~855-880: in two of three series runs and one of two
`--deterministic` runs the roof (boards, trusses, rafters, the loft floor, east studs: ~114
members in one settle) came down ~8 s after the last stick, with ~1,440 pieces awake against
the house and nothing else going off. The branch's eight runs are all in the low mode (709-724):
with the piles asleep, nothing knocks it down. Main isn't repeatable here even under
`--deterministic` (713 and 857, as #538 found for the saloon's three sticks), so a deterministic
pair can't name the difference member by member; the one pair taken (before the blast rule)
differed by one west stud of 713.

RubbleSleep's own cost: under 2.3 ms on its worst frame, ~0.2 ms a frame mean while there's
rubble (`rubble_sleep` timer); nothing once all is asleep.

## With #590 on main (the farmhouse's slow motion, merged 2026-11-02 before this)

#590 took out three things that *woke* the piles (RubbleRest's shapes set aside as a pile slept,
earth laid up through resting pieces, pieces pressed under a dug tile); this takes out what keeps
them *from sleeping*. Main with #590 against this branch merged with it, alternately, #590's
`in=farm` with `sticks=6 gap=1.5`, two pairs each:

| | broken | settled (s after the last stick) | < 50 awake (s) | frame median, 10-60 s | Jolt's step |
|---|---|---|---|---|---|
| farmhouse, main (#590) | 619, 744 | 29, 33 | 29, 32 | 18.7, 25.9 | 2.5, 2.9 |
| farmhouse, branch | 619, 619 | 14, 15 | 14, 14 | 14.7, 15.4 | 2.1, 2.2 |
| street, main (#590) | 930, 934 | 18, never (748 awake at 60 s) | 18, never | 21.3, 54.7 | 2.7, 32.6 |
| street, branch | 929, 932 | 8, 10 | 8, 9 | 19.9, 21.6 | 2.4, 2.6 |

Together they settle in half the time #590 does alone at the farmhouse, and the street's piles
that #590 leaves awake for the minute (one run in two) sleep 8-10 s after the last stick.
