# The listening bench (#1293)

What the player hears standing somewhere for four game hours (a game hour is 112.5 s), before and
after the overheard exchanges (`src/people/overheard.gd`).

    python3 experiments/overheard/run.py experiments/overheard/results/NAME [--only=bar,table,porch,store,walk,livery,hotel] [--murder]

Each spot is its own headless game on its own port. **Three at once at most**: a valley is about
3.5 GB, and five were killed for memory on a 15 GB workspace. An ordinary evening in saloon B
(20:00 to 24:00, `--no-murder`) stood at the bar, by the back table and on the porch; Main Street by
day stood in the street by the store's walk (08:00 to 12:00), walked end to end (13:00 to 17:00), stood
by the livery's doors (13:00 to 17:00) and by the hotel's porch (15:00 to 19:00; #1325).

`bridge.gd` adds `oh_start`, `oh_stop` (every line said: who, words, metres from you, clock, kind,
clarity; and how long each pair of men stood within 6 m of each other, in game minutes; `ended`, each exchange's end
and why; `why_not`, #1325: each sample, every exchange in its hours and not yet heard whose cast are
all within 15 m of you, the first thing that stops it: `busy:`/`not_free:` a man (resting, walking,
just spoke), `tags:`, `apart`, `if`, `left`, or `could`), `oh_by
PERSON [D]`, `oh_where` (each man's spot and place tags).

In the table, "lines shown" are the subtitles the player gets (before #1293 any line within 45 m;
after it, an overheard line only from clarity 0.12), "within 10 m" what a man stood there would catch.
The results are in `results/` (`table.md` and one JSON a spot).
