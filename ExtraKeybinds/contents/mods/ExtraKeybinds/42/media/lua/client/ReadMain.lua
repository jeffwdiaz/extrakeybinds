-- Extra Keybinds Mod - Read All Books with Category Options
-- Enhanced version of ReadAll.lua with player-configurable literature categories

require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISReadABook"
require "TimedActions/ISInventoryTransferAction"
require "TimedActions/ISGrabItemAction"
require "ReadModOptions"
require "ReadCategories"

-- Use the game's own literature read detection logic (from original ReadAll.lua)
local function isLiteratureRead(playerObj, item)
    if not item then return false end
    if not item:IsLiterature() then return false end
    
    local modData = item:hasModData() and item:getModData() or nil
    if modData ~= nil then
        if (modData.literatureTitle) and playerObj:isLiteratureRead(modData.literatureTitle) then return true end
        if (modData.printMedia ~= nil) and playerObj:isPrintMediaRead(modData.printMedia) then return true end
        if (modData.teachedRecipe ~= nil) and playerObj:getKnownRecipes():contains(modData.teachedRecipe) then return true end
    end
    
    local skillBook = SkillBook[item:getSkillTrained()]
    if (skillBook ~= nil) and (item:getMaxLevelTrained() < playerObj:getPerkLevel(skillBook.perk) + 1) then return true end
    
    if (item:getNumberOfPages() > 0) and (playerObj:getAlreadyReadPages(item:getFullType()) == item:getNumberOfPages()) then return true end
    
    if (item:getTeachedRecipes() ~= nil) and playerObj:getKnownRecipes():containsAll(item:getTeachedRecipes()) then return true end
    
    return false
end

-- Enhanced readable book check with category filtering
local function isReadableBook(item)
    if not item then return false end
    if not item.getCategory then return false end
    
    -- Only literature, exclude writable notebooks
    if item:getCategory() ~= "Literature" then return false end
    if item.canBeWrite and item:canBeWrite() then return false end
    
    local player = getPlayer()
    if not player then return false end
    
    -- Check if player is illiterate
    if player:getTraits() and player:getTraits():isIlliterate() then
        -- Illiterate players can only read picture books
        if not item:hasTag("Picturebook") and not item:hasTag("Picture") then
            return false
        end
    end
    
    -- Check if it's a skill book that we can't read
    if item.getSkillTrained and item:getSkillTrained() then
        local skillTrained = item:getSkillTrained()
        if player and SkillBook and SkillBook[skillTrained] then
            if item.getLvlSkillTrained and item:getLvlSkillTrained() > player:getPerkLevel(SkillBook[skillTrained].perk) + 1 then
                return false -- Can't read this skill book yet
            end
        end
    end
    
    -- Use the game's own validation logic to check if already read
    if isLiteratureRead(player, item) then
        return false -- Already read
    end
    
    -- NEW: Check if this item category is enabled in settings
    if not ExtraKeybindsCategories.shouldReadItem(item) then
        return false -- Category not enabled by player
    end
    
    -- Check if the book is actually readable (has pages or is a regular book)
    if item.getNumberOfPages then
        local numPages = item:getNumberOfPages()
        if numPages > 0 then
            -- Skill books and books with explicit pages - check if we can read more
            if item.getAlreadyReadPages and item:getAlreadyReadPages() < numPages then
                return true
            end
        elseif numPages < 0 then
            -- Regular books (negative pages means always readable if not already read)
            return true
        end
    else
        -- Books without page info (like regular fiction books)
        -- If we got here and it's not already read, it should be readable
        return true
    end
    
    return false
end

local function collectUnreadBooks(inventory, accumulator)
    if not inventory then return end
    if not inventory.getItems then return end
    
    local items = inventory:getItems()
    if not items then return end
    
    for i = 0, items:size() - 1 do
        local currentItem = items:get(i)
        if currentItem and isReadableBook(currentItem) then
            table.insert(accumulator, {item = currentItem, container = inventory, isGround = false})
        end
        -- Recurse into containers
        if currentItem and currentItem.IsInventoryContainer and currentItem:IsInventoryContainer() then
            local subInv = currentItem:getInventory()
            if subInv then
                collectUnreadBooks(subInv, accumulator)
            end
        end
    end
end

local function queueReadForItem(player, item, originalContainer)
    if not player or not item then return end

    -- Skip if player cannot possibly read now (these checks mirror ISReadABook:isValid())
    if player:getTraits() and player:getTraits():isIlliterate() then return end
    if player.tooDarkToRead and player:tooDarkToRead() then return end
    
    -- Additional validation to ensure the book is actually readable
    if not isReadableBook(item) then return end

    local mainInv = player:getInventory()
    local needsTransfer = originalContainer ~= nil and originalContainer ~= mainInv

    if needsTransfer then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, originalContainer, mainInv))
    end

    -- Queue the read timed action (default duration similar to context menu)
    ISTimedActionQueue.add(ISReadABook:new(player, item, 150))

    -- Return the book to its original container after reading
    if needsTransfer then
        ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, mainInv, originalContainer))
    end
end

-- Function to collect books from a specific square
local function collectBooksFromSquare(square, accumulator)
    if not square then return end
    
    local player = getPlayer()
    if not player then return end
    
    -- Check items on the ground using getWorldObjects() (the correct method)
    local worldObjects = square:getWorldObjects()
    if not worldObjects then return end
    
    for i = 0, worldObjects:size() - 1 do
        local worldObj = worldObjects:get(i)
        if worldObj then
            -- Get the actual item from the world object
            if worldObj.getItem then
                local item = worldObj:getItem()
                if item and isReadableBook(item) then
                    table.insert(accumulator, {item = item, container = nil, isGround = true, square = square})
                end
            end
        end
    end
    
    -- Also check regular objects for containers (bags, boxes, etc.)
    local objects = square:getObjects()
    if objects then
        for i = 0, objects:size() - 1 do
            local obj = objects:get(i)
            if obj and obj.getContainer then
                local container = obj:getContainer()
                if container then
                    -- Recursively check container contents
                    collectUnreadBooks(container, accumulator, obj)
                end
            end
        end
    end
end

-- Public function: reads all unread books everywhere (inventory, containers, floor, 3x3 area)
function ExtraKeybinds_ReadAllBooksWithOptions()
    local player = getPlayer()
    if not player then return end

    local unreadBooks = {}
    local playerSquare = player:getSquare()
    if not playerSquare then return end
    
    local cell = getCell()
    if not cell then return end
    
    local x0, y0, z0 = playerSquare:getX(), playerSquare:getY(), playerSquare:getZ()
    
    -- Scan 3x3 area around player
    for x = x0-1, x0+1 do
        for y = y0-1, y0+1 do
            local square = cell:getGridSquare(x, y, z0)
            if square then
                collectBooksFromSquare(square, unreadBooks)
            end
        end
    end
    
    -- Also scan player's inventory
    collectUnreadBooks(player:getInventory(), unreadBooks)

    if #unreadBooks == 0 then
        return
    end

    -- Queue actions for each unread book
    for _, bookData in ipairs(unreadBooks) do
        if bookData.isGround then
            -- For ground items, we need to pick them up first, then read
            local item = bookData.item
            local square = bookData.square
            if item and square then
                -- First, pick up the item from the ground
                -- We need to use the world item system
                local worldItem = item:getWorldItem()
                if worldItem then
                    -- Use the grab item action to pick up from ground
                    ISTimedActionQueue.add(ISGrabItemAction:new(player, worldItem, 50))
                    -- Then read the book
                    ISTimedActionQueue.add(ISReadABook:new(player, item, 150))
                end
            end
        else
            -- For inventory/container items, use existing logic
            queueReadForItem(player, bookData.item, bookData.container)
        end
    end
end

-- Key handler using mod options keybind
local function readAllKeyHandler(key)
    if isGamePaused() then return end
    if key == nil then return end
    
    -- Use the keybind from mod options instead of game keybinds
    local configuredKey = ExtraKeybindsSettings.getReadAllKeybind()
    if key == configuredKey then
        ExtraKeybinds_ReadAllBooksWithOptions()
    end
end

Events.OnCustomUIKey.Add(readAllKeyHandler)
