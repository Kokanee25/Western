"""The voice pilot (docs/briefs/voice-pilot.md): the same lines made three ways on fal, plus the
saloon's ambience layers, every take checked by transcription, for Sean's blind listen.

    FAL_KEY=... python3 tools/voice/pilot.py --out=DIR [--only=a,b,c,amb]
    python3 tools/voice/pilot.py --cost

  A  Eleven v4, the words alone (stock voice, stability 0.5)
  B  Eleven v4, the same words directed: audio tags and punctuation (stability 0.3)
  C  Eleven v3 Text to Dialogue: each conversation made whole from B's lines, then cut into lines
     at its pauses (v4 dialogue isn't on fal)
  amb  the saloon's crowd beds (looping) and one-shot layers (laughs, glasses, chairs...)

Writes DIR/<version>/<line id>.mp3, DIR/amb/<name>.mp3 and DIR/manifest.json (each clip: who,
version, words, what the transcription heard, word match, length). Dry: no room sound in any of it.
"""
import concurrent.futures as cf
import difflib
import json
import os
import re
import subprocess
import sys
import urllib.request

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "cinematic"))
import audio as fal  # noqa: E402  (request/run/save on fal's queue)

HERE = os.path.dirname(os.path.abspath(__file__))
LINES = json.load(open(os.path.join(HERE, "pilot_lines.json")))
V4 = "elevenlabs/tts/eleven-v4"
DIALOGUE = "fal-ai/elevenlabs/text-to-dialogue/eleven-v3"
SFX = "fal-ai/elevenlabs/sound-effects/v2"
STT = "fal-ai/elevenlabs/speech-to-text"
WORKERS = 4

CROWD = ("Realistic interior ambience of a crowded 1880s American frontier saloon at night. {n} men having "
         "overlapping low conversations, indistinct speech, deep male murmuring, no words clear. {extra} Wooden "
         "chairs creaking, boots shifting on timber floors. No music, no piano, no modern sounds, no clear "
         "foreground dialogue, dry close recording, seamless continuous ambience.")
AMBIENCE = [
    # name, text, seconds, loop
    ("crowd_quiet_1", CROWD.format(n="Three or four", extra="Quiet afternoon, long pauses, a cough, a glass set down."), 22, True),
    ("crowd_quiet_2", CROWD.format(n="Three or four", extra="Quiet afternoon, soft talk, someone shuffling cards."), 22, True),
    ("crowd_evening_1", CROWD.format(n="Fifteen to twenty", extra="Normal evening, occasional light laughter, glasses clinking."), 22, True),
    ("crowd_evening_2", CROWD.format(n="Fifteen to twenty", extra="Normal evening, lively, bottles and glasses at the bar."), 22, True),
    ("crowd_busy_1", CROWD.format(n="Thirty", extra="Busy Saturday night, loud, raucous laughter, someone arguing, glasses."), 22, True),
    ("crowd_busy_2", CROWD.format(n="Thirty", extra="Busy Saturday night, rowdy, men calling out, laughter rising and falling."), 22, True),
    ("crowd_tense_1", CROWD.format(n="Ten", extra="Tense, subdued, men muttering under their breath, no laughter."), 22, True),
    ("crowd_tense_2", CROWD.format(n="Ten", extra="Tense, nervous, hushed murmuring, a chair shifting, no laughter."), 22, True),
    ("hush", "A crowded saloon's chatter dying away into complete silence over three seconds as everyone stops "
             "talking at once, one chair creaks, then silence. Dry, no music.", 5, False),
    ("laugh_table_1", "Three men at a card table burst out laughing at a joke, rough deep laughter, then settling. Close, dry.", 4, False),
    ("laugh_table_2", "Two men chuckling and one man laughing loudly, slapping the table once. Close, dry.", 4, False),
    ("laugh_one", "One old man wheezing laugh that turns into a cough. Close, dry.", 3, False),
    ("glass_clink", "Two whiskey glasses clinked together in a toast, close, dry.", 1.5, False),
    ("glass_set", "A heavy glass tumbler set down on a wooden bar top, close, dry.", 1, False),
    ("bottle_pour", "Whiskey poured from a glass bottle into a tumbler on a wooden bar, close, dry.", 3, False),
    ("chair_scrape_1", "A wooden chair scraped back across a plank floor as a man stands up, close, dry.", 2, False),
    ("chair_scrape_2", "A wooden chair dragged a short way on old floorboards, close, dry.", 1.5, False),
    ("cough", "A man clearing his throat and coughing twice, gruff, close, dry.", 2, False),
    ("boots_boards", "Boots with spurs walking slowly across creaking wooden saloon floorboards, five steps, close, dry.", 4, False),
    ("cards_shuffle", "A deck of playing cards shuffled and dealt onto a felt table, close, dry.", 4, False),
]


def all_lines():
    """Every line once: (id, who, plain, directed, scene)."""
    out = []
    for c in LINES["conversations"]:
        for l in c["lines"]:
            out.append((l["id"], l["who"], l["plain"], l["directed"], c["scene"]))
    for l in LINES["lines"]:
        out.append((l["id"], l["who"], l["plain"], l["directed"], l["scene"]))
    return out


def voice_of(who):
    return LINES["cast"][who]["voice"]


def jobs(only):
    js = []
    for lid, who, plain, directed, scene in all_lines():
        if "a" in only:
            js.append(("a/" + lid, V4, {"text": plain, "voice": voice_of(who), "stability": 0.5, "seed": 7}))
        if "b" in only:
            js.append(("b/" + lid, V4, {"text": directed, "voice": voice_of(who), "stability": 0.3, "seed": 7}))
    if "c" in only:
        for c in LINES["conversations"]:
            js.append(("c_whole/" + c["id"], DIALOGUE, {
                "inputs": [{"text": l["directed"], "voice": voice_of(l["who"])} for l in c["lines"]],
                "stability": 0.5, "seed": 7}))
    if "amb" in only:
        for name, text, secs, loop in AMBIENCE:
            js.append(("amb/" + name, SFX, {"text": text, "duration_seconds": secs, "prompt_influence": 0.6,
                                             "loop": loop}))
    return js


def cost(js):
    t = 0.0
    for name, app, b in js:
        if app == V4:
            t += len(b["text"]) / 1000.0 * 0.08
        elif app == DIALOGUE:
            t += sum(len(i["text"]) for i in b["inputs"]) / 1000.0 * 0.10
        else:
            t += 0.10
    return t


def duration(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
                         capture_output=True, text=True).stdout.strip()
    return float(out or 0)


def silences(path, noise="-38dB", d=0.12):
    err = subprocess.run(["ffmpeg", "-hide_banner", "-i", path, "-af", "silencedetect=n=%s:d=%s" % (noise, d),
                          "-f", "null", "-"], capture_output=True, text=True).stderr
    starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", err)]
    ends = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", err)]
    return list(zip(starts, ends))


def split_dialogue(whole, conv, out):
    """Cut a conversation into its lines at its N-1 longest pauses (inside the speech)."""
    n = len(conv["lines"])
    total = duration(whole)
    gaps = [(e - s, (s + e) / 2) for s, e in silences(whole) if s > 0.05 and e < total - 0.05]
    cuts = sorted(m for _, m in sorted(gaps, reverse=True)[:n - 1])
    bounds = [0.0] + cuts + [total]
    made = []
    for i, l in enumerate(conv["lines"]):
        if i + 1 >= len(bounds):
            break
        dst = os.path.join(out, "c", l["id"] + ".mp3")
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        subprocess.run(["ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-i", whole, "-ss", "%.3f" % bounds[i],
                        "-to", "%.3f" % bounds[i + 1], "-c:a", "libmp3lame", "-q:a", "3", dst], check=True)
        made.append(l["id"])
    return made, len(cuts) == n - 1


def words(s):
    s = re.sub(r"\[[^\]]*\]", " ", s.lower())
    return re.findall(r"[a-z0-9']+", s)


def match(expected, heard):
    a, b = words(expected), words(heard)
    if not a:
        return 1.0
    return difflib.SequenceMatcher(None, a, b).ratio()


def main():
    a = {k: (v or True) for k, _, v in (x[2:].partition("=") for x in sys.argv[1:] if x.startswith("--"))}
    only = a.get("only", "a,b,c,amb")
    only = only.split(",") if isinstance(only, str) else ["a", "b", "c", "amb"]
    js = jobs(only)
    print("%d calls, about $%.2f (+ transcription, a few cents)" % (len(js), cost(js)), flush=True)
    if a.get("cost"):
        return
    key = os.environ["FAL_KEY"]
    out = os.path.abspath(a.get("out", "build/voice"))
    urls = {}

    def make(job):
        name, app, body = job
        path = os.path.join(out, name + ".mp3")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        ans = fal.run(app, body, key)
        fal.save(ans, path)
        return name, ans["audio"]["url"]

    failed = []
    with cf.ThreadPoolExecutor(WORKERS) as ex:
        for fut in cf.as_completed([ex.submit(make, j) for j in js]):
            try:
                name, url = fut.result()
                urls[name] = url
                print("made", name, flush=True)
            except Exception as e:     # one bad call doesn't sink the pilot
                failed.append(str(e)[:300])
                print("FAILED", str(e)[:300], flush=True)

    manifest = {"clips": [], "failed": failed, "cast": LINES["cast"]}
    split_ok = {}
    for c in LINES["conversations"]:
        whole = os.path.join(out, "c_whole", c["id"] + ".mp3")
        if os.path.exists(whole):
            made, ok = split_dialogue(whole, c, out)
            split_ok[c["id"]] = ok
    info = {lid: (who, plain, scene) for lid, who, plain, directed, scene in all_lines()}

    def check(rel):
        path = os.path.join(out, rel)
        heard = ""
        url = urls.get(rel[:-4])
        try:
            if url is None:
                # A cut line: send the file itself as a data URL (short clips).
                import base64
                url = "data:audio/mpeg;base64," + base64.b64encode(open(path, "rb").read()).decode()
            ans = fal.run(STT, {"audio_url": url}, key)
            heard = ans.get("text") or " ".join(w.get("text", "") for w in ans.get("words", []))
        except Exception as e:
            heard = "?? " + str(e)[:120]
        return rel, heard

    clips = []
    for v in ("a", "b", "c"):
        d = os.path.join(out, v)
        if os.path.isdir(d):
            clips += [v + "/" + f for f in sorted(os.listdir(d)) if f.endswith(".mp3")]
    with cf.ThreadPoolExecutor(WORKERS) as ex:
        for rel, heard in ex.map(check, clips):
            v, f = rel.split("/")
            lid = f[:-4]
            who, plain, scene = info[lid]
            conv = next((c["id"] for c in LINES["conversations"] if any(l["id"] == lid for l in c["lines"])), None)
            manifest["clips"].append({"file": rel, "version": v, "id": lid, "who": who, "words": plain,
                                      "scene": scene, "conversation": conv, "heard": heard,
                                      "match": round(match(plain, heard), 3),
                                      "seconds": round(duration(os.path.join(out, rel)), 2),
                                      "cut_ok": split_ok.get(conv, True) if v == "c" else True})
    manifest["ambience"] = [{"file": "amb/%s.mp3" % n, "text": t, "loop": lp}
                            for n, t, s, lp in AMBIENCE if os.path.exists(os.path.join(out, "amb", n + ".mp3"))]
    json.dump(manifest, open(os.path.join(out, "manifest.json"), "w"), indent=1)
    bad = [c for c in manifest["clips"] if c["match"] < 0.8]
    print("clips %d, ambience %d, word mismatches %d, failed calls %d" % (
        len(manifest["clips"]), len(manifest["ambience"]), len(bad), len(failed)), flush=True)
    for c in bad:
        print("  check", c["file"], c["match"], "heard:", c["heard"][:80], flush=True)


if __name__ == "__main__":
    main()
