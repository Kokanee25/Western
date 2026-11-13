# The Red Garter: the dancer's number

Sean, 2026-11-13: "something provocative for the dancer - maybe just piano and fiddle at most since that
will be what's at the saloon the first night". An original in two parts, fiddle and piano:
- the habanera (`fiddle/tunes/red_garter_habanera.abc`, D minor, 2/4, quarter 66, ~46 s): the fiddle with
  slides and vibrato (`player.vibrato_cents` 14, `common.string_controls`), the piano's habanera left hand
  (`piano.STYLE = "habanera"`) and no melody (`piano.MELODY = False`, `band.py --piano-accompany`);
- the galop (`fiddle/tunes/red_garter_galop.abc`, D, quarter 150, ~27 s), the piano's oom-pah.
Joined with a breath between (`whole.mp3`, 78 s). The fiddle in tune: 93% of the habanera's notes (with
vibrato) and 99% of the galop's within 30 cents.
