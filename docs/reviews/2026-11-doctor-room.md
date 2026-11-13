# The doctor's office as a room: why it reads cheap (#818)

A review, 2026-11-11. Report only: no game code, material or prop was changed.

Sean, on the desk and dispensary shots: "look at the paint job in the corner and the furniture -
it's looking pretty cheap". He is right, and most of it is not the props. Six causes sit in the
building's recipe, the library's rules and the light; they would repeat in the jail, the store and
the saloon.

**In short:** the room is lit by one flat tint with no lamp and no window light; one red walnut is
on the floor and every piece of furniture; the wall paint judged on 9 cm beaded boards is drawn on
24 cm planks; and the windows are one sheet of glass in an unlined hole.

## How this was checked

- **Pictures:** the renders already in the repo. Props round 3
  (`experiments/prop_lab/results/2026-11-11_doctor_d2/r3/`: desk, dispensary, front office, shelves,
  counter) and the paint round (`experiments/building_lab/doctor/results/2026-11-11_paint/`).
- **Not a lab setup.** Those renders are the game's own scene: the valley, the real look, the game's
  exposure, at 10:00 (`experiments/prop_lab/doctor/dress.gd`). Only three things are the lab's: the
  door leaves are set aside, the anti-aliasing is the software renderer's, and the neighbours are
  the valley's grey boxes (the game's too, for now).
- **No new render run.** This session's machine had no Godot or lavapipe, and the existing renders
  show all six of Sean's points. So nothing here was tested by changing a dial and rendering again.
  **Not seen:** the front at golden hour (only the paint round's noon front).
- **Code and data read:** `doctor.json` (`materials`, `lamps`, the openings),
  `spec_building.gd` (`_finish`, `_library_finishes`, `_lib_material`), `false_front_building.gd`
  (`_glass`, `_add_interior_ambient`), `room_light.gd`, `config/material_library.json`,
  `scan_wood.gdshader` (the paint's wear), `prop_kit.gd` (the `lib:` look), the desk's, counter's
  and shelving's kit files, `real_dials.json`, `real_light.json`.
- **Yardsticks:** the period office (`experiments/prop_lab/refs/doctor/desk_remick_office.jpg`) and
  an RDR2 interior, read in place in the private Studio (branch `claude/studio-refs`), not copied.

Each cause below says **proved** (the code or data says so outright) or **inferred** (the code
makes it very likely; one render would confirm it).

## Sean's six points, and where each comes from

| What Sean saw | Whose | Cause |
|---|---|---|
| One red mahogany on everything, floor included | material library + building spec + prop recipe | 2 |
| Stretched even grain, no wear, no dust, plastic top | material library (no furniture role) | 5 |
| Pigeonholes empty with white backs | props (dressing) | 6 |
| Corner split orange / blue-grey; grain through paint; no grime or scuffs | light (the split), building recipe (the boards), shader (the wear) | 1, 3, 7 |
| Window a flat slab, thin trim, nothing outside | building recipe | 4 |
| Dim and flat, no lamp, no contact shadows | light + building spec | 1 |

## 1. What reads fake, ranked by lift for its cost

Crops are in `docs/reviews/2026-11-doctor-room/`.

### 1. The room has no light of its own (light lane; the biggest lift)

**What a player sees:** `desk_corner.jpg`. One wall is flat orange, the wall beside it flat
blue-grey, with a hard line down the corner. No shadow has a shape. The bottle wall is lost in the
dark. At night the room would be black.

**Cause:**
- **Proved:** the spec has no lamps (`doctor.json` `"lamps": {}`). The only lamp is the one the
  prop lab's `dress.gd` adds to the surgery for its night view.
- **Proved:** the whole building's indoor light is one probe with one flat colour
  (`FalseFrontBuilding._add_interior_ambient`: amber `(1.0, 0.82, 0.62)` at 0.45, or RoomLight's
  colour). One tint for nine rooms cannot have shape.
- **Proved:** no sky light comes through his windows. RoomLight makes its soft window light only
  for the front door and two fixed false-front window places (`RoomLight._room_for`), not for the
  spec's fourteen real windows.
- **Inferred:** the orange / blue split is the probe's edge, not light. The probe's box stops at
  the studs' inner face (`width - STUD_D * 2`) and fades over 0.3 m. The outer walls' boards sit
  2 cm inside that edge, so they get almost none of the amber and take the sky's cool fill
  instead. Partitions are well inside and get all the amber. The desk stands where a partition
  (orange) meets the east wall (blue).
- **Already logged:** thin contact shadows under the real look's SSAO (#711).

**Fix:**
- The probe's box reaches past the outer walls' boards, and its tint is near neutral.
- RoomLight takes its openings from the spec's own windows and doors.
- Every spec names its lamps (here: a reflector lamp in the surgery, a desk lamp, a hall lamp),
  and rooms are judged with them.

**Lane:** art (light). `false_front_building.gd` is gameplay's file: say so in the commit.

**Check:** in the desk view the two walls differ in brightness but not in hue. The cheap judge's
tell 1 (flat light) passes in the dispensary by day and the surgery at night.

### 2. One red wood on the floor and all the furniture (material library, props)

**What a player sees:** `dispensary.jpg`. Floor, counter, shelving, desk and chair are one
saturated red, flame-figured wood. It looks like one texture poured over the room.

**Cause (all proved):**
- The floor is the walnut because it was "the library's only passing floor"
  (`doctor.json` `finishes.floor`: `fine_walnut_tg`). No pine or fir floor is in the library.
- Every furniture board is the same entry: the desk 42 members, the counter 30, the shelving 14,
  all `lib:fine_walnut_tg/few`.
- The prop recipe asks for it: "So a table matches the floor it stands on"
  (`docs/briefs/prop-factory.md`, the recipe brought up to date, point 1).
- The walnut's own tint doubles the scan's red (`tint_new [2.0, 1.72, 1.5]`). It passed on a
  small panel at "game"; a whole room of it was never judged.

**Fix:**
- A worn softwood floor in the library, judged as a floor: pine or fir, 10-14 cm boards, a path
  worn pale from door to desk, dirt in the joints.
- Furniture woods by class, never the floor's entry: oak or ash for office pieces, painted pine
  for the shelving and counter, walnut for one hero piece a room.

**Lane:** art (the library entries and their judging), props (re-pointing the kit files: a
one-line change a prop once the entries pass).

**Check:** in any room view, the floor and the biggest piece of furniture are plainly different
woods. The props critic's "all one stock" note is gone.

### 3. The wall paint is drawn on boards nearly three times too wide (building recipe)

**What a player sees:** `desk_corner.jpg`. Planks about 24 cm wide with wood grain showing through
thin white paint, like stained plywood. No skirting at the floor, nothing at the ceiling.

**Cause (all proved):**
- The paint that passed is "narrow planed pine boards", 9 cm, with a bead
  (`painted_pale_tg`: `board_w 0.09`, `bead 1.0`).
- The builder cuts inside boards 24 cm wide (`spec_building.gd` `_finish`: `bw := 0.24` for
  `boards`) and draws each member as one library board. So the judged look and the built look are
  different things. The grain that reads as fine at 9 cm between beads reads as plywood at 24 cm.
- Only the `wainscot` finish builds a skirting. `boards` has none, and no rail at the ceiling.
- The casings take the wall's own paint (`/m/casing` -> `inside`), so they vanish. The spec's own
  words ask for green trim and sash.

**Fix:**
- A finish is drawn at the board width it was judged at. Keep the 24 cm member for cost and draw
  it as the entry's boards (three 8 cm beaded boards on one member), or cut members to the
  entry's width where the count allows.
- Every finished room gets a skirting and a rail or cove at the ceiling.
- Casings take the trim's finish, not the wall's.

**Lane:** art (the building lab's builder).

**Check:** a test that fails when a member's drawn board width is more than a fifth off its
finish's `board_w`. In the corner view you can count beads.

### 4. The windows are a sheet of glass in an unlined hole (building recipe)

**What a player sees:** `window.jpg`. One flat grey pane. Dark rough strips down both sides (you
are looking into the wall). A bright slit of daylight under the sash. Outside, a grey box. From the
street (`front_noon.jpg`) the two show windows read as orange boards.

**Cause:**
- **Proved:** `_glass` makes one glass member for the whole opening. The spec's `"lights": 4` is
  read by nothing (no code mentions it). There is no sash, meeting rail or glazing bar.
- **Proved:** the glass is a 28 % grey-green film (`WoodMaterials.glass`) with no dirt and no
  reflection of the room.
- **Inferred from the picture:** the opening's reveal has no jamb lining, so the stud space
  shows; the stool does not meet the glass.
- **Proved:** the neighbours are the valley's grey blocks. A window that faces one shows a grey
  wall 1-2 m away.
- **Inferred:** the orange show windows are cause 1's amber fill seen through the film.

**Fix:**
- A window is built as a sash: stiles, rails, glazing bars by `lights`, a pane a light (each pane
  then breaks alone, which the gunfights want), a lined reveal, a sill that meets it.
- `Checks.built_right` fails a window whose `lights` are not built or whose reveal is open.
- Glass with dust in the corners.
- Until the neighbours are built, judge window views that face the street or the yard.

**Lane:** art (the building lab's builder); gameplay for how panes break.

**Check:** the front office window shows four lights and no dark strips. From the street, the show
windows read as glass.

### 5. The furniture's finish is a wall board's (material library)

**What a player sees:** every face of the desk the same new varnish. Big flame figure across an
11 cm drawer front. No rubbed edges, no dark round the pulls, no dust. The chest's top shines
sky-blue like plastic.

**Cause (proved):**
- A prop's `lib:` wood is the wall board's material with the outdoor ageing switched off
  (`PropKit`: grime 0, no sun fade, no streaks). The only wear is the `/top` role.
- The scan is mapped at a wall's scale, so a small part shows a slice of big figure. One scan
  serves every part.
- **Inferred:** the plastic sheen is varnish 0.9 reflecting cause 1's sky fill.

**Fix:** a `furniture` role in the library shader: smaller, straighter figure; edges rubbed pale;
dark handling wear round pulls and at the knee hole; dust on faces that look up; the varnish
duller in patches. Judged on a chest of drawers, not a wall panel.

**Lane:** art (shader and library), then props re-point.

**Check:** the materials judge on a furniture panel at "game" or better; the blind critic no
longer says "one piece of stock".

### 6. Storage with nothing in it (props; the cheapest)

**What a player sees:** the pigeonholes hold a few sheets stood upright, which read as white
backs. The bottle wall is a grid of the same bottle. Tops are bare.

**Cause (proved):** the desk does have a walnut back (`case_back`); what shows pale is the paper.
The critic's round 3 already says the rest (the grid, the empty slots).

**Fix:** a storage prop ships with what it holds, mixed and untidy: ledgers, letters, an inkwell;
jars of three sizes with gaps. Batch D3 (#819) brings books; add the desk's and the bottle mix.

**Lane:** props.

**Check:** the blind critic's "empty" and "wallpaper" notes are gone.

### 7. The indoor paint's wear lands under the floor (shader; a bug)

**What a player sees:** no hand-rubbed band, no scuffs low, no grime at the skirting.

**Cause (proved):** the paint's indoor wear is placed by height over the building's ground
(`scan_wood.gdshader`: `hp = v_world.y - v_ground`; `_library_finishes` passes the structure's
origin). His floor is 0.95 m above that. So the hand band (0.75-1.1 m) falls at the floor line, and
the low scuffs (under 0.35 m) fall below the floor, out of sight. Wear by a door or a latch does
not exist at all: a board does not know where the doors are.

**Fix:** inside finishes are given their floor's height. The spec's `use` marks (the building
lab's `Marks`, built for "lived in" and inert in the game) drive wear at doors, latches and the
desk.

**Lane:** art.

**Check:** a band at hand height in the hall; scuffs above the skirting.

## 2. Rules for the recipes (all APPROVED: Sean's yes to the five picks on #821, 2026-11-11)

**`experiments/building_lab/RECIPE.md`**

- APPROVED (#821) (step 2): a spec is not done without its lamps. Every room people use names one, with
  where it hangs or stands.
- APPROVED (#821) (step 2): each room's finishes are named by room, not one `inside` for the house (the
  surgery's grey-green is already in the library).
- APPROVED (#821) (step 3): windows are sashes with their `lights` built and their reveals lined;
  `Checks.built_right` fails otherwise.
- APPROVED (#821) (step 3): every finished room has a skirting, casings in the trim's finish, and a rail
  or cove at the ceiling.
- APPROVED (#821) (step 4): a finish is drawn at the layout it was judged at. A test compares each
  member's drawn board width with its entry's.
- APPROVED (#821) (step 4): floor, walls and furniture never share an entry.
- APPROVED (#821) (step 4): inside wear is measured from the room's floor.
- APPROVED (#821) (step 5): before any judge round, a room has its lamps, its skirting and its windows.
  Views are the ones a player gets: standing height, from the door. Window views face the street
  or the yard until the neighbours exist.
- APPROVED (#821) (step 5): one "whole room" view a building is checked for one wood or one tint
  covering more than half the frame.

**`docs/briefs/prop-factory.md` (the recipe brought up to date)**

- APPROVED (#821): strike "So a table matches the floor it stands on". Replace with: a prop's wood is
  never its floor's entry; a room holds at least three woods or finishes.
- APPROVED (#821): furniture takes the library's `furniture` role, not the wall board's.
- APPROVED (#821): woods by class. Plain rooms: painted or bare pine, oak. Fine rooms: one walnut or
  mahogany hero piece.
- APPROVED (#821): a storage prop is not done until it holds something, mixed.
- APPROVED (#821): the batch's judge views include one whole-room view with the building's own lamps.

**`config/material_library.json` and `docs/concept/judge/MATERIAL.md`**

- APPROVED (#821): a floor wood for each building class (rough: wide pine; common: pine or fir, worn;
  fine: narrow oak or maple), judged as a floor with a worn path.
- APPROVED (#821): a `furniture` role, judged on a furniture panel.
- APPROVED (#821): a paint passes only at its own board width, and the judge is shown one corner of a
  room as well as the panel.
- APPROVED (#821): a fine wood is judged once more as a whole wall and floor before a building uses it
  widely (the walnut passed small and failed big).

**Light (`#711`, `#608`)**

- APPROVED (#821): a spec building's indoor fill covers its outer walls and is near neutral.
- APPROVED (#821): RoomLight's openings come from the spec.

## 3. What the jail session should do first (#811)

1. **Before any look work, read this file's section 2.** The jail's steps 4-6 are where these
   causes would repeat.
2. **Lamps into `jail.json` first** (the office's desk lamp, a hall lamp by the cells), so no room
   is ever judged unlit.
3. **Windows:** the jail's are barred. Build the sash and lined reveal behind the bars now, as the
   pattern the store and saloon reuse.
4. **The office's finishes by name, three different ones:** a floor that is not its furniture's
   wood, walls at the entry's own board width, trim in the trim's finish. If the library has no
   passing floor wood, say so and ask for it; do not reuse a wall wood.
5. **Skip judge rounds until 2-4 are in.** The doctor's rounds spent their renders on being told
   "dark, empty, one wood".
6. Leave the probe, RoomLight and the shader's wear height to the light and material sessions,
   unless Sean says the jail session should take them.

## What I am least sure of

- The probe-edge reading of the orange / blue corner is from the code, not from a test render.
- The window's dark strips are read from one crop.
- I did not see the front at golden hour.
