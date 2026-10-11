# Blind critic, e9b

I looked only at the two images in this folder, `face.png` and `nose_moustache.png`. I enlarged
crops of them, compared the panels pixel by pixel, and made a dark mask of the moustache. A, B and
C are the same in the eyes, brows, hat, ear, skin squares and collar; any differences there are
small and spread across the frame. The real differences are all in the moustache: its outline,
its two ends, and its tone. So the scores below are the same everywhere except where the
moustache is judged.

## nose_moustache.png (the main image)

| Panel | Square regularity | Crispness | 3D form | Semantic readability | Master's style |
|---|---|---|---|---|---|
| A | 2 | 3 | 3 | 3 | 2 |
| B | 3 | 3 | 3 | 3 | 3 |
| C | 3 | 3 | 3 | 4 | 3 |

**Best panel (C) against the master:** in the master, the moustache is a rounded, scalloped mass
of dark grey-brown with lighter brown squares inside it. Its edge steps smoothly in small squares
and it tapers to a point at the left. C's moustache is a flat, near-black slab with a square-toothed
top edge, like battlements. At the philtrum it has a wide square notch filled with a large pale
triangle, which reads more as a hole than as a small gap of skin. Its squares also lean with the
face, where the master's sit square. C's one real gain is the right end: it hangs down past the
corner of the mouth toward the jaw, as the master's does.

**Worst panel (A), its biggest flaw:** the right end of the moustache, right of the mouth near the
jaw, breaks into a few loose dark chips with skin showing between them. It stops at the corner of
the mouth instead of hanging down, so the mass looks broken off rather than drawn. A small stray
chip also sits detached under the left end. In the one way A is better, its tone is a warmer, more
varied dark brown, nearer the master's colour than B's and C's flat black. (Mean colour of the
moustache, RGB: A 37/14/4, B 30/11/3, C 31/12/4, master about 62/30/17.)

**B** sits between them: the right end steps down one square further than A's and holds together,
but it doesn't hang as far as C's.

**Shared by all three, against the master:** the moustache is much darker and more saturated, a
red-black where the master's is grey-brown. Its top edge is a row of equal rectangular teeth, not
a rounded scalloped outline. Under the nose there's no nostril shape, only a small black slit with
an orange square. The master draws a soft dark nostril and a shaded tip.

## face.png

| Panel | Square regularity | Crispness | 3D form | Semantic readability | Master's style |
|---|---|---|---|---|---|
| A | 3 | 3 | 3 | 3 | 2 |
| B | 3 | 3 | 3 | 3 | 3 |
| C | 3 | 3 | 3 | 3 | 3 |

**Best panel (C) against the master:** at the whole-face size, the master's moustache is a heavy,
rounded, drooping horseshoe in dark brown. C's is a black "comb": a square-toothed top edge, a
square notch at the centre, and the drooping right end as the only curve. The squares over the
whole face run on a slant and vary in size, while the master's sit on a steady upright grid. The
face is also brighter and more orange than the master's (mean RGB about 108/59/30 against
91/47/25). The eyes are white-specked slots, not the master's drawn almond eyes with lids.

**Worst panel (A), its biggest flaw:** the same broken right end of the moustache, next to the
mouth corner. At this size it reads as the moustache stopping short and leaving a light gap
between the mouth and the jaw, where the master's moustache wraps down. Everything else in A
matches B and C.

## Final ranking over all features

1. **C**: the moustache's right end hangs down past the mouth corner, the closest of the three to
   the master's drooping shape. Still a flat black slab with a crenellated top and a wide notch.
2. **B**: holds together as one mass with a slight droop on the right. Otherwise like C, but the
   ends are less shaped.
3. **A**: its warmer, more varied brown is nearest the master's tone, but the right end breaks
   into loose chips and stops at the mouth corner, and a stray chip sits under the left end. It's
   the most fragmented outline.
