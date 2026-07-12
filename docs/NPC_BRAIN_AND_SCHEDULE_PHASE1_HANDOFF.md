# NPC Brain And Schedule Phase 1 Handoff

Phase 1 runtime groundwork is implemented in the separate `civilian_schedule`
brain. Hostile actors remain owned by `hostile_basic`.

Implemented contracts:

- `data/schedule_profiles.json` contains generic worker, guard, resident, and
  leisure profiles, including weekend variants.
- `ContentDatabase` loads and validates schedule profiles, bindings, and semantic destinations.
- `ScheduleResolver` handles start-based blocks, midnight wrapping, deterministic leisure pools, and personal overrides.
- `CivilianScheduleManager` owns visible movement, streamed-out catch-up, interruptions/resume, reservations, portal-route state, compact save data, and debug snapshots. It also resolves collision-aware paths through authored surface/interior portal chains, chooses authored activity actions, supports weekend routine variants, and records social groups at shared leisure anchors.
- Runtime state also tracks hunger and fatigue. Critical needs temporarily override a routine with eating or sleeping, recover over simulated time, and survive compact save/load. Combat promotion records a schedule interruption and civilian control is restored after the hostile brain returns home.
- A badly wounded scheduled civilian now abandons hostile combat, flees through the authored home/portal route, enters a one-hour recovery state, and resumes the current schedule afterward.
- Attack and trespass incidents persist per NPC. Wary civilians expose an `Address the incident` action; acknowledging it clears the unresolved disposition without erasing the incident history.
- Unresolved incident memories can become social rumors when companions meet, so player actions propagate through the town’s social network.
- `ShopManager` gates schedule-aware services on hours plus a qualified worker being present at the service anchor.
- `MainDebugState` exposes the schedule snapshot; `SaveManager` stores the optional `civilian_schedules` section.

Northgate bindings, the shopkeeper/farmer proposal actors, and the required farm
anchors are in `data/runtime/northgate_schedule_*.json` and
`data/proposals/northgate_civilian_schedule_proposal.json`. They remain marked
`proposal`/`review_required`; no name, identity, relationship, or lore is made
canon by this implementation.

Focused verification is in:

- `tests/unit/core/test_schedule_resolver.gd`
- `tests/unit/managers/content/test_civilian_schedule_manager.gd`
- `tests/unit/managers/content/test_schedule_reservation_manager.gd`

The Northgate coverage slice now binds the innkeeper, smith and apprentice,
reeve, clerk, storekeeper, stablehand, guard, shrine keeper, and five residents
in addition to the farmer and shopkeeper. Runtime civilians stay neutral during
routine but remain damageable; an attacked civilian can temporarily use the
hostile brain and return to the civilian routine after disengaging.

The proof covers normal advancement, waiting-compatible time jumps, midnight,
streamed-out catch-up and rematerialization, visible movement, farmer work/meal/
relax/home/sleep blocks, shopkeeper service presence, interruption/resume, and
schedule state save/load.

Follow-on people-behavior slices now present in the runtime:

- residents have authored weekend visit targets; one resident stays home as a
  host while others travel to household anchors;
- nearby civilians form social groups only after reaching the same leisure or
  visit anchor, choose deterministic exchange actions, and persist pair
  familiarity/meeting memory;
- private-home trespass causes an occupied resident to investigate and confront
  the intruder before resuming the current schedule;
- incapacitated, hostile, dead, or streamed-out workers no longer count as
  physically present services.

The next character slice now also records nearby work as compact per-NPC output
history. Farmer, shopkeeper, and guard action loops leave role-specific work
summaries that survive save/load. Civilians sharing a leisure anchor can carry
the latest work output as a local social topic, and the player can ask a nearby
social NPC for that rumor through context actions.

Quest stages may now author `npc_routines`. An active stage temporarily owns the
listed civilian routine, including destination, action, movement, interruption,
and resume policy. Stage completion/failure releases the NPC back to the current
schedule block. The Northgate missing-manifest proposal proves this with the
storekeeper leaving the counter to search the ledger desk.

Time now exposes deterministic spring/summer/autumn/winter days and daily
weather. Schedule profiles may author `weather_overrides`; the Northgate farmer
stays home for rain, storm, or snow with a different work action, then returns
to the field on the next clear/cloudy day. Weather rules are validated and are
derived from saved day state, so waiting and reloads remain deterministic.
