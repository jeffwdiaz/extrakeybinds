-- Extra Keybinds Mod - Literature Categorization System
-- Categorizes literature items based on their Item IDs and properties

require "EKModOptions"

ExtraKeybindsCategories = {}

-- Category detection functions based on Item IDs from items.md

-- * Leisure Material (Magazines, Books, Comics)
function ExtraKeybindsCategories.isLeisure(item)
    if not item or not item.getFullType then return false end
    
    -- Use game properties inspired by P4HasBeenRead mod
    local hasRecipes = item.getTeachedRecipes and item:getTeachedRecipes() ~= nil
    local trainsSkill = item.getSkillTrained and item:getSkillTrained()
    local skillBook = trainsSkill and SkillBook and SkillBook[trainsSkill]
    
    -- Check mod data for print media (like P4HasBeenRead does)
    local modData = item:hasModData() and item:getModData() or nil
    local hasPrintMedia = modData and modData.printMedia
    local hasLiteratureTitle = modData and modData.literatureTitle
    
    -- Leisure material: have print media or literature title, but don't train skills or teach recipes
    if (hasPrintMedia or hasLiteratureTitle) and not hasRecipes and not skillBook then
        return true
    end
    
    -- Fallback to pattern matching for edge cases (COMMENTED OUT FOR TESTING)
    --[[
    for _, pattern in ipairs(knownLeisurePatterns) do
        if string.match(itemId, pattern) then
            return true
        end
    end
    --]]
    
    return false
end

-- * Recipe Magazines
function ExtraKeybindsCategories.isRecipeMagazine(item)
    if not item or not item.getFullType then return false end
    
    -- PURE GAME LOGIC TESTING - Use only game properties
    local hasRecipes = item.getTeachedRecipes and item:getTeachedRecipes() ~= nil
    
    -- TODO: Need to find pure game property to identify magazines vs books
    -- For now, any item with recipes could be a recipe magazine
    -- (Commenting out name-based detection for testing)
    --[[
    if hasRecipes then
        local isMagazineType = itemId:find("Magazine") ~= nil or itemId:find("Mag") ~= nil
        if isMagazineType then
            return true
        end
    end
    --]]
    
    -- Pure logic: if it has recipes, assume it could be a recipe magazine
    if hasRecipes then
        return true
    end
    
    -- Fallback pattern for known recipe magazines (COMMENTED OUT FOR TESTING)
    --[[
    if string.match(itemId, "Mag%d+$") then
        return true
    end
    --]]
    
    return false
end

-- * Skill Books
function ExtraKeybindsCategories.isSkillBook(item)
    if not item or not item.getFullType then return false end
    
    -- Use game properties: Skill books train skills AND are in SkillBook table
    local trainsSkill = item.getSkillTrained and item:getSkillTrained()
    
    if trainsSkill then
        -- Verify it's actually a skill book using the game's SkillBook table
        local skillBook = SkillBook and SkillBook[trainsSkill]
        if skillBook then
            return true
        end
    end
    
    -- Fallback patterns for known skill books (COMMENTED OUT FOR TESTING)
    --[[
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
    --]]
    
    return false
end

-- * Seed Packets
function ExtraKeybindsCategories.isSeedPacket(item)
    if not item or not item.getFullType then return false end
    
    -- PURE GAME LOGIC TESTING - Use game properties from actual seed packet definitions
    local hasRecipes = item.getTeachedRecipes and item:getTeachedRecipes() ~= nil
    local hasFastReadTag = item.hasTag and item:hasTag("FastRead")
    local isLiterature = item.getCategory and item:getCategory() == "Literature"
    
    -- Seed packets are Literature items with FastRead tag and recipes
    if isLiterature and hasFastReadTag and hasRecipes then
        -- Check if the recipes are farming-related (contain "Growing Season")
        local recipes = item:getTeachedRecipes()
        if recipes then
            for i = 0, recipes:size() - 1 do
                local recipe = recipes:get(i)
                if recipe and string.find(recipe, "Growing Season") then
                    return true
                end
            end
        end
    end
    
    return false
end

-- * Main Category Check
-- Main function to check if an item should be read based on current settings
function ExtraKeybindsCategories.shouldReadItem(item)
    if not item then return false end
    
    -- Check each category based on user settings
    if ExtraKeybindsSettings.getLeisureEnabled() and ExtraKeybindsCategories.isLeisure(item) then
        return true
    end
    
    if ExtraKeybindsSettings.getRecipeMagazinesEnabled() and ExtraKeybindsCategories.isRecipeMagazine(item) then
        return true
    end
    
    if ExtraKeybindsSettings.getSkillBooksEnabled() and ExtraKeybindsCategories.isSkillBook(item) then
        return true
    end
    
    if ExtraKeybindsSettings.getSeedPacketsEnabled() and ExtraKeybindsCategories.isSeedPacket(item) then
        return true
    end
    
    return false
end
