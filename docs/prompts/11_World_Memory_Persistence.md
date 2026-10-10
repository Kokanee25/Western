# PROMPT 11 — Salt Creek: Persistent World State, NPC Memory and Consequences

**Repository:** https://github.com/Kokanee25/Western  
**Owner:** Gameplay  
**Priority:** CRITICAL — foundational for social simulation and the vertical slice.

## Objective
Build on Salt Creek's **existing** event bus, DeedWatch, Relations, physiological states, World/Town save code and NPC routines to make events endure, influence future behaviour and survive saving/reloading. Persistent consequences are not simply static relationship counters; they must remain discoverable through later actions and conversations.

## Read first and preserve invariants
Read `CLAUDE.md`, `DESIGN.md` on deeds, memory, social systems and saving, `src/autoload/events.gd`, relevant `src/people/` modules, body injury serialization, structure/fire/prop state, existing save architecture and tests. Identify implemented vs proposed memory consolidation and event provenance. Respect **sleep-in-bed saves**, 45-real-minute game days, fixed-timestep simulation, person and object IDs, and events surviving even if NPCs are not actively loaded. No new parallel save format or background LLM in the frame loop. Gameplay-owned branch/worktree; do not edit Art/Characters code without coordination.

## A — Event provenance
Define compact stable event records: who did what, to whom/what, when/where, physical evidence, witnesses and visibility/hearing conditions, event importance, reliability, certainty and source. Link local perceptions/rumours to **one underlying event** when appropriate, while allowing mistaken identity and distorted retellings. Avoid omniscient NPC knowledge: a witness should know only what was plausibly seen, heard, inferred or told. Provide traceable state transitions and diagnostic inspector output.

## B — Personal memory and opinion
Implement or validate per-person trust, fear, affection, respect, grudge, gratitude, debt and beliefs updated by meaningful events. People react based on relation, courage, temperament, context and recall, not one universal hostility meter. Important memories persist; less important ones fade or consolidate nightly by deterministic rules. Prevent uncontrolled exponential growth in stored events and avoid overwriting pivotal witness reports. Ensure memories can be searched by person, place, event, topic and credibility.

## C — World consequences
Make a focused set of changes survive: damaged/displaced furniture, destroyed building components, fires/burn marks, injuries/amputations, dropped items, owner/shop states and NPC location/agenda changes. Integrate via existing serialization hooks and a delta-from-authored-world model. Validate GUID/ID stability, restoration order (structure before supported props, character before held items), collisions on restored dynamic objects, migration/versioning and error handling for missing assets.

## D — Time and schedules
Across a sleep/save/day transition, NPCs should continue appropriate agendas, services should reflect destroyed workplaces, rumours should travel only through plausible contacts, and consequences should evolve over days. Define unloaded-simulation approximations without incorrectly advancing detailed physics or conjuring supplies and witnesses.

## E — Vertical-slice tests
1. Threaten a shopkeeper; return next day; encounter changed attitude and recorded memory.
2. Threat witnessed but not heard by an absent sheriff; witness later tells sheriff; sheriff's belief records provenance.
3. Innocent character blamed through mistaken description; conflicting evidence can revise belief.
4. Shoot a chair/break a window; leave, save by sleep, reload; geometry and memory consistent.
5. Wound a man; treatment or death changes what other NPCs know.
6. Two independent witnesses have different information and cannot instantly pool memories.
7. Save/load repeated twice without duplicating events, items or rumours.

## Data and performance validation
Create structured traces, reproducible seeded tests, state snapshots and a debug viewer. Benchmark event stores with town-scale NPC counts, memory consolidation, save/load time and size, version migration and day advancement. AI/LLM is never required for deterministic rules. Clearly separate facts, claims and opinions; privacy/cost of external dialogue models is a later concern.

## Deliverables
Minimal reusable memory/consequence architecture or audited improvements to existing one, schemas/tests, seven live demos with before/after snapshots, performance/state-size measurements, known failures, and migration/integration plan. Do not rewrite existing event/relationship logic unnecessarily. **Success: the same threat or injury matters tomorrow, for the right people and for reasons traceable to observed events.**
