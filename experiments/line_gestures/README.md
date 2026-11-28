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

## Results

See `results/table.md` (and the PR).

## What the face can't do yet (the MetaHuman, #692)

Today's talking faces have the shapes `brows_up`, `brows_down`, `squint`, `scowl`, `smile`, `smile_l`,
`smile_r` (tools/faces/talking_face.py, MakeHuman's units). What a tag wants beyond them is named in
`config/delivery.json` by its ARKit name and set wherever a face has a shape of that name: the set jaw
(`jawForward`, `mouthPressLeft/Right`), wide eyes (`eyeWideLeft/Right`), the sad inner brow
(`browInnerUp`), the corners down (`mouthFrownLeft/Right`), the sneer (`noseSneerLeft/Right`), the
smile's cheeks (`cheekSquintLeft/Right`). Sean's MetaHuman re-export with its 52 ARKit shapes (#692)
gets them with no code change.
