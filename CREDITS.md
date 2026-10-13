# Credits

What Salt Creek uses that it didn't make itself, and under what licence. Everything here may be
redistributed with the game.

## Models and scans

- **Your hand on the revolver** (the painterly test, `assets/held/hand.glb`, `hand_normal.png`,
  `hand_cavity.png`): made by `tools/blender/held_scan_hand.py` from the Smithsonian
  Institution's 3D scan of Leonard Wells Volk's 1860 cast of Abraham Lincoln's right hand
  (National Portrait Gallery, S/NPG.71.6; cast c. 1917), Smithsonian Open Access, **CC0**.
  The scan as fetched is in `assets/held/scan/` (`tools/held/fetch_scan.py`).
- **People's bodies and garments:** MakeHuman v1.2.0 base mesh, targets and assets, **CC0**
  (`tools/blender/fetch_makehuman.py`; nothing of it is kept in the repo but what the people
  pipeline makes from it).
