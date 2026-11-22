# Scripts: the voiced lines, one mission a file (#807)

Each mission's lines are data here (`<mission>.json`), and each has its own artifact page (the
listening board), private to Sean, built from that file by `board.html`. Sean reads the script on his
phone, leaves notes, taps **Script OK**; later the same page holds the cast's voice candidates and 3-4
takes under every line, and he picks one.

| Mission | Script | Page | State |
|---|---|---|---|
| The sheriff on the road | `sheriff_road.json` (page `board.html`) | https://claude.ai/artifact/FyzbCopumhRVDAeH7hN1vX | rewritten 2026-11-17 (#1056), waiting on Sean's Script OK |
| No Law | `no_law.json` (page `no_law.html`) | https://claude.ai/artifact/65eAXArWQm5XD5FCEXpYuY | rewritten 2026-11-17 (#1056), waiting on Sean's Script OK |
| No Justice | `no_justice.json` (page `no_justice.html`) | https://claude.ai/artifact/3ojdVLjNoGLCt5qkADSEiW | rewritten 2026-11-17 (#1056), waiting on Sean's Script OK |
| The town (no mission: the runner, the news, the morning after, the uneasy day, the undertaker; townsfolk step 8) | `town.json` (page `town.html`; the game reads its copy `config/town_script.json`, kept identical by `tests/test_town_script.gd`) | https://claude.ai/artifact/JFQURoGdJrUGWHtQp9LfA6 | written 2026-11-22 (#1144), waiting on Sean's Script OK |

## The house style, and the rewrite of 2026-11-17 (#1056)

Every line is written to [`docs/story/DIALOGUE.md`](../story/DIALOGUE.md) (how people talked, the craft,
the AI tells banned by name) and read blind before it goes to Sean (its last section; two rounds at
most). The three scripts were rewritten that way on 2026-11-17, as one story:

- **Callbacks:** a line's `when` names the StoryState fact it waits on, so the town remembers what you
  did (`docs/story/SETUPS.md` part E). Each script's `facts` list says which facts the game sets and
  which gameplay has to add.
- **The scripts lead the game.** The game's lines (`config/moments/`) are copies of these. A wording
  with status `built` is what the game says now; `new` is what it should say. Every difference is in
  [`CHANGES.md`](CHANGES.md) (file, key, old and new words, the new lines, the facts to add), for a
  gameplay session once Sean has tapped Script OK. A story session never edits `config/moments/`.
- **New fields:** `was` (a line's wordings before the rewrite), `added` (a line that's new), a line's
  `note` (the answer to Sean's note on the page, where he left one), and at the top `facts` and `kept`
  (lines the blind reader flagged that stay because they're Sean's own or fixed in the game, each
  with a period way to say it if he wants one).
- **No Law's page shows the sheriff's last day** (scene `day2`) as a copy of `sheriff_road.json`'s, so Sean reads the
  oath, the nod or shake and "That's not the way this works, son." with the rest of the mission. The lines live in
  the sheriff's file: change them there and copy the scene across again.
- **Script OK after a rewrite:** a script's `rewritten_at` (a UTC time) makes the page ignore an OK tapped before it,
  so Sean's old tap doesn't count for new words and his row isn't touched. Set it whenever the words change after an OK.
- **The sheriff's page holds takes** made on an unmerged voices branch (#846), on the old wording. A
  republish keeps a line's takes only where its words still stand (the page's `script.json` is the
  repo's file with those takes and the cast's fixed voices carried over); a re-worded line's takes are
  dropped from the page.

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
