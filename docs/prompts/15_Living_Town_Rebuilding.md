# PROMPT 15 — Salt Creek: Living Town, Repairs, Rebuilding and Local Economy

**Repository:** https://github.com/Kokanee25/Western  
**Owner:** Gameplay; Art coordinates reconstruction visuals  
**Priority:** MEDIUM — after persistent state and structural destruction are reliable.

## Objective
Make structural damage create visible work and social/economic consequences over subsequent in-game days. A burned livery or collapsed porch should not magically reset, but rebuilding also need not simulate every nail and hammer swing. Reuse the structural support graph, TownLife NPC agendas, fire consequences, persistence and available materials.

## Read first
Read `CLAUDE.md`, `DESIGN.md`, current `src/structures/`, fire and settlement code, `src/people/` routines, `config/town.json`, `docs/TOWN.md`, existing save and economy/inventory logic, and Prompts 06/11. Inspect what repairs or building phases are already supported. Do not replace existing fire/bucket-line or structure rules. Make changes only within a Gameplay-owned experimental branch; Art controls new period-appropriate dressing, debris and construction visuals.

## A — Damage assessment and repair planning
Build a small repair-state machine: intact → damaged/unsafe → cleared/stabilized → materials acquired → under repair → serviceable/rebuilt. Each stage has physical/material prerequisites, estimated labour and in-game schedule; progress can pause due to missing supply, weather, new damage or absent workers. Damage severity and load-bearing support should determine what can be patched versus fully replaced. Respect ownership, costs and survivor access to resources.

## B — Period-credible supply chain
Assess lumber sources appropriate to the frontier valley (local timber if available, sawmill/yard, teamsters or rail supply if plausible), nails, boards, stone/brick and tools. A carpenter or worker can fetch/deliver material; heavy structural members may require teams. Avoid inventing a complete resource-extraction economy until a narrow prototype proves useful. Track material counts/costs without making every plank an always-active physics body.

## C — Visible staged rebuilding
Prototype a damaged storefront/porch: debris remains, site is cleaned, temporary braces/foundation appear, framing rises, boards and roof return, interior reopens. Workers visit and carry out simplified plausible task loops with hand/tool animations where available. Construction steps must only materialize at plausible progress intervals and should not pop instantly from ruins to fully finished. Use authored construction states or reversible structure members; do not manually animate each nail. NPCs should not path through unsafe rubble.

## D — Service and social consequences
Destroyed store/doctor/livery should change access to goods, care or transport; people redirect work, remember losses, seek help or blame perpetrators. Reconstruction cost affects owner/debts and labour schedules. If enough of town burns, alternative temporary services might emerge slowly, not instantly. A building's state must survive save/reload and repeated destruction, with no duplicate walls or workers.

## E — Tests
One small porch repair over 1–3 days; major building loss over several days; materials exhausted; worker injured/absent; site re-damaged halfway; player supplies lumber; saved/reloaded mid-stage; NPC navigation while site is unsafe; town service restored only once usable. Verify visually at each state using time advance/test commands; measure CPU, node, save and activation cost.

## Deliverables
Minimal phased-repair architecture, one complete time-lapse rebuilding prototype, state/material schema and tests, documented art hooks, actual footage/screenshots across days, memory/service integration points and performance report. **Success: the town visibly repairs what happened, at a credible pace, because people and materials made it possible.**
