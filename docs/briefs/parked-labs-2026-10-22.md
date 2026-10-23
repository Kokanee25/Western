# The labs, parked (2026-10-22)

Sean, 2026-10-22: the labs have done their first jobs and are burning the usage. They're parked
here, each where it stands, so any of them can be picked up later from this page. **Focus now: the
card cheat playable in the saloon, and finding out if the shooting is fun** (see "What's next" at
the end).

How to pick a lab up later: its **`next session`** issue holds a ready-to-paste prompt for a fresh
session. Where a lab has no such issue, the "Pick up" line says what to paste. Read the open
`waiting on Sean` issues first, as always.

## Where each lab stands

| Lab (lane) | Done so far | Open PR (state on 2026-10-22) | Waiting on Sean | Pick up with |
|---|---|---|---|---|
| **Gunfight lab** (3.0, gameplay) | Bench, baseline, three fixes as the gang's variants A/B/C, playable on Y/X/Z (#254) | #277 the perception fix measured, fairness check widened (lab only) | **#257 play the nine A/B/C runs** (the fun question) | After #257: cover in the saloon and the cover-on-arrival fault |
| **Perception lab** (gameplay) | Bench, baseline, fix 1: a heard sound doesn't name its maker (#263) | none | none | `next session` **#267** (fix 2, lamplight at night) |
| **Sound lab** (gameplay) | Brief, baseline, changes 1–4 merged: gunshots with weight, passes and strikes by surface, dynamite near and far, breaking placed and a voice limit (#246, #256, #261, #269) | #278 change 5: fire by size, footsteps on boards and dirt | **#264 listen to the new sounds** (and: should a .45 ball snap?) | After #278: the lab's README lists what's left |
| **Gun lab** (gameplay) | Bench and baseline | #248 bench and baseline (changes nothing in the game) | #221 play and agree the feel ranges | `next session` **#274** (the hands and the gun metals painted) |
| **Body and gore lab** (3.1b, gameplay) | Bench, baseline, fixes, the gore lab's first round (#167, #215) | #241 painted face wounds, the sling, singed hair, ten wounded men cheaper | #220 dynamite up close; how long a gut shot takes | After #241: the lab's README "next" |
| **Ragdoll lab / falls** (3.1, gameplay) | Four rounds of falls, railing, the chair kick-out (#204, #211) | #238 arms-out brace; #250 getting up (stacked on #238) | **#239** the brace, **#251** getting up | `next session` **#272** (the collapse at a stair's head) |
| **Breakage lab / dig-able ground** (3.3a, gameplay) | Bench, baseline, blast near field, boards cut, the blast's look, ground tiles, take and put, the crater, walking round holes (#235–#255) | none | #227 three paper sites (optional) | `next session` **#266** (step 5, the ground built natively) |
| **Building lab** (gameplay, art) | The saloon from its spec, walkable on F5 | #262 the spec and the saloon (Sean: "merge this so we can start testing") | none | After #262: the brief `docs/briefs/building-pipeline.md` |
| **Prop lab** | Chair, card table, bottle, oil lamp in the game (#213, #232) | #280 barrels, crates, stools, wall props, fixtures, the piano | none | `next session` **#281** (what props hold: leaking barrels, the spittoon, the tin cup) |
| **Barkeep's chores** (gameplay, prop lab) | The rag and wiping the bar (#260) | #282 mopping: the mop, the bucket, what's on the floor | #258 up to $0.30 to paint the cloth | After #282: idea #276 (life details) |
| **Town life: men sitting** (gameplay) | | #270 Seating, a seated drink, Brody at the card table (changes what the gang does in the saloon) | Sean's OK on #270 | Needed by the card cheat |
| **Material lab** (1.4a, art) | Rounds 1–7; Sean picked 6b: the game's exterior woods (#268) | none | none | `next session` **#273** (round 7a, the texture memory test) |
| **Fire** (art) | Flipbook fire the default (#216, #268) | #244 fire through the roof and out of the openings | none | After #244: firelight's look (step 5) |
| **Characters: faces and talking** | Faces alive (#252), fingers on eight men (#236) | #275 mouths say their lines | #224 record three face takes; #222 recipe route (finger bones answered) | After #275: the lip-sync takes |
| **Characters: old PRs** | | #103, #155, #156 (from 2026-10-12 to 10-20) | in #222: keep, merge or close | |
| **Docs** | | #265 stop at the end of your step; #271 the night's status | none | Merge both |

Ideas for later (labelled `idea`): **#259** coffins, burial and graves dug up; **#276** life details
(45 of them), the town's calendar (freight, stage, payday), its services and the deadfalls.

## Before the labs stop

Every running lab: finish the step it's on, push, write its status entry, open its `next session`
issue, then stop (CLAUDE.md "Stop at the end of your step", PR #265). Don't start anything new.

## What's next: the card cheat and the shooting

Two questions, answered by playing, not by building more systems:

1. **Is shooting fun?** Sean plays the gunfight lab's nine runs in the saloon (issue #257: Y, then
   the scoring in `experiments/gunfight_lab/PLAYTEST.md`) and agrees or changes the gun feel
   (#221). This needs no session, only a build and his evening.
2. **The card cheat, playable** (one gameplay session, the prompt below). Most of its parts are in:
   the kit chair and card table, the chair kick-out (#204), bottles that shatter (#232), the falls
   and wounds, the hand to the wound, the barkeep's chores. It wants #270 (men sitting) and, ideally,
   #238 and #250 (the brace and getting up) merged first.

Prompt for the card cheat session:

```
Gameplay lane, branch claude/gameplay-card-cheat. Make the card cheat playable in the game's saloon: docs/briefs/showcase-moments.md, "The card cheat" (with the punchline rule), and docs/briefs/parked-labs-2026-10-22.md "What's next". Read them, docs/PARTS.md, and the open "waiting on Sean" issues first. Merge main first; if #270 (men sitting) isn't merged, ask me rather than redoing it.

Use only parts in the game: the kit chair and card table, the seating, the seated falls and kick, the bottles, the falls, wounds and gore, the hand to the wound, deeds and the escalation ladder, the barkeep's rag and mop. A man at the card table; the victim walks in angry, kicks the chair's back legs out, the cheater goes over backwards, the victim stands over him, draws, shouts and puts the gun in his mouth; the player has a few seconds. Every way out works by the systems, not a script: shoot him (the ball can carry on into the man on the floor), shout or draw so he turns on you, shove him, throw a bottle, shoot his gun hand, or do nothing. Afterwards the room reacts by what each person saw, and the barman's first words are about his chair, named at whoever broke it (the owners rule); then he cleans up. Set it up as data (who, where, why), triggerable from the dev bridge and a key, placed in the saloon at a time of day.

The playtest agent plays it blind ten times first and reports what happened each time. Then give me a build with exactly how to start it and what to try. Stop at the end of the step (CLAUDE.md).
```

After both: if the shooting isn't fun yet, the gunfight lab picks up from #257's answers; if it is,
roadmap 3.5 (Acts: missions written as data) is next, so the card cheat becomes the first scene
written in it.
