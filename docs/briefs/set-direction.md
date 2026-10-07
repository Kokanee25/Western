# Brief: set direction, so every building looks like its own place

Sean, 2026-10-06: "Should we have a set director for all the buildings, props and design so they
all look unique." Yes: a written set bible (one card a building) and a blind check after each
building is dressed.

## Goal

Every building on Main Street (and, as they're built, every building on the map) reads at a
glance as a different place, owned by a different person, built at a different time with
different money. Nothing looks like the same front with a different sign. The saloon's front
(`FacadeArt`, 2026-10-06) is the model for how far a front is taken; the cards say what each one
is taken *towards*.

## References

- The look: `docs/concept/street-golden-hour.png`, `docs/concept/saloon-blocks.png` (DESIGN.md §4).
- The layout: `docs/concept/town-map.png`, `config/town.json`, `docs/briefs/town.md`,
  `docs/briefs/main-street.md`.
- Who owns what and what's inside: `docs/TOWN.md` (the cards don't repeat its rooms and systems;
  they add how the place looks and why).
- Period: Sanborn fire-insurance maps (Tombstone 1886, Dodge City 1887) and period photographs of
  Western main streets (Library of Congress, Denver Public Library's Western History collection):
  look at real fronts, not other games.

## The card

One card a building, in this file under **Cards**. Short: a card that runs past half a page is
saying too much.

- **Who and why:** the owner, how long they've been here, what they want the street to think.
- **Age and money:** when it was put up, what with, what's been added or patched since.
- **Its own colours and materials:** two or three colours named (paint, bare wood, brick, iron)
  and the factory material ids they come from; no two neighbours share a main colour.
- **The sign:** what it says, how it's lettered (painted by whom, how well, how faded), where it
  hangs. No two signs in the same hand.
- **The front's shape:** height, roof line, porch or none, windows, door, steps (from
  `config/town.json`; the card says what's characteristic, gameplay's layout says where).
- **Wear and life:** what the weather, the street and the owner have done to it; what's left
  outside (stock, a chair, a dog's bowl, a broken thing nobody's fixed).
- **Inside, at a glance:** the one or two things you see through the door or window first, and
  one or two story clues (TOWN.md's systems give them: the ledger, the forged deed).
- **Against its neighbours:** one line on how it differs from the buildings either side and across.

Homes (DESIGN.md §11 "Everyone has a home") get the same card, tied to who lives there.

## Who does what

- **The art session** writes the cards (with Sean), dresses each building to its card (fronts,
  signs, textures, props, `StreetDressing`, `FacadeArt`), and runs the set director check.
- **The gameplay session** builds each building's structure from the map and the card (size,
  storeys, materials it can burn or break as, interior members), as it does now.
- **The characters session** reads the owner line when dressing that owner (a banker's coat
  matches his bank's money).
- **Sean** approves each card before its building is dressed (a line in the card: "Sean: OK").

## How it's judged

**The set director check**, after every building is dressed (alongside the blind critic, which
judges the look against the paintings): a fresh agent that hasn't seen the code, the cards or the
reasoning gets renders of the street (the street shot, a view down each side, the new building
close up, and its neighbours) and lists:

1. what looks repeated or generic (a shared colour, a copied sign hand, the same props, the same
   window, a front that could be any shop's);
2. what it guesses each building is and who owns it, from the pictures alone;
3. the three changes that would most make the new building its own place.

Saved as `docs/screenshots/set/<date>_<building>/set.md` with its crops. The building is done
when the agent names it and its kind of owner correctly, and nothing on it is in list 1 that
isn't on purpose (a card can say "the same hand as the barber's: he painted both").

## What done looks like

Every Main Street building has an approved card and has passed the check; walking the street, no
two fronts are mistaken for each other at golden hour or at night. The map's other buildings get
their cards as they're built.

## Cards (first pass, for Sean to approve or change)

Owners are TOWN.md's. Colours named are the intent; the factory ids are where they come from
today or a new material to paint.

### Saloon (the model)
- **Who and why:** the saloon owner; wants it the loudest, richest-looking thing on the street.
- **Age and money:** the first two-storey front in town, put up when the money first came;
  repainted every spring.
- **Colours:** oxblood red boards (`saloon_red`), dark brown trim, gilt lettering.
- **Sign:** SALOON, big, framed, a professional sign painter's hand, the only gilt on the street.
- **Front:** tall false front, porch on brackets, batwings, up four steps (done, `FacadeArt`).
- **Wear and life:** spittoon, wanted posters, boot-scuffed steps, lanterns lit early.
- **Inside:** the back bar's lamps and mirror through the door.
- **Against neighbours:** the only red and the only gilt; the store beside it is pale and plain.

### General store
- **Who and why:** the storekeeper; wants to look honest and well stocked.
- **Age and money:** as old as the saloon, built cheaper; the big front windows are its pride.
- **Colours:** whitewashed boards gone cream and grey (`store_boards`), green window frames.
- **Sign:** GENERAL STORE in plain black block capitals he painted himself, a little uneven;
  prices chalked on a board by the door.
- **Front:** wide, two big many-paned windows, low porch, stock outside.
- **Wear and life:** barrels, sacks, a bench, crates stacked against the wall, a broom.
- **Inside:** shelves to the ceiling seen through the windows; the ledger on the counter.
- **Against neighbours:** pale and busy where the saloon is dark and showy; the telegraph is new paint.

### Telegraph
- **Who and why:** the railroad land agent (TOWN.md 10, the wire half); wants to look official.
- **Age and money:** the newest building on the street, railroad money, still smells of paint.
- **Colours:** railroad ochre (`painted_ochre`) with brown trim, clean.
- **Sign:** TELEGRAPH in the railroad's stencilled capitals, crisp; the company's name small under it.
- **Front:** narrow, no porch lantern, one window with the key and sounder in it.
- **Wear and life:** almost none, which is the point: the wire off the roof to the poles.
- **Inside:** the operator at his desk under a lamp; a pinned map of the survey.
- **Against neighbours:** the only fresh paint on the south side.

### Barber
- **Who and why:** the barber (also bathhouse and undertaker, TOWN.md 8); wants trade, any trade.
- **Age and money:** old, small, added to: a lean-to bathhouse at the side, coffins out the back.
- **Colours:** bare weathered pine (`weathered_pine`), a red-and-white striped pole.
- **Sign:** a hand-lettered board with three trades on it, the third (UNDERTAKER) added later in
  a different paint; BATHS 25¢ hung under the porch.
- **Front:** low, one window, a barber chair visible inside.
- **Wear and life:** a tin bath against the wall, a coffin lid propped by the back.
- **Against neighbours:** the pole is the street's only stripe.

### Doctor's
- **Who and why:** the doctor; respectable, tired, owes money.
- **Age and money:** a house more than a shop, two storeys, once painted white, now peeling.
- **Colours:** white paint flaking to grey pine, dark green shutters.
- **Sign:** a small neat painted shingle by the door (DR. … PHYSICIAN & SURGEON), not a big board.
- **Front:** no false front, a pitched roof, a small porch, lace in the upstairs window.
- **Wear and life:** a basin emptied by the step, a horse's hitch for night calls.
- **Inside:** the operating table and the cabinet of bottles through the window.
- **Against neighbours:** the only house-shape on Main Street; the only shingle sign.

### Hotel
- **Who and why:** the widowed landlady; wants a decent house.
- **Age and money:** two storeys, a balcony across the front, built by her husband.
- **Colours:** soft blue-grey paint, white trim, both faded.
- **Sign:** HOTEL in serif capitals across the balcony, carefully painted and fading evenly.
- **Front:** balcony on posts, curtained windows, chairs on the porch, a boot scraper.
- **Wear and life:** a flower box gone dry, a rocking chair, a lamp in the parlour window at night.
- **Against neighbours:** the only blue; the only curtains.

### Bank
- **Who and why:** the railroad-backed banker; wants to look permanent.
- **Age and money:** the only brick front on the street (TOWN.md 5), stone sill and lintels.
- **Colours:** red-brown brick, grey stone, black iron bars.
- **Sign:** BANK cut or cast in raised letters in the stone (or gilt on black glass), the town's
  most expensive lettering after the saloon's.
- **Front:** heavy door, barred windows, no porch roof, a stone step.
- **Wear and life:** clean, swept, nothing left outside; a hitching ring set in the stone.
- **Inside:** the teller's cage and the safe's door.
- **Against neighbours:** brick among wood, and smarter brick than the jail's: pressed, even,
  with stone trim. (Sean, 2026-10-06: brick. The game's bank is wood painted rust today; brick is
  gameplay's structure work, below.) Sean: OK on brick.

### Livery
- **Who and why:** the blacksmith who runs it; practical, no show.
- **Age and money:** a big barn, the oldest building in town, patched many times.
- **Colours:** grey-brown barn boards, newer yellow boards where it's been patched.
- **Sign:** LIVERY painted straight on the boards above the doors, big and rough.
- **Front:** gable front, double doors, loft door with a hay hook.
- **Wear and life:** hay spilling from the loft, harness on pegs, horseshoes nailed up, dung.
- **Inside:** stalls and horses' heads.
- **Against neighbours:** the only gable on the north side; the jail beside it is squat and closed.

### Jail
- **Who and why:** the town (the sheriff); wants to look like it can hold a man.
- **Age and money:** brick (Sean, 2026-10-06: "maybe the jail should be too"; proposed), put
  up by the county after a man dug out of the old log lock-up. Common brick laid by a local
  mason: uneven courses, thick mortar, no ornament. Strap-iron cells inside.
- **Colours:** dull dark red-brown brick, sooty over the stovepipe, black iron straps and bars,
  a plank door sheathed in iron.
- **Sign:** SHERIFF on a board hung under the porch, plain; the wanted board beside the door.
- **Front:** small, barred windows, a heavy door, a bench outside.
- **Wear and life:** posters layered and torn, a chair tipped back against the wall, a spittoon.
- **Against neighbours:** the darkest front in town; brick like the bank's but cheap, rough and
  plain, so the two read as the town's money and the town's law, not a pair.

### Assay office
- **Who and why:** the mining company; wants nobody to come in.
- **Age and money:** small, new-ish, company paint.
- **Colours:** the company's grey-green paint, black trim.
- **Sign:** ASSAYS in company stencil, the company's name under it, a small "No Admittance".
- **Front:** narrow, one shuttered window, a strong door.
- **Wear and life:** ore samples in a box on the step, crushed rock round the door.
- **Inside:** scales and crucibles in lamplight.
- **Against neighbours:** shuttered where its neighbours are open.

### Water tower yard, well and windpump
- **Who and why:** the town; the railroad's tower beside it.
- **Look:** the tower's tank dark and stained by leaks, the windpump's wheel bright tin vanes, the
  well's stone ring worn smooth, the stock tank green-edged, mud round it.
- **Against everything:** the only metal turning in the town; the wettest ground.

### Corral
- **Who and why:** the livery's.
- **Look:** grey split rails mended with newer poles and wire, a gate on leather hinges, a
  water trough, hoof-churned ground with no grass.

### Brick (for the gameplay session)

The bank's front, and the jail if Sean confirms, need brick as a building material: members laid
in courses that a ball chips rather than passes through, that don't burn (a brick building's
roof and floors still do), and that dynamite cracks into chunks (TOWN.md 5, the blasted brick
wall in `docs/concept/livery-fire.png`). The jail's back wall is the jailbreak target (TOWN.md 3).
How brick is built (members or voxels, mortar strength, numbers from published references) is
gameplay's to propose in a brief before it's built; the art session paints the two bricks.

The map's other buildings (feed store, blacksmith's forge, wagon repair, freight storehouse,
stage stop, church, school, cemetery and the houses) get their cards as they're built.
