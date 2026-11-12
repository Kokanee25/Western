# Scripts: the voiced lines, one mission a file (#807)

Each mission's lines are data here (`<mission>.json`), and each has its own artifact page (the
listening board), private to Sean, built from that file by `board.html`. Sean reads the script on his
phone, leaves notes, taps **Script OK**; later the same page holds the cast's voice candidates and 3-4
takes under every line, and he picks one.

| Mission | Script | Page | State |
|---|---|---|---|
| The sheriff on the road | `sheriff_road.json` (page `board.html`) | https://claude.ai/artifact/FyzbCopumhRVDAeH7hN1vX | draft, waiting on Sean's Script OK |
| No Law | `no_law.json` (page `no_law.html`) | https://claude.ai/artifact/65eAXArWQm5XD5FCEXpYuY | draft, waiting on Sean's Script OK |
| No Justice | `no_justice.json` (page `no_justice.html`) | https://claude.ai/artifact/3ojdVLjNoGLCt5qkADSEiW | draft, waiting on Sean's Script OK |

## The file

The fields are in the file's `_doc`. In short: `cast` (each speaker, his voice brief, `voice` empty
until casting), `scenes` in play order, each with `lines`: `id`, `speaker`, `trigger` (what in the
game makes him say it), `when` (the branch: his blood-loss band, `sheriff.care`, a nod or shake),
`condition`, `delivery`, `words` (wordings, each `built` / `new` / `bible`), `setups` (SETUPS.md ids),
`check` (a WORDS.md worry), `takes` (empty until voiced). Built lines (in `config/moments/`) are copied
as they are and never changed here; a change to one is a gameplay change.

## The page

- Publish: the Artifact tool with `file_path` `docs/scripts/board.html`, `files`
  `{"script.json": "docs/scripts/<mission>.json"}` and `capabilities` `{"db": {}}`. To update the
  sheriff's page from another session, pass its URL as `url` (read it first). A new mission is a new
  artifact (no `url`): a copy of `board.html` (the template, also the sheriff's page) with its `<title>` and `<h1>`
  changed. A change to the page's code goes into `board.html` and every copy, and each page is republished.
- Speakers shared between missions (the doctor, the widow) keep one cast id and one voice across pages.
- Takes go in each line's `takes` as `[{"id": "t1", "url": "<asset url>"}]` (audio uploaded to the
  page's asset store: declare `assets` too); the page shows them shuffled, lettered A-D, no
  "recommended". Cast candidates go in `cast[].voice.candidates` the same way.
- What Sean leaves is in the page's database (ArtifactData, the page's URL): `lines/<line id>`
  `{note, pick, at}`, `cast/<cast id>` `{note, pick, at}`, `page/script` `{ok, at}`. Read them with
  `list`; they're his, so don't overwrite them.

## The cast (#836)

Each speaker's voice is designed on fal (ElevenLabs Voice Design, `eleven_ttv_v3`) from his brief,
by a request in `tools/voices/requests/` that runs once on GitHub (`.github/workflows/voices.yml`,
`tools/voices/run.py`, `cast.py`; `FAL_KEY` in the repo's secrets, never in a session). Each
candidate says the same two lines; a second call in Eleven v4 (the takes' model) proves its saved
`voice_id` works. The candidates go to the page's asset store as audio-only mp4 (the store takes no
mp3) and into `cast[].voice.candidates`; Sean picks on the page (`cast/<id>.pick`), and the pick is
copied into `cast[].voice.picked`. Costs: `tools/voices/paid.csv`; terms: `tools/voices/TERMS.md`.
