# PROMPT 18 — Salt Creek: Emergent Missions and Autonomous NPC Plans

**Repository:** https://github.com/Kokanee25/Western  
**Owner:** Gameplay / narrative systems  
**Priority:** LATER — only after a complete vertical slice demonstrates reliable autonomy and consequences.

## Objective
Develop a small-world mission/event framework that lets independent NPC plans create player choices and consequences, rather than requiring a fragile sequence of scripted quest stages. Salt Creek is a social simulator with danger, not a shooting gallery. Interventions may change or prevent events, and the timeline should continue if the player does nothing.

## Read first
Review `CLAUDE.md`, `DESIGN.md` (30-day railroad clock, factions, proposed story spine/missions, drama manager and NPC knowledge), current gang/town agendas, `src/people/`, economy/law systems, Prompt 11 persistence and Prompt 12 robbery outcomes. Do not reopen decided story canon without asking. No full mission-generation AI system until a handful of hand-authored plans successfully interact with current world rules. Gameplay-owned isolated branch/worktree.

## A — Actor intentions and planning
Give named NPCs/factions explicit resources, relationships, priorities, deadlines, desired outcomes and plausible knowledge. A plan is a sequence of bounded world actions that can fail, pause, re-route or be completed by someone else. Example: gang seeks money/influence; storekeeper defends stock; town official wants to preserve order or protect a backer; doctor prioritizes treatment. Plans should not rely on player presence to proceed. Preserve the design's one-valley 30-day clock.

## B — Event framework
Model triggers, prerequisites, time windows, involved places, witness/rumour propagation, available player interventions, interruption, irreversible outcomes and persistence. Events emerge when plans cross (collection, theft, intimidation, fire, rescue, testimony), but don't spawn nonsensically just to guarantee combat. Keep mission state interpretable without revealing NPC secret motives to the player. Use deterministic rules and existing scheduler/event bus over an LLM-controlled authority.

## C — Three working scenario prototypes
1. Store robbery from Prompt 12, now driven by a gang goal rather than a special mission trigger.
2. A property intimidation/burnout plan that can be prevented, witnessed, delayed or completed without the player's attendance.
3. A witness/suspect dispute involving law enforcement and reputational consequences, with paths to arrest, violence, escape or miscarriage of justice.

The Indigenous encampment/bandit-investigation mission is an important proposed narrative example but should receive historical/cultural review and robust law/persistence mechanics before production mission writing. Avoid turning sensitive story content into algorithmically interchangeable templates.

## D — World reaction and dramatic pacing
Allow local NPC agendas, wound/care, damage and services to feed new opportunities. Ensure nonviolent resolution counts as satisfying activity and quiet periods remain possible. A drama manager may choose which grounded event to surface, but must not invent facts, teleport actors, replace destroyed locations silently or forcibly resurrect resolved antagonists.

## E — Test and evaluate
Run seeded simulations with player intervening early, late, never, aiding opponents, destroying a location and incapacitating a key NPC. Record causality chains, event count/type, time spent without meaningful choice, impossible dependencies, stuck plans, NPC omniscience and save/reload consistency. Review whether outcomes feel distinct from the player's perspective and whether town consequences truly differ over subsequent days.

## Deliverables
Small reusable NPC plan/event data architecture, three prototype scenarios, timeline/dependency visualizations, test runner, gameplay footage, state/causal trace, performance measurements and a staged narrative-production plan. **Success: the town has problems and intentions before the player arrives, and the player's actions can change—not merely select—the outcome.**
