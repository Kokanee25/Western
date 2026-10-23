# Movement presets, measured

Flat floor, 60 Hz physics, `experiments/movement_feel/measure.gd` (2026-10-23).
The old movement's column is worked out from its numbers (acceleration 30, deceleration 22, bob
0.022 m at 0.7 a metre, a footstep every 0.75 m, the eyes sliding 3.5 m/s to a crouch).

| | old | light | middle | heavy |
|---|---|---|---|---|
| to a walk (95%), s | 0.09 | 0.13 | 0.30 | 0.50 |
| standstill to a full run (95%), s | 0.19 | 0.38 | 0.97 | 1.62 |
| stop from a walk, s | 0.13 | 0.17 | 0.32 | 0.47 |
| ... and carried on, m | 0.18 | 0.20 | 0.41 | 0.63 |
| stop from a run, s | 0.27 | 0.33 | 0.67 | 0.95 |
| ... and carried on, m | 0.82 | 0.95 | 1.95 | 2.66 |
| steps a second walking | 3.70 | 2.95 | 2.80 | 2.80 |
| steps a second running | 8.00 | 4.00 | 3.53 | 3.33 |
| head travel walking (top to bottom), cm | 4.40 | 2.42 | 3.69 | 5.23 |
| head travel running, cm | 7.00 | 4.23 | 6.38 | 9.29 |
| footfalls with the head at its low (share; old: not tied) | – | 1.00 | 1.00 | 1.00 |
| lean into a walking strafe, degrees | 0.00 | 0.67 | 1.70 | 2.59 |
| dip landing a jump, cm | 0.00 | 1.91 | 5.04 | 9.00 |
| crouch, 90% of the way down, s | 0.13 | 0.18 | 0.22 | 0.30 |
| ... sinking past it, cm | 0.00 | 0.00 | 0.55 | 1.55 |
| stand up, 90% of the way, s | 0.13 | 0.18 | 0.22 | 0.30 |
| the player's physics frame walking, ms (headless) | – | 0.25 | 0.29 | 0.25 |
| the body's motion alone, µs | 0.00 | 6.45 | 7.96 | 5.59 |
