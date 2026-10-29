# Brief: a fitted coat (route 3), tried on the bold cowboy

Sean, 2026-10-29: "Yeah let's try with the bold cowboy." Issue #499. Lane: characters. Branch
`claude/characters-coat`. **Status: waiting on Sean's look at this brief; nothing is built yet.**

## Goal

Give men coats the way the blacksmith's apron was done (`tools/faces/apron.py`, Sean: "Perfect"),
not cut from a Rodin twin. This is the "proper garments" Sean asked for on 2026-10-18.

- **One template, built once by script:** a period sack coat with:
  - a turned collar and lapels with real depth;
  - separate set-in sleeves;
  - skirts to mid-thigh (but see question 1: his pictures' coat is longer);
  - an open front, so his waistcoat, tie and belt show.
- **One fit for every man:** a script sizes the template by his own joints and lays it just
  outside his body. Each sleeve is skinned to its arm, and the skirts are bent to his thighs below
  the hip, as the apron's skirt is.
- **Painted from his own pictures,** with procedural cloth as the fallback.
- **The first man is the bold cowboy,** `bold_cowboy_s3_talking`, the whole coatless Studio man
  (Rodin run 89, from the arms-out pictures). The yardstick is his current layered coat,
  `bold_cowboy_layered`.

## What went wrong before, and this brief's answer to each

Three coats have failed. The new one is held to each fault by a number, not by eye.

| Before | What was wrong | This time |
|---|---|---|
| The layered coat, cut from Rodin's coated twin (`LAYERED.md` §3, Oct 15–17) | Sleeves fused to the sides (the "wing" with hands up). The collar fused to the neck, then "a flat band", which Sean turned down twice. Vest and shirt were painted into the opening's edges. | Sleeves are their own meshes, weighted only to their arm and the shoulder helper. The collar is its own piece, standing off the neck. No AI mesh is cut (DONT_REPEAT 1). The opening shows his real waistcoat. |
| Garments lofted from the skin (Oct 18, `GARMENTS.md`) | Puffy, cape-like shoulders, a big collar and a small head. It was an offset of the skin, with no drape. | A designed template, not his skin offset. The shoulder line is a straight slope from neck to shoulder point. It stands at most 12 mm off him over the shoulders. The collar is at most 1.25× his neck girth and stands at most 3.5 cm (DONT_REPEAT 2). |
| The Studio's coat (`studio/steps/coat.py`, Oct 21, parked: "The coat isn't great") | A tiled swatch beside painted clothes. A tube with no folds. The same coat on three men. The rancher's collar up at his ear. | Painted from *his* pictures panel by panel, with no tiled swatch. Below the chest the cloth hangs, as the apron's does: straight from his chest and shoulder blades, bridging the small of his back and the gap between his legs. It breaks at the elbow. Sizes come from his joints and paint from his pictures, so no two men's coats are alike. The collar's top is measured under his ear in every pose. |

The Studio's coat is read for its measures and traps (the holster drape, the unsewn underarm,
the hidden skin under the coat), not copied wholesale. It wasn't approved (Studio BRIEF.md,
"clothing parked").

## References

- **The cut (1870s–80s sack coat).** I found these published manuals:
  - Jno. J. Mitchell Co., *The Standard Work on Cutting Men's Garments*, 5th ed., New York,
    1886. [archive.org scan](https://archive.org/download/standardworkoncu00mitc/standardworkoncu00mitc.pdf).
  - Louis Devere, *The Handbook of Practical Cutting on the Centre Point System*, 1866. Sack
    coats are drafted from the frock: "Sack coats are measured the same as frocks, with exception
    that no fashionable length of waist need to be taken."
  - *Designing Sack Coats, Dress Coats and Vests*
    ([cuttersguide.com](https://cuttersguide.com/pdf/19th-Century-Mens-Tailoring/pdf/Designing_sack_coats_dress_coats_and_vests.pdf)).
  - Gordon, *The American Coat, Vest and Trousers System*
    ([archive.org](https://archive.org/details/americancoatvest00gord)).

  **The hosts are blocked here:** `archive.org` and `cuttersguide.com` fail through the
  session's network policy, so no numbers have been read yet (question 3). Until they are, each
  template number in `sack_coat.json` carries its source, or is marked `"source": "to read"`. It
  is never filled in from memory. These numbers include the length off the nape, the collar's
  stand and fall, the lapels' width and notch, the sleeve's cap height and width at the cuff, the
  vent, and the button stance.
- **His look:** the bold cowboy's coated pictures, `docs/concept/style/factory/bold_cowboy_dressed/`
  (front, left, right, back), the ones his layered coat was painted from. They show a rough brown
  wool with a darker mottle, broad notched lapels, the coat open over his waistcoat, flap pockets,
  a half-belt across the back and the hem at the knee. The Studio's swatch
  (`inputs/bold_cowboy/swatches/coat.png`) is the cloth close up.
- **The yardstick:** `bold_cowboy_layered` in the same lab, lights and poses.
- **The method:** `tools/faces/apron.py` and `bandana.py`. Their parts are:
  - `Shell`: his outermost surface seen from his trunk's axis;
  - the hang (a column's distance from the axis never shrinks going down);
  - weights from his joints;
  - the skirt's hip-to-thigh bend (`BEND`, `THIGH_SHARE`).

## The template (built once: `tools/blender/coat_template.py`)

A headless Blender script (bpy) writes `assets/people/garments/sack_coat.glb` and
`sack_coat.json`. It is built on a neutral standard body (the MakeHuman base the hands and faces
already use), in its rest pose.

- **Pieces,** each its own mesh, with UVs laid out as a tailor's flat pattern:
  - two fronts;
  - the back in two halves, with a centre seam and a vent from the hem;
  - two sleeves, each an upper and an under sleeve, with a cap and an open cuff;
  - the collar: a stand and a fall turned over it, the roll line running on into the lapels;
  - the lapels, turned back with a facing and a notch.

  Every edge a viewer can see has thickness: about 4 mm of cloth, closed at the edge, so the
  lapel and collar read as folded wool, not a sheet. The template also carries named points the
  fit reads (`landmarks` in the json): neck base front and back, shoulder points, armhole top and
  bottom, chest line, waist line, hip line, hem, elbow and cuff.
- **Shape:** the template sets the coat's shape; his body only sets where it lies:
  - the shoulders a straight slope;
  - a little ease over the chest;
  - hanging straight from the chest and shoulder blades (a sack has no waist seam);
  - a small flare at the hem;
  - a gentle forward bend of the sleeve at the elbow.
- **Folds:** a few modelled ones where wool really breaks: the inside of the elbow, the back of
  the waist, and the sleeve head's ease. Small, so they bend with him. The rest are painted from
  his pictures.
- **Budget:** about 6,000 triangles for the whole coat, as one material. The apron is 2,510.

## The fit (one script for every man: `tools/faces/coat.py --man=<m> --out=<m>_coat`)

1. **Sized by his joints:** the template's landmarks are mapped to his skeleton's (the skin's
   binds, as `apron.joints`). Each landmark is mapped separately: a vertical scale between the
   lines, the width at each line from his trunk's shell, and the sleeves along his arm bones. No
   number is set per man (DONT_REPEAT 11).
2. **Laid just outside him:** each vertex is pushed out to at least his shell plus a gap: the
   trunk from `bandana.Shell` and each arm from its own shell round the bone. It is never pulled
   in, so the template's drape stands where his body falls away. Below his chest the fronts and
   back hang as the apron does. His holstered revolver is part of the shell on his right hip, so
   the skirt drapes over it.
3. **Weights:**
   - body panels: chest, abdomen and pelvis by height;
   - armhole rim: the shoulder helper (`PeopleBodies.shoulder_share`);
   - sleeves: upper arm and forearm only, blended at the elbow, with the cap shared with the
     shoulder helper;
   - collar and lapels: the chest and the neck's base, never his head, so turning his head can't
     lift the collar;
   - skirts: pelvis to thighs over `BEND` below the hip, the apron's numbers to start, with the
     vent letting the two halves part.

   No body vertex is weighted to an arm bone, so the side can't fuse to the sleeve.
4. **The underarm:** the sleeve is sewn into the armhole round the top and left open for a few
   centimetres under the arm, overlapping, so raising the arm opens a shadowed gap, not a
   stretched sheet. (The Studio's coat measured this: `underarm_open_share`.)
5. **What it hides:** his skin, shirt and waistcoat triangles fully under the coat (never near
   its open edges) are listed, so they can be culled later. Not in the first try: they stay drawn.

## The paint (`tools/faces/coat_paint.py`)

- **Route A (free; the first try):** his coated pictures laid onto the coat piece by piece.
  - Each piece is rendered from each view and its outline lined up with that piece's region in
    the picture (a per-piece line-up, the fix `LAYERED.md` §5 named for the sleeves).
  - A view is used for a piece only if the outlines overlap by ≥ 0.90 (DONT_REPEAT 3).
  - Each texel takes the view that faces it most squarely. No blending, except along a seam
    placed on purpose, at most 2 texels wide. A provenance map is written beside the texture.
  - **Light:** the pictures' broad warm light is taken out (fault 6: R² ≤ 0.10 of the paint
    against facing), and the folds and mottle are kept.
  - **No squares:** fault 7's block share is under 3%, and the import has mipmaps (fault 9).
  - **Unseen texels** (under the lapels, inside, under the arms) are filled with cloth made from
    that piece's own painted texels (their colour spread and mottle scale), not a flat fill (fault
    4) and not a tiled swatch.
  - The lining (inside, seen at the open front and the vent) is a darker plain cloth.
- **Fallback:** procedural wool, the apron's `leather()` way, in the colour measured from his
  pictures, if route A fails its checks twice. Report that, then move on.
- **Route B (paid, only with Sean's OK):** GPT-5.4 paints the coat flat in the template's pattern
  layout from his pictures (Studio `task: pictures`; the Studio's own estimate was ~$0.25 a man).

## Into the game

- The coat goes in a new model, `bold_cowboy_s3_coat`: a copy of his glb with `cloth_coat` added,
  `<m>_coat.png` beside it, and his `.json` gaining `coat` (what the fit did, its numbers).
  `bold_cowboy_s3_talking` stays as he is until Sean picks. Then the cast (`town_life.gd`,
  gameplay's file) swaps to the coat model, with the file named in the commit.
- `coat` is already in `HumanBody.DOUBLE_SIDED`, so the inside draws. A whole man wears every
  piece his model has (`PeopleBodies`), so nothing in the game's code changes. Taking the coat off
  and putting it back on is a later step, not part of this brief.

## What done looks like

- `cloth_coat` on the bold cowboy, painted to match his pictures.
- **Works check** (`tools/characters/works_check.gd`): 0 in stand, walk, run, sit, crouch and the
  ragdoll fall. Hands-up and aim are no worse than `bold_cowboy_layered`'s, measured first in the
  same run (table below). The hat off and a .45 through his chest show on the coat.
- **The faults' numbers:**
  - no triangle spans arm and trunk with his hands up (DONT_REPEAT 1);
  - over the shoulder line, at most 12 mm off his skin;
  - the collar at most 1.25× his neck's girth and standing at most 3.5 cm (DONT_REPEAT 2);
  - in every pose, the collar's top below his ear, with daylight between collar and neck at the
    back;
  - the paint's provenance, light, squares and mipmaps (DONT_REPEAT 3, 6, 7, 9).
- **Sheets, the new coat beside the old one:**
  - close, and at 3, 6, 10 and 20 m;
  - front, side and from behind;
  - the poses;
  - in the game's three lights (noon, golden hour, the saloon).

  The sheets go in `docs/style_test/coat/`, with his pictures first and the numbers underneath
  (DONT_REPEAT 12).
- The full test suite passes. No paid calls unless Sean says so.

| Works check (sheet cm² / sheets) | stand | walk | run | hands up | aim | sit | crouch | ragdoll |
|---|---|---|---|---|---|---|---|---|
| `bold_cowboy_layered` (yardstick) | to measure | | | | | | | |
| `bold_cowboy_s3_talking` (no coat) | to measure | | | | | | | |
| `bold_cowboy_s3_coat` (new) | | | | | | | | |

## How it's judged

1. **The numbers above are gates against the known faults,** not a score.
2. **A fresh sub-agent** that hasn't seen the work gets only his pictures and the two coats'
   sheets, and lists the five biggest differences a viewer would notice. These go in the status
   entry.
3. **Sean judges from the sheets:** keep it, or say what's off. A coat that passes every number
   but that Sean doesn't like isn't done.

## Steps (each a session; the session stops at its end, CLAUDE.md "Working lean")

1. **This brief** → Sean's look and his answers to the questions below (issue labelled
   `waiting on Sean`).
2. **The template:** the baseline works checks first (the table), then `coat_template.py` and a
   sheet of the template alone (front, side, back and a close-up of the collar and lapels) for
   Sean, before it's fitted to anyone. He has turned down two collars, so he sees this one first.
3. **The fit:** `coat.py` on the bold cowboy, procedural paint, the works check and the fault
   numbers.
4. **The paint:** route A, then the sheets for Sean.
5. **Merge** when Sean keeps it; the cast swap after his word.

## Questions for Sean (in the issue)

1. **Length.** The issue says a sack coat to mid-thigh. His pictures' coat, and his layered
   coat, reach the knee. Which? I suggest the template's length be a shared option (`hem`: mid
   thigh or knee), and that he gets his pictures' length (knee), so his paint fits it.
2. **Paint.** Route A (free, from his pictures) first, with route B (~$0.25, paid) only if A
   fails?
3. **The manuals.** Allow `archive.org` and `cuttersguide.com` in the environment's network
   settings, so the template's numbers come from the 1886 manual and not from guesses?
   (Settings: the environment menu in the session's title bar → Edit → Network access → Allowed
   domains.)

## Not in this brief

- Taking the coat off and putting it on, shooting it off, or swapping it between men (a later
  step, once one coat is kept).
- Other men's coats; the waistcoat, shirt and trousers as their own garments (after the coat,
  if Sean wants them).
- Culling the skin hidden under the coat (listed by the fit, not used yet).
- Cloth simulation: the coat is skinned, not simulated.
