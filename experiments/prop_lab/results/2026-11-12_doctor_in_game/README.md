# The doctor's furniture in play (#844), 2026-11-12

The game itself (`-- --world=valley,--real`, Forward+ under lavapipe, 960x540), driven by `tools/bridge.py run bridge_script.txt`:
the player stands on the walk, walks in through the street door (3 m, arrived in the front office) and looks round;
then free-camera views of each room at its hour, the surgery at night with its lamp lit.

`sheet.jpg`, left to right, top to bottom: the street door from the walk; the front office as walked in (his
roll-top and chair); the street door from inside; the dispensary (counter, scales, mortar, bottles); the front
office; the hall's kitchen door; the sick room (both cots, the second now along the back wall); the surgery by
morning (the examining table, the instrument tray under the east window); the surgery at night.
("The game stalled over 5 s" is lavapipe drawing the first frames of a room, not the game.)

`middle_chimney.jpg`: the "metal post at a door" Sean saw (#844): `chimney/middle/0..2`, the front office's
brick chimney (`spec_building.gd` `_chimneys`, `doctor.json` `chimneys.list` "middle"), drawn in the game's
stone until a brick is made; beside the office's back door it reads as a blue-grey iron column. Also fixed in
this merge: the summer beams' front posts stood 0.15 m proud beside the street door (now inside the wall).
