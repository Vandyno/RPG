# NPC Brain And Daily Schedule Plan

## Goal

Build civilians who appear to live in the world. An NPC should wake at home,
travel to work, perform a role, take breaks, seek food or company, return home,
and sleep. The system must support Oblivion/Skyrim-like authored routines while
remaining deterministic, persistent, interruptible, and affordable in a very
large streamed world.

This document is the source of truth for civilian brains and schedules. It does
not make generated NPC names, relationships, religions, or personal histories
canon. Those remain proposals until approved.

## Existing Foundations

- `TimeManager` owns day and minute-of-day, advances across midnight, emits time
  changes, and participates in save/load.
- `WorldPathfinder` and `WorldEntityMovement` provide continuous collision-aware
  travel. The hostile brain already proves chase, return, and path refresh.
- `EntityManager` saves runtime movement and behavior state.
- Shops already support authored opening and closing hours.
- Northgate proposals provide homes, workplaces, services, interiors, portals,
  footpaths, NPC role slots, and a required working farm in its hinterland.

The civilian system should compose these pieces. It should not turn
`hostile_actor_brain.gd` into a universal god object.

## Core Model

Each scheduled NPC needs:

- a stable NPC ID and `civilian_schedule` brain ID;
- a home structure/layer and safe sleep anchor;
- zero or one primary workplace and work anchor;
- schedule profile ID plus optional NPC-specific overrides;
- allowed leisure destinations and social preferences;
- current activity, destination, route, interruption, and lateness state;
- a compact persistent state record for save/load and streaming.

Schedules select intent. Activities execute intent. Movement only moves toward
an activity destination. Reactive behavior can interrupt either without
destroying the underlying daily plan.

```text
clock + calendar
      |
schedule resolver ---- NPC overrides / quest state / weather later
      |
activity intent (sleep, work, eat, relax, travel, sandbox)
      |
destination resolver ---- home / shop / farm / inn / public anchor
      |
path + portal traversal
      |
local activity behavior and animation
```

## Data Contracts

Use authored JSON, validated at load time.

### Schedule profile

```json
{
  "id": "schedule_farmer_standard",
  "brain_id": "civilian_schedule",
  "weekday_blocks": [
    {"start": "05:30", "activity": "wake", "destination": "home"},
    {"start": "06:15", "activity": "work", "destination": "primary_workplace"},
    {"start": "12:00", "activity": "eat", "destination": "workplace_break"},
    {"start": "13:00", "activity": "work", "destination": "primary_workplace"},
    {"start": "18:00", "activity": "relax", "destination_pool": "town_leisure"},
    {"start": "21:30", "activity": "sleep", "destination": "home"}
  ],
  "tolerance_minutes": 20,
  "sandbox_radius_tiles": 8
}
```

Blocks are start-based and cover the full day by wrapping at midnight. Profiles
may define weekday/weekend or named-day variants later. NPC overrides can move a
block, replace a destination, or suppress an activity without copying a profile.

### NPC schedule binding

```json
{
  "npc_id": "npc_northgate_farmer_01",
  "schedule_id": "schedule_farmer_standard",
  "home_structure_id": "structure_northgate_west_home_plot",
  "workplace_id": "poi_northgate_working_farm",
  "leisure_destination_ids": ["structure_northgate_coaching_inn", "northgate_square"],
  "personal_overrides": [],
  "canon_status": "proposal"
}
```

### Runtime state

Persist only state that cannot be reconstructed safely:

- current schedule block and activity;
- current world layer and position;
- chosen destination from a pool;
- active interruption and resume policy;
- work progress or reserved interaction anchor when meaningful;
- last simulated absolute minute;
- temporary unavailable/dead/hostile flags.

Do not save raw path arrays. Rebuild routes after load or topology changes.

## Activity Types

- `sleep`: occupy a bed/home anchor; unavailable for routine conversation unless
  explicitly woken or trespassed upon.
- `wake`: short home sandbox—dress, eat, use hearth, gather tools.
- `travel`: path toward a resolved destination, including surface/interior
  portals and settlement gates.
- `work`: reserve a job anchor and run role-specific loops. Shopkeepers must be
  physically present for normal service. Farmers rotate between field, byre,
  storage, and meal anchors.
- `eat`: choose a valid meal anchor at home, work, or inn.
- `relax`: choose a weighted valid destination such as home hearth, public
  square, neighbour, or inn. The choice is deterministic for NPC/day/block.
- `sandbox`: wander among authored anchors within a limited area; never choose
  arbitrary unreachable coordinates.
- `quest`: an authored quest package temporarily owns the NPC.
- `flee`, `investigate`, `combat`, `recover`: reactive packages with explicit
  conditions for resuming or abandoning the schedule.

## Decision Priority

Highest priority wins:

1. death/incapacitation;
2. immediate combat, flee, fire, or other danger;
3. quest scene package;
4. crime/trespass reaction;
5. critical personal need (hunger/fatigue recovery);
6. current schedule block;
7. local idle/sandbox detail.

An interruption stores a resume policy: resume current activity, advance to the
now-current block, go home, or remain quest-owned. NPCs must not return to a
missed morning task at midnight after combat ends.

## Time And Catch-Up

The brain uses absolute minutes derived from day and minute-of-day. It must
handle normal ticks, waiting, sleeping, fast travel, save/load, and streamed-out
actors consistently.

- On small time changes, active nearby NPCs walk and act normally.
- On large jumps, resolve the current schedule block and place an off-screen NPC
  at the current destination or a plausible point along travel.
- Never teleport a visible NPC. Visible late NPCs travel and may arrive late.
- Streamed-out NPCs use low-cost schedule simulation with no scene node or path.
- Re-entering a streamed area materializes the NPC from authoritative compact
  state, not from the original spawn marker.

## Destinations And Reservations

Destinations are authored semantic anchors, not loose coordinates:

- `home.sleep`, `home.meal`, `home.personal`;
- `shop.counter`, `shop.stock`, `shop.break`;
- `farm.field`, `farm.barn`, `farm.trough`, `farm.meal`;
- `inn.bar`, `inn.table`, `inn.guest_bed`;
- `town.square`, `town.bench`, `town.wander_loop`.

Shared anchors need reservations with expiry and fallback anchors. Two NPCs may
socialize at one table, but six NPCs should not occupy the same chair tile.

## Northgate Groundwork Schedules

Initial profiles should prove different lives:

- Shopkeeper: home 06:30, shop preparation 07:30, counter 08:00–18:00,
  stock/counting after close, inn or home evening, sleep 22:30.
- Smith and apprentice: early forge preparation, two work blocks with meal
  break, variable inn evening, sleep at their assigned homes.
- Farmer: wake 05:30, exterior farm 06:15–12:00 and 13:00–18:00, home/inn
  leisure, sleep 21:30. Later seasons can change this profile.
- Innkeeper/cook: staggered shifts so the inn functions morning and evening;
  neither should stand behind the bar continuously for 24 hours.
- Guards: rotating gate/patrol/rest packages with coverage reservations.
- Residents: household-specific wake, town errand, leisure, visit, and sleep
  blocks derived from their approved identity and home.

## Services

Opening hours alone are insufficient. A normal service is available only when:

- the clock is within service hours;
- a qualified living NPC is present at the service anchor;
- the NPC is not hostile, fleeing, asleep, quest-locked, or otherwise unable;
- the place itself is accessible.

UI feedback should say why a service is unavailable and, when known, when the
worker is expected back.

## Performance Tiers

- `near`: full movement, portals, local avoidance, activity animation.
- `loaded_far`: infrequent intent/path updates and simplified sandbox behavior.
- `streamed_out`: schedule math only at time changes or coarse intervals.

The first implementation must support hundreds of scheduled records without
hundreds of active pathfinders.

## Validation And Debugging

Add validators for full-day coverage, ordered times, existing destinations,
valid home/work bindings, reachable portal chains, service qualification, and
fallback destinations. Detect impossible commutes and overlapping exclusive
reservations.

Add a debug inspector showing:

- current time, block, activity, destination, and reason;
- next scheduled transition;
- current interruption and resume policy;
- path/portal target and lateness;
- whether the NPC is fully simulated or off-screen.

## Delivery Phases

### Phase 1 — Groundwork

- Schedule profile and binding schemas, loaders, and validators.
- Pure schedule resolver with midnight, gaps, time jumps, and deterministic
  leisure selection tests.
- `civilian_schedule` brain coordinator separate from hostile combat logic.
- Semantic destination registry and basic reservations.
- Save/load compact schedule state.
- Northgate shopkeeper and farmer walking home/work/sleep loops.
- Required Northgate exterior farm proposal and path connection.
- Debug schedule readout.

### Phase 2 — Playable Town Coverage

- Bind all Northgate residents and workers.
- Cross-layer portal travel and presence-based services.
- Inn leisure, public wandering, guard shifts, household routines.
- Wait/sleep/stream-out catch-up verified across every schedule profile.

### Phase 3 — Robust Reactions

- Crime, trespass, flee, combat, injury, death, quest packages, locked doors,
  absent workers, and schedule recovery.

### Phase 4 — World Scale And Character

- Seasonal/day variants, relationships, visits, weather responses, rumours,
  dynamic work needs, and low-cost simulation across the full world.

## Phase 1 Acceptance Criteria

- A farmer visibly leaves a Northgate home, walks through a gate to the exterior
  farm, works, takes a break, optionally visits the inn, returns home, and sleeps.
- A shopkeeper opens service only while present and follows home/work/leisure/
  sleep blocks.
- Waiting across multiple blocks or midnight produces the correct current state.
- Save/load preserves meaningful activity and location.
- Combat or quest interruption resumes according to policy.
- Streamed-out catch-up and visible behavior agree on the resolved block.
- Tests use real clock advancement and actual actor movement where player-facing
  behavior is claimed.

## Phase 1 implementation handoff

The Phase 1 runtime is implemented in the existing project without changing the
hostile combat brain. Generic authored profiles live in
`data/schedule_profiles.json`; bindings and destination anchors are loaded by
`ContentDatabase`. `CivilianScheduleManager` owns compact runtime state,
reservations, interruption/resume, streamed-out catch-up, service presence, and
debug snapshots. `CivilianScheduleBrain` is the separate per-frame coordinator.

Northgate actor identities, bindings, destinations, service details, and fixture
actors remain in
`data/proposals/northgate_civilian_schedule_proposal.json` with
`canon_status: proposal` and `activation_status: review_required`. The focused
Northgate tests load that proposal directly; it is not promoted into canon
world content.
