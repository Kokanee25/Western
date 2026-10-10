# PROMPT 10 — Salt Creek: NPC Combat Intelligence and Physical Movement

**Repository:** https://github.com/Kokanee25/Western  
**Owner:** Gameplay  
**Priority:** HIGH, target one convincing encounter before global AI changes.

## Objective
Improve moment-to-moment combat intelligence and character movement so NPCs behave like fallible, motivated frontier people rather than scripted shooting targets. Preserve Salt Creek's existing person-specific relationships, threat escalation, gang coordination and wound/physiology systems. Combat outcomes should arise from goals, perception, fear, ability and local conditions, not from universal hostile flags or endless violence.

## Read first
Review `CLAUDE.md`, `DESIGN.md` §§6–9, current `src/people/`, `src/bodies/`, ballistics, NPC navigation/cover/routines, `docs/MOCAP.md`, current tests, and Prompts 08/09 where available. Identify behaviours already present (gang tactics, morale, cover, surrender, bucket line, etc.) and propose refinements, not duplicates. Keep to Gameplay ownership, branch/worktree, staged tests and no merge before review.

## Behaviour study
Create a small auditable decision model for perception → threat appraisal → intent → action → feedback. Consider ammunition state, weapon readiness, injury, blood loss, fear, trust of companions, protection of civilians, line of fire, obstacles, cover, possible escape and ability to negotiate/surrender. Make NPC variation parameterized (hothead, fearful amateur, professional gunman, bystander) without magical perfect information. Respect partial hearing, obscuring smoke, occlusion, delayed reactions, recognition, ambiguous threats and a person's own motives.

## Cover and movement
Test finding, approaching and exiting cover; avoiding exposure; using doorway sides and boardwalk stairs; peeking/leaning; crouch-walking and taking a knee correctly; repositioning when cover is destroyed; avoiding fellow NPCs, firearms and moving furniture; maintaining a believable path to a destination. The goal is fewer wall jams, clipping and robot turns. Require foot and hand IK integration *interfaces* where workstream boundaries prevent direct changes. Do not slide characters rapidly with perfect rotation changes or teleport them to cover.

## Combat interactions
Implement or prototype clear readable warnings, hesitations, draws, single-action revolver firing/reloading rhythms, moving while wounded, retreat, mutual covering fire, bringing wounded comrades to safety, surrender, capture of opponents and reasonable post-fight behaviour. NPCs shouldn't shoot until perceived threats justify it, and they can be mistaken. Injuries change physical ability and judgement; a character who cannot hold a pistol should stop pretending to. Never make firearms hyper-accurate merely to raise challenge.

## Encounter tests
One outlaw vs player/noncombatant; two coordinating gang members; three-person robbery with an uninvolved player; unexpected bystander intervenes; weapon holstered/withdrawal de-escalates; companion wounded; smoke and broken cover; civilian caught in line of fire; no player participation. Use fixed seeds where possible and record action/event trace with reasons for transitions. Run visual camera/playtest passes at gameplay speed and in-game-time measurements of paralysis/stuck behaviour and resolution variety.

## Acceptance/deliverables
A small reproducible combat sandbox and scenario runner, decision traces, observed failures, gameplay videos, nav/cover metrics, performance with several NPCs, compatibility notes with mocap/IK/ragdoll/furniture, and a minimal production integration proposal. **Three legitimate outcomes—including de-escalation—must be possible in the same core encounter.**
