class_name Layers
## Physics and render layers, in one place.

## Physics: the world (ground, buildings, props, the player).
const WORLD := 1
## Physics: body-part hitboxes and ragdoll pieces. Bullets hit them; the player walks through.
const BODY_PARTS := 4
## Physics: the capsule that keeps a living person solid to walk into. Bullets ignore it.
const PEOPLE := 8
## Everything a bullet can hit.
const BULLETS := 0xFFFFFFFF & ~PEOPLE

## Render: people's skin and clothes (wound and blood decals paint only these).
const VIS_BODY := 2
