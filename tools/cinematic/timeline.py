"""The cinematic's timeline (docs/briefs/cinematic.md): the shots and the sound cues, in seconds.
Used by film.py (what to render with which camera) and cut.py (fades, the mix)."""

FPS = 24
LENGTH = 60.0

# (name, start, end): consecutive, covering 0..LENGTH.
SHOTS = [
    ("table", 0.0, 4.5),      # 1. the felt, the lamp, cards and coins (fades up from black)
    ("ots", 4.5, 9.5),        # 2. over your shoulder: the stranger, silent
    ("room", 9.5, 14.0),      # 3. the room: the barkeep at his rag, the moon in the door
    ("ace", 14.0, 17.0),      # 4. the ace slides out of the cheater's cuff
    ("smirk", 17.0, 20.0),    # 4. his smirk
    ("lyle", 20.0, 23.5),     # 5. Lyle's eyes lift; the music stops
    ("rise", 23.5, 26.0),     # 6. Lyle stands, his chair goes back, he steps round
    ("kick", 26.0, 29.0),     # 6. the kick: the chair goes, the cheater goes down
    ("rain", 29.0, 31.0),     # 6. cards and coins coming down round him
    ("draw", 31.0, 33.0),     # 7. the gun clears leather
    ("floor", 33.0, 36.0),    # 8. on the floor, terrified, a hand up
    ("aim", 36.0, 37.5),      # 9. down the barrel; the flash is the last frames
    ("after", 37.5, 42.5),    # 9. your view: smoke, the body, a coin still rolling
    ("stranger", 42.5, 49.0), # 10. he hasn't moved; a drink; "Welcome to Salt Creek."
    ("title", 49.0, 60.0),    # 11. black, then SALT CREEK
]

# Beats (seconds) the animation and the sound share.
BEAT = {
    "ace_slide": 14.6,
    "eyes_lift": 21.6,
    "music_cut": 22.8,
    "rise": 23.6,
    "kick": 26.3,
    "draw": 31.25,
    "flash": 37.42,       # the shot (the aim shot's last two frames)
    "toast": 45.6,
    "line": 46.0,         # "Welcome to Salt Creek."
    "title_black": 49.0,
    "title_in": 50.0,
    "end_fade": 58.4,
}

# Picture fades: (start, end, from, to) in brightness.
FADES = [
    (0.0, 1.6, 0.0, 1.0),
    (48.6, 49.0, 1.0, 0.0),
    (49.0, 50.0, 0.0, 0.0),
    (50.0, 51.4, 0.0, 1.0),
    (58.4, 60.0, 1.0, 0.0),
]

# Sound: (file in assets/cinematic/audio without .mp3, at s, gain dB, from s in the file, length s or None,
# fade-in s, fade-out s). The score is cut in two: its opening under the table and its end under the title.
CUES = [
    ("sfx_room", 0.3, 7.0, 0.0, 22.6, 1.5, 0.4),
    ("music_score", 0.0, -6.0, 0.0, 22.8, 2.0, 0.25),
    ("sfx_shuffle", 1.2, -4.0, 0.0, None, 0.0, 0.2),
    ("sfx_ace", 14.6, -2.0, 0.0, None, 0.0, 0.1),
    ("sfx_clock", 22.7, -6.0, 0.0, 8.0, 0.3, 0.0),
    ("sfx_clock", 30.7, -6.0, 0.0, 6.7, 0.0, 0.3),
    ("sfx_kick", 26.25, 0.0, 0.0, None, 0.0, 0.3),
    ("sfx_coins", 26.9, -3.0, 0.0, None, 0.0, 0.5),
    ("sfx_draw", 31.15, -1.0, 0.0, None, 0.0, 0.2),
    ("sfx_shot", 37.42, 2.0, 0.0, None, 0.0, 1.5),
    ("sfx_room", 40.0, 0.0, 5.0, 8.5, 2.5, 1.0),
    ("sfx_drink", 45.5, -9.0, 0.0, 1.2, 0.0, 0.3),
    ("voice", 46.0, 1.0, 0.0, None, 0.0, 0.1),
    ("sfx_title", 50.0, -2.0, 0.0, None, 0.0, 1.0),
    ("music_score", 50.0, -4.0, 51.25, 8.75, 0.05, 1.6),  # the score's own hit (51.5 s in it) on the title
]

VOICE = "voice_welcome_bill"


def frame(t):
    return int(round(t * FPS))


def shot_at(f):
    t = f / FPS
    for name, a, b in SHOTS:
        if a <= t < b:
            return name
    return SHOTS[-1][0]


def frames_of(name):
    for n, a, b in SHOTS:
        if n == name:
            return frame(a), frame(b) - 1
    raise KeyError(name)
