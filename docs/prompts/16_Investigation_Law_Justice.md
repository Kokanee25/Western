# PROMPT 16 — Salt Creek: Investigation, Evidence, Arrests and Justice Systems

**Repository:** https://github.com/Kokanee25/Western  
**Owner:** Gameplay  
**Priority:** MEDIUM, dependent on the memory/consequence foundation.

## Objective
Prototype real investigative and law-enforcement gameplay for the 1882 frontier town: observe traces, interview witnesses, compare inconsistent accounts, arrest or release suspects, hold them lawfully or corruptly, and follow social/judicial consequences. Investigation must allow the player to reason with uncertain evidence; it should not be a highlighted-object collection quest. Where period law is used, research authoritative historical sources for the game's setting and distinguish established practice from game simplification.

## Read first
Read `CLAUDE.md`, `DESIGN.md` (law/evidence, witness recognition, camp story proposal, deeds, saving), current ballistics/wounds/blood traces, world object persistence, Relations/DeedWatch, conversation rules and Prompts 11/13. Identify any existing sheriff/jail/wanted poster implementation and avoid duplication. Separate plausible historical mechanics from speculative procedural assumptions; no claim of legal/historical accuracy without evidence. Use Gameplay-owned isolated branch.

## A — Evidence model
Support provenance/condition for: spent cartridges, bullet impacts/deformation, blood trails, footprints/tracks, broken property, recovered objects, wounds, property records and witness descriptions. Avoid portraying early firearm comparison as modern laboratory certainty. Describe observational confidence and time sensitivity (rain/traffic degrade prints; bodies and scenes change). Evidence cannot be known unless actually found, documented or reported; save state and chain-of-custody should be queryable when needed.

## B — Witnesses and uncertain identification
Each person reports what they could perceive (distance, light, obstruction, fear, recognition familiarity) with possible mistakes, rumours and deliberate lies. Account records include what the witness actually saw, their statement, and source. Contradictory accounts should have meaningful impact; no instant universal guilty flag. Interviews use authored dialogue/intent framework when available and a menu fallback when offline.

## C — Arrest and detention
Prototype surrender, weapon drop, restraint, escort, search, detention cell, escape and release. Account for injured people needing treatment, resisting suspects and bystander interference. NPCs and player use equivalent world/physiology states where feasible; no ragdoll teleporting to jail. Enforce clear lawful/extra-legal consequences as the frontier authorities see them, and allow the town leadership to be biased or corrupt without treating one version as objective truth.

## D — Justice and aftermath
Model the minimal judicial pipeline as evidence/witness evaluation + politics + social pressure + practical outcome (charges dismissed, release, restitution, sentencing). Avoid attempting a full legal simulator initially. Important events enter persistent memory, affect reputation and create follow-on objectives. For the Indigenous encampment mission, handle distinct communities and perspectives carefully and avoid treating Indigenous people as interchangeable NPC types or reducing their motives to a single stereotype. This scenario should be developed with historical/cultural research and narrative review before implementation.

## E — Tests and demo
One test offence with two witnesses, one misleading statement, physical trace, suspect who may surrender/escape, arrest and release decision. Include a mistaken-identification branch, an injured suspect needing first aid and an authority refusing to act. Test saving, changing evidence over time, later witness recantation, duplicate evidence prevention and NPCs recognizing a legally unresolved incident. Record live playthroughs and trace why authorities reached each outcome.

## Deliverables
Reusable evidence schema and witness account model, minimal playable investigation/arrest scenario, tests, sourced historical assumptions, event/decision trace, gameplay footage, integration plan, and honest gaps. **Success: player observation, witness reliability and choices matter more than finding a magic glowing clue.**
