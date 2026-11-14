# Brief: props that scale (Sean, 2026-10-24, issue #357)

Sean: "I just want to make sure we can have a real cluttered street." On how: "Ya!"

## Why

The kit's props (`PropKit`, `KitProp`; `assets/props/kit/`) are built of members, as the buildings
are, and each member is three nodes: its body (`StructureMember`, a StaticBody3D), its mesh and its
collision shape. A freight wagon from the prop factory is ~96 members, about 300 nodes. The calm
street sits near `tests/test_perf.gd`'s guards (visible meshes, nodes), and one more freight
wagon in the street's empty lot (PR #332) tipped it over. The guards are our own tripwire; the
real limits are the frame (60 fps on one 3.25 GHz core, CLAUDE.md's frame budget) and draw calls.
The prop factory (#338) keeps adding clutter and street session 3 (#327) places it, so the cost of
a prop has to drop before the street fills.

## The goal

**Four times today's props on the calm street, inside the frame budget**, every prop still
breaking, burning and being knocked about as it does now. The guards drop or stay put; they don't
go up.

## The measure

- `tools/perf_bench.gd --clutter=4` (new): the street with three more of every kit prop it has,
  laid out in the street's open ground in view of the bench's camera (`PropClutter`), against
  `config/frame_budget.tres` (calm, fire, wall), headless and `--render` (lavapipe's draw calls
  and render CPU).
- `tests/test_perf.gd`'s counts on today's street (nodes, visible meshes), and a clutter test:
  4x the props within the same guards.
- A probe per prop: members, nodes, meshes, visible meshes, bodies (`build/probe_props.gd`, a
  scratch copy of what the bench's census does, by kit id).

## What to try (one change at a time, each measured)

1. **Members at rest without their own nodes.** A batched member's mesh is hidden anyway (its
   structure draws it in a batch); its collision can be a shape on the member's own body (Godot's
   shape owners, as `Ground` does since #332) instead of a CollisionShape3D node. At rest a member
   is one node; the moment anything happens to it (unbatched: a hole, heat, breaking, going loose)
   its mesh and shape nodes are made again exactly as built and every rule after works as now.
   The member stays the collider (ballistics, blows, footings and Fittings ask for it by body).
   The issue's "one body per prop" (members as shapes on one body) would make every hit ask which
   shape it was; this keeps the body per member and drops the two nodes, ~3x fewer nodes.
2. **Batched across props.** A resting prop's batches (one a material, its dress, its far-lamp
   shadow) joined with its neighbours' in cells of the street (`PropBatch`), so a street of
   barrels and crates is a handful of draws, not three a prop; a prop leaves its cell's batch when
   it's touched, as a member leaves its prop's.
3. **Asleep at rest.** A prop with nothing to do (footed, no rubble, nobody on it, nothing leaking)
   costs nothing a frame; its checks (the footing every 0.25 s) run from a shared round-robin, or
   on the events that change them.
4. **Far away** (only if 1–3 aren't enough): beyond a distance, drawn merged with no collision.

## What done looks like

- The clutter run (`--clutter=4`) inside the frame budget on calm, fire and wall; the guards on
  today's street the same or lower.
- The kit's tests and the prop lab's bench pass unchanged: a member shot, kicked, burnt, blown and
  dropped behaves exactly as before (the dormant member made real first).
- What works promoted into the kit and `Structure` (`docs/PARTS.md`, `docs/LAYOUT.md`).
- The freight wagon back in the empty lot (`StreetDressing._vacant_lot`, art's file, once #332 has
  merged it).

## How it's judged

Numbers, before and after each change: nodes, visible meshes, draw calls, and the frame's parts
against the budget (`perf_bench`'s `budget` line), today's street and the 4x street.
