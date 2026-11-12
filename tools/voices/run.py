"""Voiced lines' paid calls (#807), run on GitHub (.github/workflows/voices.yml), never in a session.

A request is tools/voices/requests/<YYYY-MM-DD>_<what>.yaml; it's done when <name>.done.yaml exists
(its outcome), so a push never runs it twice. Fields:
    task: probe | cast
    spend: 0.00          # the most the whole request may cost ($): required; the run stops before passing it
    note: why
probe (free): fetches fal's API schemas and pages for its ElevenLabs endpoints and the terms
(ElevenLabs, fal) into tools/voices/probe/, for the session to read (the workspace can't reach them).
cast (paid): see cast.py.
Every paid call is a row in tools/voices/paid.csv (date, request, app, what, est $).
"""
import glob
import html
import json
import os
import re
import sys
import urllib.request

import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
UA = {"User-Agent": "saltcreek-voices/1"}

FAL_APPS = [
    "fal-ai/elevenlabs/text-to-voice/design/eleven-v3",
    "fal-ai/elevenlabs/tts/eleven-v3",
    "elevenlabs/tts/eleven-v4",
    "fal-ai/elevenlabs/tts/multilingual-v2",
    "fal-ai/elevenlabs/text-to-dialogue/eleven-v3",
]
PAGES = {
    "fal_elevenlabs": "https://fal.ai/elevenlabs",
    "fal_models": "https://fal.ai/models?keywords=elevenlabs",
    "fal_terms": "https://fal.ai/terms",
    "el_terms": "https://elevenlabs.io/terms-of-use",
    "el_service_terms": "https://elevenlabs.io/service-specific-terms",
    "el_use_policy": "https://elevenlabs.io/use-policy",
    "el_publish_help": "https://elevenlabs.io/docs/help-center/legal/can-i-publish-the-content-i-generate-on-the-platform/llms.txt",
    "el_voice_design_doc": "https://elevenlabs.io/docs/api-reference/text-to-voice/design.md",
    "el_models_doc": "https://elevenlabs.io/docs/models.md",
}


def fetch(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
        return r.read().decode("utf-8", errors="replace")


def text_of(page):
    page = re.sub(r"(?is)<(script|style)[^>]*>.*?</\1>", " ", page)
    page = re.sub(r"(?s)<[^>]+>", " ", page)
    return re.sub(r"[ \t]+", " ", re.sub(r"\n\s*\n+", "\n", html.unescape(page))).strip()


def probe(out):
    os.makedirs(out, exist_ok=True)
    got = {}
    for app in FAL_APPS:
        slug = app.replace("/", "_")
        for kind, url in (("openapi", "https://fal.ai/api/openapi/queue/openapi.json?endpoint_id=" + app),
                          ("llms", "https://fal.ai/models/%s/llms.txt" % app)):
            try:
                t = fetch(url)
                open(os.path.join(out, "%s.%s.%s" % (slug, kind, "json" if kind == "openapi" else "txt")), "w").write(t)
                got[url] = len(t)
            except Exception as e:
                got[url] = "failed: %s" % e
    for name, url in PAGES.items():
        try:
            raw = fetch(url)
            if name == "fal_models":   # just the ElevenLabs endpoint ids
                ids = sorted(set(re.findall(r"(?:fal-ai/)?elevenlabs/[a-z0-9/_.-]+", raw)))
                open(os.path.join(out, "fal_models.ids.txt"), "w").write("\n".join(ids) + "\n")
            else:
                open(os.path.join(out, name + ".txt"), "w").write(raw if url.endswith((".txt", ".md")) else text_of(raw))
            got[url] = len(raw)
        except Exception as e:
            got[url] = "failed: %s" % e
    json.dump(got, open(os.path.join(out, "_fetched.json"), "w"), indent=1)
    return {"fetched": got}


def main():
    ran = 0
    for path in sorted(glob.glob(os.path.join(HERE, "requests", "*.yaml"))):
        if path.endswith(".done.yaml") or os.path.exists(path[:-5] + ".done.yaml"):
            continue
        req = yaml.safe_load(open(path))
        if "spend" not in req:
            out = {"error": "no spend: field"}
        elif req.get("task") == "probe":
            out = probe(os.path.join(HERE, "probe"))
        elif req.get("task") == "cast":
            sys.path.insert(0, HERE)
            import cast
            try:
                out = cast.run(req, os.path.basename(path)[:-5])
            except Exception as e:   # a failed run is recorded, never retried by itself
                out = {"error": repr(e)}
        else:
            out = {"error": "unknown task"}
        with open(path[:-5] + ".done.yaml", "w") as f:
            yaml.safe_dump(out, f, sort_keys=False, allow_unicode=True)
        print(path, json.dumps(out)[:2000])
        ran += 1
    print("requests run:", ran)


if __name__ == "__main__":
    main()
