-- Extra Keybinds Mod - Mod Options Configuration
-- Provides player-configurable settings for literature reading categories

require "PZAPI/ModOptions"

-- Mod Options Setup
local ExtraKeybindsOptions = PZAPI.ModOptions:create("ExtraKeybinds", "Extra Keybinds")

-- Add title and description
ExtraKeybindsOptions:addDescription("Configure which types of literature to read with the Read All key binding.")

ExtraKeybindsOptions:addDescription("===== Literature Categories ====")

-- Literature category options
ExtraKeybindsOptions:addTickBox("enableLeisure", "Read Leisure Material", true, 
    "Entertainment magazines, books, and comics (HottieZ, novels, comic books, etc.)")
    

ExtraKeybindsOptions:addTickBox("enableRecipeMagazines", "Read Recipe Magazines", false, 
    "Magazines that teach crafting recipes (Tailoring, Smithing, Cooking, etc.)")

ExtraKeybindsOptions:addTickBox("enableSkillBooks", "Read Skill Books", false, 
    "Books that provide skill experience multipliers")

ExtraKeybindsOptions:addTickBox("enableSeedPackets", "Read Seed Packets", false, 
    "Empty seed packets that teach farming seasons")

ExtraKeybindsOptions:addDescription("===== Key Bindings =====")

-- Keybind option
ExtraKeybindsOptions:addKeyBind("readAllKeybind", "Read All", 82, -- Default: R key
    "Keybind to trigger reading all selected literature types")

-- Global access to options
ExtraKeybindsModOptions = ExtraKeybindsOptions

-- Helper functions to check option values
ExtraKeybindsSettings = {}

function ExtraKeybindsSettings.getLeisureEnabled()
    return ExtraKeybindsModOptions:getOption("enableLeisure"):getValue()
end

function ExtraKeybindsSettings.getRecipeMagazinesEnabled()
    return ExtraKeybindsModOptions:getOption("enableRecipeMagazines"):getValue()
end

function ExtraKeybindsSettings.getSkillBooksEnabled()
    return ExtraKeybindsModOptions:getOption("enableSkillBooks"):getValue()
end

function ExtraKeybindsSettings.getSeedPacketsEnabled()
    return ExtraKeybindsModOptions:getOption("enableSeedPackets"):getValue()
end

function ExtraKeybindsSettings.getReadAllKeybind()
    return ExtraKeybindsModOptions:getOption("readAllKeybind"):getValue()
end
