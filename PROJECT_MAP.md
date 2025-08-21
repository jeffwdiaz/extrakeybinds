# Project Map

## Directory Structure

. (project root)
| .gitignore
| CHANGELOG.md
| PROJECT_MAP.md
| README.md
| project_zomboid_modding.md
| wash_feature_debugging_session.md
|
+---docs
| Project documentation and guides
|
+---DynamicInvFilteringFix
| \---contents
| \---mods
| \---DynamicInvFilteringFix
| | mod.info
| |
| \---42
| \---media
| \---lua
| \---client
| DIF_GlobalPosition.lua
|
+---ExtraKeybinds
| | preview.png
| | workshop.txt
| |
| \---contents
| \---mods
| \---ExtraKeybinds
| | icon.png
| | mod.info
| | poster.png
| |
| +---42
| | | icon.png
| | | mod.info
| | | poster.png
| | |
| | \---media
| | \---lua
| | +---client
| | | DrinkMain.lua
| | | EKModOptions.lua
| | | ReadCategories.lua
| | | ReadMain.lua
| | | SitMain.lua
| | | WashMain.lua
| | |
| | \---shared
| | \---Translate
| | \---EN
| \---common
| .gitkeep

## Folder & File Descriptions

- docs/: Project documentation and guides
- DynamicInvFilteringFix/: Mod for fixing dynamic inventory filtering issues in Project Zomboid
  - contents/mods/DynamicInvFilteringFix/: Main mod directory
  - 42/media/lua/client/: Client-side Lua scripts for the mod
- ExtraKeybinds/: Mod for adding extra keybind functionality to Project Zomboid
  - contents/mods/ExtraKeybinds/: Main mod directory
  - 42/media/lua/client/: Client-side Lua scripts for drink, read, sit, and wash features
  - 42/media/lua/shared/Translate/EN/: English translation files
  - common/: Common mod files
- README.md: Project overview and instructions
- CHANGELOG.md: Project changelog
- PROJECT_MAP.md: This file; describes the project structure
- project_zomboid_modding.md: Documentation about Project Zomboid modding
- wash_feature_debugging_session.md: Debugging session notes for wash feature
