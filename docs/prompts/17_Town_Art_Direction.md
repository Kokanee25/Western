# PROMPT 17 — Salt Creek: Town Art Direction and Environment Consistency

**Repository:** https://github.com/Kokanee25/Western  
**Owner:** Art (coordinate Characters/Gameplay as needed)  
**Priority:** MEDIUM — after approval of Prompt 07's style direction.

## Objective
Turn Salt Creek's approved art direction into reproducible rules for every building, room, prop and lighting setup while preserving a visually distinct identity for each business and resident. The town should feel authored and inhabited rather than procedurally repeated. Improve the **actual Godot world** before adding more disconnected concept artwork.

## Read first
Review `CLAUDE.md`, `DESIGN.md`, `docs/briefs/set-direction.md`, `docs/TOWN.md`, `config/town.json`, `docs/concept/`, golden screenshots, art critics and current environment shader/material/prop tools. Determine what facade cards and signs are already approved. Inspect Prompt 07's chosen style bible and Prompt 04's component authoring results. Never change Art-owned approved references or golden images automatically; use a separate Art branch and approval flow.

## A — Building identity cards
For each selected frontage/interior, define owner, occupation, age/repair state, means, construction material, distinctive form, palette, hand-lettered signs, practical furnishings and five unique clues to how it is used. Start with **saloon, general store, jail, bank and livery**. Respect earlier bank/jail brick decisions in repository unless explicitly superseded. Distinctive does not mean random stylistic inconsistency.

## B — Modular but non-repeating set dressing
Build a small controlled kit: weathered board variants, period-appropriate doors/windows, counters, shelves, stools, oil lamps, hand tools, posters, hardware, signs and grime/damage layers. Record material scale, edge/shadow treatment, sensible geometry/texel density, variation budget, reuse frequency and placement rules. Make each room serve NPC actions (sit, shop, drink, work, take cover), preserving gameplay collision, door clearance and breakable-part interfaces.

## C — Lighting and atmosphere
Ensure one coherent style under golden hour, midday, lamplit saloon evening and nighttime street. Check exposure, sky/sun colour, haze, lantern halos, readable facial planes, existing fire/smoke treatment and how cloth/wood/stone react. Compare **in-engine** screenshots and camera walks with concept references. Avoid hardcoded light tricks for one camera, uncontrolled over-darkness or smooth modern surfaces inconsistent with the style. Changes to shared `project.godot` or Gameplay-owned structure assets need coordination.

## D — Quality and automation
Use fixed-view goldens and independent blind critic familiar with the style references but unaware of implementation changes. Add validations for duplicated props, unusable entrances, inconsistent texel/material scale, stretched letters, floating objects, poor silhouette and missing interiors. Rank issues by player-visible salience, not purely numerical pixel matching. Track performance/instancing/draw call budget.

## Deliverables
Approved or proposed building cards, concise material/lighting/prop style bible, representative upgraded saloon/store/jail screenshots and walks, reusable authoring/check scripts, art scorecards, measured performance and prioritized backlog. **Success: from any street or interior view, a player can tell where they are and who uses the space without the world's style changing between buildings.**
