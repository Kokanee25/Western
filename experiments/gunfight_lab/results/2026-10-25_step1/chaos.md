# The chaos test's flake, reproduced and found (more-cores step 1, 2026-10-25)

`test_chaos`'s `test_the_same_seed_gives_the_same_chaos` failed twice on CI on
`claude/perf-threading` (a townsperson's wound count differing) and passed here. Reproduced with
`chaos_load.sh TAG`: the chaos digest (`--only=test_write_a_digest_when_asked`, seed 77) five times
in fresh Godots, `worker_pool/max_threads=1` (as the test runs it), with four busy loops loading
this workspace's four cores. Each run's digest hashed; the broken members counted.

| Code | Digests (md5, 8) | Members broken |
|---|---|---|
| before (`claude/perf-threading`) | c411e615 326db100 0d769355 ccd86b0a 342ab31e | 743 743 739 742 745 |
| count budgets only | e286d8f1 b6505d60 518ac84d fdcc34e5 0c8c9a57 | 745 741 744 744 747 |
| + voxel swap and smoke on fixed frames | cb615856 ddc3bf01 f54691f4 adc5c3e8 f54691f4 | 743 745 744 744 744 |
| GlassProp's dice only (no count budgets) | ffee5524 97d1e2f8 90ffa088 72b91488 0d769355 | 740 745 750 742 739 |
| **all of commit 1** | **9cb408ca x5** | **741 x5** |

Two causes, both needed:

1. **The wall-clock budgets** (#375's `settle(budget_ms)`, `FireSystem._check_loads`, the batches'
   rebuild): on a loaded machine a blast's collapse got less far on each tick. Under
   `World.deterministic` they're counts (`WorkBudget`: members analysed, batches built).
2. **Godot's global dice in GlassProp:** its first support check was put at `randf() *
   CHECK_EVERY`, and the chaos test never seeds the global RNG. Found by a per-tick trace (every
   rigid body, ticks 89-92): the first difference, the tick after the big blast at the piano
   (411 members, ~560 new bodies), was `Saloon/Props/WallSconce22` coming off its wall a frame
   sooner in one run than another. Now its phase is by its name.

The voxel meshes (the plugin's own worker threads, collected when done) and the smoke field's
async step were made to land on fixed frames under `deterministic` too; on their own they didn't
end it, but they're the same kind of thing (a result the machine's load times).
