# Dynamite up close: options for Sean (list item 7; nothing changed)

**Today:**
- One stick (0.2 kg TNT) lying 1 m in front of a man bursts his eardrums and throws him down.
- Since fix 1, its gravel can wound him too: two pieces at 1 m, flesh wounds.
- He keeps every limb. A limb comes off only with the stick within about half a metre of a hand or
  foot, and about a quarter of a metre of a thigh.

**Why it's mild:** people take the side-on pressure of a charge in free air (`Blast.overpressure_kpa`,
Kinney-Graham). Two things a stick on the ground at his feet adds are left out:

1. **The ground.** A charge lying on the ground blasts a hemisphere, not a sphere. The usual
   allowance is to count it as about 1.8 times the TNT. The structures don't get this either.
2. **His front.** The side of him facing the blast takes the reflected pressure, 2–8 times the
   side-on. `Blast.reflection()` already does this for walls, not people.

**What each would give** (the game's own formula, 0.2 kg; distances to the part's skin):

| pressure at a part | today | ground (×1.8) | ground + his front reflected |
|---|---|---|---|
| at 1 m | 300 kPa | 470 | 2,070 |
| at 2 m | 62 | 95 | 260 |
| at 3 m | 28 | 40 | 94 |
| eardrums go within | 2.7 m | 3.2 m | 5.0 m |
| lungs bruised within (250) | 1.1 m | 1.3 m | 2.0 m |
| lungs torn within (700) | 0.7 m | 0.8 m | 1.4 m |
| a hand or foot off within (1,500) | 0.5 m | 0.6 m | 1.1 m |
| a forearm or shin off within (2,600) | 0.4 m | 0.45 m | 0.9 m |
| an upper arm or thigh off within (4,500) | 0.27 m | 0.33 m | 0.8 m |

My reading:
- **Ground only** is the safe correctness fix. It's physics the game already uses the idea of, and
  it makes a stick at the feet a little worse. Limbs still come off only point-blank.
- **Ground plus his front** makes your design's rule true ("dynamite at close range can take limbs":
  feet and shins within about a metre, lungs torn within 1.4 m). It makes a stick a much deadlier
  thing in a fight.
- The lung thresholds (250 / 700 kPa) were set against side-on pressure. With his front reflected
  they'd want raising, or blast lung would come on too easily.
- Either changes the structures and glass too if applied to all of `Blast`. People only is the
  smaller change.

Your call: leave it, ground only, or ground and front (people only, or everything).
