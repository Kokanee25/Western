# Hands up (issue #694)

Sean, 2026-11-07: "they all do it". Men put their hands up by swinging their arms straight out
to the sides and over in one flat arc, like a bird flapping.

**Why:** `HumanBody.POSES[&"hands_up"]` turned each upper arm 150 degrees about one axis (z) with
the forearm 25 more in the same plane, and the pose blend lerps Euler numbers: a flat arc, nearly
straight up, elbows almost straight.

**Now** (`src/bodies/human_body.gd`):

- `POSES[&"hands_up"]`: upper arms out at shoulder height, 22 degrees forward of his sides; elbows
  bent 98 degrees; hands at head height (wrist 1.67 m on the 1.78 m anatomy), palms to the front;
  chest 4 and head 6 degrees back. Each arm's turns were solved from those directions (upper arm a
  YXZ turn putting the elbow's hinge across the arm and forearm, the forearm a pure bend, the palm
  turned at the wrist with the hand bent back 15). The skeleton has no clavicles; a Studio man's
  shoulder helper (`PeopleBodies.shoulder_share`) still takes its share of the raised arm.
- `HANDS_UP_KEYS`: the way up, slerped joint by joint from wherever his arms were: early
  (0.11 s, forearms already bent and up in front), mid (0.24 s, upper arms forward and out half
  way, hands at his chin), over (0.40 s, a little higher and wider than the pose), the pose at
  0.58 s. Time runs on an ease-out to the overshoot, then a smoothstep settle.
- Letting them down (any pose after it): the arms slerped to the new pose over 0.5 s
  (`HANDS_DOWN_TIME`), the shortest turn, not the Euler numbers' swing out and over.
- A snapped pose (`_apply_pose(0, true)`, the screenshots, tests) is there at once, no track.

**Test:** `tests/test_hands_up.gd` (elbow 85-115, upper arm level, elbow out and forward, hand at
head height and over the elbow, palm forward, both sides alike; forward first within 0.2 s,
elbows bent within 0.15 s, near the top by 0.6 s, overshoot 1.5-12 cm, never wider than it ends;
down without going over his head). On the old pose it fails on every count (elbow 23 degrees,
hand at 2.04 m, palm sideways).

## The films

`bridge.gd` (lab commands `hu_man`, `hu_cam`, `hu_film`): one man, no brain, at a spot; the free
camera from in front, his right side, or between; every frame drawn saved while his hands go up.
"old" is the pre-#694 pose reproduced exactly in the same build (its numbers, reached by the same
Euler blend: the stand pose's goal plus offsets), so old and new share the light and camera.

```sh
python3 tools/bridge.py start --size=720x720 --fps=60
python3 tools/bridge.py -f build/hu_saloon.txt     # the script is in results/2026-11-07/films.txt
python3 tools/bridge.py stop
```

Results: `results/2026-11-07/` (films old | new, front, side and three-quarter, the saloon at
night with the bold cowboy, the street at golden hour with Brody; each real time then half speed).
