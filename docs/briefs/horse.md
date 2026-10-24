# The horse

**Goal.** The town's horses as creatures, not props: first the horse itself (step 1, done
2026-10-24), then what happens to him in a fight, then riding and the lasso. Horses are never
targets (DESIGN.md §5, "No shooting animals"); they are cover, they get hurt, they spook, they're
ridden and lassoed (§8 rope, §11 "Horses as creatures", "Riding horses").

**References.** The street painting's horse at the livery rail (`docs/concept/street-golden-hour-painted.png`,
crop in `docs/screenshots/horse/2026-10-24/sheet.jpg`); `docs/ART_REVIEW.md` §3.5 (no boxes;
"a 500-triangle horse with a baked texture reads at that size").

## Step 1: the horse (2026-10-24, branch `claude/saltcreek-horse-model-fxzbuw`)

The route: Blender by script with the pip `bpy` (`tools/blender/horse.py`, as `make_people.py`
and the fire flipbooks run it), no paid calls. No gun was made in Blender (the guns are built in
code, `src/weapons/revolver_model.gd`; the gun lab painted their metals), so this follows the repo's
headless-Blender route instead. Rigify's horse metarig wasn't used: its generated rig is control
bones and constraints glTF can't carry; a 37-bone deform skeleton made by script is what the game
plays.

- **Form:** a signed-distance sculpt (ellipsoids and round cones for each muscle mass and bone),
  marching cubes at 1 cm (~185k triangles), decimated to 2,900 (coat and tail) and 477 (far).
- **Paint:** per texel from the sculpt (position, normals, occlusion): the bay, black points from
  knee and hock, white socks, dark hooves, mane and tail in strands, soft painted light cut to 7
  tones; 1024² (~250 texels a metre). Drawn in the men's skin shader.
- **Tack:** saddle (skirts, seat, horn, fenders, wooden stirrups, cinch), blanket (striped edge),
  bridle (headstall, browband, throatlatch, noseband, bit, conchos), reins, saddlebags: 2,660
  triangles in all, separate meshes on the skeleton, 512² paint; `take_off`/`put_on`.
- **Idle:** 12 s at 15 fps: the left hind rested, a shift to square, the right rested, back; two
  tail swishes, three ear flicks, a head dip with a sniff, breathing; standing hooves planted.
- **Collision:** ten capsules on the bones (barrel, quarters, neck, head, each leg in two).
- **In the street:** every horse at its rail, tied by two reins from the bit to the bar. The rails
  had all been dropped (each tested as one circle its length across against the steps); now tested
  point by point and cut to their longest clear stretch: four horses stand (main had two, untied).

**Judged by:** Sean's eye on the sheet; the judge and the blind critic on the street shot before
and after (`docs/screenshots/judge/2026-10-24_r1`, `_r2`); `tests/test_horse.gd`.

## Next steps (not started)

2. **Hit and going down:** a ball into a horse (it will happen in a fight): a flinch and a wound
   on his body (the wound shader is already his), a stagger, going down as a ragdoll of his own
   (capsules joined like a man's) when it's bad. Never a target: nothing aims at him; no reward.
3. **Cover in the gunfight lab:** men use a standing horse as cover (his capsules are on the
   world's layer already); a horse moves, so cover that can walk off.
4. **Spooking at gunfire:** shots near him (GameAudio's placed sounds, Senses) → ears back, head
   up, a sidestep, pulling at the reins; a hard pull frees him (DESIGN.md §8: "a spooked horse can
   pull free"); walking and trotting need mocap or a procedural gait first.
