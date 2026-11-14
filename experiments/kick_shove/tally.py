#!/usr/bin/env python3
"""Tally the kick and shove lab (run.py): for each case, how often he goes down, where he ends
(metres back along the push, how far he dropped), what broke, and the push's numbers.

  python3 experiments/kick_shove/tally.py build/kick_shove/base [--md=FILE]

Writes <root>/tally.json and <root>/tally.md (or --md).
"""
import glob, json, os, statistics, sys


def main():
    root = sys.argv[1]
    md_out = next((a.split("=", 1)[1] for a in sys.argv[2:] if a.startswith("--md=")), os.path.join(root, "tally.md"))
    cases = {}
    for f in sorted(glob.glob(os.path.join(root, "seed_*", "*", "summary.json"))):
        s = json.load(open(f))
        p = s.get("push") or {}
        if not p:
            continue
        broke = [e["member"] for e in s.get("events", []) if e.get("kind") == "member_broken"]
        c = cases.setdefault(s["scenario"], [])
        end = p.get("end_local", [0, 0, 0])
        c.append({"down": p.get("went_down", False), "result": p.get("result"), "momentum": p.get("momentum", 0.0),
                  "his_speed": p.get("his_speed", 0.0), "catch": p.get("catch", 0.0), "joules": p.get("joules", 0.0),
                  "back": end[2], "drop": p.get("drop", 0.0), "broke": len(broke), "rail": sum(1 for b in broke if "rail" in b or "baluster" in b),
                  "up_again": p.get("went_down", False) and not p.get("down_at_end", True)})
    rows = []
    for name, runs in sorted(cases.items()):
        n = len(runs)
        med = lambda k: statistics.median([r[k] for r in runs])
        rows.append({"case": name, "n": n, "down": sum(r["down"] for r in runs), "up_again": sum(r["up_again"] for r in runs),
                     "momentum": med("momentum"), "his_speed": med("his_speed"), "catch": med("catch"), "joules": med("joules"),
                     "back_m": med("back"), "back_range": [min(r["back"] for r in runs), max(r["back"] for r in runs)],
                     "drop_m": med("drop"), "fell_far": sum(1 for r in runs if r["drop"] > 0.8),
                     "broke_any": sum(1 for r in runs if r["broke"] > 0), "broke_median": med("broke")})
    json.dump(rows, open(os.path.join(root, "tally.json"), "w"), indent=1)
    lines = ["| case | runs | down | up again | N*s | his m/s | catch m/s | blow J | back m (range) | drop m | fell > 0.8 m | broke (runs, median members) |",
             "|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for r in rows:
        lines.append("| %s | %d | %d | %d | %.0f | %.2f | %.2f | %.0f | %.2f (%.2f to %.2f) | %.2f | %d | %d, %g |" % (
            r["case"][2:], r["n"], r["down"], r["up_again"], r["momentum"], r["his_speed"], r["catch"], r["joules"],
            r["back_m"], r["back_range"][0], r["back_range"][1], r["drop_m"], r["fell_far"], r["broke_any"], r["broke_median"]))
    open(md_out, "w").write("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main()
