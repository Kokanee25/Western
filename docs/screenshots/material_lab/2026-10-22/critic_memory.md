# Blind check, the memory test (2026-10-22)

studio10 (round 6b, the game's exterior woods) with its stains' amounts at nought (as the game
draws it), on the stand at golden hour, four woods on their part's view: saloon_red (wall), floor
(steps), timber (post), fascia (deck_ends). Four sets: 384 texels a metre lossless (RGBA8, the game
today), 384 BC7, 256 BC7, 192 BC7 (`"vram": true`). A fresh agent got the men's sheet and the
centre 640 x 360 of each frame, the four versions of each wood shuffled as A-D (`critic_memory/`,
judged as PNG, kept as JPEG), and was asked to rank them for how well the wood keeps its painted look.

## Unblinded

| Wood | Can't tell apart (best) | First loss | Clear loss |
|---|---|---|---|
| saloon_red | 384 = 384 BC7 | 256 BC7 (fine streaks merge) | 192 BC7 (grain into fewer patches, a light board one smooth band) |
| floor | 384 = 384 BC7 | 256 BC7 (slightly simplified) | 192 BC7 (a stain's ring gone, a small dark block in it) |
| timber | 384 = 384 BC7 | 256 BC7 (knots and flecks a bit softer) | 192 BC7 (a knot gone, flecks flat) |
| fascia | 384 = 384 BC7 | 256 BC7 (light shapes on the step's face simpler) | 192 BC7 (a stain broken up, a small dark block) |

In every wood the identical pair is 384 lossless and 384 BC7 (they differ by at most 4/255). No
colour shift in any (mean RGB within ~0.5), no banding, seams clean in all. Its overall line: the
look holds in every version at normal size; the losses only show zoomed in.

## Memory

| | 384 lossless | 384 BC7 | 256 BC7 | 192 BC7 |
|---|---|---|---|---|
| The stand (measured: `numbers.json` `texture_bytes`, every texture it draws, mipmaps) | 10.76 MB | 3.62 MB | 1.63 MB | 0.96 MB |
| The town's exterior woods (strips + end grain and bare wood, from the files: RGBA8 4 B a texel, BC7 1, x4/3 mipmaps) | 25.7 MB | 6.4 MB | 2.9 MB | 1.6 MB |
