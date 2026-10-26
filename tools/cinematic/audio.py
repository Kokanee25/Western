"""The cinematic's sound, generated on fal (docs/briefs/cinematic.md, step 3): the stranger's line
(ElevenLabs v3 TTS), the effects (ElevenLabs sound effects v2) and the score (ElevenLabs music).

    FAL_KEY=... python3 tools/cinematic/audio.py [--only=voice,sfx,music] [--out=build/cinematic/audio]
    python3 tools/cinematic/audio.py --cost        # what a full run costs, no calls

Every request is in REQUESTS below, so a run is repeatable; each answer is saved as
<out>/<name>.mp3 and listed in <out>/made.json (prompt, model, seconds). Prices (fal's pages,
2026-10-26): TTS $0.10 per 1,000 characters; music $0.60 per started minute; effects billed by fal
per call (a few cents).
"""
import json
import os
import sys
import time
import urllib.request

QUEUE = "https://queue.fal.run/"
POLL = 2.0

# The stranger's voice: low, dry, unhurried. v3 takes audio tags in the text.
VOICE = {"name": "voice_welcome", "app": "fal-ai/elevenlabs/tts/eleven-v3",
         "body": {"text": "[low, dry, unhurried] Welcome to Salt Creek.", "voice": "Bill",
                  "stability": 0.35, "similarity_boost": 0.75, "speed": 0.9}}
VOICE_TAKES = [("Bill", 1), ("George", 2), ("Callum", 3)]   # three voices to pick from

SFX = [
    ("sfx_shuffle", "A deck of old playing cards riffle-shuffled and bridged on a felt table, close", 3.0),
    ("sfx_room", "Quiet 1880s saloon at night: low murmur of men, a glass set down, creaking floorboards, "
                 "distant honky-tonk piano, no music melody up front", 20.0),
    ("sfx_clock", "A slow old pendulum wall clock ticking in a silent room, close and dry", 8.0),
    ("sfx_ace", "A playing card slid slowly out of a cloth sleeve, tiny paper whisper, very close", 1.5),
    ("sfx_kick", "A heavy boot kicks a wooden chair out from under a man, the chair clatters across a "
                 "plank floor and the man hits the floor hard", 2.5),
    ("sfx_coins", "Coins and cards falling and scattering on a wooden floor, coins rolling and spinning down",
     3.0),
    ("sfx_draw", "A Colt revolver drawn fast from a leather holster, then the hammer cocked, close", 1.5),
    ("sfx_shot", "A single black-powder revolver shot indoors in a wooden saloon, huge and sharp, long "
                 "room ring-out", 3.0),
    ("sfx_drink", "A tin cup of whiskey lifted from a wooden table and a slow sip", 2.0),
    ("sfx_title", "A deep cinematic boom with dust settling and a single spur jingle", 4.0),
]

MUSIC = {"name": "music_score", "app": "fal-ai/elevenlabs/music",
         "body": {"prompt": "Cinematic western trailer score, 60 seconds, instrumental. Starts sparse and tense: "
                            "a lone detuned saloon piano and low cello drone. Builds slowly with a soft heartbeat "
                            "drum and a tremolo baritone guitar. At 34 seconds it stops dead for silence. "
                            "At 50 seconds a big low brass and timpani hit for the title, then a lonely "
                            "harmonica phrase that fades out. Gritty, dusty, Morricone feel, no vocals.",
                  "music_length_ms": 60000, "force_instrumental": True}}


def request(method, url, key, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method,
                                 headers={"Authorization": "Key " + key, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read().decode())


def run(app, body, key):
    """Submit to fal's queue and wait for the answer."""
    q = request("POST", QUEUE + app, key, body)
    base = QUEUE + "/".join(app.split("/")[:2])
    status = q.get("status_url") or "%s/requests/%s/status" % (base, q["request_id"])
    resp = q.get("response_url") or "%s/requests/%s" % (base, q["request_id"])
    for _ in range(600):
        st = request("GET", status, key).get("status")
        if st == "COMPLETED":
            return request("GET", resp, key)
        if st not in ("IN_QUEUE", "IN_PROGRESS"):
            raise RuntimeError("%s: %s" % (app, st))
        time.sleep(POLL)
    raise RuntimeError("%s: timed out" % app)


def save(answer, path):
    url = answer["audio"]["url"]
    with urllib.request.urlopen(url, timeout=120) as r, open(path, "wb") as f:
        f.write(r.read())


def jobs(only):
    out = []
    if "voice" in only:
        for voice, n in VOICE_TAKES:
            b = dict(VOICE["body"], voice=voice, seed=n)
            out.append(("%s_%s" % (VOICE["name"], voice.lower()), VOICE["app"], b))
    if "sfx" in only:
        for name, text, secs in SFX:
            out.append((name, "fal-ai/elevenlabs/sound-effects/v2",
                        {"text": text, "duration_seconds": secs, "prompt_influence": 0.5}))
    if "music" in only:
        out.append((MUSIC["name"], MUSIC["app"], MUSIC["body"]))
    return out


def cost(js):
    total = 0.0
    for name, app, b in js:
        if "tts" in app:
            total += len(b["text"]) / 1000.0 * 0.10
        elif "music" in app:
            total += 0.60 * -(-b["music_length_ms"] // 60000)
        else:
            total += 0.08    # an effect: an upper guess per call
    return total


def main():
    a = {k: (v or True) for k, _, v in (x[2:].partition("=") for x in sys.argv[1:] if x.startswith("--"))}
    only = a.get("only", "voice,sfx,music")
    only = only.split(",") if isinstance(only, str) else ["voice", "sfx", "music"]
    js = jobs(only)
    print("%d calls, about $%.2f" % (len(js), cost(js)))
    if a.get("cost"):
        return
    key = os.environ.get("FAL_KEY", "")
    if not key:
        print("No FAL_KEY: nothing made.")
        return
    out = a.get("out", "build/cinematic/audio")
    os.makedirs(out, exist_ok=True)
    made = {}
    for name, app, b in js:
        print("making", name, flush=True)
        ans = run(app, b, key)
        path = os.path.join(out, name + ".mp3")
        save(ans, path)
        made[name] = {"app": app, "body": b}
    json.dump(made, open(os.path.join(out, "made.json"), "w"), indent=1)
    print("made", len(made))


if __name__ == "__main__":
    main()
