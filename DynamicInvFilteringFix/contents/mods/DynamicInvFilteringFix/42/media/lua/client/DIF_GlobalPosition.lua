-- Dynamic Inventory Filtering Fix: render DIF toolbar as a global overlay and position above title bar
require 'ISUI/ISInventoryPage'
local DIF = require 'DIF_Panel'
local CFG = require 'DIF_Config'
local PanelClass = DIF.PanelClass

local _orig_create = ISInventoryPage.createChildren
function ISInventoryPage:createChildren()
	_orig_create(self)
	if not self.difPanel then
		self.difPanel = PanelClass:new(self)
		self.difPanel.isGlobal = true
		self.difPanel:initialise()
		self.difPanel:setAlwaysOnTop(true)
		self.difPanel:show()
		self.inventoryPane.filterPanel = self.difPanel
		self.difPanel:setCategoriesFromPane(self.inventoryPane)
	end
end

local _orig_prerender = ISInventoryPage.prerender
function ISInventoryPage:prerender()
	_orig_prerender(self)
	if not self.difPanel then return end

	local reserve = (CFG and CFG.BAR_RESERVED_WIDTH) or 280
	local wantX = self.transferAll and (self.transferAll:getX() - reserve - 20) or self.inventoryPane:getX()
	local wantY = self.transferAll and (self.transferAll:getY() - 30) or (self.inventoryPane:getY() - 24 - 30)
	local ax, ay = self:getAbsoluteX(), self:getAbsoluteY()

	self.difPanel:setX(ax + wantX)
	self.difPanel:setY(ay + wantY)
	self.difPanel:bringToTop()
end
