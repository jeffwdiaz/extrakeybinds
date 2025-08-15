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

-- Find all dirty bandages/rags across main inventory AND nested containers (incl. worn bags)
-- Returns two arrays: mainInvItems (items already in player inventory) and bagItems (items in other containers)
local function findDirtyItems(player)
	if not player then 
		logWash("DEBUG: No player provided")
		return {}, {}
	end
	local inv = player:getInventory()
	if not inv then 
		logWash("DEBUG: No inventory found")
		return {}, {}
	end

	local dirtyTypeSet = {
		["Base.BandageDirty"] = true,
		["Base.RippedSheetsDirty"] = true,
		["Base.DenimStripsDirty"] = true,
		["Base.LeatherStripsDirty"] = true,
	}

	local function isDirtyBandageLike(item)
		if not item or not item.getFullType then return false end
		if item.getJobDelta and item:getJobDelta() > 0 then return false end
		local fullType = item:getFullType()
		return dirtyTypeSet[fullType] == true
	end

	-- Use recursive search to include worn-bag contents and nested containers
	local ok, all = pcall(function() return inv:getAllEvalRecurse(isDirtyBandageLike) end)
	if not ok or not all then
		logWash("DEBUG: getAllEvalRecurse not available; falling back to non-recursive getAllTag")
		local nonrec = inv:getAllTag("CanBeWashed", ArrayList.new())
		all = nonrec
	end

	-- Diagnostics similar to previous debug
	local manualCheck = {
		["Base.BandageDirty"] = inv:getCountTypeRecurse("Base.BandageDirty"),
		["Base.DenimStripsDirty"] = inv:getCountTypeRecurse("Base.DenimStripsDirty"),
		["Base.LeatherStripsDirty"] = inv:getCountTypeRecurse("Base.LeatherStripsDirty"),
		["Base.RippedSheetsDirty"] = inv:getCountTypeRecurse("Base.RippedSheetsDirty"),
	}
	for itemType, count in pairs(manualCheck) do
		logWash(string.format("DEBUG: Manual check - %s: %d items", itemType, count))
	end

	local mainInvItems, bagItems = {}, {}
	local playerInv = player:getInventory()

	for i = 0, (all:size() - 1) do
		local item = all:get(i)
		if isDirtyBandageLike(item) then
			logWash(string.format("DEBUG: candidate %d: %s (jobDelta: %s)", i, item:getFullType(), tostring(item:getJobDelta())))
			local fromContainer = item.getContainer and item:getContainer() or nil
			if fromContainer == playerInv then
				table.insert(mainInvItems, { item = item })
			else
				table.insert(bagItems, { item = item, fromContainer = fromContainer })
			end
		end
	end

	logWash(string.format("DEBUG: Returning %d main-inv items and %d bag/nested items for cleaning", #mainInvItems, #bagItems))
	return mainInvItems, bagItems
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
    
    -- Hard limit to adjacent object water sources only (natural water later)
    if not waterObject.getSquare then
        logWash("DEBUG: waterObject has no getSquare method")
        return
    end
    if not waterObject:hasWater() then
        logWash("DEBUG: waterObject has no water")
        return
    end
    if waterObject:getFluidAmount() <= 0 then
        logWash("DEBUG: waterObject fluid amount <= 0")
        return
    end

    logWash("DEBUG: Water source validation passed")

	-- Find all dirty items (split by container origin)
	local mainInvItems, bagItems = findDirtyItems(player)
	local totalCount = #mainInvItems + #bagItems
	logWash(string.format("DEBUG: findDirtyItems returned %d main + %d bag = %d total", #mainInvItems, #bagItems, totalCount))
	if totalCount == 0 then
		logWash("No items available to clean")
		return
	end

	-- Soap is NOT needed for bandage/rag cleaning (only uses water)
	logWash("DEBUG: Skipping soap list for bandages - they only need water")

	-- Announce what we're doing
	player:Say("Cleaning bandages and rags...")
	logWash(string.format("Found %d items to clean", totalCount))

	-- Ensure we are adjacent once
	logWash("DEBUG: About to call luautils.walkAdj")
	if not luautils.walkAdj(player, waterObject:getSquare(), true) then
		logWash("Walk adjacent failed")
		return
	end
	logWash("DEBUG: walkAdj succeeded")

	-- 1) Wash items already in main inventory (one at a time)
	for _, rec in ipairs(mainInvItems) do
		local item = rec.item
		local single = { item }
		local ok1, err1 = pcall(function()
			ISWorldObjectContextMenu.onWashClothing(player, waterObject, {}, single, nil, false)
		end)
		if not ok1 then
			logWash("ERROR washing main-inv item: " .. tostring(err1))
		end
	end

	-- 2) Wash items from worn bags / nested containers (transfer-in, then wash)
	local playerInv = player:getInventory()
	for _, rec in ipairs(bagItems) do
		local item = rec.item
		local from = rec.fromContainer
		if item and from and from ~= playerInv then
			ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, from, playerInv))
		end
		local single = { item }
		local ok2, err2 = pcall(function()
			ISWorldObjectContextMenu.onWashClothing(player, waterObject, {}, single, nil, false)
		end)
		if not ok2 then
			logWash("ERROR washing bag/nested item: " .. tostring(err2))
		end
	end

	logWash("Wash actions queued successfully")
end

-- Find all worn clothing items that need washing (blood or dirt > 0)
local function findDirtyWornClothing(player)
	if not player then return {} end
	
	local dirtyClothing = {}
	local wornItems = player:getWornItems()
	if not wornItems then return dirtyClothing end
	
	for i = 0, wornItems:size() - 1 do
		local wornItem = wornItems:get(i)
		if wornItem and wornItem.getItem then
			local item = wornItem:getItem()
			if item and item.IsClothing and item:IsClothing() then
				local needsWashing = false
				local bloodLevel = 0
				local dirtLevel = 0
				
				-- Check blood level
				if item.getBloodLevel then
					local ok, blood = pcall(function() return item:getBloodLevel() end)
					if ok and blood and blood > 0 then
						needsWashing = true
						bloodLevel = blood
					end
				end
				
				-- Check dirt level
				if item.getDirtyness then
					local ok, dirt = pcall(function() return item:getDirtyness() end)
					if ok and dirt and dirt > 0 then
						needsWashing = true
						dirtLevel = dirt
					end
				end
				
				-- Skip if already being processed
				if needsWashing and item.getJobDelta and item:getJobDelta() == 0 then
					logWash(string.format("Found dirty worn clothing: %s (blood: %.1f, dirt: %.1f)", 
						item:getDisplayName(), bloodLevel, dirtLevel))
					table.insert(dirtyClothing, item)
				end
			end
		end
	end
	
	logWash(string.format("Found %d worn clothing items needing wash", #dirtyClothing))
	return dirtyClothing
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

-- Clean all dirty worn clothing
local function queueCleanWornClothing(player, waterObject)
	logWash("=== STAGE 3: Starting worn clothing washing ===")
	
	if not player or not waterObject then
		logWash("DEBUG: Missing player or waterObject for worn clothing wash")
		return
	end
	
	-- Find worn clothing that needs washing
	local dirtyClothing = findDirtyWornClothing(player)
	if #dirtyClothing == 0 then
		logWash("No worn clothing needs washing")
		return
	end
	
	-- Build soap list for worn clothing (needed for blood removal)
	local soapList = buildSoapList(player)
	logWash(string.format("Built soap list for worn clothing: %d items", #soapList))
	
	-- Announce what we're doing
	player:Say("Washing worn clothing...")
	logWash(string.format("Found %d worn clothing items to wash", #dirtyClothing))
	
	-- Ensure adjacency (should already be done from Stage 1, but safety check)
	if not luautils.walkAdj(player, waterObject:getSquare(), true) then
		logWash("Walk adjacent failed for worn clothing")
		return
	end
	
	-- Wash each clothing item individually (worn items don't need transfers)
	for _, item in ipairs(dirtyClothing) do
		local single = { item }
		local ok, err = pcall(function()
			ISWorldObjectContextMenu.onWashClothing(player, waterObject, soapList, single, nil, false)
		end)
		if not ok then
			logWash("ERROR washing worn clothing item: " .. tostring(err))
		else
			logWash(string.format("Queued wash for worn item: %s", item:getDisplayName()))
		end
	end
	
	logWash("Worn clothing wash actions queued successfully")
end

-- Find all equipped weapons that need cleaning (blood > 0)
local function findBloodyEquippedWeapons(player)
	if not player then return {} end
	
	local bloodyWeapons = {}
	
	-- Check primary hand item
	local primaryItem = player:getPrimaryHandItem()
	if primaryItem and primaryItem.IsWeapon and primaryItem:IsWeapon() then
		local bloodLevel = 0
		if primaryItem.getBloodLevel then
			local ok, blood = pcall(function() return primaryItem:getBloodLevel() end)
			if ok and blood and blood > 0 then
				bloodLevel = blood
				-- Skip if already being processed
				if primaryItem.getJobDelta and primaryItem:getJobDelta() == 0 then
					logWash(string.format("Found bloody primary weapon: %s (blood: %.1f)", 
						primaryItem:getDisplayName(), bloodLevel))
					table.insert(bloodyWeapons, primaryItem)
				end
			end
		end
	end
	
	-- Check secondary hand item
	local secondaryItem = player:getSecondaryHandItem()
	if secondaryItem and secondaryItem.IsWeapon and secondaryItem:IsWeapon() then
		local bloodLevel = 0
		if secondaryItem.getBloodLevel then
			local ok, blood = pcall(function() return secondaryItem:getBloodLevel() end)
			if ok and blood and blood > 0 then
				bloodLevel = blood
				-- Skip if already being processed
				if secondaryItem.getJobDelta and secondaryItem:getJobDelta() == 0 then
					logWash(string.format("Found bloody secondary weapon: %s (blood: %.1f)", 
						secondaryItem:getDisplayName(), bloodLevel))
					table.insert(bloodyWeapons, secondaryItem)
				end
			end
		end
	end
	
	logWash(string.format("Found %d equipped weapons needing cleaning", #bloodyWeapons))
	return bloodyWeapons
end

-- Clean all bloody equipped weapons
local function queueCleanEquippedWeapons(player, waterObject)
	logWash("=== STAGE 4: Starting equipped weapons cleaning ===")
	
	if not player or not waterObject then
		logWash("DEBUG: Missing player or waterObject for weapons cleaning")
		return
	end
	
	-- Find equipped weapons that need cleaning
	local bloodyWeapons = findBloodyEquippedWeapons(player)
	if #bloodyWeapons == 0 then
		logWash("No equipped weapons need cleaning")
		return
	end
	
	-- Build soap list for weapons (needed for blood removal)
	local soapList = buildSoapList(player)
	logWash(string.format("Built soap list for weapons: %d items", #soapList))
	
	-- Announce what we're doing
	player:Say("Cleaning equipped weapons...")
	logWash(string.format("Found %d equipped weapons to clean", #bloodyWeapons))
	
	-- Ensure adjacency (should already be done from previous stages, but safety check)
	if not luautils.walkAdj(player, waterObject:getSquare(), true) then
		logWash("Walk adjacent failed for equipped weapons")
		return
	end
	
	-- Clean each weapon individually (equipped items don't need transfers)
	for _, weapon in ipairs(bloodyWeapons) do
		local single = { weapon }
		local ok, err = pcall(function()
			ISWorldObjectContextMenu.onWashClothing(player, waterObject, soapList, single, nil, false)
		end)
		if not ok then
			logWash("ERROR cleaning equipped weapon: " .. tostring(err))
		else
			logWash(string.format("Queued clean for equipped weapon: %s", weapon:getDisplayName()))
		end
	end
	
	logWash("Equipped weapons cleaning actions queued successfully")
end

-- Find all worn bags/containers that need washing (blood or dirt > 0)
local function findDirtyWornBags(player)
	if not player then return {} end
	
	local dirtyBags = {}
	local wornItems = player:getWornItems()
	if not wornItems then return dirtyBags end
	
	for i = 0, wornItems:size() - 1 do
		local wornItem = wornItems:get(i)
		if wornItem and wornItem.getItem then
			local item = wornItem:getItem()
			if item and item.IsInventoryContainer and item:IsInventoryContainer() then
				local needsWashing = false
				local bloodLevel = 0
				local dirtLevel = 0
				
				-- Check blood level
				if item.getBloodLevel then
					local ok, blood = pcall(function() return item:getBloodLevel() end)
					if ok and blood and blood > 0 then
						needsWashing = true
						bloodLevel = blood
					end
				end
				
				-- Check dirt level (if containers can get dirty)
				if item.getDirtyness then
					local ok, dirt = pcall(function() return item:getDirtyness() end)
					if ok and dirt and dirt > 0 then
						needsWashing = true
						dirtLevel = dirt
					end
				end
				
				-- Skip if already being processed
				if needsWashing and item.getJobDelta and item:getJobDelta() == 0 then
					logWash(string.format("Found dirty worn bag: %s (blood: %.1f, dirt: %.1f)", 
						item:getDisplayName(), bloodLevel, dirtLevel))
					table.insert(dirtyBags, item)
				end
			end
		end
	end
	
	logWash(string.format("Found %d worn bags needing wash", #dirtyBags))
	return dirtyBags
end

-- Clean all dirty worn bags/containers
local function queueCleanWornBags(player, waterObject)
	logWash("=== STAGE 5: Starting worn bags washing ===")
	
	if not player or not waterObject then
		logWash("DEBUG: Missing player or waterObject for worn bags wash")
		return
	end
	
	-- Find worn bags that need washing
	local dirtyBags = findDirtyWornBags(player)
	if #dirtyBags == 0 then
		logWash("No worn bags need washing")
		return
	end
	
	-- Build soap list for worn bags (needed for blood removal)
	local soapList = buildSoapList(player)
	logWash(string.format("Built soap list for worn bags: %d items", #soapList))
	
	-- Announce what we're doing
	player:Say("Washing worn bags...")
	logWash(string.format("Found %d worn bags to wash", #dirtyBags))
	
	-- Ensure adjacency (should already be done from previous stages, but safety check)
	if not luautils.walkAdj(player, waterObject:getSquare(), true) then
		logWash("Walk adjacent failed for worn bags")
		return
	end
	
	-- Wash each bag individually (worn containers don't need transfers)
	for _, bag in ipairs(dirtyBags) do
		local single = { bag }
		local ok, err = pcall(function()
			ISWorldObjectContextMenu.onWashClothing(player, waterObject, soapList, single, nil, false)
		end)
		if not ok then
			logWash("ERROR washing worn bag: " .. tostring(err))
		else
			logWash(string.format("Queued wash for worn bag: %s", bag:getDisplayName()))
		end
	end
	
	logWash("Worn bags wash actions queued successfully")
end

-- Find any remaining dirty items that weren't covered by previous stages
-- This includes: other clothing in inventory/bags, dirty containers not worn, misc washable items
local function findRemainingDirtyItems(player)
	if not player then return {}, {} end
	local inv = player:getInventory()
	if not inv then return {}, {} end
	
	-- Get all items that can be washed using the CanBeWashed tag
	local ok, allWashable = pcall(function() return inv:getAllEvalRecurse(function(item)
		if not item or not item.getFullType then return false end
		if item.getJobDelta and item:getJobDelta() > 0 then return false end -- Skip items being processed
		
		-- Check if item has CanBeWashed tag OR has blood/dirt levels
		local hasWashTag = false
		if item.getTags then
			local tags = item:getTags()
			if tags and tags:contains("CanBeWashed") then
				hasWashTag = true
			end
		end
		
		local hasBloodOrDirt = false
		-- Check blood level
		if item.getBloodLevel then
			local bloodOk, blood = pcall(function() return item:getBloodLevel() end)
			if bloodOk and blood and blood > 0 then
				hasBloodOrDirt = true
			end
		end
		-- Check dirt level
		if item.getDirtyness then
			local dirtOk, dirt = pcall(function() return item:getDirtyness() end)
			if dirtOk and dirt and dirt > 0 then
				hasBloodOrDirt = true
			end
		end
		
		return hasWashTag or hasBloodOrDirt
	end) end)
	
	if not ok or not allWashable then
		logWash("DEBUG: getAllEvalRecurse failed for remaining items, skipping Stage 6")
		return {}, {}
	end
	
	local mainInvItems, bagItems = {}, {}
	local playerInv = player:getInventory()
	
	-- Filter out items that were already handled in previous stages
	local alreadyHandledTypes = {
		["Base.BandageDirty"] = true,
		["Base.RippedSheetsDirty"] = true,
		["Base.DenimStripsDirty"] = true,
		["Base.LeatherStripsDirty"] = true,
	}
	
	for i = 0, allWashable:size() - 1 do
		local item = allWashable:get(i)
		if item then
			local fullType = item:getFullType()
			local isWorn = false
			local isEquipped = false
			
			-- Skip if this was handled by previous stages
			if alreadyHandledTypes[fullType] then
				-- Skip bandages/rags (Stage 1)
			elseif item.IsClothing and item:IsClothing() then
				-- Check if this clothing is currently worn (Stage 3 already handled worn clothing)
				local wornItems = player:getWornItems()
				if wornItems then
					for j = 0, wornItems:size() - 1 do
						local wornItem = wornItems:get(j)
						if wornItem and wornItem.getItem and wornItem:getItem() == item then
							isWorn = true
							break
						end
					end
				end
				if not isWorn then
					-- This is unworn clothing in inventory/bags that needs washing
					local fromContainer = item.getContainer and item:getContainer() or nil
					if fromContainer == playerInv then
						table.insert(mainInvItems, { item = item })
					else
						table.insert(bagItems, { item = item, fromContainer = fromContainer })
					end
				end
			elseif item.IsWeapon and item:IsWeapon() then
				-- Check if this weapon is currently equipped (Stage 4 already handled equipped weapons)
				local primaryWeapon = player:getPrimaryHandItem()
				local secondaryWeapon = player:getSecondaryHandItem()
				if item ~= primaryWeapon and item ~= secondaryWeapon then
					-- This is an unequipped weapon in inventory/bags that needs cleaning
					local fromContainer = item.getContainer and item:getContainer() or nil
					if fromContainer == playerInv then
						table.insert(mainInvItems, { item = item })
					else
						table.insert(bagItems, { item = item, fromContainer = fromContainer })
					end
				end
			elseif item.IsInventoryContainer and item:IsInventoryContainer() then
				-- Check if this container is currently worn (Stage 5 already handled worn bags)
				local wornItems = player:getWornItems()
				if wornItems then
					for j = 0, wornItems:size() - 1 do
						local wornItem = wornItems:get(j)
						if wornItem and wornItem.getItem and wornItem:getItem() == item then
							isWorn = true
							break
						end
					end
				end
				if not isWorn then
					-- This is an unworn container in inventory/bags that needs washing
					local fromContainer = item.getContainer and item:getContainer() or nil
					if fromContainer == playerInv then
						table.insert(mainInvItems, { item = item })
					else
						table.insert(bagItems, { item = item, fromContainer = fromContainer })
					end
				end
			else
				-- Other washable items (tools, etc.)
				local fromContainer = item.getContainer and item:getContainer() or nil
				if fromContainer == playerInv then
					table.insert(mainInvItems, { item = item })
				else
					table.insert(bagItems, { item = item, fromContainer = fromContainer })
				end
			end
		end
	end
	
	logWash(string.format("Found %d remaining main-inv items and %d remaining bag items needing wash", #mainInvItems, #bagItems))
	return mainInvItems, bagItems
end

-- Clean any remaining dirty items not covered by previous stages
local function queueCleanRemainingItems(player, waterObject)
	logWash("=== STAGE 6: Starting remaining dirty items washing ===")
	
	if not player or not waterObject then
		logWash("DEBUG: Missing player or waterObject for remaining items wash")
		return
	end
	
	-- Find remaining items that need washing
	local mainInvItems, bagItems = findRemainingDirtyItems(player)
	local totalCount = #mainInvItems + #bagItems
	if totalCount == 0 then
		logWash("No remaining items need washing")
		return
	end
	
	-- Build soap list for remaining items (may need soap for blood removal)
	local soapList = buildSoapList(player)
	logWash(string.format("Built soap list for remaining items: %d items", #soapList))
	
	-- Announce what we're doing
	player:Say("Washing remaining items...")
	logWash(string.format("Found %d remaining items to wash", totalCount))
	
	-- Ensure adjacency (should already be done from previous stages, but safety check)
	if not luautils.walkAdj(player, waterObject:getSquare(), true) then
		logWash("Walk adjacent failed for remaining items")
		return
	end
	
	-- 1) Wash items already in main inventory (one at a time)
	for _, rec in ipairs(mainInvItems) do
		local item = rec.item
		local single = { item }
		local ok1, err1 = pcall(function()
			ISWorldObjectContextMenu.onWashClothing(player, waterObject, soapList, single, nil, false)
		end)
		if not ok1 then
			logWash("ERROR washing remaining main-inv item: " .. tostring(err1))
		else
			logWash(string.format("Queued wash for remaining item: %s", item:getDisplayName()))
		end
	end
	
	-- 2) Wash items from bags (transfer-in, then wash)
	local playerInv = player:getInventory()
	for _, rec in ipairs(bagItems) do
		local item = rec.item
		local from = rec.fromContainer
		if item and from and from ~= playerInv then
			ISTimedActionQueue.add(ISInventoryTransferAction:new(player, item, from, playerInv))
		end
		local single = { item }
		local ok2, err2 = pcall(function()
			ISWorldObjectContextMenu.onWashClothing(player, waterObject, soapList, single, nil, false)
		end)
		if not ok2 then
			logWash("ERROR washing remaining bag item: " .. tostring(err2))
		else
			logWash(string.format("Queued wash for remaining bag item: %s", item:getDisplayName()))
		end
	end
	
	logWash("Remaining items wash actions queued successfully")
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

				-- Natural water fallback removed; see `washfeature.md` for archived snippet
            end
        end
    end

    if bestCandidate then
        logWash(string.format("Selected source: %s at (%d,%d,%d), amount=%s",
            bestCandidate.label, bestCandidate.square:getX(), bestCandidate.square:getY(), bestCandidate.square:getZ(), tostring(bestCandidate.amount)))
        return bestCandidate
    end

	-- Natural water fallback removed; see `washfeature.md` for archived snippet

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
	-- Explicitly log the selected water source details for debugging/telemetry
	logWash(string.format("Source found: kind=%s, label=%s, pos=(%d,%d,%d), amount=%s",
		tostring(found.kind), tostring(label),
		found.square and found.square:getX() or -1,
		found.square and found.square:getY() or -1,
		found.square and found.square:getZ() or -1,
		tostring(found.amount)))

    -- =================================================================
    -- * STAGE 1: CLEAN BANDAGES AND RAGS FIRST
    -- =================================================================
    -- Clean dirty bandages, leather strips, denim strips, and ripped sheets
    -- This happens before washing the player to ensure items are cleaned first
    logWash("=== STAGE 1: Starting bandage and rag cleaning ===")
    queueCleanBandagesAndRags(player, found.object)

    -- =================================================================
    -- * STAGE 2: WASH THE PLAYER
    -- =================================================================
    -- After bandages/rags are queued for cleaning, wash the player's body
    logWash("=== STAGE 2: Starting player washing ===")
    -- Attempt to wash yourself using the built-in handler (auto-walk allowed by handler)
    if found.kind == "object" and found.object and ISWorldObjectContextMenu and ISWorldObjectContextMenu.onWashYourself then
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
    elseif found.kind == "natural" then
        -- Natural water handling will be added in a later step
        logWash("Natural water washing not implemented yet; skipping")
    else
        logWash("No compatible wash-yourself handler available")
    end

    -- =================================================================
    -- * STAGE 3: WASH WORN CLOTHING
    -- =================================================================
    -- After washing the player, clean any dirty/bloody worn clothing
    if found.kind == "object" and found.object then
        queueCleanWornClothing(player, found.object)
    else
        logWash("STAGE 3: Skipping worn clothing wash (no object water source)")
    end

    -- =================================================================
    -- * STAGE 4: CLEAN EQUIPPED WEAPONS
    -- =================================================================
    -- After washing worn clothing, clean any bloody equipped weapons
    if found.kind == "object" and found.object then
        queueCleanEquippedWeapons(player, found.object)
    else
        logWash("STAGE 4: Skipping equipped weapons cleaning (no object water source)")
    end

    -- =================================================================
    -- * STAGE 5: WASH WORN BAGS
    -- =================================================================
    -- After cleaning equipped weapons, wash any dirty/bloody worn bags themselves
    if found.kind == "object" and found.object then
        queueCleanWornBags(player, found.object)
    else
        logWash("STAGE 5: Skipping worn bags washing (no object water source)")
    end

    -- =================================================================
    -- * STAGE 6: WASH REMAINING DIRTY ITEMS
    -- =================================================================
    -- Finally, wash any remaining dirty items in inventory/bags not covered by previous stages
    if found.kind == "object" and found.object then
        queueCleanRemainingItems(player, found.object)
    else
        logWash("STAGE 6: Skipping remaining items washing (no object water source)")
    end
end

Events.OnCustomUIKey.Add(washHotkeyHandler)



