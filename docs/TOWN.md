# Salt Creek — the town, buildings, set pieces and dressing

What the town is made of: every building, its owner and rooms, what's inside, and what it does in
the systems. Build sessions work through this **one building per session** after M3's structure
systems exist (see CLAUDE.md "Build plan"). Everything is member-built (posts, beams, studs, joists,
siding, shingles, bricks) with pixel-art textures made in code, unless noted.

**Rules for everything placed in the town**
- Every building, room and prop has an **ID**, an **owner** (a person, the town, the railroad, nobody),
  and **systemic properties**: flammable / breakable / movable / lockable / edible / wearable / worth.
  Property matters: taking something you don't own is theft if someone sees.
- Buildings are framed the way they really were in 1882 (ask Sean — timber framer). False fronts are
  real false fronts; the back of the building is plainer and cheaper.
- Interiors are real rooms you can enter, not facades — except blockout buildings in the far distance.
- Wear and age: silvered and checked wood, peeling paint, patched boards, sagging porches, rust.
  Richer buildings (bank, baron's house) are newer and painted.
- Layout lives in a data file (town layout), not hard-coded, so buildings can be moved without code.

---

## Main street

| # | Building | Owner (cast) | Construction |
|---|---|---|---|
| 1 | Saloon | the saloon owner | two-storey false front, timber frame, plank walls |
| 2 | General store (mercantile) | the storekeeper | false front, big front windows, cellar |
| 3 | Sheriff's office and jail | the town | brick (proposed, Sean 2026-10-06), plain and rough; strap-iron cells |
| 4 | Doctor's office | the doctor | small two-storey house with a surgery downstairs |
| 5 | Bank | the railroad-backed banker | **brick** — pride of the town (the jail may be brick too, plainer) |
| 6 | Livery stable and blacksmith | the blacksmith | big barn, hay loft, open forge shed |
| 7 | Church | the preacher / town | white-painted, bell tower, graveyard behind |
| 8 | Barber, bathhouse and undertaker | the barber | one building, three trades (common then) |
| 9 | Hotel / boarding house | a widowed landlady | two storeys, rooms to rent, dining room |
| 10 | Land office and telegraph | the railroad land agent | new, painted, the agent's office and the wire |
| 11 | Newspaper | the editor | small shop with a hand press |
| 12 | Stage and freight depot | the stage line | platform, freight shed, corral |
| 13 | Laundry and eating house | a Chinese family (former railroad workers) | written with care and research — real people, not props |
| 14 | Assay office | the mining company | small, strong-box, scales |

### 1. Saloon
- **Rooms:** barroom (long bar, back bar with mirror, card tables, piano, stag head, spittoons,
  oil sconces and a chandelier), back storeroom (whiskey barrels, crates, the owner's strongbox),
  owner's office, upstairs rooms off a balcony with a rail overlooking the barroom.
- **Systems:** the rumour hub (the owner hears and sells everything); card games (cheating, fights);
  drink (drunkenness); the balcony rail breaks under a falling body; the chandelier can be shot down;
  black-powder smoke fills the room in a fight; lamp oil + wood = the worst fire in town.
- **Matches:** `docs/concept/saloon-night.png`.

### 2. General store
- **Rooms:** shop (counter, ledger, scales, shelves of tins and sacks, barrels of crackers and
  pickles, bolts of cloth, hats, boots, a glass case of revolvers and cartridges, lamp oil, rope,
  tools), back storeroom, cellar (root cellar, hidden things), storekeeper's quarters behind.
- **Systems:** buy/sell with prices that react to events; the **ledger** is readable (who owes what —
  evidence); stealing; clothes for disguise; lamp oil and rope for everything else; the front windows
  shatter (already built in M1).

### 3. Sheriff's office and jail
- **Rooms:** office (desk, wanted posters board, gun rack, key ring on a nail, stove, coffee pot),
  two cells (bunks, bucket, barred window), a back door.
- **Systems:** arrest and holding prisoners; keys (steal, copy, lose); wanted posters built from
  witness descriptions; **the back wall is the jailbreak target** (dynamite or a team and chain);
  cells hold people the AI remembers you put there.

### 4. Doctor's office
- **Rooms:** waiting room, surgery (operating table, instrument cabinet: probes, saws, forceps,
  sutures; laudanum and carbolic; basin and pitcher; a skeleton on a stand), recovery room with two
  beds, the doctor's quarters upstairs.
- **Systems:** where you wake after going down; treatment of the anatomy system (probing, stitching,
  setting bones, amputation); the doctor's secret about the sheriff's wound; medicine can be stolen.

### 5. Bank
- **Rooms:** lobby with a teller cage (brass bars), manager's office, **the vault** (steel door, time
  lock or combination), back office with the railroad's money.
- **Systems:** brick and stone behave differently from wood (dynamite cracks it into chunks, fire
  doesn't take it); the vault is a heist; the banker's ledgers tie to the land agent's forged deeds.
- **Matches:** the blasted brick wall in `docs/concept/livery-fire.png`.

### 6. Livery stable and blacksmith
- **Rooms:** stalls with horses, tack room (saddles, bridles), **hay loft** (the fire hazard), office;
  forge shed (forge, bellows, anvil, quench tub, horseshoes, tools).
- **Systems:** horses (buy, rent, steal, care); the forge makes and repairs iron; the hay loft is
  where fires start and spread fastest; a big timber frame that collapses spectacularly.
- **Matches:** the burning livery in `docs/concept/livery-fire.png`.

### 7. Church and graveyard
- **Church:** pews, pulpit, organ, bell rope; the bell rings the hours (a time source with no HUD)
  and rings for fire.
- **Graveyard:** wooden markers and a few stones with **real names** of people who died — including
  the ones the player kills. Funerals happen here.

### 8. Barber, bathhouse and undertaker
- Barber chair (shaves and haircuts — disguise; pulls teeth — the brawling layer), bathhouse tubs
  (hygiene), undertaker's back room (coffins, the laying-out table, bodies waiting for burial —
  evidence and wounds can be examined here).

### 9. Hotel / boarding house
- Front desk with register (names and dates — evidence), dining room, kitchen, rooms upstairs with
  **beds to rent (save points)**, a landlady who notices who comes and goes at night.

### 10. Land office and telegraph
- The railroad land agent's office (maps, survey plans, **deeds — some forged**), the telegraph
  key and wire (news and orders arrive; cut the wire and the town is cut off).

### 11. Newspaper
- Hand press, type cases, stacked papers; the weekly paper prints the town's real events (slightly
  wrong). The editor is a witness who writes things down.

### 12. Stage and freight depot
- Ticket window, freight shed, corral; the stage arrives on a schedule (strangers, mail, the money
  shipment — a robbery target).

### 13. Laundry and eating house
- A family that came to build the railroad; washing lines (clothes to steal), tubs, a kitchen.
  Their own lives, opinions and history of how the town treats them. Research and care required.

### 14. Assay office
- Scales, crucibles, a strongbox; tells you what the mine is worth.

---

## Outskirts

- **The player's homestead:** small cabin (bed = save point, stove, table, trunk), **the spring**
  (the stakes of the whole game), vegetable garden, small barn, well, woodpile, outhouse, fence. It
  can be improved — or burned out by the gang.
- **The widow's homestead:** similar, older, better kept; she's alone.
- **The cattle baron's ranch:** big painted two-storey house, bunkhouse, corrals, barn, windmill, a
  water tank; hands who work and fight for him.
- **The railroad survey camp:** tents, stakes and flags along the line, a cook wagon; grows over the
  30 days until the rails arrive and a platform and water tower go up.
- **The mine:** head frame, timbered adit (timber framing underground — the same structure system,
  so tunnels can collapse), ore carts on rails, tailings pile, **powder magazine** (the source of
  dynamite), a shack. Its purpose is still open (DESIGN.md §13).
- **The road:** where the sheriff is found on day 1 (a place to return to for evidence).
- **The Colter hideout:** a line shack or dugout in the hills.
- **The creek:** water, fording, the spring's outflow; mud that holds footprints.

---

## Set pieces (authored spaces for big moments; they must work however the player arrives)

- **Day 1 — the sheriff on the road at dawn** (wagon wheel, his horse, his revolver in the dirt).
- **The livery fire** — bucket line from the trough, horses led out, loft collapsing.
- **The bank job** — the vault, the brick wall, the teller.
- **The jailbreak** — the back wall of the jail.
- **A trial** in the saloon or church (period-accurate: courts met wherever there was room),
  and **the gallows** built for a hanging.
- **The railroad's arrival** — the platform, bunting, a crowd, the first train.
- **The mine** — a cave-in, or a fight in the tunnels.
- **A funeral** in the graveyard.
- **The saloon standoff** — smoke, the balcony, the chandelier.

---

## Dressing kit (reusable props, all with systemic properties)

- **Street:** hand-lettered signs, awnings and porch posts, boardwalks, hitching rails, water troughs,
  barrels (water, whiskey, nails), crates, sacks, woodpiles (firewood), outhouses, clotheslines
  (disguise), rain barrels, benches, spittoons, lamp posts (few — this is a small town).
- **Vehicles:** buckboard, freight wagon, stagecoach, handcart, wheelbarrow.
- **Infrastructure:** windmill, water tower, telegraph poles and wire, fences (rail, picket, barbed
  wire — new in the 1880s), wells with buckets.
- **Paper:** wanted posters, handbills, the newspaper, letters, ledgers, deeds, gravestones — readable,
  much of it written from the town's real events.
- **Animals:** horses, dogs, cats, chickens, a pig, mules; flies around the livery.
- **Nature:** sagebrush, tumbleweeds, dry grass, cottonwoods by the creek, rocks, dust.
- **Interior kit:** tables, chairs, beds, stoves, lamps and lanterns, crockery, bottles, tools, rugs,
  pictures, mirrors, trunks, coat hooks (coats to steal), gun racks, safes.
- **Light sources** are real lights (and fire sources): oil lamps, lanterns, candles, stoves, the forge.

## Build order (suggested)

1. The kit of parts and the dressing kit (so every building uses them).
2. Sheriff's office and jail, doctor's office, general store (the first slice needs them).
3. Saloon (already started as the art test room), livery, bank, church and graveyard.
4. Hotel, barber, land office and telegraph, depot.
5. The player's homestead, the widow's homestead.
6. Newspaper, laundry and eating house, assay office.
7. The baron's ranch, survey camp, the mine, the hideout.
