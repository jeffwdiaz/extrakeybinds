-- Extra Keybinds Mod - Literature Categorization System
-- Categorizes literature items based on their Item IDs and properties

require "ExtraKeybindsModOptions"

ExtraKeybindsCategories = {}

-- Category detection functions based on Item IDs from items.md

function ExtraKeybindsCategories.isLeisureMagazine(item)
    if not item or not item.getFullType then return false end
    
    local itemType = item:getFullType()
    local itemId = item:getType()
    
    -- Leisure magazines based on items.md patterns
    -- These are entertainment magazines, not recipe-teaching ones
    local leisureMagazinePatterns = {
        "^Magazine$",           -- Base.Magazine  
        "^HottieZ",            -- Base.HottieZ_New
        "^TVMagazine$",        -- Base.TVMagazine
        "^Magazine_",          -- Base.Magazine_Popular, Base.Magazine_Rich, etc.
        "^MagazineCrossword$", -- Base.MagazineCrossword
        "^MagazineWordsearch$" -- Base.MagazineWordsearch
    }
    
    for _, pattern in ipairs(leisureMagazinePatterns) do
        if string.match(itemId, pattern) then
            return true
        end
    end
    
    return false
end

function ExtraKeybindsCategories.isRecipeMagazine(item)
    if not item or not item.getFullType then return false end
    
    local itemId = item:getType()
    
    -- Recipe magazines end with Mag followed by numbers (from items.md)
    -- Examples: TailoringMag9, SmithingMag8, CookingMag1, etc.
    if string.match(itemId, "Mag%d+$") then
        return true
    end
    
    return false
end

function ExtraKeybindsCategories.isSkillBook(item)
    if not item or not item.getFullType then return false end
    
    local itemId = item:getType()
    
    -- Skill books follow pattern: Book[Skill][Level] (from items.md)
    -- Examples: BookFarming1, BookCarpentry2, BookElectrician3, etc.
    local skillBookPatterns = {
        "^BookFarming%d+$",      -- Agriculture books
        "^BookAiming%d+$",       -- Aiming books
        "^BookHusbandry%d+$",    -- Animal Care books
        "^BookButchering%d+$",   -- Butchering books
        "^BookCarpentry%d+$",    -- Carpentry books
        "^BookCarving%d+$",      -- Carving books
        "^BookCooking%d+$",      -- Cooking books
        "^BookElectrician%d+$",  -- Electrical books
        "^BookFirstAid%d+$",     -- First Aid books
        "^BookFishing%d+$",      -- Fishing books
        "^BookForaging%d+$",     -- Foraging books
        "^BookGlassmaking%d+$",  -- Glassmaking books
        "^BookFlintKnapping%d+$",-- Knapping books
        "^BookLongBlade%d+$",    -- Long Blade books
        "^BookMaintenance%d+$",  -- Maintenance books
        "^BookMasonry%d+$",      -- Masonry books
        "^BookMechanic%d+$",     -- Mechanics books
        "^BookBlacksmith%d+$",   -- Metalworking books
        "^BookPottery%d+$",      -- Pottery books
        "^BookReloading%d+$",    -- Reloading books
        "^BookTailoring%d+$",    -- Tailoring books
        "^BookTracking%d+$",     -- Tracking books
        "^BookTrapping%d+$",     -- Trapping books
        "^BookMetalWelding%d+$", -- Welding books
        "^SewingPattern$"        -- Special case: Sewing Pattern
    }
    
    for _, pattern in ipairs(skillBookPatterns) do
        if string.match(itemId, pattern) then
            return true
        end
    end
    
    return false
end

function ExtraKeybindsCategories.isLeisureBook(item)
    if not item or not item.getFullType then return false end
    
    local itemId = item:getType()
    
    -- Leisure books from items.md (hardcover, paperback, leatherbound)
    local leisureBookPatterns = {
        "^Book$",              -- Generic book
        "^Book_",              -- Book_AdventureNonFiction, Book_Art, etc.
        "^Paperback",          -- Paperback, Paperback_Art, etc.
        "^BookFancy_",         -- Leatherbound books
        "^HollowBook",         -- Hollow books
        "^HollowFancyBook$",   -- Hollow leatherbound book
        "^ChildsPictureBook$", -- Picture books
        "^ComicBook",          -- Comic books
        "^RPGmanual$"          -- RPG Manual
    }
    
    for _, pattern in ipairs(leisureBookPatterns) do
        if string.match(itemId, pattern) then
            return true
        end
    end
    
    return false
end

function ExtraKeybindsCategories.isSeedPacket(item)
    if not item or not item.getFullType then return false end
    
    local itemId = item:getType()
    
    -- Seed packets from items.md (both empty and full)
    if string.match(itemId, "BagSeed$") or string.match(itemId, "BagSeed_Empty$") then
        return true
    end
    
    return false
end

-- Main function to check if an item should be read based on current settings
function ExtraKeybindsCategories.shouldReadItem(item)
    if not item then return false end
    
    -- Check each category based on user settings
    if ExtraKeybindsSettings.getLeisureMagazinesEnabled() and ExtraKeybindsCategories.isLeisureMagazine(item) then
        return true
    end
    
    if ExtraKeybindsSettings.getRecipeMagazinesEnabled() and ExtraKeybindsCategories.isRecipeMagazine(item) then
        return true
    end
    
    if ExtraKeybindsSettings.getSkillBooksEnabled() and ExtraKeybindsCategories.isSkillBook(item) then
        return true
    end
    
    if ExtraKeybindsSettings.getLeisureBooksEnabled() and ExtraKeybindsCategories.isLeisureBook(item) then
        return true
    end
    
    if ExtraKeybindsSettings.getSeedPacketsEnabled() and ExtraKeybindsCategories.isSeedPacket(item) then
        return true
    end
    
    return false
end
