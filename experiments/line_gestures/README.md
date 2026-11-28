# Lines with the face and body (#1316)

What a man saying a line does with his face and body, and what the men by him do: before (LineGesture
off: only his mouth moves, and the room's bits) and after (a line's delivery tag drives his face and a
gesture on its beat; the listeners answer).

- `sheet.gd` + `sheet.py`: the contact sheet (`sheet.jpg`): one man says a line of each tag and is caught
  on its beat, off then on, his face inset; then a man mocking another with a third by. A plain stage by
  day (saloon B at night crashes the software renderer, #1260).

      xvfb-run -a godot --path . --rendering-driver vulkan --fixed-fps 60 -s res://experiments/line_gestures/sheet.gd -- --out=build/lg_sheet
      python3 experiments/line_gestures/sheet.py build/lg_sheet experiments/line_gestures/sheet.jpg

- `bridge.gd` + `run.py`: the bench in the running valley, headless: an evening in saloon B (20:00, stood
  at the bar) and Main Street by day (13:00, walked end to end), gestures off and on, two game hours each.
  For each line within 15 m of you: its tag; for the speaker and every man within 4 m, the most his
  face's shapes moved off where they were as it began, and his arms, body and head turned (degrees),
  over the line and a second after. `table.md` the shares that moved (face > 0.15, arms > 8°, body > 4°,
  head > 6°) and the medians.

      python3 experiments/line_gestures/run.py experiments/line_gestures/results

## Results (2026-11-28, two game hours a spot, this workspace's 2.1 GHz core)

| | saloon B 20:00-22:00, off | on | the street 13:00-15:00, off | on |
|---|---|---|---|---|
| lines within 15 m (an exchange's) | 83 (45) | 80 (48) | 9 (0) | 10 (1) |
| tagged (not calm) | 30 | 29 | 1 | 2 |
| a tagged line's speaker: face moved > 0.15 | 0 of 30 | 21 of 29 | 0 of 1 | 0 of 1 |
| men within 4 m who answered it | 0 of 84 | 44 of 96 | - | 1 of 1 |
| gestures played (the most) | none | lean_in_small 7, laugh_shake 5, proud 4, nod 4, jab 4, low 4, head_back 3, mock_tilt 3 | none | proud, nod |
| `faces` timer, ms a tick (FaceLife, FaceSpeech, LineGesture) | 0.039 | 0.105 | 0.011 | 0.010 |

Before: a man saying a line moved his mouth and, at the bar, his room bit (a laugh, a toast) when the
director gave him one; nothing else in his face or body followed the words, and nobody near him answered.
His joints moved anyway (`table.md`: median 50° of arm at the bar, off or on), from his chores, so
the joints' share can't tell a gesture from wiping a glass; the face and the answers can. The listeners
who didn't answer weren't calm, were Sarge, or were past 1.5 x `listen_m` from him. By day the street's
men seldom stand together (#1293's finding), so few lines are said near you there. The cost:
+0.07 ms a tick at the busiest (+0.04 at Sean's clock), only while lines play; the people's total held
(people_body 2.3-2.5, senses 0.9 either way).

## What the face can't do yet (the MetaHuman, #692)

Today's talking faces have the shapes `brows_up`, `brows_down`, `squint`, `scowl`, `smile`, `smile_l`,
`smile_r` (tools/faces/talking_face.py, MakeHuman's units). What a tag wants beyond them is named in
`config/delivery.json` by its ARKit name and set wherever a face has a shape of that name: the set jaw
(`jawForward`, `mouthPressLeft/Right`), wide eyes (`eyeWideLeft/Right`), the sad inner brow
(`browInnerUp`), the corners down (`mouthFrownLeft/Right`), the sneer (`noseSneerLeft/Right`), the
smile's cheeks (`cheekSquintLeft/Right`). Sean's MetaHuman re-export with its 52 ARKit shapes (#692)
gets them with no code change.
