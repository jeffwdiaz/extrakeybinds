-- Better Simple Drink Hotkey Mod - Using Proper PZ API
require "ISUI/ISInventoryPaneContextMenu"
require "EKModOptions"

local function drink()
    local player = getPlayer()
    local playerInventory = player:getInventory()
    
    -- Check if player is thirsty
    if player:getStats():getThirst() <= 0.01 then
        player:Say("Not thirsty")
        return
    end
    
    -- First priority: Try to drink from nearby sink/faucet
    local function findNearbySink()
        local playerSquare = player:getSquare()
        if not playerSquare then return nil end
        
        local cell = getCell()
        local x0, y0, z0 = playerSquare:getX(), playerSquare:getY(), playerSquare:getZ()
        
        -- Check a 3x3 grid around the player (same as FastKeys mod)
        for x = x0-1, x0+1 do
            for y = y0-1, y0+1 do
                local sq = cell:getGridSquare(x, y, z0)
                if sq and sq:getBuilding() == player:getBuilding() then
                    -- Look for objects with water in this square
                    for i = 0, sq:getObjects():size()-1 do
                        local obj = sq:getObjects():get(i)
                        if obj:hasWater() and obj:getFluidAmount() > 0 then
                            return obj
                        end
                    end
                end
            end
        end
        return nil
    end
    
    -- Try drinking from sink first using the correct function from game files
    local sink = findNearbySink()
    if sink then
        -- Use the correct function call based on the actual game code
        -- Try different parameter approaches to avoid getSpecificPlayer error
        local playerNum = player:getPlayerNum()
        ISWorldObjectContextMenu.onDrink({sink}, sink, playerNum)
        player:Say("Drinking from faucet")
        return
    end
    
    -- Better search for drinkable items using proper PZ API
    local function findDrinkable(inventory)
        for i = 0, inventory:getItems():size() - 1 do
            local item = inventory:getItems():get(i)
            
            if item then
                local isDrinkable = false
                local itemName = item:getDisplayName() or "Unknown"
                
                -- Method 1: Check if it's a liquid Food item that reduces thirst
                if item:IsFood() then
                    local thirstChange = item:getThirstChange()
                    if thirstChange < 0 then -- Negative thirst change means it reduces thirst
                        -- Only consider it drinkable if it's actually a liquid (not solid food)
                        -- Check if it's drainable (liquids are drainable, solids aren't)
                        if item:IsDrainable() then
                            isDrinkable = true
                        end
                    end
                end
                
                -- Method 2: Check if it can store water and is currently a water source
                if item:canStoreWater() and item:isWaterSource() then
                    local uses = item:getCurrentUses()
                    if uses > 0 then
                        isDrinkable = true
                    end
                end
                
                -- Method 3: Check if it's drainable (like water bottles)
                if item:IsDrainable() then
                    local uses = item:getCurrentUses()
                    if uses > 0 then
                        -- Additional check: see if it has thirst-reducing properties
                        if item.getThirstChange and item:getThirstChange() < 0 then
                            isDrinkable = true
                        -- Or if it's a water source
                        elseif item:isWaterSource() then
                            isDrinkable = true
                        end
                    end
                end
                
                if isDrinkable then
                    return item, inventory
                end
                
                -- Check containers recursively
                if item:IsInventoryContainer() then
                    local subInventory = item:getInventory()
                    if subInventory then
                        local found, foundIn = findDrinkable(subInventory)
                        if found then
                            return found, foundIn
                        end
                    end
                end
            end
        end
        return nil, nil
    end
    
    -- Find any drinkable item
    local drinkItem, originalContainer = findDrinkable(playerInventory)
    
    if drinkItem then
        local needsReturn = (originalContainer ~= playerInventory)
        
        if needsReturn then
            -- Move to main inventory first
            ISTimedActionQueue.add(ISInventoryTransferAction:new(player, drinkItem, originalContainer, playerInventory))
        end
        
        -- Drink it using the proper action
        local drinkAction = ISDrinkFromBottle:new(player, drinkItem, 10)
        ISTimedActionQueue.add(drinkAction)
        
        if needsReturn then
            -- Move it back to original container
            ISTimedActionQueue.add(ISInventoryTransferAction:new(player, drinkItem, playerInventory, originalContainer))
        end
        
        player:Say("Drinking " .. drinkItem:getDisplayName())
    else
        player:Say("No drinkable items found")
    end
end

-- Key handler
local function drinkButtonHandler(key)
    if isGamePaused() then return end
    if key == nil then return end

    -- Use the keybind from mod options
    local configuredKey = ExtraKeybindsSettings and ExtraKeybindsSettings.getDrinkKeybind and ExtraKeybindsSettings.getDrinkKeybind()
    if configuredKey and configuredKey > 0 and key == configuredKey then
        drink()
    end
end

-- Register the hotkey event
Events.OnCustomUIKey.Add(drinkButtonHandler)