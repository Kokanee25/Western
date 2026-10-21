# Gore painted by Gemini (Sean, 2026-10-21: "go ahead with Gemini and make some good gore")

**$0.28** on run 105 (`textures = blood:stumps,gore`; Gemini 3 Pro image, the pick of the gore test
in `../2026-10-21_blood_paint/`). With the blood marks and the test, $1.62 of Sean's $3 is spent.

**What it painted** (`gore.jpg`, top: the eight textures as cut):
- `stumps`: four limbs in section where they were torn off.
  - One bone, its marrow, muscle bellies in their pale sheaths, a ring of yellow fat and the skin
    (an upper arm).
  - A thigh.
  - Two bones (a forearm or shin).
  - A blast's splintered bone and shredded muscle.
  - The sections follow Gray's Anatomy, the cross-sections of the limbs.
- `gore`: four big wounds.
  - A shotgun's crater from a few feet.
  - An exit burst outward in flaps.
  - A blast's tear peppered by gravel.
  - A torn gash. The wounds follow DiMaio, *Gunshot Wounds*.

**The cutter** (`cut_blood.py`, `blood_map.json`):
- Gemini painted the stumps at a slant, with the limb's side showing. `face` finds the cut face
  by its colours: red muscle, yellow fat, and the bone it closes round. It fits the ellipse the
  face makes and stretches it back to a circle, seen end-on.
- The wounds keep only what's red, so the painted skin drops out and they lie on each man's own
  skin.

**In the game** (`HumanBody`):
- `_stump_face`: a disc with the painted section across the stump and the limb's torn end.
  - It sits where the opening leaves the skin and is as wide as the limb there.
  - The stump gets its own section (`_stump_look`); the torn end gets that or the blast's.
- `_gore_edge`: the painted torn edge round each opening that's big enough to show the insides.
  - The entry is a crater, the exit a burst, a blast's a peppering.
  - It is laid on the skin and clothes round the hole and grows with it. The insides show in the
    hole itself.
- Neither appears with reduced gore (`Settings.reduced_gore`).
- Bottom of `gore.jpg`: the knee stump and the shin that flew (the lab's new `stump_close`
  frames), and a shotgun from 5 m into the upper arm.

**Not yet:**
- From most angles a stump's face is end-on to the camera only when he lies right. The muscle
  and bone of the insides stand proud of it, which reads well up close.
- `gore_gash` isn't used yet: no wound in the game tears a long gash. A knife would.
