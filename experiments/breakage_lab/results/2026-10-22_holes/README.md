# What's in and round a hole (2026-10-22)

Step 4 of `docs/briefs/dig-ground.md`, on top of the crater (`../2026-10-22_crater/`).
`bold_cowboy_s0`, one game each; the look run `--look=0,0.5,2,4,8`.

## The change

- On `Events.ground_changed`, what stands on the ground looks again:
  - a building's grounded member whose bottom has lost the earth (5 cm, `undercut`, at its corners
    and middle) is grounded no more, and the building settles;
  - a kit prop looks for its feet again (`KitProp._on_ground_changed`: one override in the prop
    lab's file);
  - Fittings drops a prop standing in the street (under 2 m) whose middle has lost the ground;
  - a man who has stood snaps to the ground again, and goes limp when it drops more than a metre
    from under him or he walks on down ground steeper than ~50 degrees more than half a metre
    below where he last stood level. A stick's crater (12 cm, ~30 degree sides) doesn't trip him.
- Under a dug tile the earth is solid: boxes a column of 8 cells (40 cm), each topped 1 cm under
  the lowest surface over it, down through the hardpan. A height field has no thickness; a 2 cm
  bone fragment at 6 m/s had gone through it to the hardpan, 2 m down (six of them in one run).
- The blast's gravel passes by its own clods.
- New scenarios: `ground_dynamite_0m_x3` (three sticks on one spot, 2.5 s apart) and
  `ground_things_dynamite_0m` (a dead man lying 0.55 m from the stick; a 25 kg strongbox dropped
  where the crater opened 2 s after, an unlit stick 3 s after). Bridge commands `dig X Z R DEPTH`
  and `ground X Z`.

## Results

| | |
| --- | --- |
| Three sticks on one spot | 23.7 cm deep (one: 11.3), radius 0.22 m, the lip 6.1 cm high; no flags |
| The dead man beside the stick | ends 0.23 m up (his pelvis), 2.9 cm deepest into anything: thrown over the lip, nothing sunk |
| The strongbox dropped into the crater | asleep, across the bowl (its 0.4 m side spans the 0.4 m crater: it rests on the lip, the bowl 10 cm under its middle) |
| The stick dropped after it | asleep on the strongbox |
| Bone fragments under the ground | none (were six, to 2.06 m down, before the earth was made solid) |
| Flags | the glass shard 8 cm under the street that main has too |
| The player (bridge) | walked across a stick's crater and out; walking into a 1 m deep hole he stood at its bottom (y -0.89) and couldn't walk out (no climbing yet: Sean, "dig out or climb later") |
| Tests | 539 passed; `test_ground` 24 (post, chair, barrel, a man walking and standing, fast bits) |
| Perf bench, at Sean's (step 3 -> step 4) | calm 8.57 -> 8.77 ms, fire 21.19 -> 21.20 ms (noise; the long ray is only cast when the short ones miss) |

## Sheets

- `sheets/three_sticks_and_things_look.jpg`: the two new scenarios, 0 to 8 s.
