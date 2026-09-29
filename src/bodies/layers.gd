class_name Layers
## Physics and render layers, in one place.

## Physics: the world (ground, buildings, props, the player).
const WORLD := 1
## Physics: body-part hitboxes and ragdoll pieces. Bullets hit them; the player walks through.
const BODY_PARTS := 4
## Physics: the capsule that keeps a living person solid to walk into. Bullets ignore it.
const PEOPLE := 8
## Physics: small loose things (spent brass, glass shards, tin cans, a dropped gun). They land on the
## world and on each other, bullets and falling timber hit them, but the player walks through them
## (a 12 g case spawned at the gun used to shove the player's capsule aside on every reload).
const DEBRIS := 16
## What debris collides with.
const DEBRIS_MASK := WORLD | DEBRIS
## Everything a bullet can hit.
const BULLETS := 0xFFFFFFFF & ~PEOPLE

## Render: people's skin and clothes (wound and blood decals paint only these).
const VIS_BODY := 2
## Render: what's inside a body, seen through a wound (decals don't paint it).
const VIS_INSIDE := 4
