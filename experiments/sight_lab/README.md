# The sight lab (more cores, step 3)

`SightWorld` (`addons/saltcreek_native/src/sight.rs`, `sight_geo.rs`) and its face `Sight`
(`src/people/sight.gd`) answer the game's sight lines in place of Jolt (docs/briefs/more-cores.md,
"The design" A; docs/LAYOUT.md, "addons/saltcreek_native"). This lab measures what it holds and
how its answers and costs compare with Jolt's. The gate itself is `tests/test_sight_world.gd`; the
numbers are in `experiments/gunfight_lab/results/2026-10-26_step3/`.

```sh
python3 tools/bridge.py start --headless
python3 tools/bridge.py "gf_play spec_hall bodies=studio" "wait 1" "sight_census"   # what's on the sight layers
python3 tools/bridge.py "sight_bench 2000"       # random lines through the spec saloon both ways: us a line, disagreements
python3 tools/bridge.py "sight_cover_at 9.8 0.78 5.4 7.62 2.38 0.55"   # gf_coverwhy in the spec saloon's own space
python3 tools/bridge.py stop
```

- `sight_census [MASK]`: every body in the tree on MASK by class, shape types and mode (in the
  spec saloon's fight: ~13,700 member boxes, the lamps' and dressing's boxes, the ground's rises,
  the horses' and the player's capsules, the mop bucket's cylinder; rubble, carved members and dug
  tiles come in a fight).
- `sight_bench [N]`: N random lines through the saloon asked of Jolt (`intersect_ray`, a query
  made each time, as the game did) and of Sight (`clear`, `cast`, `lines`), microseconds a line.
- `sight_cover_at`: the gunfight lab's `gf_coverwhy` with both points in the building's space.

The gunfight lab's `run.py --game-args=--jolt-sight` runs the same build with every sight line
asked of Jolt through Sight's face, for a same-build comparison.
