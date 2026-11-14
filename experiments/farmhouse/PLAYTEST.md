# Playtest: the farmhouse

Read `tools/playtest.md` first (how to start the game, the commands, the report). This brief
replaces its "What to try": play **one mission** instead of the street.

**The mission.** Outlaws are holding a rancher hostage at his farmhouse, out east of town along
the road. You get in, cut him loose and get him out alive. Nobody tells you how; find out by
playing.

**How it starts.** The game starts in town by the livery. A man there (the blacksmith) wants a word:
walk up to him (`walk blacksmith`) and listen (`events 10`). When he's done, a line on screen
tells you what's going on; it's in the events too.

**Getting there.** The farm is east along the road out of town, up on a rise north of the road
(`read places` lists `road_farm`, `farm_lane` and other places round the house). Walk, or `goto`
somewhere short of it to save time, but come up to the house the way a player would.

**Two tries, two ways in.** Play it twice, going in a different way each time:

1. **The obvious way:** up to the front and in at the front door.
2. **Another way:** round the side or the back, quietly (crouch: `press crouch_toggle`), and in
   by the back door; or blow a hole in a wall with dynamite. To plant a stick: `weapon dynamite`,
   stand right at the wall and face it about chest high, then `press shove 1.2`. That holds E,
   which sets the stick; letting go lights it. Then get well clear: it goes off in 5 seconds.

When you reach the hostage, holding E by him cuts him loose (`press shove 2`). After that, get
him out and away from the house.

If it goes wrong (he's killed, or you go down), a line on screen says so. `press ui_accept`
(Enter) starts it again from the edge of town. Use that for your second try too, if you need it.

**What to report**, besides `tools/playtest.md`'s questions:
- Did you understand what to do, and how? Where were you confused?
- How did the outlaws behave before they knew you were there, when they found out, when you came
  in? Did they feel like men holding a house?
- The hostage: did you hear or see him? What did he do once he was free?
- Was it too hard, too easy, fair? What killed you, or him?
- What was fun? What was wrong with it?

Write the report to `docs/playtests/<date>-farmhouse.md`.
