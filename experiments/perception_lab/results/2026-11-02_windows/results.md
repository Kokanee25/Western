# Fix 3: windows (issue #565, 2026-11-02)

The baseline's item 4, "windows are walls to the eye": every unbroken pane was a `StructureMember` on
`Layers.WORLD`, so `Sight.clear` stopped on it and nobody saw or was seen through glass.

**The fix (the whole game):** the sight service holds a pane on a sight-only bit
(`Layers.SIGHT_GLASS`, the plugin's `sight_layer`; `Sight.KIND_GLASS`), so every line looked along
on WORLD (Senses, a man's shot line, Cover, SightLight's sky and lamps) passes glass, and the
physics keeps it on WORLD (a ball still meets it and breaks it, nobody walks through it). Without
the plugin, `Sight._jolt_hit` does the same with Jolt. `Sight.see` says when a line went through
glass, and Senses dims a man seen through it (SightTuning `glass_seen` 0.8) and for glare: from the
bright side into the dark one by the ratio of the light on him to the light on the looker (down
to `glass_glare_min` 0.25 at 1:50 and below).

**Measured** (the sight group, 60 cases, `run.py --group=sight`; before on main at 7705909, after
on the branch; tables here): only the three window cases changed. Everything else the same to the
tick.

| case | light | before | after | expected |
| --- | --- | --- | --- | --- |
| through_window (a man a step behind the saloon's window, 9.5 m out) | day | never | 3.32 s | either |
| | golden | never | 3.32 s | either |
| | night, lamps lit | **never (MISSED)** | **1.18 s** (slow: the 1 s mark) | sees |
| | night, lamps out | never | never | doesn't |

Verdicts: 29 as expected both; missed 3 -> 2, slow 14 -> 15 (the lit window, now seen, a little
over the 1 s mark). By day the glass gives back the street: 3.3 s to pick him out, against 0.7 s
in the open.
