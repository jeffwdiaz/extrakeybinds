# Project Zomboid Reference Files Rule

## Project Overview

Always read `roadmap.md` in the root folder for current project status and goals.

## Game Reference Location

All Project Zomboid Build 42 reference files, APIs, function definitions, and game assets are located in the `GameFilesForReference/` folder. This includes:

- **Lua API references**: `GameFilesForReference/lua/client/`, `GameFilesForReference/lua/server/`, `GameFilesForReference/lua/shared/`
- **Scripts and definitions**: `GameFilesForReference/scripts/`
- **Game items and recipes**: `GameFilesForReference/items/`
- **Sound definitions**: `GameFilesForReference/sound/`
- **Animation sets**: `GameFilesForReference/AnimSets/`
- **Action groups**: `GameFilesForReference/actiongroups/`
- **Models and assets**: Various `GameFilesForReference/` subdirectories

## Mod Development Context

**Current Project**: ExtraKeybinds mod for Project Zomboid Build 42

- **Reference Implementation**: `ExtraKeybinds/contents/mods/ExtraKeybinds/42/media/lua/client/ReadAll.lua.disabled`
  - ⚠️ **DO NOT MODIFY** - This file is for reference only (disabled from loading)
  - Contains working example of automated book reading with smart inventory management
  - Shows successful usage of: ISTimedActionQueue, ISReadABook, ISInventoryTransferAction, ISGrabItemAction
- **Development Approach**: Create new files for new features, keep ReadAll.lua as reference

## Development Guidelines

1. **Reference Real Game Files**: Always check `GameFilesForReference/lua/` for actual PZ API usage patterns
2. **Verify Function Signatures**: Use `grep` to search for function definitions in game files before using them
3. **Follow Game Patterns**: Look at how the base game implements similar features (especially in TimedActions)
4. **Build 42 Compatibility**: Ensure all code works with PZ Build 42 APIs (some APIs changed from Build 41)

## Search Strategy for PZ Development

1. Use `grep` to search `GameFilesForReference/lua/` for specific function names or patterns
2. Check `GameFilesForReference/scripts/` for item definitions and game mechanics
3. Look at `GameFilesForReference/actiongroups/player/` for player action examples
4. Reference existing TimedAction implementations in `GameFilesForReference/lua/client/TimedActions/`

## Common PZ Build 42 APIs (Reference Only)

- **Player**: `getPlayer()`, `player:getInventory()`, `player:getSquare()`
- **Inventory**: `inventory:getItems()`, `item:IsLiterature()`, `item:getCategory()`
- **Timed Actions**: `ISTimedActionQueue.add()`, `ISReadABook:new()`
- **World**: `getCell()`, `square:getWorldObjects()`, `square:getObjects()`

This ensures mod compatibility with PZ Build 42 and reduces API errors.
