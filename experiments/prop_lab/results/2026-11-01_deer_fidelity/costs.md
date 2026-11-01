| Version | Triangles | Textures VRAM (BC, mips) | Textures as drawn (RGBA8) | Lavapipe close / across (ms) | Draws |
|---|---|---|---|---|---|
| C0 the game's deer now: 6k, 1k paint, grid shader, no mipmaps, roughness 0.85 | 5,999 | 1.0 MB | 4.0 MB | 17.1 / 16.2 | 1 |
| C1 C0 with mipmaps | 5,999 | 1.3 MB | 5.3 MB | 20.0 / 19.2 | 1 |
| C1f C1 without the min-square coarsening (fixed_squares: a texel a square) | 5,999 | 1.3 MB | 5.3 MB | 19.6 / 18.9 | 1 |
| C1fl C1f lit per pixel, not per texel (global tile_light 0: the wall too) | 5,999 | 1.3 MB | 5.3 MB | 18.5 / 16.7 | 1 |
| C2 C0 drawn by a standard (PBR) material: filtered, mipmapped | 5,999 | 1.3 MB | 5.3 MB | 19.8 / 17.8 | 1 |
| C3 6k, 2k paint, standard material | 5,999 | 5.3 MB | 21.3 MB | 20.0 / 17.9 | 1 |
| C4 C3 + normals baked from the master + Rodin's roughness (2k) | 5,999 | 13.3 MB | 64.0 MB | 20.1 / 18.3 | 1 |
| C5 15k, 2k, baked normals, Rodin's roughness | 14,998 | 13.3 MB | 64.0 MB | 24.3 / 22.7 | 1 |
| C6 the master's 30k, 2k maps (its own normal and roughness) | 29,630 | 13.3 MB | 64.0 MB | 31.0 / 28.1 | 1 |
| C7 C5 with roughness by surface (fur, antler, glass eye, wet nose, varnished plaque) | 14,998 | 13.3 MB | 64.0 MB | 23.0 / 20.8 | 1 |
| Cg2 grid shader kept, 15k and 2k paint, mipmaps | 14,998 | 5.3 MB | 21.3 MB | 24.5 / 23.9 | 1 |
| Ag the master's 30k and 4k paint through the grid shader (no mipmaps, as the game) | 29,630 | 16.0 MB | 64.0 MB | 28.1 / 27.8 | 1 |
| A Rodin's master untouched: 30k, 4k colour, normal, roughness | 29,630 | 53.3 MB | 256.0 MB | 27.8 / 25.8 | 1 |
