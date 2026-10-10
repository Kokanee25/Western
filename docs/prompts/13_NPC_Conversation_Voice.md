# PROMPT 13 — Salt Creek: NPC Conversation, Intent Recognition and Authored Voice

**Repository:** https://github.com/Kokanee25/Western  
**Owner:** Gameplay/conversation systems, with Art/Characters coordination for face/voice animation  
**Priority:** HIGH.

## Important existing decision
Per `DESIGN.md` §9 (October 2026), **NPCs primarily speak authored, recorded dialogue lines**, while AI interprets what the **player** types/says into structured intent/deed records. It does NOT ordinarily invent NPC dialogue and is never invoked in the real-time frame loop. Rare fallback live-generated text can remain an explicitly opt-in research variant. Do not silently replace this design with always-on generative conversation.

## Inspect first
Read `CLAUDE.md`, `DESIGN.md` conversation and action-command sections, existing Events/DeedWatch/Relations, NPC brain and memory code, controls and dialogue UI, voice tools and current project key/proxy architecture. Inspect Prompt 11's provenance/memory work. Verify connected APIs, model pricing and commercial/Steam licensing before proposing external service use. Never put keys inside the game client, logs or repository; no paid requests without approval. Experimental branch/worktree owned appropriately.

## A — Player intent interpretation
Design a strict JSON-like schema from player utterance: addressee, speech act (greet, ask, warn, threaten, bargain, apologize, confess, lie, demand, comfort, buy), tone, referenced people/objects/events, confidence, asserted claims and suggested target deed. Enforce a whitelist: model output **cannot directly change truth, world state or NPC inventory**. Validate against game entities, follow with deterministic world logic and fail safely into authored misunderstanding lines. Benchmark ambiguous, sarcastic, shouted, interrupted and historically anachronistic input. Prevent prompt injection from changing game rules, revealing hidden NPC knowledge or corrupting save state.

## B — Contextual response rules
Write a compact response-selection engine prototype for bartender, sheriff and outlaw. Select **approved authored lines** based on social state, mood, current threats, time/place, injuries, drunkenness, knowledge provenance, relation and conversation history. A dying man sounds different from the same man calm, but remains coherent. Preserve secrets and real unknowns. Avoid repetitive line loops, unnatural silence and word-splicing artifacts. If line content is missing, use a documented neutral fallback; don't invent certainty.

## C — Dialogue creation and voice workflow
Build the authoring format for line IDs, condition tags, variants, voice/actor, pronunciation and revision. Prototype a **small** line bank with text and placeholders first; when authorized, test batch TTS/ElevenLabs or approved tool without committing credentials. Record source ownership, permission, per-minute/request cost, commercial rights and asset hashes. Include controller-ready suggested responses and subtitles when speech recognition/network is unavailable. Talk and physical action commands are different input modes; action commands must map only to real permitted game actions.

## D — Memory and asynchronous execution
On each utterance, retrieve only relevant actor knowledge, apply bounded context and explicit timeout/cache policies, report inference cost and latency, and keep network off physics/render loops. Use opt-in redaction for any voice/audio transmitted externally. NPCs must still function when offline; trust/fear/knowledge updates must be deterministic and explainable rather than delegated to freeform prose. Spoken claims may become rumours with uncertainty and attribution.

## E — Benchmarks and demo
Test 50–100 intent sentences across variants with gold labels and confusion matrix; adversarial text; contradictory claims; hidden facts; changing injuries; three-way overheard conversations; line selection coverage and repetition; offline fallback; latency/cost in measured permitted calls or offline estimations clearly labelled. Show bartender, sheriff and outlaw reacting differently to the **same** player demand. Human-review dialogue writing for character voice and period fit.

## Deliverables
Schema/validator, minimal speaker state and selector, sample authored line banks, deterministic tests, optional approved TTS prototype, demo footage/transcripts, real measured model outcomes if authorized, data/cost/licence assessment and production integration plan. **Success: the player can speak flexibly, but Salt Creek's rules—not the LLM—decide what happens.**
