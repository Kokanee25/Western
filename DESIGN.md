# Salt Creek — design document

Working title. A first-person immersive-sim Western for PC, set in one small frontier town in 1882.
Everything here came out of the first design session (Sept 27, 2026). Decisions are marked **decided**;
anything still open is listed at the end.

---

## 1. The game in one paragraph

You're a homesteader who bought the best spring claim in the valley a few months ago. The railroad is
coming through in thirty days, and whoever owns the water when it arrives will be rich. On the first
morning the sheriff is found gut-shot on the road outside town. From there you can become the law, ride
with the gang, sell out to the cattle baron, work as a hired gun, or just try to keep your farm. Nothing
is scripted: the town runs on rules, its people remember what you do, and the story is what happens
when you push on it.

## 2. Pillars

1. **Systems, not scripts.** Everything obeys consistent rules — bodies, fire, wood, law, memory,
   money — and stories emerge from how the rules meet. If the player burns the building where a
   scene was meant to happen, the systems carry on.
2. **Consequences that stay.** Wounds, rubble, bullet holes, scorch marks, grudges and reputations
   persist until something in the world changes them.
3. **People you can actually talk to.** Townsfolk with AI minds, real memories, their own goals and
   the social rules of 1882.
4. **Grounded and gritty, with humour** (**decided**). The world takes itself seriously; the people
   in it don't always. Deadwood and Unforgiven more than a spaghetti Western. Violence is heavy and
   has lasting consequences.
5. **A small world, deep.** One valley done thoroughly beats a big empty map. Build a few systems that
   interact heavily rather than many that don't.

## 3. Platform, view, time, saving (all **decided**)

| | |
|---|---|
| Platform | **PC / big screen first** (Windows, Mac, Linux; Steam later). Not phone-first. Controller and keyboard/mouse. |
| Engine | **Godot 4** (see CLAUDE.md for why). |
| View | **First person** only. You can look down and see your body, holster and boots. |
| Day length | **45 real minutes** per in-game day. The railroad clock is 30 in-game days. |
| Saving | **Only when you sleep in a bed.** No save-anywhere; consequences stay heavy. |
| Death | **You wake up at the doctor's** — hurt, poorer, and the town knows what happened. |
| World | **The town, its outskirts, and a mine.** Grow outward later (ranches, railroad camp, open country). |

## 4. The look (**decided**)

Reference: `docs/concept/saloon-night.png`, `docs/concept/livery-fire.png` and
`docs/concept/street-golden-hour.png` (Sean, 2026-10-01: the main street at golden hour, first person
with the revolver; the target for the street, materials and daylight).

- **"High-resolution Duke Nukem 3D", in real 3D** (Sean, 2026-09-28): solid, readable low-poly models
  with **pixel-art textures** (chunky, countable texels, nearest-neighbour filtering, roughly 32–64
  texels per metre), rendered into a pixelated frame whose internal resolution is a setting. The
  concept art is the mood and lighting target; the models aim for this crisper, simpler look.
- **Default look (Sean approved, 2026-09-28; resolution raised 2026-09-30):** 1280×720 render (was
  640×360: the concept painting's clean pixels are the textures' squares, each several screen
  pixels big, which 640×360 smears), 32 texels per metre on the world (2026-10-02, Sean's "at the
  painting's density": the judge measures the paintings' squares at twice the size 64/m gave; was
  64, and 40 before that) with distance smoothing, a mosaic of close shades square by square, a
  dark line along every board's edge, pixel shading off. The look stays switchable in play as graphics options: render
  resolution, texel size (32 / 24 / 16 / 64 per metre) and pixel shading (banded light + dither). They
  are debug keys now (F2 / F7 / F6) and move into a settings menu later.
- **The concept painting's pixel style, as rules (Sean, 2026-09-30: "that exact art style"):**
  (1) squares painted on the surfaces at a set size in metres (~32/m on the world's wood and dirt, ~64–80/m on cloth, ~120–190/m on
  faces and hands), drawn nearest, so near things have big squares and far things small; (2) each
  square several screen pixels big, so it stays crisp and tilts with the surface (hence the
  1280×720 default); (3) a mosaic: neighbouring squares differ a little in shade within a warm,
  limited palette per material; (4) clean drawing: clear shapes, bold dark features (eyes, brows,
  moustache, tie), a white collar that reads; (5) warm soft lamplight with glow and haze, deep brown
  shadows. Everything in the game follows them, people and world alike.
- **Animation is realistic, not retro:** smooth motion-captured animation (Mixamo, the CMU library,
  or video-to-mocap of Sean acting scenes out), procedural touches (feet planted on the ground,
  looking, breathing, balance), full **physics ragdolls**, and **active ragdolls** for the living
  (muscles driving the body towards the animation, so hits stagger, buckle and spin people). No
  stepped, sprite-style animation.
- **People are detailed enough to lose a finger:** a full skeleton down to three bones per finger,
  and meshes with separate fingers, so a shot-off finger or hand is visible and physical (it falls
  away as its own piece). Close up, at a table or on your own hand, it must read clearly.
- **Modern lighting on top:** warm oil lamps against blue moonlight, long low sun, dust and smoke in
  the air, light shafts through gaps in plank walls, embers, bloom, fog. The lighting carries the
  atmosphere.
- **Palette:** sun-bleached ochre, rust red, dusty sage, sky blue by day; deep blue and amber at night.
- **People:** realistic faces and bodies with readable silhouettes and layered clothing
  (hat, vest, coat, shirt) — each layer takes damage separately.
- Expectation: lighting, atmosphere and effects can come very close to the concept art; models and
  faces are deliberately simpler (low-poly, pixel-textured), while movement is fully realistic.
- **Target: the saloon concept painting as a real-time game** (Sean, 2026-09-28: "a game that looked as
  good as that would be amazing"). A look pass is planned after M2: a hand-pixelled final pass
  (1-px outlines, lit-edge highlights, palette snapping, pixel-stable camera — the known technique
  for 3D that reads as hand-made pixel art), painterly pixel-art textures generated with an image
  model and mapped onto models, and much denser dressing (bottles, glasses, pictures, people).
  **Faces as good as the painting's** (Sean, 2026-09-29: "I want the faces to look that good"):
  reachable. At the game's 640×360 the painting's face is only about 70×80 pixels, and a 3D face can
  make those pixels (image-model face on a sculpted head, framed and lit as the painting has him).
  What's hard is keeping it that good in motion (talking, blinking), from other angles, for every
  townsperson rather than one, and in the web build's simpler renderer.
- **Method for the look pass: a shot match** (Sean approved, 2026-09-28). Build the scene in
  `docs/concept/saloon-night.png` in the game saloon and put a fixed camera at the painting's angle:
  first-person, seated at a round table with a lamp, bottle and tin cup in the foreground; a man in a
  coat and hat across the table; card players at a green-felt table on the left; the swinging doors
  open onto a moonlit street; the staircase and balcony with a man leaning on the rail; a piano; the
  long bar on the right with the bartender, back bar, mirror and bottles; oil sconces everywhere;
  a stag head and framed paintings on the walls; smoke haze in the lamplight. Add the view to
  `tools/screenshots.gd` as `shot_match_saloon`. Each art session: render it, put it **side by side
  with the painting** (`docs/screenshots/shot_match/<date>_<n>.png` next to the concept), name the
  **biggest difference**, fix that first, repeat. Keep every round's render so progress is visible.
  - **Gap assessment (2026-09-28):** lighting and mood (dark and muddy → hot lamp glow, deep contrast,
    amber vs moon blue, volumetric haze, colour grade) — reachable, mostly tuning; textures (flat →
    richer palette and value range) — reachable; dressing (placeholder boxes → the full prop list in
    `docs/TOWN.md`) — reachable, volume of work; **characters (primitive shapes → real proportions,
    detailed skin/hair/clothing textures snapped to the pixel palette, animated faces) — the biggest
    gap**: needs proper character models from the Blender pipeline (a free human base such as MakeHuman
    is a reasonable start) and face animation (iPhone face capture); the painting's face detail is
    the target (see "Faces as good as the painting's" above); a saloon of 8–12 people.
  - Order of attack: lighting → textures and palette → dressing → characters.
  - **Characters: how we get to the painting's men** (Sean, 2026-09-29, after the first generated
    body: "how do we get our characters to look like this"). The code-lofted `BodyMesh` is a
    mannequin; the painting's look needs four things, in this order:
    1. **Shot-match scene first:** the man seated across a saloon table at night, lamp between
       you, framed like the painting (`shot_match_saloon`), so every character change is judged
       against it in lamplight, not at noon in the desert.
    2. **A real human base mesh:** MakeHuman's base body (CC0, so it's fine in the public repo;
       real face topology, hands, adjustable build/age) cut to ~4–8k triangles, fitted to our
       17-segment skeleton and the anatomy hitboxes, split per segment exactly as `BodyMesh` pieces
       are now (openings, `sever_limb`, ragdoll, X-ray must keep working; keep `HumanBody`'s API).
    3. **Detail baked into pixel textures:** the painting's faces are flat pixel colour with the
       light, wrinkles, stubble and cloth folds painted in. Model detail in Blender (creases,
       folds, garments draped with cloth simulation: coat with lapels, vest, shirt, cravat,
       bandana, hat), bake it (AO + curvature + detail) into small textures (~256 px face,
       128–256 px per garment), then quantize to a pixel palette. Clothes stay separate layers.
    4. **Faces painted by an image model** in the concept's style, projected onto the head UVs and
       pixelated: a different face per townsperson from a prompt. Key as an environment secret
       (OpenRouter has image models); never in the repo.
    Then the lighting pass (warm key, rim light, haze) on the same shot.
    - **Blender runs on GitHub Actions**, not in the cloud workspace: the workspace's network blocks
      download.blender.org and pypi (bpy). A workflow (manual trigger) installs Blender and the
      MakeHuman assets, runs `tools/blender/*.py`, and commits the generated `.glb` + textures to
      `assets/people/`. Every step is a script; nothing hand-made. Keep sizes small (git).
    - The game loads the generated people through the same `HumanBody` (`BodyMesh` stays as the
      fallback when a generated body isn't there, and for tests).
  - Real-GPU caveat: cloud renders use software Vulkan; ask Sean for a screenshot of the same view from
    his PC at milestones, since lighting can differ.
  - **What the painting's pixels are (2026-10-01; reopened 2026-10-02 with Sean after
    `docs/ART_REVIEW.md`):** blocks of colour laid over a **cinematic, photoreal picture**. Near,
    the blocks are screen-aligned dabs with slightly ragged, soft edges and a little gradient and
    texture inside, sized as a fixed real size falls with perspective (the near ground ~11 px at
    1280 wide, the coat 6–8, a horse 3–4, men down the street 2–3), so textures at a fixed density
    in metres on the surfaces give the right sizes. **Far off the blocks dissolve**: the bartender
    across the room, the mountains, the sky and the far street are nearly smooth and soft, dimmed
    and warmed by haze; distance makes things soft, never chunkier. Under the blocks: deep warm
    shadows (41 % of the saloon's pixels are under L* 10), a few true emitters that bloom into the
    air (lamps, the moon, the sun), real detail in every surface (folds, boards each their own
    colour, ruts and hoof marks), and specific objects (a saddle, a stag, bottles with labels). No
    outlines: edges come from value contrast. The 2026-10-01 reading ("tiles on the surfaces,
    each lit as one flat colour") got the near field right and the far field wrong, and the
    per-tile lighting is the style's smallest part. What that means for us:
    - **The base stays:** pixel textures at a fixed density on 3D surfaces, nearest filtering,
      1280×720 or native (native by default once the frame rate allows; the 1.5× nearest upscale
      to 1080p doubles every other pixel). `tiles.gdshaderinc` (light per texel, **P**) is kept,
      low priority.
    - **Under it, a cinematic picture:** light with range (a dark room, lamps that bloom, warm
      bounce), haze with distance, textures with real structure (each board its own, no 2 m repeat,
      no random square-to-square noise), real shapes for props and people.
    - **Over it, a light finish:** bloom off true emitters only (drawn above display white, the
      glow threshold above every lit surface) and a grade; later, possibly, a soft block edge.
      Never a screen-space mosaic, never a global palette snap.
    - **Blocks need content:** realistic detail first (baked, scanned or image-model painted),
      then reduced to blocks keeping the light and the per-board colour. Random variation on a flat
      field reads as static, not paint.
    - **The man:** a lit portrait under blocks, not blocks with a face drawn on. The paint-bake
      pipeline (the painting's pixels projected, dominant colour per square, posterised light) is
      at its ceiling; next is a flat-lit turnaround under ordinary lighting, then image-to-3D.
    - The order of work is `docs/ART_REVIEW.md` §10; the judge's old measures reward noise and
      composition (§5 there) and are being replaced.
  - **The plan from here (Sean, 2026-10-01), both pictures as targets** (`saloon-night.png`,
    `street-golden-hour.png`). Tiles are built; what's missing is what goes *in* them, and the room:
    1. **Characters:** image model paints a full-length man → image-to-3D (Tripo/Meshy on GitHub
       Actions, key as a repo secret) → our Blender fit to the skeleton and hitboxes → tiles. The
       MakeHuman pipeline stays the fallback.
    2. **A texture factory for the world:** image-model paintings of each material (weathered
       planks, floorboards, tabletop, dirt road, brick, painted sign boards with lettering, hay),
       made seamless along a member, reduced to broad palette-limited colour clusters at the tile
       size; replaces `PixelArt`'s noise textures. Same principle as the clothes bake: realistic
       detail first, then tiles.
    3. **A reference judge:** fixed views framed like each painting (`shot_match_saloon`, a new
       `shot_match_street`), rendered side by side with it, plus measured differences (tile size,
       palette, contrast, brightness by region), so the art session can iterate unattended and keep
       every round's image.
    4. **Dressing:** the saloon as painted (bar, back bar and mirror, bottles, card table with
       players, piano, stairs and balcony, sconces, pictures, stag head, chairs, rug) and the street
       (signs with lettering, lanterns, barrels, crates, hay, troughs, wagon, water tower, windmill,
       telegraph poles, a horse at the rail), then golden-hour light and haze down the street.
- The internal resolution is also the main performance lever: 1280×720 is under half the pixels
  of 1080p, and F2 drops to 960×540 or 640×360 on modest PCs.
- **Gore setting** (full / reduced), so the game can be shown to anyone.

## 5. Setting and story

### Premise: Salt Creek, 1882
- A small frontier town in a dry valley. The railroad's survey line runs through it; the rails arrive
  on **day 30** whatever the player does.
- **Water is the stakes.** The player's claim holds the best spring.
- **Day 1:** the sheriff is found **gut-shot** on the road. By the wound rules he has hours, not
  minutes. He's conscious, knows who shot him, is frightened and unsure who to trust. He might tell
  you, pin his badge on you, be saved by the doctor, or die while you're elsewhere — and the town
  goes looking for someone to blame.

### Cast (each has goals, secrets, relationships, and acts whether or not the player does)
- **The sheriff** — dying on day 1. What he knows and who he trusts drives the opening.
- **The cattle baron** — wants every drop of water in the valley, and is patient.
- **The railroad land agent** — buying claims with forged deeds.
- **The Colter gang** — hired to scare homesteaders off, with plans of their own. One of them
  "knows" the player (see §6).
- **The doctor** — knows more about the sheriff's wound than he says. The most important
  character in the town, given the wound system.
- **The saloon owner** — hears everything, sells it to whoever pays.
- **The widow** — refuses to sell her claim, alone.
- Plus ordinary townsfolk (barber, blacksmith, storekeeper, preacher, children, dogs) with routines,
  feuds, debts, friendships and affairs among themselves.

### How the story works
- **Author the situation, not the scenes:** a place under pressure, people with goals, a clock.
- A **timeline of what the antagonists do if unopposed** (the gang burns someone out, the agent
  takes deeds to court, the survey comes through, the rails arrive).
- A handful of **hand-built big moments** that fit any path (the sheriff's last hours, the
  railroad's arrival).
- A **drama manager** (the idea from the Façade-style project): an AI director that watches pacing —
  gives someone a reason to act when it goes quiet, and lets survivors react instead of forcing the
  plot back when the player breaks it.
- **Many endings, none written in full:** become sheriff and hang the gang, sell the spring and get
  rich, marry the widow and hold the valley, ride with the Colters, leave with the baron's money…

### Story flow (**decided**, 2026-10-01)
The danger in a systemic game is a sandbox with nothing pulling you along. The flow comes from a
clock, factions working their plans, and the player always holding a few live leads.

- **Three acts on the 30-day clock** (days are 45 real minutes, so ~22 hours of play):
  - **Act 1, the sheriff (days 1–3):** the hook. You ride into town at dawn and find him on the road.
    Saving him teaches first aid under pressure (the hospital-steward past pays off in minute one).
    Whatever happens, by day 3 the town has no law, the Colters are in town, and everyone wants to
    know what you saw.
  - **Act 2, the squeeze (days 4–21):** every faction works its plan whether or not you act. The
    baron buys or frightens out homesteaders, the agent files forged deeds, the gang runs jobs and
    leans on the town, the widow holds out. You pick sides, or play them off each other.
  - **Act 3, the rails (days 22–30):** the survey crew arrives, deeds go to the circuit judge, and
    the factions make their final moves (a burn-out, a robbery of the land money, a trial, a
    showdown). Day 30: the first train comes in. Whatever the valley is that morning is your ending.
- **Faction plans, not quests:** each antagonist has a timeline of steps with conditions (the gang
  burns out the widow on day 9 *if* she still holds her claim and nobody's guarding it). Steps happen
  off-screen if you're elsewhere; you hear about them or find the ashes. Stop a step and the plan
  adapts or escalates.
- **Leads, not a quest log:** news reaches you the way it would in 1882 — rumour in the saloon (the
  owner sells it), a letter, the weekly paper, a wanted poster, a kid running up the street, a
  gunshot two streets over. Your character keeps a **journal** in his own words (what he saw, who
  said what, what he means to do). That's the only "quest list".
- **The drama manager keeps the pace:** it watches tension. Quiet too long, and someone gets a reason
  to act (a stranger arrives, a debt comes due, the gang gets drunk). Too much at once, and it holds
  a step back a day. It never forces a scene the world has made impossible; it lets survivors react.
- **Hand-built moments that fit any path:** the sheriff's last hours, the widow's burn-out night, the
  trial, the robbery of the land money, the train's arrival. Each is staged so it works whoever's
  alive and whatever's standing.
- **You find the sheriff** (decided): you ride in at dawn and he's on the road. The other big moments
  work the same way where they can: the player is there, or arrives in the middle, rather than
  hearing about it afterwards.
- **The game can end early** (decided): hanged after a trial, dead with no doctor to wake you at,
  run off your claim, or killed by the gang. A game-over is told the same way as an ending (the
  paper, the town), so it reads as a story, not a fail screen.
- **The ending is the state of the world:** who's alive, who owns the spring and the widow's claim,
  who wears the badge, what's still standing, what people think of you. Told as the newspaper's
  front page and the town's reactions on day 30, plus a walk through the town afterwards.

### Reasons to fight (**decided**, Sean 2026-10-01)
The gunfight and the bodies are the deepest systems we have, so the 30 days must bring regular,
varied reasons to use them, without turning the town into a shooting gallery. Every fight should
come out of the story or the world, and most standoffs should have a way out that isn't shooting.
- **The factions bring fights to you.** Their plans include violence on a schedule: the gang
  burning out the widow (defend her at night, or arrive to the ashes), night riders at your own
  spring, the stage robbed on the road, the land money hit in town, a jailbreak, the baron's hands
  running off homesteaders, claim jumpers, and the act-three showdown.
- **Work that pays in lead:** bounties from the wanted posters (alive pays more, so arrests are
  rewarded over killing), guarding the stage or the money shipment, riding with a posse, clearing
  the gang's hideout or the mine.
- **The street:** call-outs and duels (built), drunks who draw, bar fights that escalate, men you
  wronged coming back, bounty hunters after you if you're wanted.
- **No shooting animals** (Sean: "I hate games where you shoot animals"): no wolves, no hunting, no
  animal targets. Horses, dogs and stock are in the world as creatures, never as things to fight.
- **Shooting for sport:** a turkey shoot or a Fourth of July match at range with money on it. Shows
  off drop, sway and the guns' feel with nothing at stake but pride and a purse.
- **Pacing:** the drama manager aims for something tense most days and a real fight every day or
  two, more in act three; quiet days are for people. Standoffs that end without a shot count as
  much as fights (clean arrests and talking men down are rewarded: DESIGN §10).

### A day in Salt Creek (**decided in outline**, 2026-10-01)
- **The loop:** leads come in → you pick what matters → you act → the world reacts → you sleep
  (and save) and the clock moves on.
- **Three pressures every day:** the story clock (factions move whether you do or not); money
  (ammunition, the doctor, food, a room, drinks, bribes); your body (wounds, sleep, hunger, drink).
- **Needs are light** (Sean): eat and sleep, small effects if you skip (tired: slower, shakier;
  hungry: weaker, grumpier with people), never a survival game.
- **Proposed, not yet decided:** a note on your claim at the bank, due before the rails arrive,
  as the money pressure (and a lever for the baron and the land agent).
- **What fills the hours:** work for money (bounties, shooting matches, guarding the stage,
  odd jobs, a barn raising, a deputy's pay), people (the saloon, cards, rumours, favours),
  investigation (the sheriff's shooting, evidence, witnesses, tracks), the factions' moves, and
  recovery (the doctor, rest, supplies, cleaning your gun).
- **A typical 45-minute day:** dawn (wake, wounds, ride in, the rails a little closer) → morning
  (errands and leads) → noon (the street empties; questioning, cards, the doctor) → afternoon
  (the day's main job) → evening (the saloon fills, the day's rumours, trouble) → night (raids,
  sneaking, or sleep; darker as the moon wanes).

### Romance (**proposed**, 2026-10-01)
Everyone will try it, usually crudely, in the first five minutes. That's fine: the people are people,
so it plays out the way it would in 1882, and the crude attempt is a source of humour, not reward.
- **Women in the town are people, not prizes.** Each has her own life, opinions, situation and
  wants (the widow fighting for her claim, a married woman, the hotel landlady, a working girl
  upstairs at the saloon), and most of them aren't looking for anything from you.
- **The crude approach goes badly, in character:** a cold look, a slap, a drink in your face, her
  husband or brother looking for you, the barkeep throwing you out, the whole town hearing about
  it by evening. Reputation drops. Being a pig is allowed; it's just remembered.
- **Courtship is slow and earned:** days, not minutes, built on what you actually do (keeping her
  claim safe, honesty, showing up, standing by her when it costs you). She can say no, change her
  mind, or lose interest if you turn out to be someone else. Some people may court you.
- **1882 rules apply:** propriety, chaperones, gossip, reputations (hers more than yours, which she
  knows), marriage as a real, binding thing with property consequences (marrying the widow is a
  path to holding the valley).
- **Fade to black.** Nothing explicit, ever. The conversation AI keeps characters in character and
  steers away from sexual content; intimacy is implied (a door closing, the morning after, the
  town talking).
- **Men too** (Sean, 2026-10-01). Same rules as any courtship: slow, earned, the other man's own
  choice. A few men in the valley are open to it as part of who they are (written as people, not
  a gimmick); most aren't. 1882 makes it a secret: discretion matters, being found out has real
  social cost for both of you, and that risk is what gives it weight (the Brokeback Mountain
  register, not a joke). A crude pass at a man who isn't interested goes as badly as one at a woman.

### History, handled with care
An honest 1880s West includes Indigenous nations, Chinese railroad workers and Mexican ranchers and
vaqueros. They belong in the game as real people with their own lives and perspectives, written with
research and care — never props or stereotypes. (Details still open; see §13.)

## 6. The player character and paths

- **Who you are:** a homesteader who arrived a few months ago and bought the spring claim. Known
  enough for people to have opinions, open enough to go anywhere.
- **Former army (proposed backstory):** a Civil War veteran (about forty in 1882) who served as a
  **hospital steward** — the enlisted medical rank that worked alongside the surgeons — and maybe
  stayed on in the frontier army after the war. It explains why the player knows tourniquets, splints and
  packing wounds, why they can handle a rifle, why they carry things they don't talk about, and why a
  stranger might say "I know you." Historical note (verify when writing it): in that era ordinary
  soldiers mostly weren't formally taught first aid — improvised tourniquets (a handkerchief and a
  stick) were common on battlefields, and surgeons packed wounds with lint; organised first-aid
  training for soldiers came later (Esmarch in Germany in the 1870s, the US Army Hospital Corps in
  1887). A hospital steward is the believable way to know it in 1882. Knowledge is period-accurate:
  germ theory and antiseptic practice were only partly adopted, so "clean" is a relative word.
- **An ambiguous past:** when the Colters ride in, one says "I know you." Rode with them once?
  Mistaken identity? A lie to rattle you? What you say in that first conversation decides it, and the
  townsfolk remember your answer.
- **No class menu.** Paths open and close through actions:
  - **Sheriff** — the badge from the dying man, a town vote after you stop a robbery, or the judge
    deputising you. Kept by keeping order, lost by abusing it.
  - **The gang** — noticed if you're violent, broke or crooked; tested with small jobs first.
  - **Hired gun** — bounties, guarding shipments, muscle for the baron one week and the widow the next.
  - **Rancher** — keep your head down and farm; the water war comes to you anyway.
- **Rules:** actions outweigh words (witnesses matter more than what you claim); every faction (town,
  law, Colters, baron, railroad) keeps its own opinion of you; paths can cross, including an
  **undercover path** (the badge while riding with the gang, or the judge's man inside); some doors
  close for good.

### Skills: you get better by doing (no XP bar, no level-up screen)
- Like Kingdom Come and Skyrim: each skill improves through use and training, not points.
- **Skills and what they change:** *pistol* (steadier aim, faster cocking and gate reloads, quicker
  recovery from recoil), *rifle*, *first aid / medicine* (faster and more reliable tourniquets, better
  packing, reading a wound correctly, eventually setting bones and stitching), *riding*, *brawling*,
  *tracking* (reading footprints and blood trails), *lockpicking*, *farming and ranch work*, *hunting*.
  No speech skill: conversation is real talk; standing comes from reputation and relationships.
- **Shown in the body, not numbers:** a better shot's hands sway less and reload faster; a practised
  medic's hands move quicker. Occasional diary lines instead of pop-ups ("Getting steadier with the Colt").
- **Ways to improve:** practise (tin cans behind the livery), real use, and **teachers** — the doctor
  teaches setting bones, an old gunfighter teaches drawing from the holster, a rancher teaches roping.
  Books and manuals for some skills.
- **Limits:** skill improves the character's hands, never past what a real person could do; the player's
  own aim and decisions still matter most. Injuries can lower skills (a lost trigger finger, a shoulder
  that never healed right).
- **Army start:** strong first aid and rifle, decent pistol, poor at farming (a homesteader who's
  better at stopping bleeding than raising corn).

## 7. Bodies: anatomy, wounds and visible damage

### Hidden anatomy (under every person, player included)
- **Bones:** skull, spine, ribs, pelvis, long bones of the arms and legs.
- **Major arteries:** neck, arms, groin, legs.
- **Organs:** brain, heart, lungs, liver, gut, kidneys.
- **Muscle groups** that decide what each limb can do.
- **Physiology, not hit points:** blood volume, blood pressure, breathing, pain, shock, and adrenaline
  (delays pain; a man may run a few seconds before he knows he's hit).

### Ballistics
- A shot traces a path through the body; tissue slows it, bone stops, deflects or shatters under it.
  Small pistol rounds can lodge in a thigh; rifle rounds go through and can hit someone behind.

### Effects (examples)
- **Femur breaks:** he drops, can still shoot from the ground.
- **Upper arm bone:** the gun falls from that hand.
- **Femoral artery:** heavy bleeding; dead in minutes without a tourniquet.
- **Lung:** short of breath, can't run, may cough blood.
- **Gut shot:** conscious and talking for hours, dying slowly without a doctor — time to confess,
  beg, or say where the money is.

### Fear and morale
Most fights end when nerve breaks, not bodies. Wounded people panic, run, beg, surrender, play dead.

### Treatment
Bandages, tourniquets, packing wounds, the doctor, bullet probes, whiskey, amputation, infection a week
later. Wounds last for the player too (a broken leg means weeks on a crutch).
**Healing is slow** (Sean, 2026-10-05): shot in the day, a bandage stops the bleeding but doesn't
put you back to normal; you heal properly by sleeping (later, with beds and saving). Where you
come round after going down will change later too.

### Field first aid (player and every NPC)
- **Direct pressure** slows bleeding but occupies your hands (no shooting, reloading or riding).
- **Improvised tourniquets** (belt, twisted bandana and a stick, rope): tight stops arterial bleeding,
  loose only slows it; left on too many hours, the limb may be lost (amputation at the doctor's).
- **Packing and bandages** from torn shirt strips (the shirt is actually shorter afterwards); clean cloth
  beats a filthy bandana, which raises infection risk later.
- **Splints** from a rifle, a board off a rubble pile, fence rails. **Whiskey** for pain and bad
  cleaning. **Moving casualties:** drag behind cover, carry, throw over a horse.
- **NPCs do all of it:** outlaws drag a downed partner behind cover and cinch a belt on his leg (two men
  not shooting); a lone wounded man stops to tourniquet his own arm (a chance to close in or call for
  surrender). Whether they risk themselves depends on relationships: loyal friends help, hired guns are
  left to bleed. Townsfolk who like you press a rag on your wound; the ones you wronged walk past.
- **Choices it creates:** save the man who shot at you because he knows where the gang hides; keep a
  prisoner alive long enough to stand trial; walk away and let the town judge you for it.
- Treatment rules should be accurate (Sean has first-aid training — use it as the reference).

### Layered characters (Skyrim / Kingdom Come approach)
- **One shared skeleton, many meshes:** a body mesh plus each garment as its own mesh skinned to the same
  skeleton (Godot: several meshes under one Skeleton3D).
- **Layers:** base (long johns — period-accurate, and the floor for stripping); middle (shirt, trousers);
  outer (vest, then coat/duster; chaps); accessories (boots, hat, bandana, gloves, gun belt).
- **Covered regions are hidden:** body and inner layers are split into regions; each garment declares
  what it covers, so nothing pokes through and hidden parts aren't drawn.
- **A few body types** (lean to heavy) via blend shapes; garments fit each type.
- **Beyond equipment:** every layer has its own damage and stain map — a bullet leaves lined-up holes
  through coat, vest and shirt; blood soaks outward through the layers; stripping reveals the damage in
  order down to the wound. Clothes are items: torn into bandages, stolen for disguise, taken off the dead
  with the hole still in them, washed, patched by the tailor, burned. They affect the body: a thick coat
  slightly slows a small pistol round, wet clothes make you colder, dirty clothes change how people react.
- **Asset cost:** every garment must fit every body type and move without clipping. AI generators are
  weak at wearable clothing, so expect a mix of generated, adapted and hand-fixed pieces.

### Visible damage
- **Wounds painted exactly where the anatomy was hit:** entry hole, blood spreading and soaking into
  clothing over time, larger exit wound. Bandages cover them; they're still there the next day.
- **Clothing layers tear and stain separately.** Strip a dead man's coat and the hole is in it.
- **Dismemberment:** bodies built in segments split at joints (below/above knee, forearm, upper arm,
  head) with finished stumps; the rest stays a working ragdoll. Dynamite at close range can take limbs;
  the doctor may amputate a crushed leg. Survivors carry it for the rest of the game (crutch, peg leg,
  a new trade) and their AI mind knows it.

### Fine detail and permanent marks
- **Fingers:** hands are modelled finger by finger; a hand shot can take one or more off. Losing the
  trigger finger means shooting with the middle finger (slower, less accurate) or learning the other
  hand; losing a thumb makes cocking a single-action revolver awkward. Grip, reins, dealing cards and
  playing piano all suffer. A missing finger is identifying.
- **Brawling layer:** bruises, black eyes, broken noses, split lips, loosened and knocked-out teeth.
  A missing tooth shows as a gap when the character talks, and can change their voice (a slight whistle
  or lisp in the TTS). Bruises go yellow and fade over days; a broken nose sets crooked unless the doctor
  straightens it.
- **Grazes and scars:** shallow wounds bleed, scab and heal into a scar exactly where they were;
  burns scar too. Scars are permanent.
- **Healing timeline:** fresh wound → stitches or scab → pink scar → pale scar over weeks of game time.
  Lost parts never come back.
- **Marks feed other systems:** people notice and ask ("Where'd you get that?") and the AI knows the
  story if they witnessed it; scars and missing fingers go on wanted posters as identifying features;
  a beard, hat or bandana can hide them, and witnesses can pick you out by them.

### Grazes, glass cuts and open wounds (visible interior)
- **Grazes:** a bullet path that only clips the edge of a segment makes a furrow, not a hole — a
  shallow bloody groove that bleeds for a while, stings (pain), and heals into a scar.
- **Glass:** shattering windows throw shards as low-energy cutters: several small lacerations at once
  (face, hands, forearms raised to cover), some shards **embedded** until the doctor removes them; a cut
  near an artery can be serious.
- **Visible interior:** every body carries a simple low-poly, pixel-textured interior built from
  `config/anatomy.json` — ribs, sternum, spine, muscle, lungs, heart, liver, gut — hidden under the skin.
  Each body keeps a list of **wound volumes** (centre, radius, depth). Small ones stay holes; large ones
  make the skin and clothing shaders **discard** inside the volume and draw torn flesh edges, revealing
  whatever's underneath.
- **Shotguns:** each buckshot pellet is traced separately. At range they spread into separate small
  wounds; at point-blank they arrive as one mass and **destroy a whole region** — ribs broken or gone
  (fragments thrown as rigid pieces), lung or heart exposed. Tissue destruction accumulates per region;
  past a threshold the region opens. Sean has seen real close-range shotgun wounds — his read on it is the
  reference for getting it honest.
- **Blasts** (dynamite) open wounds the same way through pressure and debris, alongside limb loss.
- **Persistent:** the body stays opened; the undertaker and doctor can examine it (evidence).
- **Tone:** pixel-style, grim and honest, never splatter; the **reduced gore** setting keeps the skin
  closed and shows a dark soaked wound instead.

### Design traps to respect
- **Realism makes fights short** — give the player ways to survive mistakes: cover, thick coats,
  a bible in the breast pocket, luck.
- **The player must understand what happened** — show it in the body (clutching the leg, going pale)
  and through the doctor's diagnosis ("Ball's lodged against the bone").

### Bodies in motion: active ragdoll tied to the anatomy
- Every living body is physical: virtual muscles drive it toward the animation pose and keep balance.
- **Healthy:** follows the animation but reacts to shoves, bullets and uneven ground.
- **Hit:** the bullet's impulse lands where it hit; the body twists, staggers, grabs; muscles fight to
  recover.
- **Wounded:** anatomy weakens specific muscles — a broken femur makes that leg go slack so he
  collapses onto it; a shot shoulder drops the arm; blood loss slowly weakens everything.
- **Unconscious:** slack but breathing and groaning. **Dead:** muscles off, pure ragdoll.
- **Agility and hand switches:** a hand planted on a corner post to swing round at a run (tighter
  turn, automatic near corners, not with a wounded arm); switching the pistol to the weak hand to shoot
  around a left-hand corner or after a broken arm or lost trigger finger (shakier until the skill
  grows); switching rifle shoulders. Enemies do the same — a wounded outlaw changing hands shows what
  you did to him.
- **Mocap covers the living moments before physics wins** (the stumble, catching himself on the rail,
  the gut-shot stagger to cover); the handoff from animation to physics is what makes it read as real.
  See `docs/MOCAP.md`.

### Recoil (procedural, never recorded)
- Each shot applies a real force at the gun hand, sized by the load (a black-powder .45 Colt is a
  heavy, slow shove, not a sharp snap); with active ragdolls it travels wrist → elbow → shoulder and the
  muscles bring the gun back down. Muzzle rise and settle on a spring, with variation per shot.
- Depends on the shooter: one hand vs two, pistol skill (faster recovery), wounds and missing fingers
  (more rise, slower recovery), fatigue and fear (shakier). Re-cocking the hammer between shots is done
  with the hand's finger bones in code — that rhythm is what makes it feel like a single-action Colt.
- Sean has fired real guns: his feel notes ("too snappy", "should push, not flip") are the tuning
  reference.

### Enemy combat behaviour (game rules, not the conversation AI — far too slow for a fight)
- **Cover first:** troughs, wagons, building corners; because buildings are real members, the game
  knows what's solid — plank walls stop little, pistol rounds punch through, cover wears away.
- **Teamwork, not perfection:** one suppresses while another moves or flanks; instant pre-recorded
  callouts ("He's behind the trough!", "I'm hit!", "Reloading!").
- **Believable aim:** no aimbot — accuracy from distance, fear, skill, wounds, black-powder smoke
  hiding the target, firing on the move. Outlaws miss a lot.
- **Real reloads:** one cartridge at a time through the gate, ducking behind cover; listen for the click.
- **Morale:** casualties break the weak (run, surrender, play dead); the leader's nerve holds them until
  he goes down. Every fight ends differently.
- **Fair tells** before they fire: raising the gun, stepping out, a shout.
- **Presentation:** mocap combat moves (crouch-run, peek, lean out, blind fire over cover, dive, crouched
  reload, dragging a wounded friend), **procedural aim** (arms and head track the real target), active
  ragdoll hit reactions, life touches (hard breathing, glancing around, flinching at near misses).
- Benchmark: F.E.A.R.'s enemy AI for decisions, RDR2 for physical reactions. First test: one outlaw on
  the test street in M2, then a few.

## 8. Buildings, fire, dynamite, rubble

### Structures from real members
Buildings are framed the way a timber framer would: posts, beams, studs, joists, siding boards,
shingles, bricks — tracked as a **support graph**. When a member breaks, anything that has lost its
load path to the ground sags, then collapses. Burn out the corner posts and the roof comes down;
knock out one stud and the wall shrugs it off.

### Fire
- Materials burn differently: dry siding and hay fast, heavy beams smoulder, stone and adobe don't burn.
- Heat spreads to neighbours; wind pushes it, rain slows it, water puts it out.
- Burning members weaken, so fires end in real collapses.
- Townsfolk respond: bucket lines from the trough, saving belongings and horses, remembering who
  they saw with the lamp oil.

### Dynamite
- Breaks what's near it: plank walls splinter into holes, brick and adobe crack into chunks, doors
  blow off.
- Can start fires in dry wood.
- Feeds the anatomy system: pressure, flying debris, burns, deafness and ringing ears.
- Uses: blow the vault, collapse a mine entrance, open the jail's back wall.

### Persistent rubble (**must have**)
- **The pieces are the wall.** Destruction frees the actual boards, beams and bricks that made the
  structure; they fall with physics and land where they land. No generic debris, no vanishing.
- Settled pieces **go to sleep** (physics off), piles are **merged for drawing**, collision is
  simplified. Only dust, splinters and sparks fade.
- The save records only the difference from the original town (which members broke, where each piece
  lies).
- Rubble is part of the world: cover, firewood and reusable material, obstacles (a fallen beam blocks
  the jail door), and evidence (a blasted safe in a scorched pile).
- **Nobody tidies up by magic:** the owner demands payment; the carpenter is hired, hauls wreckage over
  days and rebuilds member by member with new lumber. If nobody pays, the ruin stays.
- Scorch marks, bullet holes in siding and bloodstains on the boardwalk persist the same way.

### Rope (**must have** — it's a cowboy game)
- **A real simulated rope:** a chain of segments that sags, swings, drags in the dirt and catches on
  corners and edges; never a straight line between two points.
- **Wrapping and friction (capstan effect):** each turn around a post, rail or saddle horn multiplies
  the grip — two turns hold a lot, one slips. This is how a cowboy **dallies** around the saddle horn.
  (Wreck Diver's wrap-and-tie rope — winding angle around a post, tie off after a full loop — is the
  prototype of this.)
- **Tension:** stretches under load, **snaps** past its breaking strength, frays where it rubs; holding
  on too hard gives **rope burn** (a wound). Knots are real states: tied, slipping, cut, burned through.
- **Uses:** lasso (a horse's neck, a steer's horns, a fleeing outlaw's legs — the ragdoll takes over
  when he goes down); tie people up (wrists, ankles, to a post or chair; prisoners struggle, bad knots
  slip); drag something or someone behind a horse; **pull a wall down** with a horse (the member-built
  frame fails where it's weakest — the jailbreak); tie a horse to a hitching rail (a spooked horse can
  pull free); the hay-loft pulley; the well bucket; climbing; rescues from the creek or a mine shaft;
  the gallows (part of the law system, handled seriously).
- **Attaches to real things:** building members, ragdoll limbs, horses, props — a lassoed man is
  dragged by his actual leg.

## 9. People: AI minds, memory, conversation

### Nobody is an enemy by default (**decided**, 2026-09-29)
- **No hostile flag.** The player is one more person in town. Outlaws, lawmen and townsfolk each have
  goals (the gang rides in to drink, see the baron's man, look over the bank) and opinions of
  particular people. Nobody shoots on sight; a fight happens between particular people because of
  what someone did.
- **Deeds, judged the same for everyone:** drawing, aiming at someone, shooting, hitting, insults,
  interfering with someone's business, hurting their friend, a badge. The player, the sheriff, a drunk
  or one of their own are all judged by the same rules, through what each person saw or heard.
- **What provokes a man depends on the man:** a hothead flares at a stare, standing too close or a
  hand resting on the holster; a professional only at a real threat. The obvious ones (pointing a gun,
  a shot, a blow) provoke everyone.
- **An escalation ladder, every step readable and reversible:** ignore → notice → wary (watches you,
  hand drifts to the holster) → warning ("Keep walking, friend") → threat (draws, aims) → fight.
  Holster, back off, apologise, buy a drink or talk him down and it steps back. Most encounters should
  end on the low rungs.
- **Hostility is per person and per moment:** in a robbery they turn on whoever resists; a clerk with
  his hands up is left alone; if the blacksmith fires on them, they fight the blacksmith. The player can
  stand in a doorway and let it play out.
- **The gang starts trouble on its own** (pushing the storekeeper around, a robbery, burning someone
  out), following its own plans and the unopposed timeline (§5), so there are moments the player can
  choose to step into, or not.
- **Called-out duels:** a man can call you out into the street, and you him.
- **Beaten men bargain:** a man who's lost can offer something for his life ("I'll tell you where
  Colter's hiding"), through the conversation AI once it exists.
- **It sticks:** grudges, debts and gratitude go into memory (below); the man you let walk away and the
  one you pistol-whipped remember you, and so does anyone who saw it.

### Memory architecture
1. **Events as small records**, not prose: who did what to whom, where, when, who saw it, importance.
2. **Opinions as numbers** per person (trust, fear, liking, respect), nudged by events, driving
   everyday behaviour **without** calling the AI (who serves you, who crosses the street).
3. **Recall only what's relevant** when a conversation starts: ~15–30 memories scored by involvement
   with the player, recency, importance and topic (the approach from Stanford's 2023 "Generative Agents").
4. **Nightly consolidation:** minor old memories fade or merge into beliefs ("thinks the stranger is a
   decent sort"); big events stay sharp.
5. **Shared knowledge stored once:** the robbery is one town event; people store how they know it
   (saw it, heard it from the barber, read it in the paper). Rumours can be wrong versions.
6. **The AI is never on the frame loop.** Town life runs on game rules; the AI is called only for
   conversation, asynchronously. The fixed part of each character sheet is prompt-cached.
7. **Saved per person**, loaded when they matter.

### Conversation
- **Voice first:** hold a button and speak (speech-to-text → the character's AI → text-to-speech with
  lip sync). **Suggested replies** generated for the moment, for controller play. **Typing** as fallback.
- **No dead air:** the character fills the gap naturally (a grunt, a sip, a glance) while the reply
  streams in.
- **Context counts:** drawn or holstered gun, distance, blood on your shirt, clothing, time and place.
- **Act mid-conversation:** hand over money, show a wanted poster, pour a drink, cock the hammer.
- **Characters can walk away**, and remember why.
- **Guardrails:** they stay in 1882 ("Don't know what a 'phone' is, mister"); the AI decides what they
  *say*, the game decides what they *can do* (a shopkeeper only hands over what's in his store);
  secrets stay secret until earned by trust or pressure.
- Critical information is never AI-only; must-work lines are authored.

### Action commands (say or type what you do)
- Two inputs: **talk** (speech to a person) and **act** (commands to your own hands). "Tell him to hold
  still" is speech; "hold him still" is an action.
- The AI turns an action command into a **sequence of real game actions**, each animated and taking real
  time. Example: "cut his shirt open, find where he's hit, tear the shirt into strips and pack the wound"
  → remove clothing (knife: fast / unbutton: slow) → examine → make bandages from the shirt (real items)
  → pack the wound and apply pressure.
- **Examination returns descriptions, not numbers:** "Entry wound under the left ribs, no exit. Blood
  dark and steady. His skin's cold and clammy." The player interprets (bullet still in, shock) or the
  doctor explains later.
- **Guardrails:** the AI can only choose from actions the game implements; impossible requests get an
  in-character "Don't know how to do that." Every step checks the world (knife? struggling? under fire?
  does the shirt exist?).
- A **radial menu** covers the obvious quick actions (pressure, tourniquet, drag) for controller play
  and emergencies; commands are for anything detailed. Works beyond first aid: search pockets, tie hands
  with his own belt, pour lamp oil along the back wall, hide money under the floorboards.

## 10. Law, evidence and society

- Sound travels: gunshots are heard across town; people investigate, flee or fetch the law.
- Witnesses and identification: light and dark matter; wanted posters with a likeness good enough to
  be recognised.
- **Evidence:** footprints in mud, blood trails, shell casings, a bullet dug out of a wall and matched
  to a gun. The lawman path is an actual investigation.
- **The law as a real process:** arrest, a cell, a trial with a judge and a jury weighing what the
  witnesses saw; verdicts can go against you; a hanging the whole town attends. (Sean's policing
  background is a design advantage here — clean arrests and use of force should be rewarded over a
  body count.)
- Ownership: locks, keys, lockpicking, deeds, property.

### Social interactions: "a round on me" (**decided**, Sean 2026-10-01)
Small, everyday social acts that cost something real and that people react to as people. The first
one is buying drinks.
- **Money is real coins.** You carry a purse (dollars, bits, a few cents) you can count; prices are
  1882's (a whiskey 15–25¢, "two bits" for the good stuff, a bottle about a dollar). No abstract
  gold counter.
- **Buying one man a drink:** say "let me buy you a drink" or push coins and a glass his way. It's a
  deed with weight: it softens a wary man a rung, opens a conversation, and is remembered ("you
  bought me a drink once"). It depends on the man: a proud one may say "I buy my own," a man with a
  grudge won't take it, and a drunk takes it and forgets you by morning.
- **"A round on me!"** Said loud in the saloon. The barkeep counts heads and pours (the price is real:
  ten men at two bits is $2.50), and the room reacts: a cheer, glasses up, "to the stranger!", the
  piano picks up, men drift to the bar. Everyone who drinks gets a small warm opinion of you, bigger
  if they're broke or it's a hard day in town. The rumour spreads ("bought the whole house a round").
- **You have to pay.** Coins leave your purse. Can't cover it? The barkeep's face drops, the room
  laughs, and you run a tab (a debt in his ledger, remembered, collected) or get thrown out. Skip
  out on a tab and that's theft.
- **Context changes it:** after a killing the room is quiet, and a round reads as guilt or bribery;
  the gang drinks your whiskey and still despises you; a widower doesn't toast. Rounds every night
  get smaller cheers and mark you as a man with money (someone may try to take it).
- **Drink is real:** each glass adds to drunkenness (aim sway, slurred speech in conversation,
  courage, memory gaps), for you and for them. Drunk men talk more and fight sooner.
- **More of the same kind, later:** tipping your hat, standing someone a meal, paying a man's fine,
  lending money, a game of cards, a toast at a funeral, settling a debt in public.

### Recognition and disguise
- **Witnesses store a description, not an identity flag:** face, build, clothes, hat, horse, gun, voice,
  scars, missing fingers, a limp. Wanted posters are built from those descriptions.
- **Recognition = matching** what they see now against what they remember, weighted by familiarity
  (strangers go by clothes; friends know your walk and voice), distance and light, and how distinctive
  the feature is (a plain brown coat means nothing; a silver-inlaid Colt, a pinto or two missing
  fingers give you away).
- **Disguise tools:** stolen clothes (the owner recognises his own coat), masks and bandanas (hide the
  face but are suspicious in themselves — except in a dust storm), shaving / growing a beard / cutting
  hair, swapping a distinctive horse or gun. **Voice is the hardest thing to hide:** people who know you
  may place it, and the AI grows suspicious in conversation.
- **Impersonation:** the dead deputy's badge and coat fool strangers, not locals; a gang member's hat
  and duster might get you into their camp until someone hears you speak.
- **Works both ways:** the Colters rob in masks too, and the lawman path becomes an investigation of
  half-seen coats, horses and missing fingers.
- **Descriptions go stale:** change enough and the poster stops matching; people who know you
  personally are much harder to fool.
- Rumour and the newspaper: news travels by word of mouth and the weekly paper prints a (slightly
  wrong) version of what you did.
- Funerals when people die; people attend, speak, remember, and some blame you.

### Why you won't burn the town down (**decided in principle**, 2026-10-01)
You can, and the game remembers it. But it should feel like a terrible decision, and most players
should care too much to do it.
1. **No undo:** saves only in a bed. Ash stays ash.
2. **The town is your life support:** each building is a service. Burn the store and there's no
   ammunition, oil, rope or food; burn the doctor's and nobody digs the ball out (you wake at the
   doctor's after going down — no doctor, no waking); burn the livery, no horses; the hotel, fewer beds.
   Services don't magically restock; whoever survives may set up again elsewhere, slowly.
3. **Named people early:** the first hour puts you with people who matter (the sheriff, the doctor,
   the widow, the barkeep who knows your drink), and every townsperson has a routine and remembers you.
4. **The town fights back, escalating:** witnesses describe you, posters go up, nobody sells to you,
   armed men come looking, a posse rides to your homestead, bounty hunters arrive on the stage.
   One bullet can kill you, so a town against you is a real threat.
5. **Fire doesn't care whose it is:** wind carries it, smoke chokes, it can take your escape route or
   ride out to your own barn.
6. **The tools come later:** lamp oil costs money; dynamite lives in the mine's powder magazine.
7. **If they do it anyway, it's a story:** the gang moves into the ruins, the railroad buys the land
   cheap, survivors talk about you for the rest of the game, the paper prints it. A burned Salt Creek
   is its own playthrough, not a dead end.

## 11. Immersion features

1. **Almost no on-screen display:** a pocket watch (or the sun and the church bell) for time; count the
   bullets in your belt loops or open the loading gate; health shown by your body (blurred view from
   blood loss, shaking hands, a limp); a real paper map you buy and mark; coins and notes you count.
2. **Guns as machines:** single-action revolvers cocked for every shot, one-at-a-time reloads through
   the gate, **black-powder smoke** that fills a saloon in a fight, misfires, fouling if you don't clean.
3. **A body you can feel:** see your legs and boots; hands that hold the reins, strike a match, drink.
   Hunger, thirst, sleep, cold, drunkenness and hygiene show in the body and in how people react.
4. **Sound:** wind in the boards, the piano through the wall, a dog two streets over, spurs on the
   boardwalk, gunshots echoing off the hills.
5. **Townsfolk with their own lives:** routines, relationships among themselves, children who go quiet
   when you pass with a gun, dogs that know their people.
6. **A readable world:** letters in drawers, the store ledger, wanted posters, the newspaper, gravestones
   — much of it written from the town's real events.
7. **Weather and seasons:** mud that slows horses and holds footprints, dust storms, winter, drought
   raising the stakes of the water war.
8. **Horses as creatures:** they tire, spook at gunfire, get hurt, can be stolen, remember who treats
   them well.

### Signature features (**decided**, Sean 2026-10-01: "Ya!" to all)
What nobody else does, made from joining systems we already have. **1–3 together are the game's
spine:** you find the sheriff, how well you treat him decides whether he lives, his last words
depend on his blood loss, the ball in him is the evidence, and it all comes out at a trial driven by
what really happened.
1. **The body changes how people talk.** The conversation AI is given the speaker's body state
   (blood loss, shock, pain, concussion, drink, a broken jaw or windpipe, fear). The dying sheriff
   is clear, then confused, then only a name; a broken jaw nods and grunts; a drunk lets things
   slip; a concussed witness gets the order of events wrong; a man in shock agrees to anything.
2. **Real forensics from real wounds.** The anatomy trace is evidence: calibre of the ball dug out
   (only certain men carry a .44), entry and exit (shot from behind, from above, from close: powder
   burns), the order of wounds, time since death (blood pooled, cold). The doctor and undertaker
   can examine bodies and tell you; the player can learn to read them (the medicine skill).
3. **A real trial.** The circuit judge sits in the saloon or church. You testify by speaking;
   AI witnesses tell what they actually remember (including what they got wrong in the dark); the
   evidence is shown; you can cross-examine; a jury of townsfolk with their own opinions of you
   decides. Verdicts can go against the innocent who couldn't prove it. Hanging is a game-over.
4. **Rumours that change as they spread.** Each retelling passes through a person (exaggerates,
   takes sides, forgets); by evening the saloon thinks you shot three men. The weekly paper prints
   its version; you can set the editor straight or pay him.
5. **Letters and the telegraph.** Write in plain words; letters go by stage over days, wires by
   the telegraph (if the wire's not cut). People answer or act: the US Marshal might come, the
   railroad might send a lawyer about the forged deeds. You can forge letters too.
6. **Leading people by talking.** Swear in deputies or hire guns and give orders in plain words
   ("you two cover the back door, nobody fires till I do"); their nerve, skill and loyalty decide
   whether they hold. Builds on the gang's teamwork (`Crew`) for your side.
7. **Your voice as a weapon (microphone, optional).** Loudness matters: a bellowed "Drop it!"
   carries further and frightens more than a muttered one; whispering keeps you hidden in the dark.
   Typed commands still work (shout/whisper as words).
8. **Teaching people.** The skills you learn from people, turned round: teach the Kid to shoot or
   the widow to dress a wound; it saves your life later, or he uses it against you.
9. **Legends between playthroughs.** A new game's old-timers tell a garbled story of your last
   character ("a stranger burned the saloon down a few years back"), and the graveyard has his
   marker. Stored outside the save, a few lines per finished game.

### World-building features (**decided**, Sean 2026-10-01)
1. **You can see the railroad coming.** Survey stakes, then grade, then rails creep across the
   valley a little each day; the work gangs' hammering and smoke get closer. The 30-day clock is
   something you see from your porch. Sabotage the line and it visibly stalls.
2. **The town builds and rebuilds itself.** Carpenters frame new buildings member by member with
   the structure system (a new store on an empty lot, tents becoming buildings as the rails near);
   after a fire, townsfolk clear the rubble and raise a new frame over days. A barn raising is a
   town event you can join and physically help lift.
3. **The moon tells time.** 30 days is one lunar cycle: the moon waxes and wanes through the game
   and darkness is real. The gang raids on dark nights; a full moon lets you see riders coming.
4. **The ground remembers.** Footprints in mud and dust until wind or rain wipes them; paths worn
   where people walk daily; blood darkening to brown over days; bullet holes stay; graves get
   flowers or get forgotten. Tracking (and covering your tracks) is real.
5. **A tintype photographer.** A travelling photographer sets up in town. Your picture can end up
   on a wanted poster with your actual face; he photographs the dead (the period custom), and his
   plates are evidence of who was where.
6. **The town's rhythm follows heat and light.** The street empties in the noon heat, the saloon
   fills at dusk, the lamplighter does his round; the church bell, the stage's arrival and the
   noon whistle tell the time with no display.
- Parked (Sean likes it, maybe no time): **your homestead built by hand** with the member system
  (fences, barn, well). Cut: water levels and drought, movable claim stakes.
- Parked (Sean, 2026-10-05: "eventually"): **a shovel that digs real dirt, and treasure to find.**
  The ground dug out as it's carved (the voxel damage's way of carving, on the ground), the dirt
  thrown in a pile; things buried to be found (a cache of stolen money, a strongbox, bones), and
  graves you can dig up, with the town's opinion of that.

Full list of buildings, interiors, set pieces and dressing: **`docs/TOWN.md`**.

## 12. First slice (what to build first)

**One small town** (saloon, jail, store, doctor, church, livery, a few homesteads), **about a dozen
people with real memories**, **a few in-game days**, and **one outlaw arriving in town**.

It must prove, in this order of priority:
1. **The gunfight feels good** — revolver handling, hits, wounds, fear. Combat feel is the longest tuning
   job; prove it early.
2. **The outlaw can end five different ways** depending on what the player does.
3. **Systems feed each other:** fire, destruction and persistent rubble, sound, witnesses, wounds.
4. **Talking works:** voice and suggested replies with memory-driven characters.
5. **The immersion core:** no display, real guns, sound, townsfolk with lives.

The test: **can the player cause a story nobody planned?**

## 13. Open questions


- **Tone details:** how dark the humour runs; how graphic the default gore setting is.
- **Historical groups:** how Indigenous, Chinese and Mexican characters and communities are included
  (needs research and care).
- **Name:** "Salt Creek" is a working title.
- **Mine:** what it's for (silver? a collapse? the gang's hideout?).
- **Economy:** prices, wages, what farming earns; how crafting (if any) works.
- **Voices:** which speech services; how much is pre-recorded vs live.
- **AI cost model** if other people play: player pays, bring-your-own-key, or priced into the game.
- **Hardware:** Sean needs a machine that can run the game once the town is lit and populated
  (e.g. an M-series Mac mini or a mid-range gaming PC). The current mini PC may handle early builds only.
