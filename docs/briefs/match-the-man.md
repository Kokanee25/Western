# Brief: the world painted in the man's hand

Sean, 2026-10-16: "Here is an image of our actual in game model - we need to figure out how we take
the rest of the art to match him", then "go ahead with the $6".

## Goal

The town looks made by the same hand as the layered cowboy (`docs/concept/targets/8_man_model.png`,
`bold_cowboy_layered`): painted, not photographed; detail at one scale (broad brush mottling on
cloth, finer on the face, no fine noisy grain); soft even light; a narrow warm earthy palette at
modest saturation. Painted illustration (DESIGN.md §4).

## References

- Target 8, the man's model sheet: the yardstick.
- The painted references the judge uses (`docs/concept/*-painted.png`) for the light and mood.
- Today's world: woods are the procedural C grain (`tools/textures/grain_woods.py`, fine and
  photo-like); 18 painted materials (`tools/textures/materials.json`); props in code with flat
  colours (`src/props/prop_models.gd`).

## Steps

1. **The match views**: the man in the town's light beside its surfaces. `man_store_golden` (on
   the street before the general store's boards at 17.6) and `man_saloon_night` (standing in the
   saloon at night). The gap is seen and measured there.
2. **One test wood** (`store_boards`): its ten boards and bare strip stacked and repainted by the
   image model with the man's sheet as the style reference, cut back into the same strips
   (seamless along the length), read by the game as before. Shown to Sean beside the man before
   the rest. (`tools/textures/paint_woods.py`.)
3. **The rest**: every wood, then the 18 painted materials, the same way; then one palette pass
   so the road and walls sit inside his range (saturation, value).
4. **Props seen close** (table, chair, lamp, bottle, glass): painted textures the same way.
5. Not this brief: the other townsmen to his standard (characters' 1.3).

## Budget

~$6 (Sean, 2026-10-16), FLUX.2 [max] via the People workflow; each call's cost logged.

## Done when

In the match views the walls, floor, road and props read as painted by the same hand as the man:
the blind critic, given target 8 and the views, no longer lists the surfaces' finish or palette
among the five biggest differences; goldens re-approved; the frame budget unchanged (textures only).
