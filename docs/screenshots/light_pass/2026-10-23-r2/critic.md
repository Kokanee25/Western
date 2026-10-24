# Blind critic, light pass (critic2)

Judged only from the images in this folder and the targets. "Closer" means closer to the targets' painted world (and, for noon, a harsh desert noon) and less cheap-looking.

## 1. The pairs

| Pair | What differs (what I see) | Closer | Why |
|---|---|---|---|
| 1 (noon street) | B's porch shade and the shaded horse are cooler and deeper (blue-grey). A's shade is warm brown-grey. | **B** | Cool, deep shade under the porches against hot dirt is what reads as noon. A's warm shade looks like flat ambient light. |
| 2 (noon fronts) | Same change as pair 1. B's porch interiors, posts and windows sit in cool blue-grey shade, and A's in warm grey. | **B** | B separates sun and shade cleanly. A's porches look muddy and lit from everywhere. One fault in B: the shaded wood goes slightly lilac and loses its brown. |
| 3 (saloon night) | A has a hard-edged blue/white disc of light on the floor by the stair and a cool tint in the shadows. B has no disc and is warm throughout. (The barkeep is visible only in B, which looks like a person moving rather than the change.) | **B** | The targets' saloon is amber everywhere and keeps the moon blue for the door and windows. A sharp blue spotlight disc on the boards reads as a lighting bug. |
| 4 (saloon night) | B's wall lamps are brighter with large blooms, and the walls and bar take a much warmer, wider orange wash (mean brightness about +40%). A is darker, with small lamp glows. | **B** | The targets' room is warmly lit and readable, and A is mostly black. B's blooms are too big, though: they swallow the lamp fixtures into white blobs, and the target shows the glass chimney and the flame. |
| 5 (noon fronts) | B has a warm colour grade over everything: dirt more orange, the SALOON sign redder, the Telegraph front yellow-olive, and the porch shade warmer (it loses its blue). | **B** (narrowly) | B looks more unified, like one painted palette, and A looks like a raw render. But B gives back pair 1/2's cool shade. Keep the grade on lit surfaces and keep the shade cool. |
| 6 (afternoon sky) | The cloud pattern differs. A is nearly full cover of soft cream masses with a faint grainy mottle. B has more blue-grey sky between streakier masses. | **B** (marginal, almost same) | B's clouds read as separate shapes against sky, and A's read as a washed overcast haze. Neither has the targets' sculpted, rounded cumulus with lit tops and shaded bellies. |
| 7 (noon fronts) | Ground dressing: A has a dark damp/mud patch in front of the trough and scattered yellow straw bits. B's ground is clean and evenly bright. (B also has very slightly darker corners and a touch of grain.) | **A** | The target road has variation everywhere (ruts, prints, stones, tufts). A's spill patch and straw make the ground look used, and B's ground is a uniform sheet. |
| 8 (golden hour) | B's road is brighter and warmer, and the rut rims and ridges catch more raking light, so the relief reads more strongly. A is duller and flatter. | **B** | The road target is all about low sun raking across ridges and ruts. B's ground shows its shape and A's lies flat. |

## 2. Five biggest differences (finals vs targets)

1. **The saloon at night is mostly black.** About 75% of final_4's pixels are near black. The back of the room, the floor and the right half disappear, and the lamps are blown white blobs with nothing lit around them. The targets show a warm amber room where every table, face, bottle, picture and the stair are readable.
   - Image: final_4. Box: 420 180 860 460.
   - Fix: add a warm bounce/ambient fill so the shadows sit at dark brown, not black, and let each lamp throw a visible pool onto the floor and tables. Tighten the bloom so you can see the glass chimney and flame. Remove the hard blue floor disc (0 500 270 160).

2. **The road reads as railway tracks on bleached sand.** At noon and in the afternoon, two or three perfectly straight, parallel, dark grooves run to the vanishing point across near-white, low-detail dirt. The targets' road is warm orange-tan, with many wandering, overlapping ruts, hoof and boot prints, stones and grass tufts.
   - Image: final_1. Box: 300 380 700 340.
   - Fix: deepen the ground tint to a warm tan and lower its exposure at noon. Replace the rail-like grooves with several softer, wavering wheel ruts plus prints and clods along the centre.

3. **The facades are grey and cold and don't take the light.** The buildings are desaturated silver-grey board in every final, and even at golden hour the General Store stays grey-brown while the sky blazes. The targets' fronts are warm red-brown and saturated, glow gold on their sunlit sides, and carry boldly painted signs.
   - Image: final_3. Box: 160 64 320 330.
   - Fix: warm and saturate the exterior wood palette toward red-brown and let the low sun's colour reach the facades (a stronger warm key on sunlit faces, raking shadows across the boards). Paint the false-front signs with weathered colour, not dark lettering on grey.

4. **Horses and figures read as flat black cut-outs.** In shade the horse's body is a featureless black mass while its legs are lit bright brown. The figures down the street are dark silhouettes. In the targets, people and horses are modelled with rim light and warm bounce, even in shade.
   - Image: final_1. Box: 168 312 240 184.
   - Fix: give the creatures and people shade fill (sky/bounce) so their form shows, and add a rim light from the sun side. Check why the horse's body and legs shade so differently.

5. **The street is empty and undressed.** The porches have no lit lamps by day, few barrels or crates, no hay, no people leaning on posts, no water tower or fences, and the end of the street is a hazy grey block. The golden target is crowded with porch lamps, barrels, hay bales, a horse at a hitching rail, townsfolk, and a canyon lit up at the street's end.
   - Image: final_2. Box: 0 220 660 260.
   - Fix: dress the porches and street edges (barrels, crates, hitching rails, hay, sitting and standing townsfolk, lamps glowing by golden hour) and give the canyon at the end warm sunlit relief instead of flat haze.

Also noticed: the noon/afternoon sky (final_1, final_2: 0 0 1280 260) is marbled and streaky rather than built from rounded cumulus. Final_3's golden sky is the closest of any part of the game to its target.

## Key (kept from the critic; before = without that change, after = with it)
- pair1: A = before, B = after
- pair2: A = before, B = after
- pair3: A = after, B = before
- pair4: A = before, B = after
- pair5: A = after, B = before
- pair6: A = after, B = before
- pair7: A = after, B = before
- pair8: A = after, B = before
- Pairs: 1, 2 cool shade (noon road, fronts); 3 moonlight (door); 4 the lamps' edges; 5 round 1 to round 2 (fronts, the painted siding); 6 grime (15:30); 7 street wear (fronts); 8 round 1 to round 2 (golden hour). Since the critic: the moon's pools weaker, wider and softer-edged.
