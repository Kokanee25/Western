# Dynamite bundles, fired together (#647; #596 step 7)

Sean, 2026-11-04, after the trestle lab (#623): "we need to be able to blow that bridge and rail up
... what I want for end game is bundles of tnt and able to detonate multiple (maybe max 2-3)
bundles at the same time". Gameplay lane. Sean's calls: the `waiting on Sean` issue linked at the
end (the firing, the bundle's size, the cap, how many you carry).

## The goal

You tie sticks into a bundle, plant up to 2-3 bundles (on a post, a wall, the rail), and set them
all off at once. End game: the trestle and its rails come down with 2-3 bundles as the train comes
on. Tested on Main Street first, then on the trestle.

## What's there (extended, not duplicated)

- `DynamiteStick` (src/blast/dynamite_stick.gd) already carries `kg` ("one stick; a bundle is
  more"): a bundle **is** a DynamiteStick of N sticks (`sticks`, `kg` = N x `tnt_per_stick`), drawn
  as N sticks tied, one fuse. Thrown, planted (`stick_to`), shot, set off by a blast near it
  (`sympathetic_kpa`) as a stick is.
- `DynamiteViewmodel`: throwing, planting with E held (#506), the fuse lit on letting go.
- `Blast.detonate` / `torn_stretch` / `effective_kg`: what a charge cuts comes out of its kg and
  where it sits. **No special case for a bundle.**
- The trestle lab fires "bundles" in code (`collapse.gd`, `sticks=N` a post).

## What a bundle does (measured 2026-11-04, main's 66 m viaduct)

Probes on the bottom story's posts (12x12 in; the two inner ones 1.2 m apart, faces 0.9 m apart),
by the blast's own rules (`tests/test_dynamite_bundles.gd` holds the last table):

| Where | Sticks | Cut |
|---|---|---|
| midway between the two inner posts (0.45 m off each face) | 2, 3, 4, 5, 6, 8 | **neither** |
| centre 6 cm off one inner post's inner face | 3, 4, 6, 8 | **that post only** |
| centre 5 cm off a post's face (the trestle lab's spot) | 1 / 2 | stands / cut |
| **touching a post, as E plants it** (any face, 0.3, 0.6 or 1.2 m up) | **1** | **cut, 12 of 12** |

So **a charge takes the post it's on, and no more**, however big; and **one stick planted on a
post cuts it**. The trestle lab's "one doesn't, two do" (#638) was 5 cm off the face: the cut
falls away that fast with the gap. That locality is how timber cutting works: the US Army's
timber-cutting rules (FM 5-25, *Explosives and Demolitions*, 1967; FM 5-250 later) are for charges
**in contact** (external, P = D²/40 lb of TNT, D the least dimension in inches; internal, in bored
holes, D²/250); a charge off the face does far less.

**But our posts cut far too easily by that rule:** for a 12 in post the external rule is 3.6 lb,
~1.6 kg of TNT, **eight sticks**; our blast cuts it with **one** in contact (0.2 kg). The manual's
figure is written to make sure of the cut every time, so the real least is lower, but by its
numbers the game's timber gives way several times too easily. **With timber as it is, bundles
aren't needed on the trestle at all** (three single sticks and the engine bring a bent down), so
the timber call decides what a bundle is for. Making timber tougher changes every wall in town
too (a stick's crawl hole, three a doorway: Sean's feel calls), so it's its own call (#638's call 4
asks the same), measured in the breakage lab, not done here.

What that means for 2-3 bundles on the trestle (from the trestle lab's round 1, #638):

- **Two bundles on a bent's two inner posts** (under the rails) is the lab's "light charge": the
  bent stands empty, and **the engine's weight brings it down under the train**. With the engine
  coming on, that's the end game in two bundles.
- A third bundle: a third post of the same bent (the outer ones are 3 m apart and out of a
  bundle's reach), or on a rail (the rail cut ahead of the gap), or a second bent's inner post.
- Bringing a bent down with no train on it takes every bottom post (8 on the tallest): more than
  the cap. The cap makes the train the finisher; that's the moment.

With today's timber a bundle only buys margin (set a few cm off, on an edge or a sill), a bigger
hole in a wall (three sticks a doorway, `test_dynamite`), a bigger crater and men thrown further
(3b). **If posts are made as tough as the manual says, a 12x12 needs a bundle of ~8**: one bundle
a post, three posts the cap, which is the game Sean described.

## What Sean picked (#648, 2026-11-04)

"Can we make it a mini game to actually build bundles - you need to prep them first - doesn't need
to be a big ordeal - but maybe it takes 10-15 seconds of holding down a key to bundle it - I don't
want the tying bundles together to the same plunger to explode at the same time to be an ordeal
though - it doesn't need to be messy". So:

1. **Making a bundle:** with dynamite in hand, **R held `make_time` (12 s)** ties `bundle_sticks`
   (4) of your loose sticks into a bundle; the sticks gather into your hand as you go. Let go early
   and the work's kept. **R tapped** puts a stick or a bundle in your hand. A bundle is lit, thrown
   (shorter: it's heavier) or set down like a stick.
2. **Firing: a plunger box (B), with no wiring to do.** A bundle planted with E is capped and wired
   to your box as it's set (a cap and a wire's tail drawn on it); it waits unlit. **5** brings out
   the box; **fire held** pushes the handle home over `push_time` (0.35 s) and every wired bundle
   goes, one a physics tick (`fire_spread_ticks` 1: the same moment to the eye, each blast's work on
   its own tick). Let go short and nothing goes. Period: H. Julius Smith's magneto-electric blasting
   machine, patented 12 March 1878 (US 201,296), sold by Laflin & Rand; electric caps fired together
   from a battery on the Hoosac Tunnel (1860s-1875). A match aimed at a planted bundle (Q) lights its
   fuse instead.

The rest (#648, answered the same day): **four sticks a bundle, three bundles waiting at once,
twelve sticks carried**; **timber tougher**, so that a bundle of four cuts a 12x12 post and fewer
sticks don't (one bundle a post), in a breakage-lab step of its own with the town's wall holes
re-measured (one stick a crawl hole, three a doorway kept); and **merge now**, the cost of a big
blast cut in the next session.

## How it's judged

- Tests (`tests/test_dynamite_bundles.gd`): a bundle is its sticks' kg; R held makes one (the work
  kept), a tap switches; planted it's wired and unlit, a match lights it; the cap holds; the plunger
  sets every wired bundle off within a tick each and leaves loose sticks; a save keeps a planted,
  wired bundle; on the trestle a charge cuts the 12x12 post it's on and not its neighbour.
- **#492's gate** with 2-3 bundles together, on Main Street and on the trestle: one hitch under
  ~100 ms at Sean's (x0.65), back above 50 fps within 0.5 s. The trestle lab's slow spell was 8-24
  bundles inside 0.4 s; 2-3 are fewer. If they go off on one tick, their work is spread (a tick
  each, Blast's slices, SpawnQueue), never what's seen.
- Films (Movie Maker): 2-3 bundles on Main Street; on the trestle as the engine comes on, from the
  floor and the rim. The frame table against the gate.

## Not in this step

How a blast looks and feels (steps 2-6), the dust cloud, the trestle's size (PR #646, Kwai size),
rope (the wire is drawn, not simulated), buying dynamite.

## Log

- 2026-11-04: brief; the probes above (a charge takes the post it's on; one stick in contact cuts
  a 12x12). Questions to Sean (#648). Built: the bundle (tied with R, its kg, the model), planted
  unlit and lit with a match aimed at it, the cap, the save. Sean's answer (same day): R held ~12 s
  makes a bundle; a plunger box (5) fires every planted bundle, wired as it's planted.
