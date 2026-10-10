# Status of this library (read first)

Sean, 2026-10-10: these are **ideas to implement once we're ready**, not active work. No session
starts one of these prompts unless Sean names it. Until then, DESIGN.md and CLAUDE.md win wherever
these prompts differ.

Where they differ today:

- **Art style:** the README and Prompt 07 call the art direction "under reconsideration". It isn't:
  DESIGN.md §4 (the bold squares, 2026-10-05) stands. Prompt 07 runs only if Sean reopens it.
- **The feature freeze:** DESIGN.md says features wait until the look is right. Prompts 10–18 are
  features and wait for that.
- **Branches and merging:** use CLAUDE.md's branch names (`claude/<session>-…`), not
  `experiment/…`. "Don't merge to main" applies to experiments only.
- **Prompt 05:** its baselines "r10" and "D2r" aren't on `main`; ask the characters session where
  they are before starting.
- **Prompt 08:** there's no `assets/mocap/` or `assets/animations/` yet.
- **Prompt 12:** the purse (CLAUDE.md M4 step 5) isn't built yet.
- **Prompt 16:** DESIGN.md §13 asks whether forensics should be lighter; settle that first.
- **Prompt 17:** builds on `docs/briefs/set-direction.md` (cards, the brick bank and jail).
