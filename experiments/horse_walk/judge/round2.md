# Blind judge, round 2 (2026-10-28)

A fresh agent (not round 1's), the same instructions, the pairs after round 1's changes. Condensed:

1. **Head and neck still high (large; all pairs).** The real horse's neck is long and near level, the
   poll at or below the withers, the nose low and well out; ours still steep, poll well above the
   withers, no visible nod.
2. **The fore still swings too high (large).** Real: a little bend at the carpus, the hoof a few
   centimetres up, toe down and forward. Ours: carpus and fetlock fold sharply, the hoof lifts to
   mid-cannon height, the sole up and back: "high-stepping trot or hackney action".
3. **The hind hooves "en pointe" at push-off (clear).** Real: the heel rises, the hock opens, the
   pastern stays in line with the cannon. Ours: the trailing fetlock over-flexes, the hoof tips to its
   toe with the sole facing back.
4. **The fores out of time with the hinds (clear).** The real fore events fall ~0.13–0.16 of a stride
   later after the hind events than ours: the 3D walk is "an even, square four-beat; the real one more
   lateral".
5. **Legs and spine stiff (small to clear).** Real loaded fetlocks visibly sink; ours stand as
   near-straight columns; the back, croup and barrel rigid.

Kept: the footfall order (lateral pairs, three hooves down most of the time), the stride length, the
stance legs' placement at each contact; the fore's roll-over at lift-off "close in direction".

## What was done about it

1. The neck lowered 26 degrees (was 16) under the model's standing pose, the nose 16 forward (was 12).
2. The knee's fold 50 -> 35 degrees, the hoof's flip in swing 65 -> 45, the toe's lift 7 -> 6 cm.
3. The hind's breakover 40 -> 35 and its flip in swing 60 -> 40 (25 was tried: the hind then couldn't
   reach its lift-off and slid 3 cm).
4. The lateral phase 0.25 -> 0.30. Sean's comment on #470 made the real footage the main reference
   and the literature the check; the clip measures 0.33, an even walk is 0.25; 0.30 is a lateral
   walk on the clip's side of the published spread.
5. The fetlock's sink at mid-stance 12/10 -> 18/15 degrees (fore/hind).

Seen in our own close render at LH lift-off: dark shards at the stifle and along the tail. The cause:
the game's glb has seam copies that disagree in weight (up to 0.26, on the neck, head and forearm too),
and copies a millimetre or two apart that the first fix's exact match missed. `rigtools.weld_weights`
now gives every group within 3 mm one weighting; the hind leg is re-weighted hip to hoof as one, and
the tail's hair is found as dark vertices nearer the tail's bones than any leg's.
