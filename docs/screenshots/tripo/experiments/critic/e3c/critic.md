# Blind critique: e3c (panels A and B against the MASTER)

A first note: A and B are almost the same image. I compared them pixel by pixel (my crops are in
`critic_e3c_work/`):

- **eyes, ear, hat:** identical.
- **face, collar, coat:** they differ by under 1 % of pixels, and only where the moustache or
  the nose base is in frame.
- **nose_moustache:** the one real difference (about 2 % of pixels) is in the moustache and
  nostrils:
  - B has a hard, near-black square block right under the right nose wing, joined to the top
    of the right moustache mass. A has orange skin there, with only a hairline dark crease.
  - B's left moustache mass is a shade lighter (mean L of the dark pixels: A 18, B 20, the
    MASTER 29).

So all the scores below are the same for A and B except on the nose and moustache.

Scores: 1 = far from the MASTER, 5 = as the MASTER. Columns: Reg = square regularity, Crisp =
crispness, 3D = 3D form, Read = semantic readability, Style = resemblance to the MASTER's style.

## face

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 4 | 3 | 2 |
| B | 2 | 3 | 4 | 3 | 2 |

**Best (B) against the MASTER:**
- The MASTER's face is an even mosaic of roughly equal, flat squares in close warm tones.
- B's cheeks and forehead break into slanted, uneven strips and wedges. This is worst down the
  lit right cheek and jaw line, where long diagonal slivers run along the edge.
- The eyes are pure-white jagged specks, where the MASTER's whites are shaded squares.

**Worst (A):**
- Its flaw is shared with B: under the chin (bottom left and centre) the collar is a smeared
  cream-and-white blotch with near-black holes, not a readable collar.

## eyes

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 3 | 3 | 2 |
| B | 2 | 3 | 3 | 3 | 2 |

**Best (B, identical to A) against the MASTER:**
- In the MASTER each eye is a few deliberate squares: a shaded off-white, a dark iris square,
  a lid line. B's eyes are dark slits sprinkled with single-pixel, pure-white L-shaped glints.
- That is fine-pixel noise, much smaller than the MASTER's squares, so the whites read as
  sparkle, not as eyeballs. This is clearest in the left eye at about one third across.

**Worst (A):**
- The brows are soft, dark smudges whose top edges fade into the hat's shadow.
- Above them the hat brim is a smooth gradient with a thin, aliased highlight line, not squares.

## nose_moustache

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 4 | 2 | 3 |
| B | 2 | 3 | 4 | 3 | 3 |

**What the two panels share, against the MASTER:**
- The MASTER's moustache is dark brown with visible square-to-square tone inside it. Its outline
  is a stepped, jagged edge of squares. The skin gap at the middle of the upper lip is a small
  notch.
- The MASTER's two nostrils are separate dark ovals sitting in skin above the moustache, with a
  band of skin between nostril and moustache.
- In both A and B the moustache is a nearly flat near-black slab (almost no inner tone). The gap
  of skin under the nose is far too big: a light vertical strip two to three squares wide, running
  from under the nose right down to the lip line. It reads as a hole cut through the moustache
  rather than a small parting.
- A one-pixel dark crease runs diagonally across the nose base from the left nostril to the right.
  It is finer than the square grid and not in the MASTER's language.

**Best (B) against the MASTER:**
- B has a dark block under the right nose wing, so a second nostril can be read and the pair looks
  balanced, as in the MASTER.
- But that block is fused straight into the top of the right moustache mass. The skin between the
  nostril and the moustache is gone, and the moustache seems to climb into the nose (centre right,
  just below the nose wing).

**Worst (A):**
- Only the left nostril exists, and it too is fused into the top of the left moustache mass
  (reddish-black blocks).
- The right nostril is missing: just orange skin and the thin crease. The nose base therefore reads
  lopsided and unfinished at centre right.

## ear

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 2 | 1 | 2 |
| B | 2 | 3 | 2 | 1 | 2 |

**Best (B, identical to A) against the MASTER:**
- The MASTER's ear is a clear, lit rim in squares around darker folds and a hollow.
- In B no ear can be read. Under the hat brim is a dark mass, then a hot orange sliver of
  cheek with a red smear. Its right edge is cut by a long, hard diagonal staircase into the black
  background (lower right).

**Worst (A):**
- Same as B: the rim, the hollow and the earlobe are absent or lost in shadow.
- The only strong shape is a slanted, trapezoidal wedge of skin (lower left to centre), not an ear.

## collar

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 3 | 2 | 2 |
| B | 2 | 3 | 3 | 2 | 2 |

**Best (B, identical to A) against the MASTER:**
- The MASTER's collar is two crisp, pale wing points with sawtooth square edges. A dark band of
  shadow sits under them, and the coat beside them is a regular weave of dark squares.
- B's collar is cream, white and black blotches of irregular size along the left and bottom edge.
  No collar point, edge or shadow line can be picked out.

**Worst (A):**
- Same as B: across the lower half, collar, neck and neckerchief run together into one mottled,
  muddy patch.
- The only crisp line is a thin dark arc along the jaw, much finer than the squares.

## hat

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 3 | 2 | 4 | 3 | 2 |
| B | 3 | 2 | 4 | 3 | 2 |

**Best (B, identical to A) against the MASTER:**
- The MASTER's band is a row of crisp, bright, studded squares on a dark ground.
- B's band squares are about the right size and spacing but blurred, like defocused lights
  (centre right).
- The brim under them is a smooth gradient with a thin highlight line and a hard, aliased
  staircase edge, not a surface drawn in squares.

**Worst (A):**
- Same as B: the soft, glowing band blocks (centre) are the main flaw. They have the MASTER's
  rhythm but none of its crispness.

## coat

| Panel | Reg | Crisp | 3D | Read | Style |
|---|---|---|---|---|---|
| A | 2 | 3 | 3 | 2 | 2 |
| B | 2 | 3 | 3 | 2 | 2 |

**Best (B) against the MASTER:**
- The MASTER's coat lapel is a crisp, dark zigzag of squares beside a pale sawtooth collar.
- In B the coat on the left is a nearly smooth dark brown with only a stepped outline, so its
  surface has no square texture.
- The collar beside it is cream blotches.

**Worst (A):**
- Same as B, and its moustache (top) has the right nostril missing, as described under
  nose_moustache.
- Below the chin, cream and black blots stand in for collar points and their shadow (centre left).

## Final ranking

1. **B:** level with A everywhere except the nose base, where its dark block gives a readable
   second nostril. The cost is that the right moustache mass fuses up into the nose.
   - Shared faults: the over-large skin gap, the flat black moustache, the slanted cheek strips,
     the white-speck eyes, the unreadable ear and collar, and a blurred hat band.
2. **A:** the same picture with the same faults.
   - In addition, the right nostril is missing (skin and a hairline crease) and the left one is
     fused into the moustache, so the nose base reads as lopsided.

The difference between them is small and confined to the nose and moustache. Neither panel yet
draws the MASTER's even, flat, crisp squares. Neither draws its finer, deliberate features: shaded
eye whites, nostrils sitting in skin, a small notch at the middle of the moustache, and collar
points with their shadow.
