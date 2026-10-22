# Sean's planning chat, 2026-10-20 to 2026-10-21: what was decided and where it lives

One long planning conversation with Sean (not a build session). Everything it decided is in the
repo; this is the index, so a new planning session can pick up from here.

## Where each decision lives

| Topic | Where |
| --- | --- |
| Godot vs Unreal: stay in Godot; a small Unreal test scene may be run later | `docs/briefs/unreal-test.md` |
| The labs: how every lab works, gunfight, body, breakage, treatment (field first aid; the doctor), people and systems labs, the Systems Playground, water, face rig, gun lab (real guns, made-up names) | `docs/briefs/labs.md` |
| When each lab and pipeline starts | `docs/ROADMAP.md`, "When the labs start" |
| Labs measure; parts live in the game; the parts list | `CLAUDE.md`, `docs/PARTS.md` |
| The prop lab (every prop end to end, the prop kit) | `docs/briefs/prop-lab.md` |
| Painted damage: wound paint, breakage paint, fire | `docs/briefs/damage-pipelines.md` |
| Fire: simulated flipbooks, painted (moved up to now) | `docs/briefs/fire-look.md`, "The next approach" |
| The material lab, the building lab, the town; the saloon sheet's critiques and Sean's answers (outside stair, both balconies, bedrooms, outhouse, a wider lot, a big cellar by a trapdoor in a kitchen behind the bar) | `docs/briefs/building-pipeline.md`, `docs/concept/saloon-sheet.png` |
| Showcase moments (the card cheat and "my chair!", the balcony blown out, the night-meeting trap, the piano player with favourite and hated songs and hands driven by the notes, and more) | `docs/briefs/showcase-moments.md` |
| Answering yes or no with a nod (proposed) | `DESIGN.md` §9, "Answering with a nod" |
| A ready-to-paste prompt for every session and lab | `docs/SESSION_PROMPTS.md` |
| Sean's checklist: GitHub Issues labelled "waiting on Sean" (each opens with "Answer in:" and the session link); ideas labelled "idea" | `CLAUDE.md` |
| Import files: CI fails if Godot's import writes `.import` files that aren't committed | `.github/workflows/build.yml`, `docs/LAYOUT.md` "CI" |

## The plan to Saturday 2026-10-24 (Sean's free usage reset, 2026-10-21)

**Finish line: the card cheat, playable in the saloon.** Up to four sessions:

1. **The card cheat, playable** (gameplay), after PR #204 (the chair kick-out) merges.
2. **The saloon building** (building lab): both triggers met (interior woods picked, `Railing` in
   the game); built as an experiment first so the card cheat keeps the current saloon.
3. **The gunfight lab**, bench and baseline (3.0).
4. **The prop lab: bottles and the oil lamp**, so the card cheat and the bar brawl have glass.

**Paused until after Saturday:** the material lab after the exterior pick (#217); fire after
Sean's A/B (#216); the breakage lab's dig-able ground and craters; characters (face rig, finger
bones, bandanas); every lab not yet started; the Unreal test.

**Sean's quick answers first:** #219 (chair poses: unblocks the card cheat), #217, #216, #222.

## Open questions for Sean (beyond the issues)

- Finger bones for the Studio's men: they block gripping guns, the piano player's fingers,
  holding things and fingers shot off (issue #222).
- The four-sessions-at-once rule is his to raise while usage allows.
