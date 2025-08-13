# Wash Feature Debugging Session - Lessons Learned

## Session Overview

**Date**: August 25, 2024  
**Goal**: Implement "Wash All" feature for bandages/rags in Project Zomboid ExtraKeybinds mod  
**Status**: ✅ WORKING - Successfully cleaning rags, needs testing on other types

## Key Findings

### 1. ✅ SOLUTION FOUND - Soap Was The Problem

**Root Cause**: The `buildSoapList()` function was failing silently when called during bandage cleaning, causing the entire cleaning process to exit without error.

**Solution**: Bandages/rags don't need soap - they only consume water. Split the implementation:

- **Self-washing**: Uses soap list (for blood cleaning)
- **Bandage cleaning**: Uses empty soap list `{}` (water only)

**Result**: ✅ Successfully cleaning rags, needs testing on bandages/denim/leather

### 2. Game File Analysis Reveals Multiple Approaches

Through analyzing vanilla game files, we discovered several different cleaning systems:

#### A. ISCleanBandage System (Recipe-based)

- Uses recipes like "Base.Clean Rag" to convert "Base.RippedSheetsDirty" → "Base.RippedSheets"
- Requires items to be in main inventory
- Limited to specific dirty item types with corresponding clean recipes

#### B. ISWashClothing System (Tag-based)

- Uses "CanBeWashed" tag to identify items
- Handles broader range of clothing items
- Can clean blood/dirt without changing item type
- Has special handling for bandages (plays "FirstAidCleanRag" sound)

#### C. CleanBandages Context Menu System

- Combines both approaches
- Uses `CleanBandages.getAvailableItems()` to find recipe pairs
- Uses `CleanBandages.onCleanAll()` to process multiple items
- Handles transfer to main inventory automatically

### 3. Critical Discovery: Soap Usage in Game Systems

**Key Insight**: Different cleaning systems have different soap requirements:

1. **ISWashClothing**: Uses soap only for blood removal (`if blood > 0 then useSoap()`)
2. **ISCleanBandage**: NO soap usage - only consumes water (`waterObject:useFluid(1)`)
3. **Self-washing**: Requires soap for effective cleaning

**Lesson**: Always check game files for actual resource consumption, don't assume!

### 4. Key Game Mechanics Discovered

#### Water Source Requirements

- Object water sources: Must have `hasWater()` and `getFluidAmount() > 0`
- Natural water: Identified by `IsoFlagType.water` property
- Adjacent requirement: Player must be within 1 tile (Chebyshev distance)

#### Item Validation Requirements

- Items must pass `item:getJobDelta() == 0` (not already being processed)
- For `ISCleanBandage`: Item must be in main inventory (`item:getContainer() == player:getInventory()`)
- For `ISWashClothing`: More flexible container handling

#### Soap/Cleaning Supplies

- Bar soap: "Soap2" item type
- Liquid cleaners: Items with FluidContainer component containing Bleach or CleaningLiquid
- Game calculates required amounts based on blood/dirt levels

### 5. Current Implementation Status

#### Working Components ✅

- Water source detection and classification
- Soap list building
- Item finding with `getAllTag("CanBeWashed")`
- Adjacent water source validation
- Detailed logging system

#### Debugging Components 🔍

- `ISWorldObjectContextMenu.onWashClothing` call - Added comprehensive debug logging
- Parameter validation - All parameters appear correct
- Error handling - Using pcall to catch any exceptions

## Code Patterns That Work

### Successful Water Detection

```lua
local function findAdjacentWaterSource(player)
    -- Scans adjacent squares for objects with hasWater() and getFluidAmount()
    -- Prioritizes highest fluid amount
    -- Fallback to natural water sources
end
```

### Successful Item Finding

```lua
local dirtyItems = inv:getAllTag("CanBeWashed", ArrayList.new())
-- Alternative: Manual type checking
local count = inv:getCountTypeRecurse("Base.RippedSheetsDirty")
```

### Working Vanilla Integration Pattern

```lua
-- Pattern used for self-washing (confirmed working)
ISWorldObjectContextMenu.onWashYourself(player, waterObject, soapList)
```

## Failed Approaches and Why

### 1. Recipe-Based Approach

```lua
-- FAILED: Tried to use ScriptManager:getRecipe() directly
local recipe = getScriptManager():getRecipe("Base.Clean Rag")
ISTimedActionQueue.add(ISCleanBandage:new(player, item, waterObject, recipe))
```

**Problem**: Items need to be transferred to main inventory first, and this approach missed that step.

### 2. Custom Return-to-Container Logic

```lua
-- FAILED: Tried to implement custom ISReturnCleanedItemAction
```

**Problem**: Overthinking - vanilla game handles container management automatically.

### 3. Direct onWashClothing Without Understanding Parameters

**Problem**: Called function without understanding exact parameter requirements.

## Debugging Techniques That Worked

### 1. Comprehensive Logging

```lua
local function logWash(message)
    print("[ExtraKeybinds][Wash] " .. tostring(message))
end
```

### 2. Manual Verification

```lua
-- Cross-check automated results with manual counts
local manualCheck = {
    ["Base.RippedSheetsDirty"] = inv:getCountTypeRecurse("Base.RippedSheetsDirty")
}
```

### 3. Parameter Debugging

```lua
logWash(string.format("DEBUG: Parameters - player: %s, waterObject: %s, soapList: %d items",
    tostring(player), tostring(waterObject), #soapList))
```

## Next Steps

### Immediate Actions

1. **Test Current Debug Build**: Run the latest version with comprehensive logging to see where `onWashClothing` fails
2. **Verify Function Signature**: Confirm `ISWorldObjectContextMenu.onWashClothing` parameters match vanilla expectations
3. **Consider CleanBandages Approach**: If `onWashClothing` continues to fail, implement using `CleanBandages.onCleanAll`

### Alternative Implementation Plan

If current approach fails, switch to CleanBandages system:

```lua
local items = {}
CleanBandages.getAvailableItems(items, player, "Base.Clean Bandage", "Base.BandageDirty")
CleanBandages.getAvailableItems(items, player, "Base.Clean Rag", "Base.RippedSheetsDirty")
-- ... other types
CleanBandages.onCleanAll(player, waterObject, items)
```

## Lessons for Future Development

### 1. Always Check Game Files First

- Don't assume API behavior - read the actual game implementation
- Multiple systems may exist for similar functionality
- Understand the full call chain before implementing

### 2. Debug Early and Thoroughly

- Add logging at every step, not just success/failure
- Verify assumptions with manual checks
- Use pcall to catch and log errors

### 3. Follow Vanilla Patterns Exactly

- Don't try to "improve" on vanilla logic until basic functionality works
- Use same function signatures and parameter orders
- Mirror vanilla validation steps

### 4. Incremental Development

- Get basic functionality working before adding features
- Test each component in isolation
- Don't combine multiple changes in single iteration

## File References

- **Implementation**: `ExtraKeybinds/contents/mods/ExtraKeybinds/42/media/lua/client/WashMain.lua`
- **Design Doc**: `washfeature.md`
- **Game Reference**: `docs/GameFilesForReference/lua/client/ISUI/ISWorldObjectContextMenu.lua`
- **Timed Actions**: `docs/GameFilesForReference/lua/shared/TimedActions/ISWashClothing.lua`

## Current Debug Status

**WORKING**: Rags are successfully being cleaned using `ISWorldObjectContextMenu.onWashClothing` ✅
**Next**: Test with bandages, denim strips, and leather strips to confirm universal functionality
**Key Learning**: Soap was the silent killer - bandages don't need it!

## Working Implementation Summary

```lua
// The solution that works:
ISWorldObjectContextMenu.onWashClothing(player, waterObject, {}, dirtyItems, nil, false)
//                                                            ^^^ Empty soap list = key!
```
