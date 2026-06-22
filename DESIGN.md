# DESIGN.md

# Tile-Based 2D Open-World RPG

## High Concept

A story-driven 2D open-world fantasy RPG built on a seamless tile-based world.

The player explores a large hand-authored world filled with towns, roads, wilderness, ruins, caves, dungeons, interiors, factions, NPCs, books, notes, quests, enemies, secrets, and meaningful choices.

The game aims to capture the feeling of a traditional open-world RPG through a 2D tile-based presentation.

The player should feel like they are physically travelling through a connected world, discovering places naturally, getting pulled into local problems, finding written lore, making choices, and leaving persistent consequences behind.

---

# Core Fantasy

The player is an adventurer in a dangerous fantasy world.

They can:

- walk roads between settlements
- explore forests, swamps, mountains, fields, caves, ruins, dungeons, and old roads
- talk to townsfolk, travellers, priests, outcasts, soldiers, merchants, cultists, scholars, criminals, and strange beings
- accept quests from people and factions
- read books, journals, signs, letters, inscriptions, notices, and forbidden texts
- fight monsters, bandits, cultists, beasts, undead, spirits, and dungeon bosses
- find weapons, armour, gold, relics, ingredients, books, keys, and quest items
- make choices that alter dialogue, quest outcomes, relationships, access, reputation, and local world state
- grow stronger through skills, equipment, experience, training, rare texts, and quest rewards

The world should feel grounded, authored, and lived-in.

---

# Player Experience

The player should often think:

- "What is down this road?"
- "What is inside that cave?"
- "Why is this shrine here?"
- "Who wrote this journal?"
- "Can I trust this NPC?"
- "What happens if I help this faction?"
- "What happens if I do not?"
- "Can I solve this quest another way?"
- "This place has history."
- "This choice might matter later."

Exploration should be rewarding even when the player is not following a quest marker.

---

# Core Gameplay Loop

The main loop is:

1. Explore the world.
2. Discover a location, NPC, object, enemy, book, note, clue, or threat.
3. Interact through dialogue, reading, combat, looting, investigation, or traversal.
4. Gain information, items, quests, reputation, access, or world-state changes.
5. Make choices.
6. Resolve or complicate local problems.
7. Grow stronger.
8. Continue exploring.

A smaller loop:

travel -> discover -> interact -> choose -> consequence -> reward -> continue

---

# World Structure

The world is one large continuous tile-based space.

It contains:

- roads
- villages
- towns
- wilderness
- farms
- camps
- shrines
- caves
- ruins
- dungeons
- interiors
- faction territories
- hidden locations
- quest areas
- landmarks
- dangerous regions

The world should feel physically connected.

Examples:

- A road leads from a village to an old watchtower.
- A forest path hides a shrine.
- A cave entrance sits in a cliff wall.
- A ruined tower overlooks a trade route.
- A bandit camp blocks a bridge.
- A dungeon exists beneath an old temple.
- A hermit lives in a hut far from town.
- A note found in a mine points to a second location.
- A faction outpost controls a mountain pass.

Locations should have a sense of place and purpose.

---

# Tile-Based Presentation

The world is tile-based.

Tiles represent terrain, structures, roads, floors, walls, water, hazards, objects, and other world features.

Gameplay logic should understand:

- where the player is
- what tile the player is standing on
- what objects are nearby
- which tiles can be walked on
- which tiles block movement
- which tiles have movement costs
- which objects can be interacted with
- which enemies can see or reach the player
- which quest triggers are nearby
- which areas have been discovered

The visual style can be polished, animated, painterly, pixel-art, illustrated, or stylized, but the underlying world should remain grid-aware.

---

# Platform and UI Direction

The game should be designed with eventual mobile play in mind.

The primary mobile orientation is horizontal landscape.

When UI is introduced or expanded, it should be comfortable on phone and tablet screens:

- touch targets should be large enough for thumbs
- important controls should sit within comfortable landscape reach zones
- text should remain readable at mobile viewing sizes
- panels should avoid covering the player, interaction targets, and combat space
- menus should support short, focused flows rather than dense desktop-only layouts
- HUD elements should be scalable, collapsible, or context-sensitive where practical
- save, inventory, dialogue, quest, readable, and combat UI should be tested at landscape mobile aspect ratios

Desktop controls can exist, but UI should not be designed as desktop-first with mobile added as an afterthought.

---

# Seamless Exploration

The player should experience the world as one connected place.

Chunk streaming may be used internally, but the player should not feel like they are moving through disconnected maps.

Travel should feel physical.

The player can wander away from the main path and discover authored content.

The world should support moments like:

- following a river and finding a cave
- cutting through woods and discovering a shrine
- walking past a ruined road marker and finding a hidden path
- seeing a tower in the distance and reaching it later
- entering a town and learning about nearby trouble
- reading a note that recontextualizes a place already visited
- finding a locked door long before knowing how to open it
- returning to a town and seeing dialogue changed by the player's actions

---

# Story Structure

The game is story-driven.

Story is delivered through:

- main quests
- side quests
- faction quests
- companion quests
- environmental storytelling
- dialogue
- books
- notes
- journals
- signs
- inscriptions
- item descriptions
- location design
- NPC reactions
- world-state changes

The main story should give direction, but the player should be free to explore, delay, investigate, or pursue side content.

Side content should feel connected to the world rather than disposable.

---

# Quest Design

Quests should be authored and meaningful.

A good quest should usually include at least some of:

- a clear local problem
- an NPC with a motive
- a place to investigate
- a choice or complication
- a reward
- a consequence
- a way the world or dialogue changes afterward

Quest types:

- main story quests
- settlement quests
- faction quests
- dungeon quests
- companion quests
- mystery/investigation quests
- hidden discovery quests
- item recovery quests
- moral choice quests
- combat-focused quests
- exploration quests

Quest outcomes may affect:

- NPC dialogue
- faction reputation
- access to locations
- rewards
- world-state flags
- future quest options
- local settlement state
- enemies present in an area
- whether a character lives, dies, leaves, or changes role
- whether an object, door, shrine, or route is available

---

# Dialogue Design

Dialogue should make NPCs feel like part of the world.

NPCs may talk about:

- local problems
- rumours
- factions
- religion
- politics
- monsters
- roads
- old ruins
- personal concerns
- recent events
- the player's choices
- books or notes the player has read
- quest progress
- reputation

Dialogue should support:

- greeting lines
- branching conversations
- player choices
- quest starting
- quest advancing
- quest resolving
- conditional options
- skill/reputation checks later
- different responses based on world-state flags
- different responses based on readables discovered or read

NPCs should not all speak with the same tone.

Dialogue should usually be concise and playable. Longer conversations should earn their length through stakes, character, mystery, or meaningful choice.

---

# Books, Notes, and Readables

Readables are a major part of the RPG experience.

They should reward curiosity, deepen the world, and sometimes affect gameplay.

Readable types:

- books
- letters
- journals
- notes
- signs
- wanted posters
- shrine inscriptions
- wall carvings
- plaques
- sermons
- laws
- recipes
- maps
- research notes
- cult writings
- faction documents
- military orders
- personal diaries
- contracts
- ledgers
- warnings

Readables can serve different purposes:

- lore
- quest clue
- warning
- joke
- history
- character backstory
- religious text
- political propaganda
- puzzle hint
- hidden quest trigger
- worldbuilding detail
- environmental storytelling
- faction flavour
- dialogue unlock
- evidence for investigation

Readables should often make places feel more real.

A mine with a journal should feel different from a mine with only enemies.

A ruined shrine with an inscription should feel different from a generic ruin.

A bandit camp with letters should reveal something about the people there.

---

# Environmental Storytelling

The world should communicate through placement, objects, and written details.

Examples:

- a skeleton beside a locked chest
- a burnt house near a road
- a journal beside a dead miner
- claw marks near a cave entrance
- a shrine with fresh candles
- a battlefield with old banners
- a noble house with hidden cult documents
- a bridge blocked by bandits
- an abandoned camp with a half-written note
- an empty crib in a locked room
- old warning signs near a sealed gate

Environmental storytelling should support quests and lore without requiring every detail to be explained by dialogue.

---

# Combat

Combat should be clear, readable, and tied to the tile/grid foundation.

Early combat can be simple:

- player attacks enemy
- enemy detects player
- enemy moves toward player
- enemy attacks
- health changes
- enemy dies
- loot drops

Later combat may include:

- weapons
- armour
- shields
- bows
- spells
- stamina
- mana
- status effects
- traps
- companions
- enemy types
- bosses
- faction hostility
- stealth
- line of sight
- terrain effects
- area effects

Combat should support character builds without becoming too complex too early.

---

# Character Progression

The player should grow through:

- experience
- skills
- perks
- equipment
- items
- quest rewards
- faction rewards
- discoveries
- special training
- rare books or teachers
- story choices

Possible build directions:

- warrior
- ranger
- rogue
- mage
- priest/holy caster
- occult caster
- survivalist
- diplomat/speaker
- scholar/investigator
- hybrid builds

Progression should create new options in combat, dialogue, exploration, reading/lore interpretation, and quest resolution.

---

# Inventory and Loot

Inventory should support:

- weapons
- armour
- consumables
- gold
- quest items
- keys
- books
- notes
- crafting ingredients later
- relics
- faction items
- evidence items

Loot should reward exploration.

Containers may include:

- chests
- barrels
- crates
- corpses
- shelves
- desks
- hidden caches
- shrine offerings
- dungeon rewards
- locked boxes
- abandoned packs

Items should have clear IDs and descriptions.

Important items should be able to affect quests, dialogue, or world state.

---

# Factions and Reputation

The world should contain factions with beliefs, goals, enemies, territory, and quests.

Faction reputation can affect:

- dialogue
- prices
- hostility
- quest access
- rewards
- guards
- travel safety
- endings
- local world state
- access to faction locations

Faction types may include:

- towns
- kingdoms
- churches
- cults
- bandits
- merchants
- ancient orders
- forest peoples
- military groups
- mages
- local families
- criminal groups

Factions should feel connected to locations and story.

---

# World-State Consequences

The world should remember important choices.

Examples:

- a cleared camp stays cleared
- an NPC changes dialogue
- a locked door becomes unlocked
- a faction becomes hostile
- a town celebrates or resents the player
- a shrine becomes active
- a quest item disappears after being returned
- a boss remains defeated
- a prisoner is freed and appears elsewhere
- a bridge is repaired
- a road becomes available
- a readable unlocks a new dialogue option
- a location becomes marked as discovered

Consequences do not need to be huge every time, but they should make the world feel responsive.

---

# Tone and Style

The tone is grounded fantasy with room for darkness, mystery, religion, folklore, humour, and weirdness.

The world should avoid feeling like generic fantasy filler.

Good tone ingredients:

- old roads
- strange shrines
- local gods
- saints
- cults
- old wars
- buried secrets
- desperate towns
- dangerous wilderness
- complicated factions
- books that hint at deeper history
- rumours that are partly true
- places with histories older than the current conflict

The game can contain serious stories, strange events, funny NPCs, and unsettling discoveries.

---

# First Vertical Slice

The first playable slice should be small but complete.

It should contain:

- a short road
- one village or camp
- one NPC
- one dialogue tree
- one readable note/book/sign
- one quest
- one item pickup
- one hostile encounter
- one cave, ruin, or interior
- one quest resolution
- save/load support for all relevant progress

The slice should prove:

- the player can explore
- the player can interact
- dialogue works
- readables work
- quests work
- inventory works
- combat works
- world state changes
- save/load preserves progress

The goal is not content size. The goal is proving the core engine loop.
