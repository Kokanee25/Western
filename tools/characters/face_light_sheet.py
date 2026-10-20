"""The head's sheet in three lights (head_neck.py's tries): his portrait | each man, in art_lab's
neutral light, the warm light made to his portraits and the saloon at night, front, three-quarter
and side.

    python3 tools/characters/face_light_sheet.py --out=SHEET.jpg --title="..." \\
        --men="Today:build/fl_today,Try A:build/fl_a" [--notes="line|line"] [--saloon=x0:y0:x1:y1]

Each man's folder is tools/characters/face_light_renders.sh's (lab/, saloon_<turn>/).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import two_tests_sheet as TS  # noqa: E402

PORTRAIT = "docs/concept/style/portrait-cowboy-%s.png@0.2:0:0.8:1"
TURNS = (("front", "0", "front"), ("3/4", "-45", "three-quarter"), ("side", "80", "profile-right"))
LAB_CROP = "0.38:0.12:0.62:0.72"


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    men = [m.split(":", 1) for m in a["--men"].split(",")]
    saloon = a.get("--saloon", "0.455:0.36:0.545:0.56")
    rows, cells = [], []
    for light in ("neutral", "warm", "saloon"):
        for label, turn, portrait in TURNS:
            rows.append("%s, %s" % (light, label))
            row = [PORTRAIT % portrait]
            for _name, d in men:
                if light == "saloon":
                    row.append(os.path.join(d, "saloon_%s" % turn, "man_saloon_night_x3.png") + "@" + saloon)
                else:
                    row.append(os.path.join(d, "lab", "game_%s_%s.png" % (light, turn)) + "@" + LAB_CROP)
            cells.append(row)
    notes = a["--notes"].split("|") if a.get("--notes") else []
    TS.sheet(a["--out"], a.get("--title", ""), ["His portrait"] + [n for n, _d in men], rows, cells, notes,
             int(a.get("--width", 1600)))


if __name__ == "__main__":
    main()
