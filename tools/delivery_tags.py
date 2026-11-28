#!/usr/bin/env python3
"""The town script's lines given their delivery tag (#1316): each line's free-text `delivery` note read
by config/delivery.json's `notes` (the first phrase found at a word's start wins; Delivery.tag_of_note
in the game reads it the same way), written as `"tag"` (and `"strength"` under 1) after the note. A line
that has a tag already keeps it (a tag set by hand wins); a calm line gets none (no tag is calm).

    python3 tools/delivery_tags.py [--check]

Writes docs/scripts/town.json and its game copy config/town_script.json (kept identical). --check
only says how many lines would change and exits 1 if any would.
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(ROOT, "docs", "scripts", "town.json")
COPY = os.path.join(ROOT, "config", "town_script.json")
DATA = os.path.join(ROOT, "config", "delivery.json")


def tag_of(note, notes):
    low = note.lower()
    for n in notes:
        for m in re.finditer(re.escape(n[0]), low):
            if m.start() == 0 or not low[m.start() - 1].isalpha():
                return n[1], float(n[2]) if len(n) > 2 else 1.0
    return "calm", 1.0


def main():
    notes = json.load(open(DATA))["notes"]
    text = open(SCRIPT, encoding="utf-8").read()
    d = json.loads(text)
    want = {}
    for s in d["scenes"]:
        for l in s["lines"]:
            if "tag" in l:
                continue
            t, k = tag_of(l.get("delivery", ""), notes)
            if t != "calm":
                want[l["id"]] = (t, k)
    if "--check" in sys.argv:
        print("%d lines would get a tag" % len(want))
        sys.exit(1 if want else 0)
    out = []
    cur = None
    for line in text.split("\n"):
        out.append(line)
        m = re.match(r'^(\s*)"id": "([^"]+)",$', line)
        if m:
            cur = m.group(2)
        m = re.match(r'^(\s*)"delivery": .*,$', line)
        if m and cur in want:
            t, k = want.pop(cur)
            out.append('%s"tag": "%s",' % (m.group(1), t))
            if k < 1.0:
                out.append('%s"strength": %s,' % (m.group(1), ("%.2f" % k).rstrip("0").rstrip(".")))
    new = "\n".join(out)
    json.loads(new)  # still JSON
    open(SCRIPT, "w", encoding="utf-8").write(new)
    open(COPY, "w", encoding="utf-8").write(new)
    d2 = json.loads(new)
    from collections import Counter
    c = Counter(l.get("tag", "calm") for s in d2["scenes"] for l in s["lines"])
    print("tags:", dict(c.most_common()), "left unplaced:", len(want))


if __name__ == "__main__":
    main()
