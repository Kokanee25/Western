# Worn round 3: blind critic

I looked only at the ten renders and the painting (`build/bl/refs/picture.png`). I made every pick by eye
on brightened crops (x1.8 to x3.2) before computing any difference map. I used the difference maps
afterwards only to confirm the picks and to find small marks I had missed. Those marks are labelled
"(found on the map)", and each was then checked by eye. Crop boxes are in the marked image's pixels
(1280x720).

## Picks

| View | Marked | By eye | Strength |
|---|---|---|---|
| entrance | **B** | probably | too faint at this distance (the floor patches show only once brightened) |
| picture | **A** | sure | about right |
| stair_close | **A** | probably | too faint, apart from one hard-edged patch on the newel |
| bar_floor | **A** | sure | about right in strength, too hard-edged |
| gallery_close | **B** | sure | about right in strength, too blotchy in pattern |

## entrance: B (probably)

At full frame the two images look the same. Once brightened, B's floor has lighter, scuffed patches
with stepped edges where the plain A is even.

| Mark | Box | Reads as |
|---|---|---|
| Lighter worn floor round the left card table, running down the left of the big post toward the camera (a path from the door to the table) | [200, 580, 300, 715], [0, 630, 100, 675] | CAUSED: chairs pushed back and feet at the table. Its edges step in blocks. |
| Lighter floor under the far tables and chairs | [410, 480, 710, 540] | CAUSED: chairs scraping. Hard to see at this distance. |
| Lighter floor at the bottom right, in front of the bar posts | [1100, 590, 1280, 715] | CAUSED: standing room at the bar. In the lamp-lit corner the patch's curved, dark-bordered edge could pass for a shadow. |
| A darker strip on the floor along the foot of the bar | [960, 470, 1280, 585] | CAUSED: dirt kicked against the bar. It is right, but you only see it on a brightened crop. |
| Soot above the wall lamps (found on the map) | [540, 180, 590, 225], [715, 180, 765, 225] | CAUSED in principle, but I could not see it: the lamps' glow covers it. |
| Left table's felt rim slightly brighter (found on the map) | [16, 480, 224, 528] | CAUSED (hands on the rim). I could not see it. |

**Strength: too faint.** In a wide shot of a dark room the marks are lost. Only the patch by the left
table registers without brightening.

## picture: A (sure)

| Mark | Box | Reads as |
|---|---|---|
| Light scuffed patches on the floor under each chair at the near table | [800, 570, 930, 625], [1100, 590, 1235, 650], [780, 500, 850, 535], [975, 515, 1040, 545] | CAUSED: exactly where chair legs scrape back and forth. The most convincing marks in the set, though the patches are flat-toned with stepped edges, closer to decals than to worn grain. |
| Light patch at the bottom right edge, beside the railing post | [1165, 695, 1280, 720] | CAUSED (the same chair traffic). Cut off by the frame. |
| Darker band at the foot of the bar | [288, 418, 770, 448] | CAUSED. Faint, but it does seat the bar on the floor. |
| Felt rim of the near table slightly lighter (found on the map) | [888, 410, 1088, 450] | CAUSED. I could not see it by eye. |
| Bench seat by the left wall slightly lighter, and dirt at the foot of that wall (found on the map) | [189, 370, 222, 422], [80, 454, 176, 486] | CAUSED. Barely visible. |
| Soot above the three wall lamps (found on the map) | [280, 215, 320, 260], [775, 255, 815, 300], [960, 225, 1000, 270] | CAUSED in principle; I could not see it next to the glow. |
| A lighter lane down the middle of the floor toward the bar | [300, 470, 720, 720] | Possibly CAUSED (a traffic lane), but too subtle to separate from the lamp light. |

**Strength: about right** for the chair scuffs. The rest is too faint to count.

## stair_close: A (probably)

| Mark | Box | Reads as |
|---|---|---|
| Newel post: a hard-edged rectangle of a different tone on its face, with a stepped corner, part way down the post | [236, 405, 320, 505] | The polish is CAUSED (hands grab the newel), but the patch reads as a **rendering bug**: a crisp rectangular seam across the post instead of a soft polish fading from the cap. It is also low on the post, not at the cap where the hand goes. |
| A lighter scuff on the bottom tread, behind the newel | [320, 585, 362, 642] | CAUSED (the first tread takes the most feet). Small and blocky. |
| Handrail slightly brighter and glossier along its length | [384, 10, 720, 240] | CAUSED (hand polish). Too faint to notice without a side-by-side. |
| Scattered lighter bits on the treads behind the balusters (found on the map) | [448, 420, 480, 455], [608, 268, 672, 302] | Unclear: too small and broken up to read as tread wear. Close to DECORATION. |
| Darker floor at the foot of the back wall (found on the map) | [576, 445, 864, 478] | CAUSED. Invisible by eye. |
| Soot above the wall lamp (found on the map) | [955, 140, 1005, 200] | I could not see it next to the glow. |

**Strength: too faint**, apart from the newel patch, whose edge is the most noticeable thing in the
pair and the wrong way to get noticed. The stair is where use should show most (dished, pale tread
centres and a dark, polished rail), and here it hardly shows.

(In both A and B there is also a white dashed line along the top edge of the wainscot panel at the
left, around [0, 380, 175, 450]. It is not part of the marks, but it is a rendering bug.)

## bar_floor: A (sure)

| Mark | Box | Reads as |
|---|---|---|
| A large pale worn patch on the floor in front of the bar, right of the post | [950, 545, 1280, 715] | CAUSED: where drinkers stand. This is the right idea and the right place. But its outline is a jagged staircase of square texels, much coarser than the boards' grain, and its tone is flat. It reads as a pasted mask more than as feet. |
| A darker stain inside that worn patch | [1090, 645, 1150, 692] | CAUSED (a spill or tobacco juice by the bar). It works. |
| Darker floor right along the foot of the bar | [730, 385, 1280, 530] | CAUSED (dirt swept against the kick). Good, and visible. |
| The big foreground post/wall darker and mottled in large blocks | [0, 0, 465, 720] | Mostly reads as darker wood rather than grime. On the map its edges are large rectangles (DECORATION, or a mask-tiling bug). By eye it is just "a bit darker". |

**Strength: about right** in contrast; if anything the worn patch is slightly overdone, because the
hard, pixel-stepped edge draws the eye.

## gallery_close: B (sure)

| Mark | Box | Reads as |
|---|---|---|
| Pale worn patches down the middle of the gallery walkway | [465, 300, 865, 718] | CAUSED in where it is (the walking line between the wall and the railing). Its pattern, though, is camouflage-like islands of pale and dark with stepped edges, not a continuous lane worn soft down the boards' centres. Halfway to DECORATION. |
| The floor below, seen through the balusters, lighter under the table's chairs | [1070, 500, 1280, 718] | CAUSED. Barely visible. |
| Soot above the wall lamp (found on the map) | [1020, 70, 1080, 130] | I could not see it. |

**Strength: about right** in contrast; the shape of the pattern is the problem.

## Overall

**Most convincing**
1. picture: the scuffs under each chair at the near table [800, 570, 1235, 650]. Exactly where chairs move, and they make the table look used.
2. bar_floor: the dark strip along the bar's foot, with the stain in front [730, 385, 1280, 530], [1090, 645, 1150, 692]. It seats the bar and suggests spit and spills.
3. entrance: the worn floor round the left card table and down to the door [200, 580, 300, 715]. It suggests traffic.

**Least convincing**
1. stair_close: the newel post's hard rectangular patch with a stepped corner [236, 405, 320, 505]. It reads as a seam or bug, and it sits too low for a hand.
2. bar_floor: the outline of the worn patch in front of the bar [950, 545, 1280, 715]. Right place, but a jagged block outline coarser than the planks.
3. gallery_close: the camouflage islands on the walkway [465, 300, 865, 718]. Uneven blotches rather than a lane worn down the middle. (A close fourth: soot above the lamps, which is invisible in every view because the lamp's own glow covers it.)

**Common faults.** Every patch has a flat tone and stair-stepped edges at a coarser grid than the wood
it sits on, so wear looks laid on top rather than worn in. Polish (the rail, the rims, the newel) is
nearly invisible. Soot never shows. The stair, where use should be strongest, shows the least.

**Against the painting.** Slightly closer, not much. The painting's lived-in feel comes from planks of
uneven tone with pale, scuffed lanes through the room and round the tables, and from dark corners and
a dark foot along the bar. The chair scuffs, the dark bar foot and the traffic patches move the worn
images toward that, and the picture and bar_floor views are the clearest gains. But in the wide views
(entrance, picture) the marks mostly disappear at this light. The painting's wear is soft and runs
along the boards, while these patches are hard-edged blocks. A viewer would say the worn rooms are "a
bit scuffed", not "a room men have drunk in for twenty years".

**Suggestions:** soften and dither the patch edges along the boards' grain, not on a square grid; make
a single lane on the gallery rather than islands; put the polish on the newel's cap and the rail's
top, brighter and glossier; move the soot higher and wider than the lamp's glow; and push the wear
harder in the wide shots (entrance), where it currently vanishes.
