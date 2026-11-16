# In the Sweet By and By (1868)

Sean, 2026-11-15, after asking for Caamp's "By and By" (copyrighted: declined; this instead). Joseph P.
Webster's hymn tune (Lyon & Healy, Chicago, 1868; public domain), **written out from memory**
(`fiddle/tunes/sweet_by_and_by.abc`): no printed score was reachable (Hymnary.org is behind a bot
challenge; the 1875 Gospel Hymns music edition, read through its OCR text, doesn't have it; the 1895
Himnos evangélicos prints words only). Up-tempo band arrangement by `sections.py`
(`tunes/sweet_by_and_by.sections.json`), G, 120 bpm, ~86 s: `song.mp3`. The fiddle's pitch check reads
84% within 30 cents: the misses are B notes over the fiddle's open-D drone, which the pitch tracker hears
as the G the two imply (380 cents low, the same on every one), not the fiddle out of tune.

## Live take (2026-11-16)

`live.mp3`: Sean asked "how do we make it loud and full of energy, like a live high-energy show".
`tunes/sweet_by_and_by_live.abc` (132 bpm; verse, chorus, verse, chorus, a 4-bar stop-time break,
a fill bar, the last chorus up a step in A) with `sweet_by_and_by_live.sections.json`, rendered by
`sections.py --live`: players panned across the stage (constant power), the crowd clapping on two and
four where the plan says `crowd`, a cheer at the key change, applause at the end, a synthetic hall
(RT60 1.4 s), a bus compressor (3:1), tanh saturation and a peak ceiling; -10.0 LUFS, peak -3.3 dBFS.
The compressor flattens the arc (every 6 s window sits between -9.5 and -10.9 LUFS), as a loud live
mix does; the energy comes from the arrangement, not the level.
