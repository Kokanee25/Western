# Measured (a guide; Sean's ear decides)

No pre-1925 cornet record could be fetched this session (archive.org and loc.gov are outside this
environment's network), so the yardstick is VSCO 2 CE's real trumpet and drums (CC0, recorded by real
players; a trumpet, not a cornet: brighter). All measured dry.

## The cornet: brightness rising with loudness (spectral centroid 150 Hz-9 kHz of a held note, Hz)

| Note | VSCO trumpet soft (v1) | VSCO loud (v3) | ours soft (0.2) | ours middling (0.5) | ours loud (0.9) |
|---|---|---|---|---|---|
| C4 (midi 60) | 1210 | 1958 | 1121 | 1362 | 2368 |
| E♭4 (midi 63) | 907 | 1796 | 1205 | 1216 | 1723 |
| B♭4 (midi 70) | 1354 | 2128 | 1349 | 1385 | 2292 |
| D5 (midi 74) | 1121 | 2182 | 1992 | 3152 | 4005 |

## The cornet in the march (110 notes, `cornet_check.py`)

- every note speaks on its own partial: 110/110
- pitch against equal temperament: median +7 cents, 5-95% -3 to +36 (the horn's own faults half lipped away; a note's first ~100 ms runs up to +35 sharp before it settles)
- the onset (10% to 90% of the note's level): median 48 ms (VSCO's trumpet sustains: 25-50 ms on most notes)

## The drums: one stroke each

| | -20 dB after the peak | -40 dB | lowest strong peak | 0.1-0.3 / 0.3-1 / 1-3 / 3-8 kHz (dB, the loudest band 0) |
|---|---|---|---|---|
| VSCO bass drum (v4) | 105 ms | 703 ms | 83 Hz | 0 / -14 / -27 / -33 |
| VSCO snare, snares on (v5) | 69 ms | 292 ms | 237 Hz | 0 / -5 / -8 / -9 |
| ours, bass drum (0.7) | 257 ms | 603 ms | 73 Hz | 0 / -25 / -41 / -48 |
| ours, side drum (0.7) | 91 ms | 216 ms | 553 Hz | -7 / 0 / -6 / -9 |

`spectrum.png`: the march's first bars, VSCO over ours, the cornet then the drums.
