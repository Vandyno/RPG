# QUEST_PROPOSAL_LOOP.md

# Purpose

This file defines a review loop for AI-generated quest ideas.

The AI should generate proposals, not canon. Final quests become canon only
after approval and integration into content data.

# Inputs

Quest generation should use:
- `DESIGN.md`
- `ARCHITECTURE.md`
- `CONTENT_GUIDE.md`
- `LORE.md`
- `MAP.md`
- approved map images or location indexes when available

For deterministic, review-only starting pitches, use
`docs/QUEST_GENERATOR.md`. The generator may cite existing content IDs but does
not create canon or runtime quest data.

# Basic Loop

1. Input world context.
2. Generate 5 to 10 quest pitches.
3. Tie each pitch to existing locations, peoples, religions, factions, or
   tensions.
4. Mark canon risk.
5. Review each pitch.
6. Approve, reject, revise, or save for later.
7. Expand approved quests into implementation-ready quest packs.
8. Save final approved quests into canon docs or game data.

# Quest Status

- IDEA
- REVIEW
- REWORK
- APPROVED
- CANON
- CUT

# Pitch Format

```json
{
  "title": "The Warden at Briarwatch",
  "status": "IDEA",
  "location": "Briarwatch",
  "factions": ["Humans", "Rootborn"],
  "type": "frontier dispute",
  "summary": "A managed grove has been cut beyond its treaty line, and both sides accuse the other of lying.",
  "player_hook": "The player is hired to find out who marked the wrong boundary stones.",
  "twist": "The markers were moved by Hollow Mercy smugglers using the dispute as cover.",
  "possible_outcomes": [
    "Expose the smugglers and preserve the treaty",
    "Side with the town and worsen Rootborn relations",
    "Side with the Rootborn and damage Briarwatch's economy"
  ],
  "canon_risk": "low"
}
```

# Expanded Quest Pack Format

When a pitch is approved for expansion, generate:
- stable quest ID
- title
- status
- starting location
- starting NPC or trigger
- summary
- stages
- objectives
- important NPCs
- important locations
- important items
- important readables
- enemies or encounters
- dialogue beats
- conditions
- effects
- world-state flags
- rewards
- possible outcomes
- save/load implications
- testing checklist

# Rules

- Do not contradict `LORE.md`.
- Do not make proposal material canon automatically.
- Do not invent major new cities, peoples, gods, wars, or map regions unless
  the request explicitly asks for that.
- Prefer local problems that reveal larger setting tensions.
- Keep quest structure compatible with `CONTENT_GUIDE.md`.
- Use stable lowercase IDs with underscores.
- Include at least one readable when the quest depends on investigation,
  history, faith, or hidden truth.
- Include at least one world-state consequence for approved vertical-slice
  quests.
