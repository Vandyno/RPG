# World Generation / Authoring Handoff

## Goal

Build a deterministic, atlas-constrained world-authoring pipeline for Velcor.
It must turn reviewed map constraints into editable regions, towns, interiors,
roads, POIs, NPC/service slots, and quest hooks without silently inventing
canon. Briarwatch remains a test yard; generated places are proposals until
approved.

## Current State

- Character/equipment system is ready for generated humanoid NPCs.
- Six peoples, full leather and iron armour, bodies, loot, interiors, roads,
  streaming, combat, and captures work.
- `MAP.md` and the continent image broadly align.
- `docs/WORLD_ATLAS_AUDIT.md` records the current comparison and gaps.
- No structured atlas data or place-generation tooling exists yet.

## Source Of Truth

Read before implementation:

- `DESIGN.md`
- `ARCHITECTURE.md`
- `CONTENT_GUIDE.md`
- `MAP.md`
- `docs/WORLD_ATLAS_AUDIT.md`
- `LORE.md`

Reference image:

- `docs/reference/velcor_continent_tangle_rootborn_shattered_isles.png`

Generated names, lore, factions, religions, locations, and quests are proposals
until explicitly approved as canon.

## Plan

### 1. Atlas Data

Create `data/world_atlas_proposal.json` with:

- continent bounds, coastline, and water exclusion;
- named region polygons and biome weights;
- rivers, lakes, mountain barriers, forests, swamps, and passes;
- fixed settlements with type, size band, role, and rough map anchors;
- major roads, trade roads, ferries, canopy routes, and cliff routes;
- political, cultural, coexistence, and cult-pressure zones;
- protected landmarks and POI anchors.

Do not parse the map image at runtime. Convert it to reviewed data once.

### 2. Atlas Validator And Preview

Validate:

- duplicate or missing IDs;
- invalid polygons and paths;
- settlements outside their intended region;
- road endpoints that do not meet settlements, ports, or passes;
- water and terrain contradictions;
- missing required named locations.

Add a capture/preview tool that renders atlas regions, roads, anchors, and
validation warnings.

### 3. Deterministic Region Generator

Given an atlas region ID and seed:

- generate terrain chunks within biome rules;
- preserve fixed rivers, roads, landmarks, passes, and named places;
- generate minor roads, farms, camps, ruins, caves, shrines, and travel clutter;
- write editable proposal data, never hidden runtime randomness.

Each generated entity records atlas region, seed, template, and generator
version.

### 4. Settlement Generator

Given a settlement anchor, seed, and role:

- generate streets, plots, districts, public spaces, walls, and gates when needed;
- assign homes, inns, shops, services, guard posts, shrines, and storage;
- create interiors through existing structure/interior systems;
- create citizen/NPC role slots, shop slots, quest hook slots, and encounter zones;
- respect region identity such as river trade, frontier, wetland ferry,
  Tanglekin canopy, or Iron March hold.

Output a proposal bundle for editing before insertion.

### 5. POI Generator

Build smaller templates first:

- road camps;
- shrines;
- bridges;
- farms;
- caves;
- ruins;
- towers;
- smuggler coves;
- ferry landings.

Every POI needs walkability, interaction/service/loot slots, visual style,
encounter rules, and optional quest hooks.

### 6. Proposal Review Workflow

Each generated region or town produces:

- editable JSON proposal;
- overview screenshot;
- structure and interior screenshots;
- validation report;
- short summary of generated roles and hooks.

Nothing merges into runtime `world_*` content until reviewed.

### 7. First Real Generated Location

After the toolkit works, generate one small approved place from atlas constraints.
Do not make it another Briarwatch cleanup.

Possible later candidates:

- Northgate: road junction;
- Stonebridge: river crossing;
- Redfield: Mireveil-edge farm and smuggling pressure;
- Oakholt: managed timber and wetland tension.

## Technical Constraints

- Extend existing global-tile, chunk-streaming, `StructureManager`, and
  data-driven content systems; do not replace them.
- Generator output must be normal editable content data.
- Preserve continuous movement and existing interior layers.
- No new PNG character pipeline.
- Validate reachability, doors, portals, collision, NPC homes/services, and
  structure interiors.
- Preserve unrelated dirty-worktree changes.

## Definition Of Done: v1

- Atlas proposal exists and validates.
- Atlas preview capture works.
- One seeded region generates terrain, roads, and POIs reproducibly.
- One seeded settlement generates editable plots, structures, interiors, and
  NPC/service slots.
- Generated output passes reachability, collision, and portal validation.
- Screenshots are reviewed before activation.
- Existing full test suite stays green.

## Immediate Next Action

Implement the atlas schema, validator, and visual preview first. Do not start
town generation until atlas constraints are inspectable and approved.
