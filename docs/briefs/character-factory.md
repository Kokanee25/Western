# Brief: the character factory (the characters session)

Sean, 2026-10-12: try building men from one good base head instead of a new AI model each time.
This is an experiment. Nothing here changes a default, a man already in the game, or another
session's files until Sean has seen the result. Read with `docs/briefs/characters.md` (the
layers, shape names and garment ids still apply).

## Why

Every AI-made man (Tripo, Rodin) comes with his own mesh and his own UVs. Two things follow:

- **The face's small forms are whatever the model happened to make.** Ears come out flat, the
  moustache sinks into the lip, eyelids and nostrils are paint, not shape. At the game's square
  size (~8 mm, about 20 squares across a face) anything under two squares vanishes, so these
  are exactly the parts that go missing. No shader can draw a form the mesh doesn't have.
- **Nothing carries over from one man to the next.** Every head repaint, eye drawing and fix is
  done again for each man, at a fal or Tripo/Rodin bill each time.

A factory fixes both: one base head with the forms built in, one UV layout, and men made from
it by parameters. The style is applied afterwards by whichever look Sean picks; the factory is
needed either way.

## What to build

1. **The base head.** Start from MakeHuman's base mesh (already fetched by
   `tools/blender/fetch_makehuman.py`, CC0, pinned to v1.2.0) and its face targets. Make the
   small forms readable at ~8 mm squares, by exaggerating them in the shape, not the paint:
   - ears flared out 15–25°, with a real rim and hollow;
   - the nose 10–20 % larger, the nostrils cut in;
   - upper eyelids as a ledge that casts a shadow over the eye;
   - lips with a defined line, the brow ridge a little heavier.
   Keep one UV layout for the head, laid out so the eyes, mouth and ears each get a fixed,
   generous patch. This layout is the point: anything drawn on it works on every man.
2. **Facial hair and hair as their own shells.** A moustache stands off the lip and casts a
   shadow (a few styles: walrus, handlebar, trimmed, none); beard and stubble options; hair as
   the existing `hair` shape (its own shell, so a hat comes off over it). Each style is made
   once and fitted to any head by the same script.
3. **Parameters.** A man is a `people.json` entry: MakeHuman's own targets (age, build, face
   width, jaw, nose, brow, cheeks, ears, chin), plus facial hair, hair, skin tone and wear.
   Start with 3–4 archetypes (lean hard man, heavy older man, young man, weathered old-timer)
   so a town doesn't read as brothers.
4. **Small details stamped by script** on the shared UV: the nostril dark, lip line, eyelid
   line, ear hollow, moustache underside, eye whites and iris. Drawn once per archetype, not
   per man.
5. **One man made from it.** The stranger is the obvious test (same outfit), built as a factory
   man through the existing `make_people.py` → `clothes.py` route into
   `assets/people/<id>_factory.glb`, alongside the existing men, not replacing them.

## Rules

- Blender headless, scripts in `tools/blender/` (a new `factory.py` or additions to
  `make_people.py`; say which). Every step repeatable from the repo.
- **No paid calls** (no Tripo, Rodin, fal, OpenRouter) unless Sean says yes to a stated cost.
  The point is that a man costs nothing.
- Licences: MakeHuman's base mesh and targets are CC0. Check any other MakeHuman asset (hair,
  eyebrow proxies) before using it and credit it in `CREDITS.md`; nothing that forbids
  redistribution goes in this public repo.
- The head must sit on the anatomy's head hitbox (drawn eyes within 1.5 cm of the anatomy's:
  `tests/test_bodies.gd` already checks fitted men).
- Branch `claude/characters-factory`. Don't touch the art session's shaders, ShotMatch or
  goldens; render with the tools.

## How it's judged

All on the same man, the same views, beside the stranger (`stranger2s`):

- **The pose check:** `tools/people_lineup.gd` standing, sitting, hands up, crouching, back
  view, no tears.
- **The face close-up:** `people_lineup.gd --head` front, three-quarter and profile, in plain
  light and in the saloon shot (`screenshots.gd --model=<id>_factory`). Do the ears, nose,
  moustache and eyelids still read at the game's square size? Crop at 2× to show it.
- **The character judge:** `tools/characters/judge_man.py` against the painting's man, both men
  scored.
- **The second man:** make a different archetype from the same base (parameters only, no new
  sculpting) and show both side by side. If the second man takes more than a parameter change
  and a run, say so: that's the factory failing.
- Report to Sean: one comparison sheet, the numbers, what it cost in time, and what's still off.
  Sean's eye decides whether the factory replaces the AI route.

## Not in this brief

The look itself (squares, the character-sheet style): that's the art session's and waits on
Sean's choice. Layered clothing beyond what `clothes.py` already makes. Facial animation.
