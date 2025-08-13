-- Extra Keybinds Mod - Wash All (Step 1: Water detection only)

require "EKModOptions"
require "ISUI/ISWorldObjectContextMenu"

local function logWash(message)
    -- Printed messages appear in the console and log files
    print("[ExtraKeybinds][Wash] " .. tostring(message))
end

-- Build a soap/cleaning list compatible with vanilla handlers
local function buildSoapList(player)
    local soapList = {}
    if not player or not player.getInventory then return soapList end
    local inv = player:getInventory()
    if not inv then return soapList end

    local numBars, numLiquids = 0, 0

    -- Bars of soap (Soap2)
    local okBars, bars = pcall(function() return inv:getItemsFromType("Soap2", true) end)
    if okBars and bars then
        for i = 0, bars:size() - 1 do
            local item = bars:get(i)
            table.insert(soapList, item)
            numBars = numBars + 1
        end
    end

    -- Cleaning liquids (Bleach / CleaningLiquid) via fluid container component (Build 42)
    local function predicateCleaningLiquid(item)
        if not item then return false end
        -- Guard against older items without these APIs
        if not item.hasComponent or not item.getFluidContainer then return false end
        if not ComponentType or not Fluid then return false end
        if not item:hasComponent(ComponentType.FluidContainer) then return false end
        local container = item:getFluidContainer()
        if not container then return false end
        local hasUseful = (container:contains(Fluid.Bleach) or container:contains(Fluid.CleaningLiquid))
        if not hasUseful then return false end
        local amount = container:getAmount()
        local threshold = (ZomboidGlobals and ZomboidGlobals.CleanBloodBleachAmount) or 1
        return amount >= threshold
    end

    local okLiquids, bottles = pcall(function() return inv:getAllEvalRecurse(predicateCleaningLiquid) end)
    if okLiquids and bottles then
        for i = 0, bottles:size() - 1 do
            local item = bottles:get(i)
            table.insert(soapList, item)
            numLiquids = numLiquids + 1
        end
    end

    logWash(string.format("Soap list built: bars=%d, liquids=%d, total=%d", numBars, numLiquids, #soapList))
    return soapList
end

local function isAdjacentTo(playerSquare, targetSquare)
    if not playerSquare or not targetSquare then return false end
    local dx = math.abs(playerSquare:getX() - targetSquare:getX())
    local dy = math.abs(playerSquare:getY() - targetSquare:getY())
    local dz = math.abs(playerSquare:getZ() - targetSquare:getZ())
    -- Same level and within 1 tile Chebyshev distance
    return dz == 0 and dx <= 1 and dy <= 1
end

local function classifyWaterObject(obj)
    -- Try to produce a friendly label, defaults to generic "Water source"
    local label = "Water source"
    if not obj then return label end

    -- Prefer object-provided name if useful
    if obj.getObjectName then
        local n = obj:getObjectName()
        if n and n ~= "" and n ~= "IsoObject" then return n end
    end

    -- Check sprite properties for human-friendly names
    local sprite = obj.getSprite and obj:getSprite() or nil
    local props = sprite and sprite.getProperties and sprite:getProperties() or nil
    local function propVal(key)
        if not props or not props.Val then return nil end
        local ok, v = pcall(function() return props:Val(key) end)
        if ok and v and v ~= "" then return v end
        return nil
    end

    local customName = propVal("CustomName")
    if customName then
        -- Normalize common names
        local low = string.lower(customName)
        if string.find(low, "sink", 1, true) then return "Sink" end
        if string.find(low, "toilet", 1, true) then return "Toilet" end
        if string.find(low, "bath", 1, true) then return "Bathtub" end
        if string.find(low, "dispenser", 1, true) then return "Water Dispenser" end
        if string.find(low, "well", 1, true) then return "Well" end
        return customName
    end

    local groupName = propVal("GroupName")
    if groupName then
        local low = string.lower(groupName)
        if string.find(low, "sink", 1, true) or string.find(low, "faucet", 1, true) then return "Sink" end
        if string.find(low, "toilet", 1, true) then return "Toilet" end
        if string.find(low, "bath", 1, true) then return "Bathtub" end
        if string.find(low, "dispenser", 1, true) then return "Water Dispenser" end
        if string.find(low, "well", 1, true) then return "Well" end
    end

    -- Fallback: inspect sprite name patterns
    local spriteName = sprite and sprite.getName and sprite:getName() or nil
    if spriteName and type(spriteName) == "string" then
        local s = string.lower(spriteName)
        if string.find(s, "sink", 1, true) or string.find(s, "faucet", 1, true) then
            return "Sink"
        end
        if string.find(s, "toilet", 1, true) then
            return "Toilet"
        end
        if string.find(s, "bath", 1, true) then
            return "Bathtub"
        end
        if string.find(s, "well", 1, true) then
            return "Well"
        end
        if string.find(s, "dispenser", 1, true) then
            return "Water Dispenser"
        end
    end

    return label
end

local function isNaturalWaterSquare(square)
    if not square then return false end
    local props = square.getProperties and square:getProperties() or nil
    if props and IsoFlagType and props.Is and props:Is(IsoFlagType.water) then
        return true
    end
    -- Fallback: some builds expose water via sprite properties too
    local spr = square.getSprite and square:getSprite() or nil
    local sprProps = spr and spr.getProperties and spr:getProperties() or nil
    if sprProps and IsoFlagType and sprProps.Is and sprProps:Is(IsoFlagType.water) then
        return true
    end
    return false
end

local function findAdjacentWaterSource(player)
    if not player then return nil end
    local playerSq = player:getSquare()
    if not playerSq then return nil end
    local cell = getCell()
    if not cell then return nil end

    local x0, y0, z0 = playerSq:getX(), playerSq:getY(), playerSq:getZ()

    -- Track the best object source by highest fluid amount; fallback to first natural water
    local bestCandidate = nil
    local bestAmount = -1
    local naturalCandidate = nil

    -- Scan adjacent squares including current square
    for dx = -1, 1 do
        for dy = -1, 1 do
            local sq = cell:getGridSquare(x0 + dx, y0 + dy, z0)
            if sq and isAdjacentTo(playerSq, sq) then
                -- Check world objects that can contain water (sinks, toilets, etc.)
                local objects = sq:getObjects()
                if objects then
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if obj and obj.hasWater and obj.getFluidAmount then
                            local ok, hasWater = pcall(function() return obj:hasWater() end)
                            local ok2, amount = pcall(function() return obj:getFluidAmount() end)
                            if ok and ok2 and hasWater and (amount or 0) > 0 then
                                local label = classifyWaterObject(obj)
                                logWash(string.format("%s found at (%d,%d,%d), amount=%s", label, sq:getX(), sq:getY(), sq:getZ(), tostring(amount)))
                                if (amount or 0) > bestAmount then
                                    bestAmount = amount or 0
                                    bestCandidate = { kind = "object", square = sq, object = obj, label = label, amount = amount }
                                end
                            end
                        end
                    end
                end

                -- Check for natural water tiles (lake/river)
                if not naturalCandidate and isNaturalWaterSquare(sq) then
                    logWash(string.format("Natural water found at (%d,%d,%d)", sq:getX(), sq:getY(), sq:getZ()))
                    naturalCandidate = { kind = "natural", square = sq, label = "Lake" }
                end
            end
        end
    end

    if bestCandidate then
        logWash(string.format("Selected source: %s at (%d,%d,%d), amount=%s",
            bestCandidate.label, bestCandidate.square:getX(), bestCandidate.square:getY(), bestCandidate.square:getZ(), tostring(bestCandidate.amount)))
        return bestCandidate
    end

    if naturalCandidate then
        logWash(string.format("Selected source: %s at (%d,%d,%d)",
            naturalCandidate.label, naturalCandidate.square:getX(), naturalCandidate.square:getY(), naturalCandidate.square:getZ()))
        return naturalCandidate
    end

    return nil
end

local function washHotkeyHandler(key)
    if isGamePaused() then return end
    if not ExtraKeybindsSettings or not ExtraKeybindsSettings.getWashAllKeybind then return end

    local configuredKey = ExtraKeybindsSettings.getWashAllKeybind and ExtraKeybindsSettings.getWashAllKeybind()
    if not configuredKey or configuredKey <= 0 then return end
    if not key or key ~= configuredKey then return end

    local player = getPlayer()
    if not player then return end

    -- Enforce adjacency: only succeed if a valid water source is adjacent
    local found = findAdjacentWaterSource(player)
    if not found then
        return -- Silent no-op when not adjacent to water source
    end

    local label = found.label or "Water source"
    player:Say(label .. " found")

    -- Step 2a: Attempt to wash yourself using the built-in handler (auto-walk allowed by handler)
    if found.kind == "object" and found.object and ISWorldObjectContextMenu and ISWorldObjectContextMenu.onWashYourself then
        -- Check if there is anything to wash first
        local requiredWater = nil
        if ISWashYourself and ISWashYourself.GetRequiredWater then
            local okReq, req = pcall(function() return ISWashYourself.GetRequiredWater(player) end)
            if okReq then requiredWater = req else requiredWater = 0 end
        end
        logWash("Required water to wash self: " .. tostring(requiredWater))
        if not requiredWater or requiredWater <= 0 then
            logWash("Nothing to wash (self); skipping handler call")
            return
        end

        logWash(string.format("Attempting wash yourself at %s (%d,%d,%d)", label, found.square:getX(), found.square:getY(), found.square:getZ()))
        local soapList = buildSoapList(player)
        local ok, err = pcall(function()
            -- Common Build 42 signature: (playerObj, sinkObject, soapList)
            ISWorldObjectContextMenu.onWashYourself(player, found.object, soapList)
        end)
        if ok then
            logWash("Wash yourself handler invoked (object source)")
            player:Say("Washing yourself...")
        else
            logWash("Wash yourself handler failed: " .. tostring(err))
        end
    elseif found.kind == "natural" then
        -- Natural water handling will be added in a later step
        logWash("Natural water washing not implemented yet; skipping")
    else
        logWash("No compatible wash-yourself handler available")
    end
end

Events.OnCustomUIKey.Add(washHotkeyHandler)



