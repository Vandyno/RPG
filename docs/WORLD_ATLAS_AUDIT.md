# Velcor Atlas Audit

Status: proposal. This document is a reconciliation pass, not canon and not
generator input yet.

Sources reviewed:

- `docs/reference/velcor_continent_tangle_rootborn_shattered_isles.png`
- `MAP.md`

## Result

The two sources agree on the continent-scale layout. `MAP.md` is a useful
semantic interpretation of the image, but it lacks the exact anchors and
geometry needed by a generator. The image also contains several named places
which the prose index does not yet record.

Treat the image as visual evidence and `MAP.md` as intent. A reviewed atlas
data file must make any conflict explicit instead of silently choosing one.

## Confirmed Macro Layout

| Area | Image position | `MAP.md` reading | Audit |
| --- | --- | --- | --- |
| Hollow Coast | western coast | western coast | aligned |
| Elderweald | northwest mainland | northwest forest | aligned |
| Shadegroves | north-central/east of Elderweald | north of the Marches | aligned |
| Tangle Heights | northeast | northeast mountains | aligned |
| Marches of Velcor | central mainland | central human heartland | aligned |
| River Veyn | north-central to southern heartland | central river/trade route | aligned |
| Lake Orin | east | east of Dunmere/Greenford | aligned |
| Blackwater | east of Lake Orin | eastern dark water | aligned |
| Mireveil | southwest mainland | southwest wetland coast | aligned |
| Greyfang Range | southeast | southeast mountains | aligned |
| Iron March | southeast/east of Greyfang | southeast | aligned |
| Shattered Isles | southwest/west offshore | southwest/west offshore | aligned |
| Ashen Isles | south of Iron March | southeast forge-adjacent islands | aligned |

## Confirmed Settlement And Site Reading

| Place | Image reading | `MAP.md` role | Audit |
| --- | --- | --- | --- |
| Briarwatch | western Elderweald frontier road | human/Rootborn frontier town | aligned |
| Northgate | north of Cairnwall on the northern road | northern junction | aligned |
| Stonebridge | northern River Veyn crossing | river crossing connector | aligned |
| Cairnwall | western-central city | sacred city | aligned |
| Dunmere | central-eastern river city | trade hub | aligned |
| Greenford | east/northeast heartland | eastern connector | aligned |
| Hallowrest | south of Cairnwall | pilgrimage town | aligned |
| Mirthbridge | southeast of Dunmere | river-adjacent town | aligned |
| Fairmead | Greyfang approach | agricultural town | aligned |
| Valeham | Cairnwall/Hallowrest route | inland chapel settlement | aligned |
| Wensford | western coast road | coastal access town | aligned |
| Redfield | southwest road | Mireveil-edge farm town | aligned |
| Oakholt | south/east of Redfield | timber/wetland-edge village | aligned |
| Southwatch | southern isolated route | fort/hold | aligned |
| Laford | Lake Orin east shore | lake town | aligned |
| Duskford | southeast Lake Orin route | Blackwater-adjacent town | aligned |
| Mosshollow | Elderweald | Rootborn gathering | aligned |
| Stepcliff Monastery | Tangle Heights | monastery/shrine | aligned |
| Branchrest | southern Tangle Heights approach | Tanglekin trade hub | aligned |
| Karag-Tor | Iron March | Tuskfolk stronghold | aligned |
| Ashforge Hold | southern Iron March/Oathroad | Tuskfolk forge hold | aligned |

## Image Labels Missing From The Current Index

These appear on the reference image but need an explicit decision before they
are generator inputs:

- Blackrook Archive Isle (the prose says Blackrook Archive near the coast;
  record whether the isle wording is canonical)
- The Last Perch, Raven Site
- Saltspring, Smuggler Port
- Mudwake, Reef Village
- Greywake, Smuggler Cove
- Wreckpoint, Smuggler Cove

The image also contains minor unlabeled settlement and route markers. They are
not automatically locations until reviewed.

## Interpretation That Needs Explicit Atlas Data

`MAP.md` describes useful pressures that are not geometric map data yet:

- Greenwood Boundary placement and extent
- Rootborn/Tanglekin coexistence area
- human/Mirefolk practical-overlap routes
- cult influence areas
- road hierarchy: major, trade, minor, canopy, cliff, ferry
- political and cultural boundary paths

These should become named polygons, paths, or point fields. Do not leave a
generator to infer them from a painted map.

## Required Generator Input

The next proposal should be `data/world_atlas_proposal.json`, with editable
world coordinates or normalized coordinates for:

- coastline and water exclusion
- region polygons and biome weights
- rivers, lake boundaries, mountain barriers, passes, and forests
- settlement anchors, type, size band, and protected identity
- road/ferry/canopy/cliff networks with required links
- faction, people, cultural, and cult pressure zones
- approved landmark and POI anchors

Every generated place must cite an atlas region and seed. The generator may add
minor roads, hamlets, farms, caves, ruins, and local POIs only within that
region's constraints. It may not move a named place, replace a major route, or
invent lore as canon.

## Review Gate

Before the atlas becomes runtime input, review:

1. missing image labels and their canon status;
2. each named settlement's anchor and type;
3. every required route and natural barrier;
4. coexistence, political, and cult zones;
5. first playable region bounds.
