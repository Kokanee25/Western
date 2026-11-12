# The harmonica (#790)

Our own free-reed model (`fiddle/harmonica.py`): `red_river_valley.mp3` (G harp), `oh_susanna.mp3` (D
harp), at -18 LUFS. Measured against Jenkins and Jenkins, "Mouth Organ Blues" (1924; `fiddle/fetch.sh`):

| | his | ours, first | ours, now |
|---|---|---|---|
| dip at a change of note (median) | -1.7 dB | -9 to -11 dB | -1.8 to -2.5 dB |
| a note's first 60 ms against the note | -3.1 c | +3 to +15 c | -0.9 to -3.8 c |
| held notes' waver | 1.6 c | 3.7 to 5.4 c | 4.1 to 6.7 c |
| H2..H5 against H1 (f0 300-500 / 500-860 Hz) | -2, -17, -10, -18 | -4, -13, -17, -16 | |

Every melody note within 30 cents. The harmonics' fall-off was already close (the 78's band and his
guitar make that comparison loose). The waver is left: the handover between notes, not the reed.
