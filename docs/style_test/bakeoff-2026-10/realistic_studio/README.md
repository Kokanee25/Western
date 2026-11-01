# The character bake-off, route A: the Studio from realistic pictures (#516, #518)

**Sean's verdict (2026-11-01): "He looks horrible next to our original bold cowboy." Not the
direction.** Seen as Rodin's raw model (`rodin_raw.jpg`, a quick Blender preview); not taken into
the game.

## What was made ($3.35: pictures $1.75, Rodin $1.60; the Studio at $71.32 of $75 with the bake-off branch)

- **Pictures** (`pictures_v2.jpg`): the bold cowboy's own card as a realistic photograph, his
  painted arms-out front as the reference (Studio `styles/realistic.yaml`, GPT-5.4). The first side
  views drifted grey and curly; remade with "dark brown, no grey"; each scaled about its boots to
  the front's height (free). Sean approved the set.
- **Rodin** Gen-2.5, the same settings as every Studio man → build `bold_cowboy_real_s1` (Studio
  branch `claude/studio-realistic`, not merged): fitted to the 17 bones, 33,459 triangles.
- **`smooth_texels`** (this branch, off for everyone): the skin shader samples a man's texture
  bilinearly and lights him per pixel, not in texel squares, when his report says so. Made at
  Sean's ask ("can we turn that shader off"); no man uses it.

## Why he looks worse (the pipeline's limits, which the painted look hides)

- **The face gets ~350 px of one 2048 texture** that covers the whole man: fine for a painted
  face, far too little for a photographic one.
- **Rodin's shapes are soft where real people are sharp:** the ears melt into the hair (pale points
  either side of the head), the hair is one smooth shell, the lips and lids lose their edges.
- **The preview's own part:** Rodin's material read glossy in Blender (the "wet" hair and skin);
  the game draws him matte. That fixes the sheen, not the shapes.

So the answer to "was it the pipeline or the style?": realism exposes the pipeline's weakest part,
the face. Rodin stays good for painted men (bodies, clothes, a stylised face). A realistic face
would need a different source for the head (a proper base head, Human Generator), not Rodin.
