"""The whole man's face-and-neck sheet (head_neck.py's tries): his portrait | today's head | each try,
at the card table at night, plain front, three-quarter and side, the street at golden hour, and 2x
crops of his eyes, moustache, hair under the brim and neck (front, side).

    python3 tools/characters/face_neck_sheet.py --out=SHEET.png --title="..." \\
        --men="Today:build/fn_today,Try A:build/fn_a3" [--notes="line|line"]

Each man's folder is tools/characters/face_neck_renders.sh's (plain/, table/, near/).
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import two_tests_sheet as TS  # noqa: E402

PORTRAIT = "docs/concept/style/portrait-cowboy-%s.png"
# Rows: (label, the render in a man's folder @ crop as shares, his portrait @ crop).
ROWS = [
    ("card table, night", "table/shot_match_close_x3.png@0.36:0.10:0.66:0.65", PORTRAIT % "front" + "@0.22:0:0.78:1"),
    ("plain front", "plain/head_stand_front.png", PORTRAIT % "front" + "@0.2:0:0.8:1"),
    ("plain 3/4", "plain/head_stand_three_quarter.png", PORTRAIT % "three-quarter" + "@0.2:0:0.8:1"),
    ("plain side", "plain/head_stand_side.png", PORTRAIT % "profile-right" + "@0.2:0:0.8:1"),
    ("street, golden hour", "near/man_store_golden_x3.png@0.455:0.46:0.545:0.86", None),
    ("eyes (2x)", "plain/head_stand_front.png@0.28:0.34:0.72:0.50", PORTRAIT % "front" + "@0.36:0.24:0.66:0.42"),
    ("moustache (2x)", "plain/head_stand_front.png@0.32:0.46:0.68:0.64", PORTRAIT % "front" + "@0.38:0.48:0.64:0.72"),
    ("hair, brim (2x)", "plain/head_stand_three_quarter.png@0.22:0.26:0.58:0.56", PORTRAIT % "three-quarter" + "@0.28:0.15:0.56:0.6"),
    ("neck, front (2x)", "plain/head_stand_front.png@0.28:0.56:0.72:0.86", PORTRAIT % "front" + "@0.32:0.6:0.7:1"),
    ("neck, side (2x)", "plain/head_stand_side.png@0.34:0.52:0.80:0.86", PORTRAIT % "profile-right" + "@0.32:0.45:0.72:0.95"),
]


def main():
    a = dict(x.split("=", 1) for x in sys.argv[1:] if "=" in x)
    men = [m.split(":", 1) for m in a["--men"].split(",")]
    cols = ["His portrait"] + [name for name, _d in men]
    cells = []
    for _label, render, portrait in ROWS:
        row = [portrait or ""]
        for _name, d in men:
            path, _, crop = render.partition("@")
            row.append(os.path.join(d, path) + ("@" + crop if crop else ""))
        cells.append(row)
    notes = a["--notes"].split("|") if a.get("--notes") else []
    TS.sheet(a["--out"], a.get("--title", ""), cols, [r[0] for r in ROWS], cells, notes, int(a.get("--width", 1600)))


if __name__ == "__main__":
    main()
