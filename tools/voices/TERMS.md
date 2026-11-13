# ElevenLabs through fal: the terms for the voiced lines (#807, #836)

Fetched 2026-11-12 by the free probe (`requests/2026-11-12_probe.yaml`, run on GitHub: the
workspace can't reach fal.ai or elevenlabs.io). Short quotes only; the pages are the record.

- **fal, the ElevenLabs page** (https://fal.ai/elevenlabs): "Can I use ElevenLabs for commercial
  projects? Yes. Content generated through the fal.ai API can be used in commercial projects. Check
  fal.ai's terms of service for full details on usage rights and licensing."
- **fal, Terms of Service** (https://fal.ai/terms, last updated 2026-09-08): the customer uses the
  output lawfully and without infringing; fal "does not represent ... that any Output Content will be
  original ... or otherwise entitle Company to any intellectual property rights in any Output Content".
  No attribution required.
- **ElevenLabs, Terms of Service** (https://elevenlabs.io/terms-of-use, updated 2026-10-09): a paid
  user "may use the Services for commercial purposes", always within the Prohibited Use Policy.
- **ElevenLabs, help: can I publish what I generate** (help centre, legal): "All paid plans include a
  commercial license, provided you're not using Beta Services"; "content generated using Beta
  Services cannot be used for any commercial purpose or in any production environment".
  ElevenLabs' models page (2026-11-12) lists `eleven_v4` and `eleven_ttv_v3` as released models,
  not alpha or beta: re-check before a later model is used.
- **ElevenLabs, Prohibited Use Policy** (https://elevenlabs.io/use-policy): no deceiving,
  manipulating or impersonating others. Our voices are designed from descriptions, never a real
  person's name or recording.

What it means here: the generated voices and takes may ship in the game (a commercial product);
no credit line is required, and `CREDITS.md` gives one anyway. fal's safety checker refuses some
violent lines (it refused two of the sheriff's four designs for "violence", 2026-11-12); a refusal
costs nothing.

**Our own ElevenLabs account later:** a voice designed on fal is saved on fal's ElevenLabs account,
so its `voice_id` won't work with our own key. To bring a picked voice over, design it again in our
account with the same inputs (`model_id: eleven_ttv_v3`, the prompt, the text, the seed, guidance
4, loudness 0.5; all in `docs/scripts/<mission>.json` cast[].voice.design and the candidate's seed):
ElevenLabs documents "same seed with same inputs produces same voice". If that ever doesn't match
by ear, the fallback is an instant voice clone from the picked voice's own takes (our generated
audio, not a real person).
