# Casting the voices (brief)

Sean, 2026-10-27, after the voice pilot (`voice-pilot.md`): "design the voices one by one until we
think it matches, then start the voice work". The pilot's stock voices sounded "very plain and modern".
His scores: conversations made in one go 3.0, directed lines 2.5/2.05, words alone 1.5/1.42 (of 5).

- ElevenLabs Voice Design (`eleven_ttv_v3`) on Sean's own account (`ELEVENLABS_API_KEY`, 2026-10-27).
- `tools/voice/cast.json`: per character a brief, three description variants and one audition with
  range (calm, threat or shout, quiet, a laugh); every description asks for the 1880s frontier, close
  and dry, unpolished. Each variant makes 3 candidates: 9 per character a round.
- `tools/voice/casting.py design` (`[cast N]` in a commit) makes a round; Sean listens on the casting
  page and picks one or writes notes ("older, rougher"); notes become the next round's first variant.
- `casting.py save` (`[castsave]`) saves picks as permanent voices: `tools/voice/cast_voices.json`
  (voice id, description). Every line a character says uses his saved voice.
- First four: the stranger, Lyle, Amos, Earl. Round 1 (2026-10-27): Lyle missouri 1, Amos midwest 1, Earl kentucky 2 saved; spares kept for later roles: riverboat 1, farm boy 2, Tennessee 3. The stranger: none fit his model (about forty, not the late fifties first briefed); round 2 from his picture.
- Every description is written from the man's model picture as well as his role. Then the voice work: conversations generated together,
  Claude's direction, the word check (contractions and numbers ignored).
