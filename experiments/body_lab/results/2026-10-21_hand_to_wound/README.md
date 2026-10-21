# A hand to the wound (Sean, 2026-10-21: "you do the wound grab")

**Before:** a man hit and still on his feet did nothing with his hands. The `clutch` and `tend`
poses put both hands in the same place, whatever the wound.

**Now** (`HumanBody._reach_for`, `_grab_step`, `_arm_to`):
- **When.** A man hit and still standing (or crouched, or aiming) puts a free hand over the hole:
  - his neck or throat;
  - his chest, belly or hip;
  - the other arm.
- **Which hand.** The one on the wound's side. Never the arm that's hit, never the hand holding his
  gun (he keeps aiming with the other), and never a broken or lost one.
- **How it moves.**
  - It's procedural: two-bone IK (posing the arm by where the hand must go) on the shoulder and
    elbow, after the pose. The hand lies across the hole, palm in.
  - On the neck it comes up from in front, the elbow down and the fingers round the side toward the
    back.
  - On the trunk it lies level across it, and on a limb along the way the arm comes.
- **Timing.** Not a flinch (Sean, 2026-10-18).
  - `GRAB_DELAY` 0.3 s: he's only just found it.
  - `GRAB_REACH` 0.55 s: eased in.
- **Holding on.** He holds it while it bleeds (`GRAB_HOLD_BLEED`, 0.15 ml/s) or hurts
  (`GRAB_HOLD_PAIN`), and lets it fall over `GRAB_LET_GO`, 1.2 s.
  - He lets go when he passes out, goes down, puts his hands up, or the hand is needed or broken.
  - A worse wound later takes the hand.
  - Out of reach (a shin, standing), he leaves it.
- **The blood.** A hand pressed over a spurting artery turns the jet into blood welling out between
  his fingers (`HumanBody.hand_over`, `BloodJet`).
- It only shows. It doesn't press on the bleed: pressure is still his tending's (the brain's
  `_tend`).

**Measured** (the lab's `grab_<spot>`: a revolver ball from 15 m, his hand watched 3 s; all four
men the same):

| spot | hand | palm on the hole | |
|---|---|---|---|
| neck (carotid) | right | 0.88 s after the hit, held | |
| chest (heart) | left | 0.88 s, held | the gun hand stays free |
| upper arm (right) | left | 0.88 s, held | |
| thigh (femur broken) | none | – | he's down: the femur takes his leg |
| belly | none | – | knocked down by this ball (a roll) |
| hand (right) | left | 0.88 s, held | he brings the shot hand in to the front of his belly and holds it with the other |

- None of the 160 wound runs changed.
- **Cost:** `--perf --brains` with and without it (`--no-grab`, `HumanBody.hand_to_wound`), three
  runs each, ten outlaws, five or six of them holding a wound. Their bodies take 1.87–2.03 ms with
  it against 1.48–1.76 without: about 0.1–0.15 ms a frame in two runs of three (0.55 in the noisiest).
  That's ~0.1 ms at Sean's, inside the people budget. The IK is worked out once per arm and each
  joint set once a tick.
- `sheet.jpg`, the drifter and the rancher, at 0.2 / 0.6 / 0.8 / 1.0 / 1.75 s after the hit:
  - row 1: the drifter's neck;
  - row 2: the rancher's neck;
  - row 3: the drifter's chest (left hand, palm on the heart);
  - row 4: the drifter's upper arm (left hand round the right arm);
  - row 5: the drifter's right hand, brought in and held.
- Footage: `run.py --render --scenario=grab_neck,... --out=DIR` writes a frame every 3 ticks for
  2 s (`DIR/<man>/grab_*/frames/`), real speed at 20 fps.
