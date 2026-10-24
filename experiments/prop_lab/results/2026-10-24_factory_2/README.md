# The prop factory, batch 2: the street's soft stuff and the deer head (2026-10-24)

`docs/briefs/prop-factory.md`; modelled in Blender by `tools/blender/props/` (bpy 5.0.1), drawn on
kit members (`"draw": {"shape": "mesh"}`); tests `tests/test_prop_factory.gd`, `tests/test_wall_props.gd`.

- `sheet_round1.jpg` (what the critic saw; `straw_pile_final.jpg` after the fix): hay bale, straw heap, feed sack, grain sacks, droppings at noon and 21:30;
  `deer_sheet_round1.jpg` (`deer_sheet.jpg` after the fix): the mount on the saloon's back wall, noon, night, night from the side.
- `critic.md`: hay bale, feed sack, grain sacks, droppings, deer head CLOSE; straw heap DOESN'T (a
  smooth sheet). Fixed after it: the heap made of ragged clumps with three times the stalks; the
  deer's neck closed where the head leaves it (it read hollow from the side) and the head rounder
  (16 sides). Straw and burlap darkened (they read new).
- Left for the next round: sacks that slump and sag into each other, seams and weave (the painted
  burlap), bristly bale faces, the street's dust on everything at ground level, the antlers' roughness.

## The deer painted (Sean, 2026-10-24: "get a paint session done on it")

`deer_painted.jpg` (noon, night, night from the side): `prop_hide`, `prop_hide_dark`,
`prop_hide_pale` and `prop_antler` painted in the men's hand (People run 124, $0.88), with a
whitetail's white throat patch and chin modelled (the saloon painting's mount). The cut tuned
locally from the paintings (no new calls): at 256-512 a metre the painted hair read as cork, so the
hide is cut at the world's 128 a metre with its contrast down; the antler's furrows quietened; the
nose (the model painted a whole nose) darkened and muted. A full ring round the muzzle read as a
pig's snout: gone.

## The rest painted (Sean on #351: "yes keep going")

`painted_sheet.jpg`: `prop_canvas`, `prop_burlap`, `prop_straw`, `prop_leather`, `prop_dung` painted
(People run 125, $1.10), cut at the world's 128 a metre. Two came out wrong and were muted in the
cut, no repaint: the leather painted as a spotted cowhide (contrast 0.3: worn mottling; the horses'
saddles share it), the burlap with a whole stencil stamp (contrast 0.25: the weave). A repaint of
either is $0.22 if Sean wants them truer.
