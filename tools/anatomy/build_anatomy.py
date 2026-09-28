#!/usr/bin/env python3
"""Writes config/anatomy.json: the hidden anatomy of an adult man (1.78 m).

Rest pose: standing, facing -Z, feet at the origin, his right is +X, arms hanging with the palms
in and thumbs forward. Units are metres. Run from the repo root:

    python3 tools/anatomy/build_anatomy.py

Segments are the parts that move as one (hitboxes; they come apart at the joints). Each has one or
more capsules [a, b, radius]; the first is its main axis. Structures are what's inside:

  bone    strength = joules to break it (less and the ball stops against it); shell = hollow
          thickness (skull, ribcage), cage = chance a path through the cage meets a rib;
          spine = which part of the spine (the vertebrae; the cord inside is a nerve)
  artery  bleed = ml/s when cut, untreated; limb = a tourniquet above it can stop it
  vein    as artery, dark steady flow instead of a pulsing jet
  organ   organ = what it is (brain, heart, lung, liver, gut, kidney, airway, eye, ...)
  muscle  what the limb can do: group = leg / arm / grip; a ball tears about half of one
  nerve   cord = spinal cord section (paralysis below it); otherwise what stops working
  finger  three bones each; hit one and it comes off
"""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "config", "anatomy.json")

segments = {}
structures = []


def seg(name, parent, *capsules):
    segments[name] = {"capsules": [list(c) for c in capsules], "parent": parent}


def cap(sid, kind, segment, a, b, r, **props):
    d = {"id": sid, "kind": kind, "segment": segment, "capsule": [a, b, r]}
    d.update(props)
    structures.append(d)


def sph(sid, kind, segment, c, r, **props):
    d = {"id": sid, "kind": kind, "segment": segment, "sphere": [c, r]}
    d.update(props)
    structures.append(d)


def m(p, sx):
    """Mirror a right-side point to the given side (+1 right, -1 left)."""
    return [p[0] * sx, p[1], p[2]]


# --- Segments (hitboxes) -----------------------------------------------------------------------
seg("pelvis", "", [[-0.07, 0.9, 0.0], [0.07, 0.9, 0.0], 0.14])
seg("abdomen", "pelvis", [[0.0, 1.0, 0.0], [0.0, 1.16, 0.0], 0.13],
    [[0.05, 1.0, 0.0], [0.05, 1.16, 0.0], 0.12], [[-0.05, 1.0, 0.0], [-0.05, 1.16, 0.0], 0.12])
# The chest is wider than deep; the shoulders slope down from the neck.
seg("chest", "abdomen", [[0.0, 1.19, 0.0], [0.0, 1.37, 0.0], 0.13],
    [[0.07, 1.19, 0.0], [0.07, 1.33, 0.0], 0.13], [[-0.07, 1.19, 0.0], [-0.07, 1.33, 0.0], 0.13])
seg("neck", "chest", [[0.0, 1.47, 0.005], [0.0, 1.56, 0.0], 0.06])
seg("head", "neck", [[0.0, 1.61, 0.0], [0.0, 1.7, -0.005], 0.095])
for side, sx in (("r", 1), ("l", -1)):
    seg(f"upper_arm_{side}", "chest", [m([0.2, 1.43, 0.0], sx), m([0.225, 1.13, 0.0], sx), 0.052])
    seg(f"forearm_{side}", f"upper_arm_{side}", [m([0.225, 1.12, 0.0], sx), m([0.235, 0.87, -0.01], sx), 0.043])
    seg(f"hand_{side}", f"forearm_{side}", [m([0.235, 0.86, -0.01], sx), m([0.24, 0.72, -0.02], sx), 0.035])
    seg(f"thigh_{side}", "pelvis", [m([0.095, 0.9, 0.0], sx), m([0.1, 0.49, 0.0], sx), 0.078])
    seg(f"shin_{side}", f"thigh_{side}", [m([0.1, 0.48, 0.0], sx), m([0.1, 0.09, 0.01], sx), 0.055])
    seg(f"foot_{side}", f"shin_{side}", [m([0.1, 0.05, 0.05], sx), m([0.1, 0.05, -0.15], sx), 0.042])

# --- Head and neck -----------------------------------------------------------------------------
sph("skull", "bone", "head", [0, 1.64, -0.005], 0.09, strength=150, shell=0.007)
sph("brain", "organ", "head", [0, 1.645, -0.01], 0.075, bleed=0.5, organ="brain")
for side, sx in (("r", 1), ("l", -1)):
    sph(f"eye_{side}", "organ", "head", m([0.033, 1.655, -0.083], sx), 0.013, bleed=0.2, organ="eye")
cap("jaw", "bone", "head", [-0.042, 1.565, -0.055], [0.042, 1.565, -0.055], 0.018, strength=70)
cap("cervical_spine", "bone", "neck", [0, 1.46, 0.035], [0, 1.57, 0.03], 0.018, strength=90, spine="cervical")
cap("cord_cervical", "nerve", "neck", [0, 1.46, 0.035], [0, 1.57, 0.03], 0.007, cord="cervical")
cap("trachea", "organ", "neck", [0, 1.46, -0.035], [0, 1.57, -0.03], 0.012, bleed=0.5, organ="airway")
cap("esophagus", "organ", "neck", [0, 1.46, 0.0], [0, 1.56, 0.0], 0.009, bleed=0.3, organ="gullet")
for side, sx in (("r", 1), ("l", -1)):
    cap(f"carotid_{side}", "artery", "neck", m([0.03, 1.46, -0.02], sx), m([0.03, 1.58, -0.02], sx), 0.009, bleed=18.0)
    cap(f"jugular_{side}", "vein", "neck", m([0.043, 1.46, -0.004], sx), m([0.043, 1.58, -0.006], sx), 0.009, bleed=10.0)

# --- Chest ---------------------------------------------------------------------------------------
cap("thoracic_spine", "bone", "chest", [0, 1.18, 0.1], [0, 1.43, 0.08], 0.022, strength=110, spine="thoracic")
cap("cord_thoracic", "nerve", "chest", [0, 1.18, 0.1], [0, 1.43, 0.08], 0.007, cord="thoracic")
cap("sternum", "bone", "chest", [0, 1.24, -0.113], [0, 1.40, -0.11], 0.012, strength=60)
cap("aorta", "artery", "chest", [-0.01, 1.18, 0.05], [-0.01, 1.36, 0.03], 0.012, bleed=90.0)
cap("vena_cava", "vein", "chest", [0.02, 1.18, 0.03], [0.02, 1.33, 0.0], 0.012, bleed=40.0)
sph("heart", "organ", "chest", [-0.03, 1.29, -0.035], 0.055, bleed=110.0, organ="heart")
for side, sx in (("r", 1), ("l", -1)):
    cap(f"ribs_{side}", "bone", "chest", m([0.065, 1.17, 0.0], sx), m([0.065, 1.42, 0.0], sx), 0.12,
        strength=45, shell=0.012, cage=0.32)
    cap(f"lung_{side}", "organ", "chest", m([0.08, 1.2, 0.0], sx), m([0.08, 1.38, 0.0], sx), 0.065, bleed=0.6, organ="lung")
    cap(f"clavicle_{side}", "bone", "chest", m([0.02, 1.43, -0.05], sx), m([0.15, 1.43, -0.02], sx), 0.01, strength=60)
    cap(f"scapula_{side}", "bone", "chest", m([0.09, 1.26, 0.105], sx), m([0.13, 1.38, 0.095], sx), 0.012, strength=60)
    cap(f"subclavian_{side}", "artery", "chest", m([0.05, 1.42, -0.03], sx), m([0.18, 1.40, -0.01], sx), 0.009, bleed=14.0)
    cap(f"subclavian_vein_{side}", "vein", "chest", m([0.05, 1.41, -0.045], sx), m([0.17, 1.39, -0.025], sx), 0.009, bleed=8.0)

# --- Abdomen and pelvis --------------------------------------------------------------------------
cap("abdominal_aorta", "artery", "abdomen", [-0.01, 0.98, 0.055], [-0.01, 1.17, 0.05], 0.011, bleed=80.0)
cap("abdominal_vena_cava", "vein", "abdomen", [0.02, 1.0, 0.045], [0.02, 1.17, 0.03], 0.012, bleed=35.0)
cap("lumbar_spine", "bone", "abdomen", [0, 0.95, 0.085], [0, 1.18, 0.1], 0.024, strength=130, spine="lumbar")
cap("cord_lumbar", "nerve", "abdomen", [0, 1.05, 0.09], [0, 1.18, 0.1], 0.007, cord="lumbar")
sph("liver", "organ", "abdomen", [0.065, 1.12, -0.02], 0.07, bleed=3.0, organ="liver")
sph("spleen", "organ", "abdomen", [-0.08, 1.12, 0.04], 0.035, bleed=2.0, organ="spleen")
sph("stomach", "organ", "abdomen", [-0.055, 1.12, -0.04], 0.05, bleed=0.3, organ="gut")
cap("small_intestine", "organ", "abdomen", [0, 0.98, -0.03], [0, 1.06, -0.03], 0.085, bleed=0.2, organ="gut")
cap("large_intestine", "organ", "abdomen", [-0.1, 0.99, 0.0], [0.1, 0.99, 0.0], 0.035, bleed=0.2, organ="gut")
for side, sx in (("r", 1), ("l", -1)):
    sph(f"kidney_{side}", "organ", "abdomen", m([0.06, 1.06, 0.065], sx), 0.032, bleed=1.2, organ="kidney")
cap("pelvis_bone", "bone", "pelvis", [-0.12, 0.93, 0.02], [0.12, 0.93, 0.02], 0.05, strength=220)
sph("sacrum", "bone", "pelvis", [0, 0.9, 0.085], 0.035, strength=150)
sph("bladder", "organ", "pelvis", [0, 0.85, -0.05], 0.04, bleed=0.3, organ="gut")
for side, sx in (("r", 1), ("l", -1)):
    cap(f"iliac_{side}", "artery", "pelvis", m([0.03, 0.99, 0.03], sx), m([0.07, 0.86, -0.03], sx), 0.008, bleed=15.0)
    sph(f"gluteus_{side}", "muscle", "pelvis", m([0.08, 0.85, 0.08], sx), 0.07, group="leg")

# --- Arms --------------------------------------------------------------------------------------
names = ["thumb", "index", "middle", "ring", "little"]
for side, sx in (("r", 1), ("l", -1)):
    ua, fa, hd = f"upper_arm_{side}", f"forearm_{side}", f"hand_{side}"
    cap(f"humerus_{side}", "bone", ua, m([0.2, 1.41, 0.0], sx), m([0.225, 1.14, 0.0], sx), 0.013, strength=150)
    cap(f"deltoid_{side}", "muscle", ua, m([0.2, 1.43, 0.0], sx), m([0.212, 1.32, 0.0], sx), 0.042, group="arm")
    cap(f"biceps_{side}", "muscle", ua, m([0.208, 1.35, -0.026], sx), m([0.222, 1.16, -0.026], sx), 0.026, group="arm")
    cap(f"triceps_{side}", "muscle", ua, m([0.208, 1.35, 0.026], sx), m([0.222, 1.16, 0.026], sx), 0.026, group="arm")
    cap(f"axillary_{side}", "artery", ua, m([0.175, 1.41, -0.01], sx), m([0.19, 1.34, -0.012], sx), 0.008, bleed=10.0)
    cap(f"brachial_{side}", "artery", ua, m([0.19, 1.34, -0.015], sx), m([0.215, 1.13, -0.02], sx), 0.007, bleed=7.0, limb=True)
    cap(f"radial_nerve_{side}", "nerve", ua, m([0.214, 1.32, 0.02], sx), m([0.226, 1.15, 0.012], sx), 0.005, disables="grip")
    cap(f"radius_{side}", "bone", fa, m([0.225, 1.10, -0.012], sx), m([0.235, 0.89, -0.022], sx), 0.01, strength=70)
    cap(f"ulna_{side}", "bone", fa, m([0.225, 1.10, 0.012], sx), m([0.235, 0.89, 0.0], sx), 0.01, strength=70)
    cap(f"forearm_flexors_{side}", "muscle", fa, m([0.212, 1.09, 0.0], sx), m([0.226, 0.92, -0.01], sx), 0.024, group="grip")
    cap(f"forearm_extensors_{side}", "muscle", fa, m([0.24, 1.09, 0.0], sx), m([0.246, 0.92, -0.01], sx), 0.02, group="grip")
    cap(f"median_nerve_{side}", "nerve", fa, m([0.212, 1.09, -0.005], sx), m([0.226, 0.9, -0.015], sx), 0.004, disables="grip")
    cap(f"radial_{side}", "artery", fa, m([0.215, 1.10, -0.02], sx), m([0.23, 0.89, -0.03], sx), 0.005, bleed=3.0, limb=True)
    cap(f"ulnar_{side}", "artery", fa, m([0.215, 1.10, 0.012], sx), m([0.23, 0.89, 0.004], sx), 0.005, bleed=2.5, limb=True)
    cap(f"hand_bones_{side}", "bone", hd, m([0.235, 0.855, -0.01], sx), m([0.24, 0.775, -0.012], sx), 0.02, strength=40)
    x = 0.24 * sx
    for i, n in enumerate(names):
        if n == "thumb":
            a, b = m([0.235, 0.835, -0.038], sx), m([0.235, 0.775, -0.048], sx)
        else:
            z = [-0.027, -0.009, 0.009, 0.026][i - 1]
            top, length = 0.775, [0.078, 0.086, 0.08, 0.064][i - 1]
            a, b = [x, top, z - 0.01], [x, top - length, z - 0.02]
        cap(f"{n}_{side}", "finger", hd, a, b, 0.009, strength=8, bleed=0.4)

# --- Legs --------------------------------------------------------------------------------------
for side, sx in (("r", 1), ("l", -1)):
    th, sh, ft = f"thigh_{side}", f"shin_{side}", f"foot_{side}"
    cap(f"femur_{side}", "bone", th, m([0.095, 0.88, 0.0], sx), m([0.1, 0.5, 0.005], sx), 0.017, strength=240)
    cap(f"quadriceps_{side}", "muscle", th, m([0.1, 0.84, -0.032], sx), m([0.1, 0.53, -0.03], sx), 0.042, group="leg")
    cap(f"hamstrings_{side}", "muscle", th, m([0.1, 0.84, 0.035], sx), m([0.1, 0.53, 0.032], sx), 0.038, group="leg")
    cap(f"femoral_{side}", "artery", th, m([0.07, 0.88, -0.035], sx), m([0.085, 0.56, -0.02], sx), 0.009, bleed=12.0, limb=True)
    cap(f"femoral_vein_{side}", "vein", th, m([0.058, 0.88, -0.026], sx), m([0.078, 0.56, -0.012], sx), 0.009, bleed=6.0, limb=True)
    cap(f"sciatic_{side}", "nerve", th, m([0.095, 0.86, 0.045], sx), m([0.1, 0.52, 0.04], sx), 0.006, disables="leg")
    sph(f"patella_{side}", "bone", sh, m([0.1, 0.49, -0.05], sx), 0.02, strength=60)
    cap(f"tibia_{side}", "bone", sh, m([0.1, 0.47, -0.015], sx), m([0.1, 0.1, 0.0], sx), 0.014, strength=170)
    cap(f"fibula_{side}", "bone", sh, m([0.125, 0.46, 0.01], sx), m([0.12, 0.1, 0.012], sx), 0.008, strength=50)
    cap(f"calf_{side}", "muscle", sh, m([0.1, 0.43, 0.03], sx), m([0.1, 0.22, 0.026], sx), 0.034, group="leg")
    cap(f"popliteal_{side}", "artery", sh, m([0.095, 0.52, 0.035], sx), m([0.1, 0.42, 0.03], sx), 0.007, bleed=6.0, limb=True)
    cap(f"tibial_artery_{side}", "artery", sh, m([0.097, 0.41, 0.022], sx), m([0.1, 0.12, 0.016], sx), 0.005, bleed=3.0, limb=True)
    cap(f"foot_bones_{side}", "bone", ft, m([0.1, 0.05, 0.03], sx), m([0.1, 0.05, -0.12], sx), 0.02, strength=60)

readme = __doc__.split("\n\n", 1)[1].strip()
data = {
    "_readme": "Generated by tools/anatomy/build_anatomy.py; edit that, not this. " + " ".join(readme.split()),
    "height": 1.78,
    "flesh_resistance": 13.0,
    "segments": segments,
    "structures": structures,
}
with open(OUT, "w") as f:
    json.dump(data, f, indent=1)
    f.write("\n")
print(f"{len(segments)} segments, {len(structures)} structures -> {os.path.relpath(OUT, ROOT)}")
