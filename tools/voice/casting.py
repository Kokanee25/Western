"""Cast Salt Creek's voices on ElevenLabs Voice Design (docs/briefs/voice-casting.md).

    ELEVENLABS_API_KEY=... python3 tools/voice/casting.py design --round=N --out=DIR [--only=stranger,lyle]
    ELEVENLABS_API_KEY=... python3 tools/voice/casting.py save --picks=tools/voice/picks.json

design: for every character not yet in cast_voices.json (or those in --only), each description variant
in cast.json (plus any `notes` Sean gave for the next round in picks.json) makes 3 candidates reading
the character's audition. Writes DIR/<who>/<variant>_<n>.mp3 and DIR/candidates.json (each
candidate's generated_voice_id, description, round).
save: each pick {who: {"candidate": "<variant>_<n>", "round": N, "generated_voice_id": ...}} is
saved to the account as a permanent voice and recorded in cast_voices.json (voice_id, description).
"""
import base64
import json
import os
import sys
import urllib.error
import urllib.request

API = "https://api.elevenlabs.io/v1"
HERE = os.path.dirname(os.path.abspath(__file__))
CAST = json.load(open(os.path.join(HERE, "cast.json")))
VOICES = os.path.join(HERE, "cast_voices.json")
MODEL = "eleven_ttv_v3"


def call(path, body, key):
    req = urllib.request.Request(API + path, data=json.dumps(body).encode(), method="POST",
                                 headers={"xi-api-key": key, "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        raise RuntimeError("%s %s: %s" % (e.code, path, e.read().decode(errors="replace")[:600]))


def cast_voices():
    return json.load(open(VOICES)) if os.path.exists(VOICES) else {}


def design(args, key):
    rnd = int(args.get("round", 1))
    out = os.path.abspath(args.get("out", "build/casting"))
    only = args["only"].split(",") if isinstance(args.get("only"), str) else None
    picks = json.load(open(args["picks"])) if os.path.exists(args.get("picks", "")) else {}
    done = cast_voices()
    made = []
    for who, c in CAST["characters"].items():
        if (only and who not in only) or (not only and who in done):
            continue
        variants = list(c["variants"])
        note = (picks.get(who) or {}).get("notes")
        if note:      # Sean's notes for the next round: a variant built from his words
            base = (picks.get(who) or {}).get("from_variant")
            text = next((v["text"] for v in variants if v["id"] == base), variants[0]["text"])
            variants = [{"id": "notes", "text": text + " " + note}] + variants[:2]
        for n, v in enumerate(variants):
            desc = (v["text"] + " " + CAST["common"])[:1000]
            body = {"voice_description": desc, "text": c["audition"], "model_id": MODEL,
                    "guidance_scale": 3.5, "seed": rnd * 100 + n, "loudness": 0.5}
            try:
                ans = call("/text-to-voice/design?output_format=mp3_44100_128", body, key)
            except RuntimeError as e:
                print("FAILED", who, v["id"], str(e)[:300], flush=True)
                continue
            for k, p in enumerate(ans.get("previews", [])):
                cid = "%s_%d" % (v["id"], k + 1)
                path = os.path.join(out, who, cid + ".mp3")
                os.makedirs(os.path.dirname(path), exist_ok=True)
                open(path, "wb").write(base64.b64decode(p["audio_base_64"]))
                made.append({"who": who, "candidate": cid, "variant": v["id"], "description": desc,
                             "generated_voice_id": p["generated_voice_id"], "round": rnd,
                             "seconds": p.get("duration_secs"), "file": "%s/%s.mp3" % (who, cid)})
                print("made", who, cid, flush=True)
    json.dump({"round": rnd, "candidates": made}, open(os.path.join(out, "candidates.json"), "w"), indent=1)
    print("candidates", len(made), flush=True)


def save(args, key):
    picks = json.load(open(args["picks"]))
    done = cast_voices()
    for who, p in picks.items():
        if not p.get("generated_voice_id") or who in done:
            continue
        name = p.get("name") or CAST["characters"][who]["name"]   # spares (kept for later roles) carry their own
        body = {"voice_name": "Salt Creek - " + name, "voice_description": p["description"][:500],
                "generated_voice_id": p["generated_voice_id"]}
        ans = call("/text-to-voice", body, key)
        done[who] = {"voice_id": ans["voice_id"], "name": body["voice_name"], "description": p["description"],
                     "from": "round %s candidate %s" % (p.get("round"), p.get("candidate")), "model": MODEL,
                     "spare": bool(p.get("spare"))}
        print("saved", who, ans["voice_id"], flush=True)
    json.dump(done, open(VOICES, "w"), indent=1)


def main():
    what = sys.argv[1]
    args = {k: (v or True) for k, _, v in (x[2:].partition("=") for x in sys.argv[2:] if x.startswith("--"))}
    key = os.environ.get("ELEVENLABS_API_KEY", "")
    if not key:
        sys.exit("No ELEVENLABS_API_KEY in this run's secrets.")
    {"design": design, "save": save}[what](args, key)


if __name__ == "__main__":
    main()
