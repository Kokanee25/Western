# One limb off no longer cracks every joint (fix 2)

**Before:** `sever_limb` called `_stop_skinning_across_joints()`, which swapped *every* piece of
him to its rigid mesh. That was so nothing would stretch across the lost joint, but it also stopped
his shoulders, neck and waist bending with the ragdoll. As he lay, every seam opened. The check's
pictures showed a pointed flap of shoulder standing up by his head, a gap at the neck, and ragged
edges round the vest's waist. All four men had it; the studio men were worst, because their clothes
are their skin.

**The fix:** only the lost limb's pieces (the part and everything below it) and the stump's own
piece go rigid. The rest of him stays skinned across his joints.

**Measured:** `before_after.jpg`, from the lab's `check` (`stumps`) on the drifter (top) and the
cowboy (bottom); left before, right after. The flap and the neck gap are gone and the vest is whole.
The stumps and the limb's cut end are unchanged: an open rim filled by the wound's insides (the
check's open-edge numbers are the same: drifter 46 / 49 cm, cowboy 48 / 53, rancher 28 / 22,
outlaw 94 / 63). None of the 160 shot and blast runs changed.

Also in this change: `lab.gd` refuses a `--model` whose `.glb` isn't there or isn't imported. It
used to fall back to the default body without a word, which is how a run after a fresh checkout,
before `godot --headless --import`, measured the wrong man.
