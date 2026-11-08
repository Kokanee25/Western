# The game's blast_lift 0.8 against #492's gate, 2026-11-05 (#636)

`bf_blast at=6.0,0.8,6.0 fuse=1 seconds=6 men=3 men_r=1.0 lift=L` (the spec saloon, one stick,
three standing men a metre round it), lift 0.8 (the game's now) and 0 alternated, twice each, one
game at a time; `gate.py` -> `gate.jsonl`. ms at Sean's (x0.65):

| | stick's worst frame | frames over 100 | frames over 50 | mean of 5 s after | thrown (m) |
|---|---|---|---|---|---|
| lift 0.8 | 79, 76 | 0, 0 | 2, 5 | 26.1, 26.0 | 4.4, 4.6, 1.3 |
| lift 0 | 90, 92 | 0, 0 | 13, 2 | 33.0, 24.8 | 1.6, 1.5, 1.0 |

The one-hitch line passes both ways (no frame over 100 at Sean's); the throw costs nothing (if
anything the thrown men's frames are lighter). Back above 50 fps takes ~11 s both ways, as it did
with no men on 2026-11-04 (8-10 s): the saloon coming down after a stick, not the men or the throw.
Broken members 632-633, as before.
