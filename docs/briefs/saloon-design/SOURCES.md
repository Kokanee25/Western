# Saloon design: the research notes (2026-11-10)

The four notes behind `../saloon-design.md`, as the research agents wrote them, with every source URL. Each marks what it couldn't check. Kept as written, except one link mended.

---

# Primary sources: HABS and the NRHP

## Saloon references: primary-source check (2026-11-10)

Checks `docs/briefs/saloon-references.md` (first pass, all "reported") against HABS records
(LoC JSON API, tile.loc.gov data-page PDFs and master TIFs of the drawing sheets) and NRHP
nominations (npgallery). Short forms used below:
- `T/<path>` = `https://tile.loc.gov/storage-services/master/pnp/habshaer/<path>`
- `S/<path>` = `https://tile.loc.gov/storage-services/service/pnp/habshaer/<path>`
- `NR/<n>` = `https://npgallery.nps.gov/NRHP/GetAsset/NRHP/<n>_text`

A HABS record's page is `https://www.loc.gov/item/<id>/`. "By scale" means measured off the
drawing against its written dimensions (about ±1 ft). **Not reachable from this session:**
hmdb, Leadville Herald, SAH Archipedia, tombstonebirdcage.com, mtech.edu, onlinenevada,
blackpast. The Wikipedia and Commons APIs refused with rate limits, so neither was used.

### (a) The first pass's figures

| Saloon | Reported | Status | Primary figure | Source |
|---|---|---|---|---|
| Carissa (HABS WY-31) | ~21 x 31 ft, one storey, false front | CHECKED | "approximately 21' x 31'", one storey, gable roof, false front with bracketed cornice | T/wy/wy0000/wy0073/data/wy0073data.pdf p.2; index card T/.../wy0073/supp/wy0073supp.pdf |
| Carissa | ~21 x 10 ft store room dug into the hill | CHECKED | "storage room constructed into the hill behind ... 21' x 10' and has a lower roof" | data p.2 |
| Carissa | a store 1868, a saloon ~1890 | PARTLY | The lot's first building was Gaston's general store, sold to J. A. Nye & Co. in 1869. The present building is ca. 1890; the index card says "reconstructed 1911", restored 1977 | data p.1; supp card |
| Carissa | front room with a long wooden bar | UNVERIFIED | HABS doesn't mention a bar. Front (main) room: tongue-and-groove floor, painted board ceiling, brick chimney centred at the rear | data pp.3-4 |
| Carissa | a log rear room | WRONG | The **front room** is lodgepole-pine log with a lap-sided front. The **rear room** has red slate-schist retaining walls (brick on the east), a log-and-dirt roof and an exposed-log ceiling. One doorway (no door) joins them | data pp.2-3 |
| Carissa | 2 measured drawings, 3 photos | CHECKED, with a caveat | 2 sheets, but they are a half south elevation, a muntin detail and a cornice detail: **no plan** | S/wy/wy0000/wy0073/sheet/00001v.jpg, 00002v.jpg |
| Grecian Bend (HABS WY-37) | 1889; rebuilt | CHECKED | "a reconstruction of the original 1889 structure"; the first Grecian Bend of 1868-69 stood on this site | T/wy/wy0000/wy0080/data/wy0080data.pdf p.1 |
| Grecian Bend | frame; no size found | NOW FOUND | Data pages: one storey, "approximately 23' x 51'". Sheet 1: 51'-3" long, saloon room 22'-0" x 34'-6", back rooms 6'-8" x 14'-6" and 14'-6" x 14'-9". Sheet 2: ceiling 10'-10", roof rise 8'-5". Frame of rough-sawn 2x6 studs with drop siding | data p.3; S/wy/wy0000/wy0080/sheet/00001v.jpg, 00002v.jpg |
| Grecian Bend | three rooms: bar room, store room, office | WRONG | Now one saloon room in front and two back rooms. The 1889 building had **four rooms**, a stove in each and two chimneys; the wall between the front and middle rooms came out in 1971 | data pp.2, 4 |
| Grecian Bend | (bar not reported) | NEW | Front bar and mirrored back bar on the **east side wall** of the saloon room, next to the hotel. Bar about 17 ft long by scale, starting ~4 ft in from the front wall, ~2½ ft wide. Back bar about 7½-8 ft high (sheet 2). Restored to its original length in 1971 | data pp.2, 5; sheets 1-2 |
| Grecian Bend | 3 measured drawings | CHECKED | 3 sheets plus 6 photos | item JSON wy0080 |
| Fort Laramie post trader's | Fort Laramie; HABS number? | FOUND | **HABS WY-2** "Sutler's Store", 7 sheets plus title sheet, 17 photos | `https://www.loc.gov/item/wy0003/` |
| Fort Laramie | 1883 addition | PARTLY | NPS: the soldiers' bar was allowed to open in 1883. HABS: adobe part 1849-50, stone part ~1865, lime-concrete part "in all probability ... about 1885" | NPS page; T/wy/wy0000/wy0003/data/wy0003data.pdf |
| Fort Laramie | stone and lime concrete | CHECKED | Adobe, sandstone and lime concrete; one storey with attic rooms; 2x10 floor joists, 2x8 attic joists | data p.2 |
| Fort Laramie | officers' club at one end, soldiers' and civilians' bar at the other, a poolroom | PARTLY | Plan: "Officers Club Room" (stair up 15 risers) and "Officers Bar Room" (~24'-9" wide) at one end; "Bar Room" (~19 x 25 ft by scale) at the other; store rooms between. NPS: soldiers played cards and pool in the bar. "Civilians" is unverified, and the plan has no separate poolroom | S/wy/wy0000/wy0003/sheet/00002v.jpg; NPS page |
| Fort Laramie | HABS drawings 1937-39 | WRONG | Measured Dec 1937; drawn Nov 1940 to Jan 1942 | title block, sheet 00000 |
| Crystal Palace (HABS AZ-7) | NW corner of Fifth and Allen | CHECKED | "Northwest corner of Allen and 5th Streets" | T/az/az0000/az0020/data/az0020data.pdf |
| Crystal Palace | reopened July 1882 | UNVERIFIED | HABS: built 1880 by Gus Tribolet as a **two-storey adobe brewery** (about a year), then remodelled as "Saloon, Gambling House and theatre" (B. Wehrfritz; "Crystal Palace Saloon, connected with the Theatre") | same, p.1 |
| Crystal Palace | one or two storeys (sources differ) | RESOLVED | Two storeys in 1880 (HABS data). One storey when measured Dec 1937 (sheet and index card "1 story adobe"). NRHP 1966: "simple three bay, two story structure", the facade restored to before May 1882 | S/az/az0000/az0020/sheet/00001v.jpg; NR/66000171 |
| Crystal Palace | 16 ft ceilings | UNVERIFIED | 1937 Fifth St elevation: porch roof line 14'-2", parapet 22'-8". Interior not drawn | sheet 00001 |
| Crystal Palace | long bar, big mirror; gambling rooms and offices upstairs | UNVERIFIED | HABS: "the original bar" still in use in 1940; no plan | data p.2 |
| Bird Cage (HABS AZ-10) | Allen and Sixth; 1881-89 | PARTLY | South side of Allen near 6th; opened **21 Dec 1881** as "Variety Theatre and Saloon". 1889 not in HABS | T/az/az0000/az0021/data/az0021data.pdf |
| Bird Cage | two-storey adobe and brick | WRONG | Index card: "Lime plaster on stone, wood trim, **one story and mezzanine**, flat roof". The front elevation is drawn in stone blocks with three arched 6'-0" double doors | T/.../az0021/supp/az0021supp.pdf; S/az/az0000/az0021/sheet/00001v.jpg |
| Bird Cage | bar at the front, a stage at the far end | CHECKED | Bar room across the front, 27'-11" wide x 19'-10" deep, full height (14'-2½"). Bar along the east (left-hand) wall ~13 ft by scale, back counter ~19 ft. A "screen", then the "Dance Hall & Theatre" (~43 ft), then a stage block 31'-2" deep. Whole building ~94 ft by scale, ~30 ft wide. Dumbwaiter from the bar's end up to the boxes | sheets 00002, 00003; data p.1 |
| Bird Cage | 12-14 curtained boxes on side balconies | CHECKED | Balcony plan: a row of boxes down each side (about seven a side), a balcony with an open rail across the hall's front, a stair "up 12 R" in the bar room; boxes "hardly high enough for a man to stand" | sheet 00002; data p.1 |
| Bird Cage | basement poker room | UNVERIFIED | The section shows a room under the stage (9'-4" high, doors). Its use isn't labelled | sheet 00003 |
| Oriental | corner of Fifth and Allen; 1880, rebuilt | PARTLY | NRHP: "pressed metal, as on the Oriental Saloon, Fifth and Allen Streets"; the town burned June 1881 and May 1882 | NR/66000171 p.2 |
| Oriental | two rooms; bar right of the door; 28-burner chandeliers | UNVERIFIED | No HABS record; sources blocked | — |
| Board of Trade, Leadville | brick 1883, 50 x 100 ft, room order, tile floor, back bar | UNVERIFIED | No HABS record ("leadville" search: 0 hits with drawings); Herald and Archipedia blocked; the Leadville district nomination wasn't found by number | — |
| Piper's Old Corner Bar | 1863, two-storey brick corner, offices up | UNVERIFIED | HABS NV-15-17 (Piper's Opera House, B & Union, 7 sheets) gives Piper's theatres (B St 1878, burned 13 Feb 1883; the present one 1885) but not the bar. Dixon's PDF blocked | S/nv/nv0000/nv0004/sheet/00001v.jpg |
| Hibernia Brewery saloon | ~60 ft x 20-30 ft | UNVERIFIED | Source blocked; no HABS record | — |
| Boston Saloon | floor below street | UNVERIFIED | Source blocked; no HABS record | — |
| Summer Saloon, Fairplay | 1879, one room, one storey, sandstone, false front | CHECKED | Date stone "Leonard Summer 1879"; "one room structure with a high ceiling"; one storey (false front); red sandstone from Red Hill Pass, rough stone with tinted mortar ruled to look like ashlar | NR/74000591 p.2 |
| Summer Saloon | (more) | NEW | No basement; nearly flat roof; windows only in front; centred double doors with nine-light upper panels, a fixed light and a 2-pane transom; **doors centred in both side walls and in the rear wall**; built at the front of Summer's brewery lot | same |
| Annex Saloon, Lamy | 1894, ~15 x 38.5 ft | UNVERIFIED | Not reached | — |
| Western Saloon, Denver | 1859, 33 x 40 ft, alleys to 132 ft | UNVERIFIED | Denver Library blocked | — |
| Shute's Bar, Calumet | HABS-measured | WRONG | **HABS MI-424** (record mi0642): 16 data pages with sketch plans, **no measured drawings** | item JSON mi0642 |
| Shute's Bar | 1893-1900 | WRONG | Built 1895, enlarged 1900 | T/mi/mi0600/mi0642/data/mi0642data.pdf p.1 |
| Shute's Bar | bar ~25 ft | CHECKED | "The bar, about twenty-five feet long, is divided into five sections" | data p.9 |
| Shute's Bar | back-bar mirror ~5 x 15 ft under a stained-glass canopy | CHECKED | "plate glass mirror of about 5' high by 15' long", the canopy in five sections, copper-framed | data p.10 |
| Shute's Bar | (more) | NEW | Two storeys, 19' x 96'. Upstairs "the space over the front half of the bar was a single room ... rented to ... Italian fraternal organizations". **Basement gambling room** reached by stair, with a speaking tube to the bar. The bar room is in two parts, four steps apart, under a low arch. Wainscot 42-48"; glazed double doors with a transom | data pp.4-9 |
| South Pass City district | 13 saloons in 1868 | CHECKED | "five hotels ... thirteen saloons"; a saloon and a dance hall survive | NR/70000670 |

### (b) More HABS records with measured drawings or data (period and West)

| Building | Survey; when | What the primary source says | Source |
|---|---|---|---|
| Miners' Exchange Saloon, Idaho City ID | HABS ID-14; 1865, club room 1867 | One-storey brick block, L-shaped, 89'-10" frontage; the saloon about 21 ft by scale x ~51 ft, with a **12'-8"-wide game room** added the length of the saloon; storage and a stair to the attic behind. 1867 "new large and elegantly furnished Club Room"; a **liquor cellar** under it. Arched openings with **folding iron shutters**; covered wooden walk; attic floor of brick under 4" of earth against fire | T/id/id0000/id0027/data/id0027data.pdf pp.1-9; S/id/id0000/id0027/sheet/00002v.jpg (plan) |
| Content Corner, Virginia City MT | HABS MT-2 ("MON-2"); 1864 | **Two-storey stone corner building**, 20'-6" front (plus a 6' store under the upper porch), 60'-7" deep, a one-storey stone store room behind. Upper floor (territorial offices 1865-76) reached **only by outside wooden stairs and a porch along the side street**; "no internal access". A side-rear door below grade. Tavern on the main floor in 1970s | T/mt/mt0000/mt0027/data/mt0027data.pdf pp.2-5; S/mt/mt0000/mt0027/sheet/00004v.jpg (elevations) |
| Crystal Palace, Tombstone | HABS AZ-7 | See (a); title sheet plus the Fifth St elevation and door/window details (door with transom, 1937) | S/az/az0000/az0020/sheet/00000v.jpg, 00001v.jpg |
| Bird Cage Theatre, Tombstone | HABS AZ-10 | See (a): title, front elevation, plans, section | S/az/az0000/az0021/sheet/00000v-00003v.jpg |
| Diana Saloon, Sacramento CA | HABS CA-1706; 1852 | One storey plus a basement, **40'-0" x 114'-0"**, brick. A row of 6x6 posts with diagonal brackets down the middle carries a 6x12 beam; joists exposed. Built low, then the street was raised: rear basement doors at the old grade | T/ca/ca0500/ca0516/data/ca0516data.pdf; 4 sheets |
| Fraternity Hall, Elkhorn MT | HABS MT-9; c.1890 | Two-storey balloon frame (2x6), false front, **28' x 72'-3"**. Ground floor: entry, assembly and **dance hall with a raised stage** (2'-6"). Upstairs: lounge with a door onto a **cantilevered balcony over the front door**, then the full-width lodge room. Inside U-stair. Storeys 12'-5" and 11'-2", floor ~1'-0" deep; ceiling joists 2x8 at 24"; hip roof behind the false front | T/mt/mt0000/mt0012/data/mt0012data.pdf pp.3-5; S/mt/mt0000/mt0012/sheet/00003v.jpg |
| Miners Union Hall, Granite MT | HABS "MON-15" on its data pages; 1890 | Three storeys, **98'-6" x 48'-1"**, granite ground floor with a cast-iron front, brick above. Ground floor: two long club and game rooms (63'-6" x 24'-2" and 63'-6" x 18'-9"; billiards and cards), split by a granite wall with an 8'-9" arched passage. **A separate street door to the stair** up to the **44' x 53' hall** (ceiling 18'-9"), with a 16' x 44' stage and a **maple "spring floor"** laid on strips about 16" apart on the diagonal. An exterior stair from behind the stage; lodge room 30' x 44' on the 3rd floor. Ceilings 12'-2" / 10'-4" / 18'-9" / 7'-2" | T/mt/mt0000/mt0010/data/mt0010data.pdf pp.2-6; 11 sheets |
| Masonic Temple, Idaho City ID | HABS ID-5; 1865 | Two-storey frame, ~32' (with a 6' addition and stair) x ~68'. Social hall below, lodge room above, reached by an **enclosed stair on the outside of the west wall**. Porches at both floors in front | T/id/id0000/id0026/data/id0026data.pdf pp.5-7; 7 sheets |
| Pioneer Lodge No. 1 (IOOF), Idaho City | HABS ID-8; 1875 | Two-storey frame, 24' (three-bay) front (length illegible in the OCR). An **exterior stair on the north side, the only way to the upstairs lodge room**; enclosed porches at both levels, the upper one with a balustrade | T/id/id0000/id0025/data/id0025data.pdf; 5 sheets |
| Miners' Union Hall, Bodie CA | HABS CA-1919; 1878 | One-storey frame false front, ~30' x 96'. Hall 29' x 57'-6", stage 12' deep, dressing rooms behind, **ceiling 13'**. 12x12 sills 6' o.c., 6x6 girders, floor joists at 18" o.c. Double door 5'-6" x 9' with transom; plank walk 2" | T/ca/ca0300/ca0356/data/ca0356data.pdf pp.2-3; 6 sheets |
| Knights of Pythias and Miners' Union Halls, Virginia City NV | HABS NV-15 series (see also NV-15-20); 1876 | Two false-fronted halls on B St, cast iron and stuccoed brick; plans of both floors; the union hall's upstairs library 1877 | S/nv/nv0000/nv0010/sheet/00001v-00005v.jpg |
| Dance Hall, South Pass City WY | HABS WY-35; c.1890 | One storey, log, ~21' x 32'-9", a single room, double glazed doors between two ~42 x 78" fixed windows | T/wy/wy0000/wy0077/data/wy0077data.pdf |
| No drawings, photos/data only | — | Crystal Saloon VC NV (NV-15-29); Pioneer Saloon, Columbia CA; Can Can Saloon, Tombstone; Commercial Saloon, Clifton AZ (AZ-189, c.1890); Hellman's Saloon, St Elmo CO (CO-139, 1908); Red Onion, Skagway (AK-275, 1898); Meyer's Dance Hall & Saloon, Coloma CA; Table Rock Billiard Saloon and Bella Union, Jacksonville OR | search JSON |

**Not found in HABS:** saloons with drawings in Leadville, Georgetown, Central City (only photos
of its opera house), Bannack, Deadwood, Bodie (only the union hall) or Columbia; no hurdy-gurdy
house in Virginia City MT. The searches for Silver Plume, Ouray, Creede, Jacksonville and others
were cut off by the run's time limit after the towns above.

**What the primary sources add on layout:**
- **The bar runs down one side wall from near the front:** Grecian Bend (east wall, ~4 ft in,
  ~17 ft), Bird Cage (left wall, ~13 ft), Shute's (25 ft).
- **Glazed double doors with a transom** at nearly every front: Grecian Bend, Carissa
  (recessed), Summer, Bird Cage, Elkhorn, Bodie, Shute's. **No batwings in any of them.**
- **Ceilings 10'-10" to 14'-2½"** in bar rooms; halls 13-18'-9".
- **Upstairs rooms are often reached from outside:** the outside stair and porch along the side
  street (Content Corner); an enclosed stair on the outside of a side wall (Idaho City's
  Masonic and IOOF halls); a separate street door to the stair (Granite).
- **Cellars:** liquor (Idaho City), gambling (Shute's), under the stage (Bird Cage).
- **Rough store room behind:** Carissa's stone room cut into the hill, Content Corner's stone
  room behind.

### (c) Sheets and photos to show (saved ~1000 px wide in `refs/`)

Credit for all of them: "Historic American Buildings Survey, Library of Congress, public domain."

1. `grecian-bend_1889_HABS-WY-37_sheet1_plan-north-elevation.jpg`: the plan with room sizes, bar, front.
   https://tile.loc.gov/storage-services/service/pnp/habshaer/wy/wy0000/wy0080/sheet/00001v.jpg
2. `grecian-bend_1889_HABS-WY-37_sheet2_section-bar-backbar.jpg`: the section with the bar and back bar, 10'-10" ceiling.
   https://tile.loc.gov/storage-services/service/pnp/habshaer/wy/wy0000/wy0080/sheet/00002v.jpg
3. `bird-cage_1881_HABS-AZ-10_sheet2_floor-and-balcony-plans.jpg`: the bar room, the screen, the hall, the boxes.
   https://tile.loc.gov/storage-services/service/pnp/habshaer/az/az0000/az0021/sheet/00002v.jpg
4. `bird-cage_1881_HABS-AZ-10_sheet3_section-boxes-stage.jpg`: the full-height bar room, the boxes, the room under the stage.
   https://tile.loc.gov/storage-services/service/pnp/habshaer/az/az0000/az0021/sheet/00003v.jpg
5. `fort-laramie-sutlers-store_HABS-WY-2_sheet2_first-floor-plan-bars.jpg`: the officers' club and bar room, and the soldiers' bar room.
   https://tile.loc.gov/storage-services/service/pnp/habshaer/wy/wy0000/wy0003/sheet/00002v.jpg
6. `fort-laramie-soldiers-bar_HABS-WY-2_photo17_bar-restored.jpg`: HABS WY-2-17 "Interior view, bar" (restored; photographer and date unknown).
   https://tile.loc.gov/storage-services/service/pnp/habshaer/wy/wy0000/wy0003/photos/175029pv.jpg
7. `elkhorn-fraternity-hall_1890_HABS-MT-9_sheet3_elevations-section.jpg`: a two-storey false front with a cantilevered balcony; the section through the hall and its floor.
   https://tile.loc.gov/storage-services/service/pnp/habshaer/mt/mt0000/mt0012/sheet/00003v.jpg
8. `content-corner_1864_HABS-MT-2_sheet4_elevations-outside-stair.jpg`: a two-storey stone corner building with the outside stair and porch on the side street.
   https://tile.loc.gov/storage-services/service/pnp/habshaer/mt/mt0000/mt0027/sheet/00004v.jpg
9. `idaho-city-miners-exchange_1865_HABS-ID-14_sheet2_floor-plan.jpg`: the saloon, the kitchen and the store in one brick block; the game room strip.
   https://tile.loc.gov/storage-services/service/pnp/habshaer/id/id0000/id0027/sheet/00002v.jpg
10. `crystal-palace-tombstone_HABS-AZ-7_photo_1937-corner.jpg`: the corner saloon under its porch, 1937.
    https://tile.loc.gov/storage-services/service/pnp/habshaer/az/az0000/az0020/photos/008707pv.jpg

Also worth showing (not saved): the Grecian Bend's bar photo
(`S/wy/wy0000/wy0080/photos/174830pv.jpg`) and the Carissa's false front with its rear room in
the hill (`S/wy/wy0000/wy0073/photos/174938pv.jpg`).

---

# Period interiors

## The western saloon interior, c. 1875-1890: facts with sources

For Salt Creek (a Colorado mining-and-ranching boom town, 1882). Each fact is tagged with its source. Where no
period source turned up, the line says **estimate** (read off photographs) or **inference**. Most of the
numbers come from two trade catalogues of the 1890s, a decade after 1882. Most saloon furniture was sold by
catalogue and shipped by rail, and it changed slowly, so their sizes hold for 1882, but the gadgets in them
may be newer.

Main sources (searched in their full OCR text; the passages quoted were read):
- **[S94]** B. A. Stevens Co. (Toledo), *Catalogue of billiard and bar supplies, saloon fittings, furniture…*, 1894. https://archive.org/details/CatalogueOfBilliardAndBarSuppliesSaloonFittingsFurnitureAndGeneral
- **[B94]** Brunswick-Balke-Collender, *Catalogue of Billiard and Pool Tables*, 1894. https://archive.org/details/brunswick-billiards-1894
- **[B98]** Brunswick-Balke-Collender, *A complete hand-book of … billiards and pool … hints to purchasers*, 1898. https://archive.org/details/completehandbook00brun_0
- **[GP87]** Gibson, Parish & Co. (Chicago), *Illustrated catalogue of cabinet hardware*, 1887. https://archive.org/details/gisbonparishcosi00gibs_0
- **[ER82]** *The Editor's Run in New Mexico and Colorado* (letters Nov 1881 to Jan 1882; Leadville letter dated 9 Dec 1881). https://archive.org/details/editorsruninnewm00chasrich
- **[IN85]** Ernest Ingersoll, *The Crest of the Continent*, 1885 (Leadville in 1879). https://archive.org/details/crestofthecont1885eng
- **[RI67]** A. D. Richardson, *Beyond the Mississippi*, 1867 (Virginia City, Montana, 1865). https://archive.org/details/beyondmississipp00rich
- **[HABS]** Historic American Buildings Survey data pages (Library of Congress): Grecian Bend Saloon, South Pass City WY (WY-37) https://www.loc.gov/item/wy0080/ ; the dance hall at South Pass City (WY-35) https://www.loc.gov/item/wy0077/ ; Diana Saloon, Sacramento (CA-1706) https://www.loc.gov/item/ca0516/ ; Crystal Saloon, Virginia City NV (NV-15-29) https://www.loc.gov/item/nv0080/
- Wikipedia: [Western saloon](https://en.wikipedia.org/wiki/Western_saloon), [Cash register](https://en.wikipedia.org/wiki/Cash_register), [Tin ceiling](https://en.wikipedia.org/wiki/Tin_ceiling), [Bird Cage Theatre](https://en.wikipedia.org/wiki/Bird_Cage_Theatre), [Faro](https://en.wikipedia.org/wiki/Faro_(banking_game)), [Spittoon](https://en.wikipedia.org/wiki/Spittoon)

### 1. The bar (front counter)
- **Length:** stock counters were made 9-18 ft long, longer to order, "with round or square returns" (an L-shaped end) [S94 pp. 30-31]. Stevens' good counters in walnut or mahogany cost $100-165 for 14-18 ft; "the cheapest counter I make", softwood grained to look like oak, walnut or mahogany with an ash top, cost $25 for 9-10 ft [S94 p. 31]. Back bars in the same catalogue run 10-20 ft, so a 14-18 ft bar is typical for a mid-sized saloon.
- **Front:** panelled. The No. 1 counter has "sunk panels" and "very heavy" columns with carved tops; the No. 2 has carved panels. The mouldings are solid wood, doweled and mortised, with 6-8 coats of finish. "All counters have my new counter irons, so that the wood work does not touch the floor" [S94 p. 30]. The bar front stands on iron feet a little off the floor. Photos: plain raised panels with pilasters at Dodge City (Long Branch) and Black Hawk 1897; a plain board front at Table Bluff 1889.
- **Height:** no catalogue gives it outright. **Inference:** the refrigerator built in under the counter top is "36½ inches high and 22 inches deep" [S94 p. 39, No. 21 "Inside"], which puts the top at about **42 in (3 ft 6 in)**. The photos agree: at Black Hawk (1897) the top meets a standing man at the hip. 42 in is also the modern standard.
- **Depth:** **inference** about 24-30 in overall. The 22 in deep ice box sits under the top, behind the panelled front. Behind the bar the floor was covered with bar mats **2 ft wide**, 8-18 ft long (galvanised steel wire, brass wire, or round hard-maple slats soaked in oil); "by turning the mat over the dirt falls out" [S94 p. 32]. So the bartender's aisle was about 2½-3 ft, with the back bar behind it.
- **Arm rail (along the top edge, customers' side):** No. 1 is a round rail "2½ inches in diameter" of mahogany or walnut on heavy nickel-plated brass brackets "weighing over five pounds each", $2.00 a foot complete. No. 2 is a cheaper round rail of walnut, mahogany or ash at $1.00-1.25 a foot [S94 p. 28].
- **Foot rail:** iron rail with brass ends on heavy ornamental cast-iron brackets, or polished brass. The rail is about 1½ in across (the OCR is garbled; [GP87] sells cast-brass foot-rail ends of 1½ in and "bar rail ends" [GP87, "Bar and foot rail fixtures"]). Stevens also sold a "Patent Swinging Foot Rail" whose bracket fixed to the counter base and hinged, so the rail tipped back against the bar "leaving floor clean for sweeping", in brass or iron [S94 p. 33]. **Height and offset: estimate** from the photos (Black Hawk, Grecian Bend, Long Branch): the rail is about 6-9 in off the floor and 8-12 in out from the bar front, running the full length.
- **Spittoons:** standing on the floor along the foot rail, roughly one every 4-6 ft (**estimate**, Long Branch and Black Hawk photos). Stevens sold three kinds. Brass cuspidors "spun and hammered … loaded bottoms", **9 in across, 6 in high** (65¢; nickel-plated 75¢). Indurated-fibre spittoons with removable tops, **12 in and 16 in across**. Cast-iron self-righting ones, japanned and decorated (25¢). Also octagonal rubber cuspidor mats [S94 pp. 74, 104].
- **Towels:** at Black Hawk (1897 photo) towels hang from hooks along the customers' side of the bar front, a towel every few feet for wiping moustaches. Behind the bar, Stevens' work boards carry "a small wooden rail on which to hang towels" [S94 p. 35].
- **Drip trough, sinks and beer:** behind and under the counter top stood the "Inside" or "work board". It held "corrugated zinc" drip boards, wash sinks and rinse tubs of "composition metal" with threaded drain outlets, a cracked-ice box and a "coil box for cooling beer", in heavy zinc or planished copper with a high back board against splashing. There was a "beer drip on top" with a hinged perforated drip pan under the faucets. The beer ran from the keg through block-tin pipe coils packed in ice to bar cocks (taps) on the counter. A 3 ft ice chamber served 1-3 taps; 4, 5 or 6 ft chambers served 4-6 taps. The Inside is built 1½ ft shorter than the counter [S94 pp. 35-39]. Earlier makers' Insides of "light galvanized iron … common tin" leaked and wasted ice [S94 p. 35], so a cheap 1882 bar in a boom town would have something cruder.

### 2. The back bar
- **Parts:** "the Mirror Frame, Glass and Cupboard constitute the complete back bar" [S94 p. 17]. A cupboard (counter-high) with drawers and doors holds a shelf at its top for bottles and glasses. Above it rises a mirror frame, often with an overhanging cornice carried on 2-4 turned or carved pillars standing on the front edge of the cupboard. Some have glass-doored "wine cases" or "bracket wings" at each end, spindle-work shelves for display bottles, and fretwork. The glass is bevelled French plate [S94 pp. 15-17].
- **Lengths:** illustrated back bars are 10, 12, 14, 16 and 18 ft, with 18 and 20 ft priced [S94 pp. 15-17]. A wall case for bottles and cigars was "10 ft long and 9 ft high" [S94 p. 16], so a full back fitting stands about **9 ft** tall.
- **Mirror sizes:** the 18 ft No. 7 back bar had a centre plate **48 × 98 in** and round end lights **48 in** across. The cheap softwood stock frames had one plate of **30 × 50 in** (for an 8 ft cupboard), **40 × 52** (10 ft), **34 × 60** (12 ft) or **40 × 60**. A three-panel frame had a centre plate **18 × 40** and two side plates **18 × 30**; others **20 × 34** and **17 × 30** [S94 pp. 17-19]. So it is one big plate or three panels, framed in wood, never a seamless wall of glass.
- **Woods:** mahogany ("by all means use mahogany"), walnut, cherry, oak or redwood; cheap ones are softwood grained to imitate oak, walnut or cherry [S94].
- **Ice box under it:** the No. 23 and No. 8 back bars have a "refrigerator chamber in center with transparent plate glass door in front of ice chamber" and provision chambers at the sides [S94 p. 16]. A cabinet of bottle-cooler and cigar case had "tilting bottle racks" and cigar cupboards with wire-screen vents and moisteners [S94 p. 16].
- **Photographs:** at Long Branch (Dodge City, 1870s-80s) a tall dark back bar with a big framed mirror and steer horns on top. At Black Hawk (1897) a carved central mirror frame flanked by glass bottle cases, mirror strips and stacked bottles. At Table Bluff (1889) only a plain shelf of bottles with a clock in the middle.
- **Cash register:** the Ritty "Incorruptible Cashier" was patented in 1879 by a Dayton saloon keeper. Eckert's National Manufacturing Co. made it until 1884, when Patterson bought it and founded NCR [Wikipedia: Cash register]. **Inference:** in Colorado in 1882 a register would be a rare novelty. Use a till drawer under the counter or back-bar shelf, and gold scales where dust was still taken.

### 3. Light
- **Kerosene, smoky and yellow:** Leadville in 1879 had "stale smoke … where the sooty oil lamps burned with a weak and yellow flame" [IN85 p. 213].
- **Hanging lamps on the centre line:** the 1865 hurdy-gurdy hall [LOC engraving] had two chandeliers of 3-4 globe lamps each, hung from the ridge with bunting. Long Branch had three fixtures down a narrow room: a 4-arm chandelier and single pendants with chimneys. Black Hawk (1897) had pendant lamps with flat white shades, about 8 ft up (estimate). The Crystal Saloon, Virginia City, had big multi-tier chandeliers with prisms (photographed 1940; HABS calls them late 19th century).
- **Over billiard tables:** "the light should be raised about three feet two inches from the bed of the table … The distance of the light from the floor should be about 6 feet 1 inch" (the bed is about 32 in high, the rail top 34 in). The pendant's cross-arms run light to light 28 in for a 5×10 table, 25 in for 4½×9 and 22 in for 4×8; the long arms (for four lights) 56, 50 and 44 in [B98 p. 15]. Brunswick sold shaded billiard fixtures with two kerosene lamps, "fixtures with four lamps can be had", and the lamps lift out to refill [B94].
- **A big hall lamp of 1894:** "Lamp for shops and halls": brass fount 9 in across, 3 in round wick, burns 9 hours, "250 candle power", hung on a chain with a ball counterweight so it can be pulled down to fill. "Give height of ceiling" when ordering [S94 p. 105]. This is a newer lamp than 1882's; the Long Branch and hurdy-gurdy fixtures are the 1870s-80s kind.
- **How many: estimate** from the photos and Brunswick's spacing. A 25 × 80 ft room wants about 4-5 hanging lamps or chandeliers on the centre line, 15-20 ft apart, 7½-9 ft up, plus 1-3 lamps or bracket lamps on the back bar lighting the mirror, and each billiard table its own 2-light fixture. A 50 × 50 ft hall wants two rows of 3, or a 3 × 3 grid. Even so the corners, the ceiling and the far wall stay dim. Mirrors double the light behind the bar, which is the brightest place in the room.

### 4. Floor, walls, ceiling and stove
- **Floor:** wide planks. HABS records "random width rough-sawn wooden planking" (South Pass dance hall, c. 1890) and 1 × 8 planks (Grecian Bend). Leadville 1879: "the sawdust floors of these reeking bar-rooms" [IN85 p. 213]. Black Hawk 1897: bare, stained planks. The Long Branch had a patterned carpet or oilcloth with a plain runner along the bar; the fancy ones did that. Billiard floors, "if carpeted at all", thick and soft [B98].
- **Walls:** "muslin covered with wall paper over the interior face of the exterior logs" (South Pass dance hall, c. 1890, HABS WY-35). Black Hawk 1897: patterned wallpaper. Long Branch: smooth light walls with a chair rail and dado. Diana Saloon, Sacramento: exposed painted brick (HABS). Board walls in plainer places (Table Bluff 1889).
- **Ceiling:** the South Pass dance hall's ceiling "shows no evidence of being covered", so the roof boards showed; the Diana had "exposed 3"×12" wood joists". The Gem in Deadwood (1890s photo) has a ceiling of narrow tongue-and-groove boards running the length of the room. Muslin tacked under the joists and papered is the cheap finish (inference from the walls). **Pressed tin is mostly later:** corrugated-iron ceilings appear in the US by the early 1870s; stamped metal was widespread from the 1880s, and about 45 firms sold it between 1890 and 1930 [Wikipedia: Tin ceiling]. *The Decorator and Furnisher* (Dec 1890) still presents Northrup's stamped panels as "one of the latest" designs (https://archive.org/details/jstor-25586233). For an 1882 boom-town saloon use boards, muslin and paper, or plaster; save tin for a rebuilt or very rich one. The Crystal Saloon's embossed tin (HABS 1940) is likely a later fit-out. **Height: estimate** 11-14 ft in a one-storey false-front saloon (the Long Branch photo shows about 2½ times a man's height). The 1889 Grecian Bend's chimney "begins at a height of seven feet-six inches … supported by a knee-braced wooden shelf" [HABS WY-37].
- **Stove:** Grecian Bend (1889, 23 × 51 ft): "Heating stove in the center of the saloon room, near rear wall, is a Willson, Estes and Fairchild No. 38, Improved-Box iron stove (Leavenworth, Kansas), patented in 1867", with a second stove in the back room. The 1889 building had "a stove in each section" and two chimneys [HABS WY-37]. So: a long cast-iron box stove (wood-burning) standing on a sheet-iron or sand-box base mid-room, its pipe rising 7-8 ft to a hung brick flue. Black Hawk 1897 has a parlour stove by the front door. "Often a single wood-burning stove might warm such establishments" [Wikipedia: Western saloon]. Keep cues "at a distance from the fire or stove" [B98].

### 5. Furniture and games
- **How many tables:** in New Mexico in 1881, "every saloon having from one to a dozen tables going at the same time. Mexican monte, keno, faro, high ball … are the prevailing games" (Socorro). In Albuquerque "the saloons, with three to ten gambling tables each … the ring of bottles, the rattle of high ball, the click of billiards and the shake of dice". In Las Vegas NM "each saloon contained a bar, from four to a dozen gambling tables" [ER82, the Socorro, Albuquerque and Las Vegas letters; Las Vegas p. 158].
- **Faro:** an oval table covered in green baize, with a cutout for the banker. On a board on it lies the layout: the 13 spades pasted in order. Players bet with checks worth 50¢-$10 and "copper" a bet with a hexagonal token. The cards are dealt from a dealing box [Wikipedia: Faro]. Stevens sold a German-silver dealing box in a case for $12, a "Spade Layout" for $12 and a "case keeper" (a bead-counter of the cards played) "fancy wood with imitation ivory markers" for $12 [S94 p. ~210]. A picture of a tiger in the window advertised a faro game [Wikipedia]. The 1910 Reno photo shows the dealer, the case-keeper and a lookout on a raised chair. **Size: estimate** from the Bisbee and Reno photos: a heavy table with rounded ends about 3½-4 × 6-7 ft, the layout board about 2 × 3½ ft, the dealer seated at a notch on one long side, the case-keeper beside him, the lookout on a raised stool.
- **Billiards:** the match table is 5 × 10 ft, "but for private houses and public rooms the smaller table, four and one-half by nine feet, has become more popular, and the four feet by eight table is frequently used". The rail top is 34 in from the floor and the slate bed 1 in thick in 3-4 slabs [B98 pp. 15-16]. Room for one table: **15 × 20 ft** (5 × 10), **14½ × 18½** (4½ × 9), **14 × 17½** (4 × 8), **12 × 15** (3½ × 7), with "four feet … between them" when there are several [B98 p. 14]. Stevens' pool table "4x8, that is, 4 ft. 2 in. x 8 ft." [S94 p. 183]. Add cue racks on the wall and a scoring string or wire overhead. Leadville 1879: "pistol-balls that fly across the billiard-table" [IN85].
- **Keno:** a "goose", a wooden bottle-shaped vessel of numbered balls, was used (secondary sources only: archive.org's *Western Lore and Language*, 1996). How keno tables were laid out was not documented in the sources read.
- **Poker:** small square or round tables with 4-6 wooden chairs, as at the back of the Long Branch photo (estimate; about 3-4 ft across).
- **Chairs:** plain wooden chairs (Long Branch), and bentwood chairs by 1910 (Reno). At Table Bluff, novelty chairs of elk antler and of bear fur. Stevens sold chairs (pp. 152-153; not read).
- **Music:** Virginia City in 1865 had a hurdy-gurdy platform for "three musicians" and a theatre "orchestra of four performers" [RI67 p. 480]. At the Bird Cage (Tombstone, from Dec 1881) "Big Minnie … sang, danced, and played the piano" [Wikipedia]. A saloon upright is plausible but no source here gives one for 1882.
- **Free lunch:** offered "with the purchase of at least one drink", recorded from about 1870 [Wikipedia: Western saloon]. A side counter or a table of crackers, cheese, pickles and cold meats.

### 6. On the walls
- Long Branch: framed paintings (landscapes and animals) hung high and tilted forward, a pair of longhorn steer horns over the back bar, and a mounted stag head on the end wall.
- Black Hawk 1897: three mounted deer and elk heads high on the wallpaper, framed prints, a calendar by the door, a bottle advertisement.
- Table Bluff 1889 (a hunter's saloon): **rifles hung on the wall** on racks, elk antlers, a bear skin, pictures and a clock. Guns on the wall are documented here, though this is not a mining town.
- Crystal Saloon, Virginia City: a wall solid with framed pictures, oil paintings and prints, frames touching (HABS 1940).
- "As towns grew, saloons were often elaborately decorated … and oil paintings were hung from the wall" [Wikipedia: Western saloon]. Nudes are not documented by the sources read here: a common claim, unverified.
- Signs and notices ("no credit", prices, "no spitting on the floor"): mass-produced spitting signs are mentioned [Wikipedia: Spittoon], but no 1882 example was found. Treat them as plausible; a hand-lettered price board on the back bar is a safe invention.

### 7. Upstairs, dance halls and variety theatres
- **The hurdy-gurdy (Virginia City MT, 1865):** "At one end of the long hall, a well-stocked bar, and a monte bank in full blast; at the other, a platform occupied by three musicians; between, many lookers-on." The dancing was on the main floor. "For every dance each masculine participant paid one dollar, half going to his partner, and half to the proprietor." After each dance the man took his partner to the bar for whisky or champagne. It ran "from nine o'clock until nearly daylight, interrupted only by two fights." Whisky cost 50¢ a drink and champagne $12 a bottle [RI67 pp. 479-480]. The engraving shows the bottle shelf along the bar wall, a clock, two chandeliers and a band on a raised box in the corner.
- **A Leadville variety theatre, 9 Dec 1881:** "a large building, with good stage and scenery, down stairs being supplied with chairs and tables and up stairs with balcony in one end and a row of boxes on both sides". Girls in the pit served liquor and cigars at the tables, and in the boxes men were "drinking, playing with the girls". The girls asked visitors "to be escorted to the bar and treated with whisky". "Dance houses and gambling hells everywhere" [ER82 pp. 178-179]. Leadville had 25 policemen.
- **The Bird Cage, Tombstone:** opened 26 Dec 1881, with **12 balcony boxes** where prostitutes worked. Miners "could drink and dance all night" [Wikipedia].
- **The dance-house business, Las Vegas NM 1881:** "$5 license for every evening's dance", plus town and territorial licences. A room rented for $100-150 a month. Daytime bar sales were light "because people fear the girls will brush up to them for a treat" [ER82 p. 158].
- **A small-town dance hall:** South Pass City, c. 1890: one room **21 ft × 32 ft 9 in**, "Stairways: None", rough planking, muslin and paper on log walls [HABS WY-35].
- **Stairs:** none of the sources read says where the stair ran. **Inference** from the theatre description and the HABS buildings: in a two-storey saloon or theatre the stair runs inside along a side wall, usually toward the back, to a balcony or a corridor of rooms or boxes. An outside stair on the side wall is common on frontier commercial buildings but undocumented here. Upstairs held rooms (lodging or cribs), the proprietor's office or a private gambling room, or the boxes of a variety theatre. The dancing itself was on the ground floor in every source found. A later, urban parallel: the Chicago Vice Commission (*The Social Evil in Chicago*, 1911, https://archive.org/details/socialevilinchic01chic) describes saloons making money from "rear rooms and from the rental of rooms over the saloon", with drinks "sold in rooms upstairs" at double the price.

### 8. Doors and windows
- **Front:** Grecian Bend (1889): "a double-leaf entrance door which is flush with the front wall. The upper four feet of each door has a six-light fixed window. … large six-light fixed windows on either side of the front entrance", with double-hung 4/4 sash on the sides [HABS WY-37]. Diana (1852): "pairs of round-arched openings" [HABS]. Black Hawk 1897: arched windows with transoms over the doors.
- **Screens rather than batwings:** Stevens sold "Blind Screens" of pine with slats, **6 ft high × 7 ft long** ($10), and glass screens **7 ft high × 6 ft wide** on castors, with bevelled plate glass [S94, "Back bars, partitions, screens", pp. ~20-27]. These stood inside the door so passers-by could not see in. The term "saloon blinds" was in use by 1880 (*Friends' Review*, 13 Nov 1880). By the 1890s towns passed laws requiring "that saloon blinds shall be drawn and the interior clearly exposed" after hours (*The Outlook*, 21 Mar 1896).
- **Batwing (louvred half) doors:** they appear as stock "Saloon Door Blinds" in the 1902 Rock Island and 1904 Radford millwork catalogues (https://archive.org/details/1902catalogueofs00rock). Black Hawk 1897 shows half-height swinging doors inside the front doors. None of the pre-1890 interiors found (1865 hurdy-gurdy, Long Branch, Table Bluff 1889) shows them. Erdoes (*Saloons of the Old West*, 1979) writes that "the typical western saloon with its false front, swinging doors, and carved bar did not make …" (only this snippet is visible; it seems to say the type came late). **Recommendation for 1882:** glazed double doors with a transom, left open in summer, with a slatted blind screen just inside. If batwings are wanted, hang them inside the real doors as an 1880s-90s summer fitting.
- **Window lettering:** the Brunswick Saloon, Telluride (c. 1900) has its name painted large across the lower panes of both display windows, with a glazed double door set back between them and a board false front over. Its glazing is big plate panes: in 1882 the panes would be smaller, like the six-light windows of the Grecian Bend (inference).

### 9. The cellar
- **Basement:** at the Diana Saloon, Sacramento, "the basement with its dirt floor was apparently used only for storage", with 12 × 12 in timber posts and "rear basement doors" [HABS CA-1706].
- **Trapdoor behind the bar:** "there was a trap-door behind the bar down which drunken men might be shunted" (*Daily Colonist*, Victoria BC, 22 Dec 1876, https://archive.org/details/dailycolonist18761222uvic). "To go down into the cellar through the trap door behind the bar" (*The Chronicle*, 27 Aug 1908). So a trapdoor in the floor of the bartender's aisle, with a ladder or steep stair below, is documented. A sidewalk hatch for barrels is not documented here.
- **Beer:** from 1880 refrigeration and pasteurisation came in with Budweiser, but beer was often served at room temperature. "Some saloons kept the beer in kegs stored on racks inside the saloon" [Wikipedia: Western saloon]. With an "Inside" the keg's beer ran through ice-packed tin coils to 1-6 taps [S94]. Kegs could stand in a cellar or back room with the lines rising through the floor or wall (inference). In Leadville in 1879 "empty barrels" served as beds [IN85]. "Lager beer saloons" were a recognised kind by 1881 [ER82, of Chicago]. Brewery wagons delivering to Leadville: not found in the sources read.

### Images to show (all public domain or no known restrictions)
Files in `period/`. The dates are honest; several of the most-reproduced "Old West saloon" photos are 1890s-1910s.

| File | What to copy from it | Place, date | Credit and source |
|---|---|---|---|
| 1865_virginia_city_montana_hurdy_gurdy_house.jpg | Long hall with the bar and bottle shelf on one wall, dancing in the middle, band on a raised box, two 3-4-globe chandeliers, bunting, clock | Virginia City, Montana Terr.; drawn 1865, published 1867 | H. W. Herrick engraving in A. D. Richardson, *Beyond the Mississippi* (1867); Library of Congress Prints and Photographs, no known restrictions. https://www.loc.gov/item/2004679247/ |
| 1870s-80s_dodge_city_long_branch_saloon_interior.jpg | A long narrow room: panelled bar down one side, foot rail and spittoons, back bar with a big framed mirror and steer horns, three hanging lamps on the centre line, pictures tilted out, card tables at the back, carpet runner | Dodge City, Kansas (traditionally the Long Branch); 1870-85 | Photographer unknown; public domain. https://commons.wikimedia.org/wiki/File:Long_Branch_Saloon_interior.jpg |
| 1889_table_bluff_california_kinman_saloon_horns_guns_on_wall.jpg | A plain board bar and bottle shelf; rifles, antlers and skins on the wall; antler and bear-fur chairs | Table Bluff, Humboldt Co., California, 1889 (Seth Kinman's saloon) | Photographer unknown; public domain (Sonoma County Library copy). https://commons.wikimedia.org/wiki/File:KinmanBar.jpg |
| 1897_black_hawk_colorado_toll_gate_saloon_bar.jpg | A Colorado mining-town bar: panelled front, towels on hooks, foot rail, spittoon, back bar with mirror and bottle cases, wallpaper, mounted heads, shaded pendant lamps, arched windows, inner half doors, stove, stained plank floor | Black Hawk, Colorado, 1897 | Photographer unknown; public domain (Denver Public Library photo via LOC American Memory). https://commons.wikimedia.org/wiki/File:1897_Saloon_Blackhawk.jpg |
| 1890s_deadwood_gem_theater_bar_board_ceiling.jpg | A long bar with turned posts and panels, foot rail, back bar of tall mirrored cabinets with clocks, wallpaper with a frieze, a **narrow-board ceiling**, shaded pendant lamps, a littered plank floor | Deadwood, Dakota Terr. / S.D.; 1890s by the clothing (the Gem burned in 1899) | Photographer unknown; public domain; note the Commons copy was upscaled with Waifu2X. https://commons.wikimedia.org/wiki/File:Saloon_Gem_Theater,_Deadwood_(late-1800s).png |
| 1973_habs_grecian_bend_saloon_south_pass_wy_bar_and_back_bar.jpg | The real proportions of a surviving frontier bar and mirrored back bar (the bar is from the 1889 saloon, restored), foot rail, spittoon, plank floor, mounted heads | South Pass City, Wyoming; bar of 1889, photo 1973 | Jack E. Boucher, HABS WY-37; Library of Congress, no known restrictions (US government work). https://www.loc.gov/item/wy0080/ |
| 1973_habs_grecian_bend_saloon_box_stove_1867_pattern.jpg | The long cast-iron box stove (1867 patent) on a hearth, its pipe to a hung flue, the plank floor | South Pass City, Wyoming; photo 1973 | Jack E. Boucher, HABS WY-37; LOC, no known restrictions. https://www.loc.gov/item/wy0080/ |
| 1940_habs_crystal_saloon_virginia_city_chandeliers_pictures_tin_ceiling.jpg | Multi-tier prism chandeliers, the top of the back bar, framed pictures hung high; the tin ceiling is likely post-1882 | Virginia City, Nevada; fixtures late 19th century, photo 1940 | HABS NV-15-29 (Kerrigan or McAfee); LOC, no known restrictions. https://www.loc.gov/item/nv0080/ |
| 1940_habs_crystal_saloon_virginia_city_wall_of_pictures.jpg | A wall packed with framed pictures; a chandelier | Virginia City, Nevada; photo 1940 | HABS NV-15-29; LOC, no known restrictions. https://www.loc.gov/item/nv0080/ |
| c1900_telluride_colorado_brunswick_saloon_front_window_lettering.jpg | The front: a frame false front, display windows lettered with the name, a glazed recessed double door, boardwalk | Telluride, Colorado, c. 1900 | Photographer unknown; public domain (via Western Mining History). https://commons.wikimedia.org/wiki/File:Brunswick_Saloon_Telluride_CO_c._1900.jpg |
| c1900_bisbee_arizona_orient_saloon_faro_table.jpg | A faro bank in play: the long round-ended table, layout board, dealing box, stacks of checks, the players crowded round; pressed-metal wall panels and hats on hooks behind | Bisbee, Arizona Terr., c. 1900 | C. S. Fly; U.S. National Archives (NARA 530986), public domain. https://commons.wikimedia.org/wiki/File:%22Orient_Saloon_at_Bisbee,_Arizona..._Faro_game_in_full_blast._Recognized,_Left_to_right-Tony_Downs_(standing_with_derby)_-_NARA_-_530986.jpg |
| 1910_reno_faro_game_layout_and_dealing_box.jpg | A faro game: the layout board, dealing box, checks, case-keeper, lookout, bentwood chairs (later, but clear) | Reno, Nevada, 1910 | Photo copyright 1910 by L. Levitch (public domain, published before 1927); Library of Congress. https://www.loc.gov/item/2003677182/ |

Candidates found but not downloaded (Wikimedia upload server rate-limited this session; all public domain on Commons):
- Alhambra Saloon, Tombstone: an engraving after a C. S. Fly photo, *Arizona Quarterly Illustrated*, July 1880. https://commons.wikimedia.org/wiki/File:Alhambra_Saloon_Tombstone_1880.jpg
- "Trinidad CO Saloon 1880s" (no data on the file page; check before use). https://commons.wikimedia.org/wiki/File:Trinidad_CO_Saloon_1880s.jpg
- Arcade Saloon, Eldora CO, 1898. https://commons.wikimedia.org/wiki/File:ArcadeSaloon-EldoraColorado-1898-DPL.jpg
- Saloon in Creede CO, W. H. Jackson, c. 1892-99 (SMU). https://commons.wikimedia.org/wiki/File:Creede_(No._1442)_(25877144008).jpg
- Not useful: "Miles city cowboys saloon 1880.jpg" is an exterior, and its "Golden Grain Belt Beers" sign (a brand of the 1890s) shows the 1880 date is wrong.

---

# Period framing

## Framing an 1882 two-storey saloon: period sources and numbers

These are research notes for the Salt Creek saloon: a 54 ft frontage on a corner lot, 80 to 100 ft deep, with a dance hall over the bar.
Period texts were read on archive.org (full text via `archive.org/stream/<id>/<id>_djvu.txt`).
Other sources were blocked here: loc.gov, tile.loc.gov, nps.gov, noehill and the archive.org download mirrors.
The Wikimedia API rate-limited this session after a few calls.
"(calc)" means I worked the number from the cited rule.
"(memory)" means a modern figure I didn't re-read here; check it before it's quoted to anyone.

### Sources (archive.org ids)
- **Hatfield TS**: R. G. Hatfield, *Theory of Transverse Strains*, 1877 (`theorytransvers01hatfgoog`).
- **Hatfield AHC**: R. G. Hatfield, *The American House-Carpenter*, 1880 ed. (`americanhousecar01hatf`).
- **Kidder 1895**: F. E. Kidder, *Architect's and Builder's Pocket-Book*, 1895 ed. (`architectsandbu01kiddgoog`; 1st ed. 1885).
- **Kidder 1905**: the same book, 1905 ed. (`architectsbuilde00kiddrich`).
- **Trautwine**: J. C. Trautwine, *Civil Engineer's Pocket-Book*, 1883 (`civilengineerspo00traurich`).
- **Bell**: W. E. Bell, *Carpentry Made Easy*, 1875 ed. (1st 1858) (`carpentrymadeeas00bell_1`).
- **Woodward**: *Woodward's National Architect*, 1869 (`woodwardsnationa01wood`), the specifications for Design No. 1.
- **HTBH**: *How to Build Houses*, 1889 (`howtobuildhouses00unse`), its bills of material.
- **Hodgson**: F. T. Hodgson, *Stair-Building Made Easy*, 1884 (`stairbuildingmad00hodgiala`).
- **Birkmire**: W. H. Birkmire, *Architectural Iron and Steel*, 1892 (`architecturaliro00birkuoft`).

### 1. The dance-hall floor

**Period floor loads**
- Tredgold (as quoted in Hatfield TS Art. 102, p. 81): a crowd is 120 lb/sq ft, and the floor itself 40.
- Hatfield TS Arts. 104-106, pp. 82-84, weighed people instead:
  - packed infantry at 300 sq in a man gives 66 lb/sq ft;
  - his allowance for the bounce of walking (a ¼ in fall of the body) gives 76 lb/sq ft "moving force";
  - he settles on **70 lb/sq ft live + 20 lb/sq ft for the floor = 90** for "dwellings and assembly rooms" (Art. 115, p. 89; Art. 360, p. 261).
  - The floor's 20 is made up of 3 lb plank, 9 lb plaster ceiling and 5 lb joists (Arts. 96-99, pp. 79-80).
- Trautwine (p. 297 note; index "Crowds, weight of, 297, 595"): a dense crowd is at most about 80 lb/sq ft. "To compensate for momentum" he adopts **100 lb/sq ft** as the limit for crowds.
- Kidder 1895 (pp. 425-426):
  - New York's building law requires 75 lb/sq ft for every floor and **120 lb/sq ft for a place of public assembly**;
  - 80 lb/sq ft is "ample" for an assembly, and 120 occurs only in a jam or panic;
  - for "churches, theatres, and **ball-rooms, 80 to 120** lbs";
  - for floors with "very much vibration … gymnasium-floor, or floors of large public halls", use only **4/5 of the safe beam coefficient** (p. 375).

**Dancing (modern)**
- AISC Design Guide 11 (2nd ed., Table 5.2, as revised in the errata) for group dancing:
  - the dancers weigh only about **12.5 lb/sq ft** spread over the floor;
  - the beat is 1.5-2.7 Hz (90-160 bpm), with a load factor **α = 0.5** on the first harmonic and 0.05 on the second (3-5.4 Hz);
  - a jumping or lively crowd puts in more.
  - Source: https://www.aisc.org/globalassets/aisc/publications/revisions-and-errata/design-guide-11-2nd-ed.-revisions-and-errata-list-2018.pdf
- Ji & Ellis, *The Structural Engineer* 72(3), 1994: one person jumping peaks at **2.3-4.8× body weight**, depending on how long the feet are on the floor.
- ASCE 7 (memory): ballrooms and dance halls are designed for **100 lb/sq ft** uniform live load.
- (calc) The 18 ft, 3x12 at 16 in floor in the table below has its first mode at about 8-10 Hz. That is safely above a fiddle's beat, so it doesn't resonate: it fails by load, not by resonance.

**Joist sizes**
- Hatfield's stiffness rule:
  - **b·d³ = j·c·l³** (b, d in inches; c = joist spacing and l = span, both in feet);
  - it holds 90 lb/sq ft at a sag of 0.03 in per foot of span (1/400);
  - j: white pine 0.65, spruce 0.54, hemlock 0.67, Georgia pine 0.32 (Hatfield AHC Arts. 152-153, pp. 126-128; the same rule in Hatfield TS Art. 361, p. 262).
- (calc) Spans in ft, spruce / white pine:

| Joist | at 12 in | at 16 in | at 18 in |
|---|---|---|---|
| 2x10 | 15.5 / 14.5 | 14.1 / 13.2 | 13.5 / 12.7 |
| 2x12 | 18.6 / 17.5 | 16.9 / 15.9 | 16.2 / 15.2 |
| 3x12 | 21.3 / 20.0 | 19.3 / 18.2 | 18.6 / 17.5 |
| 3x14 | 24.8 / 23.3 | 22.5 / 21.2 | 21.7 / 20.4 |

- Hatfield TS Arts. 117-122, pp. 89-91, works a 20 ft spruce span: 3x9 at 22 in, or 2½x9 at 18½ in (strength rule, safety factor 4).
- **Maximum span**: Kidder 1895 p. 425 says wood beams should not span more than **25 ft** ("difficult to stiffen them sufficiently to prevent vibration under a heavy or moving load"). The NY and Boston laws allow no more than 25 ft between bearings in buildings over 30 ft wide unless girders take the place of a wall.
- **So, for 54 ft**: two girder lines running front to back, 18 ft apart, make three 18 ft bays of 3x12 (or 2x12 at 12 in). One central girder would leave 27 ft spans, over the 25 ft limit.

**Girder and posts**
- Hatfield AHC Art. 163, p. 141: where partitions aren't wanted, "a large piece of timber called a girder, sustained by posts set at intervals of **from 8 to 15 feet**".
- Rule XLVI (p. 142) is the same rule as for joists, with c = the width of floor the girder carries. His worked example: Georgia pine, 14 ft between posts, carrying 15 ft of floor, comes out **8x12**.
  - (calc) Spruce, carrying 18 ft: 10x12 with posts at 12 ft, 8x12 at 10 ft, 10x14 at 14 ft.
- HTBH 1889, Design 27, p. ~75: **girders 10x10, posts 8x8**, joists 2x10 at 14-22 ft, 2x2 bridging, a 1x6 "ribbon" board.
- Woodward 1869: cellar girders under bearing partitions sit on locust posts.
- (calc) A post carries about 12×18×90 ≈ 19,400 lb. An 8x8 at 13 ft is comfortable for that; a 6x6 is marginal for a crowd.
- **In the bar room below**: two rows of posts, 18 ft in from each side wall, 10-14 ft apart along the room. The bar runs along a side wall, inside the post line.

**Bridging, bearings and boards**
- Bridging:
  - Bell pp. 52-53: joists 12 ft or longer are bridged "in one or more places" with crossed board braces, crown side up;
  - Hatfield AHC Art. 161 (pp. 138-139): **cross-bridging every 5-8 ft**; it barely adds strength under an even load, but makes the neighbours help carry a concentrated one;
  - Kidder 1895: cross-bridging of **1¼x3** stock.
- On the walls (balloon frame, which was normal for 1880s frame commerce; platform framing came later):
  - Bell p. 52: the upper joists sit on "a piece of inch board, from 4 to 6 inches wide, which is **let into the studs**" (the ribbon), and are **spiked to the studs**;
  - HTBH 1889: the ribbon is a 1x6.
- On the girder: joists lapped over the top and spiked to each other, or carried on strips on its sides.
  - Richmond 1870 is the warning: the joists were "rested on a slight ledge" of about 4 in.
- Floor boards:
  - Woodward: "narrow, clear 1¼-inch tongued flooring, blind nailed";
  - Kidder 1905 p. 1400: everywhere outside New England, "flooring" means tongued and grooved.
  - (memory) A dance floor would be 7/8-1¼ in pine or maple strips, 3-4 in wide, laid across the joists.

### 2. A joist sawn half through; how floors failed

**What a cut leaves**
- Bending strength goes as b·d²/6 and stiffness as b·d³/12. A cut through half the depth leaves **¼ of the bending strength and ⅛ of the stiffness** at the cut.
- A saw kerf on the tension (bottom) face is a sharp notch: the wood splits along the grain from its root, so in practice the joist keeps nearer **15-20%** of its strength.
- NDS (memory, §4.4.3): sawn joists may not be notched on the tension side in the middle third of the span, and end notches are limited to d/4.
- A kerf cut from the top only carries again once it closes under sag.
- Duration of load: Trautwine (beam tables) found timbers "bore their breaking loads for months before they actually gave way" and took a permanent set at well under breaking. So a cut joist should creep and sag before it goes.

**Numbers** (calc; rough full-size 3x12, ponderosa pine or spruce)
- Effective breaking stress taken as about 5,000 psi (the clear-wood MOR of about 9,400 psi less defects).
- *Wood Handbook* FPL-GTR-190, Table 5-3a (memory, at 12% moisture):

| Species | MOR | MOE |
|---|---|---|
| Ponderosa pine | 65 MPa | 8.9 GPa |
| Engelmann spruce | 64 MPa | 8.9 GPa |
| Interior Douglas-fir | 87 MPa | 12.6 GPa |

- The 18 ft joist breaks at about **555 lb/sq ft**, and at about **140** (or about 100 with the notch) once half cut.
- A packed crowd is 65-70, so **one** half-cut joist, with boards and bridging sharing out its load, sags and cracks but does not fall.
- **The girder is the weak point.** A 10x12 on posts 12 ft apart, carrying 18 ft, breaks at about **310 lb/sq ft**, and at about **75** half cut. That is less than the floor (20) plus a dancing crowd or onlookers packed to watch (40-65, ×1.25-1.5 for the dancing).
- It drops a panel about 12 ft along the girder and up to 18 ft to each side, hinging on the wall ribbons.
- For the game: saw the girder, or saw 3-4 neighbouring joists about ¾ through.

**Documented collapses** (all were girders or bearings, not single joists)
- **Richmond, Virginia, 27 April 1870, the Capitol disaster:**
  - the gallery fell onto a courtroom floor crowded for a hearing, then the floor fell to the storey below;
  - a contemporary account says a girder under a partition snapped, and that the joists rested on a roughly 4 in ledge rather than being let into the walls;
  - **62 killed, 251 hurt**;
  - sources: en.wikipedia.org/wiki/Virginia_State_Capitol; G. L. Christian, *The Capitol Disaster* (1915), archive.org `capitoldisasterc00chri`.
- **London, Ontario, 3 January 1898, City Hall:** a second-floor room crowded for the mayor-elect; a wooden support beam under it snapped; **23+ killed, about 150 hurt** (londonfirefighters.ca/1898/01/03/city-hall-collapse/).
- **Wellsville, New York, about 1858 (recalled in the *Wellsville Daily Reporter*, 24 June 1884):**
  - a Masonic festival in a hall over a paint shop;
  - the floor gave way and "300 or 400 persons were precipitated to the floor beneath, which also gave way";
  - source: alleganyhistory.org, "The Floor Gave Way".
- Later, and a dance: the **Pickwick Club, Boston, 4 July 1925**, a second-floor club where couples were dancing (the Charleston); the building came down and **44 died** (en.wikipedia.org/wiki/Pickwick_Club_collapse).

### 3. The gallery (balcony) over the boardwalk, and the outside stair

**Period gallery details**
- Woodward 1869 (piazza and veranda framing):
  - floor joists **2x6 at 2 ft centres**;
  - piazza plate 4x7, cased; veranda plate 3x8;
  - sills and cross-sills 4x6 at each post;
  - posts on locust posts set **3 ft in the ground**, or on piers **8 in square**;
  - "plane up and **chamfer** the small columns of veranda"; 1¼ in tongued floor, joints in white lead.
- HTBH 1889 bills: porch balusters 2x2x10 in; turned balusters 3x3x18 in.
- Typical western galleries, from photographs (not measured):
  - **4x4 to 6x6 posts, chamfered or turned**, at the walk's street edge, roughly one per store bay (**8-12 ft**);
  - a plate or beam across the post tops; joists running back to the front wall, on a ribbon there and spiked to the studs;
  - a railing of a top rail, a bottom rail and square or turned balusters, about 30-36 in high.
- Photographs to work from:
  - Tombstone: C. S. Fly, "Tombstone (probably in 1881).jpg" and "Tombstone year 1881.jpg" (the Grand Hotel), and Commons' "Category:Allen Street (Tombstone, Arizona)" (HABS 1937);
  - Virginia City: Commons' "Category:Virginia City, Nevada" (1867-68 views, Watkins 1873-83, HABS 1937 C Street);
  - Leadville: the Clarendon Hotel, Harrison Ave, about 1879, with a second-storey balcony and balustrade (Denver Public Library);
  - Georgetown: the Grand Central Hotel, with a balcony and a sign on a post at the edge of the board walk (Denver Public Library).

**Modern checks** (memory)
- A balcony is designed for 1.5× the room's live load, up to 100 lb/sq ft.
- Guards (IBC): 42 in high (IRC 36 in), openings that stop a 4 in sphere, the top rail good for 200 lb or 50 lb per foot.
- (calc) At 100 lb/sq ft, a 10 ft deep gallery puts about 5,800 lb on each post. A 6x6 carries that comfortably; a 4x4 is slender at 11 ft.
- The post-top beam over 10 ft should be about **6x10 or 4x12**. Blow out one post and it spans 20 ft and folds; the joists hinge down from the wall ribbon.

**The outside stair**
- On a corner lot it climbs the **side-street wall** (or the rear), along the wall to a landing at the hall door.
- Steps:
  - Hatfield AHC (stairs, p. 244): tread = 24 − 2 × riser for dwellings, so a **7½ in rise takes a 9 in tread** (an exterior stair would use about 7-7¾ in rise and 10-11 in tread);
  - Hodgson 1884 p. 12: the carriage is **rough strings** "cut from undressed plank", with "half-space" landings; his dog-leg example is 5 ft 8 in across two flights, about 2 ft 10 in each.
- A rise of about 15 ft (a 14 ft bar room ceiling plus the floor) is about 24 risers, so it needs a mid landing about 4x4 ft on 4x4 or 6x6 posts.
- Build it **3½-4 ft wide**: three **2x12 (or 3x12) stringers**, 1¼-1½ in treads, a rail at 34-36 in, with balusters on the open side.
- Modern minimums (memory): 36 in wide (IRC) or 44 in (IBC); 100 lb/sq ft plus a 300 lb point load.

### 4. The cellar
- Walls:
  - Woodward 1869: cellar walls **20 in thick** of flat building stone in lime mortar, dug 5 ft below grade (a dwelling);
  - Kidder 1905 (cost of masonry): "rubble cellar walls, **18 ins. to 2 ft thick**, laid in lime mortar".
- Depth: a saloon's keg cellar would be **7-8 ft clear**, partly below grade. Kegs need it cool.
- The floor over it: the bar-room joists sit on a sill bedded on the stone wall. Where the cellar runs under the room, a girder on posts (or on stone piers) at **8-15 ft** carries them (Hatfield AHC Art. 163).
- Access:
  - a **trapdoor behind the bar**: a framed opening with doubled trimmers and a header (Kidder 1895 "carriage-beams, headers and tail-beams"), about 2½x4 ft, and a ship's ladder or steep stair;
  - a **sidewalk hatch**: a pair of wooden or iron doors in the boardwalk over the vault, for rolling kegs down skids.
- In bigger towns the sidewalk vault had **vault lights** (glass lenses 1½-2 in in iron or concrete frames) and wrought-iron "illuminating doors" for "sidewalk elevators, area steps and hatchways" (Birkmire 1892 Art. 226, pp. 146-147). The New York building law's "Vault Lights and Areas Protected" is on p. 184.

### 5. Brick or stone fronts on frame buildings
- After the fires, fire limits banned new frame buildings in town centres:
  - Denver banned frame in its fire limits from 1862-63;
  - Golden was trying from 1878;
  - Georgetown burned in 1881;
  - Leadville's 1879-80 blocks were brick hauled in by wagon (WebSearch summaries; the original ordinances weren't reachable).
- A common 1880s compromise was a **brick (or cast-iron and pressed-metal) front on a frame body**:
  - the front was 2-3 wythes: Kidder 1905 says "most cities require **13-inch walls**" for the upper storey and for two-storey buildings, and 12 in may do for the top storey;
  - cast-iron columns and lintel at the shop front (Birkmire 1892);
  - a brick parapet hiding the roof;
  - frame side and rear walls.
- The **wooden false front** is the cheaper version: the front wall's studs run up past the roof to a cornice, stiffened by braces back to the roof framing or the ceiling joists.

### Numbers to build from

| Member | Size (in) | Spacing | Span | Source |
|---|---|---|---|---|
| Hall floor joists | 3x12 (or 2x12 at 12 in) | 16 in | 18 ft (three bays across 54 ft) | Hatfield AHC Rule XXXVIII, pp. 126-128, spruce j = 0.54 (calc) |
| Joist limit | 3x14 | 16 in | 22 ft max; never over 25 | Kidder 1895 p. 425 |
| Bridging | 1¼x3 crossed | rows every 5-8 ft | between joists | Hatfield AHC Art. 161; Kidder 1895 |
| Hall floor | 1¼ T&G pine (or 7/8 maple strip) | across joists | – | Woodward 1869 |
| Wall bearing | 1x6 ribbon let into studs, joists spiked to studs | – | – | Bell 1858/75 p. 52; HTBH 1889 |
| Girders (2 lines, front to back) | 10x12 (8x12 at 10 ft, 10x14 at 14 ft) | 18 ft apart | 12 ft between posts | Hatfield AHC Rule XLVI, p. 142 (calc); HTBH 10x10 |
| Bar-room posts | 8x8 (chamfered), on stone footings in the cellar | 12 ft along each line | about 13 ft high | HTBH 1889 (8x8); Hatfield AHC 8-15 ft |
| Design load, hall | 70 live + 20 dead (period); 100 (Trautwine, ASCE); 120 (NY law) lb/sq ft | – | – | Hatfield TS Art. 115; Trautwine p. 297; Kidder 1895 p. 425 |
| Dancing | crowd about 12.5 lb/sq ft, load factor 0.5 at 1.5-2.7 Hz; one jumper 2.3-4.8× body weight | – | – | AISC DG11; Ji & Ellis 1994 |
| Gallery posts | 6x6 (4x4 light), chamfered | 10 ft (one per bay) | about 11 ft to beam | Woodward 1869; photos |
| Gallery beam (on posts) | 6x10 or 4x12 | – | 10 ft | calc at 100 lb/sq ft |
| Gallery joists | 2x8 (Woodward 2x6 at 2 ft for a porch) | 16 in | 10 ft, beam to front-wall ribbon | Woodward 1869; calc j = 0.65 |
| Gallery rail | 2x4 top rail, 2x2 or 3x3 balusters | balusters at 4-5 in | 36 in high (period); 42 in modern | HTBH 1889; IBC |
| Outside stair stringers | 2x12 or 3x12 rough plank, 3 per flight | – | 3½-4 ft wide flight | Hodgson 1884 p. 12 |
| Stair steps | 7½ rise / 9-10 tread (about 24 risers to 15 ft) | – | mid landing 4x4 ft on 4x4-6x6 posts | Hatfield AHC p. 244 |
| Cellar walls | rubble stone 18-24 in thick | – | 7-8 ft clear | Woodward (20 in); Kidder 1905 |
| Cellar girder and posts | 10x10 to 10x12 on 8x8 posts | posts 8-12 ft | – | HTBH 1889; Hatfield AHC |
| Trapdoor | about 30x48 in opening, doubled trimmers and header | – | – | Kidder 1895 (headers and trimmers) |
| Brick front | 13 in (3 wythes) brick, cast-iron shop-front columns | – | 54 ft | Kidder 1905; Birkmire 1892 |
| Sabotage target | 10x12 girder half-sawn leaves about 25% (75 lb/sq ft); one joist half-sawn leaves about 140, shared, so it holds | – | – | calc |

---

# Games and film

## The saloon as a place: what games and film do, and what Salt Creek should copy

Research note, 2026-11-10. **How this was gathered:** web search snippets plus Wikipedia (curl). The
session's network blocks kotaku.com, reddead.fandom.com, 80.lv and gamesbeat.com, so those pages
were read only through search-result excerpts, never in full. No Rockstar level-design talk or art
book text about the saloons turned up. Claims marked **(memory, unconfirmed)** come from my own
knowledge of the games and films and were not checked against a source. No images were saved.

### 1. Red Dead Redemption 1 and 2

- **Saloons are the town's hub.** Kotaku's "Every Bar in RDR2, Reviewed" (Samuel Horti, 2018-12-27)
  treats them as their towns' hubs. Its writer spent "tens of hours" in them. It gives Smithfield's in
  Valentine 5/5 as "no-frills… dirty tables, patchy walls and rowdy drinkers". Keane's, the rival
  saloon down the street, is "remarkably clean; the floorboards look like they're scrubbed daily".
  https://kotaku.com/every-bar-in-red-dead-redemption-2-reviewed-1831342570 (excerpts only).
  *Lesson:* character comes from wear and a crowd, not from size.
- **Smithfield's (Valentine):** the wiki says it is "always lively, at day and night". It has a barber
  in the back right and hotel rooms upstairs that the player can't use. Poker is played on the main
  floor. NPC day routines end in the saloon in the evening.
  https://reddead.fandom.com/wiki/File:Smithfields_Saloon_seen_from_the_north.jpg ,
  https://www.powerpyx.com/red-dead-redemption-2-where-to-play-poker/ ,
  https://mein-mmo.de/en/3-npcs-red-dead-redemption-2-einen-tag,286499
  Layout **(memory, unconfirmed):** the door is on the street corner, the bar runs along one long
  wall, the tables and piano are in the open middle, the stair is at the back to an upper landing, and
  there is a side door to the alley.
- **The Valentine brawl ("Americans at Rest"):** Bill head-butts a patron on his way in, and the whole
  room joins the fight. Tommy throws Arthur *out through the front window*, and the fight goes on in
  the rain on the muddy street.
  https://www.powerpyx.com/red-dead-redemption-2-americans-at-rest-walkthrough/ ,
  https://guides4gamers.com/red-dead-redemption-2/quest/americans-at-rest
  Players still throw NPCs through those windows for fun: one "can't eat at the Valentine saloon
  until all of the front windows are gone"
  (https://gamingbible.com/news/red-dead-redemption-2-combat-mechanic-718849-20250226).
  *Lesson:* the front windows are a way out, a stage and something that breaks, all at once.
- **La Bastille (Saint Denis):** Kotaku says the upstairs "is basically a luxury hotel, with high
  ceilings and thick rugs". From your room you step onto a *shared balcony* over a square with a
  fountain. There is a stained-glass window over the staircase, and in the back room "upbeat piano"
  feels as if it might start a dance (Kotaku excerpt, URL above). The first Saint Denis mission ("The
  Joys of Civilization") opens with questions at its bar and has no fight inside
  (https://reddeadredemption2.wiki.fextralife.com/The+Joys+of+Civilization).
  *Lesson:* a saloon can be a place for information, not only for fights.
- **Rhodes:** in "A Short Walk in a Pretty Town" you walk down the main street to the saloon to meet
  the Grays. The ambush that kills Sean is sprung on that street
  (https://guides4gamers.com/red-dead-redemption-2/quest/a-short-walk-in-a-pretty-town).
  *Lesson:* the walk up to the saloon's front is the build-up. The street and the facades are part of
  the place.
- **Armadillo (RDR1):** it has "a large accessible balcony" upstairs. A back door leads out to the
  balcony, and players jump from it straight onto their hitched horse. The saloon is also the
  safehouse (https://breezewiki.discard.no/reddead/wiki/Armadillo). *Lesson:* the balcony is a second
  way out and connects to the street.
- **Other RDR2 towns:** Wikipedia gives the context: Valentine is a livestock town, Armadillo a
  cholera ghost town, Tumbleweed is declining, and Blackwater is still being built
  (https://en.wikipedia.org/wiki/Red_Dead_Redemption_2). The rule that a saloon's state shows its
  town's state comes from that. I found no layout detail for Tumbleweed, Blackwater or Strawberry.
  Ambarino has no saloon (wiki excerpt). **Not found:** any Rockstar GDC talk or interview about
  saloon layout. Rob Nelson's GamesBeat deep dive exists, but the session couldn't read it.

### 2. Other games and films

- **Hunt: Showdown (Crytek).** Compounds are built "like little multiplayer maps within the larger
  map" and give "both teams defensive and offensive options" (Crytek interview excerpt,
  https://press.crytek.com/hunt-showdown-developers-discuss-level-design-in-latest-dev-diary).
  Locked doors can be broken with a sledgehammer or axe, and each way of breaking one sounds
  different (https://www.dualshockers.com/hunt-showdown-level-design-dev-diary/). Critics single out
  the sound: "creaking boardwalks… inside, jangling chains and crunching glass are to be avoided"
  (PCGamesN, quoted at https://en.wikipedia.org/wiki/Hunt:_Showdown_1896). DeSalle has a saloon with
  swinging doors
  (https://gamingtrend.com/news/time-to-explore-desalle-with-a-new-map-for-hunt-showdown/).
- **Desperados III:** at night, enemies see badly unless they carry a lamp or look into a lit area
  (https://en.wikipedia.org/wiki/Desperados_III). *Lesson:* at night, the lamps decide who is seen.
- **Call of Juarez: Gunslinger:** the whole game is told by Silas Greaves while he holds court in a
  saloon (https://digitaltrends.com/gaming/call-of-juarez-gunslinger-review). The saloon frames the
  stories. I found no layout detail.
- **Kingdom Come: Deliverance II:** taverns are hubs for trade, rooms and rumours, with dice tables
  "often upstairs or outside" (https://peace.gamerguides.com/kingdom-come-deliverance-ii/database/points-of-interest/activities/dice).
  Town taverns are louder, and a brawl costs you reputation (https://sevenswords.uk/?p=10699).
- **Dishonored, the Hound Pits Pub:** it is the hub between missions. Arkane cut a third floor while
  iterating on it (Eurogamer interview via
  https://rpgwatch.com/news/dishonored--peeling-back-the-layers-eurogamer-20859.html). I couldn't
  confirm the details.
- **Alone in the Dark (Slaughter Gulch):** a cellar under the saloon is reached by a *trapdoor behind
  the bar*, with a secret way into a prison
  (https://aloneinthedark.fandom.com/wiki/Cellar_(Saloon)).
- **Not covered (no usable sources):** Wild West Online, Westerado, Weird West, Hard West, Hitman,
  Thief.
- **Film: Unforgiven (Greeley's/Skinny's).** Ned and the Kid are upstairs with the women while
  Little Bill beats Will in the bar below. They *escape through a back window*. Later, Ned's corpse
  is *displayed in a coffin outside the saloon*. Will walks in alone with a shotgun, kills Skinny,
  shoots Bill and the posse, and *orders the rest of the men out*
  (https://en.wikipedia.org/wiki/Unforgiven). The rain was shot at night, and the rain machine's
  water froze (https://www.slashfilm.com/956088/a-snowstorm-on-the-unforgiven-set-meant-skirting-every-studio-rule).
  The cinematographer describes Munny "backlit" over Bill
  (https://www.dga.org/craft/dgaq/issues/2003-summer-2020/shot-to-remember-unforgiven).
- **Film: Rio Bravo (1959).** A wounded killer hides in the saloon's *loft over the bar*. Dude sees
  *blood drip from above into a beer glass* on the bar, turns and shoots up into the loft
  (https://filmsite.org/riobravo.html, https://en.wikipedia.org/wiki/Rio_Bravo_(film)). This is the
  model for an upper floor that is a threat sitting over the bar.
- **Film: The Hateful Eight (Minnie's Haberdashery).** Tarantino treated the one room "like a
  landscape". Production designer Yohei Taneda divided it into areas with *pillars and beams instead
  of walls* (https://thewrap.com/hateful-eight-haberdashery-location-design-tarantino ,
  https://ny411.com/blog/post/production-designer-yohei-taneda-reteams-with-tarantino-on-the-hateful-eight).
  Jody hides in the *cellar* and shoots Warren *up through the floor*
  (https://thecinemaholic.com/the-hateful-eight-ending-explained-who-poisoned-the-coffee/). Mobray
  naming the room's halves after the war's sides is **(memory, unconfirmed)**.
- **Film: Tombstone.** The town was rebuilt at the Mescal set, with the Oriental Saloon among its
  landmarks. The real Bird Cage was "a huge inspiration" for the production design
  (https://www.slashfilm.com/1860088/tombstone-filming-locations-explained). The Bird Cage itself:
  12–14 curtained *balcony cribs overhanging the main floor*, a *basement poker game* said to have run
  about 8 years, and 120–140 bullet holes still in it (https://en.wikipedia.org/wiki/Bird_Cage_Theatre ,
  https://tombstonebirdcage.com/balconycribs.html). The exact numbers vary between sources.
- **TV: Deadwood (the Gem).** Swearengen watches the town, and a duel, *from the Gem's balcony*. The
  real Gem had a bar and theatre at the front and rooms at the back
  (https://en.wikipedia.org/wiki/Gem_Theater_(Deadwood,_South_Dakota)). The set's blueprints were
  lost (https://www.primetimer.com/item/Deadwood-The-Movies-production-designer-had-to-carefully-watch-old-episodes-because-blueprints-for-original-sets-disappeared-mpSbBw).
- **History: the card-table killing.** In Saloon No. 10 (1876), Hickok took the only open chair,
  which put his back to the door. McCall walked up behind him and shot him
  (https://en.wikipedia.org/wiki/Old_Style_Saloon_No._10 , https://history.com/this-day-in-history/wild-bill-hickok-is-murdered).
  The accounts disagree about the seat.

### 3. Principles, each with an example

1. **What you see first from the door.** Through the batwings you should see the bar, the stair and
   the gallery. The Level Design Book says to let the player survey a cover arena before the fight,
   either with enemies unaware and visible from the entrance or from a vista
   (https://book.leveldesignbook.com/process/combat/encounter , read through a mirror). Will walks
   in, takes in the posse, then acts (Unforgiven).
2. **The bar is a stage and cover.** The fight starts there (Valentine). The bar is half cover with
   breakable glass behind it: a back bar with a large mirror, up to 42 ft (13 m) of bar in a
   150 ft (46 m) building (SAH Archipedia's Colorado entries, from search excerpts only; I didn't
   pin down which page, https://sah-archipedia.org). The Level Design Book's
   advice that every strong position needs a counter-approach comes from a practitioner rule
   (https://www.thepromptindex.com/skill/1164-level-design), not from the book itself.
3. **The stair and gallery are a second level.** Rio Bravo's loft ambush, the Bird Cage's cribs
   overhanging the floor, the Unforgiven upstairs. High ground is "a huge advantage" over the room
   below (https://book.leveldesignbook.com/process/blockout/massing/prospect-refuge),
   so the gallery's posts and balustrade have to be breakable cover, not a safe perch.
4. **The back room** is for games, deals and overhearing: Bastille's back room, the Bird Cage's
   basement game, KCD's upstairs dice, Saint Denis' bar as the place to ask questions.
5. **Ways out on every floor.** The front door, a window to the street (Valentine), a back window
   from upstairs (Unforgiven), a balcony door to the horse (Armadillo). Hunt's compounds give both
   sides options in and out.
6. **Light is the mood and decides who is seen at night.** Desperados III: the lamps decide who is
   seen. Unforgiven: a backlit figure, rain outside. **(Memory, unconfirmed:** RDR2's saloons at night
   are a few warm pools of light with dark corners.)
7. **Size against movement.** The real saloons were long and narrow (search excerpts above). From a
   seat you should be able to read every face, and you should cross the room in about 6–8 strides
   (**our proposal**, not sourced). RDR2 keeps saloons small so the crowd is dense (memory).
8. **Crowd density.** A crowd "at day and night" (Smithfield's). A brawl pulls in the whole room
   (TV Tropes "Escalating Brawl", https://www.tvtropes.org/pmwiki/pmwiki.php/Main/EscalatingBrawl).
   A gunfight empties it (Will: "all of you get out").
9. **Places to sit and watch.** A seat with its back to the door is the classic vulnerability
   (Hickok). Gunslinger's narrator holds court from a table. Swearengen watches from his balcony.
10. **Zones by posts, not walls.** The Hateful Eight: sightlines stay open and the room reads as one.
    Here, the same posts carry the floor above.
11. **The outside advertises the inside.** False fronts carried the sign
    (https://atlas.thc.state.tx.us/NR/pdfs/84001849/84001849.pdf). Ned's coffin outside Skinny's.
    Rhodes' walk up the street. Batwings and porches
    (https://en.wikipedia.org/wiki/Western_saloon).
12. **Sound.** Creaking boardwalks and crunching glass (Hunt). The room's noise rising and falling
    with events (KCD).

### 4. The specific pieces

**(a) A balcony over the street on posts.** Armadillo: the balcony is reached through a back door and
you can jump from it to the street. Swearengen: the balcony as a place to watch from. Keane's: a fan
source puts a balcony over Valentine's main street (unverified). La Bastille: a shared balcony
outside the upstairs rooms. *For us:* reach it through a door from the upstairs rooms. Hold it on a
few posts the player can see, standing at the boardwalk's edge, so the posts read as its weak point.
Put waist-high railing and boards on it, so men on it are half hidden from the street and can be
shot from below at an angle. Leave a clear fall line onto the boardwalk and hitching rail. **(Our
proposal:** whoever stands on it gets the vista from Principle 1, so it is the enemy's best post and
the player's best target.)

**(b) A dance hall over the bar.** There are two models. The *open well* is the Bird Cage's cribs, or
a gallery round a void. The *closed floor* is Rio Bravo's loft, where what happens upstairs is felt
below only through the ceiling. Your mission needs the closed floor. A real collapse shows the
mechanism: in Chicago in 1948 a dance-hall floor "broke loose completely on one side" and threw
dancers into the billiard room below
(https://anengineersaspect.blogspot.com/2012/03/the-st-patricks-day-chicago-dance-hall.html; also
the Pickwick Club, Boston, 1925, https://wikipedia.com/wiki/Pickwick_Club_collapse). I found no
19th-century saloon case. *For us:* exposed joists and girders over the bar, with lamps hung from
them. Let the upstairs come through: music, stamping feet, dust sifting down, a lamp swaying, a drip
(Rio Bravo). Then the warning grows: a sag and the creak of a girder. When it goes, one end tears
loose and the floor hinges down onto the bar. Upstairs is reached by its own stair from the bar room
and by the outside stair.

**(c) An outside stair as a second way up.** Unforgiven: the men upstairs leave by a back window
without passing the bar. Armadillo: the back door onto the balcony. **(Memory, unconfirmed:** an
outside stair at the side or back was a common way into an upstairs hall or rooms with its own
entrance on frontier commercial buildings.) *For us:* it lets the dance hall's paying crowd come and
go without passing the bar. It gives the saboteur a way to come and go unseen. It gives the AI a
route to flank the player, and the player a way into the gallery fight from outside.

**(d) A cellar.** Alone in the Dark: a trapdoor behind the bar, and a hidden way on from the cellar.
The Hateful Eight: a man hidden under the floor shoots up through the boards. Bird Cage: the
long-running game in the basement. Pendleton, Oregon: basements under businesses joined by vaults
under the sidewalks, used for goods, gambling, opium and bootlegging
(https://1859oregonmagazine.com/think-oregon/history/pendleton-underground-tunnels/ ,
https://redmondspokesman.com/?p=12544). *For us:* a trapdoor behind the bar down to the barrels,
with a sidewalk hatch or chute to the street. It works for smuggling, a hidden gunman, an escape,
and somewhere for the dance floor's wreck to fall into.

### Design rules, ranked by how much they matter to our missions

1. **The floor over the bar must read as a ceiling the player watches.** Exposed joists and a girder,
   lamps hung from them, and the dance upstairs heard and felt below: thumps, dust, a drip, a swaying
   lamp (Rio Bravo; Chicago 1948). The payday collapse is only fair if the player saw it coming.
2. **Seat the card-table murder.** The player's chair must see the victim's face and the man who comes
   up behind him. The victim's back faces the door (Hickok). The back-bar mirror shows what is behind
   the player.
3. **Every floor has at least two ways out:** front door, back door, front windows, a back window
   upstairs, the balcony door and the outside stair (Valentine, Unforgiven, Armadillo, Hunt).
4. **The balcony stands on a few visible posts over the boardwalk** and is reached through a door.
   Men on it are half hidden by railing and easy to read from the street (Armadillo, Deadwood).
5. **What you see first through the door** is the bar along one side, the stair at the back and the
   gallery above. The player sizes up the fight before it starts (Level Design Book; Unforgiven).
6. **The bar is cover with glass behind it:** a counter waist to chest high, then a back bar of
   bottles and mirror that shatters (Valentine; the Brunswick back bars).
7. **The gallery and stair are the second level the AI takes.** Breakable balustrade, falls onto
   tables (Rio Bravo, Bird Cage). No perch is safe.
8. **Zones by posts, not walls.** The same posts carry the floor above, so a broken post is both a
   tactical choice and the structure giving way (The Hateful Eight).
9. **Night: a few warm pools of lamp light.** Who is lit is who is seen (Desperados III; our
   `SightLight`). A smashed lamp changes the fight.
10. **The outside advertises the inside:** a false front with the sign, lit upstairs windows on payday,
    the balcony and its crowd, and the walk up the street as the build-up (Rhodes, Unforgiven).
11. **A dense, worn room:** crowded day and night, dirty tables, a brawl that pulls everyone in and a
    gunfight that empties the room (Smithfield's, the brawl tropes).
12. **A cellar by a trapdoor behind the bar,** with a hatch to the street, for smuggling, a hidden
    shooter, an escape, and as the pit the wreck falls into (Hateful Eight, Pendleton, Alone in the
    Dark).
