# Style pictures

Put pictures in the look we want here (PNG, JPG or WebP). `tools/style/train_style.py` (People
workflow, input `style: train`) crops them, along with the concept paintings one folder up, and
trains the image model's style on fal.

Optional: `captions.json` here, `{"file.png": "what it shows, in a few words"}`; without it, each
picture is captioned plainly as pixel-art painting.

The repo is public: only add pictures we're allowed to keep in it.
