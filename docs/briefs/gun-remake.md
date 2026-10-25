# The guns remade in the painted style (gun lab, gameplay; art judges)

Sean, 2026-10-23: "remake the shotgun and handgun so they look and match the art style - if you need
paid art rounds those are approved for $3".

## Goal

Both guns in your hands (the Colt-pattern revolver and the hammer coach gun, now with a pistol grip)
read as painted in the same hand as the Studio men (`docs/concept/targets/9_studio_men.png`): real
silhouettes (no boxes), the steel, case colours, walnut and brass painted, not code squares; every
moving part still its own piece (hammer, trigger, cylinder, gate, ejector; hammers, triggers, lever,
barrels on the hinge) and every node the hands, the viewmodels and the tests use still there.

## How

1. **Shapes in code** (`GunParts`): `profile` (an outline extruded across the gun with bevelled
   edges: frame, hammer, trigger, grip, lockplates, stock), `stroke` (a band along a line: trigger
   guards, backstrap), `turned` (a profile turned round an axis: barrels, cylinder, bead). Real
   proportions (a 7½" Single Action Army; a 20" coach gun).
2. **One painting a gun** (paid, `tools/textures/references.json`, `paint_reference.py` on GitHub):
   the new gun rendered from its right side, flat colour by material, orthographic (`views.gd
   --side`), sent as the base; the image model repaints it in the men's hand keeping the silhouette.
   About $0.22 a painting; a retake each at most: ~$0.90 of the $3.
3. **The painting projected from the side** onto every part (`GunParts.project_side`: UVs from each
   vertex's place in the gun at rest, so a moving part carries its own paint), one material a gun.
   Without a painting the factory materials stay (the game never breaks).

## Done when

- Both guns rebuilt and painted; the hands still fitted (`views.gd --fit`, `GAP`).
- A blind judge, given only the men's sheet and the old and new first-person sheets, finds the new
  guns CLOSE or SAME to the men's hand, the old DIFFERENT.
- Tests green, the goldens with a gun re-approved (art's files, said so), Sean's film.
