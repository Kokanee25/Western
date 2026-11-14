# Salt Creek: the "this looks cheap" judge's rubric

Sean, 2026-11-03 (#609, for #608 and every art merge after it). The art judge (`RUBRIC.md`) asks
"is this our painted look?"; the blind critic asks "how does this differ from the painting?". This
judge asks what a player asks in the first ten seconds: **"Does this look like a cheap indie or
AI-made game, and why?"**

It is a fresh, blind sub-agent (`python3 tools/critic.py cheap ...`). It sees only the renders, and
the concept targets for the one question that needs them (the verdict's top end). It has not seen
the code, the briefs or anyone's reasoning. Its pictures are named a, b, c... so a filename can't
give a render away.

**Realistic, in Red Dead's direction (Sean, 2026-11-04; DESIGN.md §4).** The game now aims at a
realistic look in the direction of Red Dead Redemption 2: real materials, light with shape, air,
wear. Red Dead is the compass, not the bar ("not that level, just that direction"), so judge
whether it looks *made with care*, not whether it is photorealistic or as rich as a AAA game:
a smaller game's honest realism with care in it is good indie or better. Leftover squares,
posterised colour or a painted, toy-like finish are now part of what reads as cheap. (Until
2026-11-04 the game was a painted illustration with a bit of square, and that style was not a tell.)

## The tells (each PASS / FAIL / N/A, with a crop as evidence)

PASS means the tell is **not** there (the picture is fine on this count). FAIL means a player would
notice it. N/A when the picture can't show it (a still can't show stiff people; an interior has no
horizon). Every FAIL names a crop.

1. **Flat light:** even fill everywhere; no real shadow shapes; the blacks lifted to grey; you
   can't say where the light comes from.
2. **No atmosphere:** the distance as sharp and saturated as the foreground; no haze, dust or
   smoke catching the light; indoors, no air in the lamplight.
3. **Too clean:** no dirt where things meet the ground; no wear on edges, corners or treads;
   materials uniform from one end of a wall to the other.
4. **Too straight:** perfect lines, levels and spacing; nothing sags, leans, warps or varies.
5. **Floating objects:** no contact darkening or shadow where props, feet, posts and walls meet
   the ground or each other.
6. **Repetition:** the same texture tile, prop, light fixture or person visibly repeated.
7. **Empty:** spaces with nothing in them to say anyone lives or works there.
8. **Scale tells:** doors, steps, props or people the wrong size for each other.
9. **Edges of the world:** a visible backdrop seam, pop-in, a flat or empty horizon, a wall
   standing alone with nothing behind it.
10. **Stiff people** (from a film strip, not a still; N/A on stills): robotic or mirrored poses,
    feet sliding over the ground, no weight shifting, everyone moving in step.

## The verdict (one per picture), on this fixed scale

| verdict | what a player would say |
|---|---|
| **AI slop** | "Generated." Melted or meaningless detail, nothing holds together, no one designed it. |
| **cheap indie** | "Asset flip / student project." Flat light, clean, empty, the tells all over it. |
| **good indie** | "Small team with taste." A clear look, a few tells, cared-for where it counts. |
| **AA** | "A real studio's game." Light with shape, air, wear and life; tells only if you hunt. |
| **AAA-feeling** | "Expensive." Every corner reads as made and lived in; the light tells a story. |

The top of the scale is the concept targets (`docs/concept/targets/*_target.jpg`) and this text,
and, when the judge is run with them, official screenshots of shipped AAA games as a yardstick for
"AA" and "AAA-feeling": a yardstick for care (light with shape, air, wear, dressing, life), not for
style. They are shown only from the private Character Studio (`--refs`), read where they are, and
**never stored in this repo**, not even as a crop (it is public: CLAUDE.md's licence rule); crops
are of the game's own pictures only.

## The five biggest reasons (one list per picture)

Ranked, biggest first. Each: the tell's number, a box (`x y w h` in the picture's pixels), what a
player sees, the **cause** (light | material | geometry | dressing | people | camera) and the
**cheapest fix** (one thing to try, the smallest change that would move a player's opinion).
