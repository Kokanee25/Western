# The Salt Creek Hotel: the design (#1146)

Sean, 2026-11-23 (#1146): design the hotel first, as a session of its own, **as opulent as an 1880s
hotel would be**: nice wood, a nice small bar, a kitchen, **a cellar with something interesting to
find**, nice rooms, carpet and wallpaper. This is the design only: no game code changed. Building is
its own sessions (#1146's first prompt; the fancy-building parts list in its first comment).

**For Sean, in one look:** the drawings in `hotel/` (ground, upper, cellar, the front, the gallery's
section, the balcony; `hotel/draw_plans.py` draws them from one set of numbers). **Your calls are §9**: the front's
material, the gallery's roof, a third storey or not, the cellar's secret (§5: A, B or C), and the
landlady's "fifty cents" line.

## 1. What it is, in a paragraph

The Salt Creek Hotel, built in 1881 by the landlady's late husband on the best lot on Main Street's north
side (lot 10, 25.2 x 20 m; the saloon lane west, a lane and the doctor's east, Back Street 30 m behind).
It is the town's pride and the Baron's dining room: where the railroad's men, the mine's men, drummers
and the Army's officers stay, and where the Baron gives his suppers (Rourke and the surgeon on Payday
Night; the captain the next day, MISSIONS.md). A frame building **dressed as well as money freighted on
the railroad could dress it**: the millwork, glass, carpets, paper and brass all came out on the cars;
the walls are local lumber. Its long gallery over the walk is where the girder men drink the night after
(the Balcony Ambush, C9 a).

## 2. What the period says (research, 2026-11-23)

Two sub-agents: one on the period (the National Register nominations for the Teller House and the Hotel
de Paris read in full; the rest secondary and marked), one on the story bible. loc.gov, sah-archipedia.org
and theclio.com were refused here, so no HABS drawings were opened (RECIPE.md "The references").

**The models, by date and size:**

| Hotel | Built | Size | What it gives Salt Creek |
|---|---|---|---|
| **Teller House**, Central City | 1871-72 | 4 storeys, brick, ~150 rooms, ~$104,000 | The sequence: street doors to the desk and to the bars; hall and stair to the desk; the dining room behind the lobby; **the kitchen in a one-storey rear wing**; a wide stair with one landing and carved newels; a long bar with painted walls later papered over; "the largest and most elaborately furnished hotel" outside Denver (Fossett, 1880). A 10 x 10 ft single at **$3 a night**. Iron balconies added 1873 so it wouldn't look like "a New England factory". NRHP nomination. |
| **Hotel de Paris**, Georgetown | 1875 | 2 storeys, 10 bedrooms upstairs, 6 big rooms down | **The small-hotel model**: a modest house dressed like a city one; the cellar for wine in casks with the bottling gear, chilled food, meat and early canned goods; no bar; laundry by Chinese laundrymen. (Its French front and electric light are c.1889-93: too late.) NRHP nomination. |
| **Grand Imperial**, Silverton | 1882-83 | 3 storeys, mansard, ~37-40 rooms | **The nearest in date and town**: the largest building in a San Juan silver town, a cherry back bar with mirrors in three arches. |
| **Clarendon**, Leadville | 1879 | Tabor's; joined to the opera house by a bridge | The hotel and the opera house as one town's showpieces (#1143 comes next). Leadville had gas streetlights from Nov 1879. |
| Windsor, Denver | 1880 | 5 storeys, ~400 rooms, stone | The city's scale: too big for Salt Creek, a picture of what she copies. |
| Beaumont (Ouray 1886), Strater (Durango 1887-88) | **after 1882** | $70-75k brick | Not models: later, bigger. |

**What a town of Salt Creek's size could afford in 1882:** a two-storey frame hotel of 12-25 rooms
for perhaps $15,000-40,000 (an inference from the costs above; no primary figure found). Lumber and
brick local; **everything fine came on the cars**: furniture from Denver (the Teller's from Rogers,
Bradley & Co.) or Chicago, the bar and back bar, plate glass, mirrors, the range, carpets, wallpaper,
brass. That is the design's rule: **local walls, freighted dress**.

**Dates that matter (anachronism traps):**
- **Pressed-tin ceilings: no.** The first known installation is 1885, the patents 1888 on. Plaster
  ceilings with a cornice and a plaster rose round the chandelier, or a beaded board ceiling painted.
- **Lighting: kerosene.** Gas works served Georgetown (1876) and Leadville (1879), not a town of a
  thousand; electric light is too early. Kerosene chandeliers and brackets, a newel lamp.
- **The bar's maker reads "J. M. Brunswick & Balke Co."** (1873-84), never Brunswick-Balke-Collender
  (1884). Back bars cost a few hundred dollars.
- **No Mesker cast-iron front** (Mesker catalogues peak 1890-1910); foundry columns from St. Louis or
  Chicago are possible but a frame building doesn't need them.
- **Waitresses, not "Harvey Girls"** (1883). Chinese laundrymen are right for 1880s Colorado (Denver's
  anti-Chinese riot was 31 Oct 1880): the hotel's washing could go to a laundry on Back Street.
- **Wallpaper in three bands** (dado, filling, frieze; darker at the bottom) is right for 1880;
  Lincrusta (embossed) arrived in the 1880s, a rich touch for the dado. Ingrain carpets are flat,
  reversible and cheaper (36 in strips); Brussels and Wilton the best, sewn up from narrow loom widths
  (27 in).
- **Plumbing:** chamber pots and washstands upstairs, privies in the yard, a bath room with a tin tub;
  hot water to the bedrooms (Hotel de Paris) is upmarket and is left out.
- **Tunnels** under Colorado towns are mostly legend (Old Colorado City; the Brown Palace's is 1892):
  §5 B keeps its drift short, timbered and explained.

## 3. The front

- **Two storeys, 80 ft across, about 32 ft to the cornice top** (`hotel/front.png`): the floor 2.5 ft
  (0.75 m) over the street, as the walk's `h`; the ground storey 13 ft 6 in floor to floor (tall
  windows, a lobby that feels high), the upper 11 ft 6 in, a frieze, a cornice on paired scroll
  brackets, and a **name board** over it, **SALT CREEK HOTEL** in gilt letters on deep red, with a small
  pediment over the middle and **1881** in it. Lettering is the game's own (sign_art), never the image
  model's.
- **Painted clapboard in three colours** (recommended; Sean's call, §9 1): the set-direction brief's
  soft blue-grey body, cream trim (corner boards, casings, cornice, posts), a deep red on the brackets,
  the name board and the sash. Narrow, smooth, planed lap (4 in to the weather), not the street's rough
  boards: the first thing that says money. Brick stays the bank's, across the street ("the only brick
  front on the street", set-direction).
- **The ground floor reads as glass:** tall plate-glass windows with round-arched heads in cream
  casings, the bar's and the parlour's two lights each; the lobby's double doors with etched glass and
  a fanlight, the name again in gold leaf on the transom; the bar's own street door at the west, the
  ladies' entrance at the east (period: ladies came in by their own door to their own parlour).
- **Upper windows** tall two-over-two sash with cream casings and a little bracketed head, green
  louvred shutters folded back, lace curtains (set-direction: "the only curtains"); the best suite's
  French doors on the axis over the main doors, onto the gallery.
- **The gallery** (the Balcony Ambush, §6): the full 80 ft over the walk, 8 ft deep, at the upper
  floor (16 ft over the street), on nine factory-turned posts 10 ft apart, a turned-baluster railing,
  the fascia beam painted cream with the red picked out. Under it: the walk, chairs and a rocker,
  a boot scraper, a bench, the dry flower box (set-direction's wear).
- **Four easy steps**, a wide flight at the main doors (valley.json's `walk.why`).

## 4. The plan, floor by floor

Main block 80 x 50 ft, two storeys; a kitchen wing 42 x 24 ft behind its west half, two storeys
(rooms over the kitchen, warm and cheap). The building stands 74 ft deep, inside the lot's 38 m
(valley.json's `depth` 20 is a planning number; the spec sets it, as saloon B did). The yard behind:
the privies, the wash house, the woodshed, the pump, a wagon gate to Back Street.

### Ground floor (`hotel/ground.png`)

| Room | Size (ft) | What's in it |
|---|---|---|
| **Lobby and office** | 28 x 28 | The heart: the walnut desk (counter) facing the door, the register on it, the bell, the pen and inkstand; behind it the key board (pigeonholes, a key and a brass tag a room) and the mail rack; a clock; a settee and armchairs, spittoons, a stand of newspapers, a hat tree, the railroad's timetable framed on the wall; **the grand stair** rising along the back wall (§4.1). |
| **The bar** | 22 x 28 | **Small and fine** (Sean): a walnut bar 16 ft long with a carved front and a brass rail, a back bar with a mirror between columns, cut-glass decanters, a few tables, a billiard table if it fits (the spec decides), its own street door and a door into the lobby; a trap to the beer cellar behind the bar. A gentlemen's room: the saloon across the lane is where the rough drink. |
| **Ladies' parlour** | 30 x 28 | The ladies' entrance's room: the piano, two settees and chairs in velvet, a centre table with the album and the lamp, a whatnot, pictures, lace at the windows, the best carpet in the house. |
| **Dining room** | 56 x 22 | Eight tables of six on white linen, the chairs bentwood or walnut, two sideboards, the silver-plated castors, a chandelier over the middle, doors from the lobby and the parlour, swing doors to the serving pantry. Laid for supper ("Supper's at six. Late is cold."). |
| **Office** | 10 x 10 | The landlady's desk, the ledger, the safe (guests' valuables), the letter press. Off the lobby behind the desk. |
| **Sample room** | 14 x 22 | Where drummers open their trunks for the town's storekeepers: long tables, a door to the saloon lane for trunks off a wagon. |
| **Back stair** | 10 x 12 | Servants' stair, cellar to upper floor. |
| **Serving pantry** | 12 x 10 | Between kitchen and dining room: shelves of china, the hot closet, the swing doors. |
| **Kitchen** | 22 x 16 | **The hotel range** (a long iron range, six to eight holes, two ovens, a hood and a pipe), a big deal table scrubbed white, a dresser of tin and copper, a flour bin, the water from the scullery. |
| **Scullery** | 12 x 14 | Two sinks, a pump (a cistern or the well), the dishwater out the back door to the yard. |
| **Store pantry, cook's room, back hall** | | The pantry's crocks and tins; the cook sleeps by the kitchen; the back hall takes the cellar stair and the yard door. |

### 4.1 The grand stair

The game already has it: `OakStair` (`src/art/oak_stair.gd`, Sean's pick B, the painted oak, 2026-10-21:
"Its golden view waits for the hotel"): 13 risers of 190 on a 270 going to a landing, a bullnose first
step round a turned newel, two turned balusters a tread, a moulded rail, a runner on brass rods. The
hotel's floor to floor is about 4.1 m, so **22 risers in two flights**: 13 up along the lobby's back
wall to a landing, turning to 9 more up into the stair hall. A newel post with a cast-brass or
bronze lamp figure on it (period: a statuette newel lamp) lights the foot of the stair.

### Upper floor (`hotel/upper.png`)

| Room | Size (ft) | What's in it |
|---|---|---|
| **The best suite** (front centre) | parlour 12 x 22, bedroom 12 x 22 | French doors to the gallery; the parlour with a settee, a writing table with the hotel's paper (**Rourke's letter**, S7), a marble-topped centre table; the bedroom a **carved walnut bedstead** with a high headboard, a marble-topped washstand and dresser, a wardrobe, a Brussels carpet. Rourke's, on Payday Night. |
| **Rooms 1-5** (the front) | 10-13 x 22 | Over the gallery, each with a window onto it (the gallery is reached by the suite's French doors and the front rooms' low sash windows, as period galleries were: the ambush men come out of rooms 1-5). **Room 4 dressed**: a brass bedstead (or iron, painted and gilt), washstand with bowl and pitcher, a slop jar, a wardrobe, a chair, a rag or ingrain carpet, a lamp, a text on the wall. The rest closed doors. |
| **Rooms 6-8** (the back) | 11-14 x 16 | Plainer: an iron bed, washstand, chair, pegs. |
| **Rooms 9-11** (over the kitchen) | 11-12 x 12 | The cheap rooms: the miner's and the drifter's (valley_folk's lodgers). |
| **The landlady's rooms** | 14 x 16, 14 x 16 | A sitting room (her husband's photograph, a sewing machine, the account books she brings up at night) and her bedroom. |
| **The maids' room** | 11 x 16 | Three narrow iron beds, a trunk each, one washstand. |
| **Bath, linen** | | A bath room with a tin tub, water carried up (no plumbing upstairs in 1882 here: §2); the linen press. Chamber pots in every room; the privies in the yard. |
| **The hall** | 6 ft wide, 80 ft | A runner carpet, a lamp on a bracket every few doors, the transoms over every door (air), the doors' numbers in brass, a window at each end (onto the lanes). |
| **Stair hall** | 18 x 6 | Where the grand stair arrives; a chair and a table with a lamp. |

Eleven rooms and the suite: about twenty beds. Real hotels in towns of a thousand ran twenty to forty
rooms, so this is a modest best hotel, right for Salt Creek (and the landlady's "two rooms empty").

## 5. The cellar, and its secret

**The ordinary cellar** (`hotel/cellar.png`), under the west and middle of the main block, 7 ft clear,
stone walls laid dry at the bottom and limed above, a flagged and earth floor, the joists overhead:

- **Beer cellar** (24 x 20) under the bar: kegs on stillage, a bulkhead out to the saloon lane where the
  brewery's wagon rolls them down, the trap up behind the bar.
- **Stores** (24 x 20): potatoes and onions in bins, flour in barrels, hams and bacon hung, crocks of
  butter and lard, canned goods by the case (oysters, tomatoes, peaches: the freight's luxuries).
- **Ice room** (16 x 14): thick double walls packed with sawdust, the ice cut on the creek or the high
  ponds in winter in sawdust, a drain, meat hung, the milk and butter.
- **Coal** (12 x 20): a chute from the lane; the range and the stoves burn coal off the railroad.
- **Wine room** (20 x 14): locked, racked: claret, champagne, port, brandy, whisky in the wood; the
  Baron's own bin.
- The cellar stair from the kitchen's back hall; a lantern on a nail at its foot.

**Three proposals for something to find** (each tied to the story bible; Sean picks one, §9 4). The
cellar's plan leaves the place for it east of the wine room (the "?" on `hotel/cellar.png`).

### A. The Baron's copy book (the paper trail)

- **What:** behind the wine room's racks, in the Baron's locked bin, a tin box: his **letter-press copy
  book** (the period's carbon copy: every letter and telegram pressed onto tissue the day it was
  written) and the hotel's own register pages torn from the book. In it: the telegrams east after each
  bad night ("the town in revolt", OUTLINE.md, S26), a copy of a letter to Rourke dated before
  Payday Night, the foreman's receipts. He writes his letters at the hotel's table, and keeps the copies
  where his wine is, because the landlady's cellar is the one place in town nobody searches.
- **How it's found:** the wine room is locked and the landlady keeps the key (on her chatelaine). The
  hint is **Rourke's letter on the hotel's paper** (S7): the same paper, the same ink. Ask her (opinion
  high enough), take the key while she sleeps, or break the lock (heard upstairs). In the Baron's bin
  the racks are false at the back.
- **What it changes:** it's proof, in writing, that the revolt was made: something to put before the
  captain on I Am the Law (against what he's shown), or keep for the end ("what people saw"). Strong
  and plain; it fits "the Baron keeps his hands clean" by showing where they got dirty. Low build cost
  (a lock, a bin, a box, a book's pages to read).

### B. The way under the lane (the girder men's road)

- **What:** the beer cellar's west wall has a low arched door, bricked up when the saloon was built and
  **opened again lately**: a drift under the saloon lane (lined with timber like a mine's, 4 ft high,
  about 60 ft) to the saloon's cellar. The landlady's husband dug it in 1881 to run kegs to the saloon he
  had a share in; she had it closed when he died. The foreman's men opened it to reach the saloon's
  cellar and the girder under the bar on Payday Night without being seen on the street.
- **How it's found:** the cellar's draught (a lamp flame leans), fresh oak sawdust on the beer
  cellar's floor (the girder is oak), a bucksaw left in the drift, mud on the steps. Found after
  Payday Night; best found by asking why the lamp leans.
- **What it changes:** it **answers s22** ("how Harlan knows the men" is open): in the drift, a
  bottle and a pay envelope from the Baron's ranch with names, or the hotel's register showing who took
  the back rooms that night. It leads straight to the Balcony Ambush, the night after; and it's a route:
  the player can come up inside the saloon. Most build (a tunnel, both cellars joined); the most
  playable. The drift is the least documented of the three: towns' "tunnels" are mostly legend (§2),
  so it's kept short, mine-timbered and explained.

### C. The payroll's hiding place (the money)

- **What:** under the ice room's sawdust, in the ice, a canvas mail sack: **the mine's payroll**, or
  part of it, from Thursday's train (`payroll.fate`). A man who stays at the hotel (a back room, his
  name in the register) hid it where the ice keeps it out of sight and the ice man only digs from the
  top. Who: one of the Colters (their own job, `gang_a.fate` "fled with the money"), or the deputy
  (twist B, OUTLINE.md: "the pay arrives saved but short").
- **How it's found:** the ice man complains the ice is "dug about"; the landlady says one lodger
  asked for the cellar key to "keep his medicine cold"; the sack's corner under the sawdust where the
  ice is melting from the drain.
- **What it changes:** the money (return it to the mine and the town's opinion rises, keep it and the
  ledger says so), and who took it (a Colter's ending, or the deputy's). Lowest story cost to explain;
  middling build. It ties to the train, not to the Baron.

**Recommended: B**, for the story's open question it closes (s22) and the route it gives, with A's
copy book as a smaller find in the Baron's wine bin if Sean wants both. A is the cheapest and
cleanest if B's tunnel feels like too much.

## 6. The gallery holds the ambush

**DECIDED (Sean, 2026-11-23, in session):** the second floor has an exterior balcony (this gallery), built to
be blown up later. It stays on its own posts at the walk's edge so dynamite at the posts brings it down; the
deck is **open, railed, no roof** (Sean, the same day). Drawn in `hotel/balcony.png`: its framing from
above, three bays close, and post 5 blown (the two bays it carried hang from posts 4 and 6 and drop to the walk; in
section the deck hinges on the ledger and tips the men down it).

The girder men drink on the gallery the night after Payday Night (C9 a; `5_act4_sides.md`). The
design gives it (`hotel/gallery_section.png`):

- **Strong enough for a crowd, by period numbers:** 2x10 joists at 16 in, 8 ft from a ledger bolted to
  the upper floor's band to a beam of three 2x12s on the posts; 6x6 posts (turned from 8x8 stock at the
  mill, a 6 in square at the top and foot) on stone footings at the walk's street edge; 1x4 tongue-and-
  groove deck laid to fall to the street. A dozen men stand on it.
- **Brought down by its posts** (C9: "the player can destroy the balcony's support posts"): the beam
  spans post to post, so a post blown out (dynamite) drops two bays of beam, the joists hinge on the
  ledger and the deck tips the men to the walk and the street (16 ft). Two posts out drops 30 ft of it.
  The unpicked ideas fit as built: a cracked post that holds until a third man steps out; one corner
  dropping and a man hanging on the railing.
- **Shot from the street:** the turned balusters give no cover (bullets go through); men crouch behind
  the fascia only when lying down. The windows behind them light them from inside (the suite's lamp).
- **An open deck, no roof** (DECIDED, Sean 2026-11-23): the men are seen against the lit windows, and the
  collapse is one clean fall. **Its beams are one a bay, ending on the posts**, not spliced through, so a
  blown post drops exactly the two bays it carried.

## 7. Materials, room by room

Plaster on lath everywhere downstairs and in the suite (so it cracks and falls in chunks off its lath,
the paper tearing with it: the issue's "they break differently"); the back rooms and the kitchen wing
in painted boards (the town's carpentry, which the builder has).

| Room | Walls | Floor | Ceiling | Wood and metal | Light |
|---|---|---|---|---|---|
| **Lobby** | Walnut wainscot 3 ft 6 in (raised panels, a moulded cap), paper above in three bands: a dark Lincrusta-style dado, a warm red-and-gold filling, a frieze | Encaustic tile in the vestibule (freighted), the rest oak boards with a Brussels carpet | Plaster, a deep cornice, a rose round the chandelier | The walnut desk with carved panels and a brass rail, the key board, the grand stair (dark oak, Sean's B) on a red runner with brass rods, brass spittoons | A kerosene chandelier of four lamps; the newel lamp; brackets by the desk |
| **The bar** | Walnut wainscot, a dark green and gold paper | Oak boards, a brass foot rail, sawdust none (it's the hotel's) | Plaster, painted (a frescoed panel or two, as the Teller's bar) | Walnut bar and back bar with a big mirror in arches, cut-glass decanters, brass | Two hanging lamps with shades, a lamp on the bar |
| **Ladies' parlour** | Paper in a pale, floral filling over a painted dado, a gilt picture rail | **The best carpet**: Brussels or Wilton in a big pattern, wall to wall, sewn from strips | Plaster with a rose | Rosewood or walnut piano, settees and chairs in red or green velvet, a marble-topped table, lace and velvet curtains on brass poles, a gilt mirror over the mantel | A chandelier, a table lamp with a painted globe |
| **Dining room** | Wainscot of oak or ash boards, a light paper above, pictures (prints, a stag's head) | Oak boards bare (crumbs and spills) | Plaster, two roses | White linen, silver plate, the sideboards in walnut, bentwood or walnut chairs | Two chandeliers, lamps on the sideboards |
| **Kitchen, scullery, pantry** | Limewashed boards, shelves | Boards, scrubbed | Boards, sooty over the range | **The hotel range** (iron, six to eight holes, a hot-water reservoir, its hood), copper pans, tin, a deal table | A lamp on a bracket, the range's glow |
| **Upstairs hall** | Paper, a dado rail | An ingrain or Brussels runner | Plaster | Brass numbers on the doors, transoms over them | A lamp on a bracket every few doors |
| **Best suite** | A rich paper, a frieze | Brussels carpet wall to wall | Plaster with a rose | **Carved walnut bedstead** (Eastlake or Renaissance revival, a high headboard), a marble-topped dresser and washstand, a wardrobe, a velvet settee, a writing table | A table lamp, a hanging lamp |
| **Room 4 (dressed)** | A cheaper floral paper | Ingrain carpet | Plaster | A brass or painted-iron bed, an ash or pine washstand with a bowl and pitcher, a wardrobe | One lamp |
| **The rest, the landlady's, the maids'** | Painted boards or a plain paper | Rag rugs on boards | Boards | Iron beds, pine furniture | One lamp each |
| **Cellar** | Stone, limed above | Flags and earth | Joists | Racks, stillage, bins | A lantern on a nail |

**The woods:** walnut is the hotel's wood (black walnut, the 1870s-80s fashion; the material library's
`furniture_walnut` FN3 is parked: it needs walnut figure first), with ash and oak for the plainer
rooms and the stair's dark oak (`dark_oak`, in the game). Brass on every hand: rails, door furniture,
lamp founts, numbers, the bed.

## 8. Who works there (#1207's list)

Every one a person you can walk up to (#1207: unique), so each gets a sheet when the town's people do:

| Who | Lives | What they do | Today |
|---|---|---|---|
| **The landlady** (Mrs. —, a widow, forties) | her rooms | Owns and runs it; the keys; the ledger; sweeps the rug at six | in valley_folk.json (`landlady`), lines from #1184 |
| **The clerk** | a back room | The desk, the register, the keys, the mail, the timetable | new |
| **The cook** | the cook's room | The range from five in the morning; the menus | new |
| **Two chambermaids** | the maids' room | The rooms, the slops, the linen, the lamps (trimmed and filled each morning) | new |
| **The waitress** (one, or the maids at supper) | the maids' room | The dining room at the three meals | new |
| **The porter and boots** (a boy or an old man) | the back hall | Trunks off the stage and the train, boots blacked, the coal and the ice carried | new |
| **The bartender** | in town | The small bar, evenings | new |
| **The lodgers** | rooms 9-11 | The miner, the drifter, the townsman (valley_folk.json) | in the game |

## 9. Sean's calls

1. **The front:** painted clapboard in three colours (recommended: brick stays the bank's across the
   street) or a brick front with stone at the corners and heads.
2. **The gallery: DECIDED** (Sean, 2026-11-23): an exterior balcony on the upper floor, an open railed deck, to be blown up later (`hotel/balcony.png`).
3. **Two storeys** (recommended: the town's size and §2's hotels; the third would be a mansard) **or three**.
4. **The cellar's secret:** A (the Baron's copy book), B (the way under the lane, recommended) or C
   (the payroll in the ice).
5. **The landlady's line "Rooms are fifty cents"** (#1184): a $3 room at the Teller House (§2); a small town's best charged dollars, not cents. Change it to "Two dollars a day, with board. Clean sheets are worth it." or keep fifty
   cents and make the hotel humbler.
6. **The target sheet** (the building lab's step 1): twelve views, about **$1.70** (the undertaker's twelve cost $1.69) (one picture a view
   ~$0.14 at 2K, the cap $2.50), painted by `building_sheet.yml` on a `claude/art-building-hotel`
   branch. The views are in `hotel/sheet_request.json` (ready, not sent).

## 10. Then: the build (#1146's first prompt)

The building lab's steps 2-6 (`experiments/building_lab/RECIPE.md`): the spec on its lot (a two-storey
building under a hipped or flat roof behind the parapet, the RECIPE's "two-storey building under
trusses" lessons from saloon B), the parts the issue's first comment lists (painted fine clapboard,
the bracketed cornice, plate glass with gilt, turned posts and balusters, wallpaper over plaster on lath
and its breaking, carpets, the hotel range), each promoted into `src/structures` and `docs/PARTS.md`
so the opera house, the bank and the Baron's house share them, and props by the prop lab's recipe in
batches (the bedsteads, washstands, the desk and key board, the bar, the range, the dining room's
tables).

## 11. Sources and what was read

Read for this design: CLAUDE.md; `docs/lanes/art.md`; `experiments/building_lab/RECIPE.md` (step 1 and
"a two-storey building under trusses"); `undertaker/` README and sheet request (the model for the
sheet); `docs/PARTS.md` (the grep for posts, railings, stairs, storefront, plaster); `config/valley.json`
(the hotel lot and its neighbours, the ground probed under it); `docs/briefs/set-direction.md` "Hotel";
`material-lab.md` "The hotel's oak stair"; `valley-plan.md`, `townsfolk.md` (hotel lines). The story bible
by a sub-agent: `5_act4_sides.md` (the ambush, 29-96), `4_act3.md` (Payday Night at the hotel), MISSIONS.md
(the captain's supper, 1087), SETUPS.md S7 (Rourke's letter on the hotel's paper), CONTRADICTIONS.md C9 a
and s22, OUTLINE.md (twist B, S26), VOICES.md (the Baron, the foreman), WORDS.md (the landlady),
`config/town_script.json` (her lines, #1184), `config/valley_folk.json` (her day; the lodgers).

**The ground under the lot** (probed from `config/valley_ground/heights.r16.gz`): about 0 at the
front, +0.4 m 10 m back, +0.7 at 20 m, +1.9 at 30 m (Back Street's rise); 0.15-0.2 m lower at the east.
The floor at the walk's top (+0.75) meets the ground near the main block's back wall: the cellar is
about 2.2 m into the ground at the back, the bulkhead on the lane wants four or five risers.

**Period sources** (the sub-agent's; checked against primary where marked):
- Teller House NRHP nomination (primary): https://npgallery.nps.gov/GetAsset/a22bf0f5-3ce7-4017-b438-c13404bd7926
- Hotel de Paris NRHP nomination (primary): https://npgallery.nps.gov/GetAsset/4d1b8c4c-bdc5-4d72-a6d6-ad70fe42f44c
- Mesker fronts (NPS): https://www.nps.gov/articles/at-the-forefront-of-storefronts-frank-ben-and-george-mesker.htm
- Metal ceilings, NPS Preservation Brief 49: https://www.nps.gov/orgs/1739/upload/preservation-brief-49-metal-ceilings-walls.pdf
- Wallpaper (NPS): https://www.nps.gov/parkhistory/online_books/tpsd/wallpaper/sec2a.htm
- Grand Imperial: https://www.historycolorado.org/node/5955 ; Teller rates: https://centralcityopera.org/the-teller-house-turns-150-years-old/
- Georgetown gas: https://georgetownenergymuseum.com/history ; Brunswick dates: https://en.wikipedia.org/wiki/Brunswick_Corporation
- Fred Harvey: https://www.kansashistory.gov/kansapedia/fred-harvey/15507 ; Chinese Colorado: https://en.wikipedia.org/wiki/History_of_Chinese_Americans_in_Colorado
- Colorado tunnels as legend: https://www.cpr.org/show-episode/hidden-tunnels-of-colorado-city/
- Pictures for the artist (public domain): the Grand Imperial's HABS photos and the Windsor's (Wikimedia
  Commons, "HABS COLO,56-SILTN,5"; "Windsor Hotel, Denver, by James Collier"); Leadville's street c.1880
  (Boston & Ziegler). No 1880s Colorado hotel interior was found open here: Denver Public Library's
  digital collection is the next place to look.

Not verified: the hotel range's maker (no 1880s source found), the room rate with board in a small
town (Teller's $3 is a big city hotel's), the build cost range.
