#!/usr/bin/env python3
"""The answers bench (#1272): each verb once on a fresh valley game in saloon B on an ordinary
evening, and what the people did about it. Usage:

    python3 experiments/answers/run.py [--only=shove,shot] [--out=experiments/answers/results/NAME]

Per verb: a fresh game (`tools/bridge.py start --headless --game-args=--world=valley`), the clock to
20:30, 25 s for the room to settle, the player set up, `ans_snap` before, the verb, `ans_watch 3`,
`ans_snap` after; then "later": 60 s in the room, a walk past each man in, and the clock run on
(scale 24 for 120 s: a game day is 2700 s at scale 1) with the player standing in the room; every line
said after the 3 s is kept, and those that speak of the verb (its `words`) count as a mention, as do
the barks log's ids naming it and a TownNews record told on (versions beyond those who saw it).
Writes `<out>/<verb>.json` and `<out>/table.md`.
"""
import json, os, re, subprocess, sys, time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
BRIDGE = [sys.executable, os.path.join(ROOT, "tools", "bridge.py")]

# Each verb: setup commands, the verb's commands (the watch starts after the last), words that
# would mean a line is about it.
VERBS = {
    "draw": (["goto 18.6 1.2 -17.4 90", "walk rancher", "look rancher chest"], ["weapon revolver"], r"gun|iron|pistol|\bdrew\b|put that"),
    "holster": (["goto 18.6 1.2 -17.4 90", "walk rancher", "look rancher chest", "weapon revolver", "wait 15"], ["weapon none"],
                r"gun|iron|holster|put (it|that) away"),
    "shove": (["goto 18.6 1.2 -17.4 90", "walk rancher", "look rancher chest"], ["shove"], r"shov|push|hands on|elbow|rough|shoved"),
    "shot": (["goto 18.6 1.2 -17.4 90", "walk rancher", "look rancher chest", "weapon revolver", "wait 15", "turn 0 80"], ["shoot 1"],
             r"\bshot\b|shooting|\bfired\b|firing|ceiling|let (that|off)|iron off"),
    "sit": (["goto 18.6 1.2 -17.4 90"], ["sit s"], r"sit down|\bsat\b|join|pull up|take a hand|\bseat\b"),
    "win_pot": (["sit s"], ["ans_pot 240"], r"\bpot\b|you won|cleaned|lucky"),
    # The card table (#1279): you sat at its south chair; a verb on your turn is the input the player
    # uses (a nod calls, a shake folds, fire raises: the "press fire" is nothing before #1279's raise).
    "call": (["sit s", "ans_turn bet 400"], ["nod"], r"\bcall|see (it|that|you)|in, then|brave"),
    "fold": (["sit s", "ans_turn any 240"], ["shake"], r"\bfold|out of it|quit|smart|scared"),
    "raise": (["sit s", "ans_turn any 400"], ["press fire"], r"\braise|rais|big bet|proud|bet like"),
    "bluff": (["sit s", "ans_turn weak 300"], ["press fire"], r"bluff|\bnothing\b|rais|big bet|lie|liar|bet like"),
    "lose_pot": (["sit s"], ["ans_lose 300"], r"\bpot\b|lost|losing|lose|cleaned|unlucky|took you"),
    "cheat": (["sit s", "wait 20", "look earl"], ["press shout"], r"cheat|bottom|deal(ing|t)? (off|from)|sleeve|crook|accus|calling me|called earl"),
    "stand": (["sit s", "wait 30"], ["stand"], r"leav|quit|go(ing)? so soon|money|cash|up and|walk(ing)? off"),
    "watch": (["goto 18.6 1.2 -17.4 90", "ans_close earl 1.6"], ["wait 0.1"], r"sit|chair|deal you|join|play|watch(ing)?|seat"),
    "knock": (["walk saloonb_front_in", "turn 180"], ["press shove"], r"knock|door|bang"),
    "crowd": (["goto 18.6 1.2 -17.4 90", "walk rancher"], ["ans_close rancher 0.6"], r"close|room|space|breath|back off|crowd"),
    # The bar (#1292): stood before the barkeep (`drink bar`), a whiskey asked for (E there), then drunk.
    "buy": (["drink bar"], ["drink buy whiskey"], r"whiskey|cents|pour|money|drink|glass|nickel"),
    "drink": (["drink bar", "drink buy whiskey", "wait 4", "drink take"], ["drink sip 1"], r"drink|whiskey|glass|alone|thirst|bottle|drunk"),
    "round": (["drink bar"], ["drink buy round"], r"round|buying|house|obliged|health|drink|neighbourly|bought"),
}


def bridge(*cmds, timeout=900):
    p = subprocess.run(BRIDGE + list(cmds) + ["--timeout=%d" % timeout], capture_output=True, text=True,
                       cwd=ROOT, timeout=timeout + 60)
    out = []
    for line in p.stdout.splitlines():
        line = line.strip()
        if line.startswith("{"):
            try:
                out.append(json.loads(line))
            except json.JSONDecodeError:
                pass
    return out


# The bar's verbs (#1292) on an ordinary evening: the bench's day 1 is No Law's night, whose scene holds the
# bar and its barkeep (SceneHold, ValleyFolk._story_on), so these start with the murder off.
ORDINARY = ("buy", "drink", "round")


def start(verb=""):
    subprocess.run(BRIDGE + ["stop"], capture_output=True, cwd=ROOT)
    args = "--world=valley" + (",--no-murder" if verb in ORDINARY else "")
    p = subprocess.run(BRIDGE + ["start", "--headless", "--game-args=" + args], capture_output=True,
                       text=True, cwd=ROOT, timeout=900)
    if p.returncode != 0:
        raise SystemExit("bridge didn't start: " + p.stdout[-400:] + p.stderr[-400:])


def moved(a, b, keys=("trust", "fear", "liking", "respect")):
    return any(abs(float(a.get(k, 0)) - float(b.get(k, 0))) > 1e-3 for k in keys)


def one(verb):
    setup, act, words = VERBS[verb]
    start(verb)
    bridge("time 20.5", "wait 25")
    log = {"verb": verb, "setup": [r for r in bridge(*setup)] if setup else []}
    before = bridge("ans_snap")[0]
    r = bridge(*act, "ans_watch %d" % (20 if verb in ("crowd", "watch") else 3))
    log["act"] = r[:-1]
    watch = r[-1]
    after = bridge("ans_snap")[0]
    # Lines said in the verb's own frame (the man shoved crying out) come before ans_watch listens: take
    # them from the bridge's log, from the verb's start to the watch's end.
    t0 = max([x.get("t", 0) for x in log["setup"]] + [before.get("t", 0)])
    for e in bridge("events 60")[0]["events"]:
        if e.get("kind") == "said" and t0 <= e.get("t", 0) <= watch.get("t", 0):
            pid, text = e["text"].split(":", 1)
            if pid not in watch["first"] or watch["first"][pid]["how"] != "said":
                watch["first"].setdefault(pid, {"how": "said", "s": round(e["t"] - t0, 2), "text": text.strip()})
                if watch["first"][pid]["how"] != "said":
                    watch["first"][pid]["also_said"] = text.strip()
    t_after = bridge("events 1")[0]["events"][-1]["t"] if bridge("events 1")[0]["events"] else 0
    # Later: the room, a walk past the men in, the clock run on.
    men_in = [p for p, m in after["men"].items() if m.get("state") == "in" and m.get("d", 99) < 15]
    later = ["wait 60"] + ["walk %s" % p for p in men_in[:6]] + ["wait 10", "clock 24", "wait 120", "clock on",
                                                               "read regard", "read news", "events 400"]
    lr = bridge(*later, timeout=1200)
    regard = next((x for x in lr if x.get("cmd") == "read regard"), {})
    news = next((x for x in lr if x.get("cmd") == "read news"), {}).get("news", {})
    events = next((x for x in lr if x.get("cmd") == "events 400"), {}).get("events", [])
    bridge("stop")
    saw = [p for p, m in before["men"].items() if m.get("sees")]
    target = "rancher" if verb in ("shove", "crowd") else None
    if target and target not in saw:
        saw.append(target)
    saw += [p for p, m in before["men"].items() if m.get("table") and p not in saw]  # the table's verbs: to their faces
    reacted = sorted(set(watch.get("first", {})) & set(saw))
    moved_ = [p for p in before["men"] if "trust" in after["men"].get(p, {}) and moved(before["men"][p], after["men"][p])]
    rx = re.compile(words, re.I)
    later_lines = [e for e in events if e.get("kind") == "said" and e.get("t", 0) > t_after]
    mentions = [e["text"] for e in later_lines if rx.search(e["text"].split(":", 1)[-1])]
    told = [r for r in news.get("records", []) if r.get("told", 0)] if isinstance(news.get("records"), list) else []
    log.update({"before": before, "watch": watch, "after": after, "saw": saw, "reacted": reacted, "moved": moved_,
                "later_lines": [e["text"] for e in later_lines], "mentions": mentions, "news": news,
                "barks": regard.get("barks", [])})
    return log


def row(lg):
    w = lg["watch"].get("first", {})
    # A man who said something in the watch shows "said" (#1279: at the table the look comes first, the words a
    # beat after, and the row hid them).
    spoke = {l[0] for l in lg["watch"].get("lines", [])}
    hows = ", ".join("%s %s" % (p, "said" if p in spoke or "also_said" in w[p] else (w[p]["how"].split(":")[0] if not w[p]["how"].startswith("reaction") else w[p]["how"].split(":", 1)[1])) for p in lg["reacted"])
    nrec = len(lg["news"].get("records", [])) if isinstance(lg["news"].get("records"), list) else 0
    near = sum(1 for m in lg["before"]["men"].values() if m.get("d", 99) <= 10.0)
    return "| %s | %d | %d | %d (%s) | %d | %s |" % (lg["verb"], near, len(lg["saw"]), len(lg["reacted"]), hows or "-",
                                             len(lg["moved"]),
                                             ("yes: " + "; ".join(lg["mentions"][:2])) if lg["mentions"] else
                                             ("news records %d, no line" % nrec if nrec else "no"))


def retable(lg):
    """Recount a saved verb from its JSON (the rules above, without running it again)."""
    setup, act, words = VERBS[lg["verb"]]
    before, after, watch = lg["before"], lg["after"], lg["watch"]
    saw = [p for p, m in before["men"].items() if m.get("sees")]
    if lg["verb"] in ("shove", "crowd") and "rancher" not in saw:
        saw.append("rancher")
    saw += [p for p, m in before["men"].items() if m.get("table") and p not in saw]
    lg["saw"] = saw
    lg["reacted"] = sorted(set(watch.get("first", {})) & set(saw))
    lg["moved"] = [p for p in before["men"] if "trust" in after["men"].get(p, {}) and moved(before["men"][p], after["men"][p])]
    rx = re.compile(words, re.I)
    lg["mentions"] = [t for t in lg["later_lines"] if rx.search(t.split(":", 1)[-1])]
    return lg


def main(argv):
    if argv and argv[0] == "--retable":
        rows = [row(retable(json.load(open(os.path.join(argv[1], v + ".json"))))) for v in VERBS
                if os.path.exists(os.path.join(argv[1], v + ".json"))]
        table = "| verb | in the room (10 m) | saw it | reacted in 3 s | regard moved | mentioned later |\n|---|---|---|---|---|---|\n" + "\n".join(rows)
        open(os.path.join(argv[1], "table.md"), "w").write(table + "\n")
        print(table)
        return
    only = next((a.split("=", 1)[1].split(",") for a in argv if a.startswith("--only=")), list(VERBS))
    out = next((a.split("=", 1)[1] for a in argv if a.startswith("--out=")), os.path.join(HERE, "results", time.strftime("%Y-%m-%d_%H%M")))
    os.makedirs(out, exist_ok=True)
    rows = []
    for v in only:
        t = time.time()
        lg = one(v)
        json.dump(lg, open(os.path.join(out, v + ".json"), "w"), indent=1)
        rows.append(row(lg))
        print(rows[-1], "(%.0f s)" % (time.time() - t), flush=True)
    table = "| verb | in the room (10 m) | saw it | reacted in 3 s | regard moved | mentioned later |\n|---|---|---|---|---|---|\n" + "\n".join(rows)
    open(os.path.join(out, "table.md"), "w").write(table + "\n")
    print(table)


if __name__ == "__main__":
    main(sys.argv[1:])
