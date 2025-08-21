-- Extra Keybinds Mod - Mod Options Configuration
-- Provides player-configurable settings for literature reading categories

require "PZAPI/ModOptions"

-- Mod Options Setup
local ExtraKeybindsOptions = PZAPI.ModOptions:create("ExtraKeybinds", "Extra Keybinds")

-- Add title and description
ExtraKeybindsOptions:addDescription(
    "- [ Configure which types of literature to read with the Read All key binding ] -")

-- * ---------------------------------------------------------------------------
-- * Literature category options

ExtraKeybindsOptions:addTickBox(
    "enableSkillBooks",
    "Read Skill Books",
    true,
    "Books that provide skill experience multipliers"
)

ExtraKeybindsOptions:addTickBox(
    "enableRecipeMagazines",
    "Read Recipe Magazines",
    true,
    "Magazines that teach crafting recipes (Tailoring, Smithing, Cooking, etc.)"
)

ExtraKeybindsOptions:addTickBox(
    "enableLeisure",
    "Read Leisure Material",
    false,
    "Entertainment magazines, books, and comics (HottieZ, novels, comic books, etc.)"
)

ExtraKeybindsOptions:addTickBox(
    "enableSeedPackets",
    "Read Seed Packets",
    false,
    "Empty seed packets that teach farming seasons"
)

-- General safety/behavior conditions
ExtraKeybindsOptions:addTickBox(
    "disableReadWhenArmed",
    "Skip reading when holding a firearm",
    true,
    "Prevents auto-reading while a firearm is equipped in hands"
)

ExtraKeybindsOptions:addTickBox(
    "preventTaintedWater",
    "Prevent Drinking Tainted Water",
    true,
    "Skip drinking from sources that contain tainted water"
)

-- * ---------------------------------------------------------------------------
-- * Key binding options

ExtraKeybindsOptions:addDescription("- [ Key Bindings ] -")

ExtraKeybindsOptions:addKeyBind(
    "readAllKeybind",
    "Read All",
    82, -- Default: R key
    "Key binding to trigger reading all selected literature types"
)

ExtraKeybindsOptions:addKeyBind(
    "drinkKeybind",
    "Drink",
    0, -- Default: none
    "Key binding to drink from nearby sources or bottles in inventory"
)

-- Wash All feature keybind (default: Left Arrow)
-- Note: Project Zomboid uses LWJGL key codes in most cases; Left Arrow is commonly 203.
ExtraKeybindsOptions:addKeyBind(
    "washAllKeybind",
    "Wash All",
    0, -- Default: Left Arrow
    "Key binding to detect water sources and wash (feature stages)"
)

-- Sit on Ground feature keybind (default: T key)
ExtraKeybindsOptions:addKeyBind(
    "sitOnGroundKeybind",
    "Sit on Ground",
    0,
    "Key binding to sit down on the ground"
)

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

function ExtraKeybindsSettings.getDrinkKeybind()
    return ExtraKeybindsModOptions:getOption("drinkKeybind"):getValue()
end

function ExtraKeybindsSettings.getDisableReadWhenArmed()
    return ExtraKeybindsModOptions:getOption("disableReadWhenArmed"):getValue()
end

function ExtraKeybindsSettings.getPreventTaintedWater()
    return ExtraKeybindsModOptions:getOption("preventTaintedWater"):getValue()
end

function ExtraKeybindsSettings.getWashAllKeybind()
    return ExtraKeybindsModOptions:getOption("washAllKeybind"):getValue()
end

function ExtraKeybindsSettings.getSitOnGroundKeybind()
    return ExtraKeybindsModOptions:getOption("sitOnGroundKeybind"):getValue()
end
