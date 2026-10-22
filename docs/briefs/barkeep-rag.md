# Brief: the barkeep's rag (Sean, 2026-10-22)

Gameplay lane, with the prop lab's leave for the cloth itself (`src/props/`, `assets/props/`: the
rag is a prop; each commit that touches them says so). Branch `claude/gameplay-barkeep-rag`.

## Goal

The barkeep has a bar cloth over his shoulder. When he's idle, with no customer near, he takes it
off, wipes down the bar in circles and long strokes, moves along, now and then wipes a glass, and
puts it back. Someone comes to the bar or trouble starts: he stops, and the cloth goes back over
his shoulder (a customer) or is tossed on the bar (trouble).

## What it's made of

- **The cloth** (`ClothProp`, kit kind `cloth`, `assets/props/kit/bar_cloth.json`): a rag about
  40 x 30 cm, off-white linen, stained. One `SoftBody3D` (Jolt's soft body) of 8 x 6 points, so it
  drapes over his shoulder, hangs from his hand and slumps on the bar top by its own physics.
  Held, a few of its points are pinned to his hand or shoulder; let go, none are.
- **A real prop:** dropped (let go anywhere, it falls and lies where it lands), knocked off (a
  blast, a ball through it, a shove or a hit on the man wearing it, him going down), picked up
  (the barkeep goes and gets it when things are calm; `ClothProp.hold` for anyone), burns (in
  flames for a couple of seconds it catches, burns as a small fire of its own that heats what's
  under it, and is gone; held, he drops it), and gets bloody (pressed on a bleeding wound by the
  hand that holds it, it soaks up blood where the wound was, and the press holds back the bleeding
  as a bare palm does).
- **The deed** (`WipeBar`, `src/people/wipe_bar.gd`): a chore in the barkeep's mind
  (`CivilianBrain.chore`), not a script. Each tick the brain says whether he's free (calm, at his
  post, nothing over him); the deed looks at the world (where the bar top is, by a ray; where the
  cloth is; who's near; which glasses stand within reach) and picks its next step: take the cloth,
  lay it on the bar, wipe a stretch, move along, wipe a glass, put it back, pick it up. It stops
  itself when a customer comes, and the brain stops it when trouble does.
- **Arms by dials, not keyframes** (CLAUDE.md "Motion"): his hands go where the deed puts them
  by the two-bone IK `HumanBody` already uses for a hand to a wound (`_arm_to`), through a new
  public `reach_to(side, at, normal, weight)`. The wiping hand rides the bar top found by a ray
  under it (it follows the surface), in circles and long strokes whose sizes, speeds and pressure
  are numbers in `config/wipe.tres` (`WipeTuning`). His head tips to watch his hand.
- **Fingers:** his real finger bones (30, skinned, #236): `curl_hand` closes the hand round the
  wad of cloth (a loose grip wiping, firmer lifting it off his shoulder), the cloth pinned to that
  hand at the palm.
- **Eyes:** FaceLife (PR #252) isn't merged. The deed keeps `watching` (the point he looks at);
  when FaceLife lands, it should read that as his gaze target. Noted in the code and the PR.

## References

- SoftBody3D under Jolt in Godot 4.7.2 (checked first, `experiments/barkeep_rag/softbody_probe.gd`):
  it runs; a 48-point rag costs ~0.07 ms a tick on one core of this 2.1 GHz workspace (~0.04 ms at
  Sean's), 8 of them ~0.24 ms; no blow-ups, no lost points. On four cores Jolt's job system adds a
  fixed ~0.3 ms of waiting and once printed "exceeded the maximum number of jobs" (it carried on).
  The fallback, if it misbehaves on the man: a few linked bones driven by simple physics.
- Linen: ~160-200 g/m², so a 40 x 30 cm rag is ~25 g dry, ~40 g damp (a bar rag is damp). Cotton
  and linen catch at ~250-400 °C; a loose rag in flames catches in about a second or two and is
  burnt through in under a minute.
- How a barkeep wipes: the cloth folded to a pad under the flat hand, small overlapping circles on
  a mark, then long strokes along the grain toward himself, moving along the bar; a glass held in
  the other hand, the cloth twisted into it. Over the left shoulder, wiped with the right.
- The hand to a wound (`HumanBody._grab`, `_arm_to`): the IK and the palm's pressure reused.
- GlassProp (`src/props/glass_prop.gd`): how a kit prop hears balls and blasts and finds fire.
- FireSystem's spilled oil (`spill`): a small burning patch that heats what's round it and
  scorches people; the burning rag is one that moves with it.

## What done looks like

1. **The lab** (`experiments/barkeep_rag/`): the barkeep (`barkeep_s2_talking`) behind a bar with
   the cloth and two cups; scenarios (a full wipe cycle; a customer walks up mid-wipe; a shot
   mid-wipe; the cloth dropped; knocked off by a blast; burnt; bloodied) run headless with numbers
   and rendered to a video.
2. **The saloon:** TownLife gives the barkeep his cloth and the chore; he wipes when the saloon
   is quiet and stops for the gang.
3. **Tests** for the deed (starts when idle, stops for a customer, tosses on trouble, puts it
   back, picks it up) and the prop (dropped, knocked off, picked up, burns, bloodied).
4. **The cost** against People's 4 ms (the deed and the arms) and Physics' 2 ms (the soft body).
   Target: under 0.1 ms in each at Sean's.
5. **Promoted:** `docs/PARTS.md` rows (the cloth, the chore, `reach_to`), LAYOUT.md lines.
6. **The look:** a free procedural texture now (`tools/textures/bar_cloth.py`: off-white linen
   weave, grey-brown stains, a frayed hem). Painting it in the men's hand through the texture
   factory (`paint_textures.py --style=man`, FLUX.2 [max], ~$0.08 a call; three takes at most,
   ≤ $0.30) waits on Sean's OK (an issue).

## How it's judged

- Sean watches the video: does it read as a barkeep wiping his bar? Does the cloth hang, drape and
  slump like cloth, not a board or a jelly? Does he stop when he should, and look right doing it?
- Numbers: the deed's and the cloth's cost in the frame; the cloth never through the bar, the
  floor or him (points inside), never flung, never lost; same seed, same result.
- The tests pass headless.
