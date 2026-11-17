#!/usr/bin/env python3
"""Rebuild config/test_times.json (seconds per test file) from CI test logs (#1015).

tests/run_tests.gd --shard=K/N splits the test files over CI's parallel jobs by these weights,
longest first; a file missing from the table counts as 30 s. When the shards drift apart (one
"Run tests" step much longer than the others), refresh the table from a run's logs:

    python3 tools/test_times.py LOG [LOG ...]            # writes config/test_times.json
    python3 tools/test_times.py LOG ... --out=-          # print instead
    python3 tools/test_times.py LOG ... --check          # only show the shards it would make

Each LOG is one job's log (Actions -> a "test (K/N)" job -> the gear -> "View raw logs", saved),
one per shard: their files are merged. The runner prints `  time test_x.gd 12.3s` after each file
(since #1015), which is used when present; an older log (one job, no time lines) is timed from
the Actions timestamps on each `  ok   test_x::method` line instead.
"""
import argparse
import datetime
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_OUT = os.path.join(ROOT, "config", "test_times.json")
MISSING = 30.0  # the runner's weight for a file not in the table

TIME_LINE = re.compile(r"\s{2}time (test_\w+\.gd) ([0-9.]+)s\s*$")
STAMP = re.compile(r"^(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?)Z ")
RESULT = re.compile(r"\s{2}(?:ok  |FAIL) (test_\w+)::")


def _stamp(line):
    m = STAMP.match(line)
    if not m:
        return None
    s = m.group(1)
    if "." in s:  # Actions writes 7 decimals; Python takes 6
        head, frac = s.split(".")
        s = "%s.%s" % (head, frac[:6])
    return datetime.datetime.fromisoformat(s)


def times_from_log(text):
    """{file: seconds} from one log: its time lines, or else its timestamps."""
    out = {}
    for line in text.splitlines():
        m = TIME_LINE.search(line)
        if m:
            out[m.group(1)] = float(m.group(2))
    if out:
        return out
    # An old log: a file's time runs from the previous file's last result to its own last.
    start = None
    last = {}  # file -> (stamp of its last result line)
    order = []
    for line in text.splitlines():
        t = _stamp(line)
        if t is None:
            continue
        if start is None and "run_tests.gd" in line:
            start = t
        m = RESULT.search(line)
        if m:
            f = m.group(1) + ".gd"
            if f not in last:
                order.append(f)
            last[f] = t
    prev = start
    for f in order:
        if prev is None:
            prev = last[f]
        out[f] = max(0.0, (last[f] - prev).total_seconds())
        prev = last[f]
    return out


def shards(times, files, n):
    """The runner's split (tests/run_tests.gd shard_files), for --check: longest first, each
    to the lightest shard (the lowest number on a tie)."""
    order = sorted(files, key=lambda f: (-times.get(f, MISSING), f))
    load = [0.0] * n
    which = [[] for _ in range(n)]
    for f in order:
        k = min(range(n), key=lambda i: (load[i], i))
        load[k] += times.get(f, MISSING)
        which[k].append(f)
    return load, which


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("logs", nargs="+")
    ap.add_argument("--out", default=DEFAULT_OUT)
    ap.add_argument("--check", action="store_true", help="print the shards, write nothing")
    ap.add_argument("--shards", type=int, default=6)
    a = ap.parse_args()

    times = {}
    for path in a.logs:
        with open(path, encoding="utf-8", errors="replace") as fh:
            got = times_from_log(fh.read())
        if not got:
            sys.exit("%s: no test results found" % path)
        times.update(got)

    files = sorted(f for f in os.listdir(os.path.join(ROOT, "tests"))
                   if f.startswith("test_") and f.endswith(".gd") and f != "test_case.gd")
    gone = sorted(set(times) - set(files))
    for f in gone:  # a file since deleted or renamed
        del times[f]
    missing = sorted(set(files) - set(times))

    load, _ = shards(times, files, a.shards)
    print("%d files timed, %.0f s in all; %d not in the logs (30 s each)%s; %d dropped"
          % (len(times), sum(times.values()), len(missing),
             (": " + ", ".join(missing[:8]) + (" ..." if len(missing) > 8 else "")) if missing else "",
             len(gone)))
    print("%d shards: %s s" % (a.shards, ", ".join("%.0f" % x for x in load)))
    if a.check:
        return
    table = {f: round(times[f], 1) for f in sorted(times)}
    text = json.dumps(table, indent=1, sort_keys=True) + "\n"
    if a.out == "-":
        sys.stdout.write(text)
    else:
        with open(a.out, "w", encoding="utf-8") as fh:
            fh.write(text)
        print("wrote", os.path.relpath(a.out, ROOT))


if __name__ == "__main__":
    main()
