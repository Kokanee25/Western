# PROMPT 12 — Salt Creek: Playable Vertical Slice — General Store Robbery

**Repository:** https://github.com/Kokanee25/Western  
**Owner:** Gameplay (coordinate art/character asset needs)  
**Priority:** CRITICAL — prove the game's systems create an engaging experience.

## Objective
Create **one fully playable, repeatable general-store robbery encounter** in which existing Salt Creek systems—relationships, escalation, NPC movement/combat, anatomy/wounds, environment, persistence, player choices and aftermath—interact meaningfully. A vertical slice is not a scripted cinema scene and not permission to rebuild systems already implemented.

## Read first
Inspect `CLAUDE.md`, `DESIGN.md`, actual town/store scenes, merchant and gang brains, OutlawBrain/CivilianBrain, DeedWatch/Relations, existing weapons/ballistics, Physiology/HumanBody, Events, saving, player interaction/bridge tooling, Prompts 10/11 and any completed Prompt 13. Preserve authored store and town appearance and approved narrative canon. Do not change unrelated art/golden images in Gameplay without approval.

## Scenario
During regular town life, a gang member or small gang pressures the storekeeper for money, goods or a favour. Player may arrive early, midway or after. NPCs have plausible independent motives and know only what they perceive. The incident should continue if the player watches, walks away, threatens the gang, helps the merchant, cooperates with gang, or fires. This cannot be one brittle quest-stage chain.

## Minimum interactions
- Player can approach, listen, holster/draw/aim, threaten, back off or leave; include fallback basic dialogue/menu even if natural-language input isn't available.
- Merchant reacts to immediate danger and personal relationship.
- Gang may threaten, bargain, steal, flee, surrender or fight based on credible triggers.
- Other witnesses respond based on proximity, line of sight and courage.
- Gunshots use actual ammo/hit and wound systems; an incapacitated robber can be alive, dead or escaping, not automatically killed.
- Cover and environmental hazards influence the action; broken props persist if supported.
- Player choices produce outcomes affecting service, inventory/finances where available, relationships, law/witness reports and gang plans.

## Acceptance outcomes
Demonstrate at least: **A — peaceful de-escalation** with no gunshot; **B — violent intervention** with injury and surviving witnesses; **C — nonintervention/escape** with theft or intimidation completed. Add a fourth outcome where player aids robbery if systems already support it. A player leaving the scene must not freeze event progress. Surviving gang members may remember what happened; nobody magically knows the player's hidden choice.

## Technical design
Use event-driven objectives/facts and small reusable behaviours, not mission-specific bypasses of regular systems. Implement minimal missing adapter rather than duplicating AI, memory or physics. Each involved actor should have documented goals, awareness, state, safety boundaries and transitions. Handle interruption, unloading, save/load and an NPC getting stuck in a doorway. Keep narrative dialogue consistent with existing DESIGN decision: recorded/authored response rules, natural language as optional player-input interpretation rather than automatic freeform NPC speech.

## Testing and visual proof
Create automated reproducible scenario runners for all paths, unexpected interventions, death/incapacitation of each actor, disabled dialogue/LLM, partially loaded scene and immediate player departure. Use existing bridge/replay/playtesting framework. Capture 3+ player-perspective gameplay videos and event/decision traces. Include one blind playtest report focused on readability, tension, player agency and system failure, not just engine errors. Record performance and save-load correctness.

## Deliverables
A playable test build/scene, documented encounter state/fixtures, 3+ distinct reachable outcomes with persistence evidence, automated tests, short clips, issues/bugs ranked by player impact, and a prioritized next-vertical-slice report. State missing systems honestly. **Success: a player can tell a story about what happened without the game imposing one canonical outcome.**
