# The card cheat, 2026-10-24: on AI animation, measured and filmed

The beat (`src/moments/card_cheat.gd`, `config/moments/card_cheat.json`) in the game's saloon at
17:30, Earl (old_rancher_s3) sat back at the front card table, Cody (bold_cowboy_s3) in from the
door; run 20 times each way through the bridge (`run.py`, a fresh game and a seed a run), and
filmed (`film.sh`; Godot's Movie Maker under lavapipe).

| | on the clips (Uthana) | pose to pose (#204's kick) |
|---|---|---|
| finished, no one dead | 20 / 20 | 20 / 20 |
| the chair went from under him | 20 / 20 | 20 / 20 |
| Earl went down | 20 / 20 | 20 / 20 |
| **Earl ends on his back** | **16 / 20** | **20 / 20** |
| Cody drew and stood over him | 20 / 20 | 20 / 20 |
| kick to fall | 2.3 s (the clip's wind-up: the boot lands 2.2 s in) | 0.2 s |

Tallies: `tally_animated.md`, `tally_pose_to_pose.md` (each run's numbers). Films (`films/`):
`bar.mp4` (from the bar's front, where the player stands), `door.mp4` (just inside the door),
`old_vs_new.mp4` (the pose-to-pose kick left, the animated one right, same camera); a sheet of
frames `films_sheet.jpg`.

**What the clips did.** Every kick Uthana gave (nine takes over three prompts, "backward and
low" among them) was a high front kick: the boot at 0.6-1.1 m. The one used (`kick_back` take 2,
0.62 m, 6.9 m/s) meets the chair's back above the seat, not its legs: it stops on the crest rail
and the far post, breaks a spindle, and the chair goes loose from under him (`KitProp.take_blow`
decides each). Earl goes over backwards 0.8-1.4 m and lands on his back 16 times in 20, face
down 4 (his head and shoulders turn on the chair's pieces on the way). The pose-to-pose kick is
the lab's 48 N·s to each back post at boot height, which snaps both legs: he goes straight over
every time. The walk, the draw and the stand-over read as a man's (the films); the stand-over's
gun hand shakes as asked, so the muzzle wanders.

**Where physics won:** the kick's follow-through is cut at the strike (a part moved by script
would otherwise plough through the chair and the man and throw him); the clip's travel stops at
walls and men; Earl's fall is the ragdoll's; a clip ends the moment he goes limp.
