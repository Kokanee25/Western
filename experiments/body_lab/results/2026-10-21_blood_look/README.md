# How arterial blood looks (Sean: "the blood looks really off")

**Before:**
- Every drop of a jet (and of a cough or a torn-off limb) was a 2 × 5 cm shiny box. The jet read as
  a stack of red bricks with white edges, and coughs left red boxes hanging in the air.
- The jet's speed was a guess from the bleed rate, so it fell along his chest instead of arcing out.

**Now:**
- **Drops** (`Blood.drop_particles`, shared by `BloodJet` and `Blood.burst`):
  - Each drop draws the last 35 ms of its flight as a thin tube about 1 cm across (a particle trail).
    The drop is drawn wider than a real one so it shows at the game's pixel size; a real one is about
    twice the stream's ~2 mm.
  - Close to the wound, where they leave close together, the tubes run into one stream. Out along
    the arc they come apart into drops (Rayleigh–Plateau: a jet breaks into drops about twice its
    width).
  - Each drop is a slightly different red and darkens a little in flight. Wet, but without hard
    highlights.
- **Speed and pulse** (`BloodJet.jet_speed`):
  - The jet leaves at the speed of the pressure behind it: v = Cd·√(2P/ρ), ρ 1060 kg/m³, with
    Cd 0.6 for the torn vessel and the hole. That's about 3.3 m/s at systole.
  - Over each beat the pressure climbs from 80 to 120 mmHg in its first third, then falls back. A
    spurt on every beat over a lower steady stream, never stopping between beats (the arterial
    Windkessel).
  - The pressure falls as he bleeds out, so the spurts weaken. His heart rate climbs with shock, so
    they come faster.
  - Venous bleeding still wells and runs dark and slow; ooze drips.
- **Bursts:** coughs and torn-off limbs throw the same drops, not boxes.

**`before_after.jpg`:**

| | left | middle | right |
|---|---|---|---|
| top | the drifter's neck before, the boxes | after, at 0.2 s: a spurt arcing out | after, at 0.5 s: the stream coming apart into drops |
| bottom | the rancher after a 5 m charge in the chest before, boxes in the air | after, the cough's drops | the drifter's brachial after |

**Sources** (searched; abstracts and secondary sources only, so read the originals before a hard
number rests on them):
- SWGSTAIN, "Recommended terminology", *Forensic Science Communications* 11(2), 2009, and ASB
  Technical Report 033, 2017: a projected pattern is blood thrown out under pressure.
- Bevel T, Gardner RM, *Bloodstain Pattern Analysis*, CRC Press: an arterial spurt rises and falls
  with each beat, in large stains and finer spray.
- Bernoulli/Torricelli, v = √(2P/ρ): ~5.5 m/s at 120 mmHg, ~4.5 at 80, an ideal ceiling; real jets
  fall short. No measured arterial jet speed was found.
- Westerhof N et al., "The arterial Windkessel", *Med Biol Eng Comput* 47:131–141, 2009: the
  arteries' recoil keeps pressure (and flow) up between beats.
- ATLS (American College of Surgeons): heart rate climbs with blood loss (over 140 in class IV).
- Eggers J, Villermaux E, "Physics of liquid jets", *Rep Prog Phys* 71:036601, 2008: a jet breaks
  into drops about twice its width.
- Laan N et al., *Phys Rev Applied* 2:044018, 2014, and Attinger D et al., *Forensic Sci Int*
  231:375–396, 2013: blood's density ~1060 kg/m³, viscosity 3–5 mPa·s, surface tension 52–60 mN/m.
- Bremmer RH et al., *PLoS ONE* 6(7):e21845, 2011: stains go from bright red to brown over hours to
  days, not minutes.
- US Marine Corps FMST 402, "Manage Hemorrhage": venous blood is dark and flows steadily; it doesn't
  spurt.

**Not yet:**
- A wound's insides show through outside a studio man's slim shoulder: a glossy red bulge on top of
  the shoulder after an upper-arm shot. The insides are built to the anatomy's size and aren't
  limited to the opening. The fix is a shader that draws them only round an opening; shaders are
  the art lane's.
- Splats on the ground are small round decals, and cloth soaking up blood isn't drawn spreading.
