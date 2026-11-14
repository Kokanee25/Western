# The drag smear painted, 2026-10-28 (#439)

Sean's $4 for paint: run 129 (People workflow, `textures = blood:smears`), Gemini, **$0.14**.
`painted_sheet.jpg` is what came back (four swipes top to bottom, `assets/textures/raw/blood/smears.jpg`);
`tools/textures/smear_band.py --painted` cuts it into the pieces WoundSigns lays (start from one
swipe's top, end from another's bottom, three bands from their middles, every piece eased to one
seam row so any two join; recoloured to the splats' reds by darkness, alpha in three steps).

- `pieces_generated_vs_painted.png`: start, five bands, end laid end to end; generated above, painted below.
- `generated_vs_painted.jpg`: the same drags in the game, generated left, painted right: the saloon
  along and from above, the street. `q1-3.jpg`: the painted ones full size.

In the saloon the painted one reads as heavy wet blood; on the street's pale dirt it's a bright
red and, like the generated one, shows its pieces where the drag kinks.
