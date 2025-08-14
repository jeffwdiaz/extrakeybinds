# ExtraKeybinds: Wash All feature (design notes)

## To-do (consolidated)

- [x] Register key handler on `Events.OnCustomUIKey`
- [x] Add Mod Options key entry: "Wash All" (default Left Arrow)
- [x] Single-file implementation in `ExtraKeybinds/contents/mods/ExtraKeybinds/42/media/lua/client/WashMain.lua`
- [x] Implement basic water detection (adjacent squares only), labeling, and source selection (prefer highest `getFluidAmount()`; deterministic tie-break)
- [x] Prefer nearby faucet/sink or any water object (`obj:hasWater()`, `obj:getFluidAmount()>0`)
- [x] Clear stage separation with visual comments and logging
- [x] Wash Self (Stage 2): guard with `ISWashYourself.GetRequiredWater(player)`; build `soapList` (Soap2 bars, Bleach/CleaningLiquid); call `ISWorldObjectContextMenu.onWashYourself`
- [x] Clean Bandages/Rags (Stage 1): main inventory using `getAllTag("CanBeWashed")` and `ISWorldObjectContextMenu.onWashClothing` with empty soap list `{}`
- [ ] Maintain target order: rags/bandages → self → worn clothing → equipped weapons → worn bags → items inside worn bags
- [ ] Return items to original container when applicable
- [ ] Ensure clothing washing uses soap only for blood removal; pass `soapList` when needed
- [ ] Extend bandages/rags cleaning to search equipped bags
- [ ] Implement per-item transfer/clean/return flow for items in bags
- [ ] Verify cleaning for bandages, denim strips, leather strips
- [ ] Natural water support for wash self (handler if available; else timed action fallback). Log outcomes
- [ ] Implement washing worn clothing (respect blood/dirt; pass soap list; handle transfers if needed)
- [ ] Clean equipped weapons with blood
- [ ] Wash worn bags themselves if dirty/bloody
- [ ] Process remaining dirty items inside worn bags (clothing/rags/weapons) with transfer/return
- [ ] Logging improvements: timed action queue before/after, per-category summaries, optional on-screen toasts
- [ ] Optional: random tie-break for equal `getFluidAmount()`; configurable via Mod Options
- [ ] Add Mod Options checkboxes for filters (Wash Self, Rags/Bandages, Equipped Items, Inventory Clothing) and honor them in code
- [ ] Final polish: translations for UI strings; error handling for missing APIs; performance tidy-up
- [x] Order of Operations: Stage 1 clean bandages/rags FIRST; Stage 2 wash the player SECOND

## Goal

- Trigger a single hotkey to wash all eligible items: worn clothing, inventory clothing, dirty/bloody rags, bloody weapons, and any other items that support washing/cleaning. Behaves similarly to Read All: finds targets near the player and queues the appropriate timed actions, leveraging the game’s context-menu handlers so we don’t reimplement validation.

## Keybind

- New option in Mod Options (like existing ones): "Wash All" key. Default: Left Arrow.
- Handler listens on `Events.OnCustomUIKey` and triggers when the configured key is pressed and the game is not paused.

## Mod Options (wash filters)

- Add checkboxes to enable/disable parts of the sequence. The order remains the same; disabled categories are skipped.
  - Wash Self: when enabled, performs "wash yourself" first.
  - Rags/Bandages: when enabled, cleans all dirty/bloody rags and bandages (including denim/leather) from main inventory and equipped bags.
  - Equipped Items: when enabled, washes worn clothing, cleans equipped weapons, and washes worn bags (the containers themselves).
  - Inventory Clothing: when enabled, washes any remaining eligible clothing items found in main inventory and inside equipped bags.
  - Defaults: All enabled (tweak as desired during implementation).

## Implementation approach

### Built-in handlers

- Use the same pattern as Drink: call the context-menu entrypoints that themselves enqueue proper `ISTimedAction` sequences.
- **✅ CONFIRMED HANDLERS** that work in the current implementation:
  - `ISWorldObjectContextMenu.onWashYourself(playerObj, sinkObject, soapList)` - **WORKING**
  - `ISWorldObjectContextMenu.onWashClothing(player, waterObject, soapList, itemList, singleClothing, noSoap)` - **WORKING for bandages/rags**
  - ~~`ISInventoryPaneContextMenu.onCleanRag(items, playerNum, waterObj)`~~ - **INCORRECT**: This was a wrong assumption
- Weapons: either included in clothing cleaning (blood removal) or a dedicated inventory-pane handler (name varies by build; look for "clean blood" actions)
- Rationale: these handlers encapsulate validation (water availability, adjacency/range, soap handling, item eligibility) and push the right timed actions (e.g., `ISWashYourself`, `ISWashClothing`, `ISCleanRag`, etc.) to `ISTimedActionQueue`.

### Water sources and movement

- Valid sources:
  - Any world object that reports water: `obj:hasWater()` and `obj:getFluidAmount() > 0` (sinks, bathtubs, toilets, dispensers, wells, rain collectors, etc.). If available, also accept `obj:isWaterSource()`.
  - Natural water tiles (rivers/lakes) when the square is flagged as water (mirrors context menu behavior for washing at shorelines).
- Selection:
  - Prefer nearest valid source in the same building; if none, consider adjacent outdoor water (shoreline) within a small radius.
  - Among multiple adjacent object sources, select the one with the highest `getFluidAmount()`. If tied, pick the first found (deterministic tie-break for debugging).
- Movement requirement:
  - Require adjacency before washing (we only scan current and neighboring squares). If not adjacent, do nothing.
  - When adjacent, rely on the handler’s built-in walk-to to align the player to the exact interaction spot. We do not enqueue our own walk actions from farther away.

## Discovery checklist (to confirm in current build)

- World water sources expose: `obj:hasWater()` and `obj:getFluidAmount()` (used already by Drink). If needed, also check `obj:isWaterSource()`.
- Inventory-pane handlers in `ISInventoryPaneContextMenu` for: wash clothing, clean rags/bandages, clean blood from weapons.
- World-object handler in `ISWorldObjectContextMenu` for washing at a faucet/sink (requires `playerNum`).
- Timed actions that will appear in queue: `ISWashClothing`, `ISCleanRag`/`ISCleanBandage`, possibly a weapon clean action. Names to be verified in the Lua console.

## High-level flow (no code)

1. Identify a nearby valid water source: scan 3×3 squares around the player; prefer same-building sources; otherwise allow nearby outdoor water (shoreline). Require adjacency: if not adjacent, abort without performing washing actions.
2. Collect targets:
   - Worn clothing: iterate worn items; filter where blood/dirt > 0.
   - Equipped items (primary/secondary): if weapon has blood, include.
   - Inventory: dirty/bloody rags; clothing items with blood/dirt in main inv and nested containers.
3. Invoke appropriate context-menu handlers:
   - Wash self: `ISWorldObjectContextMenu.onWashYourself(player, sinkObject, soapList)`
   - Other categories follow similarly (later steps)
4. If an item is inside a container, transfer to main inventory first, then after the handler enqueues wash actions, enqueue a transfer back (mirrors Read All behavior).

## Edge cases

- No water source in range: either do nothing or print a short say/tooltip; we won’t auto-use bottled water for washing in v1.
- No eligible items: no-op.
- Soap: build an explicit `soapList` (bars and qualifying cleaning liquids) and pass it to handlers so vanilla helpers can compute soap availability correctly.
- Multiplayer safety: client-only actions; rely on built-in handlers for validation.

## Data points to detect eligibility

- Clothing contamination: fields exposed via clothing item API (blood/dirt level; confirm exact getters in console).
- Rags: dirty/bloody rag item types; use inventory-pane handler to "Clean Rag/Bandage" rather than bespoke checks.
- Weapons: presence of blood state on weapon (cleanable via inventory-pane handler if available in current build).

## File layout

- `ExtraKeybinds/contents/mods/ExtraKeybinds/42/media/lua/client/WashMain.lua` (single-file feature)

## Notes

- We will prefer invoking context menu handlers over manual timed actions to minimize edge-case bugs.

### Archived: Natural water fallback snippet (previously in `WashMain.lua`)

These lines detected and selected a natural water tile as a fallback when no object water source was found in adjacent squares. We removed them from the code to simplify behavior (object sources only), but keep them here for easy restoration if needed.

Detection within the scan loop:

```lua
-- Check for natural water tiles (lake/river)
if not naturalCandidate and isNaturalWaterSquare(sq) then
    logWash(string.format("Natural water found at (%d,%d,%d)", sq:getX(), sq:getY(), sq:getZ()))
    naturalCandidate = { kind = "natural", square = sq, label = "Lake" }
end
```

Selection after object preference:

```lua
if naturalCandidate then
    logWash(string.format("Selected source: %s at (%d,%d,%d)",
        naturalCandidate.label, naturalCandidate.square:getX(), naturalCandidate.square:getY(), naturalCandidate.square:getZ()))
    return naturalCandidate
end
```

### Key Technical Discoveries

- **Soap Usage**: Different cleaning systems have different soap requirements:
  - Self-washing: Requires soap for blood removal
  - Bandages/rags: Water only (no soap needed)
  - Regular clothing: Soap used for blood removal only
- **Item Detection**: `getAllTag("CanBeWashed")` correctly identifies all washable items
- **Handler Choice**: `ISWorldObjectContextMenu.onWashClothing` handles both regular clothing AND bandages/rags
