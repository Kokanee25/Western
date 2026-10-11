# Blind critic, e8

I looked only at `ear.png` and `face.png` in this folder, and spent most of the time on `ear.png`.
To compare them I zoomed crops of each panel and measured pixel differences between panels. In
`face.png`, A and B are identical except at the two ears (0.2 % of pixels differ, all on the
ears' rims). C differs from both at square level across the whole face (about 5 % of pixels: a
different shade on scattered single squares) and at the ears. On the face itself C is as flat as
A and B: lit neighbouring pixels within 1 grey level 0.66 against 0.66, where the master's are
0.54. So in practice the panels differ at the ears.

## Feature 1: ear (`ear.png`)

| Panel | Square regularity | Crispness | 3D form | Semantic readability | Resemblance to master's style |
|---|---|---|---|---|---|
| A | 2 | 3 | 2 | 2 | 2 |
| B | 2 | 3 | 2 | 2 | 2 |
| C | 3 | 3 | 3 | 3 | 3 |

**Best (C) against the master:** the master's ear is a C-shaped curl. A lit helix rim wraps
round a dark concha, with an antihelix ridge inside, and dark hair frames it. C's ear is still a
straight diagonal wedge. Its darker hollow (the deep-red block in the middle of the wedge, about a
third of the way up) sits inside a lit band, but no rim curls over the top or back down, so it
reads as "something with a hollow" rather than an ear.

**Worst (A, with B almost the same):** the inside of the wedge breaks into thin slanted slivers
and single-pixel steps, from its tip at the top (where it meets the hat's shadow) down to the
middle. The dark-red streak there runs along the wedge as a line, not a hollow, so there is
neither a rim nor a hollow to read, only a lit blade. B differs only in a hot, thin cream line
up the outer edge near the tip. That line hints at a rim edge, but it is one or two pixels wide,
much finer than the master's squares, and on the shadow-side ear in `face.png` the same change
gives B a near-white square that reads as a glint.

## Feature 2: face (`face.png`)

| Panel | Square regularity | Crispness | 3D form | Semantic readability | Resemblance to master's style |
|---|---|---|---|---|---|
| A | 3 | 4 | 3 | 3 | 3 |
| B | 3 | 4 | 3 | 3 | 3 |
| C | 3 | 4 | 3 | 3 | 3 |

**Best (all three are effectively tied; C by a hair at its ears) against the master:** the
master's skin squares carry fine variation inside and between them (cheeks, forehead), and its
eyes are drawn as almond shapes with lids and a soft white either side of the iris. In the
renders the skin is a quilt of flat, tilted squares a little too even and too bright, and each
eye is a dark slot with tiny star-like white specks at its corners (centre of each panel, under
the brim). The specks read as glints, not as eye whites.

**Worst (A or B, identical apart from the ears):** the moustache is one solid black slab with a
square-cornered notch. It keeps the skin gap under the nose (the philtrum), but it lacks the
master's drooping, tapering ends and the drawn edge where the moustache meets the lip. Together
with the slot eyes, this makes the face read as stencilled rather than drawn. The ears at both
panel edges are lit wedges with no rim.

## Final ranking over all features

1. **C**: the only panel whose ear has blockier, more even squares and a dark hollow set inside a
   lit band, so it reads a little more as a solid ear. Its face is level with the others.
2. **A**: the same face as B. Its ear is a fragmented lit blade with a streak, not a hollow, but
   it has no hot spot.
3. **B**: the same as A, plus a hot, too-thin cream line on the lamp-side ear's rim and a
   near-white square on the shadow-side ear. Both are finer and hotter than anything in the
   master's drawing.
