# PROMPT 14 — Salt Creek: Automated Gameplay Playtesting and Stability Laboratory

**Repository:** https://github.com/Kokanee25/Western  
**Owner:** Gameplay/testing  
**Priority:** HIGH, build on existing infrastructure—do not replace it.

## Objective
Enable an automated agent to play and stress Salt Creek encounters, identify reproducible behavioural bugs, and supply evidence useful to Gameplay, Characters and Art owners. This is **not** just another unit-test suite; it should detect stuck characters, implausible reactions, missing feedback, state corruption and scenarios that technically pass but look broken or feel inert.

## Read first
Review `CLAUDE.md`, `DESIGN.md`, `tests/run_tests.gd`, `tools/bridge.py`, `tools/playtest.md`, `tools/playtest.py`, `tools/replay.gd`, `tools/soak.gd`, `tools/screenshots.gd`, `tools/scene_probe.gd`, `tools/visual_checks.py`, `src/debug/bug_recorder.gd`, CI workflows, and current test outcome conventions. These may already support screenshots, command-driven gameplay, deterministic replay, long soak and blind playtests. Identify and extend the narrow missing capabilities only. Respect three workstream ownership areas and don't auto-edit production while judging it.

## A — Scenario harness
Create scripts describing a starting seed/scene/character state and a time-ordered or goal-directed sequence of player acts (walk, look, draw, aim, shoot, holster, interact, leave, sleep, save/load). Support deliberate environment disruptions (fire, broken furniture, wounded NPC, lost cover), scheduled autonomous NPC actions, and abort/recovery when expected objects are missing. Provide both strict replay and adaptive playtest modes; distinguish their reproducibility guarantees.

## B — Observation/logging
Capture scene/state snapshots, event trace, player inputs, NPC goals/routes, relevant collisions and world changes, visual footage/screenshots, CPU time and errors. Add anomaly detection for NPC path jams, collision penetration, stuck prompts, duplicated/deleted items, immortal unconscious NPCs, ragdoll launches, failed reloads, unreachable services, broken save/restore and scenes that cannot reach a stable outcome. Use concrete thresholds calibrated by test data and report likely owners/files without claiming root cause if not verified.

## C — Playthrough suites
- Store robbery peaceful, violent, witness-only and ignored.
- NPC enters/leaves saloon/boardwalk through stairs and doorway, without teleporting.
- Wounded enemy flees or is treated/dragged.
- Fire starts, people respond, rebuilding or changed services later where implemented.
- Player dies/awakens, enters and exits current save cycle.
- Overturned furniture blocks navigation; NPC selects new path.
- Night/day and poor visibility alter perception without omniscience.
- Extended quiet town period does not stall or leak nodes.

## D — Automated critic and human evidence
Use an independent reviewer exposed to footage and intended design behaviour, but not implementation details, for clear animation/scene quality assessment. Report false positives, unverified findings, screenshots with timestamps, repro commands and severity. Tests should not auto-approve subjective realism; keep numerical anomalies separate from human review.

## E — CI and performance constraints
Run short smoke/regression suites routinely and expensive render/soak suites selectively, respecting runtime cost of CI. Capture baseline build/commit, fixed seed and engine version. Test that instrumentation itself doesn't significantly change frame time. Produce minimal failing `.saltbug` or equivalent replay when supported. Never publish credentials or raw external voice data.

## Deliverables
CLI-driven playthrough definitions, executable runner using existing bridge/replay, 7+ scenario reports, screenshots/clips/replays, prioritized bugs with ownership and repro steps, runtime statistics, CI recommendation and concise documented handoff to a fresh agent. **Success: find repeatable things a player would actually notice before the user has to find them manually.**
