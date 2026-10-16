# The targets (roadmap step 1.1, 2026-10-15)

The pictures the game is judged against, one per subject, each beside a render of the game made
today (build 1150, the woods merge: `docs/screenshots/golden/`). `*_target.jpg` is the target,
`*_render.jpg` the game, `*_sheet.jpg` both side by side. The three gaps under each were written
by a fresh agent that saw only the sheets (as the blind critic does), biggest first, then
trimmed of what's only a different shot.

Sources: the saloon and street paintings are `docs/concept/saloon-night.png` and
`street-golden-hour.png` (the judge's two shots). The man is Sean's painterly portrait
(`docs/concept/style/portrait-painterly-front.png` on `claude/characters-portrait-factory`,
2026-10-15: "that's fucking it"). The wall and post are the approved grounded-3D saloon exterior
(Sean's material reference pack, 2026-10-14; the whole picture is `4_wall_and_post_target_whole.jpg`).
The prop is `docs/concept/style/prop-lamp-card-table.png`.

Changing a target is Sean's call; a gap closes when a new render beside it no longer shows it.

Since 2026-10-16 the judge and the blind critic compare against the paintings redrawn in the
painted-illustration look (DESIGN.md §4; Sean chose street C): `docs/concept/street-golden-hour-painted.png`
(the old shot under his sky and on his road), `saloon-painted.png`, `livery-fire-painted.png`, painted
by `tools/textures/paint_reference.py` (`references.json`; the tries in `assets/textures/raw/ref_*`,
sheet `docs/screenshots/sky/references_new.jpg`). The squared originals stay for history.

## 1. A man close at a table

Render: `shot_match_close`.
1. **His face is a painted mask.** It is flat orange blocks with hard dark outlines round the
   eyes, nose and jaw. The portrait is modelled: soft warm light across cheekbones and brow,
   cool shadow under the jaw. The skin needs less saturation, light that grades across it, and
   two or three values to a plane. (Step 1.2, the characters session's painted-light brief.)
2. **His collar and tie are a jagged mess of white blocks.** The portrait has a crisp white
   collar and a black tie over a dark vest. (His hat hides the portrait's hair and brow. That's
   by design; the hat is step 1.3's.)
3. **The room behind him doesn't glow.** It is dim and brown, with almost no bright lamps. The
   portrait is lit by warm lamps with bright cores and soft halos, against a cool blue window.

## 2. The saloon at night

Render: `shot_match_saloon`.
1. **The standing men read as mannequins.** They stand stiff with their arms at their sides,
   are lit flat, and wear too-bright clean clothes (white sleeves, a saturated red vest). The
   painting's figures are dark against the lamplight and posed: leaning on the bar, seated, at
   the piano.
2. **There are no pools of light.** The room is an even mid-brown with few bright points and no
   deep darks. The painting has many lamps, each warming its own wood, black shadows between
   them and haze toward the back.
3. **The back of the room is flat.** Through the door there's a blue-grey plane under the moon,
   not a lit street. The back bar is a brown slab with bottles, not a carved back bar with a
   mirror and gilt catching the light.

## 3. The street at golden hour

Render: `shot_match_street`.
1. **The road is loud, even static to the horizon.** It's a checkerboard of orange squares at
   one size and contrast. The painting's dirt has ruts and paths, finer detail with distance,
   and long raking shadows.
2. **The light is heavy and brown.** The sky is orange-brown with dark slate clouds, and the
   fronts are evenly dim. The painting has a clean blue upper sky fading to gold at the sun,
   white-gold cloud edges and sun rays, and fronts lit warm on their sunward faces with crisp
   shadows.
3. **The street is underdressed.** It has no water tower, windmill, wagons, barrels, hay or
   people. The fronts are dark plain boxes, where the painting's are weathered grey-white boards
   with painted signs and trim.

## 4. A wall and a post up close

Render: `texel_porch`. This is the nearest fixed view; a saloon-porch close-up at golden hour is
wanted as a fixed view of its own (step 1.4).
1. **Wrong light for the target.** The render is flat, cool daylight on pale boards. The target
   is in warm low sun, with deep red siding, hot rim light on the posts and dark shade under the
   balcony. (Partly the view's hour; it still holds at golden hour, see the lab's sheets.)
2. **The foreground is bright and loose.** The ground is a near-white checkerboard with big dark
   and gold grass blades like cutouts. The target has a solid boardwalk, a hitching rail and
   crates.
3. **The construction is plain.** The posts look askew and the beams overhead are plain
   sticks. The target has square upright posts with carved knee braces and caps, a balustrade,
   lit windows and glowing lanterns. (The built boardwalk is in `docs/BACKLOG.md`.)

## 5. A prop: the lamp on the card table

Render: a crop of `shot_match_saloon`.
1. **The lamp's base reads as plastic.** It is a smooth faceted spool with banded flat shading.
   The target's is brass with a metallic sheen and the same squares as the rest. The chimney's
   glass and flame are close.
2. **The mug and bottle are smooth and untextured.** The bottle is a flat brown box with a pale
   stripe and a stray white highlight. The target has hammered pewter mugs and an amber bottle
   with a lit, stained label.
3. **The table is bare and evenly lit.** It is a wide smooth top with stretched streaks and
   three props, lit to its edges in front of a bright brown wall. The target's round worn top
   carries cards, chips, an ashtray and a cigar, with the light falling off into a dark room.

**Closest already:** the street's composition and the painted SALOON sign; the lamp's chimney
with its glowing flame.

## 6. The road (Sean, 2026-10-15)

`6_road_target.jpg`, added after step 1.4's first merge: "this is what it needs to look like now".
Deep wheel ruts with a sunlit ridge and a shadowed groove, solid stones each with a lit top and a
shadow, long raking light and dust haze down the street. Its boot prints are to come from people
walking (gameplay's, `docs/BACKLOG.md`), not painted into the road.
