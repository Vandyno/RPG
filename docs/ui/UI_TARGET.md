# UI_TARGET.md

This file captures the RPG UI direction shown in the three mockup references
from the June 22 UI discussion. It is the implementation target for player-facing
HUD, menus, dialogue, readables, trade, and related screens.

Do not use the current debug-shaped HUD as the visual target. Debug panels may
exist for development, but player-facing UI should move toward the structures
below.

## Non-Negotiable Rule

If a UI change would be thrown away when this target UI lands, do not build it.

Useful work either:
- implements part of this target directly
- extracts game state/actions so this target can consume them cleanly
- replaces debug-facing structure with durable player-facing structure
- adds verification that protects the intended UI behavior

## Visual Direction

The UI should feel like a dark fantasy RPG interface laid over a playable world:

- dark leather/wood/iron panels
- restrained gold trim and dividers
- compact framed controls
- readable serif-like presentation where practical
- green/gold highlights for selected safe actions
- red/blue/gold resource bars and currencies
- large thumb-friendly command controls on mobile landscape
- the world remains the primary surface whenever no menu/dialogue is open

The current game does not need to match the painterly isometric art of the
mockups, but the UI composition should match their intent.

## Exploration HUD Target

Reference: walled Briarwatch town HUD mockup.

Required structure:

- Top-left player/vitals cluster
  - portrait or portrait placeholder
  - level badge
  - health/resource bars
  - compact status/quick-slot icons
- Top-center location banner
  - current place name, e.g. `Briarwatch`
  - decorative framed treatment
  - should not obscure the player or active target
- Top-right navigation cluster
  - `Quests`
  - `Journal`
  - `Map`
  - `Menu`
  - icon plus label where space allows
- Bottom-left movement control
  - thumb joystick or virtual movement disk
  - not four debug-labeled buttons
  - must stay out of the main play/targeting space
- Bottom-right action cluster
  - large attack aim joystick
  - three smaller ability aim joysticks bound to assigned spell slots
  - secondary controls for `Inventory`, `Target`, and `Menu`
  - world interaction should come from taps, target hints, and context panels
    instead of turning the attack joystick into `Talk`, `Use`, `Open`, or `Rest`
- Bottom-center message strip
  - recent event feedback, e.g. `You feel well rested.`
  - short, legible, and non-modal
- World markers
  - NPC/POI labels should be visible in-world when useful
  - selected/quest targets should be obvious from the world view
  - routine interactions should be tappable from visible world affordances

The exploration HUD should never feel like a minimap or debug overlay.

## Systems Menu Target

Reference: full inventory/character screen mockup.

Required structure:

- Full-screen framed overlay over a dimmed or blurred world background
- Top bar
  - place/title on the left, e.g. `Briarwatch`
  - summary/status line under it
  - currency, carry weight, time, and close button on the right
- Left vertical navigation
  - `Inventory`
  - `Character`
  - `Quests`
  - `Map`
  - `Journal`
  - `Trade`
  - large icon plus label rows
- Center content pane
  - tab/category row for inventory-like screens
  - selectable rows/cards with icon, name, type, count/weight/value
  - current selection highlighted
- Detail pane
  - selected item/quest/place/trade details
  - action-relevant text and stats
- Right character/status pane where appropriate
  - equipment slots
  - portrait/silhouette
  - health/resource bars
  - attributes
  - active effects
- Bottom command bar
  - context actions such as `Use`, `Equip`, `Drop`, `More`, `Back`
  - actions route to game systems; UI is not source of truth

The menu should be real player UI, not a multiline label dump.

## Dialogue And Interaction Target

Reference: Harrow Venn dialogue/quest screen mockup.

Required structure:

- World remains visible behind the dialogue panel
- Bottom dialogue panel
  - NPC portrait/placeholder on the left
  - NPC name and role/title
  - relationship/reputation/status row when available
  - dialogue text in a readable central area
- Choice/action list on the right
  - each row has icon/label/subtitle
  - selected/recommended/quest choices have clear highlight
  - routine choices include `Leave`
- Quest/action preview pane
  - shows relevant quest name, item/target, and rewards when an action changes state
  - should make turn-ins and accepted jobs understandable before committing
- Bottom quickbar can remain visible if it does not compete with dialogue choices

Dialogue, readables, POIs, forge services, and trade should be dedicated
player-facing screens or panels. They should not be generic debug cards.

## Mobile Landscape Requirements

The target UI is mobile-landscape first:

- all primary touch targets should be comfortably thumb-sized
- left and right edge controls should respect play space in the center
- text must fit at 640x360 and similar aspect ratios
- panels should avoid covering the selected target/player unless intentionally modal
- full-screen menus may cover the world, but exploration HUD should not
- every major UI change must be smoke-rendered at desktop and 640x360

## Implementation Guidance

Prefer a staged replacement that survives into the final UI:

1. Define player-facing UI components and data contracts.
2. Move debug-only text/state behind debug mode.
3. Build the exploration HUD shell from the target layout.
4. Replace systems tabs with real menu panes.
5. Replace content cards with dialogue/readable/POI/trade-specific panels.
6. Keep `HudShell` as shared UI plumbing while player-facing panels replace legacy debug content.

Avoid changes that only make the old debug-shaped HUD prettier.

## Verification

Meaningful UI work should include:

- tests for layout bounds at 1152x648 and 640x360
- tests for action routing from buttons to game systems
- tests for modal/open/close behavior
- smoke renders at desktop and mobile landscape
- visual inspection against this target document
