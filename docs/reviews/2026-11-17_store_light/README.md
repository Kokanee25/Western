# Why the general store is dark inside (#1044, review only)

Sean, 2026-11-17: "there's just not enough light coming in". This review touches none of the store's files.
The tests ran in a throwaway copy of #1035's branch (PR #1043, `day_fill` 0.55, `window_day` 26), with its spec
swapped by hand. Script: `light_review.gd.txt`, a copy of #1035's `store/render_valley.gd` that adds grey cards
and the dials `max_area` and `exposure`. Rendered under lavapipe at 640x360, about 7 minutes a view.

## The cause: mostly the light, then the ceiling; the plan matters less today

1. **The light (most of it).**
   - **One exposure for street and room.** The real look holds exposure at x1.05 all day (`real_light.json`).
     Nothing lets the eye adapt indoors, though RealLook already knows when the camera is under a roof.
   - **No daylight bounce.** SDFGI is off (#643). Indoors, daylight is RoomLight's spots plus the probe's flat
     fill. A window's sky spot grows with the square root of its area and is **capped at 2.5 m²**
     (`opening_max_area`). The spots fall off before the back wall.
   - **The grey cards** (display value, 18% card): front of the shop 0.47, mid 0.31, back 0.10. In linear light
     the back gets about a tenth of the middle.
   - **Every interior is like this.** Saloon B's bar and dance hall render darker (screen mean 0.07) and the
     jail's office about the same (0.13–0.15) as the store (0.11–0.14). See `other_interiors.jpg`.
2. **The ceiling (most of what the eye reads as dark).**
   - The shop has no ceiling. You see the loft floor's underside (fir, albedo ~0.2) between joists, beams and
     posts in the library's walnut (F2, scan albedo 0.04, tinted ~0.07).
   - That is 178 m² of dark across the top third of every view.
   - The walls are fine: pale cream paint, about 0.6.
   - Typical reflectances, from general knowledge rather than a measured source: whitewash ~0.8, cream paint
     0.6–0.7, new pine 0.4–0.5, oiled fir floor 0.2–0.3, walnut 0.05–0.1.
3. **The plan (the period look; little light today).**
   - The front has two 2.0 x 2.0 m four-light house windows (sill 0.5, head 2.5 m) and a 1.22 m door.
   - That is 9.5 m² of glass: 15% of the shop's front wall and about 30% of its width. The storey is 3.9 m.
   - Ground glass is 5.9% of the floor. The doctor's is 18%, saloon B's 8%, the jail's 4%.
   - The alley windows face a building 1.2 m away.
   - A period storefront (NPS Preservation Brief 11): display windows on a low bulkhead, a recessed entry, a
     transom row over windows and door, "expanding the display window area to the maximum extent possible"
     from 1850 to 1900. Estimated: 60–80% of the width is glass, up to 3.0–3.6 m.
   - Rule of thumb (Millet & Bedrick; AIA 1982): daylight reaches 2–2.5x the head height above the work
     plane. Today's 2.5 m head gives about 4.4 m into a 10.7 m room; a 3.5 m head gives about 6.6 m.
   - Country stores were described as "on the dark side", lit by hanging lamps.
   - The glass itself is not the problem: `WoodMaterials.glass()` is alpha 0.28, faint green, and the sun's
     bars cross the floor.

## The tests (noon, the shop's two views: grey cards mid / back / side / back wall; counter view front / mid)

| Test | Shop view | Counter view |
|---|---|---|
| Now, 12:00 | 0.312 / 0.104 / 0.130 / 0.115 | 0.468 / 0.224 |
| Now, 16:00 | 0.326 / 0.105 / 0.146 / 0.118 | 0.497 / 0.236 |
| RoomLight cap lifted (2.5 -> 12 m²) | 0.335 / 0.111 / 0.148 / 0.118 | 0.491 / 0.238 |
| Bigger front glass (3.4 x 3.0 m, door transom 0.9) | 0.317 / 0.108 / 0.140 / 0.115 | 0.486 / 0.232 |
| Bigger glass + cap lifted | 0.376 / 0.114 / 0.156 / 0.121 | not rendered (time limit) |
| + pale ceiling and timber | 0.377 / 0.113 / 0.166 / 0.122 | 0.510 / 0.278 |
| Indoor exposure x1.9 alone | 0.441 / 0.134 / 0.173 / 0.144 | 0.625 / 0.321 |
| All (glass, cap, pale, exposure x1.6) | 0.480 / 0.135 / 0.206 / 0.141 | 0.629 / 0.363 |

- Noon and 4 pm differ by about 5%.
- Bigger glass alone does almost nothing, because of the cap.
- The pale ceiling barely moves the cards (there is no bounce), but it changes the picture most
  (`ceiling.jpg`).
- The back of the room moves only with exposure.

Pictures: `tests.jpg` (now / exposure / glass / all), `ceiling.jpg`, `front_glass.png` (the front now and in
the trial), `other_interiors.jpg` (the jail, saloon B and the store as rendered by their own sessions; its top
row is the doctor's sheets).
