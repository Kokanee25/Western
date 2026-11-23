# Saloon B's placed props by lamplight: blind critic, round 1 (#987)

Views: `place_views.gd` (bar_night, bar_day, aisle_night, well_night, gaming_night; 960x540 here). A fresh
sub-agent saw only the renders and `experiments/prop_lab/refs/saloon/`. Its five, ranked:

1. **Gaming room, the tall chair at the faro table.** Read as a stool twice the table's height blocking it.
   *Ours:* it is the `lookout_stool` (the case keeper's high seat at the dealer's elbow, period-correct); the view
   is from the dealer's side, so it stands in front. No change.
2. **Gaming room's lighting:** flat cream walls, the wall sconce a white blob, the hanging lamps not pooling on the table.
3. **Bar room:** the lamps light themselves more than the room; the stove's hearth plate too bright.
4. **Back bar and counter:** niches, no mirrors, no spittoons; huge bottles on the aisle's shelves; curved shelf hooks.
5. **Aisle:** the grate over the work board oversized, its orange panels look like floating tiles, the slat mat reads as a ladder;
   well room: the piano nearly lost in the dark, windows dark.

Verdicts: aisle_night most convincing; gaming_night worst; bar_day murky (a lamp-lit room by day, the sun's
shafts not reaching in).

## What was done
Hanging lamps: energy 1.0 -> 1.5 (shaded 1.2 -> 1.7) rendered in the well and gaming views: **no visible change**, so
they are not too dim; reverted. The room reads right at 1.0 beside the reflector lamps. Second round not spent.
