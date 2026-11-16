# Bring the House Down

Sean, 2026-11-16: "a tune that is super energetic and lively, one that pulls lots of people to the dance
floor when the dance floor collapses". An original hoedown breakdown (`fiddle/tunes/bring_the_house_down.abc`;
tune and chords our own), G then A, 192 beats a minute (half note 96), boom-chick under it (the kick on
one and three, the snare on two and four: `drum_style: stomp`), rendered by `sections.py --live` with
`tunes/bring_the_house_down.sections.json`:

- the banjo alone for two bars, then the band crashes in; the fiddle's A part (a punched hook) twice, the
  B part (up the neck) twice;
- the banjo's break (the fiddle sits out), then four bars of stop-time, the fiddle alone, running;
- a snare roll, and the whole tune again a step up in A, the crowd cheering as it lands; a three-time tag
  and out on one hit, the cheer.

No crowd clapping (Sean: "the clap sounds horrible"). `live.mp3`: 105 s, stereo, -10.0 LUFS, peak -3.5 dBFS.

## From downstairs and from outside (2026-11-16)

Sean: "give it the live sound from the lower floor of the saloon and from outside". `sections.py --live
--place=downstairs|outside` hands the stage mix to `fiddle/places.py`: the band upstairs in Saloon B's
dance hall (its own ~1.1 s reverberation, nobody close to a player) and forty-odd dancers' heels on the
boards on every beat, half of them on the off-beat too (the plan's `dance_bars`, by default from the
drums' first bar to the end).

- `downstairs.mp3` (at the bar, under the dance hall): the hall's sound down the 14 x 22 ft well, a
  little darker; through the floor, the lows (the mass law) and the feet in the joists; the bar room's
  ~0.8 s and a murmur. -15.5 LUFS (the feet's peaks hold it there).
- `outside.mp3` (across Main Street): the bass and kick through the walls, the hall's sound faint out
  of the open doors and windows, the feet as a low thud, a slap off the false front across the street,
  wind and crickets; the saloon a little left. -17.4 LUFS.

Both are measured, not yet heard: next to the live mix, the 0.8-3 kHz band sits ~6-7 dB further down
against the lows (the fiddle dulled, the floor's boom up).
