# ExtraKeybinds: Wash All feature (design notes)

## Goal

- Trigger a single hotkey to wash all eligible items: worn clothing, inventory clothing, dirty/bloody rags, bloody weapons, and any other items that support washing/cleaning. Behaves similarly to Read All: finds targets near the player and queues the appropriate timed actions, leveraging the game’s context-menu handlers so we don’t reimplement validation.

## Scope (v1)

- Player proximity: prefer nearby faucet/sink or any world object with water (`obj:hasWater()` and `obj:getFluidAmount()>0`).
- Targets, in this order:
  1.  Wash the player (wash yourself)
  2.  Wash all bloody/dirty rags and bandages in the player inventory AND in equipped bags (including denim/leather rags)
  3.  Worn clothing with blood and/or dirt
  4.  Equipped weapons with blood
  5.  Equipped containers (wash the worn bags themselves; contents are handled in the next step)
  6.  Lastly, any dirty items inside the equipped bags (clothing, rags/bandages, weapons)
- Return items to original container when applicable.
- Soap handling: we build and pass a soapList (bars and qualifying cleaning liquids); the game uses it if present.
- Single-file implementation: `client/WashMain.lua` registered via `Events.OnCustomUIKey` (like Drink/Read).

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
- Likely handlers to call (verify exact names in-game with console autocompletion):
  - `ISWorldObjectContextMenu.onWashYourself(playerObj, sinkObject, soapList)`
  - `ISWorldObjectContextMenu.onWashClothing(objects, clothingList, playerNum)`
  - `ISInventoryPaneContextMenu.onCleanRag(items, playerNum, waterObj)` (or similar; sometimes called "Clean Rag/Bandage")
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

## Testing plan

- Spawn faucet with water and soap bars.
- Wear bloodied clothing; carry dirty rags and a bloody weapon in a bag.
- Press hotkey:
  - Verify timed actions queue: transfers (if needed) → wash clothing → clean rags → clean weapon → transfers back.
  - Confirm water/soap counts reduce as expected; items return to original containers (except worn clothing/weapons which remain equipped).
  - Current step: verify player says "<Source> found", logs show candidates and "Selected source", then logs "Required water...", "Soap list built...", and wash handler invocation; confirm auto-walk and action enqueue.

## To-do

- [ ] 1. Natural water support for wash self (handler if available; else consider timed action fallback). Log outcomes.
- [ ] 2. Add Mod Options checkboxes for filters (Wash Self, Rags/Bandages, Equipped Items, Inventory Clothing) and honor them in code.
- [ ] 3. Implement Step 3: clean rags/bandages (collect from main inventory and equipped bags), with transfers and return.
- [ ] 4. Implement Step 4: wash worn clothing (respect dirt/blood; sorting optional); pass soap list, handle transfers if needed.
- [ ] 5. Implement Step 5: clean equipped weapons with blood.
- [ ] 6. Implement Step 6: wash worn bags themselves if dirty/bloody.
- [ ] 7. Implement Step 7: process remaining dirty items inside worn bags (clothing/rags/weapons) with transfer/return.
- [ ] 8. Logging improvements: timed action queue before/after, per-category summaries, optional on-screen toasts.
- [ ] 9. Optional: random tie-break for equal `getFluidAmount()`; configurable via Mod Options.
- [ ] 10. Final polish: translations for UI strings; error handling for missing APIs; performance tidy-up.

## File layout

- `ExtraKeybinds/contents/mods/ExtraKeybinds/42/media/lua/client/WashMain.lua` (single-file feature)
  - Step 1: water detection (adjacent only), labeling, and logging
  - Step 2a: wash self via handler with `soapList` and required-water guard
- Register key handler with `Events.OnCustomUIKey`.
- Add Mod Options key entry: "Wash All" (default none; during development we use Left Arrow), consistent with existing options style.

## Notes

- We will prefer invoking context menu handlers over manual timed actions to minimize edge-case bugs.

## Current implementation status

- Keybind: Mod Options adds "Wash All" (default Left Arrow).
- Detection: scans adjacent squares only; labels source (Sink/Toilet/Bathtub/Well/Dispenser/Lake) and logs candidates and the selected source. Picks highest fluid amount; deterministic tie-break.
- Wash Self (object sources):
  - Logs required water via `ISWashYourself.GetRequiredWater(player)` and skips if 0.
  - Builds and passes `soapList` (Soap2 bars, Bleach/CleaningLiquid containers) to `ISWorldObjectContextMenu.onWashYourself`.
  - Relies on handler to auto-walk and enqueue actions; logs success/failure.
  - Natural water handling not implemented yet.

## Development approach (small, testable steps)

- We will implement and verify in narrow increments to avoid regressions:
  1. Detect valid water sources (sinks and other sources; enforce adjacency). Ship and test.
  2. Implement "Wash Self" only using the detected source. Ship and test.
     - Pre-check: log `ISWashYourself.GetRequiredWater(player)`; skip if 0 ("Nothing to wash").
     - Build `soapList` (Soap2 bars, Bleach/CleaningLiquid containers) and pass to handler.
     - Call `ISWorldObjectContextMenu.onWashYourself(player, sinkObject, soapList)` and rely on handler auto-walk.
  3. Add rags/bandages cleaning (from main inventory and equipped bags). Ship and test.
  4. Add worn clothing washing. Ship and test.
  5. Add equipped weapons cleaning. Ship and test.
  6. Add washing worn bags themselves. Ship and test.
  7. Add washing remaining dirty items inside equipped bags. Ship and test.
  8. Wire Mod Options filters (enable/disable categories) and default Left Arrow keybind. Ship and test.
  9. Final polish: error handling, no-op messaging, and performance checks.
