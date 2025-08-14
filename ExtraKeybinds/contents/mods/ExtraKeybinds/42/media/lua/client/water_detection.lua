-- water_detection.lua
-- Reusable helpers to detect nearby water sources for washing (clothes/self)
-- and for drinking/filling, without coupling to UI code.
--
-- Exported API (global table):
--   WaterDetection.findWashSource(player)  -> record|nil
--   WaterDetection.findDrinkSource(player) -> record|nil
--
-- Returned record shape:
--   { kind = "object", object = <IsoObject>, square = <IsoGridSquare>, amount = <number>, label = <string> }
--   or
--   { kind = "natural", square = <IsoGridSquare>, label = "Natural Water" }

local WaterDetection = {}

-- Internal: log helper for debug builds (kept quiet by default)
local function dbg(msg)
	-- print("[WaterDetection] " .. tostring(msg))
end

-- Internal: cheap adjacency check (Chebyshev distance <= 1 on same Z)
local function isAdjacentTo(aSq, bSq)
	if not aSq or not bSq then return false end
	local dx = math.abs(aSq:getX() - bSq:getX())
	local dy = math.abs(aSq:getY() - bSq:getY())
	local dz = math.abs(aSq:getZ() - bSq:getZ())
	return dz == 0 and dx <= 1 and dy <= 1
end

-- Internal: human-friendly object label with graceful fallback
local function classifyWaterObject(obj)
	local label = "Water source"
	if not obj then return label end
	if obj.getObjectName then
		local n = obj:getObjectName()
		if n and n ~= "" and n ~= "IsoObject" then return n end
	end
	local sprite = obj.getSprite and obj:getSprite() or nil
	local props = sprite and sprite.getProperties and sprite:getProperties() or nil
	if props and props.Val then
		local ok, v = pcall(function() return props:Val("CustomName") end)
		if ok and v and v ~= "" then return v end
	end
	-- Final fallback aligns with vanilla tooltip wording
	return getText and getText("ContextMenu_NaturalWaterSource") or label
end

-- Internal: detect if a grid square is a natural water tile (lake/river/puddle)
local function isNaturalWaterSquare(sq)
	if not sq then return false end
	local props = sq.getProperties and sq:getProperties() or nil
	if props and IsoFlagType and props.Is and props:Is(IsoFlagType.water) then
		return true
	end
	local spr = sq.getSprite and sq:getSprite() or nil
	local sprProps = spr and spr.getProperties and spr:getProperties() or nil
	if sprProps and IsoFlagType and sprProps.Is and sprProps:Is(IsoFlagType.water) then
		return true
	end
	return false
end

-- Internal: safe taint check on objects; defaults to false if unsupported
local function isObjectTainted(obj)
	if not obj then return false end
	if not obj.isTaintedWater then return false end
	local ok, tainted = pcall(function() return obj:isTaintedWater() end)
	return ok and tainted == true
end

-- Internal scanner: iterate adjacent squares (including current) and evaluate objects
local function scanAdjacent(playerSq, evaluator)
	local cell = getCell()
	if not cell or not playerSq then return nil, nil end
	local x0, y0, z0 = playerSq:getX(), playerSq:getY(), playerSq:getZ()

	local bestRec, bestScore = nil, -1
	local naturalRec = nil

	for dx = -1, 1 do
		for dy = -1, 1 do
			local sq = cell:getGridSquare(x0 + dx, y0 + dy, z0)
			if sq and isAdjacentTo(playerSq, sq) then
				-- Objects pass through the provided evaluator
				local objects = sq.getObjects and sq:getObjects() or nil
				if objects then
					for i = 0, objects:size() - 1 do
						local obj = objects:get(i)
						local rec, score = evaluator(obj, sq)
						if rec and score and score > bestScore then
							bestRec, bestScore = rec, score
						end
					end
				end
				-- Track first natural water tile as a fallback
				if not naturalRec and isNaturalWaterSquare(sq) then
					naturalRec = { kind = "natural", square = sq, label = getText and getText("ContextMenu_NaturalWaterSource") or "Natural Water" }
				end
			end
		end
	end

	return bestRec, naturalRec
end

-- NEW API: Simplified two-function surface
-- 1) detectWaterNearby(player): find best adjacent water source of any kind
--    Prefers objects that explicitly support washing (hasWater), then any fluid-bearing object (hasFluid),
--    with a natural-water tile as a final fallback.
--    Returns a record with capability flags so call sites can decide how to use it.
-- 2) isSourceTainted(sourceRecord): determine taint; objects use isTaintedWater(); natural defaults to true.

function WaterDetection.detectWaterNearby(player)
	if not player or not player.getSquare then return nil end
	local playerSq = player:getSquare()
	if not playerSq then return nil end

	local function evaluator(obj, sq)
		if not obj then return nil, nil end
		local supportsWash = (obj.hasWater ~= nil)
		local supportsFluid = (obj.hasFluid ~= nil)
		if not (supportsWash or supportsFluid) or not (obj.getFluidAmount and obj.getSquare) then return nil, nil end
		local okAmt, amt = pcall(function() return obj:getFluidAmount() end)
		if not okAmt then return nil, nil end
		amt = amt or 0
		if amt <= 0 then return nil, nil end
		-- Prefer wash-capable objects by boosting their score slightly
		local score = amt + (supportsWash and 1000 or 0)
		local rec = {
			kind = "object",
			object = obj,
			square = sq,
			amount = amt,
			label = classifyWaterObject(obj),
			supportsWash = supportsWash,
			supportsFluid = supportsFluid,
		}
		return rec, score
	end

	local bestRec, naturalRec = scanAdjacent(playerSq, evaluator)
	return bestRec or naturalRec
end

function WaterDetection.isSourceTainted(source)
	if not source then return false end
	if source.kind == "object" and source.object then
		if source.object.isTaintedWater then
			local ok, tainted = pcall(function() return source.object:isTaintedWater() end)
			if ok then return tainted == true end
		end
		return false
	end
	-- Natural water tiles are considered tainted by default
	return true
end

-- Find a nearby water source suitable for washing clothes/self.
-- Prefers adjacent objects that report hasWater() and have fluid available.
function WaterDetection.findWashSource(player)
	if not player or not player.getSquare then return nil end
	local playerSq = player:getSquare()
	if not playerSq then return nil end

	local function evaluator(obj, sq)
		if not obj then return nil, nil end
		if not (obj.hasWater and obj.getFluidAmount and obj.getSquare) then return nil, nil end
		local ok1, has = pcall(function() return obj:hasWater() end)
		local ok2, amt = pcall(function() return obj:getFluidAmount() end)
		if not (ok1 and ok2) then return nil, nil end
		if not has then return nil, nil end
		amt = amt or 0
		if amt <= 0 then return nil, nil end
		local rec = { kind = "object", object = obj, square = sq, amount = amt, label = classifyWaterObject(obj) }
		return rec, amt -- score by available amount
	end

	local bestRec, naturalRec = scanAdjacent(playerSq, evaluator)
	-- Washing actions in vanilla expect an object; return natural as informational fallback only
	return bestRec or naturalRec
end

-- Find a nearby water source suitable for drinking/filling.
-- Prefers adjacent objects that report hasFluid() and have fluid available.
-- Falls back to a natural water tile record if no object is found.
function WaterDetection.findDrinkSource(player)
	if not player or not player.getSquare then return nil end
	local playerSq = player:getSquare()
	if not playerSq then return nil end

	local function evaluator(obj, sq)
		if not obj then return nil, nil end
		if not (obj.hasFluid and obj.getFluidAmount and obj.getSquare) then return nil, nil end
		local ok1, has = pcall(function() return obj:hasFluid() end)
		local ok2, amt = pcall(function() return obj:getFluidAmount() end)
		if not (ok1 and ok2) then return nil, nil end
		if not has then return nil, nil end
		amt = amt or 0
		if amt <= 0 then return nil, nil end
		local rec = { kind = "object", object = obj, square = sq, amount = amt, label = classifyWaterObject(obj) }
		return rec, amt -- score by available amount
	end

	local bestRec, naturalRec = scanAdjacent(playerSq, evaluator)
	return bestRec or naturalRec
end

-- Find a nearby NON-TAINTED, drainable object source suitable for drinking/filling.
-- Excludes natural tiles and any object reporting tainted water.
function WaterDetection.findNonTaintedSource(player)
	if not player or not player.getSquare then return nil end
	local playerSq = player:getSquare()
	if not playerSq then return nil end

	local function evaluator(obj, sq)
		if not obj then return nil, nil end
		if not (obj.hasFluid and obj.getFluidAmount and obj.getSquare) then return nil, nil end
		local okHas, has = pcall(function() return obj:hasFluid() end)
		local okAmt, amt = pcall(function() return obj:getFluidAmount() end)
		if not (okHas and okAmt) or not has then return nil, nil end
		amt = amt or 0
		if amt <= 0 then return nil, nil end
		if isObjectTainted(obj) then return nil, nil end
		local rec = { kind = "object", object = obj, square = sq, amount = amt, label = classifyWaterObject(obj) }
		return rec, amt
	end

	local bestRec = select(1, scanAdjacent(playerSq, evaluator))
	return bestRec
end

-- Find a nearby TAINTED source suitable for cleaning (bandages/clothes).
-- Prefers tainted object sources; falls back to natural water tiles when no tainted object nearby.
function WaterDetection.findTaintedCleaningSource(player)
	if not player or not player.getSquare then return nil end
	local playerSq = player:getSquare()
	if not playerSq then return nil end

	local function evaluator(obj, sq)
		if not obj then return nil, nil end
		-- Accept both hasWater (wash gating) and hasFluid (general) but require tainted
		local supportsWater = obj.hasWater ~= nil
		local supportsFluid = obj.hasFluid ~= nil
		if not (supportsWater or supportsFluid) or not (obj.getFluidAmount and obj.getSquare) then return nil, nil end
		local okAmt, amt = pcall(function() return obj:getFluidAmount() end)
		if not okAmt then return nil, nil end
		amt = amt or 0
		if amt <= 0 then return nil, nil end
		if not isObjectTainted(obj) then return nil, nil end
		-- If both APIs exist, optionally ensure hasWater() for wash flows
		if supportsWater then
			local okHas, has = pcall(function() return obj:hasWater() end)
			if not (okHas and has) then return nil, nil end
		end
		local rec = { kind = "object", object = obj, square = sq, amount = amt, label = classifyWaterObject(obj) }
		return rec, amt
	end

	local bestRec, naturalRec = scanAdjacent(playerSq, evaluator)
	-- If no tainted object found, prefer natural water tile for cleaning fallback
	return bestRec or naturalRec
end

return WaterDetection


