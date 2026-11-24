#!/usr/bin/env python3
"""Which test files a change needs (#1234): CI's pull requests run these, main runs them all.

A PR's run is the core set (config/test_map.json "core": boot, the valley, a save, a mission's
start) plus the tests mapped from the files the PR changes against main, sharded by
config/test_times.json. Main runs the whole suite after every merge, as before.

Each changed file is looked up three ways (their union is the selection):
  1. config/test_map.json's rules: path globs ("except": globs it leaves to other rules) ->
     test-file globs ("@group" names a group; "all" runs everything; [] runs nothing). `**` is any path, `*` any name, `{x}` captures a name
     that the rule's tests can use (config/buildings/{b}.json -> test_building_{b}*).
  2. A test file that names it: its `res://` path, or its class_name as a word.
  3. A changed test file is run itself.
A changed file no rule matches runs everything (and says so): new kinds of file are safe until
someone maps them.

Merging main in (--since=SHA, the PR's last green run's commit): what that push changed in the
PR's own files is selected as above; main's files only bring the PR's tests they share. A merge
whose clashes were only in docs then runs the core set alone.

    python3 tools/test_select.py --base=origin/main [--head=HEAD] [--since=SHA]   # the selection
    python3 tools/test_select.py ... --github         # writes GITHUB_OUTPUT and the step summary
    python3 tools/test_select.py --files=src/people/senses.gd,docs/x.md          # given files
    python3 tools/test_select.py --replay=20          # main's last 20 merges through the map
    python3 tools/test_select.py --check              # every pattern matches, every test reachable
"""
import argparse
import fnmatch
import json
import math
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAP_PATH = os.path.join(ROOT, "config", "test_map.json")
TIMES_PATH = os.path.join(ROOT, "config", "test_times.json")
MISSING = 30.0  # the runner's weight for a file not in the times table
ALL = "all"
# A shard's wall time on CI, roughly: its seconds by the table times CI_SCALE (measured 1.3-1.85,
# run 45419255133, six shards), plus SETUP_MIN (checkout, plugin, import: ~4 min).
CI_SCALE = 1.5
SETUP_MIN = 4.0


def git(*args, check=True):
    r = subprocess.run(["git", "-C", ROOT, *args], capture_output=True, text=True)
    if check and r.returncode != 0:
        raise RuntimeError("git %s: %s" % (" ".join(args), r.stderr.strip()))
    return r.stdout if r.returncode == 0 else None


def changed_files(a, b, three_dot=True):
    out = git("diff", "--name-only", "--no-renames", ("%s...%s" if three_dot else "%s..%s") % (a, b))
    return [f for f in out.splitlines() if f]


def all_tests():
    d = os.path.join(ROOT, "tests")
    return sorted(f for f in os.listdir(d)
                  if f.startswith("test_") and f.endswith(".gd") and f != "test_case.gd")


def load_json(path):
    with open(path) as fh:
        return json.load(fh)


def _glob_regex(pattern):
    """A path glob as a regex: ** any path, * a name's part, {x} a captured name part."""
    out = ""
    i = 0
    while i < len(pattern):
        if pattern.startswith("**/", i):
            out += "(?:.*/)?"
            i += 3
        elif pattern.startswith("**", i):
            out += ".*"
            i += 2
        elif pattern[i] == "*":
            out += "[^/]*"
            i += 1
        elif pattern[i] == "{":
            j = pattern.index("}", i)
            out += "(?P<%s>[^/]+?)" % pattern[i + 1:j]
            i = j + 1
        else:
            out += re.escape(pattern[i])
            i += 1
    return re.compile(out + r"\Z")


class Selector:
    def __init__(self, test_map=None, tests=None, times=None):
        self.map = test_map if test_map is not None else load_json(MAP_PATH)
        self.tests = tests if tests is not None else all_tests()
        self.times = times if times is not None else (load_json(TIMES_PATH) if os.path.exists(TIMES_PATH) else {})
        self.groups = self.map.get("groups", {})
        self.rules = [(r, [_glob_regex(p) for p in r["paths"]], [_glob_regex(p) for p in r.get("except", [])])
                      for r in self.map["rules"]]
        self._texts = None
        self._classes = None

    # -- the tests' own text, for "a test that names it" --
    def _test_texts(self):
        if self._texts is None:
            self._texts = {}
            for t in self.tests:
                with open(os.path.join(ROOT, "tests", t), encoding="utf-8", errors="replace") as fh:
                    self._texts[t] = fh.read()
        return self._texts

    def expand(self, patterns, caps=None, seen=()):
        """Test-file patterns (globs, @groups) -> the set of test files."""
        out = set()
        for p in patterns:
            if caps:
                for k, v in caps.items():
                    p = p.replace("{%s}" % k, v)
            if p.startswith("@"):
                name = p[1:]
                if name in seen:
                    continue
                out |= self.expand(self.groups[name], caps, seen + (name,))
            else:
                out |= {t for t in self.tests if fnmatch.fnmatchcase(t, p)}
        return out

    def _class_name(self, path):
        if not path.endswith(".gd"):
            return None
        full = os.path.join(ROOT, path)
        text = None
        if os.path.exists(full):
            with open(full, encoding="utf-8", errors="replace") as fh:
                text = fh.read(4000)
        m = re.search(r"^class_name\s+(\w+)", text or "", re.M)
        return m.group(1) if m else None

    def naming_tests(self, path):
        """Test files that name `path` (its res:// path or its class_name)."""
        src = re.sub(r"\.(uid|import)$", "", path)
        res = "res://" + src
        cls = self._class_name(src)
        word = re.compile(r"\b%s\b" % re.escape(cls)) if cls else None
        return {t for t, text in self._test_texts().items()
                if res in text or (word is not None and word.search(text))}

    def for_file(self, path):
        """(tests or ALL, why) for one changed file."""
        src = re.sub(r"\.(uid|import)$", "", path)
        if src.startswith("tests/") and src.count("/") == 1 \
                and fnmatch.fnmatchcase(os.path.basename(src), "test_*.gd") and os.path.basename(src) != "test_case.gd":
            name = os.path.basename(src)
            return ({name}, "itself") if name in self.tests else (set(), "a test removed")
        out = set()
        matched = []
        for rule, regs, excepts in self.rules:
            if any(x.match(path) for x in excepts):
                continue
            for rx in regs:
                m = rx.match(path)
                if not m:
                    continue
                matched.append(rule.get("name", rule["paths"][0]))
                if rule["tests"] == ALL:
                    return ALL, "rule %s" % matched[-1]
                out |= self.expand(rule["tests"], m.groupdict())
                break
        if not matched:
            return ALL, "unmapped"
        named = self.naming_tests(path)
        why = "rule " + ", ".join(dict.fromkeys(matched))
        if named - out:
            why += " + named by %d test(s)" % len(named - out)
        return out | named, why

    def for_files(self, paths):
        """(tests or ALL, {path: (tests, why)})."""
        out = set()
        each = {}
        everything = False
        for p in paths:
            tests, why = self.for_file(p)
            each[p] = (tests, why)
            if tests == ALL:
                everything = True
            else:
                out |= tests
        return (ALL if everything else out), each

    def core(self):
        return self.expand(self.map["core"])

    def seconds(self, tests):
        tests = self.tests if tests == ALL else tests
        return sum(float(self.times.get(t, MISSING)) for t in tests)

    def minutes(self, tests):
        """Roughly how long CI's slowest test job takes for this selection."""
        names = self.tests if tests == ALL else sorted(tests)
        n = self.shards(tests)
        loads = [0.0] * n
        for t in sorted(names, key=lambda f: (-float(self.times.get(f, MISSING)), f)):
            i = min(range(n), key=lambda k: (loads[k], k))
            loads[i] += float(self.times.get(t, MISSING))
        return SETUP_MIN + max(loads) * CI_SCALE / 60.0

    def shards(self, tests):
        """How many CI jobs: every job ~per_shard seconds of the table, at most max_shards."""
        if tests == ALL:
            return int(self.map.get("all_shards", 6))
        per = float(self.map.get("per_shard_seconds", 420))
        biggest = int(self.map.get("max_shards", 6))
        return max(1, min(biggest, math.ceil(self.seconds(tests) / per)))


def select(sel, base, head, since=None):
    """The PR's selection: (tests or ALL, report lines)."""
    pr = changed_files(base, head)
    lines = ["PR's files against main: %d" % len(pr)]
    if since and git("cat-file", "-e", since + "^{commit}", check=False) is not None:
        pushed = changed_files(since, head, three_dot=False)
        prs = set(pr)
        own = [f for f in pushed if f in prs]
        mains = [f for f in pushed if f not in prs]
        own_t, own_each = sel.for_files(own)
        main_t, _ = sel.for_files(mains)
        pr_t, _ = sel.for_files(pr)
        if pr_t == ALL:
            shared = main_t
        elif main_t == ALL:
            shared = pr_t
        else:
            shared = pr_t & main_t
        lines.append("since the last green run (%s): %d of the PR's files changed, %d of main's"
                     % (since[:10], len(own), len(mains)))
        if own_t == ALL or shared == ALL:
            tests = ALL
        else:
            tests = own_t | shared
        lines.append("the PR's tests main's files also touch: %s"
                     % ("all" if shared == ALL else len(shared)))
        each = own_each
    else:
        if since:
            lines.append("(the last run's commit %s isn't in this history: the PR's whole set)" % since[:10])
        tests, each = sel.for_files(pr)
    if tests != ALL:
        tests = tests | sel.core()
    return tests, each, lines


def report(sel, tests, each, lines):
    out = list(lines)
    n = "all %d" % len(sel.tests) if tests == ALL else "%d of %d" % (len(tests), len(sel.tests))
    out.append("tests: %s, ~%.0f s by the table, %d shard(s), ~%.0f min" % (
        n, sel.seconds(tests), sel.shards(tests), sel.minutes(tests)))
    for p, (t, why) in sorted(each.items()):
        out.append("  %s -> %s (%s)" % (p, "ALL" if t == ALL else len(t), why))
    return out


def replay(sel, count, ref="origin/main"):
    """Main's last `count` merges of a PR, each through the map as if its PR ran now."""
    log = git("log", "--first-parent", "--merges", "-n", str(count), "--format=%H %P|%s", ref)
    total_all = sel.seconds(ALL)
    rows = []
    for line in log.splitlines():
        head, subject = line.split("|", 1)
        parts = head.split()
        if len(parts) < 3:
            continue
        m, p1, p2 = parts[0], parts[1], parts[2]
        tests, each = sel.for_files(changed_files(p1, p2))
        if tests != ALL:
            tests = tests | sel.core()
        why_all = sorted({p for p, (t, _) in each.items() if t == ALL})
        pr = re.search(r"#(\d+)", subject)
        rows.append((pr.group(1) if pr else m[:8], len(each), tests, why_all))
    print("| PR | files | tests | table s | of all | shards | ~min | why all |")
    print("|---|---|---|---|---|---|---|---|")
    for pr, nfiles, tests, why_all in rows:
        s = sel.seconds(tests)
        print("| #%s | %d | %s | %.0f | %.0f%% | %d | %.0f | %s |" % (
            pr, nfiles, "all" if tests == ALL else len(tests), s, 100 * s / total_all,
            sel.shards(tests), sel.minutes(tests),
            ", ".join(why_all[:3]) + (" ..." if len(why_all) > 3 else "")))
    print("\nThe full suite: %.0f s by the table, %d shards, ~%.0f min." % (
        total_all, sel.shards(ALL), sel.minutes(ALL)))


def check(sel):
    """Every pattern in the map matches a test, every core file exists; lists tests no rule reaches."""
    bad = []
    for name, pats in sel.groups.items():
        for p in pats:
            if not p.startswith("@") and "{" not in p and not sel.expand([p]):
                bad.append("group %s: %s matches no test" % (name, p))
            if p.startswith("@") and p[1:] not in sel.groups:
                bad.append("group %s: no group %s" % (name, p))
    for rule in sel.map["rules"]:
        if rule["tests"] == ALL:
            continue
        for p in rule["tests"]:
            if p.startswith("@") and p[1:] not in sel.groups:
                bad.append("rule %s: no group %s" % (rule["paths"][0], p))
            elif not p.startswith("@") and "{" not in p and not sel.expand([p]):
                bad.append("rule %s: %s matches no test" % (rule["paths"][0], p))
    for p in sel.map["core"]:
        if not sel.expand([p]):
            bad.append("core: %s matches no test" % p)
    reached = set(sel.core())
    for rule in sel.map["rules"]:
        if rule["tests"] != ALL:
            reached |= sel.expand([p for p in rule["tests"] if "{" not in p])
    loose = [t for t in sel.tests if t not in reached]
    for b in bad:
        print("BAD  " + b)
    print("%d tests only run when changed themselves, named by a change, or in a full run: %s"
          % (len(loose), " ".join(loose)))
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--base", help="main (the PR's base): files are those changed since the merge base")
    ap.add_argument("--head", default="HEAD")
    ap.add_argument("--since", help="the PR's last green run's commit")
    ap.add_argument("--files", help="comma-separated paths instead of git")
    ap.add_argument("--all", action="store_true", help="select everything (main, by hand)")
    ap.add_argument("--github", action="store_true", help="write GITHUB_OUTPUT and the step summary")
    ap.add_argument("--replay", type=int)
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    sel = Selector()
    if a.check:
        return check(sel)
    if a.replay:
        replay(sel, a.replay)
        return 0
    if a.all:
        tests, each, lines = ALL, {}, ["everything (main, or asked for)"]
    elif a.files is not None:
        tests, each = sel.for_files([f for f in a.files.split(",") if f])
        if tests != ALL:
            tests |= sel.core()
        lines = []
    elif a.base:
        tests, each, lines = select(sel, a.base, a.head, a.since)
    else:
        ap.error("give --base, --files, --all, --replay or --check")
    text = report(sel, tests, each, lines)
    shards = sel.shards(tests)
    names = "" if tests == ALL else ",".join(sorted(tests))
    if a.github:
        with open(os.environ["GITHUB_OUTPUT"], "a") as fh:
            fh.write("all=%s\nfiles=%s\nshards=%d\n" % ("true" if tests == ALL else "false", names, shards))
        summary = os.environ.get("GITHUB_STEP_SUMMARY")
        if summary:
            with open(summary, "a") as fh:
                fh.write("### The tests this run needs (tools/test_select.py)\n\n```\n%s\n```\n" % "\n".join(text))
                if names:
                    fh.write("\n<details><summary>the files</summary>\n\n%s\n\n</details>\n" % names.replace(",", " "))
    print("\n".join(text))
    if names:
        print("files: " + names)
    return 0


if __name__ == "__main__":
    sys.exit(main())
