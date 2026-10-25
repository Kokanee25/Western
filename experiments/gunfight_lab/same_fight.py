#!/usr/bin/env python3
"""Did two runs of the gunfight lab play the same fights? The determinism check for the more-cores
work (docs/briefs/more-cores.md): the same seeds in RUN_A and RUN_B, each fight's record compared
event for event (its timeline, its ending, every man's shots and hits, your shots and hits), the
frame times left out.

    python3 experiments/gunfight_lab/same_fight.py RUN_A RUN_B [--tol=0.0] [--quiet]

RUN_A and RUN_B are run roots (with fights/*.json), or two single fight records. Exit 0 when every
fight paired by name is the same, 1 otherwise; prints the first divergence of each fight that
differs (the event in A, the event in B, and how far in). --tol=S lets an event's time differ by
up to S seconds (a build that changes the tick order a little but not the fight).
"""
import glob
import json
import os
import sys

IGNORED = {"perf", "track", "body_notes", "hour_at_start", "hour_at_end"}


def load(path):
    if os.path.isfile(path):
        with open(path) as fh:
            return {os.path.basename(path)[:-5]: json.load(fh)}
    out = {}
    for p in sorted(glob.glob(os.path.join(path, "fights", "*.json"))):
        with open(p) as fh:
            out[os.path.basename(p)[:-5]] = json.load(fh)
    return out


def opt(args, name, default=None):
    for a in args:
        if a.startswith("--%s=" % name):
            return a.split("=", 1)[1]
    return default


def men_summary(f):
    out = {}
    for mid, m in (f.get("men") or {}).items():
        out[mid] = {k: m.get(k) for k in ("shots", "hits_on_you", "hits_taken", "friendly_hits", "outcome", "out_at", "cover_changes", "peeks", "reloads")}
    return out


def first_divergence(a, b, tol):
    """The first timeline event that differs: (index, event_a, event_b), or None."""
    ta, tb = a.get("timeline") or [], b.get("timeline") or []
    for i, (ea, eb) in enumerate(zip(ta, tb)):
        same_t = abs(float(ea[0]) - float(eb[0])) <= tol
        if not (same_t and ea[1] == eb[1] and ea[2] == eb[2]):
            return i, ea, eb
    if len(ta) != len(tb):
        i = min(len(ta), len(tb))
        return i, (ta[i] if i < len(ta) else None), (tb[i] if i < len(tb) else None)
    return None


def compare(name, a, b, tol, quiet):
    diffs = []
    for key in ("ending", "end", "length_s", "first_shot_by", "first_hit_by", "outcomes"):
        if a.get(key) != b.get(key):
            diffs.append("%s: %r vs %r" % (key, a.get(key), b.get(key)))
    ya, yb = a.get("you") or {}, b.get("you") or {}
    for key in sorted(set(ya) | set(yb)):
        if ya.get(key) != yb.get(key):
            diffs.append("you.%s: %r vs %r" % (key, ya.get(key), yb.get(key)))
    ma, mb = men_summary(a), men_summary(b)
    for mid in sorted(set(ma) | set(mb)):
        for key in sorted(set(ma.get(mid, {})) | set(mb.get(mid, {}))):
            va, vb = ma.get(mid, {}).get(key), mb.get(mid, {}).get(key)
            if va != vb:
                diffs.append("%s.%s: %r vs %r" % (mid, key, va, vb))
    div = first_divergence(a, b, tol)
    same = not diffs and div is None
    if quiet:
        return same
    if same:
        print("SAME  %s  (%d events, %.1f s, %s)" % (name, len(a.get("timeline") or []), float(a.get("length_s", 0)), a.get("ending")))
        return True
    print("DIFF  %s" % name)
    for d in diffs[:12]:
        print("      %s" % d)
    if div is not None:
        i, ea, eb = div
        n = max(len(a.get("timeline") or []), 1)
        print("      first divergence at event %d of %d (%.0f%% in):" % (i, n, 100.0 * i / n))
        print("        A: %s" % (ea,))
        print("        B: %s" % (eb,))
    return False


def main(argv):
    paths = [a for a in argv if not a.startswith("--")]
    if len(paths) != 2 or "-h" in argv or "--help" in argv:
        print(__doc__)
        return 2
    tol = float(opt(argv, "tol", "0.0"))
    quiet = "--quiet" in argv
    a, b = load(paths[0]), load(paths[1])
    names = sorted(set(a) & set(b))
    if not names:
        print("no fights with the same name in both (%d in A, %d in B)" % (len(a), len(b)))
        return 2
    same = 0
    for name in names:
        if compare(name, a[name], b[name], tol, quiet):
            same += 1
    only = sorted((set(a) | set(b)) - set(names))
    print("%d of %d fights the same%s" % (same, len(names), ("; unpaired: " + ", ".join(only)) if only else ""))
    return 0 if same == len(names) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
