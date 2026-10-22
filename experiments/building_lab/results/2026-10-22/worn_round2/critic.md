# Blind critic: worn wood, round 2

Looked at only the ten renders in this folder and the painting `build/bl/refs/picture.png`.
Crops were brightened (x2-3, gamma 0.8) into `/tmp/claude-0/critic4/`. I picked A or B by eye first,
then used a signed A-minus-B difference map only to find where the marks are and to tighten the
crop boxes. Boxes are in the full 1280x720 frame's pixels.

## Picks

| View | Has the marks | By eye | Strength at this distance and light |
|---|---|---|---|
| entrance | **B** | probably | too faint, except the pale ring round the near round table |
| picture | **B** | probably | too faint, except the pale ring round the table, which is close to overdone and hard-edged |
| stair_close | **A** | sure | about right for the treads; too faint for the rail and soot |
| bar_floor | **A** | sure | overdone (the patch by the bar); the grime line at the bar foot too faint |
| gallery_close | **A** | can't tell at the plain exposure; probably once brightened | too faint, and the wrong kind of mark |

## entrance (B)

| Mark | Box | Reads as |
|---|---|---|
| Pale scrubbed or scuffed ring on the floor round the round table and its chairs | [330,600,560,700] | **Caused** (chairs dragged in and out). At the plain exposure it reads as the table lamp's pool of light, not as wear. Its edge steps in square blocks. |
| Pale patch under the left card table and its benches | [0,600,260,720] | **Caused**, same reading. Stepped edge, visible only when brightened. |
| Lighter diagonal band running from the left toward the round table | [415,490,565,530] | Half **caused** (a path between tables), half a stray shaft of light. Faint. |
| Pale worn swath on the floor, front right, in front of the bar | [1100,560,1280,720] | **Caused** (where drinkers stand). Hard stepped edge on its left side. Faint. |
| Slightly darker line at the foot of the bar front | [950,410,1280,520] | **Caused** (kick dirt). Almost invisible. |
| Soft round glowing blob on the back wall, left of the right-hand sconce | [670,355,715,395] | **Rendering bug** or random decoration: a fuzzy disc on a plain wall at head height, nowhere near anything you'd touch. |

Strength: most of it is lost in the dark. Only the ring under the round table shows without
brightening, and then as light, not as use.

## picture (B)

| Mark | Box | Reads as |
|---|---|---|
| Bright pale patch round the table, under all four chairs | [770,520,1280,720] | **Caused** in where it is (chairs scraping), but it's the brightest thing on the floor, has blocky stepped edges, and reads first as a lamp's light pool or a bleached decal. Close to overdone. |
| Pale scuffed patch on the floor under the chair by the left-hand wall | [120,460,230,510] | **Caused** (a chair always pushed back there). Faint. |
| Lighter, blotchy panel on the wall beside the left doorway | [190,330,225,425] | **Caused** if meant as hands at the door jamb; it's dim and hard to read as anything. |
| Darker line at the foot of the far bar | [330,420,880,450] | **Caused** (kick dirt). Barely there. |

Strength: one mark dominates (the table ring) and the rest are below what a viewer will notice.
The worn floor has no traffic path between the door, the tables and the bar; it's patches round
furniture only.

## stair_close (A)

| Mark | Box | Reads as |
|---|---|---|
| Pale worn patches in the middle of the treads, several steps | [320,380,610,570] (upper treads), [170,630,240,700] (bottom tread) | **Caused**: the centre of the tread where feet land. The most convincing mark in the set: it shows even at the plain exposure. Fault: the patches are made of big square blocks with ragged stair-step edges, and some run over the nosing and down the riser, so up close they look like a low-resolution mask. |
| Lighter polished streaks along the top of the handrail | [240,10,720,300] | **Caused** (where the hand slides). Right idea, but faint; only visible brightened. |
| Pale patch on the floor at the foot of the gallery stair's post (right) | [1130,545,1240,610] | **Caused** (people turn there at the stair's foot). Its shape is a neat blob with a hard edge; it reads a little like a light pool. |
| Faint darker soot above the right-hand wall lamp | [940,90,1030,180] | **Caused** (lamp soot). Too faint to see without a side-by-side. |

Strength: about right for the treads; the rail and soot need roughly double.

## bar_floor (A)

| Mark | Box | Reads as |
|---|---|---|
| Large pale mottled patch on the boards right of the post, in front of the bar | [940,540,1280,720] | **Caused** in idea (in front of the bar), but it sits a metre or more back from the bar's foot rather than hugging it, is the brightest thing in the frame's lower half, and its inside is a coarse checkerboard of pale squares: reads as a texture fault or bleach spill. **Overdone.** |
| Dotted pale streak across the boards left of the post | [715,470,895,535] | **Rendering bug** or decoration: a line of separate pale squares running across the grain, like a mask seam. Nothing explains it. |
| Darker grime band on the floor along the bar's foot | [720,370,1280,480] | **Caused** (spit, boots, the foot rail). Right place, believable, but too faint. |
| Near post (left) darker and grimier overall, a darker band low down | [0,0,700,720], band [0,455,380,545] | Even all over: reads as **decoration** (general dirt) rather than where shoulders or hands go. Faint. |

Strength: overdone in one place and too faint everywhere else; the balance is backwards (the
grime line at the bar foot is the believable one and should be the stronger).

## gallery_close (A)

| Mark | Box | Reads as |
|---|---|---|
| Sparse single pale squares scattered down the gallery walkway | [490,350,740,650] | The placement is **caused** (a walking line along the gallery), but as isolated one-texel dots it reads as **noise or a bug**, not wear. Real wear here would be a continuous paler, smoother lane down the middle of the boards. |
| Paler floor round the table seen through the railings, on the floor below | [1050,520,1260,650] | **Caused** (same chair-ring as the other views). Faint at this distance. |

Not a difference between A and B: both have a pale blotchy patch on the dark door or panel at left
([290,400,380,530]); it looks like a texture artefact in both. The gallery's handrail cap, the
part every hand holds, shows no polish in either image.

Strength: too faint, and the walkway mark is the wrong shape.

## Overall

**The three most convincing marks**
1. stair_close A: pale worn centres of the treads [320,380,610,570]. Right place, readable at the
   plain exposure, instantly says "people use these stairs".
2. bar_floor A: the dark grime band along the bar's foot [720,370,1280,480]. Exactly where it
   should be; just too quiet.
3. entrance B / picture B: the scuffed rings round the tables ([330,600,560,700],
   [770,520,1280,720]). Right logic (chairs dragged), though they need softer edges and less
   brightness to stop reading as lamplight.

**The three least convincing**
1. bar_floor A: the dotted pale streak across the boards [715,470,895,535]: looks like a bug.
2. entrance B: the soft glowing disc on the back wall [670,355,715,395]: looks like a bug.
3. gallery_close A: the scattered single-texel dots down the walkway [490,350,740,650], and with it
   bar_floor A's big checkered patch [940,540,1280,720]: both have the wear's mask showing as
   coarse squares instead of a worn surface.

**What runs through all of it**
- Wear is always **paler**, never smoother or glossier; nothing reads as polish (bar edge, rails,
  the newel cap). The painting's worn floor is lighter *and* has a soft sheen on the lanes.
- The masks are too coarse: stepped, block-edged shapes and checkerboard interiors. Edges should
  fade over a board's width or more.
- What's missing: the **path from the door** (no traffic lane in entrance or picture), a
  continuous lane down the gallery, polish on the handrails people hold, and dark grime in the
  corners and along the skirting.
- The balance is off: dark caused marks (bar-foot grime, soot) are near invisible while a couple
  of pale patches are the brightest things on the floor.

**Closer to the painting?** Slightly, in two views: stair_close (the worn treads) and the table
rings in entrance and picture give the floor some history the plain images lack. But overall the
worn images are not yet much closer to the painting's lived-in feel. At this exposure most marks
can't be seen, and the ones that can read either as light pools or as texture faults. The
painting's lived-in look comes from broad, soft variation: lighter, sheened traffic lanes, dark
corners and joints, glossy hand-worn edges. That needs softer, larger and more continuous wear
with gloss, plus stronger dark grime where things collect.
