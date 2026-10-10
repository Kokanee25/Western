# SALT CREEK — CLAUDE MASTER PROMPT LIBRARY

**Repository:** https://github.com/Kokanee25/Western  
**Game:** Salt Creek, grounded first-person frontier-town immersive simulation  
**Engine:** Use the exact Godot version pinned in the repository (4.7.2 at compilation of this library) and the configured Jolt Physics backend.  
**Library revision:** 2026-10-10  
**Document purpose:** Copy **one numbered assignment** into Claude at a time. This is a backlog of research and production briefs, **not an instruction to execute everything**.

## How to use this library

1. Open this document and choose a prompt by number. Paste **only that prompt** into the Claude session that owns its files, or send the whole library with the explicit instruction: **“Read this as reference only. Execute Prompt N and no other prompt.”**
2. Before executing, Claude must read the repository's current `CLAUDE.md` and `DESIGN.md`, inspect current branches and recent work, verify paths and versions, and reconcile any differences with the instructions below. `DESIGN.md` is the project's design authority; do not silently override newer decisions.
3. Maintain exactly the existing Art, Characters and Gameplay ownership structure unless the owner expressly changes it. “Environmental Physics,” “Testing,” and other labels in these briefs describe topics, **not permission to start a fourth conflicting workstream**.
4. For R&D, create a clearly named isolated branch/worktree, keep tests and outputs isolated, preserve a reproducible baseline, and **do not merge to `main` or change shared production systems without approval**. Read-only inspection of production code is fine.
5. Avoid uncontrolled scope expansion, needless rewrites, paid model calls, or destructive overwrites. Before any third-party paid calls or training, obtain explicit authorization and a cost estimate. Do not claim visual proof without rendered evidence, nor numerical proof without actual measurements.
6. Finish each assignment with: modified files; reproduction commands; key footage/screenshots; pass/fail tests; measured runtime/performance; unresolved problems; and a recommendation. Mark **verified**, **partial**, **not implemented**, and **proposed** distinctly.
7. The current art direction is under reconsideration. **Prompt 7 is an art-style decision gate.** Prompt 5 deliberately preserves the earlier painted-square investigation and should only proceed in full if that style is reaffirmed; otherwise adapt its geometric lessons to the newly approved style, with authorization.

## Index and status

| ID | Title | Source/status | Area | Suggested dependency |
|---|---|---|---|---|
| 01 | Automated Ragdoll Testing Laboratory | Revised existing prompt | Gameplay / tools | First for physics |
| 02 | Active Ragdoll Research Prototype | Revised existing prompt | Gameplay R&D | 01; 08 for mocap handoff |
| 03 | Interactive Object and Furniture Physics | Revised existing prompt | Gameplay R&D | 01; may run independently of 02 |
| 04 | AI-Directed 3D Asset Authoring Pipeline | Existing user prompt | Characters/Art R&D, isolated | 07 decision helpful |
| 05 | Character Face Geometry and Painted-Square Refinement | Existing user prompt | Characters | 07 style gate |
| 06 | Structural Destruction and Breakable Furniture | Existing user prompt | Gameplay R&D | 03 basic object system, 01 |
| 07 | Art Style Feasibility and Consistency Laboratory | **New draft — review** | Art + Characters coordination | Run early |
| 08 | AI Motion Capture, Animation and IK Pipeline | **New draft — review** | Characters | Character rig, 02 integration study |
| 09 | Passive Ragdoll Stabilization and Hit Reactions | **New draft — review** | Gameplay | 01 baseline |
| 10 | NPC Combat Intelligence and Movement | **New draft — review** | Gameplay | Existing NPC systems; 08 animation |
| 11 | Persistent World, NPC Memory and Consequences | **New draft — review** | Gameplay | Existing event/save systems |
| 12 | Playable Vertical Slice — General Store Robbery | **New draft — review** | Gameplay | 10, 11; can stub 13 |
| 13 | NPC Conversation, Intent Recognition and Voice | **New draft — review** | Gameplay/content | 11, existing conversation decisions |
| 14 | Automated Gameplay Playtesting and Stability | **New draft — review** | Gameplay/testing | Reuse current tests and replay |
| 15 | Living Town — Repair, Rebuilding and Economy | **New draft — review** | Gameplay | 06, 11 |
| 16 | Investigations, Evidence, Arrests and Justice | **New draft — review** | Gameplay | 11, 13 |
| 17 | Town Art Direction and Environment Consistency | **New draft — review** | Art | 07 |
| 18 | Emergent Missions and Autonomous NPC Plans | **New draft — review** | Gameplay | 11, 12, 16 |

### Suggested short-term sequence

**Art:** 07 → decide whether to resume 05 → 04 → 17.  
**Characters:** 08, while face work continues only under the approved style direction.  
**Gameplay:** 01 → 09; 03 → 06; 10 + 11 → 12; 13 + 14 can support the vertical slice.  
**Later systems:** 15, 16, 18, subject to a successful playable vertical slice.

These are dependencies, not permission to run multiple sessions concurrently or change another workstream's files.

---
