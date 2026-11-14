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

## Step 1b: remade to Sean's pictures (2026-10-24, same branch)

Sean drew the horse (four views, `docs/concept/horse/`) and asked why Rodin and not Blender. The
answer: Blender can't read a picture; Rodin is the AI that turns pictures into a shape (~$1.60),
and everything after it would still be Blender. So first, for $0, the pictures drive the Blender
build directly:

- **Shape:** `horse_ref.py` cuts the horse out of each picture (the backdrop is flat grey; his
  shadow darker grey, so it stays out) and measures him (454 px a metre, his withers at 1.52 m).
  The body, neck and head are lofted from his side outline (per column: top to underline; widths
  set against the front and back outlines); legs, ears and tail placed where the pictures put them. The
  two side pictures disagree in length by 7% and are lined up by the trunk; both then give the
  same stance (left fore and hind forward, the right hind well back). Side outline match 0.76
  IoU before the leg stance was fitted.
- **Paint:** the coat is Sean's pictures projected onto him (`horse_paint.projected`): each texel
  from the pictures that face it squarely and see it (a depth test against the sculpt, so the
  head isn't painted on the chest). The blaze, cream stockings, dark brown mane and tail and the
  brushwork are the pictures'. `--paint=rules` keeps the old rule-painted bay.
- **Kept:** the rig (now 39 bones, a six-bone tail), the idle (the tail's swish cut to a flick,
  ~17°), the tack (moved back 0.14 m with the shorter body), collision (capsules now in
  `horse.json`, from `horse_shape.capsules`).
- **Not yet like the pictures:** the tail is solid where his is loose hair (a lower arch and a
  thinner sheet since the first remake, which read as a paddle); the hindquarters a little less round. Rodin stays the next try if the shape is still wrong to Sean.

Sheet: `docs/screenshots/horse/2026-10-24b/` (his pictures against the model; the game views).

## Step 1c: Rodin on a new picture set (2026-10-24, Sean's pick A on #340)

Sean: "weird bumps at the tops of its legs and the back legs are all kinda messed up". Cause: the
sculpt's legs were separate shapes on a lofted body (a ledge at the elbow, knobs at the stifle), and
his pictures' legs overlapped and his two sides stood differently. So (Sean: "A", then "Approved"):

- **Pictures** (the Character Studio, `claude/studio-horse`, `studio/steps/horse.py`, $0.42): the
  left side standing square in a true profile, then front and back, from his pictures by Nano Banana
  Pro; the right the left mirrored; front and back scaled to the sides' height. Sean approved them.
- **Shape** (Rodin Gen-2.5, $1.60, no T-pose): `inputs/horse/shape.glb` in the Studio.
- **The game's build** (`horse.py --shape=GLB`, `horse_rodin.py`): Rodin's model turned to our
  axes, scaled to 2.05 m at the ear tips, centred on his barrel, and measured: each leg's line by
  level cuts (fetlock, knee or hock, elbow or stifle), poll, muzzle, withers, the tail by its dark
  paint. Those landmarks replace the sculpt's in `horse_shape` (`set_legs`, `set_head`,
  `set_tail`, `set_trunk`), so the rig, weights (the tail's bones kept to the tail's points),
  idle, tack and capsules fit him. The coat is Rodin's own paint baked into the coat's layout.
  The sculpt route stays (no `--shape`).
- **The tack slid back** (Sean: "too close to his head"): `SADDLE_BACK` 0.12 m in `horse.py`, the
  blanket's front now behind the withers; sheet `docs/screenshots/horse/2026-10-24d/`.

## Next steps (not started)

2. **Hit and going down:** a ball into a horse (it will happen in a fight): a flinch and a wound
   on his body (the wound shader is already his), a stagger, going down as a ragdoll of his own
   (capsules joined like a man's) when it's bad. Never a target: nothing aims at him; no reward.
3. **Cover in the gunfight lab:** men use a standing horse as cover (his capsules are on the
   world's layer already); a horse moves, so cover that can walk off.
4. **Spooking at gunfire:** shots near him (GameAudio's placed sounds, Senses) → ears back, head
   up, a sidestep, pulling at the reins; a hard pull frees him (DESIGN.md §8: "a spooked horse can
   pull free"); walking and trotting need mocap or a procedural gait first.
