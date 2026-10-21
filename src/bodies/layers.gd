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
## Physics: the hat a man's wearing (HumanBody.hat_body): bullets hit it and take it off;
## nothing else looks for it.
const HATS := 32
## Physics: a limp man's parts, on BODY_PARTS too (bullets hit them): they collide with each
## other and with other limp men, so a fallen man's arm lands on his chest, not in it. A standing
## man's hitboxes aren't on it, so a body can be dragged and walked past as before.
const RAGDOLL := 64
## Physics: a surface only for walking on, where the real thing is steps no walker could climb
## (the saloon stair's ramp under its treads). The player and people stand and walk on it; a
## falling man, debris, a hat, a ball, a blast and sight pass through it to the treads themselves.
const WALK := 128
## What a walker stands on: the world and the walking ramps.
const STAND := WORLD | WALK
## Everything a bullet can hit.
const BULLETS := 0xFFFFFFFF & ~PEOPLE & ~WALK

## Render: people's skin and clothes (wound and blood decals paint only these).
const VIS_BODY := 2
## Render: what's inside a body, seen through a wound (decals don't paint it).
const VIS_INSIDE := 4
## Render: what's in your hands (guns, your hand and sleeve, a stick of dynamite), on the world's
## layer too: its own fill light reaches only this (WeaponViewmodel).
const VIS_HELD := 8
## Render: what a far lamp's shadow is cast by (OilLamp): each structure's shadow mesh (on this
## alone) and its members' own meshes (on this and 1). The sun, the moon and near lamps leave the
## shadow meshes out (`ALL_BUT_WALLS`): theirs is cast by the batches, as before.
const VIS_WALLS := 16
const ALL_BUT_WALLS := 0xFFFFFFFF & ~VIS_WALLS
## Render: dust and smoke in the air, off the world's layer so the ground's decals (a blast's scorch)
## don't paint it; cameras and lights see it as any other.
const VIS_AIR := 32
