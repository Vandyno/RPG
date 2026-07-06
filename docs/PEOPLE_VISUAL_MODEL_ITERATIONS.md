# People Visual Model Iterations

Status: proposal, not canon final art.

Purpose: record the current visual-model direction for playable peoples and
humanoid NPC peoples. The screenshot progression is saved under:

```text
reports/people_iterations_v7/
```

Latest crowd-scale and feature-detail proof is saved under:

```text
reports/people_iterations_v51/
```

The reusable archetype data is authored in:

```text
data/people_visual_models.json
```

## Screenshot Rounds

- `round_01.png`: baseline humanoid stack. This proved the problem: the peoples
  were too similar if only palette changed.
- `round_02.png`: proportion pass. Tanglekin became leaner, Tuskfolk shorter
  and stockier, Mirefolk lower and wider, Ravenfolk taller/robed, Rootborn
  taller/rooted.
- `round_03.png`: feature pass. Added tusks, high amphibian eyes, hood/mask,
  and leaf crown. The old Tanglekin motion-cord read is superseded by the
  simian tail/hands/muzzle direction.
- `round_04.png`: gameplay-readability pass. Added stronger body planes so the
  shapes read at small scale and can accept armour later.
- `round_05.png`: variant pass. Added marks and secondary shapes to support many
  authored variants instead of one-off hero designs.
- `round_06.png`: Ravenfolk logic pass. Kept Ravenfolk humanoid, rare, severe,
  robed, and archive-coded. No full bird body or functional wings.
- `round_07.png`: breadth proof for the seventh archetype slot.
- `round_08.png`: full breadth proof for the eighth archetype slot.

The v42 split-labeled, crowd, people-family, turnaround, population-stress, and
hundred-look sheets are the current live-renderer candidate direction. They
prove that people defaults plus `people_visual_models` variants compose into
previewable `HumanoidProfile` appearances with visual model IDs, feature IDs,
palettes, and proportion deltas, then render through `HumanoidAvatar2D`.

v5 added side and back reads. v6 expands the reusable set to 8 archetypes per
people and captures every archetype slot. v7 adds small role accents derived
from `visual_model_id`, such as aprons, wraps, belts, sashes, and shawls. The
renderer avoids generic hair/face layers where they muddy non-human peoples,
especially Mirefolk and Ravenfolk.

v8 adds all-people crowd sheets: all 48 reusable archetypes labeled together,
small-scale rows, and one mixed crowd with no labels. This proves the variants
still read when used as a population set rather than isolated card art.

v9 narrows Ravenfolk from a wing-like mantle to a humanoid robe plus feather
collar, keeping the archive/omen read while avoiding full bird anatomy. It also
adds `round_04_people_families.png`, a clean quick-review sheet with three
representative examples per people.

v10 added one reusable feature layer for each non-human people in that pass.
The old Tanglekin wrap-band direction is superseded; Tanglekin now use simian
tail, grasping hand/foot, muzzle, and brow-tuft features. Tuskfolk clan marks,
Mirefolk webbed hands, Ravenfolk ink beads/quill marks, and Rootborn branch
crown remain useful shared-avatar marks.

v11 tightens that pass: Rootborn branch crown is shorter and less antler-like,
Mirefolk webbed hands are more readable, and `round_05_turnaround.png` captures
front, side, and back reads for one representative of each people.

v12 expands breadth from 8 to 12 archetypes per people, increasing the reusable
set from 48 to 72 visual archetypes. The labeled proof is split into
`round_01a_variants_01_06_labeled.png` and
`round_01b_variants_07_12_labeled.png` so the larger set remains reviewable.

v13 fills the role-accent coverage gaps for the expanded 72-archetype set. Every
variant now resolves to a small readable role cue, while keeping people
silhouette and equipment anchors as the primary visual contract.

v14 is a shape-rule pass. Tuskfolk defaults became shorter and broader, with a
heavier face/jaw read, so every inherited variant starts squat. Ravenfolk gained
a sharper hood/mask silhouette and clearer feather-collar details while staying
humanoid, robed, and wingless.

v15 expands breadth from 12 to 16 archetypes per people, increasing the reusable
set from 72 to 96 visual archetypes. The capture tool now creates labeled pages
dynamically, including `round_01c_variants_13_16_labeled.png`, so future
population expansions remain visible in screenshots.

v16 adds `round_06_population_stress.png`, a generated proof of 144 NPC looks
that mix archetype, facing, locomotion, sneak posture, weapons, and offhand
shield visuals. This checks whether the peoples remain readable once the same
shared humanoid avatar is used at population scale.

v17 adds per-variant hair and marking support. Human variants now preview with
different hair colors, while representative non-human variants use small marks
such as brow marks, cheek dots, chest bands, hand wraps, leaf specks, and ash
streaks. These marks are deliberately secondary to people silhouette.

v18 adds one hundred-look proof sheet per people:
`round_07_human_hundred.png`, `round_07_tanglekin_hundred.png`,
`round_07_tuskfolk_hundred.png`, `round_07_mirefolk_hundred.png`,
`round_07_ravenfolk_hundred.png`, and `round_07_rootborn_hundred.png`.
These sheets generate 100 examples per people from the same 16 archetypes plus
markings, motion, facing, weapons, and shield overlays.

v19 adds a third palette to each non-human people and tightens the Tuskfolk
shape rule. Tuskfolk are now a little shorter and stockier by default, with test
coverage to keep every generated Tuskfolk variant squat and broad. Ravenfolk
remain provisional: the current logic is a hooded archive-omen humanoid with a
feather collar, ink beads, and mask/beak suggestion, not a full bird body.

v20 strengthens the Ravenfolk read without changing the humanoid rule. Every
Ravenfolk archetype now keeps the mask/beak feature, and the renderer gives the
hood, face mask, beak-mask, and feather collar clearer tiny-scale shapes. This
keeps the current direction wingless and humanoid while reducing the risk that
Ravenfolk read as only dark robed humans.

v21 tightened the old Tanglekin placeholder direction, but that direction is no
longer canonical. Tanglekin are now monkey-like humanoids; the renderer and
visual models should use tails, grasping hands/feet, muzzles, brow tufts, long
arms, and agile posture instead of cords, ropes, or baked-in wraps.

v22 tightens Rootborn. Branch crowns are shorter and narrower, with small leaf
buds at the tips, and leaf crowns are less antler-like. Branch-crown variants
must now keep bark or leaf context so the people read stays plant/root-based.

v23 tightens Mirefolk. A pale throat/belly patch, stronger reed cheek marks,
and foot webbing make the amphibian read survive side and back-facing
population shots better. Every Mirefolk archetype now keeps either high eyes or
webbed hands so the wetland people read does not collapse into generic green
humanoid.

v24 tightens Humans. Human variants now author hair-shape IDs, and the renderer
draws distinct short waves, close crops, side parts, tied-back hair, wide curls,
and shaved crowns. This keeps Humans ordinary and baseline-readable while giving
hundreds of generated townspeople more population breadth.

v25 tightens Ravenfolk logic. The renderer now treats the mask/beak signal as a
front/side-facing mask instead of drawing it on the back view, strengthens the
mask geometry, and adds robe hem plus bead/seal detail. Every Ravenfolk
archetype now keeps either mantle or ink beads so the archive-read remains
visible without adding full bird anatomy or wings.

v26 tightens Tuskfolk. The renderer adds a heavier lower-torso cue, makes
tusks/jaw/brow front-and-side aware, and keeps the back view broad without
showing face details. Test coverage now preserves the short height, broad
shoulders, broad waist, strong feet, and tusk identity across every Tuskfolk
archetype.

v27 tightens Tanglekin population read. Wrap-band variants now show small hand
and ankle wraps, motion-cord variants keep a clearer back-facing cord path, and
loose cord knots are visible on front/side reads. Test coverage now preserves
their tall, lean proportions plus cord/wrap identity across every archetype.

v28 tightens Rootborn rootedness. The renderer adds subtle root-spur marks at
the feet and trunk-like bark lines on bark-mark torsos, while test coverage
preserves tall/rooted proportions plus leaf or bark identity across every
Rootborn archetype.

v29 tightens Mirefolk facing logic. Mouth and reed cheek marks now draw only on
front/side-facing views, high raised eyes keep the back silhouette without
front-facing pupils, foot webbing follows stride offsets, and rear reads gain
small damp back spots. Test coverage now preserves wide heads, broad feet, and
amphibian cues across every Mirefolk archetype.

v30 is a final-candidate audit capture with no art-system changes. It preserves
the v29 renderer and data, and exists as a broad proof set for mixed crowds,
families, turnarounds, population stress, and hundred-look sheets.

v31 applies the Tuskfolk proportion call more strongly. The shared Tuskfolk
baseline is now lower and broader, so every variant inherits a little shorter
and stockier shape rule before individual deltas apply. Ravenfolk remain
deliberately provisional: current visuals are humanoid robe, hood, feather
collar, ink beads, and mask/beak cultural language, not final bird anatomy.

v32 tightens Ravenfolk without solving them biologically. The renderer gives
the ritual mask a sharper front/side shape, extends the mask-beak signal,
adds small collar notches, and gives ink-bead variants tiny quill/seal cues.
This makes Ravenfolk read more like robed archive witnesses and scribes, while
still avoiding wings, bird legs, full bird bodies, or final anatomical beaks.

v33 is a population-breadth pass. Role accents now receive deterministic tinting
from each visual model ID, which makes hundred-look sheets less same-costume
without adding random generation or a deeper clothing pipeline. This helps
Humans and Tanglekin most, but benefits all peoples while preserving silhouette
and people-specific feature layers as the primary read.

v34 tightens Rootborn. The renderer now gives every Rootborn subtle trunk-ring
bands and stronger root-foot flares, while bark-mark variants gain heavier face
and torso grooves. This pushes the repeat-crowd read toward bark/root/sprout
and away from generic green humanoids or elves.

v35 tightens Tanglekin. The renderer strengthens wrap-band thickness, waist
knots, hand/ankle wraps, and lower torso cord anchors so the cord/wrap identity
survives hundred-look sheets better. The motion-cord stays torso-bound and
back-readable, avoiding the old halo-like read.

v36 tightens Ravenfolk population breadth. The renderer now derives muted robe
undertones, hem seams, and small archive-seal tags from the visual model ID.
This makes hundred-look crowds less same-costume while keeping Ravenfolk
provisional, humanoid, dark, hooded, robed, mask-led, and wingless.

v37 tightens Human population breadth. The shared avatar now adds a Human-only
cloth panel with deterministic tunic tint, hem, trim, and small front/back
details derived from visual model ID. This keeps Humans ordinary and baseline,
but makes large town crowds less cloned before final clothing art exists.

v38 tightens Tuskfolk population breadth. The renderer now derives muted
clan-band tint, a heavy belt/buckle detail, and small tusk-ring marks from
visual model ID. This adds clan/craft identity while preserving the main
Tuskfolk rule: shorter, broader, stockier, and grounded.

v39 tightens Mirefolk population breadth. The renderer now derives muted throat
tint, belly spots, web tint, reed-mark color, and back spots from visual model
ID. This keeps the frog-like wetland humanoid read while adding damp/reed
variation for hundred-look crowds.

v40 tightens Rootborn population breadth. The renderer now derives growth tint,
lichen patches, varied sprout lift, extra leaf buds, and bark-band variation
from visual model ID. This keeps the bark/root/leaf read while making Rootborn
crowds less same-crowned and avoiding elf or antler language.

v41 tightens Ravenfolk mask/collar identity. The renderer strengthens mask trim,
lower mask scoring, collar notches, shoulder points, seal beads, and beak-mask
scoring. This helps Ravenfolk read as distinct robed archive-omen humanoids
without adding wings, bird legs, back-facing face details, or final bird
anatomy.

v42 fixes two visual-read bugs found in screenshot review. Tanglekin motion
cords no longer draw a low dangling front/side strand that could read as a tail
coming through the body; they now stay as shoulder, torso, and waist wrap
language. Mirefolk without the high-eye feature now still draw small visible
front/side eyes, while high-eye variants keep the stronger raised-eye read.

v43 redesigns Ravenfolk away from the provisional robed/masked read. Ravenfolk
are now slender feathered humanoids: narrow body defaults, visible body-feather
rows, head crests, true beaks, optional tail feathers, and quill marks. Robes,
hoods, and clothing are no longer part of the people layer; they must come from
equipment or authored worn items.

v44 corrects a lore drift in Tanglekin. The old cord/wrap visual language is now
superseded. Tanglekin are monkey-like agile humanoids with visible tails,
grasping hands/feet, small muzzles, brow/ear tuft features, and nimble posture.
Mirefolk defaults are shorter and slenderer while keeping amphibian heads, high
eyes, and webbed feet. Tuskfolk tusks now mount from the lower face/jaw instead
of floating outside the head silhouette. Ravenfolk torso quill marks no longer
use yellow/bone accents near the lower torso.

v45 removes the remaining pale lower-torso Ravenfolk quill marks. Ravenfolk
quill detail is now dark feather detail only, so the body read stays feathered
instead of looking like stray clothing, medals, or grey/yellow torso ornaments.

The first in-game debug appearance creator now opens with `P`. It can cycle
people, visual variants, facing buckets, and simple gear previews, then apply
the selected generated appearance to the player for fast inspection.

v46/v47 add the first full 16-direction people consistency pass. The renderer
now gives torso, waist, side seams, back planes, Tanglekin tails, Tuskfolk
tusks/clan marks, Mirefolk belly/eyes/webbing, Ravenfolk feathers/beaks, and
Rootborn crowns/body marks different front, side, diagonal, and back reads
instead of drawing the same feature shapes at every angle. The capture tool can
filter to `sixteen_turnaround`, and the larger proof sheet lives at:

```text
reports/people_iterations_v47/round_05b_16_direction_turnaround.png
```

v48/v49 add large per-people 16-direction zoom sheets for all 16 variants per
people. Tanglekin side/back reads were tightened with a stronger tail curve and
rear ear read, while keeping the tail behind the body layer instead of letting
it pass through the front.

v50/v51 add larger 16-direction detail proof pages, split into four variants
per page so individual angle bugs are readable. Ravenfolk tail feathers now hide
on direct front buckets and grow toward side/back buckets, and head crests
compress/shift by facing direction instead of stamping the same shape on every
angle. Current proof pages live under:

```text
reports/people_iterations_v51/round_09_<people>_16_detail_<range>.png
```

## Current Calls

- Humans: average baseline, broadest normal variation through hair shape, hair
  color, cloth tint, tunic/hem trim, equipment, complexion, markings, and
  regional styling.
- Tanglekin: monkey-like agile humanoids. Use shorter lean bodies, long arms,
  grasping hands/feet, visible tails, small muzzles, brow/ear tufts, and nimble
  posture. Do not use cord/wrap language for their people layer; wraps and
  clothing must come from equipment.
- Tuskfolk: shorter and stockier as a rule. Broad shoulders, broad waist, strong
  hands/feet, visible tusks, clan marks, waist bands, and small tusk rings. This
  is visual shape, not a movement penalty.
- Mirefolk: frog-like wetland humanoids. Shorter and slenderer bodies, wide
  head, high eyes, pale throat/belly, webbed hands/feet, damp greens/blues,
  subtle reed marks, small wetland spots, and always-visible front/side eyes.
  Not swamp monsters.
- Ravenfolk: slender feathered humanoids. Use narrow shoulders/torso/waist,
  body-feather rows, dark feather palettes, head crests, true beaks, quill
  marks, and small tail-feather attachments. Clothing and robes must come from
  equipment, not people appearance. Avoid functional wings for first playable
  pass.
- Rootborn: bark/leaf/root silhouette, older and stranger than humans. Use
  trunk rings, rooted feet, bark grooves, lichen patches, leaves, and short
  twig/sprout crowns. Do not drift into generic elves. Branch crown is useful
  only as twig/sprout language, not antlers.

## Reusable Variant Axes

- proportions: body height, shoulder width, torso width, waist width, head size,
  hand size, foot size
- palette: surface/skin/material tone, now with three non-human tones per people
- head shape: round, narrow, broad, wide-eyed, beaked, leaf-crowned
- feature layer: tusks, high eyes, simian tails, grasping hands/feet, muzzles,
  brow tufts, clan marks, webbed hands, body feathers, head crests, beaks, tail
  feathers, quill marks, bark marks, leaf crown, branch crown
- micro-identity: hair color, brow/cheek/chest/hand markings, ash streaks,
  leaf specks, deterministic role-accent tinting
- equipment/clothing: should attach to the same body anchors, not replace the
  people silhouette

The current `data/people.json` mirrors these calls with body plan IDs, head IDs,
palette IDs, feature IDs, visual notes, and default proportions.

`data/people_visual_models.json` builds on those defaults with per-people
archetypes. Each variant keeps the parent people's body plan, head, palette, and
feature contract, then applies small proportion deltas and role notes. Ravenfolk
are now constrained as slender feathered humanoids with no baked-in robe/clothing
layer; functional wings are not part of the first playable avatar pass.

Each people currently has 16 reusable visual archetypes. This is not hundreds of
authored NPCs yet; it is the reusable shape vocabulary for making hundreds
without losing identity. Role accents are deliberately small: they support role
readability but do not replace people silhouette, equipment, or final clothing
art.
