# Brief: the three-gunman fight (gameplay; roadmap Phase 3)

Sean's brief, 2026-10-17, as he gave it, below the line. Read this note first.

**Most of this already exists.** Don't spend the session re-discovering it: check the code for what's
listed here, then work on the gaps. Already built (see `docs/LAYOUT.md` and `docs/status/`):

- **Guns:** the single-action revolver (cock, gate-load one round at a time) and the coach gun;
  sway from breathing, posture, moving and stress (`WeaponViewmodel.sway`, `PlayerComposure`: rattled,
  winded, flinch from near misses and hits); the ball leaves along the barrel; real drop and drag.
- **Impacts:** wood penetrated by thickness, members carved as voxels (cover wears away), glass
  shatters, ricochets off stone, metal and shallow ground with sparks, near-miss cracks and whizzes,
  dust and splinters (`ImpactEffects`).
- **Fire:** a shot lamp smashes and spills burning oil, fire spreads through members, simulated
  smoke, people flee fire, bucket lines.
- **NPCs:** senses (sight cones, light, hearing by loudness and walls, last-known positions with
  error, searching), cover finding with peeks, suppression, flanking, callouts between friends,
  rescue of the wounded, fear and nerve, backing down, surrender, fleeing; personalities by temper,
  nerve and pride (Brody cool, Lyle a hothead, the Kid timid).
- **Bodies:** hidden anatomy, wounds that bleed and stop men without hit points, falls that keep
  momentum (roadmap 3.1, in progress).

**The gaps against this brief, as far as is known:**
1. **Fights end too fast.** Both playtests: the gang hits first and the player is down in a
   second or two (the Kid three hits of three at 18 m). Measure fight length and who hits first
   before changing anything.
2. **NPC accuracy is a random spread** (`OutlawBrain.spread_degrees`), not the physical sway the
   player has. The brief wants misses that come from the gun's state: give NPCs the same sway model
   (breathing, moving, fear, pain, being shot at, time to settle after drawing or moving).
3. **Cues the player can hear:** NPC footsteps (porch boards vs dirt), a hammer cocked, a shouted
   warning are noises NPCs hear but the player may not. Make them sounds, placed in space.
4. **Dust:** dirt impacts thrown the right way, and enough of them to briefly hide a man.
5. **Small interactions:** furniture (roadmap 3.3), a chair leg shot out, kicking a chair aside,
   hanging things that swing.
6. **The arena and the measures:** a repeatable three-gunman setup on the existing street (the
   saloon front, porch, fence, crates; no new town), run many times by the bridge and the playtest
   agent, with numbers: fight length, shots fired and hit per side, who hits first, how often each
   man changes cover, surrenders and flights.

---

SALT CREEK — Gameplay & Immersive Simulation Development Brief

1. Core Vision

Salt Creek is a grounded, systemic Western immersive simulation set in the late 19th century, being developed in Godot.

The goal is not to build a conventional third-person shooter. We want a living, physically reactive Western world where combat is dangerous, unpredictable, deliberate, and highly interactive.

Central design principle: Every bullet should change the situation, even when it misses.

Combat should produce emergent stories through the interaction of physical environments, intelligent NPCs, gun mechanics, and player decisions.

The player should feel that they survived a dangerous gunfight through observation, improvisation, positioning, and skill — not because they depleted enemy health bars.

We are prioritizing believable systems that create enjoyable gameplay over absolute realism.

⸻

2. Gunfight Design

Small numbers of enemies

Most encounters should involve approximately 2–5 armed opponents, not waves of enemies.

An individual gunfight should be capable of lasting approximately 45–90 seconds through meaningful gameplay, although faster resolutions must remain possible.

Do not artificially lengthen combat through inflated health pools, invulnerability, or scripted waiting.

Instead, create duration through:

* Enemies seeking and changing cover.
* Uncertain enemy locations.
* Deliberate aiming and weapon handling.
* Reloading and ammunition management.
* Flanking and repositioning.
* Destructible cover and changing environmental hazards.
* NPC fear, hesitation, suppression, retreat, and surrender.
* Interruptions in visibility caused by dust, smoke, obstacles, and movement.

Gunfights should alternate between short bursts of extreme violence and tense periods of uncertainty.

A single well-placed shot can end a confrontation. This is intentional.

Responsive controls, deliberate actions

The character should never feel artificially sluggish.

Movement, camera control, and input response must feel precise. Physical commitment comes from weapon handling, animations, inertia, recovery, and exposure to danger.

We want weight and physicality without frustrating input delays.

⸻

3. Weapon Accuracy — A Critical Requirement

Bullets must not miss simply because a random accuracy percentage says they should.

Accuracy should emerge from the physical state of the weapon and the shooter’s ability to stabilize it.

Proposed mechanics:

* Natural weapon sway from breathing and posture.
* Increased instability while moving.
* Increased instability under physical stress or incoming fire.
* Recoil and recovery after firing.
* Disturbance from nearby impacts, injury, or sudden movement.
* Aiming down sights improves stability but does not guarantee accuracy.
* Hip firing is quicker but substantially less stable.
* Rushed trigger inputs may disturb the weapon’s alignment.

Projectile direction should follow the actual barrel orientation at the moment of discharge.

Do not use arbitrary randomized bullet spread as the primary difficulty mechanism.

The player should be able to understand why a shot missed.

Weapon sway must be visible, consistent, learnable, and controllable through player skill. Stress effects should not overwhelm player agency.

Historical firearm handling should be considered, including single-action revolver cocking and loading individual cartridges where appropriate.

⸻

4. Bullet Impacts and Environmental Feedback

Every gunshot should produce convincing physical and audiovisual consequences.

Dirt and terrain

* Bullets striking nearby dirt produce localized dust eruptions.
* Dirt and debris should be thrown in a direction consistent with impact.
* Close impacts feel threatening through sound, particles, and environmental feedback.
* Repeated gunfire may temporarily obscure sightlines.

Wood and cover

* Bullet impacts create splinters, chips, and visible damage.
* Different materials react according to their physical properties.
* Wooden cover may progressively deteriorate.
* Boards, posts, furniture, and other structures can break where appropriate.
* Some bullets penetrate thin wood; heavier cover provides greater protection.

Cover should not always be permanent safety.

Glass, metal, and props

* Glass can shatter.
* Metal impacts produce appropriate sparks, sounds, and deflections.
* Bottles and fragile objects break.
* Hanging objects can swing.
* Objects can fall, topple, or shift from physical forces.

Fire and environmental hazards

An important example is shooting an oil lantern.

A successful hit might:

1. Break the lantern.
2. Spill burning fuel.
3. Ignite nearby combustible materials.
4. Produce increasingly heavy smoke.
5. Force NPCs to abandon positions.
6. Potentially spread fire to other objects.

This should be implemented through reusable environmental systems rather than a bespoke scripted cinematic.

Not every object needs to be fully destructible. Prioritize meaningful interactions and convincing physical responses.

⸻

5. NPC Combat Intelligence

NPCs must behave like people trying to stay alive, not stationary targets programmed to attack the player.

Perception

NPCs should only react to information they can reasonably perceive.

Relevant inputs include:

* Direct line of sight.
* Gunshot direction and approximate origin.
* Footsteps and movement sounds.
* Nearby bullet impacts.
* Visible muzzle flashes or smoke.
* Another NPC shouting information.
* Seeing a companion injured or killed.
* Physical changes to cover or the environment.

NPCs must not automatically know the player’s location once visual contact is lost.

Their knowledge should have uncertainty.

Self-preservation

NPCs should be able to:

* Seek cover.
* Duck when incoming fire threatens them.
* Return fire from relative safety.
* Move between protective positions.
* Flank the player.
* Retreat when outmatched.
* Hesitate or panic.
* Surrender.
* Flee.
* React to the death or injury of an ally.
* Abandon cover that becomes dangerous.

NPCs should have different personalities and levels of courage, aggression, and competence.

A frightened amateur should behave differently from a seasoned gunfighter.

Combat readability

The player should have a fair opportunity to understand enemy movements without receiving magical information.

Examples include footsteps behind a building, a boot scuffing across a porch, a shouted warning, a gun being cocked, or muzzle smoke revealing a concealed shooter.

Uncertainty should create tension, not arbitrary punishment.

⸻

6. Physical Character Reactions

Bodies should react convincingly to bullets, collisions, and environmental forces.

Avoid generic ragdolls that simply buckle vertically when shot.

Desired features include:

* Animation-to-ragdoll transitions.
* Physical momentum carried into falls.
* Different reactions based on posture, movement, and impact circumstances.
* Characters stumbling, collapsing, or losing balance.
* Bodies interacting with furniture, walls, and other objects.
* Wounded characters potentially remaining mobile depending on injury severity.

Do not implement unrealistic knockback from bullet impacts.

The objective is grounded, physically plausible behavior, not exaggerated action-movie physics.

Hits should have meaningful consequences without relying on conventional bullet-sponge health systems.

⸻

7. Immersive Simulation Features

Salt Creek should ultimately support interconnected systems that allow player experimentation.

Physical interactions

The player and NPCs should follow consistent environmental rules.

Examples:

* Kick a chair aside or use a table for temporary cover.
* Shoot a chair leg and cause the chair to collapse.
* Push an object into someone’s path.
* Break a window to create an alternative entry or escape.
* Shoot through a thin wooden door.
* Extinguish or destroy light sources.
* Create environmental hazards as distractions.

Multiple solutions

Encounters should not require violence.

Possible approaches include talking, negotiation, intimidation, stealth, distraction, escape, or direct combat.

Persistent consequences

As development progresses, the world should remember significant actions.

NPC deaths, damage to buildings, crimes, witnesses, relationships, and reputation should produce believable consequences.

NPC social simulation

Eventually, townspeople should have routines, occupations, relationships, and responses to local events.

For example, a witness might inform the sheriff, or a shopkeeper might refuse service to a known criminal.

These are longer-term systems, not prerequisites for the first combat prototype.

⸻

8. First Prototype — The Three-Gunman Encounter

Primary objective: Determine whether fighting three intelligent enemies in a reactive environment is genuinely fun.

Build a compact test arena, ideally a Western street with a saloon frontage, porch, doors, windows, wooden cover, and a small selection of interactive objects.

The initial encounter involves the player and three gunmen.

Each enemy should have distinct behavioral tendencies:

* Gunman A: Confident and aggressive, willing to advance.
* Gunman B: Defensive, prefers cover and carefully selected shots.
* Gunman C: Opportunistic, tries to flank but may retreat if threatened.

These are behavioral tendencies, not predetermined scripts.

Initial prototype features

1. Functional revolver handling, aiming, sway, recoil, and projectile ballistics.
2. Convincing bullet impacts on dirt and wood.
3. A basic destructible-cover system.
4. NPC line-of-sight and sound perception.
5. NPC cover-seeking and relocation.
6. Basic suppression and self-preservation.
7. Physical character hit reactions.
8. Clear spatial audio cues.

After these features work together, introduce one environmental hazard, such as a destructible oil lantern and limited fire propagation.

Example emergent encounter

The player encounters three armed men.

One exchanges shots from behind a fence. The player fires at his position, breaking portions of the wood and forcing him to relocate.

Another gunman circles around the saloon.

The player temporarily loses sight of him, but hears his footsteps on the wooden porch.

The third gunman is wounded and attempts to retreat.

A shot breaks a nearby lantern and starts a fire, creating smoke and making one position unsafe.

The player must decide whether to push forward, escape, reload, or relocate.

This should be the outcome of interacting gameplay systems rather than a sequence of explicitly scripted events.

⸻

9. How We Evaluate the Prototype

Run the same three-gunman encounter repeatedly.

We want to determine:

* Do different believable situations emerge naturally?
* Is aiming challenging but fair?
* Do players understand why they miss?
* Do incoming rounds and near misses feel dangerous?
* Are enemies intelligent without appearing omniscient?
* Is losing sight of an enemy exciting rather than annoying?
* Does destructible cover meaningfully alter tactics?
* Can fights last longer without enemies becoming bullet sponges?
* Do firearms and physical reactions feel satisfying?
* Does the encounter remain entertaining after repeated attempts?

The target is a fight that can resolve quickly through excellent shooting but regularly develops into a tense, unpredictable struggle.

Important: Do not artificially force every encounter to reach a duration target.

⸻

10. Potential Demo Missions

After the core gameplay systems are validated, we can build three or four small missions that exercise them in different contexts.

These are provisional concepts, not finalized story missions.

Mission 1 — A Quiet Drink

A saloon confrontation that tests conversation, escalation, intimidation, close-range combat, furniture destruction, and civilian reactions.

Mission 2 — Dead Man’s Crossing

A roadside wagon ambush testing outdoor ballistics, destructible cover, positioning, flanking, and NPC survival behavior.

Mission 3 — The Missing Ranch Hand

An investigation with opportunities for observation, dialogue, stealth, and nonviolent resolution.

Mission 4 — Blood on Main Street

A confrontation involving multiple buildings, changing cover, escape routes, witnesses, and consequences from earlier decisions.

Do not develop all four missions before proving the core mechanics.

⸻

11. Development Approach

This is an existing Godot project. Inspect the current implementation before making architectural changes.

We want to build reusable, data-driven gameplay systems rather than tightly scripted encounters.

Priorities:

1. Establish what firearm, projectile, hit detection, AI, navigation, physics, destruction, and audio systems already exist.
2. Identify deficiencies relative to this brief.
3. Develop an incremental implementation plan.
4. Build the smallest functional combat prototype.
5. Validate gameplay behavior before increasing visual complexity or expanding the world.
6. Profile performance, especially where debris, rigid bodies, NPC behavior, and destruction interact.

Avoid attempting to construct the entire immersive simulation at once.

Prioritize systems that improve the combat experience and can later be reused across missions.

12. Final Creative Direction

Salt Creek’s combat should feel dangerous, physical, deliberate, and unscripted.

A gunfight involving three people should have enough depth to be more compelling than a conventional shooter encounter involving twenty enemies.

Our defining features should be:

* Few enemies, high stakes.
* Meaningful gun handling.
* Physical accuracy rather than arbitrary randomness.
* Intelligent opponents with believable self-preservation.
* Destructible, reactive environments.
* Spatial awareness and uncertainty.
* Multiple possible approaches.
* Emergent outcomes instead of predetermined action sequences.

The ultimate goal is a Western where the player remembers what happened during a gunfight because of the unique circumstances, not because of a scripted spectacle.

Immediate instructions for the gameplay development session

Review the existing Salt Creek Godot systems against this brief. Report which capabilities are already present, which can be extended, and which require new implementation.

Propose the first practical development milestone for the three-gunman combat prototype, including the scene setup, components, required dependencies, and criteria for success.

Then begin implementing that milestone using the established project architecture. Preserve existing functional systems where possible, and do not expand into unrelated features until the combat foundation has been tested.