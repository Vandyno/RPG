# Northgate Art Direction

Runtime layout remains authored in Godot. Generated images provide concept and
source material only; they do not own collision, portals, schedules, or object
placement.

## Visual Target

Reference: `reports/northgate_art_direction/northgate_target_v1.png`

- compact low-fantasy road town;
- irregular timber buildings with steep roofs and stone footings;
- muddy, worn lanes with drainage, wheel ruts, and soft edges;
- dense purposeful yard detail rather than empty grass or decorative noise;
- distinct inn, hall, smithy, stable, shrine, and gate silhouettes;
- muted moss, umber, soot, ochre, rust, oak, and slate palette;
- small amber windows; no cyan glass, bay windows, modern trim, or neon;
- every home gets a unique roof, extension, yard use, and household props.

## Asset Pipeline

1. Generate coherent building and prop source sheets against a removable flat
   background.
2. Remove the background and cut selected elements into separate source PNGs.
3. Paint down and simplify them for the current `32 px` tile scale.
4. Import sprites as visual overlays only. Existing structure terrain remains
   the authoritative collision footprint.
5. Build side-aware walls, doors, and service silhouettes in Godot, then fit
   reviewed generated roof material inside the authoritative footprint.
6. Recapture the full town after every building or prop family.

Whole-town generated paintings are never shipped as a map layer. They cannot
preserve interaction alignment, occlusion, animation, or runtime state.

## Source Review

- `northgate_buildings_source_v1`: accepted for palette, material, roof, and
  facade-detail reference; rejected for direct runtime use because its camera is
  too frontal and its silhouettes are too tall for the authored footprints.
- `northgate_cottage_pilot_v1`: rejected for runtime use. A stricter prompt still
  produced a frontal elevation, proving that whole generated buildings are not
  reliable enough for collision-faithful overhead sprites.
- Runtime building sprites must use a roof-dominant overhead view, with only a
  shallow south wall visible. The entrance threshold must align to the authored
  portal tile and the opaque footprint must not imply collision outside the
  structure rect.
- Image generation is approved for isolated overhead props, material studies,
  roof/wall source texture, and broad art direction. Buildings are assembled and
  aligned deliberately from those pieces.

## Prop Pilot Verdict

`northgate_props_source_v1` passed the first live town comparison. Twenty props
were chroma-keyed, cut, downscaled, and imported. Their overhead silhouettes and
materials are a clear improvement over fallback vector shapes while their world
positions remain ordinary authored entities. Keep this pipeline.

The prop pass makes the remaining flat building facades more obvious. The next
asset family is isolated overhead roof modules, followed by shallow authored wall
strips. These can be fitted to exact structure rects without introducing hidden
collision.

`northgate_roofs_source_v1` passed the live footprint test after deliberate
normalization. The generated material and roof detail are retained, while Godot
still owns final width, depth, wall strip, entrance side, chimney, landmark, and
portal alignment. Bright procedural gold trim was reduced after the close-up
review because it read as UI chrome against the painted assets.

`northgate_ground_source_v1` passed only for road and work-yard wear: mud,
ruts, drainage stone, ash, straw, scattered grain, and broken timber. Generated
vegetation patches were rejected from runtime because their baked dirt circles
looked pasted onto grass and made the settlement feel generated again.

`northgate_facades_source_v1` is retained as material reference but rejected as
a runtime facade layer. Even after fake doors were removed, front-elevation wall
strips read as pasted scenery in the top-down world. Runtime exteriors now use
Harrow's forge grammar: the roof owns most of the footprint, only the inhabited
entry edge is visible, and the authoritative portal is drawn in that edge.

`northgate_interior_props_source_v1` passed after the old procedural furniture
and service-zone overlays were removed. Generated beds, tables, counters,
hearths, shelves, storage, benches, workbenches, and shrine pieces are visual
fixtures only. Interior wall/floor terrain remains the sole collision authority.

## Runtime Review Result

- all thirteen exteriors now use roof-dominant top-down volumes;
- side-entry doors sit in visible wall edges instead of floating over roofs;
- the palisade and buildings were pulled inward around bent, softened roads;
- exterior and interior legacy underlays no longer show behind painted art;
- all thirteen interiors were recaptured at inspection zoom and reviewed;
- homes use different fixture combinations and restrained floor accents;
- generated facades and generated vegetation remain excluded from runtime.

## Roof Variant Pass Two

`northgate_roofs_source_v2` was generated from the accepted roof material
language to reduce repeated silhouettes. Five cottage roofs, a hipped civic
roof, a soot-dark smith roof, a hayloft stable roof, and narrow lean-to annexes
passed live review. The two L-shaped modules were rejected as primary runtime
roofs because their transparent corners exposed rectangular wall underlays and
made buildings look cut in half. They remain source material only.

The final runtime also uses a separate `worn_ground` terrain material for the
market, coach yard, and smith yard. It is walkable, has softened irregular edges,
and deliberately avoids the crop furrows used by garden `soil` tiles.

The retained ground-decal pilot was later rejected in the complete-town review.
At gameplay scale even the contextual mud, ruts, ash, straw, and stone cuts read
as brown pasted blobs. Runtime streets now use deterministic material marks and
subtle authored edge variation instead.

`northgate_facades_source_v1` is rejected for direct runtime use. The wall strips
were attractive in isolation but remained front-elevation paintings pasted into
a top-down world. They also forced portal doors onto unrelated side edges. The
runtime renderer now follows Harrow's spatial grammar: roof-first footprint,
narrow wall only on the authored entry side, portal embedded in that wall, and
service landmarks assembled separately.

`northgate_interior_props_source_v1` passed after aggressive downscaling,
checkerboard removal, premultiplied-alpha resizing, and live room review. Beds,
tables, shelves, counters, hearths, workbenches, storage, and shrine furniture
replace abstract fixture rectangles. Godot still owns fixture placement and
interaction; the sprites do not create collision. Image generation remains
useful for isolated props, not room layouts.
