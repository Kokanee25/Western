# The look panel's settings (art session → gameplay session)

For `docs/briefs/review-tools.md`, gameplay item 1 (the live look panel) and art item 1. Every
setting that matters for the look, grouped as the panel should group them: where it lives, its
value today, a sensible slider range, and one line on what it does. Ranges are the span worth
dragging through, not hard limits. "Default" means the value in the file named; a preset Sean
exports should carry the keys in the first column, and `--look=FILE` / `tools/apply_look.gd`
should set them the same way the game does (the "how to set" column: most are a property on a
node or resource the DayCycle already applies every tick, so setting the config and letting it
run is enough; shader uniforms are set with `set_shader_parameter` on the material named).

When Sean sends a preset: the art session renders both judge shots with it
(`tools/screenshots.gd --look=FILE` once gameplay adds it), judges it, and bakes his values
into the defaults in the same files.

Written 2026-10-04 from the files as they are; when a default here drifts from the file, the
file wins.

## Sun & sky

| Key | Where | Default | Range | What it does |
|---|---|---|---|---|
| `sun_max_energy` | `config/day_cycle.tres` (DayCycleConfig) | 1.6 | 0.5–3 | The sun's light at full height; scaled down as it nears the horizon. |
| `sun_tilt_degrees` | DayCycleConfig | 35 | 10–70 | How far the sun's arc leans from overhead (lower = a lower sun all day, longer shadows). |
| `sun_azimuth_degrees` | DayCycleConfig | 20 | −45–45 | The arc turned round the vertical: at 20 the sun sets south of west and lights the north side's porches at golden hour. |
| `day_bias` | DayCycleConfig | 0.1 | 0–0.3 | Shifts the sun's path so days are a little longer than nights. |
| `sun_color` | DayCycleConfig, a Gradient over the day (0 = midnight) | see the .tres | per stop | The sun's colour through the day: deep orange at dawn and dusk, near white at noon. A panel can expose the dawn/noon/dusk stops as three colour pickers. |
| `sky_top` / `sky_horizon` | DayCycleConfig, Gradients | see the .tres | per stop | The sky's zenith and horizon colours through the day; the sky shader, the ambient and the fog all read them. The late-afternoon top (stop 0.7–0.755) is a pale grey-blue (the painting's upper sky, L* ~61). |
| `sun_size` | `src/world/sky.gdshader` (the scene's sky material) | 0.035 | 0.01–0.08 | The sun disc's size, as a fraction of the sky. |
| `low_sun_dim` | sky.gdshader | 0.45 | 0–0.8 | How much the sky away from a low sun darkens (the painting's deep blue opposite the sunset). |
| `cloud_cover` | sky.gdshader | 0.46 | 0–0.9 | Share of sky under cloud. |
| `cloud_scale` | sky.gdshader | 2.6 | 1–6 | Size of the cloud heaps (bigger = fewer, larger). |
| `cloud_ragged` | sky.gdshader | 0.32 | 0–0.6 | How much a finer noise eats the clouds' edges. |
| `cloud_tones` | sky.gdshader | 0 | 0–1 | 0 = clouds shaded smoothly; 1 = the three painted tones (cream top, warm body, grey-violet underside) as hard bands. |
| `cloud_drift_speed` | DayCycleConfig | 0.002 | 0–0.02 | How fast the clouds slide across the street (per second; sent to the sky in ~2 s steps so the sky isn't re-lit every frame). |
| `sky_squares` | sky.gdshader | 0 | 0–200 | The sky cut into squares, cells per radian (100 ≈ 7 px at 1280 wide); 0 = smooth (the painting's sky is soft). |
| `sky_mosaic` | sky.gdshader | 0 | 0–1 | A shade's worth of mosaic across those squares. |
| `fog_sun_scatter` | `scenes/test_street.tscn` Environment | 0.05 | 0–0.5 | How much the sun's colour scatters into the haze when you look toward it. |
| `light_volumetric_fog_energy` (sun) | the scene's Sun DirectionalLight3D | 0.35 | 0–1.5 | How much the sun lights the volumetric haze (god rays down the street). |

## Night & moon

| Key | Where | Default | Range | What it does |
|---|---|---|---|---|
| `moon_max_energy` | DayCycleConfig | 0.45 | 0–1.2 | The moon's light when it's up. |
| `moon_color` | DayCycleConfig | (0.55, 0.65, 1.0) | colour | The moonlight's colour. |
| `moon_tilt_degrees` | DayCycleConfig | 78 | 35–85 | The moon's own arc: at 78 it crosses low (~12° up over +Z) and stands in the saloon's doorway near midnight. 35 = the sun's arc (the old high moon). |
| `star_strength` | DayCycleConfig | 1.2 | 0–3 | Brightness of the stars (faded out by daylight). |
| `ambient_energy_night` | DayCycleConfig | 0.7 | 0–3 | Ambient light at night in the open (lerps to `ambient_energy_day` with daylight). |
| `interior_ambient_night` | DayCycleConfig | 0.04 | 0–0.5 | Ambient inside buildings at night (their interior probes; the saloon overrides it with `night_ambient`). |
| `night_ambient` (saloon) | `src/structures/saloon_building.gd` (FalseFrontBuilding export) | 0.035 | 0–0.3 | The saloon's own fill at night: the painting's room is dark and lit by its lamps. Other buildings: `false_front_building.gd` default 0.04. |
| `exposure_night` | DayCycleConfig | 0.72 | 0.4–1.2 | The eye's exposure at night (the saloon painting's median L* is 12). |
| sky night gradient stops | DayCycleConfig `sky_top`/`sky_horizon` stops 0, 0.2, 0.83, 1 | see the .tres | per stop | The night sky's colours (deep blue-black). |
| `night_tint` | `src/art/backdrop.gdshader` | (0.1, 0.11, 0.17) | colour | What the painted backdrop's land turns at night. |

## Lamps

Every oil lamp is an `OilLamp` (`src/world/oil_lamp.gd`); the dressing sets each one's numbers
when it's built, so a panel slider is best applied as a multiplier over all lamps in a group
(street lanterns, saloon sconces, back-bar lamps, hung lamps, the shot's table lamp) rather than
per lamp.

| Key | Where | Default | Range | What it does |
|---|---|---|---|---|
| `energy` | OilLamp export | 1.4 (class); street lanterns 0.9, saloon sconces 0.6, back-bar lamps 0.45, hung lamps 0.6, the shot's table lamp 1.5 | 0–3 | The lamp's light. The bar side's lamps were raised ×1.5 so the back bar glows (§10.1). |
| `light_range` | OilLamp export | 7 (class); lanterns 6, back-bar 3.5, hung 5, table lamp 7 | 1–12 m | How far its light reaches. |
| `haze` | OilLamp export | 1.2; lanterns 1.6, table lamp 0.4 | 0–3 | How much the lamp lights the room's haze (the glow in the air round it). |
| `casts_shadows` | OilLamp export | true; wall lanterns false | on/off | Whether the lamp throws shadows (lanterns' own caps cut hard wedges out of the fronts). |
| `lit_from_hour` / `lit_until_hour` | OilLamp export | 18 / 7 | 0–24 | When lamps are lit. |
| `bloom` | `src/props/chimney_glass.gdshader` (per lamp) | 3.0 | 0–6 | How far over display white the chimney glass is drawn round the flame: the only thing that blooms besides the moon. |
| `squares_per_m` | chimney_glass.gdshader | 110 | 40–250 | The chimney's squares. |
| lamp light colour | `oil_lamp.gd` | (1, 0.74, 0.48) | colour | The warm golden lamp colour. |
| `FILL_ENERGY` | `src/weapons/weapon_viewmodel.gd` (HeldFill) | 0.55 | 0–1.5 | The warm fill on the gun and hand only (the painting lights the gun's side with the sun behind it); scaled by daylight. |

## Fog & haze

| Key | Where | Default | Range | What it does |
|---|---|---|---|---|
| `fog_density` | DayCycleConfig (applied to the Environment every tick) | 0.008 | 0–0.03 | Distance haze down the street. |
| `fog_aerial_perspective` | test_street.tscn Environment | 0.7 | 0–1 | How much far things take the sky's colour rather than the fog's. |
| `fog_low_sun_level` | DayCycleConfig | 0.8 | 0–1.5 | How bright the haze's gold is with the sun low (beside the horizon's colour). |
| `fog_light_color` | Environment (DayCycle overwrites it from the sky's colours each tick) | computed | colour | The haze's colour at noon; at golden hour it's the horizon/sun gold × `fog_low_sun_level`. |
| `volumetric_fog_density` | DayCycleConfig | 0.012 | 0–0.05 | The volumetric haze lamps and the sun light (Forward+ only). |
| `volumetric_fog_albedo` | Environment | (0.8, 0.75, 0.68) | colour | The haze's own colour. |
| `volumetric_fog_length` | Environment | 48 | 16–128 m | How far the volumetric haze is computed. |
| `volumetric_fog_ambient_inject` | Environment | 0.15 | 0–1 | How much ambient light the haze picks up. |
| `room_haze` (saloon) | saloon_building.gd (FalseFrontBuilding export) | 0.012 | 0–0.05 | Tobacco smoke in the saloon (a FogVolume the room's size, denser under the roof). |
| `haze` / `haze_scale` | backdrop.gdshader | 0.2 / 1.0 | 0–1 / 0–3 | How much of the fog's colour lies over the painted backdrop's far, mid and near rings; `haze_scale` follows the scene's fog density. |

## Glow

| Key | Where | Default | Range | What it does |
|---|---|---|---|---|
| `glow_intensity` | Environment | 0.8 | 0–2 | Strength of the glow off true emitters (chimney glass, the moon). |
| `glow_hdr_threshold` | Environment | 1.7 | 1–3 | Only pixels brighter than this bloom; at 1 lamp-lit things bloom too and veil the frame. |
| `glow_bloom` | Environment | 0 | 0–0.3 | A share of everything blooming; any of it veils the whole frame (§10.1). |
| `glow_levels/3`, `glow_levels/5` | Environment | 1.0, 0.8 | 0–1 each | Which blur sizes the glow uses (3 = tight halo, 5 = wide). |
| `glow_blend_mode` | Environment | 1 (screen) | additive/screen/softlight | How the glow is laid over the frame. |

## Grade

| Key | Where | Default | Range | What it does |
|---|---|---|---|---|
| `tonemap_exposure` | Environment (DayCycle sets it: 1 at noon, `exposure_low_sun` with the sun low, `exposure_night` at night) | 1.0 / 0.85 / 0.72 | 0.4–1.5 | The eye's exposure. ACES tonemap (`tonemap_mode` 3). |
| `exposure_low_sun` | DayCycleConfig | 0.85 | 0.4–1.2 | Exposure at golden hour. |
| `adjustment_contrast` | Environment | 1.15 | 0.8–1.5 | Contrast after the tonemap. |
| `adjustment_saturation` | Environment | 1.12 | 0.6–1.5 | Saturation after the tonemap. |
| `ambient_energy_day` | DayCycleConfig | 1.0 | 0–2 | Ambient light at noon. |
| `ambient_low_sun` | DayCycleConfig | 0.6 | 0–1 | Ambient cut to this share of the day's with the sun low (deep golden-hour shadows). |
| `ambient_sky_low_sun` | DayCycleConfig | 0.5 | 0–1 | Share of that ambient from the sky (the rest is the warm horizon colour, so shadows are warm brown not blue). |
| `ambient_warm_level` | DayCycleConfig | 0.45 | 0–1 | How bright the warm bounce colour is beside the horizon's. |
| `interior_ambient_day` | DayCycleConfig | 0.45 | 0–1 | Ambient inside buildings by day. |
| `ssao_radius` / `ssao_intensity` | Environment | 0.8 / 1.6 | 0.2–2 / 0–4 | Screen-space ambient occlusion in corners and under things. |
| `shade_tint` | backdrop.gdshader | (0.88, 0.6, 0.5) | colour | The backdrop's shadow-side colour with the sun low. |

## Ground

| Key | Where | Default | Range | What it does |
|---|---|---|---|---|
| `sun_direct` | `src/world/ground.gdshader` (the ground's material) | 0.7 | 0–1.5 | The sun's direct light on the ground, scaled (the painting's sunlit road is barely brighter than its shadowed road). |
| `sky_fill` | ground.gdshader | 0.15 | 0–0.5 | A share of the sun's light, unshadowed and half way to grey, on all the open ground (the painting's road is lit ochre in the fronts' shadows too). |
| `sun_wrap` | ground.gdshader | 0 | 0–1 | Wraps the sun's light round the ground's facing (blew the sunlit side out at 0.5; left at 0). |
| `dirt_color` / `dirt_dark` / `scrub_color` / `sage_color` | ground.gdshader | (0.6, 0.47, 0.33) / (0.4, 0.3, 0.21) / (0.62, 0.52, 0.38) / (0.52, 0.49, 0.35) | colours | The code-painted dirt's colours where the factory's tiles aren't in use; the tints the road tiles sit on. |
| `road` tile grade | `tools/textures/materials.json` → `reduce.py` (`lightness` 1.3, `contrast`, `chroma`, `hue`) | 1.3 / 1 / 1 / 0 | 0.6–1.6 / 0.5–3 / 0.5–2 / −30–30° | The road tile's grade in Lab; not live (re-cut by `reduce.py`), so a panel slider for it would be a tint multiplier on the ground material. |
| `groove` / `churn` darkening | ground.gdshader (constants, 0.5 / 0.2) | 0.5 / 0.2 | 0–1 | How dark the wheel ruts' bottoms and the churned middle draw. |

## People's paint

`HumanBody.paint_look` (`src/bodies/human_body.gd`, a static dict applied to every painted
person's `body_skin` material); the panel can set the dict and call the bodies to re-apply.

| Key | Where | Default | Range | What it does |
|---|---|---|---|---|
| `paint_gain` | paint_look | 2.2 | 0.5–5 | Scene light × this on painted parts (the model paints him in even mid light; the lamp has to bring him to the painting's). |
| `paint_ambient` | paint_look | 1.0 | 0–1 | How much of the scene's ambient reaches painted parts. |
| `paint_wrap` | paint_look | 0.3 | 0–1 | Light wrapped round him (the shading is painted in). |
| `paint_limit` | paint_look | 4.0 | 1–6 | No light makes him brighter than this × painted. |
| `self_lit` | paint_look | 0 | 0–1 | Share of him that glows as painted, light and all (the old look used 0.35). |
| `light_steps` | paint_look (and `body_skin.gdshaderinc` for unpainted people, 4) | 0 | 0–8 | Lambert stepped into this many tones (0 = smooth). |
| `paint_contrast` | body_skin.gdshaderinc | 1.08 | 0.8–1.5 | Contrast on the painted texture. |
| `roughness_value` | body_skin.gdshaderinc | 0.8 | 0.3–1 | Skin and cloth roughness (a hard glint only in the wet eyes). |
| `square_texels` | body_skin.gdshaderinc (per shape, from the fit) | 1–3 | 1–4 | How many texels the shader lights as one square (the face's 3×3). |
| `use_paint` | HumanBody | on for the shot's man, off for the townsfolk | on/off | Painted textures, or code-painted cloth of his own colours. |

## Squares

| Key | Where | Default | Range | What it does |
|---|---|---|---|---|
| `texels_per_meter` | `Settings.texels_per_meter` (F7; `PixelArt.DENSITY_PRESETS` 32/24/16/64) | 32 | 16–64 | The world's texel density: the painting's squares are ~32 a metre. |
| `min_square_px` | shader global, set by `Settings` (`MIN_SQUARE_PX`) | 2 | 0–8 | The smallest square a texel may draw on screen, in render pixels: far surfaces stay chunky; 0 = off. |
| `tile_look` | `Settings.tile_look` (P) | square | off / square / ragged | Light per texel (each tile one colour), ragged tile edges, or smooth light. |
| `TILE_RAGGED` | Settings | 0.3 | 0–0.6 | How far a ragged tile's centre wanders, in tiles. |
| `tile_gradient` | shader global (`Settings.FINISH_GRADIENT` when the finish is on) | 0 (finish off) | 0–1 | A faint gradient of the real light across each tile. |
| `finish` / `FINISH_SOFTEN` | Settings (`pixel_screen.gdshader` `finish_soften`) | off / 0.5 | on/off, 0–1 | Softens a render pixel on hard block edges; off since the screen mosaic. |
| `mosaic` | `Settings.mosaic` (O) | on | on/off | The screen mosaic (`DepthMosaic` on the game camera). |
| `MOSAIC_K` (`block_k`) | Settings / `DepthMosaic` tuning | 5 | 2–10 | Block size in render px × metres of depth (3–4 px on a man across a table, 2 px far off). |
| `MOSAIC_STEPS` (`steps`) | Settings / DepthMosaic | 14 | 0–32 | Tones the light is posterised into (0 = none). |
| `min_block` / `max_block` | DepthMosaic `KNOB_DEFAULTS` | 2 / 4 | 1–12 | The block size's floor and ceiling in render pixels. |
| `depth_power` | DepthMosaic | 1 (0.5 under quantise once) | 0.25–1.5 | Block size as `block_k / depth^power`; 0.5 = nearly one size near and far. |
| `soft` | DepthMosaic | 0 (0.5 under quantise once) | 0–1 | Pixels of blend across block edges. |
| `average` | DepthMosaic | 0 (1 under quantise once) | 0–1 | A block as the mean of its own band's pixels rather than the sample at its centre. |
| `dark_weight` | DepthMosaic | 0 (2 under quantise once) | 0–6 | The darker pixels weigh more in that mean, so shadow edges keep the shadow. |
| `sat_steps` / `hue_steps` | DepthMosaic | 0 / 0 | 0–12 / 0–48 | The block's colour snapped to a limited palette as well as `steps` of light (0 = off). |
| `block_in` / `block_out` | `Settings.QUANTISE_TUNING` | 4 / 6 | 2–10 | Block size under a roof and in the open (the saloon painting's blocks ~4 px, the street's ~6); the mosaic casts a ray up and eases between them. |
| `quantise_once` | `Settings.quantise_once` (I; reloads the scene) | off | on/off | Every pre-blocking step off and the mosaic refined (the whole A1 look). |
| `PixelArt.mosaic` | `src/art/pixel_art.gd` | 0.6 | 0–2 | Per-square shade clusters in the code-painted textures (not the factory's). |
| `edge_shade` | `texel_grid.gdshaderinc` (every grid material) | 0.7 | 0–1 | The dark line along every member face's edges (the line between boards). |
| `roughness` / `specular` | texel_grid.gdshaderinc | 0.95 / 0.2 | 0.5–1 / 0–0.5 | The world's surfaces' roughness and specular. |
| `internal_resolution` | Settings (F2) | native | native, 1280×720, 960×540, 640×360 | The render size the mosaic and squares are measured in. |

## Time of day

`DayCycle.set_time(hour)` (`src/world/day_cycle.gd`) jumps the clock; the shots are at 17.6
(street, golden hour) and 23.67 (saloon). `day_length_seconds` 2700 and the debug speeds
(`debug_time_scales` 1/30/180, T) are in DayCycleConfig.
