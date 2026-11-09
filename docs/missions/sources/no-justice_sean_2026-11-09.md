# Salt Creek: Mission card, No Justice

**Status:** DECIDED by Sean, 2026-11-09 (his mission write-up plus the master chat's changes, which he accepted that day). Lines marked **OPEN** are not settled.
**Replaces:** DESIGN.md story mission 1, "The camp". Its third ending (take the man past the town to a marshal or circuit judge) is **dropped on purpose**: two endings, not three.
**Estimated length:** 25–35 minutes.

## Premise
Harlan rides with Joe, a Southern Ute widower, to hunt down the gang that raped, murdered and scalped his wife. The mission ends in a choice: let Joe take his revenge, or enforce a law that almost certainly won't punish the murderer.

## How you hear of it
Harlan meets Joe at **the doctor's office in Salt Creek**. There's no quest marker: it's a man in grief in a room you walk into.

## Where on the map
- **Salt Creek:** the doctor's office, the jail, Main Street.
- **Joe's camp:** the Southern Ute community, north-west of town (`config/valley.json`).
- **The bandits' hideout:** a secluded wooded spot in the foothills, with a main cabin on rising ground and a hillside above it to watch from. It's one of the places with height (#736).

## The beats

### 1. Learning about the murder (town)
- Harlan meets Joe at the doctor's.
- Joe's wife was murdered and scalped in a raid on their camp while the men were away hunting. Joe wants the men who did it.
- **The doctor warns Harlan:** even if the killers are arrested, they're unlikely to be punished.
- **The bold cowboy agrees:** the law won't give justice for an Indigenous woman.
- Harlan agrees to ride with Joe.

*Purpose: the crime, Joe's reason, and the expectation that the law will fail.*

### 2. Visiting Joe's camp
- Harlan and Joe ride to the camp. The raid's damage is still there: burned belongings, bullet holes.
- The survivors tell what happened to Joe's wife.
- **They name the main murderer by one thing: a faded red shirt.**
- They know roughly which way the raiders fled. Joe gets ready to follow.

*Purpose: make it personal, introduce the man in the red shirt, and give the gang's direction without a long investigation.*

### 3. Hunting the gang
- **Joe changes into ordinary cowboy clothes** (a hat and a neckerchief) so no one can tell he's from the camp. He says why: he doesn't want the gang's friends taking revenge on his people.
- They ride through the foothills. Joe leads, reading the ground and the raiders' trail.
- They talk a little on the way, about his wife and his want for revenge, without long stops.
- They find the gang's camp in the woods.

*Purpose: build Joe as a character, then move naturally into the fight.*

### 4. Assault on the bandit camp
- Harlan and Joe watch the camp from the hillside: **five or six armed bandits**, the man in the red shirt among them.
- **The player chooses how it starts:** creep in quietly, or open fire.
- Joe fights beside Harlan, taking cover and shooting.
- Destructible wooden cover, barrels and furniture keep the fight moving.
- **The man in the red shirt is a coward.** At the first shots (or as the fight turns) he runs for the main cabin and barricades himself in. It happens in the world, with no cutscene, and the red shirt must be plain to see as he runs.
- The rest of the bandits are beaten.

**When it goes wrong (the mission bends, it doesn't break):**
- **The player kills the man in the red shirt outside.** Joe is furious ("that was mine to take"). He goes to the body, and the scalping happens there. There's no nod moment: the player took the choice away by shooting. Joe's trust drops, but he still respects that Harlan came.
- **Joe is hit.** He goes down wounded, not dead (a companion who is down, not killed, at this point). He can be helped up, and the wound stays with him afterwards. **OPEN:** whether Joe can truly die here, which would mean his later role needs a fallback (#738 rule 2).
- **The player flees or abandons Joe.** Joe finishes it alone or dies trying. **OPEN:** what follows.

### 5. The confrontation inside
- Harlan enters the cabin with Joe close behind.
- The man in the red shirt is cornered, frightened and unarmed. He surrenders and begs to be taken into custody.
- **The player can still shoot him.** Nothing stops it. But killing a man with his hands up is murder: Joe sees it, and the world can learn of it (#738: witnesses and rumour).
- Joe walks to the prisoner and draws his knife. He makes it plain he means to kill and scalp the man who did the same to his wife.
- **Joe turns to Harlan and asks if he's going to stop him.**

**The answer is given with the nod** (DESIGN.md "Answering with a nod"): the player has to look Joe in the eye.
- **Nod (yes, I'll stop you):** Joe is held back. Harlan arrests the murderer and takes him to Salt Creek.
- **Shake (no, I won't stop you):** Harlan stands aside. Joe kills and scalps the murderer.
- **Acting counts as an answer too:** stepping between them, drawing on the man, or walking out.
- A small, slow nod reads as a reluctant yes. An unclear one gets "Is that a yes?"
- No dialogue menu, no morality meter, nothing on screen saying which answer is right.
- The killing and scalping play out on the wound system, not as a cutscene. The player can stay or walk away, and the camera never moves in (DESIGN.md).

## 6. After: the world remembers
**If Harlan lets Joe take his revenge:**
- Joe finishes it in the cabin, and they ride back together.
- Joe is quieter. Revenge hasn't magically mended his grief.
- **It doesn't stay a secret:** the gang's bodies are found, and whoever finds them carries the story to town.
  - The town splits: some say good riddance, some say a white man rode with Indians against white men.
  - The camp trusts Harlan.
  - **The bandits' kin or friends hear and come looking.** That's the trigger for the hanging (below).

**If Harlan arrests the murderer:**
- Harlan takes the prisoner to the Salt Creek jail. Joe comes along, plainly unhappy.
- The prisoner is handed on to the proper authorities.
- **Later, Harlan learns the murderer was released without real punishment.** Joe learns it too, and the doctor's and the cowboy's warnings come true. That's the mission's title.
- The camp's trust in Harlan cools. They didn't expect the law to help, and it didn't.
- **The released man comes back.** He walks free through Salt Creek, and Harlan can run into him. No new mission is needed, just a man on the street (Sean's open question, now decided: yes).

**If the player shot the surrendered man:** it's murder. Joe saw it. Who else learns of it, and the law's response, run through the witness and rumour systems.

## 7. Where it leads: the hanging
Both main endings lead to the same big moment, for different reasons. **Someone tries to hang Joe, and Harlan shoots the rope with the Winchester** (#734, #738):
- **The arrest ending:** the released murderer is in town. Joe kills him there, in front of witnesses, and the town tries to hang Joe.
- **The revenge ending:** the bandits' kin learn who rode with Harlan, come for Joe, and try to lynch him.

## 8. The end of the mission
- Either way, Joe respects Harlan for helping when the law wouldn't.
- **Joe becomes Harlan's main companion** for the rest of the game, and later the man with plans (#738, PROPOSED). How Joe treats Harlan reflects the choice, but the main story isn't changed at its root.

## Systems it needs
- **The nod** (to build first; this is its first real use).
- **Surrender:** hands up, begging, and being taken prisoner and escorted.
- **A companion who fights:** takes cover, can be wounded and down, and is helped up.
- **The knife and scalping** on the wound system (the knife is not in the game yet; PR #167 has a start).
- **Destructible wooden cover**, barrels and furniture.
- **A barricaded cabin:** a door that's blocked and a way to force it.
- **The bodies stay, are found, and carry the story** (#483 bodies; the rumour and witness systems).
- **The wardrobe:**
  - the faded red shirt (unique, and readable at range);
  - Joe's own clothes and his cowboy disguise (Studio).
- **The jail and the prisoner's transfer**, and a news item later.
- **The released man** as a living-world man in town.
- **Joe's memory of the choice**, which shapes his talk and trust later.

## Keep these three details
- **The red shirt:** plain to see in the gunfight, so the final prisoner's identity is never in doubt.
- **Joe's cowboy disguise:** it gives him personality and shows he's protecting his surviving people, not only chasing revenge.
- **The prisoner's release:** it makes the arrest ending true to the warnings and gives the mission its name.

## Design notes
- **Linear until the cabin, on purpose.** No detective work, no several hideouts, no subplots. The strength is the moral choice, not the manhunt. (A judge should score "choices" knowing this was chosen.)
- **History, handled with care** (DESIGN.md): the Southern Ute people, the camp, Joe's language and dress, and the period's law (1882: the camp's own witnesses might not be heard in court) need proper research. Scalping is shown as the act it was, never as spectacle.

## Still open
- Whether Joe can die in the gunfight, and his fallback if so.
- What happens if Harlan abandons Joe.
- Joe's past: why he knows timber and trains, if he becomes the man with plans (#738). It needs to fit a Southern Ute man in 1882; for example, work on the Denver & Rio Grande line crews is a candidate to research.
