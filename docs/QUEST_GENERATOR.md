# Quest Proposal Generator

## Purpose

This is the safe first stage of quest authoring. It produces deterministic,
review-only quest pitches from existing game content. It never adds a quest to
runtime data, changes canon, creates NPCs, or edits dialogue.

It exists to turn a reviewed place and its available context into usable work
for a writer or implementation pass.

## Inputs

The generator reads existing IDs and display text from:

- `data/locations.json`
- `data/npcs.json`
- `data/factions.json`
- `data/readables.json`
- `data/quests.json` (collision avoidance only)

The output may only cite those existing IDs. It marks every pitch `IDEA` and
`unreviewed`; it does not make a pitch canon.

## Run

From the project root:

```powershell
tools\generate_quest_proposals.cmd first_quest_pass 5
```

Generate three proposals constrained to one existing location:

```powershell
tools\generate_quest_proposals.cmd briarwatch_jobs 3 location_briarwatch_crossroads
```

Optional fourth argument is the output path. Default output is:

```text
reports/quest_proposals/first_quest_pass.json
```

## Output Contract

Each bundle is `quest_proposal_bundle_v1` with `runtime_import: manual_only`.
Each pitch includes:

- stable proposal ID, status, approval state, location, and existing references;
- hook, summary, twist, outcomes, and canon risk;
- implementation gaps and source constraints.

The validator rejects missing source IDs, duplicate proposal IDs, collision with
runtime quests, non-proposal status, or missing review requirements.

## Review To Playable Quest

1. Review the pitch against `LORE.md`, `MAP.md`, and the location plan.
2. Mark it approved in a separate review record; generated text is not canon.
3. Choose exact world targets, NPCs, dialogue, stages, rewards, and a persistent consequence.
4. Add the approved result manually to `data/quests.json` and related content files.
5. Run content validation and play the quest in-game.

Use `QUEST_PROPOSAL_LOOP.md` for the pitch and expanded-pack review rules.
