# Inside bleeding, and packing that can hold an artery (fixes 5 and 6)

**Before** (the baseline):

- **Packing never stopped an artery.** Pressure keeps a quarter of a bleed
  (`pressure_factor`), but a bleed too fast to clot on its own was marked as one that never clots
  when it opened. Packing only slowed it: a packed femoral still killed in 18 min. In the swine
  femoral model, gauze pressed for three minutes stops the bleeding in a third to seven in ten
  (README, source 13).
- **A ball's heart, aorta, vena cava, iliac, liver and spleen bled "outside",** so packing slowed
  them (a packed heart lived 36 s instead of 32, a packed liver 27 min instead of 7). That blood goes
  into the chest and belly, where no pressure from outside reaches it.

**The change:**

- `tools/anatomy/build_anatomy.py` marks those nine structures `inside`: the heart, aorta, vena
  cava, abdominal aorta and vena cava, the iliacs, liver and spleen. `config/anatomy.json` is
  regenerated.
- A ball through one opens an `internal` bleed. The game's tending, the belt and the lab's packing
  already skip internal bleeds, and no jet shows outside. The wound track's own flesh bleeding still
  shows.
- A bleed too fast to clot, once pressed or packed, rolls once whether the packing holds
  (`PhysiologyTuning.packing_holds`, 0.5). If it holds, it clots under the pressure as a cut does.
- The roll comes from `Physiology.rng`, which `HumanBody` seeds from his `rng_seed`, hashed:
  people's seeds run 501, 502…, and Godot's first draws from consecutive seeds agree. With
  consecutive seeds 13 of 40 held; with hashed seeds, 17.
- Lungs and kidneys stay outside bleeds that clot: a single holed lung usually lives (README,
  source 14).

**Measured** (`run.py --vessels`, `vessels_before.md` / `vessels_after.md`; every vessel cut alone,
packed at 30 s, 40 seeds for the packing's roll):

| vessel | packed, before | packed, after: lives (40 seeds) | when it holds | when it doesn't |
|---|---|---|---|---|
| heart, aortas, venae cavae, iliacs, liver, spleen | slowed a little | n/a: packing can't reach it | | dies as untreated |
| carotid, subclavian, femoral, axillary, jugular | dead in 11–22 min | **42%** | lives, ~0.6–1.1 L lost | dies as before |
| brachial, popliteal, femoral vein | dead in 31–37 min | **42%** | lives, ~0.4 L lost | dies as before |
| radial, ulnar, tibial, kidney, lung | clot; live | 100% | | |

The shots (`run.py`, all 160 runs against fix 1's; the outlaw at 5 m shown, and every man the same):

| shot | packed 30 s, before → after | packed + doctor 10 min, before → after |
|---|---|---|
| thigh (femoral artery + vein) | dead 11:13 → lives (−1.1 L) | lives (−2.3 L) → lives (−1.1 L) |
| neck (carotid + jugular) | dead 6:42 → lives (−1.6 L) | dead first → lives |
| upper arm (brachial) | dead 31:18 → lives (−0.4 L) | lives (−1.1 L) → lives (−0.4 L) |
| chest (heart) | dead 33 s → dead 31 s | dead first, as before |
| belly (abdominal aorta) | dead 1:21 → dead 43 s | dead first, as before |
| shotgun, belly (liver) at 15 m | dead 25:43 → dead 6:49 | lives → dead before the doctor |

- A shot scenario runs one seed (the lab's), and that seed's roll held. The vessel table gives the
  odds.
- Untreated deaths are unchanged everywhere.
