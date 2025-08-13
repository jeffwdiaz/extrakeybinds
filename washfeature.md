## ExtraKeybinds: Wash All feature (design notes)

Goal

- Trigger a single hotkey to wash all eligible items: worn clothing, inventory clothing, dirty/bloody rags, bloody weapons, and any other items that support washing/cleaning. Behaves similarly to Read All: finds targets near the player and queues the appropriate timed actions, leveraging the game’s context-menu handlers so we don’t reimplement validation.

Scope (v1)

- Player proximity: prefer nearby faucet/sink or any world object with water (`obj:hasWater()` and `obj:getFluidAmount()>0`).
- Targets, in this order:
  1.  Wash the player (wash yourself)
  2.  Wash all bloody/dirty rags and bandages in the player inventory AND in equipped bags (including denim/leather rags)
  3.  Worn clothing with blood and/or dirt
  4.  Equipped weapons with blood
  5.  Equipped containers (wash the worn bags themselves; contents are handled in the next step)
  6.  Lastly, any dirty items inside the equipped bags (clothing, rags/bandages, weapons)
- Return items to original container when applicable.
- Soap handling: none required by us; the game auto-uses soap from inventory when applicable.
- Single-file implementation: `client/WashMain.lua` registered via `Events.OnCustomUIKey` (like Drink/Read).

Keybind

- New option in Mod Options (like existing ones): "Wash All" key. Default: Left Arrow.
- Handler listens on `Events.OnCustomUIKey` and triggers when the configured key is pressed and the game is not paused.

Mod Options (wash filters)

- Add checkboxes to enable/disable parts of the sequence. The order remains the same; disabled categories are skipped.
  - Wash Self: when enabled, performs "wash yourself" first.
  - Rags/Bandages: when enabled, cleans all dirty/bloody rags and bandages (including denim/leather) from main inventory and equipped bags.
  - Equipped Items: when enabled, washes worn clothing, cleans equipped weapons, and washes worn bags (the containers themselves).
  - Inventory Clothing: when enabled, washes any remaining eligible clothing items found in main inventory and inside equipped bags.
  - Defaults: All enabled (tweak as desired during implementation).

How to queue washing using built-in context menu logic

- Use the same pattern as Drink: call the context-menu entrypoints that themselves enqueue proper `ISTimedAction` sequences.
- Likely handlers to call (verify exact names in-game with console autocompletion; soap is auto-used, no explicit soap list management):
  - `ISWorldObjectContextMenu.onWashClothing(objects, clothingList, playerNum)`
  - `ISInventoryPaneContextMenu.onCleanRag(items, playerNum, waterObj)` (or similar; sometimes called "Clean Rag/Bandage")
- Weapons: either included in clothing cleaning (blood removal) or a dedicated inventory-pane handler (name varies by build; look for "clean blood" actions)
- Rationale: these handlers encapsulate all validation (water availability, distance, soap auto-use, item eligibility) and push the right timed actions (e.g., `ISWashClothing`, `ISCleanRag`, etc.) to `ISTimedActionQueue`.

Water sources and movement

- Valid sources:
  - Any world object that reports water: `obj:hasWater()` and `obj:getFluidAmount() > 0` (sinks, bathtubs, toilets, dispensers, wells, rain collectors, etc.). If available, also accept `obj:isWaterSource()`.
  - Natural water tiles (rivers/lakes) when the square is flagged as water (mirrors context menu behavior for washing at shorelines).
- Selection:
  - Prefer nearest valid source in the same building; if none, consider adjacent outdoor water (shoreline) within a small radius.
- Movement requirement:
- Require adjacency before washing. If the player isn’t adjacent to the chosen source, do nothing (no auto-walk, no remote washing).
- Rely on built-in handlers to validate adjacency and range; we will not enqueue any walk-to actions.

Discovery checklist (to confirm in current build)

- World water sources expose: `obj:hasWater()` and `obj:getFluidAmount()` (used already by Drink). If needed, also check `obj:isWaterSource()`.
- Inventory-pane handlers in `ISInventoryPaneContextMenu` for: wash clothing, clean rags/bandages, clean blood from weapons.
- World-object handler in `ISWorldObjectContextMenu` for washing at a faucet/sink (requires `playerNum`).
- Timed actions that will appear in queue: `ISWashClothing`, `ISCleanRag`/`ISCleanBandage`, possibly a weapon clean action. Names to be verified in the Lua console.

High-level flow (no code)

1. Identify a nearby valid water source: scan 3×3 squares around the player; prefer same-building sources; otherwise allow nearby outdoor water (shoreline). Require adjacency: if not adjacent, abort without performing washing actions.
2. Collect targets:
   - Worn clothing: iterate worn items; filter where blood/dirt > 0.
   - Equipped items (primary/secondary): if weapon has blood, include.
   - Inventory: dirty/bloody rags; clothing items with blood/dirt in main inv and nested containers.
3. Invoke appropriate context-menu handlers with: `[sink]` (as `objects`), `playerNum`, and `clothingList`/`items`.
4. If an item is inside a container, transfer to main inventory first, then after the handler enqueues wash actions, enqueue a transfer back (mirrors Read All behavior).

Edge cases

- No water source in range: either do nothing or print a short say/tooltip; we won’t auto-use bottled water for washing in v1.
- No eligible items: no-op.
- Soap: handled automatically by the game if present in inventory; we won’t manage it explicitly.
- Multiplayer safety: client-only actions; rely on built-in handlers for validation.

Data points to detect eligibility

- Clothing contamination: fields exposed via clothing item API (blood/dirt level; confirm exact getters in console).
- Rags: dirty/bloody rag item types; use inventory-pane handler to "Clean Rag/Bandage" rather than bespoke checks.
- Weapons: presence of blood state on weapon (cleanable via inventory-pane handler if available in current build).

Testing plan

- Spawn faucet with water and soap bars.
- Wear bloodied clothing; carry dirty rags and a bloody weapon in a bag.
- Press hotkey:
  - Verify timed actions queue: transfers (if needed) → wash clothing → clean rags → clean weapon → transfers back.
  - Confirm water/soap counts reduce as expected; items return to original containers (except worn clothing/weapons which remain equipped).

File layout

- `ExtraKeybinds/contents/mods/ExtraKeybinds/42/media/lua/client/WashMain.lua` (single-file feature)
- Register key handler with `Events.OnCustomUIKey`.
- Add Mod Options key entry: "Wash All" (default none), consistent with existing options style.

Notes

- This is for Project Zomboid (typo was "Soundboy").
- We will prefer invoking context menu handlers over manual timed actions to minimize edge-case bugs.

Development approach (small, testable steps)

- We will implement and verify in narrow increments to avoid regressions:
  1. Detect valid water sources (sinks and other sources; enforce adjacency). Ship and test.
  2. Implement "Wash Self" only using the detected source. Ship and test.
  3. Add rags/bandages cleaning (from main inventory and equipped bags). Ship and test.
  4. Add worn clothing washing. Ship and test.
  5. Add equipped weapons cleaning. Ship and test.
  6. Add washing worn bags themselves. Ship and test.
  7. Add washing remaining dirty items inside equipped bags. Ship and test.
  8. Wire Mod Options filters (enable/disable categories) and default Left Arrow keybind. Ship and test.
  9. Final polish: error handling, no-op messaging, and performance checks.
