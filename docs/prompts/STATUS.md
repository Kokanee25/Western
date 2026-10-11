# Status of this library (read first)

Sean, 2026-10-10: these are **ideas to implement once we're ready**, not active work. No session
starts one of these prompts unless Sean names it. Until then, DESIGN.md and CLAUDE.md win wherever
these prompts differ.

Where they differ today:

- **Art style:** Sean, 2026-10-10: "we're going to test the art style a bit more and decide how to
  finally handle it." So Prompt 07 is live once Sean starts it; until he decides, DESIGN.md §4 (the
  bold squares) stays the working look and nothing is migrated.
- **The feature freeze:** DESIGN.md says features wait until the look is right. Prompts 10–18 are
  features and wait for that.
- **"Read CLAUDE.md" (every prompt):** since 2026-10-11 that means CLAUDE.md as it is (lean),
  DESIGN.md's index, and the `docs/LAYOUT.md` sections the prompt's files belong to; the history
  the prompts refer to ("active branch/status", "recent work") is in `docs/status/`, newest file last.
- **Branches and merging:** use CLAUDE.md's branch names (`claude/<session>-…`), not
  `experiment/…`. "Don't merge to main" applies to experiments only.
- **Prompt 05:** its baselines "r10" and "D2r" aren't on `main`; ask the characters session where
  they are before starting.
- **Prompt 08:** there's no `assets/mocap/` or `assets/animations/` yet.
- **Prompt 12:** the purse (CLAUDE.md M4 step 5) isn't built yet.
- **Prompt 16:** DESIGN.md §13 asks whether forensics should be lighter; settle that first.
- **Prompt 17:** builds on `docs/briefs/set-direction.md` (cards, the brick bank and jail).

## Notes for discussion (gameplay session's review, 2026-10-10)

Sean: these are ideas to discuss as development goes on, not plans. What the code says today:

- **No save system yet.** Only some things write themselves out (members, wounds, relations,
  guns); there's no bed, save file or load. Prompts 11, 12, 14 and 15 test "sleep, save, reload",
  so a save system comes first, and it's a job of its own.
- **No memory store yet.** `Events` is a signal bus; nothing records who saw what (CLAUDE.md M4
  step 8). Prompt 11 is new work, and 12, 16 and 18 sit on it.
- **Prompts 03 and 06 overlap what exists.** Building furniture is already structural members
  (load, breakage, voxel carving) and `Fittings` drops what loses its support. A shot-out chair leg
  is mostly a chair built as a member structure, plus a hook to drop a seated man (he's posed, not
  resting on the seat). Build on that rather than a second support system.
- **Footage is slow here.** The drawn game runs ~2 s a frame under lavapipe (2026-10-07), so
  three-camera clips for every scenario take hours. Set a footage budget per prompt; render
  offline as the tour does; keep videos out of git (public repo).
- **Experiments go stale fast unmerged.** Lab tools in their own folder can merge once tested;
  only changes to how the game plays need Sean's OK. `tests/run_tests.gd` only finds `tests/`.
- **Prompt 08:** the skeleton is flat (a bone per body part, posed in code, no animation player),
  so retargeting mocap onto it is the hard part.
- **Prompt 10:** the gang's measured back-down share in the street is 0 of 3 (2026-10-05); the
  de-escalation outcome starts from there.
- **Prompt 14:** bridge, playtest agent, replay, soak, chaos tests and visual checks exist; what's
  missing is anomaly detection and scripted scenario runs (save/load waits on the save system).
- **Prompts 01/09 are right about the falls:** a bullet knockdown pushes the chest up to ~4.5×
  the hit plus a random sideways shove (`HumanBody.go_limp`), and a severed limb gets a random
  spin of up to ±8 rad/s.
- **Jolt on its own thread** breaks firing and dynamite (space queries outside the physics step,
  `docs/briefs/performance-b.md`), so physics experiments should stay on the main physics step.
- A possible gameplay order when the freeze lifts: 01, then 09, then 14's gaps, then 03+06 as one
  job; 11, 12, 15, 16 and 18 each want a save/memory brief first.

## Done

- **Prompt 01, the ragdoll lab** (2026-10-11, gameplay session; Sean: "let's work the ragdoll"):
  `experiments/physics_lab/` (README there). It measures only; the game is unchanged. Its
  baseline's five faults are what Prompt 09 starts from.
