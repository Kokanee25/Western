# Blind critic, material lab round 3 (2026-10-21)

A fresh agent, the Studio men's sheet and the 32 crops in `critic_round3/` (golden hour, a man in front of each wood: round 2 clean, round 2 weathered per board, round 3's weathering layer with the free stand-in sheet and with the painted sheet; shuffled, unlabelled), asked of each: "Do the man and the wood look like the same painting? What gives it away?"

An earlier critic pass on the same crops was set aside: the per-board set had been rendered while a debug shader was on disk (magenta lines on three crops). Before setting it aside it named the round 3 stains' stepped tones as "tide marks" and "stamped" over the seams, so round 3b (what's judged here) lays them smooth and a touch different on each board.

## Unblinded

| Wood | Round 2 clean (studio5) | Round 2 weathered per board (studio5w) | Round 3 layer, free sheet (studio6) | Round 3 layer, painted sheet (studio6p) |
|---|---|---|---|---|
| store_boards | 16 CLOSE | 14 CLOSE | 09 SAME | 15 SAME |
| floor | 02 CLOSE | 07 CLOSE | 01 CLOSE | 30 CLOSE |
| weathered_pine | 05 DIFFERENT | 26 DIFFERENT | 31 SAME | 21 CLOSE |
| framing | 08 CLOSE | 12 DIFFERENT | 18 DIFFERENT | 17 CLOSE |
| dark_trim | 23 DIFFERENT | 22 DIFFERENT | 20 CLOSE | 24 DIFFERENT |
| timber | 04 DIFFERENT | 28 DIFFERENT | 25 CLOSE | 19 CLOSE |
| saloon_red | 29 DIFFERENT | 06 DIFFERENT | 11 CLOSE | 32 CLOSE |
| fascia | 03 CLOSE | 13 CLOSE | 10 CLOSE | 27 CLOSE |

Round 2 clean 0 / 4 / 4; Round 2 weathered per board 0 / 3 / 5; Round 3 layer, free sheet 2 / 5 / 1; Round 3 layer, painted sheet 1 / 6 / 1 (SAME / CLOSE / DIFFERENT, eight woods each).

## The critic's answer

Reference: `docs/concept/targets/9_studio_men.png`. The men are painted in broad, flat value bands with hard edges, such as the face planes and sleeves. Their stains are darker, irregular and soft-edged, and follow the cloth (the brown vest, the tan vest). There is very little fine detail.

| Crop | Verdict | What gives it away |
|---|---|---|
| 01 | CLOSE | The dark deck sits well with the pinstripe trousers, but its grain lines, knots and hairline cracks are crisp and photographic next to the man's flat bands. |
| 02 | CLOSE | The same as 01. Pale, bleached streaks on the back wall and rail add a white-hot edge the man never has. |
| 03 | CLOSE | Smooth, broad gradients on the steps suit the painted cloth, but the wood looks lacquered (varnish sheen, airbrushed dark knot blots), not painted. |
| 04 | DIFFERENT | The wall is candy-striped: near-white boards next to deep red ones. The post's vertical cracks are photo-sharp. The man's shadow is a soft, blurred ghost. |
| 05 | DIFFERENT | Pale cream and dark brown boards in stark stripes, with a crisp knot and white streaks. The wall is louder and busier than either man. |
| 06 | DIFFERENT | The stripes are more saturated red than in 05. The board-to-board value jumps are far wider than anything on the men. |
| 07 | CLOSE | The same deck as 01. The value range matches, but the crisp grain and cracks don't. |
| 08 | CLOSE | The wall's tones are near the old man's vest, but its pale, streaky boards are stripier than his banded sleeve. |
| 09 | SAME | An even, warm tan wall with soft grain at the same value as the shirt and vest. Only the stair-stepped shadow edge breaks it. |
| 10 | CLOSE | The steps are smooth and broad, but there is a large, blurry, airbrushed dark smudge on the beam and a varnish sheen. |
| 11 | CLOSE | Like 09, but faint pale blotches at the lower right read as light spill, not dirt. |
| 12 | DIFFERENT | The wall is covered in pale, round, soft blobs that read as dappled leaf-light or clouds, not stains. The man's vest stains are darker. |
| 13 | CLOSE | The same steps as 03. They are smooth and quiet, but the polished sheen and soft knot blots read as furniture. |
| 14 | CLOSE | The dark upper boards suit the men. The pale, streaky lower boards are stripier and more bleached. |
| 15 | SAME | Quiet, warm tan boards with soft grain. The wall's value and chroma match the shirt and vest. |
| 16 | CLOSE | Mostly like 15, but repeated pale round blobs at the lower right look stamped. |
| 17 | CLOSE | The wall's warmth matches the vest. The lower boards' pale blob stains look like dappled light or a stamp. |
| 18 | DIFFERENT | The same view as 17, with more and larger pale cauliflower blobs repeated along each board. The weathering reads as a pattern, not dirt. |
| 19 | CLOSE | A darker, more muted wall that sits with both men. The post's crack detail and the soft, blurred cast shadow are still unlike them. |
| 20 | CLOSE | The wall and the post in shade are broad and dark, near the face's banding. A fine sandy speckle on the post shows in its lit edge. |
| 21 | CLOSE | A warm, mid-dark wall that suits the men. One crisp knot and some streaks are sharper than anything on them. |
| 22 | DIFFERENT | The post has a fine sandy, photographic speckle. The wall alternates near-white and red boards behind a face painted in a few flat planes. |
| 23 | DIFFERENT | The same as 22: speckled post, striped wall, and a weathered grey plank fence at the left with photo grain. |
| 24 | DIFFERENT | The same as 22 and 23. The post's noise texture and the wall's stripes are the giveaways. |
| 25 | CLOSE | Like 19: a muted wall that sits with the men. The post's cracks and the soft-blurred shadow are still off. |
| 26 | DIFFERENT | Bleached white streaks and a crisp, dark knot. The pale boards are lighter than the white shirt. |
| 27 | CLOSE | The same steps as 03 and 13: smooth and quiet but polished. The airbrushed knot blots don't match the men's stains. |
| 28 | DIFFERENT | Like 04: a strongly striped wall, a photo-cracked post, and a soft ghost shadow. |
| 29 | DIFFERENT | The loudest wall: white-cream boards against dark red, crisp knots and grain. It outshouts both men. |
| 30 | CLOSE | The same as 02: the deck sits well, but the bleached streaks on the back wall and rail and the crisp grain don't. |
| 31 | SAME | An even, warm wall with soft grain and one knot, matching the men's value and chroma. This is the best match. |
| 32 | CLOSE | Like 31, but pale round stamp-like blobs at the lower right read as light, not dirt. |

## The five biggest differences

1. **Board-to-board stripes with too wide a value range.** Near-white, bleached boards sit next to deep red-brown ones. The men never go that light or that contrasty within one material, so the wall outshouts them. This shows most in 29, 05, 06, 04, 28, 22 and 26.
2. **The weathering reads as light, not dirt.** The stains are pale, soft, round blobs, repeated board after board like a stamp, and look like dappled leaf-light or cloud shadows. The men's stains (the brown vest, the tan vest's patches) are darker than the cloth, irregular and follow the form. This shows most in 18, 12, 17, 32 and 16.
3. **Fine photographic detail against broad painted bands.** The wood has crisp grain lines, sharp knots, hairline cracks, vertical checks on the posts and a fine sandy speckle on the lit post. The men are a few flat planes with almost no small detail. This shows most in 22, 23, 24 and 20 (the post speckle), 04 and 28 (the post's cracks), 01 and 07 (the deck's grain) and 05 and 29 (the knots).
4. **Smooth, lacquered gradients against hard-edged value bands.** The men are posterised into hard-edged bands, such as the old man's sleeve and the young man's face. The steps and beams are continuous gradients with a varnish sheen and blurry, airbrushed dark blots, so they look like polished furniture rather than painted wood. This shows most in 10, 03, 13 and 27, against 08, 12 and 17 for the men.
5. **The cast shadows are not painted either way.** On the wall, the men's shadows are either soft, blurred ghosts (04, 19, 25, 28) or jagged, pixel-stepped silhouettes (09, 15, 31, 21). The shadow block on the vested man's right sleeve is a stepped rectangle. Neither matches the men's clean, hard-edged shade bands, and the wall's lit areas have no banding at all.

## Best and worst

- **Best:** 31, 09 and 15 (a quiet, even, warm tan wall at the men's value), then 19 and 25 (a muted, darker wall).
- **Worst:** 29 and 05 (stark white-red stripes with crisp knots), 18 (repeated pale blob stamps), and 22 and 26 (a speckled post or bleached streaks behind a face painted in a few flat planes).
