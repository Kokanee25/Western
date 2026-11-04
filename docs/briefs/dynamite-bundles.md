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

A probe (one bundle a bent, the bottom story's two inner posts, 1.2 m apart, faces 0.9 m apart;
the blast's own rules):

| Where | Sticks | Cut |
|---|---|---|
| midway between the two inner posts (0.45 m off each face) | 2, 3, 4, 5, 6, 8 | **neither** |
| on one inner post's inner face | 3, 4, 6, 8 | **that post only** |
| on a post's outer face | 1 | none |
| on a post's outer face | 2 | that post |

So **a bundle takes the post it's on, and no more**, however big. That's how timber cutting
works: the US Army's timber-cutting rules (FM 5-25, *Explosives and Demolitions*, 1967; FM 5-250
later) are for charges **in contact** (external, P = D²/40 lb of TNT, D the least dimension in
inches; internal, in bored holes, D²/250); a charge off the face does far less.

**But our posts cut easily by that rule:** for a 12 in post the external rule is 3.6 lb, ~1.6 kg
of TNT, **eight sticks**; our blast cuts it with two (0.4 kg). The manual's figure is written to
make sure of the cut every time, so the real least is lower, but by its numbers the game's timber
gives way about four times too easily. (Sean's call 4 on #638 asks the same: keep, or tougher.)
Making timber tougher changes every wall in town too (a stick's crawl hole, three a doorway), so
it's proposed as its own call, not done here.

What that means for 2-3 bundles on the trestle (from the trestle lab's round 1, #638):

- **Two bundles on a bent's two inner posts** (under the rails) is the lab's "light charge": the
  bent stands empty, and **the engine's weight brings it down under the train**. With the engine
  coming on, that's the end game in two bundles.
- A third bundle: a third post of the same bent (the outer ones are 3 m apart and out of a
  bundle's reach), or on a rail (the rail cut ahead of the gap), or a second bent's inner post.
- Bringing a bent down with no train on it takes every bottom post (8 on the tallest): more than
  the cap. The cap makes the train the finisher; that's the moment.

Bigger bundles still matter: more margin when it's set badly (higher on the post, on an edge,
on a sill), a bigger hole in a wall (three sticks a doorway, `test_dynamite`), a bigger crater,
and men further off thrown (3b).

## Proposed (for Sean)

1. **How a bundle is made:** with dynamite in hand, **R ties another stick on** (~1.5 s each, a
   wrap of cord; the bundle in your hand grows 1, 2, 3, ...), up to `bundle_max_sticks`. A bundle
   is then lit, thrown (shorter: it's heavier), set down or planted (E held) like a stick. Untying
   isn't needed. Proposed: **up to 8 sticks** (the Army's charge for a 12 in post, if timber is
   made tougher); with today's timber **4 is plenty** (twice what cuts a post).
2. **The cap:** 3 bundles armed at once (`max_bundles`; wired to the machine, or with matched
   fuses running). A count of bundles, not sticks: a bundle is one charge to place and fire.
3. **How many you carry:** today 6 sticks. Three bundles of four is 12. Proposed: `sticks_carried`
   12 for the end game (the mission hands them over); 6 elsewhere until there's a store to buy them.
4. **How they fire together**, the main call:
   - **(A) Matched fuses.** The first bundle's fuse lit starts a clock (`fuse_window`, proposed
     30 s); each bundle lit after it has its fuse cut to finish at the same moment, as a blaster
     cuts fuses to length. Safety fuse burns to within about ±10% of its rate, so they go off
     within a few tenths of a second of each other, not on one tick (which also spreads the
     frame's work). Cheap to build; but you must be at the charges to light them, 30 s or so
     before they go, so timing it to a moving train is a guess.
   - **(B) A blasting machine** (a plunger box and a reel of wire). Period-correct for 1882: H.
     Julius Smith's magneto-electric blasting machine was patented 12 March 1878 (US 201,296),
     sold by Laflin & Rand; electric caps fired together from a battery were used on the Hoosac
     Tunnel (1860s-1875). Each planted bundle gets a cap and is wired as you walk away from it
     (the wire lies on the ground behind you, up to `wire_length`, proposed 150 m); set the box down
     (E) and push the plunger (E held 0.3 s): **every wired bundle goes off at once**. You watch
     the train from the box and pick the moment. More to build (the box, the wire drawn on the
     ground, cut by a blast or a man's spur), and the box and wire are things to carry.
   - **Recommended: (B), with fuses still on every bundle** (light one by hand as now when you
     don't need the box). The end game is timing to the train; only the plunger lets you.

## How it's judged

- Tests: a bundle is its sticks' kg; tied one stick at a time to the cap; planted, it cuts a 12x12
  post; 2-3 fire on the same moment (or within the fuses' spread for A); the cap holds; a save keeps
  a planted, unfired bundle (where, how many sticks, what it's on, its wiring or fuse).
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

- 2026-11-04: brief; the probe above (a bundle takes the post it's on). Questions to Sean.
