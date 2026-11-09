# The mission judge

A fixed rubric for scoring a mission card, the same every run, so scores compare across missions and
over time. Sean's ask (#739, 2026-11-09): "a mission idea and execution judge to rate our missions
and give ideas to beef them up", compared fairly with AAA missions.

**What it judges:** the design on the card, not polish. A shipped AAA mission is also its voice
acting, set dressing and polish, which a paper card can't show; a 4 here means "the design is as
strong as the references that scored 4", not "it will feel as good". The play test decides in the
end (#739: a mission is done only after it's been played).

**What it never does:** rewrite the mission, copy a reference's content, or put anything on a card.
Its ideas go to Sean as a list; only the ones he picks go on a card, as his, with the date.

## The seven criteria (1–5)

Score each with one line saying why, and name the **nearest reference** from the shelf
(`references.md`, scored below) for that criterion: "choices 4, about Lady Boyle". Score what the
card says the mission is. A line marked OPEN or a section left empty counts as missing, not as the
best version of it. Half points are not used.

### 1. Choices: the real number of different ways

How many ways through that genuinely differ (tools, route, approach, outcome), and whether there's a
big choice with a real cost and no clean answer.

| | |
|---|---|
| 1 | One path. Variation is cosmetic. |
| 2 | Two ways that converge on the same result, or a choice with no real cost. |
| 3 | Two or three ways that really differ, **or** one real choice with a cost, not both. |
| 4 | Several ways that differ in approach **and** a big choice with a real cost. |
| 5 | Many ways that come out of the systems (not only the ones listed), **and** a choice that has no clean answer and can't be undone. |

### 2. Systems over scripts

Does the situation get set up and the systems play it out, or is it a script with systems
decorating it?

| | |
|---|---|
| 1 | The outcome is authored; the player triggers steps. |
| 2 | Scripted beats with systemic fights between them. |
| 3 | Systems carry the action, but the turns and the outcome are scripted. |
| 4 | Set up as a situation; systems decide most outcomes; a few authored beats. |
| 5 | People, props and a reason are placed; everything after is systems; any interference is handled because nothing depended on a script. |

### 3. Consequences the world remembers

| | |
|---|---|
| 1 | Nothing persists after the mission. |
| 2 | A flag changes a line or two later. |
| 3 | A later scene, mission or ending changes. |
| 4 | People, factions and places carry it, and later missions play differently. |
| 5 | The world visibly holds it (bodies, ruins, people changed toward you, a thread taking another course), and it's carried by systems, not hand-written branches. |

### 4. Unique (among other games, and among our own missions)

| | |
|---|---|
| 1 | A stock mission of the genre, and a twin of another of ours. |
| 2 | Familiar from other games; overlaps strongly with one of ours. |
| 3 | A familiar setup with one fresh element; little overlap with ours. |
| 4 | Something rarely done, or a familiar setup turned by a mechanic nobody else has. |
| 5 | Not seen elsewhere, and no overlap with ours. |

### 5. True to 1882

| | |
|---|---|
| 1 | An anachronism or a cliché that breaks the period. |
| 2 | Western-movie generic; the period is set dressing. |
| 3 | Plausible for 1882, not specific to it. |
| 4 | Rooted in documented practice (law, work, tools, money), people written as people. |
| 5 | Could only happen in that time and place; its people and their reasons come from the record. |

For the references, judge "true to its own setting" by the same scale.

### 6. Discoverable

Will players find the mission, and its showpiece, without a marker? (#738's worry: "I just don't want
all these ideas to go to waste if the player doesn't know it's an option.")

| | |
|---|---|
| 1 | Needs a marker, or one person telling you exactly what to do. |
| 2 | One way to hear of it; the showpiece only if told. |
| 3 | Heard of one way; the showpiece is findable by those who look. |
| 4 | Several ways to hear of it; the place shows the showpiece plainly. |
| 5 | The world brings it to you in more than one way, and the showpiece reads from the place itself even if its hint-giver is dead. |

### 7. Cost to build (5 = cheap)

Scored so that higher is better: what it needs that doesn't exist, and whether that's shared with other
missions or a one-off. For our missions use the card's systems section and the systems table's state
words (exists, partly, being built, decided, new). For the references, judge it against the studio's
own shared systems (how much was bespoke for this one mission); it's the least comparable criterion.

| | |
|---|---|
| 1 | Several new systems that only this mission uses. |
| 2 | New systems, mostly one-off. |
| 3 | Some new systems, mostly shared with other missions. |
| 4 | Mostly existing systems, one or two shared new ones. |
| 5 | Almost everything exists; the mission is placement and data. |

## Calibration (the reference shelf scored)

Scored before any of ours, by a fresh agent that saw only the rubric and `references.md` (2026-11-09).
Every later run is anchored on these: a 4 means "as good as the references that scored 4".

CALIBRATION

## How a run works

1. One **fresh sub-agent per mission**. It sees only: the mission's card, this file (with the
   calibration), `references.md` and `STORY.md`. Not the other cards, not the other judgments, not
   the map.
2. It writes, for that mission:
   - the seven scores, each with one line and the nearest reference;
   - **what the references do that this doesn't** (two or three lines, the biggest gaps);
   - **2–3 ways to beef it up**, drawn from those gaps, in our world and our systems, never a
     reference's content;
   - **1 thing to cut or simplify** (required);
   - the total (out of 35), for ranking only.
3. Results go in `judged/<date>.md`, one section a mission, with a header saying what was judged and
   repeating the limit (design to design, not polish).
4. Sean reads them and picks. Only his picks go on a card, as his, with the date.

### The prompt (paste with the four files)

```text
You are the Salt Creek mission judge. Read docs/missions/JUDGE.md (the rubric and the calibration),
docs/missions/references.md (the scored reference shelf), docs/missions/STORY.md (the one-page
story) and the one mission card you're given. Read nothing else in the repo.

Score the card on the seven criteria exactly as the rubric says, anchored on the calibration scores:
for each criterion give the score, the nearest reference by name ("choices 4, about Lady Boyle"),
and one line why. Score only what the card says; OPEN or empty counts as missing. Then: what the
references do that this mission doesn't (2–3 lines); 2–3 ways to beef it up, in Salt Creek's world
and systems, never copying a reference's content; exactly 1 thing to cut or simplify (required);
the total out of 35. Don't rewrite the mission. Don't edit any file. Reply in this exact form:

## <Mission name> (`<id>`)
| Criterion | Score | Nearest reference | Why |
|---|---|---|---|
| Choices | n | ... | ... |
| Systems over scripts | n | ... | ... |
| Consequences | n | ... | ... |
| Unique | n | ... | ... |
| True to 1882 | n | ... | ... |
| Discoverable | n | ... | ... |
| Cost to build | n | ... | ... |
| **Total** | **n/35** | | |

**What the references do that this doesn't:** ...
**Beef it up:** 1. ... 2. ... (3. ...)
**Cut or simplify:** ...
```
