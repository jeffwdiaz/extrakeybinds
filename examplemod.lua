local P4HasBeenRead = {}

P4HasBeenRead.doNotAutoMark = false

P4HasBeenRead.textureBookNR = getTexture("media/ui/P4HasBeenRead_Book_NR.png")
P4HasBeenRead.textureBookNC = getTexture("media/ui/P4HasBeenRead_Book_NC.png")
P4HasBeenRead.textureBookAR = getTexture("media/ui/P4HasBeenRead_Book_AR.png")
P4HasBeenRead.textureBookSM = getTexture("media/ui/P4HasBeenRead_Book_SM.png")
P4HasBeenRead.textureBookCT = getTexture("media/ui/P4HasBeenRead_Book_CT.png")

P4HasBeenRead.notReadTexture = P4HasBeenRead.textureBookNR
P4HasBeenRead.notCompletedTexture = P4HasBeenRead.textureBookNC
P4HasBeenRead.alreadyReadTexture = nil
P4HasBeenRead.selfMarkingTexture = P4HasBeenRead.textureBookSM
P4HasBeenRead.currentTargetTexture = P4HasBeenRead.textureBookCT

P4HasBeenRead.Messages_ToDoAutoMark = getText("UI_P4HasBeenRead_Messages_ToDoAutoMark")
P4HasBeenRead.Messages_ToDoNotAutoMark = getText("UI_P4HasBeenRead_Messages_ToDoNotAutoMark")
P4HasBeenRead.ContextMenu_ToDoAutoMark = getText("ContextMenu_P4HasBeenRead_ToDoAutoMark")
P4HasBeenRead.ContextMenu_ToDoNotAutoMark = getText("ContextMenu_P4HasBeenRead_ToDoNotAutoMark")

P4HasBeenRead.recordedMediaResult = {}
P4HasBeenRead.sharedModData = {}
P4HasBeenRead.playerModData = {}

P4HasBeenRead.status = nil
P4HasBeenRead.marking = nil
P4HasBeenRead.current = nil

-- *****************************************************************************
-- * Options
-- *****************************************************************************

P4HasBeenRead.options = {
	ShowNR = nil,
	ShowNC = nil,
	ShowAR = nil,
	ShowNCasNR = nil,
	ShowSM = nil,
	ShowCT = nil,
	EnableMap = nil,
	EnableFlier = nil,
	EnableBrochure = nil,
	EnableTitled = nil,
	EnableCD = nil,
	EnableVHS = nil,
	EnableHVHS = nil,
	AutoMark = nil,
	ReverseMarkDisplay = nil,
	ShareFlier = nil,
	ShareBrochure = nil,
	ShareTitled = nil,
	ShareMarking = nil,
}

P4HasBeenRead.initOption = function()
	local options = PZAPI.ModOptions:create("P4HasBeenRead", "Has Been Read")
	P4HasBeenRead.options.ShowNR = options:addTickBox("ShowNR", getText("UI_P4HasBeenRead_Options_ShowNR_Name"), true, getText("UI_P4HasBeenRead_Options_ShowNR_Tooltip"))
	P4HasBeenRead.options.ShowNC = options:addTickBox("ShowNC", getText("UI_P4HasBeenRead_Options_ShowNC_Name"), true, getText("UI_P4HasBeenRead_Options_ShowNC_Tooltip"))
	P4HasBeenRead.options.ShowAR = options:addTickBox("ShowAR", getText("UI_P4HasBeenRead_Options_ShowAR_Name"), false, getText("UI_P4HasBeenRead_Options_ShowAR_Tooltip"))
	P4HasBeenRead.options.ShowNCasNR = options:addTickBox("ShowNCasNR", getText("UI_P4HasBeenRead_Options_ShowNCasNR_Name"), false, getText("UI_P4HasBeenRead_Options_ShowNCasNR_Tooltip"))
	P4HasBeenRead.options.ShowSM = options:addTickBox("ShowSM", getText("UI_P4HasBeenRead_Options_ShowSM_Name"), true, getText("UI_P4HasBeenRead_Options_ShowSM_Tooltip"))
	P4HasBeenRead.options.ShowCT = options:addTickBox("ShowCT", getText("UI_P4HasBeenRead_Options_ShowCT_Name"), true, getText("UI_P4HasBeenRead_Options_ShowCT_Tooltip"))
	P4HasBeenRead.options.EnableMap = options:addTickBox("EnableMap", getText("UI_P4HasBeenRead_Options_EnableMap_Name"), true, getText("UI_P4HasBeenRead_Options_EnableMap_Tooltip"))
	P4HasBeenRead.options.EnableFlier = options:addTickBox("EnableFlier", getText("UI_P4HasBeenRead_Options_EnableFlier_Name"), true, getText("UI_P4HasBeenRead_Options_EnableFlier_Tooltip"))
	P4HasBeenRead.options.EnableBrochure = options:addTickBox("EnableBrochure", getText("UI_P4HasBeenRead_Options_EnableBrochure_Name"), true, getText("UI_P4HasBeenRead_Options_EnableBrochure_Tooltip"))
	P4HasBeenRead.options.EnableTitled = options:addTickBox("EnableTitled", getText("UI_P4HasBeenRead_Options_EnableTitled_Name"), true, getText("UI_P4HasBeenRead_Options_EnableTitled_Tooltip"))
	P4HasBeenRead.options.EnableCD = options:addTickBox("EnableCD", getText("UI_P4HasBeenRead_Options_EnableCD_Name"), true, getText("UI_P4HasBeenRead_Options_EnableCD_Tooltip"))
	P4HasBeenRead.options.EnableVHS = options:addTickBox("EnableVHS", getText("UI_P4HasBeenRead_Options_EnableVHS_Name"), true, getText("UI_P4HasBeenRead_Options_EnableVHS_Tooltip"))
	P4HasBeenRead.options.EnableHVHS = options:addTickBox("EnableHVHS", getText("UI_P4HasBeenRead_Options_EnableHVHS_Name"), true, getText("UI_P4HasBeenRead_Options_EnableHVHS_Tooltip"))
	P4HasBeenRead.options.AutoMark = options:addTickBox("AutoMark", getText("UI_P4HasBeenRead_Options_AutoMark_Name"), false, getText("UI_P4HasBeenRead_Options_AutoMark_Tooltip"))
	P4HasBeenRead.options.ReverseMarkDisplay = options:addTickBox("ReverseMarkDisplay", getText("UI_P4HasBeenRead_Options_ReverseMarkDisplay_Name"), false, getText("UI_P4HasBeenRead_Options_ReverseMarkDisplay_Tooltip"))
	P4HasBeenRead.options.ShareFlier = options:addTickBox("ShareFlier", getText("UI_P4HasBeenRead_Options_ShareFlier_Name"), false, getText("UI_P4HasBeenRead_Options_ShareFlier_Tooltip"))
	P4HasBeenRead.options.ShareBrochure = options:addTickBox("ShareBrochure", getText("UI_P4HasBeenRead_Options_ShareBrochure_Name"), false, getText("UI_P4HasBeenRead_Options_ShareBrochure_Tooltip"))
	P4HasBeenRead.options.ShareTitled = options:addTickBox("ShareTitled", getText("UI_P4HasBeenRead_Options_ShareTitled_Name"), false, getText("UI_P4HasBeenRead_Options_ShareTitled_Tooltip"))
	P4HasBeenRead.options.ShareMarking = options:addTickBox("ShareMarking", getText("UI_P4HasBeenRead_Options_ShareMarking_Name"), false, getText("UI_P4HasBeenRead_Options_ShareMarking_Tooltip"))
end
P4HasBeenRead.initOption()

-- *****************************************************************************
-- * ModData functions
-- *****************************************************************************

P4HasBeenRead.initModOptions = function()
	-- SharedModData
	local sharedModData = ModData.getOrCreate("P4HasBeenRead")
	if not sharedModData.readMap then
		sharedModData.readMap = {}
	end
	if not sharedModData.markedMap then
		sharedModData.markedMap = {}
	end
	P4HasBeenRead.sharedModData = sharedModData

	-- PlayerModData
	local playerModData = getPlayer():getModData()
	if not playerModData.P4HasBeenRead then
		playerModData.P4HasBeenRead = {}
		playerModData.P4HasBeenRead.doNotAutoMark = false
	end
	if not playerModData.readMap then
		playerModData.readMap = {}
	end
	if not playerModData.markedMap then
		playerModData.markedMap = {}
	end
	P4HasBeenRead.playerModData = playerModData
	P4HasBeenRead.doNotAutoMark = playerModData.P4HasBeenRead.doNotAutoMark
end

P4HasBeenRead.read = function(type)
	P4HasBeenRead.sharedModData.readMap[type] = true
	P4HasBeenRead.playerModData.readMap[type] = true
end

P4HasBeenRead.marked = function(type)
	P4HasBeenRead.sharedModData.markedMap[type] = true
	P4HasBeenRead.playerModData.markedMap[type] = true
end

P4HasBeenRead.markedAll = function(types)
	for i,v in ipairs(types) do
		P4HasBeenRead.marked(v)
	end
end

P4HasBeenRead.unmarked = function(type)
	P4HasBeenRead.sharedModData.markedMap[type] = nil
	P4HasBeenRead.playerModData.markedMap[type] = nil
end

P4HasBeenRead.unmarkedAll = function(types)
	for i,v in ipairs(types) do
		P4HasBeenRead.unmarked(v)
	end
end

P4HasBeenRead.toggleDoNotAutoMark = function()
	local modData = getPlayer():getModData()
	modData.P4HasBeenRead.doNotAutoMark = not modData.P4HasBeenRead.doNotAutoMark
	P4HasBeenRead.doNotAutoMark = modData.P4HasBeenRead.doNotAutoMark
	if P4HasBeenRead.doNotAutoMark then
		P4HasBeenRead.showInfo(P4HasBeenRead.Messages_ToDoNotAutoMark)
	else
		P4HasBeenRead.showInfo(P4HasBeenRead.Messages_ToDoAutoMark)
	end
end

-- *****************************************************************************
-- * Event trigger functions
-- *****************************************************************************

P4HasBeenRead.OnLoad = function()
	P4HasBeenRead.loadFunctions()
end
Events.OnLoad.Add(P4HasBeenRead.OnLoad)

P4HasBeenRead.OnCreatePlayer = function(playerIndex, player)
	P4HasBeenRead.initModOptions()
end
Events.OnCreatePlayer.Add(P4HasBeenRead.OnCreatePlayer)

P4HasBeenRead.initTextures = function()
	P4HasBeenRead.notReadTexture = nil
	if P4HasBeenRead.options.ShowNR.value then
		P4HasBeenRead.notReadTexture = P4HasBeenRead.textureBookNR
	end
	P4HasBeenRead.notCompletedTexture = nil
	if P4HasBeenRead.options.ShowNC.value then
		if P4HasBeenRead.options.ShowNCasNR.value then
			P4HasBeenRead.notCompletedTexture = P4HasBeenRead.textureBookNR
		else
			P4HasBeenRead.notCompletedTexture = P4HasBeenRead.textureBookNC
		end
	end
	P4HasBeenRead.alreadyReadTexture = nil
	if P4HasBeenRead.options.ShowAR.value then
		P4HasBeenRead.alreadyReadTexture = P4HasBeenRead.textureBookAR
	end
	P4HasBeenRead.selfMarkingTexture = nil
	if P4HasBeenRead.options.ShowSM.value then
		P4HasBeenRead.selfMarkingTexture = P4HasBeenRead.textureBookSM
	end
	P4HasBeenRead.currentTargetTexture = nil
	if P4HasBeenRead.options.ShowCT.value then
		P4HasBeenRead.currentTargetTexture = P4HasBeenRead.textureBookCT
	end
end
Events.OnGameStart.Add(P4HasBeenRead.initTextures)

P4HasBeenRead.OnFillInventoryObjectContextMenu = function(player, contextMenu, items)
	if P4HasBeenRead.options.ShowSM.value then
		local markedMap = P4HasBeenRead.playerModData.markedMap
		if P4HasBeenRead.options.ShareMarking.value then
			markedMap = P4HasBeenRead.sharedModData.markedMap
		end
		if #items == 1 then
			local item = nil
			if not instanceof(items[1], "InventoryItem") then
				item = items[1].items[1]
			else
				item = items[1]
			end
			local type = P4HasBeenRead.getFullType(item)
			local category = item:getCategory()
			if category == "Literature" then
				if P4HasBeenRead.isTargetLiterature(item) then
					if markedMap[type] then
						local menuText = "UI_P4HasBeenRead_Unmarked_Book"
						if item:getFullType() == "Base.Flier" then
							menuText = "UI_P4HasBeenRead_Unmarked_Flier"
						elseif item:getFullType() == "Base.Brochure" then
							menuText = "UI_P4HasBeenRead_Unmarked_Brochure"
						end
						if P4HasBeenRead.options.ReverseMarkDisplay.value then
							menuText = "UI_P4HasBeenRead_Marked_Book"
							if item:getFullType() == "Base.Flier" then
								menuText = "UI_P4HasBeenRead_Marked_Flier"
							elseif item:getFullType() == "Base.Brochure" then
								menuText = "UI_P4HasBeenRead_Marked_Brochure"
							end
						end
						contextMenu:addOption(getText(menuText), type, P4HasBeenRead.unmarked)
					else
						local menuText = "UI_P4HasBeenRead_Marked_Book"
						if item:getFullType() == "Base.Flier" then
							menuText = "UI_P4HasBeenRead_Marked_Flier"
						elseif item:getFullType() == "Base.Brochure" then
							menuText = "UI_P4HasBeenRead_Marked_Brochure"
						end
						if P4HasBeenRead.options.ReverseMarkDisplay.value then
							menuText = "UI_P4HasBeenRead_Unmarked_Book"
							if item:getFullType() == "Base.Flier" then
								menuText = "UI_P4HasBeenRead_Unmarked_Flier"
							elseif item:getFullType() == "Base.Brochure" then
								menuText = "UI_P4HasBeenRead_Unmarked_Brochure"
							end
						end
						contextMenu:addOption(getText(menuText), type, P4HasBeenRead.marked)
					end
				end
			elseif instanceof(item, "MapItem") then
				type = item:getMapID()
				if type then
					if markedMap[type] then
						local menuText = "UI_P4HasBeenRead_Unmarked_Map"
						if P4HasBeenRead.options.ReverseMarkDisplay.value then
							menuText = "UI_P4HasBeenRead_Marked_Map"
						end
						contextMenu:addOption(getText(menuText), type, P4HasBeenRead.unmarked)
					else
						local menuText = "UI_P4HasBeenRead_Marked_Map"
						if P4HasBeenRead.options.ReverseMarkDisplay.value then
							menuText = "UI_P4HasBeenRead_Unmarked_Map"
						end
						contextMenu:addOption(getText(menuText), type, P4HasBeenRead.marked)
					end
				end
			elseif type == "Base.Disc_Retail" then
				type = "Base.RM-" .. item:getMediaData():getIndex()
				if markedMap[type] then
					local menuText = "UI_P4HasBeenRead_Unmarked_CD"
					if P4HasBeenRead.options.ReverseMarkDisplay.value then
						menuText = "UI_P4HasBeenRead_Marked_CD"
					end
					contextMenu:addOption(getText(menuText), type, P4HasBeenRead.unmarked)
				else
					local menuText = "UI_P4HasBeenRead_Marked_CD"
					if P4HasBeenRead.options.ReverseMarkDisplay.value then
						menuText = "UI_P4HasBeenRead_Unmarked_CD"
					end
					contextMenu:addOption(getText(menuText), type, P4HasBeenRead.marked)
				end
			elseif type == "Base.VHS_Retail" or type == "Base.VHS_Home" then
				type = "Base.RM-" .. item:getMediaData():getIndex()
				if markedMap[type] then
					local menuText = "UI_P4HasBeenRead_Unmarked_VHS"
					if P4HasBeenRead.options.ReverseMarkDisplay.value then
						menuText = "UI_P4HasBeenRead_Marked_VHS"
					end
					contextMenu:addOption(getText(menuText), type, P4HasBeenRead.unmarked)
				else
					local menuText = "UI_P4HasBeenRead_Marked_VHS"
					if P4HasBeenRead.options.ReverseMarkDisplay.value then
						menuText = "UI_P4HasBeenRead_Unmarked_VHS"
					end
					contextMenu:addOption(getText(menuText), type, P4HasBeenRead.marked)
				end
			end
		else
			local types = {}
			for i,v in ipairs(items) do
				local item = nil
				if not instanceof(v, "InventoryItem") then
					item = v.items[1]
				else
					item = v
				end
				local type = P4HasBeenRead.getFullType(item)
				local category = item:getCategory()
				if category == "Literature" then
					if P4HasBeenRead.isTargetLiterature(item) then
						table.insert(types, type)
					end
				elseif instanceof(item, "MapItem") then
					type = item:getMapID()
					if type then
						table.insert(types, type)
					end
				elseif type == "Base.Disc_Retail" then
					type = "Base.RM-" .. item:getMediaData():getIndex()
					table.insert(types, type)
				elseif type == "Base.VHS_Retail" or type == "Base.VHS_Home" then
					type = "Base.RM-" .. item:getMediaData():getIndex()
					table.insert(types, type)
				end
			end
			if #types > 0 then
				if P4HasBeenRead.options.ReverseMarkDisplay.value then
					contextMenu:addOption(getText("UI_P4HasBeenRead_Marked_ALL"), types, P4HasBeenRead.unmarkedAll)
					contextMenu:addOption(getText("UI_P4HasBeenRead_Unmarked_ALL"), types, P4HasBeenRead.markedAll)
				else
					contextMenu:addOption(getText("UI_P4HasBeenRead_Marked_ALL"), types, P4HasBeenRead.markedAll)
					contextMenu:addOption(getText("UI_P4HasBeenRead_Unmarked_ALL"), types, P4HasBeenRead.unmarkedAll)
				end
			end
		end
	end
end
Events.OnFillInventoryObjectContextMenu.Add(P4HasBeenRead.OnFillInventoryObjectContextMenu)

P4HasBeenRead.OnFillWorldObjectContextMenu = function(player, context, worldObjects, test)
	if P4HasBeenRead.options.ShowSM.value and P4HasBeenRead.options.AutoMark.value then
		if P4HasBeenRead.doNotAutoMark then
			context:addOption(P4HasBeenRead.ContextMenu_ToDoAutoMark, nil, P4HasBeenRead.toggleDoNotAutoMark)
		else
			context:addOption(P4HasBeenRead.ContextMenu_ToDoNotAutoMark, nil, P4HasBeenRead.toggleDoNotAutoMark)
		end
	end
end
Events.OnFillWorldObjectContextMenu.Add(P4HasBeenRead.OnFillWorldObjectContextMenu)

-- *****************************************************************************
-- * Overwrite functions
-- *****************************************************************************

P4HasBeenRead.MainOptions_apply = MainOptions.apply
function MainOptions:apply(closeAfter)
	P4HasBeenRead.MainOptions_apply(self, closeAfter)
	P4HasBeenRead.initTextures()
end

P4HasBeenRead.ISInventoryPaneContextMenu_onCheckMap = ISInventoryPaneContextMenu.onCheckMap
function ISInventoryPaneContextMenu.onCheckMap(map, player)
	P4HasBeenRead.ISInventoryPaneContextMenu_onCheckMap(map, player)
	local mapId = map:getMapID()
	if mapId then
		P4HasBeenRead.read(mapId)
	end
end

P4HasBeenRead.ISReadABook_perform = ISReadABook.perform
function ISReadABook:perform()
	P4HasBeenRead.ISReadABook_perform(self)
	if P4HasBeenRead.isTargetLiterature(self.item) then
		local modData = self.item:getModData()
		if modData.literatureTitle then
			P4HasBeenRead.read(modData.literatureTitle)
		elseif modData.printMedia then
			P4HasBeenRead.read(modData.printMedia)
		end
	end
end

P4HasBeenRead.ISInventoryTransferAction_perform = ISInventoryTransferAction.perform
function ISInventoryTransferAction:perform()
	-- Auto mark if needed
	if P4HasBeenRead.options.ShowSM.value and P4HasBeenRead.options.AutoMark.value and not P4HasBeenRead.doNotAutoMark then
		local inventory = self.character:getInventory()
		local needsMark = false
		if inventory == self.destContainer then
			needsMark = true
		else
			local containingItem = self.destContainer:getContainingItem()
			if containingItem and inventory:containsRecursive(containingItem) then
				needsMark = true
			end
		end
		if needsMark then
			local type = P4HasBeenRead.getFullType(self.item)
			local category = self.item:getCategory()
			local isMarkable = false
			if category == "Literature" then
				if P4HasBeenRead.isTargetLiterature(self.item) then
					isMarkable = true
				end
			elseif instanceof(self.item, "MapItem") then
				type = self.item:getMapID()
				if type then
					isMarkable = true
				end
			elseif type == "Base.Disc_Retail" or type == "Base.VHS_Retail" or type == "Base.VHS_Home" then
				type = "Base.RM-" .. self.item:getMediaData():getIndex()
				isMarkable = true
			end
			if isMarkable then
				P4HasBeenRead.marked(type)
			end
		end
	end
	-- Original function call
	P4HasBeenRead.ISInventoryTransferAction_perform(self)
end

-- *****************************************************************************
-- * For Compatible functions
-- *****************************************************************************

P4HasBeenRead.loadFunctions = function()
	-- Inventory Tetris
	if TetrisEvents then
		P4HasBeenRead.InventoryTetris = {}
		P4HasBeenRead.InventoryTetris.options = require "InventoryTetris/Settings"

		function P4HasBeenRead.InventoryTetris.call(eventData, drawingContext, renderInstructions, instructionCount, playerObj)
			for i = 1, instructionCount do
				local instruction = renderInstructions[i]
				local hidden = instruction[9]
				if not hidden then
					local item = instruction[2]
					local x = instruction[3]
					local y = instruction[4]
					local h = instruction[6]
					P4HasBeenRead.setTextures(playerObj, item)
					if P4HasBeenRead.status or P4HasBeenRead.marking or P4HasBeenRead.current then
						local yoff = P4HasBeenRead.InventoryTetris.options.CELL_SIZE * h
						local alphaMult = instruction[7]
						if P4HasBeenRead.status then
							drawingContext.javaObject:DrawTexture(P4HasBeenRead.status, x+2, y+yoff-19, alphaMult)
						end
						if P4HasBeenRead.marking then
							drawingContext.javaObject:DrawTexture(P4HasBeenRead.marking, x+12, y+yoff-13, alphaMult)
						end
						if P4HasBeenRead.current then
							drawingContext.javaObject:DrawTexture(P4HasBeenRead.current, x+1, y+yoff-31, alphaMult)
						end
					end
				end
			end
		end
		TetrisEvents.OnPostRenderGrid:add(P4HasBeenRead.InventoryTetris)
	end
end

-- *****************************************************************************
-- * Main functions
-- *****************************************************************************

P4HasBeenRead.setTextures = function(player, item)
	local type = P4HasBeenRead.getFullType(item)

	local recordedMedia = getZomboidRadio():getRecordedMedia()
	local readMap = P4HasBeenRead.playerModData.readMap
	local markedMap = P4HasBeenRead.playerModData.markedMap
	if P4HasBeenRead.options.ShareMarking.value then
		markedMap = P4HasBeenRead.sharedModData.markedMap
	end

	local statusTexture = nil
	local selfMarkingTexture = nil
	local currentTargetTexture = nil
	if item:getCategory() == "Literature" then
		if P4HasBeenRead.isTargetLiterature(item) then
			local skillBook = SkillBook[item:getSkillTrained()]
			if skillBook then
				local perkLevel = player:getPerkLevel(skillBook.perk)
				local minLevel = item:getLvlSkillTrained()
				local maxLevel = item:getMaxLevelTrained()
				if (minLevel <= perkLevel + 1) and (perkLevel + 1 <= maxLevel) then
					currentTargetTexture = P4HasBeenRead.currentTargetTexture
				end
				local readPages = player:getAlreadyReadPages(item:getFullType())
				if readPages >= item:getNumberOfPages() then
					statusTexture = P4HasBeenRead.alreadyReadTexture
				elseif perkLevel >= maxLevel then
					statusTexture = P4HasBeenRead.alreadyReadTexture
				elseif readPages > 0 then
					statusTexture = P4HasBeenRead.notCompletedTexture
				else
					statusTexture = P4HasBeenRead.notReadTexture
				end
			elseif item:getTeachedRecipes() and not item:getTeachedRecipes():isEmpty() then
				if player:getKnownRecipes():containsAll(item:getTeachedRecipes()) then
					statusTexture = P4HasBeenRead.alreadyReadTexture
				else
					statusTexture = P4HasBeenRead.notReadTexture
				end
			elseif P4HasBeenRead.options.EnableFlier.value and item:getFullType() == "Base.Flier" then
				if P4HasBeenRead.options.ShareFlier.value then
					readMap = P4HasBeenRead.sharedModData.readMap
				end
				if readMap[type] then
					statusTexture = P4HasBeenRead.alreadyReadTexture
				else
					statusTexture = P4HasBeenRead.notReadTexture
				end
			elseif P4HasBeenRead.options.EnableBrochure.value and item:getFullType() == "Base.Brochure" then
				if P4HasBeenRead.options.ShareBrochure.value then
					readMap = P4HasBeenRead.sharedModData.readMap
				end
				if readMap[type] then
					statusTexture = P4HasBeenRead.alreadyReadTexture
				else
					statusTexture = P4HasBeenRead.notReadTexture
				end
			elseif P4HasBeenRead.options.EnableTitled.value then
				if P4HasBeenRead.options.ShareTitled.value then
					readMap = P4HasBeenRead.sharedModData.readMap
				end
				if readMap[type] then
					statusTexture = P4HasBeenRead.alreadyReadTexture
				else
					statusTexture = P4HasBeenRead.notReadTexture
				end
			end
			if P4HasBeenRead.options.ShowSM.value then
				if markedMap[type] then
					if not P4HasBeenRead.options.ReverseMarkDisplay.value then
						selfMarkingTexture = P4HasBeenRead.selfMarkingTexture
					end
				else
					if P4HasBeenRead.options.ReverseMarkDisplay.value then
						selfMarkingTexture = P4HasBeenRead.selfMarkingTexture
					end
				end
			end
		end
	elseif instanceof(item, "MapItem") then
		local mapId = item:getMapID()
		if mapId then
			if P4HasBeenRead.options.EnableMap.value then
				-- Map only access to SharedModData
				if P4HasBeenRead.sharedModData.readMap[mapId] then
					statusTexture = P4HasBeenRead.alreadyReadTexture
				else
					statusTexture = P4HasBeenRead.notReadTexture
				end
			end
			if P4HasBeenRead.options.ShowSM.value then
				if markedMap[mapId] then
					if not P4HasBeenRead.options.ReverseMarkDisplay.value then
						selfMarkingTexture = P4HasBeenRead.selfMarkingTexture
					end
				else
					if P4HasBeenRead.options.ReverseMarkDisplay.value then
						selfMarkingTexture = P4HasBeenRead.selfMarkingTexture
					end
				end
			end
		end
	elseif recordedMedia then
		local mediaData = item:getMediaData()
		if mediaData then
			local isTarget = false
			local index = mediaData:getIndex()
			local category = mediaData:getCategory()
			if P4HasBeenRead.options.EnableCD.value and category == "CDs" then
				isTarget = true
			elseif P4HasBeenRead.options.EnableVHS.value and category == "Retail-VHS" then
				isTarget = true
			elseif P4HasBeenRead.options.EnableHVHS.value and category == "Home-VHS" then
				isTarget = true
			end
			if isTarget then
				statusTexture = P4HasBeenRead.recordedMediaResult[index]
				if statusTexture then
					if statusTexture == "mynil" then
						statusTexture = nil
					end
				else
					if recordedMedia:hasListenedToAll(player, mediaData) then
						statusTexture = P4HasBeenRead.alreadyReadTexture
					else
						statusTexture = P4HasBeenRead.notReadTexture
					end
					if statusTexture then
						P4HasBeenRead.recordedMediaResult[index] = statusTexture
					else
						P4HasBeenRead.recordedMediaResult[index] = "mynil"
					end
				end
			end
			if P4HasBeenRead.options.ShowSM.value then
				if markedMap["Base.RM-" .. index] then
					if not P4HasBeenRead.options.ReverseMarkDisplay.value then
						selfMarkingTexture = P4HasBeenRead.selfMarkingTexture
					end
				else
					if P4HasBeenRead.options.ReverseMarkDisplay.value then
						selfMarkingTexture = P4HasBeenRead.selfMarkingTexture
					end
				end
			end
		end
	end
	P4HasBeenRead.status = statusTexture
	P4HasBeenRead.marking = selfMarkingTexture
	P4HasBeenRead.current = currentTargetTexture
end

P4HasBeenRead.ISInventoryPane_renderdetails = ISInventoryPane.renderdetails
function ISInventoryPane:renderdetails(doDragged)
	P4HasBeenRead.ISInventoryPane_renderdetails(self, doDragged)
	P4HasBeenRead.recordedMediaResult = {}

	-- [NOTICE]
	-- The source code below is the basicaly same as the vanilla code in Build 41.50.
	-- Due to changes in the vanilla code, it may not work properly.

	local player = getSpecificPlayer(self.player)
	local y = 0
	local MOUSEX = self:getMouseX()
	local MOUSEY = self:getMouseY()
	local YSCROLL = self:getYScroll()
	local HEIGHT = self:getHeight()
	for k, v in ipairs(self.itemslist) do
		local count = 1
		for k2, v2 in ipairs(v.items) do
			local item = v2
			P4HasBeenRead.setTextures(player, item)
			if P4HasBeenRead.status or P4HasBeenRead.marking or P4HasBeenRead.current then
				local doIt = true
				local xoff = 0
				local yoff = 0
				local isDragging = false
				if self.dragging ~= nil and self.selected[y+1] ~= nil and self.dragStarted then
					xoff = MOUSEX - self.draggingX
					yoff = MOUSEY - self.draggingY
					if not doDragged then
						doIt = false
					else
						isDragging = true
					end
				else
					if doDragged then
						doIt = false
					end
				end
				local topOfItem = y * self.itemHgt + YSCROLL
				if not isDragging and ((topOfItem + self.itemHgt < 0) or (topOfItem > HEIGHT)) then
					doIt = false
				end
				if doIt == true then
					local tex = item:getTex()
					if tex ~= nil then
						local texWH = math.min(self.itemHgt-2,32)
						if count == 1  then
							if P4HasBeenRead.status then
								self:drawTexture(P4HasBeenRead.status, xoff+5, (y*self.itemHgt)+self.headerHgt+yoff+texWH-16, 1, 1, 1, 1)
							end
							if P4HasBeenRead.marking then
								self:drawTexture(P4HasBeenRead.marking, xoff+15, (y*self.itemHgt)+self.headerHgt+yoff+texWH-10, 1, 1, 1, 1)
							end
							if P4HasBeenRead.current then
								self:drawTexture(P4HasBeenRead.current, xoff+4, (y*self.itemHgt)+self.headerHgt+yoff-3, 1, 1, 1, 1)
							end
						elseif v.count > 2 or (doDragged and count > 1 and self.selected[(y+1) - (count-1)] == nil) then
							if P4HasBeenRead.status then
								self:drawTexture(P4HasBeenRead.status, xoff+21, (y*self.itemHgt)+self.headerHgt+yoff+texWH-16, 0.3, 1, 1, 1)
							end
							if P4HasBeenRead.marking then
								self:drawTexture(P4HasBeenRead.marking, xoff+31, (y*self.itemHgt)+self.headerHgt+yoff+texWH-10, 0.3, 1, 1, 1)
							end
							if P4HasBeenRead.current then
								self:drawTexture(P4HasBeenRead.current, xoff+20, (y*self.itemHgt)+self.headerHgt+yoff-3, 0.3, 1, 1, 1)
							end
						end
					end
				end
			end
			y = y + 1
			if count == 1 and self.collapsed ~= nil and v.name ~= nil and self.collapsed[v.name] then
				break
			end
			if count == 51 then
				break
			end
			count = count + 1
		end
	end
end

P4HasBeenRead.isTargetLiterature = function(item)
	local isTarget = false
	local modData = item:getModData()
	if SkillBook[item:getSkillTrained()] then
		isTarget = true
	elseif item:getTeachedRecipes() and not item:getTeachedRecipes():isEmpty() then
		isTarget = true
	elseif item:getFullType() == "Base.Flier" or item:getFullType() == "Base.Brochure" then
		isTarget = true
	elseif modData then
		if modData.literatureTitle then
			isTarget = true
		elseif modData.printMedia then
			isTarget = true
		end
	end
	return isTarget
end

P4HasBeenRead.getFullType = function(item)
	local type = item:getFullType()
	local modData = item:getModData()
	if modData then
		if modData.literatureTitle then
			type = modData.literatureTitle
		elseif modData.printMedia then
			type = modData.printMedia
		end
	end
	return type
end

P4HasBeenRead.showInfo = function(message)
	getPlayer():Say(message, 0.607, 0.717, 1.000, UIFont.Dialogue, 15, "radio")
end
