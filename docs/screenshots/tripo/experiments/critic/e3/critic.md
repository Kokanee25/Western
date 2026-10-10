# Blind critic: e3

Scores run from 1 (far from the master) to 5 (as the master). The columns are: Reg = square
regularity, Crisp = crispness, Form = 3D form, Read = semantic readability, Style = resemblance to
the master's style.

**A and B are the same panel almost everywhere.** A pixel comparison finds no difference on eyes,
ear, collar and hat. They differ only in the middle of the moustache (and in the corner of the coat
crop, where the moustache shows), where B has a lit notch of skin and A has solid dark. So their
scores match except where the moustache counts.

**Faults common to A, B and C, compared with the master:**
- The squares lie on the surfaces, not on one steady grid. On the cheeks, forehead and neck they
  are slanted, stretched into trapezoids or tall strips, and broken where planes meet.
- Silhouettes step in 1-pixel stairs (brim, ear, jaw) instead of the master's square-sized steps.
- The face is a hotter, paler orange with weaker cool and dark accents.

## Face

| Panel | Reg | Crisp | Form | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 4 | 4 | 3 | 3 |
| B | 2 | 4 | 4 | 4 | 3 |
| C | 2 | 2 | 4 | 2 | 2 |

- **Best (B) against the master:** the master's cheeks and forehead are even, near-square clusters
  in a steady mosaic. B's cheeks (left-centre and under the right eye) are tall vertical strips and
  skewed quads that change size and angle across the face. It reads as a texture stretched over a
  surface rather than an authored mosaic.
- **Worst (C):** the moustache (centre) is a soft brown smudge with averaged edges and a red lip
  line bleeding through. The eyes carry small star-shaped white glints instead of drawn whites.

## Eyes

| Panel | Reg | Crisp | Form | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 4 | 3 | 3 | 3 |
| B | 2 | 4 | 3 | 3 | 3 |
| C | 2 | 3 | 3 | 2 | 2 |

- **Best (A/B) against the master:** the master's eye is a clear almond, a grey-white sclera mass
  either side of a dark iris, under a lid line. In A/B the whites are only a few isolated cream
  pixels at the corners (the left eye's inner corner, and a bright fleck below the iris). They read
  as glints, not the white of an eye. The lids and iris merge into one dark slit.
- **Worst (C):** both eyes are narrowed to dark slits with cross/asterisk-shaped white sparkles at
  their corners (the right eye shows this most). The brows above are softer, mottled bands rather
  than the master's solid dark brow squares.

## Nose and moustache

| Panel | Reg | Crisp | Form | Read | Style |
|---|---|---|---|---|---|
| A | 3 | 4 | 3 | 3 | 3 |
| B | 3 | 4 | 3 | 4 | 3 |
| C | 2 | 2 | 3 | 2 | 2 |

- **Best (B) against the master:** B has the philtrum gap, but as a hard lit vertical slot cut
  through the moustache, left of centre. The master's moustache is a mid-dark brown built of
  several tones of square, with a subtle lighter middle. B's is a flat near-black cut-out with no
  internal squares. The nostril is only a faint dark line at the nose's base, where the master
  draws a distinct dark nostril square.
- **Worst (C):** the whole moustache (centre-left) is blurred, averaged brown with no hard edge. A
  dark-red lip line shows through its lower edge. There is no philtrum gap and no readable split
  between moustache and lip.

## Ear

| Panel | Reg | Crisp | Form | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 2 | 1 | 2 |
| B | 2 | 3 | 2 | 1 | 2 |
| C | 2 | 3 | 2 | 1 | 2 |

- **Best (all three are alike) against the master:** the master draws the ear from the side, with
  rim, hollow and lobe in deliberate squares framed by dark hair. In the renders the ear is an
  edge-on sliver glowing orange, with a blurred red blotch in its middle (lower centre of each
  panel). There is no rim or hollow, and its outer edge is a 1-pixel staircase.
- **Worst (C, marginally):** the red blotch is the most saturated and the silhouette the most
  jagged against the dark ground. It reads as a lit flame shape, not an ear.

## Collar

| Panel | Reg | Crisp | Form | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 2 | 3 | 2 | 2 |
| B | 2 | 2 | 3 | 2 | 2 |
| C | 2 | 2 | 3 | 1 | 2 |

- **Best (A/B) against the master:** the master's collar is pale points with zig-zag square-stepped
  edges, under a crisp dark neckerchief, with the chin's shadow falling across them. In A/B the
  collar (bottom-left) is a mottled cream-and-black patch like a cow print. There are no collar
  points, edge or shadow shape. Only the jaw's underside (a crisp dark line, top-centre) is drawn
  deliberately.
- **Worst (C):** the neck and collar are bigger, softer blotches. The cream collar dissolves into
  the lit neck (bottom-centre), and the black neckerchief pieces float as loose specks (left).

## Hat

| Panel | Reg | Crisp | Form | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 2 | 3 | 3 | 2 |
| B | 2 | 2 | 3 | 3 | 2 |
| C | 2 | 2 | 3 | 2 | 2 |

- **Best (A/B) against the master:** the master's band is a row of small, bright, distinct square
  studs on dark felt. In A/B the band is large soft rectangles (two to three times the master's
  square) with blurred edges, like an upscaled low-res texture. The brim's edge (left) is thin
  aliased 1-pixel streaks rather than a solid stepped rim.
- **Worst (C):** the band's bright patches smear into one another (centre), so the studs no longer
  read as separate pieces. The brim's underside is a mass of fine streaks.

## Coat (chin, collar and lapel crop)

| Panel | Reg | Crisp | Form | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 3 | 2 | 2 |
| B | 2 | 3 | 3 | 2 | 2 |
| C | 2 | 2 | 3 | 2 | 2 |

- **Best (A/B) against the master:** the master's crop is a strong graphic design: the dark coat
  edge and neckerchief as bold zig-zag stepped bands, pale collar triangles, and an even mosaic on
  the chin. In A/B the coat's edge (left) is a dark smear with slanted streaks. The collar is a
  blotchy cream mass with black specks, so the bold dark/light shapes are lost.
- **Worst (C):** everything is softer. The chin's squares blur, the moustache at the top is a
  muddy smudge, and the collar's cream (bottom-centre) is an averaged glow with no edges.

## Final ranking

1. **B:** the crispest moustache and the only panel with the philtrum gap. Otherwise it shares A's
   faults: slanted, stretched squares; glint-like eye whites; an unreadable ear and collar; a
   blurry hat band.
2. **A:** identical to B, except the moustache is one solid dark slab with no gap of skin. That
   costs it readability on the face, nose and moustache, and coat.
3. **C:** the softest and most averaged throughout: a muddy moustache with the lip bleeding
   through, star-shaped eye sparkles, smeared hat studs and a dissolving collar. It is furthest
   from the master's crisp, authored clusters.
