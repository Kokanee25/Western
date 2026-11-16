# Gameplay lane: current state

Branch `claude/gameplay-…`. Everything that isn't art, characters or props: missions, people, weapons,
structures, blast, the valley, performance, CI. Replace your lines here at the end of a session; no history
(that goes in `docs/status/` and the PR). Keep under 10 KB (a test fails the build over it). History: `docs/status/`.

## The slice's missions (LAYOUT "src/missions", "src/moments")
- **The sheriff on the road** (#746, build 3698): `-- --world=valley --mission=sheriff`; `StoryState`,
  `HeadGesture`, `Act`. Waiting on Sean: #755.
- **No Law** steps 1-5 done (`ValleyFolk`, `PlayerSeat`, `CardGame`, `NoLawMurder`, `SheriffDies`, `Funeral`;
  `experiments/valley_folk/README.md` "Step 4", "Step 5"). Cody isn't the red shirt (the red shirt, Silas
  Kett, raided Joe's camp; the stranger shot the sheriff, #905; nobody names either yet). The morning after: Earl to the undertaker's, day folk's lines
  by the story's facts (`talk`); the sheriff dies on the doctor's cot (`-- --mission=sheriff_dies`); the story's
  Harlan is unarmed till then. **The funeral** (#868, `-- --world=valley --mission=funeral`): the day after, at
  ten, at the cemetery; nolaw.funeral = attended / distance / missed, nolaw.offer_heard, baron.met; mourners
  are the folk's own men (`borrow`/`give_back`: never built in play). No Law's script still isn't OK'd (#835).
  Open: playtests `docs/playtests/2026-11-13-funeral.md` and step 4's (the funeral's cues, grave, mourners'
  looks, stand-in models; the badge on the dying sheriff, the wife's hands). **Next: the whole mission played end to end on the real clock and its
  seams mended (#876).**
- **No Justice: steps 1-4 done** (#843's plan; each `-- --world=valley --mission=<m>`, bridge `moment <m> set_up=1`).
  Joe is `CompanionBrain` (`--joe`, the lab's `joe=1`, `--joe-tune`); `held`, a scene walks him and he doesn't step out
  of your line. 2: `NoJusticeCamp` (`no_justice`). 3: `NoJusticeHideout` (`no_justice_hideout [--arrive]`), ends
  `nojustice.kett` = holed_up / dead_outside / down_outside / dead_inside, then starts 4: `NoJusticeCabin` (#966,
  `no_justice_cabin [--down]`): kicks add up against the bar; Kett gives up (an OutlawBrain, silent) in the corner;
  Joe's knife and ask; nod / between / gun on either / a shove at Joe / binding Kett = arrest (a card, then Kett bound
  to the jail's door); shake / walking out / silence = revenge (`take_knife`); your ball in him = murder. Facts
  nojustice.ending, answer, joe_trust, camp_trust, joe_saw, bodies, jail. Playtests `docs/playtests/2026-11-1[345]-*.md`.
  **Played whole (#979):** `tests/test_no_justice_whole.gd`, the doctor's to each ending at pace 1, by keys and
  balls; down in the fight, Enter retries it on the slope (`NoJusticeHideout.retry_on_load`, its checkpoint).
  Open: the hideout fight's hard (spotted ~30 m, five guns; difficulty #349 is Sean's); silence at the doctor's
  is a no; the clock's held (only cards move it); the drawn ground hides the shack's floor; the knife is two
  boxes; a kick at 0.9 m can miss; the jail and rides are cards; no line when Kett's jailed (C8 a, Sean's).
  Riding waits on #478. Playtest `docs/playtests/2026-11-15-nojustice-whole.md`.
- Story decisions: #744's latest comments and STORY.md; the story bible is #809.
- **Townsfolk behaving realistically** (#850; `docs/briefs/townsfolk.md`, 11 steps). Done: step 2 the day and the
  book (#870), step 3 the roster as data (#936), **step 4 spots (#957, `SpotChore`)**: a block's `do` at a spot is
  the man's chore (stand, lean, sit, counter, sweep/rug, carry, talk, drink, work), breaks by seed, none held 15 s;
  the broom, rug, sacks, glass, anvil and bench are drawn stand-ins (the prop lab's to make). **Next: step 5,
  reactions in stages.** Open: nobody has seen the chores drawn (the valley's picture under the bridge was broken
  for the playtest, `docs/playtests/2026-11-15-spots.md`; `goto X Z` puts you under its ground); no talk sound; the
  doctor's crossing is 14-15 (the brief's 7-12 waits for the sheriff-dies act); two women share the widow's body;
  step 1's perception leaks wait; the men's build at load ~20 s headless.

## Systems the slice leans on
- **The valley** (#467, `config/valley.json`, `tools/valley/`; LAYOUT "src/world/town_layout.gd"): G1-G7 done,
  heights (#736). **Saloon B's frame is on its lot** (art, #848: `experiments/building_lab/saloon_b/` README).
  No Law's set is still in the yard (no switch built): to move it in, `config/valley_folk.json`'s `set` goes to
  the saloon lot's floor (the walk's top, not the ground: `ValleyFolk.ground` gives the pad under the floor), using
  the spec's own `no_law_table` (under the well) and bar instead of spawning a second set, with ways in by the
  corner door. Payday Night: `SpecBuilding.saw_girder()` with the dancers' weight on the dance floor's boards.
- **Falls from height** done (#759, `Falls`, `config/falls.tres`).
- **Winchester 1873 in the game** (#792; key 6, `Rope`, the rope range at F5's last stop). Waiting on Sean's
  play. Parked: men carrying it (#800).
- **The Colt** (#693 step 1 approved). Harlan's arms are characters' (#693).
- **Gunfight D+** (#633 bugs; difficulty #349 is Sean's).
- **The valley's frame bench** (#865, `docs/reviews/2026-11-valley-bench.md`): `perf_bench --world=valley
  --townsfolk=N [--band=] [--bodies] [--spikes=MS]`, `tools/valley/bench_runs.py`. **The cuts are in (#881; the review's "After the cuts"): the brief's 24 townsfolk fit.** The valley's spec buildings warm their first analysis on a worker
  (`Structure.warm_analysis`; the valley has no FireSystem, so a settle is whole on one frame). `max_bodies`
  65,536. Train past 400 m `Train.distant`. Open: every scene's else is over (~1 ms untimed engine share, the
  train ~0.4 near, RoomLight ~0.2); the outlaws' first cover moves (~120 ms twice at a fight's start, ~21k
  walk casts); the gunfight's people are over (its men at full rate by design).

- **The garment handoff** (#917, #949, #986, #997; LAYOUT "src/bodies"): `GarmentHandoff` and `GloveAct` (bridge
  `glove MAN`) on **our own cloth** (`SolverCloth`/`ClothCore`, #973, `docs/briefs/garment-cloth.md`): his skin
  is its collider (step 2, #986) and **it can meet itself** (step 3, #997: `self_thickness` 2 mm, off in the
  handoff: MetaHuman `--seed=2` never rests; film `experiments/garment_handoff/results/2026-11-16-self/`);
  Jolt fallback. Open: that rest, **the cost**, ~7.2 ms a tick at Sean's drawn off (skin 1.6; itself: its lists), ~6.8
  tossed, ~4.2 settling, budget 0.5 (step 4); skin specks 0.2 s as it leaves (`uncover`); the lab's under-skin
  count is mostly his upper arm under the cuff. Build here:
  `NO_PROXY=localhost,127.0.0.1 no_proxy=localhost,127.0.0.1 cargo build --release` in the plugin, the .so to
  bin/; `apt-get install -y mesa-vulkan-drivers` for films (--real at 960x540).

## Parked until after the slice
coach heist (#840; `experiments/coach_heist/` README) · train (#542 step 7; waiting #553, #557, #601) · trestle (#638, #658) ·
dynamite (#596; #656 waiting; PR #683 open; bundles #647, #682) · masonry step 3 (#667) · horse (#341,
riding #478) · farmhouse (#565, #573, #651) · men dying on the run (#483) · perf step 9 (#401) · Payday
Night floor lab (#745).

- **Resets and places** (#864, the review's R3): a reload wipes the story (`GameReset`; No Law plays again after
  Backspace); a mission's retry starts from the story at its start (`GameReset.retry`, `StoryState.mark_checkpoint`).
  `WorldPlaces`: knocked out in the valley you wake at its doctor's (`bedside`), else the store's walk; the outlaws'
  street spot is the loaded world's.

## Open problems
- **The valley's people tests** (#925, PR #939): three real causes fixed (`HumanBody._spare_rubble`,
  `NoLawMurder._clear_to_head`, `WoundSigns.SMEAR_GAP`), each with a test. Sample a people test's odds by running
  its scene many times in one process, not the suite again.
  Traps: any `intersect_shape(q, N)` on `Layers.WORLD` counts standing members toward N; CI's machine draws
  differently from a workspace's (the same commit fails there and passes here: read the test's own timeline);
  the kit chair's pieces keep collision exceptions to freed bodies (`get_collision_exceptions` on one errors:
  test by `body_test_motion`); two test suites at once collide on the bridge port and `user://`.
  `run_tests.gd -- --only=a,b,c` takes a list; `-- --no-buildings` is the valley without its spec buildings.
- **The nightly checks run the valley and the missions** (#863, `nightly.yml`): soaks of the town and the
  valley; smoke legs for the valley, the sheriff, No Law (`sheriff_dies`) and the coach; a red night opens a
  `nightly red` issue. The orphan rule counts only what isn't held on purpose. Not yet in the valley: the
  goldens and the tour (art's views); the bench is by hand (`perf_bench --world=valley`, below). Rubble growth is by design (DESIGN §8).

## Traps
- A `-s` script can't build a structure (autoloads); probe through a test or the bridge. A `-s` tool must
  `load()` GameQuit, not name it.
- Never measure two games at once; compare alternately. The lab's `--deterministic` keeps the workers'
  merges off: crashes in threaded paths need runs without it.
- After merging main mid-run: `godot --headless --import` before the next game. Never edit
  `outlaw_brain.gd` while `run.py` runs.
- Tests at night in the valley turn the murder off (`-- --no-murder`); a drawn rifle on Main Street sets the
  gang off (use the rope range).
- lavapipe draws ~1 frame a second: a bridge `wait` under a second misses short poses.
- Sight takes a new structure in at its first look (look once at the build).
- The native plugin doesn't build in the cloud workspace while crates.io is blocked (#985): test pure-Rust
  modules with `rustc --test FILE.rs`; Godot tests and films on a runner (LAYOUT "CI", `lab_film.yml`).
- The valley bench: the drawn runs take ~6 min each (80 s of shader compiles). Workspaces' cores differ (one
  read 38% slower at 25): compare against a baseline from the same workspace; the noise is ±0.35.
- Bridge commands: LAYOUT "The dev bridge"; a lab's own commands in `experiments/<lab>/bridge.gd`.
