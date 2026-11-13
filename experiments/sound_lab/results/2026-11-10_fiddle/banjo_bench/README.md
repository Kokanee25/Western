# The banjo bench (#790)

Sean, 2026-11-12: "make an artifact that's just the banjo until it's perfect - can you try making it
sound more like the band dead south". The Dead South's banjoist (Colton Crawford) plays open-back banjos
(a Vega Little Wonder, a Deering Saratoga Star), clawhammer and three-finger (Deering's artist pages).
Every clip here is one fixed gain to -22 LUFS (`fiddle/bench_clip.py`), Turkey in the Straw in open G.

## Round 1: two right hands on a modern open-back

`r1/`: `claw_modern` (A: clawhammer), `rolls_modern` (B: three-finger rolls with picks), both
`--strings=modern`; `ref_gut` and `ref_steel` the period banjos to compare. Brightness (centroid): A 1.80
kHz, B 1.96, gut 1.11, steel 1.68; above 4 kHz -16.3, -13.7, -25.2, -17.2 dB.
