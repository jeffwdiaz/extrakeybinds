-- QuickUse Drugs Mod - Mod Options Configuration
-- Project Zomboid Build 42 compatible
-- Author: fireblanket

require "PZAPI/ModOptions"

-- Mod Options Setup
local QUDrugsOptions = PZAPI.ModOptions:create("QuickUseDrugs", "QuickUse Drugs")

-- Add title and description
QUDrugsOptions:addDescription(
    "- [ Configure QuickUse Drugs keybindings and options ] -")

-- * ---------------------------------------------------------------------------
-- * Key binding options

QUDrugsOptions:addDescription("- [ Key Bindings ] -")

QUDrugsOptions:addKeyBind(
    "quickUseDrugsKeybind",
    "QuickUse Drugs",
    0, -- Default: none (unbound)
    "Key binding to trigger quick use of various drugs based on player condition"
)

-- Global access to options
QUDrugsModOptions = QUDrugsOptions

-- Helper functions to check option values
QUDrugsSettings = {}

function QUDrugsSettings.getQuickUseDrugsKeybind()
    return QUDrugsModOptions:getOption("quickUseDrugsKeybind"):getValue()
end

print("QUDrugs: Mod options loaded successfully")
