## project context

Use these files as the current source of truth:
- `DESIGN.md` for game vision and player experience
- `ARCHITECTURE.md` for technical boundaries and system ownership
- `CONTENT_GUIDE.md` for authored content structure and ID conventions
- `docs/ui/UI_TARGET.md` for the player-facing RPG UI mockup target
- `LORE.md` for setting canon and worldbuilding
- `MAP.md` for map direction and preserved place names
- `QUEST_PROPOSAL_LOOP.md` for AI quest proposal workflow

Generated lore, quests, locations, factions, or religions are proposals until
the user explicitly approves them as canon.

## working priorities

Prioritize the first playable slice over generalized systems. Do not build broad
abstractions, such as an effect framework or deep content pipeline, while core
movement, interaction, combat, quests, UI, and spawn-area playability still need
work. Add systems only when they directly improve the playable experience or make
the next concrete POI, quest, NPC, service, or UI flow easier to ship and test.

Focus on player pain points before polish for its own sake. The player does not
need heavy hand-holding; they need systems that work, make sense, and respond
intuitively to intent. Prefer making default actions, targeting, feedback, and
world interactions feel natural over adding more explanatory UI.
