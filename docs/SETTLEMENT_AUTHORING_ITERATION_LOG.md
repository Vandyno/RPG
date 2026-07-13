# Settlement Authoring Iteration Log

## Purpose

Record how settlements move from generated proposals to acceptable playable
places. Later towns must learn from concrete failures and fixes instead of
repeating them.

Passing validation is not the same as passing the player-facing quality bar.
Each iteration must preserve both its evidence and its verdict.

## Required Iteration Record

Every meaningful settlement pass records:

- settlement ID, seed, generator version, and date;
- the player-facing problem being addressed;
- what changed in layout, terrain, architecture, interiors, content, or runtime;
- before-and-after preview paths or screenshots;
- automated tests and real-input flows run;
- a short in-game playthrough report;
- verdict: `reject`, `functional_only`, `passable`, or `ship_candidate`;
- reusable rule learned for generators and future authored settlements;
- remaining defects, without hiding them behind test results.

Use one entry per coherent pass. Do not rewrite old verdicts after later work;
append a new entry so the path to quality remains visible.

## Acceptance Gates

A settlement is `passable` only when all gates pass:

1. Spatial: terrain, roads, barriers, entrances, and POIs form a believable
   place and match the surrounding geography.
2. Navigation: expected destinations are readable and reachable without debug
   knowledge. Every occupied building connects to the local path network.
3. Functional: doors, services, quests, storage, schedules, arrival/exit, and
   persistence work through real player input.
4. Lived-in: homes and workplaces communicate occupants and purpose through
   layout, furniture, possessions, wear, and small environmental stories.
5. Visual: streets, buildings, landmarks, props, composition, and interiors
   survive human review in the running game. Proposal dots, fixture counts, and
   automated tests cannot satisfy this gate.
6. Content: names and lore have the correct canon/proposal status, and the town
   has enough activity and minor detail to avoid feeling like a system demo.

`ship_candidate` additionally requires a complete visual review at target
resolution, performance review, and no known high-impact player-facing defect.

## Northgate Case Study

### NG-00 — Initial generated settlement

- Basis: Northgate seed `2701`.
- Problem: sparse, square town plan; square houses; weak terrain/location
  relationship; paths did not reach every building; too few minor POIs.
- Result: rejected visually.
- Reusable rules:
  - building placement needs offsets, rotations in composition, varied setbacks,
    and non-rectangular footprints;
  - road and footpath generation must connect every occupied structure;
  - terrain and POIs must be co-designed rather than generated independently;
  - flat regions still need drainage, vegetation, land use, and subtle relief;
  - minor POIs provide cadence and orientation, not just quest hooks.

### NG-01 — Spatial proposal refinement

- Changes: thick polyline streets, building footpaths, offset plots, irregular
  footprints, non-rectangular palisade, open gates, more contextual POIs, and
  flatter Marches terrain treatment.
- Evidence: settlement proposal JSON and generated settlement previews.
- Result: accepted as the runtime layout basis, not as final visual quality.
- Reusable rules:
  - approval must state exactly what is approved: here, layout basis only;
  - terrain barriers should separate regions where appropriate, but should not
    contradict an intentionally open, flat region such as the Marches;
  - preview legends must explain abstract markers and never imply finished art.

### NG-02 — Functional runtime activation

- Changes: activated terrain, collision, palisade and gates, 13 exterior/interior
  pairs, reciprocal portals, coach arrival/exit, residents, schedules, inn,
  trading, smithing and repair, notices, storage, one local quest, persistence,
  and 68 runtime furniture fixtures.
- Verification: Northgate real-pointer flows cover both coaches, all 13 building
  pairs, services, storage, quest completion, and save/load. Repository GUT run:
  764 tests across 23 suites with zero failures; four standalone real-click
  verifiers also passed.
- Result: `functional_only`.
- Known failure: the running town still looks generated and primitive. Furniture
  is symbolic, architectural composition is weak, streets lack density and
  environmental storytelling, and interiors do not yet meet the requested
  beautifully-authored standard.
- Reusable rules:
  - never translate “all systems work” into “the town is good”;
  - fixture presence and fixture uniqueness are data checks, not visual quality;
  - every completion report must state which acceptance gates were actually
    reviewed in the running game;
  - visual playthrough and screenshots are mandatory before `passable`.

### NG-03 — Required next pass

- Target: move Northgate from `functional_only` to `passable`.
- Preserve: working geometry contracts, services, quest, residents, schedules,
  coaches, and persistence.
- Re-author: street composition, architectural silhouettes, landmarks, prop
  density, surface detail, lighting, and every interior as an occupant-specific
  space.
- House-scale correction: current Northgate home exteriors occupy roughly
  `10x8` to `12x10` tiles, while Harrow's deliberately authored forge exterior
  is `6x3`. Northgate houses read as massive generated blobs because the
  building footprint consumes most of its plot. Treat the plot as house plus
  yard, access, work area, drainage, planting, and negative space. Author the
  actual building footprint compactly, using Harrow's structure as the current
  composition benchmark rather than filling a generated rectangle.
- Interior size is a separate abstraction from exterior footprint. A larger
  interior layer is acceptable only when its rooms, circulation, furniture,
  purpose, and occupant story justify the space; it must not become an empty
  box scaled up to hold fixture markers.
- Required evidence: before/after exterior and interior captures plus a written
  human playthrough verdict against all six acceptance gates.
- Current verdict: completed by NG-04. The compact footprint rule held up in
  the running game; broader town quality remains separately review-gated.

#### Provisional house-scale rule to test

- Start ordinary single-household exteriors near Harrow's `6x3` scale.
- Grow only for a visible reason: attached workshop, multiple households,
  public service, livestock, storage, or explicit wealth/status.
- Never derive wall footprint directly from the full plot rectangle.
- Review silhouette, yard-to-building ratio, doorway approach, and interior
  density in the running game before promoting this into a generator default.

## Rule Promotion

### NG-04 — Compact house and town composition pass

- Changes: re-authored Northgate household exteriors as compact Harrow-style
  facades near the `6x3` benchmark, left yards and plots open, condensed the
  active settlement footprint, tightened the road spokes, and preserved all
  existing portal and service IDs.
- Household authorship: all five homes retain a `10x8` interior abstraction but
  now use different fixture arrangements and identity-bearing details for a
  quiet craft household, multigenerational household, courier household,
  kitchen-garden household, and lodger household. Exteriors add timber bracing,
  stone foundations, eaves, household facade details, and plot-specific yard
  dressing instead of scaling the house to fill its plot.
- Live correction: the first live entry showed that spawning one tile from a
  `96px` exit interaction covered most of a compact room with the exit prompt.
  Entry spawns were first moved three tiles inside; NG-05 later established
  four tiles as the safe distance from the enforced `48px` door radius.
  Reusable rule: prompt coverage is part of interior composition and must be
  reviewed from the actual arrival point, not only from a clean capture.
- Evidence: final live captures cover the center, four street approaches, all
  13 exterior structures, and all 13 interior layers. The launched game loads
  the saved Northgate state at the condensed junction.
- Verification: Northgate data checks pass 76/76; Northgate pointer flows pass
  5/5; the full main-flow suite passes 101/101.
- Verdict: visual pass complete for house scale and settlement density;
  broader `passable` status remains review-gated. New identities and lore stay
  proposal-only.

### NG-05 — Public core authorship pass

- Baseline failure: civic buildings still consumed generated rectangles,
  service interiors auto-packed fixtures against one wall, the junction lacked
  usable street-edge activity, and several silhouettes depended on labels.
- Exterior changes: authored compact footprints for the shrine, guard post,
  hall, inn, stable, shop, storehouse, and smithy. Their plots now retain yards,
  loading space, hitching space, drainage, and negative space. Added a hall
  cupola, guard lookout, shrine arch, stable loft and stalls, store loading
  ramp, open smithy bay, inn dormers, and shop display windows.
- Interior changes: all eight public interiors now have explicit fixture
  positions, circulation zones, and at least six purpose-specific furnishings.
  Added shrine aisle, guard duty/sleep division, hall petition runner, inn
  service/common zones, stable stalls, shop counter line, store loading bays,
  and smithy hot-work zone.
- Street-edge changes: added market stalls, notice kiosk, hitching rails, horse
  trough, drainage stones, and retained the square well, benches, lanterns,
  work-yard props, signs, trees, and household details.
- Live correction: the old coach arrival overlapped the civic/service core and
  stole nearby door targeting. It now arrives on the east road between the inn
  and stable.
- Live correction: exterior `f` cells were mapped to walkable floor, allowing
  the player to appear on roofs. Surface footprints are now solid wall except
  for the authored door. This is a required generator contract, not a visual
  workaround.
- Live correction: two- and three-tile interior entry spacing allowed the exit
  hint to dominate some rooms because doors enforce a `48px` usability minimum.
  Entry spawns now land four tiles inside, beyond that radius.
- Live correction: the guard post occupied the north-road centerline, making
  the nominally walkable gate approach impassable in play. It now flanks the
  road opposite the shrine. The runtime check covers every tile from the north
  gate to the civic core so a future footprint cannot block the approach.
- Defense correction: palisade terrain, gate cuts, route POIs, and gate props
  had two competing coordinate definitions. They now share one defense layout.
  Gate approaches use the same five-tile width as the major town roads, while
  route markers are roadside signs rather than generic POI huts in the opening.
- Current verdict: materially improved but not yet a whole-town `passable`
  verdict. Remaining work is palisade/gate composition, terrain transitions,
  full live review of every public interior, and atmosphere/activity polish.

After a pass, promote broadly useful lessons into generator templates,
validators, capture tooling, or `CONTENT_GUIDE.md`. Keep subjective lessons in
this log when they cannot be validated mechanically. Validators should prevent
known structural failures; they must not pretend to certify taste.

### NG-06 — Proposal/runtime unification pass

- Baseline failure: the reviewed proposal still showed the old wide town while
  activation privately replaced streets, footprints, doors, and defenses with
  a compact layout. Preview approval therefore did not prove what players got,
  and the useful corrections could not transfer to another settlement.
- Generator correction: `settlement_templates_v6` now authors the compact town
  bounds, irregular fourteen-point palisade, gates, road widths, public square,
  individual plot yards, compact footprints, explicit door sides, and every
  building footpath. The settlement generator emits this as editable proposal
  geometry.
- Activation correction: removed all Northgate-only structure, archetype,
  street, portal, and defense remaps. Activation now promotes proposal origins,
  terrain rows, anchors, doors, streets, and palisade data directly. A runtime
  regression test compares every promoted structure, archetype, and portal to
  the proposal so the split cannot silently return.
- Scale correction: proposal-authored shells were still too large at live game
  scale. Homes now sit near `6x3`, while public shells grow only for visible
  function: hall `8x4`, inn `10x5`, stable `7x6`, shop/store `7x4`, and smithy
  `8x5`. Their larger interiors remain a separate authored abstraction.
- Surface correction: moved dressing out of collision after the new geometry
  exposed eight overlapping props. Non-gate surface details are now required
  to occupy walkable tiles; gate towers derive from reviewed gate coordinates.
- Access correction: the Briarwatch coach portal was hidden under the market
  cart and NPC cluster. It now has a separate walkable roadside position, and
  the live game can target and use it normally.
- Live evidence: travelled from Briarwatch through the coach, reviewed the east
  service road, junction square, north road, north gate, shrine, guard post,
  hall, inn, stable, smithy, and compact home facades. The north approach and
  central roads remain clear. Guard entry opens on the interior without an exit
  prompt covering the room.
- Current verdict: exterior composition is materially closer to passable and
  the review artifacts are now trustworthy. Full post-NG-06 review of every
  interior, south/west edges, and resident activity is still required.

### NG-05 — Runtime coordinate correction and visual recheck

- Root cause found after live review: the previous pass compacted decorative
  plot rows, but runtime structures, portals, and street targets still used the
  old wide coordinates. The live town therefore remained visually similar.
- Changes: compacted runtime structure origins and exterior archetype sizes,
  rebuilt local street targets around the junction, kept the approved palisade
  and gate geometry, applied the Harrow/Briarwatch facade treatment to all
  Northgate exteriors, and remapped yard props into the compact plots.
- Capture tooling now waits for streamed chunks before saving and centers each
  building view correctly.
- Human visual review: launched game, loaded the Northgate save, inspected the
  condensed center and street views, five home exteriors, and all thirteen
  interiors. The town is materially more compact and authored than NG-04's
  actual runtime, but final subjective approval remains review-gated.
- Verification: data suite 77/77; main-flow suite 102/102. These checks do not
  substitute for the visual verdict above. New identities and lore remain
  proposals.

### NG-07 — Room-language and lived-activity pass

- Baseline failure: fixture data said the right things, but clean runtime
  captures reduced many rooms to sparse symbols inside similar rectangles.
  Household variants also inherited the same hearth, table, bed, and chest
  positions, so their identity props could not overcome the repeated layout.
- Household correction: the five homes now override their shared furniture
  positions by household identity. Quiet craft, multigenerational, courier,
  kitchen-garden, and lodger homes have different circulation, work, sleep,
  storage, and guest zones. Rugs, wall details, windows, work traces, papers,
  herbs, jars, boots, pegs, and partitions reinforce those uses at room scale.
- Public-room correction: shrine, guard post, hall, inn, stable, shop,
  storehouse, and smithy gained purpose-readable room-scale composition beyond
  their interactive fixture markers. The inn now has a stocked bar, four
  furnished tables, lights, and a guest nook; the hall has a dais, petition
  benches, and wall records; stable stalls have rails, straw, tack, and a worn
  aisle. Shop, storehouse, smithy, shrine, and guard spaces received equivalent
  operational detail.
- Activity correction: all Northgate schedule bindings existed, but activation
  assigned generic combat behavior to every civilian except the shopkeeper.
  Every bound civilian now starts under `civilian_schedule`; combat can
  interrupt it and the existing recovery path restores the schedule afterward.
- Streaming correction: schedule state changed correctly while actors were
  unloaded, but their streamed spawn locations remained at their original
  interiors. Entity streaming now adopts the current schedule destination, so
  residents materialize in a loaded square, workplace, inn, or patrol area.
- Exterior-edge correction: live south-edge review exposed broad empty grass and
  household props left at obsolete pre-v6 coordinates outside the palisade.
  Home plots now author proposal-level soil zones with a reusable walkable soil
  terrain material. Wash lines, gardens, benches, firewood, fences, trees, and
  barrels sit inside their actual yards. Roads and footpaths override soil where
  they cross it.
- Civic-anchor correction: the resident gathering point and guard patrol still
  referenced pre-v6 coordinates. Both now derive from the proposal-authored
  public-square rectangle and north gate. Eight walkable square anchors prevent
  five residents from stacking on one tile.
- Reusable rules:
  - fixture names and counts do not prove that a room reads correctly;
  - shared building profiles may supply essentials, but occupant variants must
    be allowed to reposition those essentials, not merely append identity props;
  - public rooms need large compositional zones as well as small interactive
    objects;
  - a schedule binding is incomplete unless the spawned actor actually runs the
    schedule brain;
  - off-screen schedule state must also drive streamed spawn location;
  - yard terrain and props must be reviewed against the current proposal, not
    carried forward as activation-only coordinates;
  - civic and patrol anchors derive from reviewed public-space and gate geometry;
  - clean contact sheets are the review contract for all rooms, while pointer
    flows separately prove traversal and interaction.
- Evidence: refreshed clean runtime contact sheets cover all 13 interiors and
  all 13 exteriors under `reports/northgate_live_reauthored`. Focused generation,
  activation, renderer, all-building pointer traversal, services, quest,
  combat interruption, recovery, and schedule-resume tests pass. The activation
  suite now checks every Northgate-bound NPC actor, every walkable square
  activity anchor, and the proposal-derived guard patrol. Activity captures
  show five residents across the real square at 09:00, three residents there at
  18:00, and the guard at the north gate at 18:00. Final repository verification
  passes 797 tests across 23 suites with zero failures, plus all four standalone
  real-pointer verifiers.
- Current verdict: `passable`. All thirteen interiors, all thirteen exteriors,
  center and four edges, gates, building paths, household yards, public
  activity, services, quest flow, and schedule recovery have current runtime
  evidence. This is a baseline for future towns, not a claim that later art
  direction cannot improve it. New household identities and implied stories
  remain proposal-only.

### NG-08 — Independent visual re-audit

- Date and basis: 2026-07-12; Northgate seed `2701`,
  `settlement_templates_v6`, and the post-NG-07 runtime captures.
- Reason for review: NG-07's `passable` verdict overstated player-facing visual
  quality. The generated source assets are often attractive in isolation, but
  their runtime application does not form a coherent authored town.
- Evidence reviewed:
  `reports/northgate_live_reauthored/northgate_complete_town.png`,
  `streets_contact_sheet_final.png`, `exteriors_contact_sheet_final.png`, and
  `interiors_contact_sheet_final.png`, compared directly with
  `reports/northgate_art_direction/northgate_target_v1.png`.
- Exterior failures: stretched roof images read as decals; building scale and
  perspective vary; broad rectangular roads overpower the buildings; terrain
  repeats as a visible debug grid; palisade segments read as decoration rather
  than a defensive structure; props are scattered instead of grouped into
  believable work, storage, domestic, and circulation zones.
- Interior failures: rooms remain similar empty brown rectangles; furniture is
  too small and visually floats on the floor; wall construction, occlusion,
  lighting, room division, and occupant-specific composition are too weak to
  carry the claimed lived-in quality.
- Whole-frame failures: the runtime mixes painterly generated assets,
  procedural terrain, fallback sprites, actor art, and a large HUD without a
  shared scale or perspective. Detail quantity does not overcome that visual
  mismatch.
- Verification: this was a screenshot-based human review. No new automated
  tests or pointer flows were run, and no new in-game playthrough is claimed.
- Revised current verdict: `functional_only`. NG-07 remains valuable evidence
  for systems, schedules, traversal, and content coverage, but its visual gate
  is not accepted by this later review.
- Next-pass method: stop applying town-wide polish. First author one
  gameplay-sized benchmark scene containing a road edge, inn, smithy, yards,
  props, terrain, actor, and exploration HUD. Lock scale, perspective,
  transitions, layering, and composition there before propagating the visual
  grammar across Northgate.
- Reusable rules:
  - asset approval and asset application approval are separate gates;
  - contact-sheet coverage proves that areas were captured, not that they look
    good;
  - a settlement cannot pass visual review while its major asset families use
    conflicting scale, perspective, lighting, or edge treatment;
  - prop density must communicate purpose through clusters and circulation,
    not object count;
  - benchmark one representative gameplay frame before spending another pass
    across an entire settlement;
  - later independent review may downgrade an earlier verdict, but must append
    the evidence and reasoning instead of rewriting history.

### NG-09 — Building pass 01: coaching inn

- Date and basis: 2026-07-12; Northgate seed `2701`,
  `settlement_templates_v6`; first building-by-building cleanup after NG-08.
- Player-facing problem: the accepted `320x82` coaching-inn roof was stretched
  over a `10x5` collision footprint, making it deep and muddy. Its `18x12`
  interior was a mostly empty brown box containing nine isolated fixture
  sprites. Yard props sat far from the building or merged with stable dressing.
- Exterior correction: reduced the authoritative inn footprint to `10x3`,
  moved its west door and reciprocal portal with it, removed the unrelated
  lean-to overlay, and regrouped the sign, hitching rail, cart, rain barrel,
  basket, barrels, woodpile, and bench into a coaching-yard composition. The
  template, reviewed proposal, runtime overlay, and activation tool carry the
  same geometry and coordinates.
- Interior correction: reduced the room abstraction to `14x10`; authored a
  continuous backbar/service zone, worn circulation, guest-nook partition, and
  wall windows; expanded the bar and backbar; grouped common-room seating; and
  moved the innkeeper behind the bar. The interactive bed now renders with the
  accepted bed asset instead of an orange fallback marker.
- Rejected attempts:
  - nine-slice-like vertical roof extension was rejected because its stretched
    middle band produced obvious vertical shingle smears;
  - concentric fake light pools were rejected because they read as painted
    circles rather than lighting;
  - a procedural south facade strip was rejected because it clashed with the
    painterly roof more than the shallow roof-only volume did.
- Capture tooling: `capture_northgate_runtime_live.gd -- --inn` now captures
  only the inn exterior and interior, shortening the visual iteration loop.
- Evidence:
  `reports/northgate_live_reauthored/clean_building_inn.png` and
  `clean_interior_inn_plot.png`. Full gameplay captures were also produced.
- Verification: data 80/80, main flows 102/102, world 48/48. The real-pointer
  Northgate flows still cover inn entry, trade, rest/service routing, all
  building portals, and persistence-sensitive services.
- Playthrough note: automated real-pointer traversal and interaction passed.
  Human review covered the clean running-game exterior and interior. A separate
  black-rectangle artifact remains visible in non-clean HUD captures and must
  be diagnosed before claiming town-wide player-facing visual acceptance.
- Verdict: coaching inn `passable`; Northgate remains `functional_only` under
  NG-08. Do not move this building to `ship_candidate` without user visual
  approval and a clean gameplay/HUD capture.
- Reusable rules:
  - fit authoritative collision geometry to an accepted asset's intended
    proportions instead of deforming the complete asset to an old shell;
  - interior size is a visual-density decision, not a prestige score;
  - adjacent full-size prop sprites need more than one tile of spacing unless
    their source art was explicitly designed to join;
  - reject procedural additions when their rendering language clashes with the
    stronger painted asset;
  - add a focused capture selector before iterating one building repeatedly;
  - record rejected visual experiments, not only the retained result.
