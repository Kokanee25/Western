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
