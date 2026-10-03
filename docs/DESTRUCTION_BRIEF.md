# Voxel destruction in Salt Creek: the brief for the gameplay session

Sean's decision, 2026-10-03: the game's identity is real destruction. Shotgun blasts that bite
through a wall, dynamite that tears chunks off lumber and leaves a crater, bodies that react and
come apart. This is built **inside the Godot game** (Kokanee25/Western) as a native plugin first;
a custom engine is the fallback only if Godot can't carry it at the frame budget.

This file lives in the Western repo (copied from Pixel-factory, 2026-10-03);
start every destruction session with Part 1.

---

## Part 1: the starting prompt

```
Read CLAUDE.md, then docs/DESTRUCTION_BRIEF.md. You are the gameplay session, on a branch named
claude/gameplay-voxel-<step>-<id>. Work the brief's steps in order, one step per merge, and stop
at each gate to report to Sean in plain English with what he should try on his PC.
Kokanee25/Pixel-factory is read-only reference for the volume format, voxeliser and renderer
(src/volume.rs, src/sdf.rs, src/assets/gltf_man.rs, NOTES.md). Never push there.
```

## Part 2: the rules (CLAUDE.md's, restated for this work)

1. **Two sessions, your own branch.** The art session is live in the same repo. Never edit its
   files: `src/render/`, `src/bodies/shaders/`, every `*.gdshader`, `src/art/`, `src/props/`,
   `assets/people/`, `assets/textures/`, `tools/paint/`, `tools/textures/`, `tools/characters/`,
   `tools/style/`, `docs/concept/`, `docs/screenshots/`. If a step needs a line in one of them
   (a material for carved faces, say), name the file and the line in the commit message and the
   status entry, and ask Sean first if it's more than a line or two.
2. **Pull `main` before starting and before merging** (`git fetch origin main && git merge
   origin/main`), run all tests (`godot --headless --fixed-fps 60 -s res://tests/run_tests.gd`),
   merge small and often, and after merging confirm the "Test and build" run on `main` is green
   and give Sean the build number. A red main is fixed before anything else.
3. **Godot 4.7.2 is pinned** in `.github/workflows/build.yml`. The plugin targets that exact
   extension API. Don't bump Godot for this work.
4. **Desktop only.** Sean tests on a Shadow cloud PC (Windows), never the browser. The plugin
   builds for Windows, Linux and Mac in CI; the web export may fail to load the plugin and that
   is acceptable (keep the web build from breaking CI: skip the plugin there, don't remove the
   export unless Sean says so).
5. **Keep every existing rule working.** Ballistics, penetration by thickness, the structural
   analysis, fire, the physiology and the 287 tests are the game. Voxel damage feeds them (how
   much section is gone, where a channel went) rather than replacing them. A step that breaks a
   test fixes it or explains, never deletes or weakens the test.
6. **Tunable numbers in resources** (`config/*.tres`), not code; seedable randomness; simulation
   testable headless. Voxel work that can't be tested without a GPU says so.
7. **Update the Status at the end of CLAUDE.md** at the end of every session, in date order, your
   entries only; tell Sean exactly what to try in each build (docs/BUILD_NOTES.md).
8. **No keys in the repo. No third-party assets with licences that forbid redistribution.**
9. **Performance is a rule, not a polish step.** The game is pinned on one core. Every carve,
   re-mesh and collision rebuild runs on the plugin's own threads; the main thread only swaps
   results. Measure with `tools/perf_bench.gd` and F3's frame split before and after every step,
   and put the numbers in the status entry. Sean sends his own F3 numbers from Shadow.
10. **Model choice:** Fable for designing each step's architecture and for any bug Opus has failed
    on twice; Opus for the steady building in between.

## Part 3: the steps and their gates

**Step 1: the foundation.** A Rust GDExtension (gdext bindings; check they support Godot 4.7.2's
extension API before writing a line, else C++ with godot-cpp) under `addons/saltcreek_native/`,
with a CI matrix building Windows, Linux and Mac artifacts that the export step picks up. One
exported class that proves the round trip (a `NativeBench` node that fills a buffer on a worker
thread and hands it back). Gate: the plugin loads in a Windows export on Shadow; CI green.

**Step 2: a wall that takes a shotgun blast.** Each `StructureMember` (or the ones in a test
wall first) gets a brick voxel volume at 64–128 cubes a metre from its box and material. A charge
carves a ragged bite from the pellets' pattern; pellets with energy left carry on; carved voxels
are thrown as splinters (DEBRIS layer); the member is re-meshed on a worker thread (blocky faces,
merged, on the texel-grid material, holes letting light through as `member_holes` does now),
collision rebuilt, and `StructureMember` told the remaining section so `StructuralAnalysis` and
`settle()` work unchanged. Revolver balls carve a channel the ball's size. Tests: a known charge
removes a known volume; a wall with 60 % of a stud gone falls when loaded; a ball's channel lets a
ray through. Gate: Sean fires a charge into the store's wall on Shadow and reports F3 before and
after; the frame budget decides whether Godot carries this.

**Step 3: dynamite and the ground.** `Blast.detonate()` carves by overpressure: chunks torn off
members as rigid voxel pieces with their texture; the street's ground gets a volume near the
blast and a crater that stays (clods thrown as debris); scorch written into the voxels. Saved in
`to_dict()` as differences, as holes are now.

**Step 4: bodies.** One anatomy volume per body type in rest space (skin, fat, muscle groups,
skeleton, organs, arteries as material IDs, from `config/anatomy.json`); a hit carves a channel
or cavity into a sparse damage mask, the skinned body drops voxels inside it so the wound stays
put through animation and exposes the layers in order; exits carved from the far side; wound
edges blood-coated; a big hit cuts a limb as its own piece carrying its slice. Plugs into
`Physiology` as `Anatomy.trace()` does now (bleeds, bones, organs by what the channel crossed).
Gate: Sean's verdict against the current wound openings, side by side, and the frame budget
with ten people.

**After step 2's gate, if Godot can't carry it:** stop, report, and the custom engine is built on
Pixel-factory's renderer with these carving rules moved over unchanged.

## Part 4: what to report at every gate

Plain English for Sean's phone: what's in the build and the build number, exactly what to do on
Shadow to see it (where to stand, what to shoot), the frame numbers before and after, what's
missing, and the honest risk for the next step.

## Part 5: characters are layers (Sean, 2026-10-03)

- **Every character is built in layers, no exceptions:** the body first (the anatomy volume in
  step 4; the MakeHuman body today), then each garment as its own piece over it (shirt,
  trousers, vest, coat, boots), the hat and a gun belt as their own pieces. A piece can be hidden,
  dropped or taken, as in Skyrim. Wounds carve the garment over the wound as well as the body.
- The MakeHuman pipeline already does this (`tools/blender/clothes.py`, `BodyMesh`'s hat). The
  Tripo route does not yet: the stranger's hat, coat and boots are baked into one skin. The art
  session's character step must produce layered output (paint and model him bare-headed in his
  shirt, with the coat and hat as separate pieces, or cut them apart after); `"whole": true` in
  a person's JSON is a stopgap, not the destination.
- **A hat shot off:** a thin hitbox on the head for the hat; a ball through it leaves a hole and
  releases the hat as a rigid body (DEBRIS layer) with the ball's push; it is also a deed, the
  loudest near miss there is: fear jumps, he says something (`DeedWatch`/`Relations`). Cheap on
  layered characters; do it with step 2's hooks. A hat on the floor can be picked up later.
