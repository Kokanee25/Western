# The gore lab, first round (Sean, 2026-10-21: "em all in whatever order you want")

The list is `docs/briefs/gore-lab.md` (all of it but the head hit's knock-out and kill, the ragdoll
lab's). `sheet.jpg` is the lab's new `gore` scenario: a row of the rancher, one injury each, done to
him as he stands and drawn four seconds on (`python3 experiments/body_lab/run.py --render
--scenario=gore --model=old_rancher_s1`). Paint: Gemini 3 Pro image, runs 108 ($0.42) and 109
($0.14), so $2.18 of Sean's $3 in all.

## In, with a test each

**A. What a ball does** (`Anatomy.trace`)
- Soft lead that breaks a bone flattens and goes on wider, a bigger hole out (sheet: flattened).
- On a strong bone it sometimes splits in two, two tracks and two holes out.
- Side-on to a bone, it skips off it, chipping it, and leaves bent; Ballistics follows it.
- It carries a plug of his clothes in, kept for the infection.
- Fired within a metre, burnt powder and soot surround the hole, wider and fainter with range.
- Closer than 30 cm, the cloth scorches round the hole.
- A contact shot tears the entry open in a star.
- These rolls come from where they happen, not from the man's dice, so they can't change how a
  fight goes (one did once; see the status entry).

**B. What a wound does to him**
- A cut radial nerve drops his wrist.
- A broken arm bone lets the arm hang; bound up, it goes in a sling across him.
- A broken kneecap keeps the knee straight, and a torn gut hunches him.
- Each comes on over 1.5 s.
- He breathes faster and deeper when short of breath or in shock, then slow gasps at the end.
- A holed lung's cough is pink froth, and a chest wound into the lung bubbles with each breath.
- A scalp wound above the eyes runs blood into one eye (worse aim).
- Missing fingers loosen his grip.
- Burst eardrums, blast lung, blind eyes, a broken jaw (no speech) and a cut spine (crawling)
  were there already; they now show.

**C. Blood** (`WoundSigns`, new)
- Blood runs from burst eardrums.
- A blow to the face gives a nosebleed that drips.
- Blood comes from his mouth after a lung, windpipe or gut wound, running from the corner when
  he's down.
- A broken jaw spits blood and a tooth or two.
- A man bleeding on his feet leaves a drip trail.
- Bloody handprints come from the hand that held a wound.
- Smears are left where he's dragged or slides.
- Blood dries dark and brown over game hours (`Blood.dry`, from the day cycle).
- A full splat list recycles its oldest.

**D. More kinds of wound**
- `HumanBody.take_knife`: a stab, narrow and deep; a slash, gaping, which across the throat opens
  the carotid. Nothing in the game uses a knife yet; it's there for one.
- A glass shard left in a cut, and a lodged splinter, stand out of him.
- A buckshot pellet lodged from further off is a dark lump.
- Fire and a blast's flash burn his bare skin and scorch his clothes (`burn_marks`).

**E. After**
- A packed wound gets a bandage, red through while it bleeds.
- A tourniquet is a belt above the wound.
- A broken arm goes in a sling; a broken leg is splinted with two sticks.
- A wound with cloth in it festers from about the third game day, and a clean one sometimes
  does, with fever.
- A limb's infection goes to gangrene, black and green, and kills four days on.
- `HumanBody.amputate` takes the limb off, tied, with the sewn stump, and the fever goes.
- A clean wound heals to a scar in 12 game days, a line for a cut. It's kept in `to_dict`, for
  when there's a save to put it in.

**F. Last moments**
- His face greys in shock and death: the face skin shader's `pallor`, art's file, at Sean's word.
- Slow gasps at the end.
- Flies come to the dead after two game hours.

## Not yet, or not right
- **Small on the Studio men's faces:** the ear and mouth runs are small and thin; side views show
  the ears better than the sheet's front view.
- **The handprint on a wall:** it doesn't show in the sheet, though its test passes on the plain
  body. A Studio man's hand sits apart from where the physics hand is.
- **The knife in the belly frame:** the camera ends up inside him once he's down.
- **The eyes open after death:** that's the face rig (characters' lane); there's no blink to stop.
- **Singed hair:** not done.
- **The sling:** his hand is held across him, but there's no sling cloth drawn yet.
- **What a knife, a doctor or an amputation are in play:** they're APIs and lab setups; the game
  has no knife, no doctor and no saw yet.
- **The golden pictures:** they need rendering again after this, and re-approving (Sean's OK of
  2026-10-21 covers what this PR changes).

## After (2026-10-22, Sean: "keep going")
- **An ear or the nose shot off, the jaw shot away** (#215, build 1980): painted by Gemini in run 110
  ($0.14): `ear_torn`, `nose_gone`, `jaw_gone` round the hole, laid upright, and the flying ear wears
  `ear_piece`.
- **On the Studio men's faces:** the runs are wider, the ear runs longer (they show down his neck),
  the nosebleed comes out under the moustache, and the mouth runs from both corners.
- **The handprint:** it's taken from where his hand is drawn (`HumanBody.drawn_hand`), so it lands
  on the wall by the hand you see.
- **The sling:** a cradle round the forearm, and a strap up over his front to the other side of
  his neck.
- **Singed hair:** at the temple toward the fire, for a strong burn.
- **`--setups=a,b`** renders only those gore setups.
- **Ten wounded men** (`--perf --brains`), timed alternately against 8245696 on this machine: 4.4 ms
  here, 2.9 at Sean's, against 2.5 / 1.65. That's still under the 4 ms budget on average, but the
  worst frames go over it.
  - The body's tick doubled. What grew: favouring the wound 0.43 ms for ten men (the falls' third
    round), the hand to the wound 0.32, the wound signs 0.38 (now 0.17, every fourth tick), the
    stains 0.09, and the pose loop +0.35.
  - The pose loop is likely the marks and dressings hung on his joints, moved with every turn.
    Not changed yet.
- **Not right yet: the skull shows at a Studio man's temples once his head is opened.** The
  interior's skull shell is the anatomy's size, wider than his drawn head. It was like that before
  this round. It wants fitting to each man's head mesh (art and characters).
- **Bullet holes as real ones are** (Sean, 2026-10-22: "way too big"; research entry and exit
  wounds). From DiMaio's *Gunshot Wounds* and *Knight's Forensic Pathology*:
  - An entry from a distance is a neat hole a little under the ball's width, with a 1–2 mm scraped
    collar at its edge.
  - An exit has no collar and its edges turn out: a slit or star a little over the ball's width.
  - A ball flattened on bone tears out about twice its width.
  - A contact shot over bone splits in a star round a sooty hole.
  - The marks were repainted to that (runs 111 and 112, $0.28; the first run's collar was a
    separate ring and its contact hole white). They're drawn at the ball's width: a .45's entry is
    about 10 mm, where it was a 35 mm patch, and its exit about 15 mm, where it was 60 mm.
  - A single ball no longer tears the skin open. It used to open a 4 cm hole with a 6 cm painted
    crater at a lodged ball's entry and at every exit. Buckshot and blasts still do.
