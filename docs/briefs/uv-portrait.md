# Brief: the UV portrait (the characters session)

Sean, 2026-10-13. Replaces the portrait factory's pipeline (`portrait-factory.md`): its rounds
gave mud skin (one brown ramp), a deformed face (crushed brow, blocky jaw) and smooth facets,
not the painting's mosaic. Branch `claude/characters-uv-portrait`, from
`claude/characters-portrait-factory`. The bold cowboy first.

## Fixed

- No camera projection of pictures onto the face, no blending of views, no landmark solver.
- Squares ~8 mm on the face (the world's size; the painting's man is ~20 across his face).
- The game's smooth light; every square its own shade, real hue changes across the face
  (peach-cream lit skin; red nose, ears, cheeks; blue-grey stubble; olive-grey shadow). No
  stepped bands, no 4-6 colour palettes.
- Our 17 bones, drawn eyes within 1.5 cm of the anatomy's, a sensible triangle budget.

## The route

1. **Shape:** a fresh Rodin bust from his four plain views ($1.60); the shared MakeHuman head
   placed on it by one similarity transform (7 numbers), then shrinkwrapped to its surface, a
   corrective smooth keeping the eye openings, lips and nostrils. Checkpoint: untextured, beside
   his plain front and profile, his outline over the profile.
2. **Layout:** the face one patch by a front-on orthographic projection (only where the surface
   turns < ~60° away, so stretch ≤ ~2×), seams at the hairline, sideburns and under the jaw;
   sides, ears and back their own patches, each as seen from its own side. Checkpoint: a checker
   on the head and the face patch flat.
3. **Paint:** each patch painted once by FLUX + the style LoRA on fal, image-to-image from an
   evenly lit grey render of the head in that patch's layout, depth ControlNet from the same
   layout; the bold portraits as the look. The guide's known light divided back out; creases
   keep a little olive-grey as colour. Seams matched in low-frequency colour only. Checkpoint:
   the painted face.
4. **Squares once at 8 mm** in each patch's grid: the median per cell, then edge-preserving
   smoothing across cells and lone-square removal, so neighbours form shapes.
5. **Clothes:** collar, tie, lapels as separate simple pieces with strip UVs.
6. **Test only:** a hard-faceted ~800-triangle head with the same paint, beside the smooth one.

Each checkpoint: a crop beside his bold portrait at 3×, neutral light and the saloon; wait for
Sean.

## Spend (up to $15 without asking)

| When | What | Why | Cost |
|---|---|---|---|
| 2026-10-13 | Rodin Gen-2.5 bust, bold cowboy (People workflow, `style: rodin`) | the shape (Sean: fresh, not run 61's) | $1.60 |
| 2026-10-13 | Paint round 1: 3 takes x 4 views on fal flux-general (LoRA, depth ControlNet; take c with his style portrait as IP-Adapter reference), People workflow `style: uvpaint` | step 3, the painted face; which settings read best | $0: refused, fal's balance exhausted (run 65); to run again on a top-up (~$0.90) |
| 2026-10-13 | Paint round 1, first try (run 66): 8 pictures made (takes a, b), lost: take c's IP-Adapter failed inside fal and stopped the job before its commit | | ~$0.60, lost |
| 2026-10-13 | Paint round 1 again (run 67): 12 pictures, all made (depth ControlNet by the union model; the IP-Adapter worked) | the same | ~$0.90 |

Total so far: ~$3.10 of $15.
