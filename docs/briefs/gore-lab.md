# The gore lab: a huge variety of injuries

Sean, 2026-10-21: "this is strictly the gore lab - let's come up with a list of things we can add to
make a huge variety of injuries" ... "Everything else looks awesome so em all in whatever order you
want", all but the knock-out and the kill from a head hit (the ragdoll lab's).

Lane: gameplay (roadmap 3.1b, the body lab, `experiments/body_lab/`). The falls, getting knocked
down and dying's fall are the ragdoll lab's; this lab builds on what they leave (`_favour_step`, the
wound's consequence) rather than doing it again. Painted marks go through `tools/textures/paint_blood.py`
(Gemini, the gore test's pick) inside what's left of Sean's $3 ($1.38 on 2026-10-21).

## What done looks like

Each item below is in the game, has a test for its rule, shows in the body lab (a scenario or a
check), and doesn't appear with reduced gore where it's gore. Numbers come from the sources below,
not invented; where a source gives a range, the range is the tunable's (in `PhysiologyTuning` or a
constant with the source beside it).

## The list, in the order it's built

**A. What a ball does**
1. A ball that hits bone flattens (soft lead): it carries more of the bone and flesh after it and
   tears a bigger exit; one that hits hard bone can split, two tracks.
2. A ball that meets bone at a slant can skip off it and come out somewhere else.
3. It carries a plug of shirt in with it (the cloth it went through); left in, the wound goes bad.
4. Point blank: the gas tears the entry into a star, powder burns and tattoos the skin round it,
   scorches the cloth.

**B. What a wound does to him**
5. Nerves: a ball through the nerve to an arm leaves the hand limp (no grip; he drops what's in it).
6. The lung: pink froth at his mouth, a hole in the chest that sucks air, short of breath, slower.
7. The gut: he walks hunched (the falls' `_favour_step` bends him; this lab says how much the gut
   asks).
8. The spine: his legs go; he drags himself on his arms.
9. A scalp graze bleeds a lot, runs into his eyes, blinds that side.
10. The eye: a hand over it, blood down his cheek, he can't aim with it.
11. The jaw: broken, he slurs, spits blood (and teeth).
12. Fingers gone: he shoots worse, then with the other hand.
13. A knee or elbow shot: the joint locks straight or hangs; he limps or hops.
14. Inside a blast: eardrums burst (blood at the ears, deaf, dazed), blast lung (coughing blood
    with barely a mark on him).

**C. Blood and what comes out**
15. From the mouth after a chest or gut wound: coughed, and running when he lies down.
16. From the nose after a blow, from the ears after a blast or a head hit.
17. On his hands from the grab: handprints where he touches (walls, doors, the bar).
18. A drip trail behind a bleeding man, walking or crawling, that can be followed.
19. Smears where he drags himself, and down a wall a man slides down.
20. Blood drying: dark red to brown over game hours, so an old fight's marks look old.

**D. More kinds of wound**
21. Buckshot from further off: a scatter of small holes, pellets under the skin as lumps.
22. The knife: a cut that gapes along the muscle, a stab narrow outside and deep inside (the
    painted gash).
23. Glass: shards left standing in him.
24. Splinters: long wooden splinters from a blasted wall or a broken table, standing in him.
25. Burns: reddened, blistered, charred; cloth burnt onto him; hair singed (fire and a blast's flash).

**E. After**
26. Bandages: a wrapped wound bleeding through, a sling, a splint.
27. Infection: a wound left with cloth in it, or not cleaned, goes red and hot over the next days,
    then fever, then gangrene; the doctor matters.
28. Amputation: the doctor's saw takes a gangrened limb; a neat sewn stump, not a torn one.
29. Scars: healed wounds leave scars, kept in the save, on him for good.
30. Living on: an old leg wound leaves a limp; the one-armed man.

**F. Last moments**
31. How a wound ends him, short of the fall (the ragdoll lab's): bleeding out (pale, grey, slower,
    cold), shock, choking on his own blood, gasping, reaching, going still.
32. After: eyes open, the pool grows and stops, flies later.

## Sources (read the originals before a hard number rests on them)
- DiMaio VJM, *Gunshot Wounds* (CRC Press, 3rd ed. 2015): entry and exit, contact and near wounds
  (the star tear, soot and powder tattooing, black powder's wider range), deforming lead, bone.
- *The Medical and Surgical History of the War of the Rebellion* (1870–88): soft-lead conoidal and
  round balls (bone shattering, cloth carried in, infection, amputation, the gut's death).
- Fackler ML, "Wound ballistics: a review of common misconceptions", *JAMA* 259:2730 (1988):
  tissue disruption, deformation and fragmentation.
- DePalma RG et al., "Blast injuries", *NEJM* 352:1335 (2005): primary blast (eardrum, lung, gut),
  secondary (fragments), tertiary (thrown), quaternary (burns).
- ATLS (American College of Surgeons): open pneumothorax ("sucking chest wound"), haemorrhage classes.
- Bremmer RH et al., *PLoS ONE* 6(7):e21845 (2011): bloodstains' colour over time.
- Gray's Anatomy: the nerves of the arm (radial, median, ulnar), the limbs in section.

## How it's judged
- The body lab: every item has a scenario or a check, rendered close (`--render`) and in the
  baseline's numbers; before/after in `results/<date>_<item>/`.
- Sean plays it: what to try goes with each merge.
- The people budget: ten wounded men stay under 4 ms (`--perf --brains`).
