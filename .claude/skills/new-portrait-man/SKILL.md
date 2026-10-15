---
name: new-portrait-man
description: Make a new man (character, cowboy, townsperson, NPC face) for Salt Creek in the approved painted-block look, or change how the portrait men are made. Use whenever a task is to create, rebuild, restyle or fix a person's face, head or likeness in the game. Follows tools/characters/RECIPE.md (the Rodin portrait route Sean approved on 2026-10-14); stops other routes being tried by accident.
---

# A new man in the approved look

Sean approved one way of making people on 2026-10-14 ("I love where we're at"): **the Rodin
portrait route**. The whole recipe is in `tools/characters/RECIPE.md`. Read it first and follow
it step by step.

In short:
1. Sean makes four plain pictures and five style portraits of the man in ChatGPT (the prompt is
   in the recipe).
2. His entry goes in `assets/people/portrait.json`, with the approved `fidelity` settings.
3. Rodin builds his shape (1.60 US dollars, the People workflow, `style: rodin`). Say the cost first.
4. `tools/characters/rodin_portrait.py paint`, then `tools/characters/render_man.sh`, then
   `test_bodies`, then `style_probe.py` against his portraits.
5. Send Sean the sheet. His eye is the gate.

Don't go down the routes that were tried and dropped without asking Sean first:
- Tripo or Rodin texturing on their own;
- the MakeHuman portrait factory (`portrait.py`);
- the style LoRA's repaints;
- Meshy.

Their histories are in `docs/briefs/portrait-factory.md` and `docs/briefs/character-style-fidelity.md`.

The approved state is the branch `look/portrait-men-2026-10-14`, a bookmark never pushed to. The
recipe's "Going back" section puts any man back to it.
