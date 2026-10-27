# The voice pilot (brief)

Sean, 2026-10-27: the cinematic's "Welcome to Salt Creek" was flat (one sentence, a stock narrator
voice, a descriptive tag, one take). Salt Creek needs thousands of voiced lines (DESIGN.md §9:
written lines, voiced by a script), so voice acting has to be produced in batches without Sean
directing each line. This pilot finds the method before any big batch.

## Decisions

- Sean OK'd the pilot (about $2–3 on fal) on 2026-10-27, and the saloon ambience layers he proposed.
- Lines are recorded dry: no room sound baked in; Godot places them (GameAudio).
- Crowd chatter comes from sound effects; intelligible talk from the voice models; laughs and
  conversations come from where the men are, not an invisible crowd.

## The pilot

- 4 characters (the stranger, Lyle, Amos the barkeep, Earl the cheat), stock voices for now; 43
  lines: 4 conversations and 19 lines on their own (`tools/voice/pilot_lines.json`).
- **A**: Eleven v4, words only. **B**: Eleven v4, Claude's direction (audio tags, pauses, emphasis,
  from the line's scene). **C**: Text to Dialogue (v3 on fal) for the conversations, cut into
  lines at the pauses. **D** (later, needs Sean's own ElevenLabs account): B with a designed voice
  per character.
- Every take transcribed and its words checked (`tools/voice/pilot.py`; `[voice]` in a commit on a
  `claude/voice-*` branch runs it; results on the `cinematic-results` branch).
- Ambience: crowd beds that loop (quiet, evening, busy, tense; two of each), a hush, and one-shots
  (laughs, glasses, a pour, chairs, a cough, boots, cards).

## How it's judged

Sean listens blind (versions shuffled per line) on his phone and scores each take; the method that
wins becomes the pipeline. The word check catches wrong or missing words; it can't judge acting.

## Then

The production pipeline: voice profiles per character, the line format (ids, conditions, scene),
direction written by Claude, takes in batches with bounded concurrency and a cache, the word check
and retries, Sean hearing only flagged lines and hero moments; hero lines optionally Sean's own
performance through the voice changer.
