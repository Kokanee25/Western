# Brief: the Studio's men talk (their mouths move with what they say)

Sean, 2026-10-22. Characters lane, branch `claude/talking-mouth-shapes-3yhmv2`. How it's laid out:
`docs/LAYOUT.md` "The talking face" (the speech paragraph).

## Goal

When a talking man (every `*_talking` model: the face from `tools/faces/talking_face.py`, 20 blend
shapes) says a line (`Events.spoke(speaker, text)`, from `civilian_brain.gd` and `outlaw_brain.gd`),
his mouth says it: the line's sounds as his mouth shapes in time, a natural pace, the jaw and a
small nod of his head on the stressed words, and still when he's done. The subtitle shows for as
long as he talks. Today the lines are text only; when recorded lines come (DESIGN.md §9) the same
component takes its timing from the audio.

## What's whose

- His mouth (jaw_open, aa, lips_apart, ee, oo, fv, mbp) is the new `FaceSpeech`'s
  (`src/bodies/face_speech.gd`, numbers in `config/speech.tres`, `SpeechTuning`).
- His eyes, lids, brows, squint, scowl and where his head looks stay FaceLife's and FaceGaze's.
  The nod rides on top of FaceGaze's head turn (`FaceGaze.nod`, added to what it writes), so the
  two never fight over `pose_offsets[&"head"]`.
- The masked man's bandana (`cloth_bandana_mask`) gets the face's mouth shapes as its own
  (`tools/faces/mask_jaw.py`): the cloth over his chin goes down with his jaw.

## How (references)

- **Text to sounds:** letter-to-sound rules in the manner of Elovitz et al., "Automatic translation
  of English text to phonetics by means of letter-to-sound rules" (NRL Report 7948, 1976): the
  word's letters matched longest-first against graphemes with their contexts (magic e, a soft c,
  final e silent, `-ed`, `-tion`), a short table of the words English spells worst (the, you, one,
  was, said, ...). Only what the lips show matters, so the sounds go straight to ~20 mouth classes
  (visemes): many sounds share one (t, d, n, k, g; s, z), which forgives the rules' mistakes.
  Checked against espeak-ng's phonemes for every line in the brains (`tools/faces/speech_check.py`).
- **Stress and pace:** content words take a stress on their first syllable (a few prefixes on the
  second), function words none; stressed vowels ~0.13 s, unstressed ~0.07 s, consonants 0.05-0.09
  s, phrase-final lengthening, pauses at punctuation (comma 0.2 s, full stop 0.35 s, "..." 0.5 s,
  a dash 0.25 s). "!" and capitals speak bigger and a touch faster, "..." smaller and slower.
  Overall ~150-160 words a minute (conversational English), checked against espeak-ng at that rate.
- **Coarticulation:** Cohen and Massaro's dominance model ("Modeling coarticulation in synthetic
  visual speech", 1993): each sound pulls the mouth toward its shape with a strength that falls off
  in time either side, and the mouth is their weighted mean. Lip sounds (m, b, p; f, v; oo, w)
  pull hard and narrow, so the lips really close on an m; tongue sounds (t, d, k, h) hardly at
  all, so they take their vowels' shapes.
- **Audio later:** `say(text, track)`, the track either a phoneme list with times (a forced
  aligner's ARPAbet, e.g. the Montreal Forced Aligner run on the recorded line) or a loudness
  envelope (`FaceSpeech.loudness(AudioStreamWAV)`): the text's plan is fitted to the voiced
  stretches between the audio's pauses, and the mouth's opening follows the loudness.

## What done looks like

1. A line from the brains plays on a talking man as timed mouth shapes; `mbp` closes his lips on
   m/b/p, `fv` on f/v, `oo` rounds, `aa`/`ee` open; the mouth eases to rest when he's done.
2. The subtitle shows for as long as he talks (with a short hold after), not a flat 3 s.
3. The same component times a line from audio (loudness, or a phoneme track); tested on a made-up
   sound and filmed on espeak-ng's voice.
4. The mask moves with his jaw (or a reason why not).
5. Tests: a line makes shapes; mbp closes the lips; shapes stop when he's done; a dead man's mouth
   stops; a masked man's mask follows the jaw; a jaw-broken man barely opens his. The cost
   measured against the People budget (4 ms).
6. A film (`face_lab.gd --mode=talk`, `talk_video.sh`): calm, angry, hurt and the dying man's
   "Hhhk— hhk—", close and at game size, with the subtitle.

## How it's judged

- Sean watches the film: does the mouth say the line (the lips shut on "My", "Bring", "problem";
  the lip bitten on "Fire", "five"; round on "Who", "you", "go"; open on "Alright", "God")?
  Is the pace natural, the jaw not flapping, the nod small?
- The numbers: `speech_check.py` (agreement of the rules' mouth classes with espeak-ng's, and the
  lines' lengths against espeak-ng's at 160 words a minute); the tests; the cost per talking man.
- Later, Sean's three Live Link takes (issue #224) are the ground truth: the text-driven mouth and
  his own on the same line, side by side.

## Not in this

The voices themselves (recorded lines, ElevenLabs), emotional expression beyond the mouth (FaceLife
owns the brows), the tongue (no shape), languages other than English.

## Results (2026-10-22)

- **Built:** `FaceSpeech` (`src/bodies/face_speech.gd`), `SpeechTuning` (`config/speech.tres`),
  `FaceGaze.nod`, HumanBody's hook, PlayerWounds' subtitle as long as the line
  (`FaceSpeech.subtitle_seconds`, was a flat 3 s), Prof timer `faces` in People.
- **The rules against espeak-ng** (`speech_check.py`, the brains' 139 lines with words): mouth
  classes agree 95% (mean); every one of espeak's 146 lip closures (m, b, p) found, none extra;
  43 of its 44 f/v. Most of what's left is espeak's rounded "aw" in gone/on/walk. Length against
  espeak-ng at 160 wpm: median 1.02, 10th-90th 0.90-1.22.
- **Pace and size:** "Keep that iron where it is." 1.4 s; an open "ah" ~0.5 of the shape calm
  (`open` 0.6: the first film at 1.0 opened a calm line to a shout's ~3 cm), more shouted.
- **Audio:** `loudness()` + `fit()` and `plan_phonemes()` tested on a made-up recording and a
  track; filmed on espeak-ng's voice (`talk_audio.py`).
- **The mask** (`mask_jaw.py`, all nine masked men): it hangs straight down from his nose 2.5-3.5 cm
  clear of his lips and chin (`bandana.py`'s draping), so his jaw drops inside it, touching only the
  sides of his jaw (a few mm of follow there). It carries the seven shapes as that follow plus a
  puff of breath over his mouth (7 mm at a full "ah", none on shut lips), set frame by frame with
  his mouth. A cloth that rode his chin would need the mask redrawn tight under his chin (bandana.py).
- **Cost** (`speech_bench.gd`): ~10-14 µs a talking man a frame, 0.07-0.09 ms for ten at Sean's
  (People's budget 4 ms); planning a line 0.16 ms (worst 0.6 ms), once when he says it.
- **Tests:** `tests/test_face_speech.gd`, 13.
- **Found (not fixed here):** on four men the face's jaw goes *back* more than down: jaw_open's
  chin moves (down, back) as (0.24, 0.97) on the widow, (0.33, 0.94) bold_cowboy_s3, (0.41, 0.91)
  young_drifter, (0.58, 0.81) the doctor (a real jaw ~ (0.9, 0.4): Lyle, the barkeep, Colter; Sean,
  the rancher, bold_cowboy_talking between). Cause: `talking_face.py` carries each MakeHuman unit by
  warping the posed face through the thin-plate spline, and a chin dropped below the landmarks is in
  the spline's extrapolation, which bends it back. Fix: carry the units by the warp's local
  derivative at the rest point, then rebuild those four heads. Their talking reads wrong until then.
