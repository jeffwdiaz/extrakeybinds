-- Extra Keybinds Mod - Wash All (Step 1: Water detection only)

require "EKModOptions"
require "ISUI/ISWorldObjectContextMenu"
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISInventoryTransferAction"
require "TimedActions/ISCleanBandage"

local function logWash(message)
	-- Printed messages appear in the console and log files
	print("[ExtraKeybinds][Wash] " .. tostring(message))
end

-- Find all dirty bandages/rags in inventory - DEBUG VERSION
local function findDirtyItems(player)
    if not player then 
        logWash("DEBUG: No player provided")
        return {} 
    end
    local inv = player:getInventory()
    if not inv then 
        logWash("DEBUG: No inventory found")
        return {} 
    end

    -- DEBUG: Check what getAllTag actually returns
    local dirtyItems = inv:getAllTag("CanBeWashed", ArrayList.new())
    logWash(string.format("DEBUG: getAllTag('CanBeWashed') returned %d items", dirtyItems:size()))
    
    -- DEBUG: Also check for the specific dirty item types manually
    local manualCheck = {
        ["Base.BandageDirty"] = inv:getCountTypeRecurse("Base.BandageDirty"),
        ["Base.DenimStripsDirty"] = inv:getCountTypeRecurse("Base.DenimStripsDirty"), 
        ["Base.LeatherStripsDirty"] = inv:getCountTypeRecurse("Base.LeatherStripsDirty"),
        ["Base.RippedSheetsDirty"] = inv:getCountTypeRecurse("Base.RippedSheetsDirty")
    }
    
    for itemType, count in pairs(manualCheck) do
        logWash(string.format("DEBUG: Manual check - %s: %d items", itemType, count))
    end
    
    local items = {}
    
    -- Convert to Lua table and log
    for i = 0, dirtyItems:size() - 1 do
        local item = dirtyItems:get(i)
        logWash(string.format("DEBUG: getAllTag item %d: %s (jobDelta: %s)", i, item:getFullType(), tostring(item:getJobDelta())))
        if item:getJobDelta() == 0 then -- Not already being washed
            logWash(string.format("Found dirty item: %s", item:getFullType()))
            table.insert(items, item)
        end
    end

    logWash(string.format("DEBUG: Returning %d items for cleaning", #items))
    return items
end

-- Clean all dirty bandages/strips/rags in strict order, one-by-one with returns.
local function queueCleanBandagesAndRags(player, waterObject)
	logWash("DEBUG: queueCleanBandagesAndRags called")
	
	if not player then 
		logWash("DEBUG: No player provided to queueCleanBandagesAndRags")
		return 
	end
	if not waterObject then 
		logWash("DEBUG: No waterObject provided to queueCleanBandagesAndRags")
		return 
	end
	
	-- Validate required interface for any world source (object or natural tile floor)
	if not waterObject.getSquare then
		logWash("DEBUG: waterObject has no getSquare method")
		return
	end
	local hasHasWater = (waterObject.hasWater ~= nil)
	local hasHasFluid = (waterObject.hasFluid ~= nil)
	local hasGetAmount = (waterObject.getFluidAmount ~= nil)
	local hasUseFluid = (waterObject.useFluid ~= nil)
	logWash(string.format("DEBUG: waterObject caps - hasWater=%s, hasFluid=%s, getFluidAmount=%s, useFluid=%s",
		tostring(hasHasWater), tostring(hasHasFluid), tostring(hasGetAmount), tostring(hasUseFluid)))
	if not hasGetAmount then
		logWash("DEBUG: waterObject missing getFluidAmount(); cannot proceed")
		return
	end
	local okAmt, amount = pcall(function() return waterObject:getFluidAmount() end)
	if not okAmt then
		logWash("DEBUG: waterObject:getFluidAmount() errored; aborting")
		return
	end
	if (amount or 0) <= 0 then
		logWash("DEBUG: waterObject fluid amount <= 0")
		return
	end

	logWash("DEBUG: Water source validation passed")

    -- Find all dirty items
    local dirtyItems = findDirtyItems(player)
    logWash(string.format("DEBUG: findDirtyItems returned %d items", #dirtyItems))
    
    if #dirtyItems == 0 then
        logWash("No items available to clean")
        return
    end

    -- Soap is NOT needed for bandage/rag cleaning (only uses water)
    logWash("DEBUG: Skipping soap list for bandages - they only need water")
    
    -- Announce what we're doing
    player:Say("Cleaning bandages and rags...")
    logWash(string.format("Found %d items to clean", #dirtyItems))

    -- Use vanilla wash clothing handler (same pattern as wash self)
    logWash("DEBUG: About to call luautils.walkAdj")
    if not luautils.walkAdj(player, waterObject:getSquare(), true) then
        logWash("Walk adjacent failed")
        return
    end
    logWash("DEBUG: walkAdj succeeded")

    -- Queue the wash action with the list of items (no soap needed for bandages)
    logWash("DEBUG: About to call ISWorldObjectContextMenu.onWashClothing")
    logWash(string.format("DEBUG: Parameters - player: %s, waterObject: %s, dirtyItems: %d items", 
        tostring(player), tostring(waterObject), #dirtyItems))
    
    local ok, err = pcall(function()
        ISWorldObjectContextMenu.onWashClothing(player, waterObject, {}, dirtyItems, nil, false)
    end)
    
    if ok then
        logWash("Wash actions queued successfully")
    else
        logWash("ERROR calling onWashClothing: " .. tostring(err))
    end
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
				-- Check world objects that can contain water (sinks, toilets, barrels, etc.)
				local objects = sq:getObjects()
				if objects then
					for i = 0, objects:size() - 1 do
						local obj = objects:get(i)
						local supportsWater = obj and (obj.hasWater ~= nil)
						local supportsFluid = obj and (obj.hasFluid ~= nil)
						local supportsAmount = obj and (obj.getFluidAmount ~= nil)
						if obj and supportsAmount and (supportsWater or supportsFluid) then
							local okAmt, amount = pcall(function() return obj:getFluidAmount() end)
							if okAmt and (amount or 0) > 0 then
								local label = classifyWaterObject(obj)
								logWash(string.format("%s found at (%d,%d,%d), amount=%s (hasWater=%s, hasFluid=%s)", label, sq:getX(), sq:getY(), sq:getZ(), tostring(amount), tostring(supportsWater), tostring(supportsFluid)))
								if (amount or 0) > bestAmount then
									bestAmount = amount or 0
									bestCandidate = { kind = "object", square = sq, object = obj, label = label, amount = amount }
								end
							end
						end
					end
				end

				-- Check for natural water tiles (lake/river). If found, synthesize a water object via the floor.
				if not naturalCandidate and isNaturalWaterSquare(sq) then
					local floorObj = sq.getFloor and sq:getFloor() or nil
					logWash(string.format("Natural water found at (%d,%d,%d); floorObj=%s", sq:getX(), sq:getY(), sq:getZ(), tostring(floorObj)))
					if floorObj then
						-- Prefer to compute amount if possible for logging/selection
						local natAmt = nil
						if floorObj.getFluidAmount then
							local okN, a = pcall(function() return floorObj:getFluidAmount() end)
							if okN then natAmt = a end
						end
						naturalCandidate = { kind = "object", square = sq, object = floorObj, label = "Natural Water", amount = natAmt }
					end
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
		logWash(string.format("Selected source: %s at (%d,%d,%d), amount=%s",
			naturalCandidate.label, naturalCandidate.square:getX(), naturalCandidate.square:getY(), naturalCandidate.square:getZ(), tostring(naturalCandidate.amount)))
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

    -- =================================================================
    -- * STAGE 1: CLEAN BANDAGES AND RAGS FIRST
    -- =================================================================
    -- Clean dirty bandages, leather strips, denim strips, and ripped sheets
    -- This happens before washing the player to ensure items are cleaned first
    logWash("=== STAGE 1: Starting bandage and rag cleaning ===")
    if found.object then
    	-- Log capabilities of the selected water object
    	local o = found.object
    	logWash(string.format("Selected waterObject caps - hasWater=%s, hasFluid=%s, getFluidAmount=%s, useFluid=%s",
    		tostring(o and o.hasWater ~= nil), tostring(o and o.hasFluid ~= nil), tostring(o and o.getFluidAmount ~= nil), tostring(o and o.useFluid ~= nil)))
    	queueCleanBandagesAndRags(player, found.object)
    else
    	logWash("ERROR: Found source has no object; skipping Stage 1")
    end

    -- =================================================================
    -- * STAGE 2: WASH THE PLAYER
    -- =================================================================
    -- After bandages/rags are queued for cleaning, wash the player's body
    logWash("=== STAGE 2: Starting player washing ===")
    -- Attempt to wash yourself using the built-in handler (auto-walk allowed by handler)
    if found.object and ISWorldObjectContextMenu and ISWorldObjectContextMenu.onWashYourself then
        -- Check if there is anything to wash first
        local requiredWater = nil
        if ISWashYourself and ISWashYourself.GetRequiredWater then
            local okReq, req = pcall(function() return ISWashYourself.GetRequiredWater(player) end)
            if okReq then requiredWater = req else requiredWater = 0 end
        end
		logWash("Required water to wash self: " .. tostring(requiredWater))
		if requiredWater and requiredWater > 0 then
			logWash(string.format("STAGE 2: Attempting wash yourself at %s (%d,%d,%d)", label, found.square:getX(), found.square:getY(), found.square:getZ()))
			local soapList = buildSoapList(player)
			local ok, err = pcall(function()
				-- Common Build 42 signature: (playerObj, sinkObject, soapList)
				ISWorldObjectContextMenu.onWashYourself(player, found.object, soapList)
			end)
			if ok then
				logWash("STAGE 2: Wash yourself handler invoked (object source)")
				player:Say("Washing yourself...")
			else
				logWash("STAGE 2: Wash yourself handler failed: " .. tostring(err))
			end
		else
			logWash("STAGE 2: Nothing to wash (self); skipping handler call")
		end
    else
        logWash("No compatible wash-yourself handler available or no water object")
    end
end

Events.OnCustomUIKey.Add(washHotkeyHandler)



