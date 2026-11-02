# The engine's shape pass (Sean, 2026-11-02: "the wheels are just solid circles and things don't connect")

Before paint, the 2-8-0's shape (`experiments/train_lab/blender/engine.py`), looked at in Blender
(`blender/render_views.py`: its own flat materials, not the game's look) and in the game:

- `blender_before.jpg` / `blender_after.jpg`: side, front three-quarter, rear three-quarter, the gear
  close, top; `blender_after_close.jpg`: the gear and the front three-quarter larger.
- `game_after.jpg`: in the game at golden hour (front, side, gear), and step 3's side view (bottom
  right) for comparison.

What changed:
- **Wheels as cast:** a tyre and flange, the wheel centre's rim, 14 spokes (8 on the pony truck) to
  a hub, the axle's end; on the drivers a crank boss with a web to the hub, the pin out to the
  rods, and a crescent counterweight opposite the pin (was a solid disc in front of the spokes).
- **Rods:** the side rods deep in the middle and tapering to bosses at each pin; the main rod
  tapered with a strap at its big end; the crosshead with its wrist pin and the piston rod; the
  main rods outside the side rods and crank pins (0.72 m); the guides run to a yoke between the
  first two pairs, tied to the frame.
- **The frame:** axle boxes, leaf springs and hangers over each pair; the running boards on
  brackets from the frame in the gaps between the wheels, a valance at their edge.
- **Turned parts (lathed):** the diamond stack with its base flange, the sand and steam domes
  skirted onto the boiler, the bell in its yoke, the whistle and safety valves, the cylinders with
  their covers and glands, the smokebox door and ring with hinge straps, dog and number plate.
- **The cab:** a shallow arched roof overhanging every side with a fascia and a hatch (was a giant
  arch), two framed windows a side with sills and heads, corner posts, the front windows framed.
- **The pilot:** a cowcatcher of slats from the beam down to a point at the rail, its V bottom
  bars and spine, steps on the beam's ends.
- **The headlight:** a hipped top and chimney, a brass rim round the lens, on its bracket.
- Handrails on stanchions, the feed pipe with its check valve, sand pipes, the pony truck's frame
  and radius bar.

12,770 -> 23,916 triangles (the engine; the tender unchanged at 1,164).
