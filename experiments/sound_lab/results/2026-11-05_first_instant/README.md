# The first instant (#596 step 3, films), 2026-11-05

One stick (0.2 kg) going off: the flash (white-hot to orange and out in 0.1 s, one light with no
shadows, 12 unlit glows that go with it), a low ring of dust kicked out along the ground or floor,
and loose dirt (splinters, on boards) thrown up and falling back. `BlastCloud`; dials in
BlastTuning "The first instant", all proposed. Sean judges by eye.

```sh
python3 experiments/sound_lab/run.py "--scenario=instant_*" --out=build/sound_lab/instant --jobs=2 --picture
ffmpeg -i build/sound_lab/instant/<s>/movie.avi -vf scale=960:540 -c:v libx264 -crf 24 -preset slow \
    -pix_fmt yuv420p -c:a aac -b:a 160k -movflags +faststart films/<s>.mp4
```

| film | the stick | you |
|---|---|---|
| `instant_street_5` | Main Street's dirt in front of the saloon and the store (8, 0, -8) | 5 m north, facing it |
| `instant_street_30` | the same | 30 m west down the street |
| `instant_saloon_5` | the saloon's hall floor near the bar (11, 0.78, 7) | 5 m off in the hall |
| `instant_saloon_30` | the same | ~25 m, across the street to the east (22, 0, -16), through its front: the farthest clear view from the street (from the west the store is in the way). **Nothing shows from outside**: the flash and the dust stay in the room (dust out by doors and windows is step 5's) |

Each runs ~3.5 s before the bang and 5 s after, 1280x720 at 60 fps under lavapipe (a drawn run ~15
min here), scaled to 960x540. "Before": step 2's films (`../2026-11-04_on_you/films/stick_5m.mp4`,
`stick_30m.mp4`, main's look at the street's east end, not the same spot).

What a drawn film showed, and changed: added glows were lost on the sunlit street (now drawn over it,
not added); the first ring was too faint (more, bigger puffs, further out); the dirt flew so fast and
high it read as specks across the sky (slower, narrower, more of it). Indoors the puffs (which don't
collide) would have run out through the saloon's walls: the ring's reach is held to the third-nearest
wall of eight rays (`BlastCloud.room_reach`), and the dirt and chunks to the ceiling (`speed_cap`).
Two games drawn side by side read each other's running marker as a crash ("didn't quit cleanly" over
the film): `--picture` runs now get their own crash box (`--crash-box=`) and no stall reports.
