-- Extra Keybinds Mod - Mod Options Configuration
-- Provides player-configurable settings for literature reading categories

require "PZAPI/ModOptions"

-- Mod Options Setup
local ExtraKeybindsOptions = PZAPI.ModOptions:create("ExtraKeybinds", "Extra Keybinds")

-- Add title and description
ExtraKeybindsOptions:addTitle("Read All Books Settings")
ExtraKeybindsOptions:addDescription("Configure which types of literature to read with the Read All keybind.")

ExtraKeybindsOptions:addSeparator()

-- Literature category options
ExtraKeybindsOptions:addTickBox("enableLeisureMagazines", "Read Leisure Magazines", true, 
    "Entertainment magazines like HottieZ, TV Magazine, Popular Magazine, etc.")

ExtraKeybindsOptions:addTickBox("enableRecipeMagazines", "Read Recipe Magazines", false, 
    "Magazines that teach crafting recipes (Tailoring, Smithing, Cooking, etc.)")

ExtraKeybindsOptions:addTickBox("enableSkillBooks", "Read Skill Books", false, 
    "Books that provide skill experience multipliers")

ExtraKeybindsOptions:addTickBox("enableLeisureBooks", "Read Leisure Books", false, 
    "Entertainment books (hardcover, paperback, leatherbound) for reducing boredom")

ExtraKeybindsOptions:addTickBox("enableSeedPackets", "Read Seed Packets", false, 
    "Empty seed packets that teach farming seasons")

ExtraKeybindsOptions:addSeparator()

-- Keybind option
ExtraKeybindsOptions:addKeyBind("readAllKeybind", "Read All Books Keybind", 82, -- Default: R key
    "Keybind to trigger reading all selected literature types")

-- Global access to options
ExtraKeybindsModOptions = ExtraKeybindsOptions

-- Helper functions to check option values
ExtraKeybindsSettings = {}

function ExtraKeybindsSettings.getLeisureMagazinesEnabled()
    return ExtraKeybindsModOptions:getOption("enableLeisureMagazines"):getValue()
end

function ExtraKeybindsSettings.getRecipeMagazinesEnabled()
    return ExtraKeybindsModOptions:getOption("enableRecipeMagazines"):getValue()
end

function ExtraKeybindsSettings.getSkillBooksEnabled()
    return ExtraKeybindsModOptions:getOption("enableSkillBooks"):getValue()
end

function ExtraKeybindsSettings.getLeisureBooksEnabled()
    return ExtraKeybindsModOptions:getOption("enableLeisureBooks"):getValue()
end

function ExtraKeybindsSettings.getSeedPacketsEnabled()
    return ExtraKeybindsModOptions:getOption("enableSeedPackets"):getValue()
end

function ExtraKeybindsSettings.getReadAllKeybind()
    return ExtraKeybindsModOptions:getOption("readAllKeybind"):getValue()
end
