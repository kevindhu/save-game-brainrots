local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local Unit = require(game.ServerScriptService.Unit)

local UnitManager = {}
UnitManager.__index = UnitManager

function UnitManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.units = {}

	setmetatable(u, UnitManager)
	return u
end

function UnitManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	routine(function()
		wait(1)
		if self.isNew then
			self:addTestUnits()
		end

		self.initialized = true
	end)
end

function UnitManager:tryStoreUnit(data)
	local unitName = data["unitName"]
	local unit = self.units[unitName]
	if not unit then
		return
	end

	self:storeUnit(unit)
end

function UnitManager:addTestUnits()
	if not Common.checkDeveloper(self.user.userId) then
		return
	end

	self:addUnit({
		unitClass = "Unit1",
	})
end

function UnitManager:tryClaimOfflineCoins(data)
	local boost = data["boost"]
	if self.claimedOfflineCoins then
		return
	end

	if boost then
		self.user.home.shopManager:tryBuyProduct({
			productClass = "OfflineCoinsClaimBoost",
		})
		return
	end

	self:claimOfflineCoins({
		boost = false,
	})
end

function UnitManager:claimOfflineCoins(data)
	local boost = data["boost"]

	self.claimedOfflineCoins = true

	local totalOfflineCoins = 0
	for _, unit in pairs(self.units) do
		totalOfflineCoins += unit.totalOfflineCoins
	end

	if boost then
		totalOfflineCoins = totalOfflineCoins * 10
	end

	-- print("CLAIMING OFFLINE COINS: ", totalOfflineCoins)

	self.user.home.itemStash:updateItemCount({
		itemName = "Coins",
		count = totalOfflineCoins,
	})

	-- clear all offline coins
	for _, unit in pairs(self.units) do
		unit.totalOfflineCoins = 0
		-- unit:sendData()
	end

	ServerMod:FireClient(self.user.player, "claimedOfflineCoins", {
		totalOfflineCoins = totalOfflineCoins,
	})
end

function UnitManager:tick(timeRatio)
	for _, unit in pairs(self.units) do
		unit:tick(timeRatio)
	end
end

function UnitManager:getRandomFrame()
	local plotManager = self.user.home.plotManager
	local floorPart = plotManager.floorPart

	local middleRatio = 0.8

	local xOffset = math.random(-floorPart.Size.X / 2 * middleRatio, floorPart.Size.X / 2 * middleRatio)
	local zOffset = math.random(-floorPart.Size.Z / 2 * middleRatio, floorPart.Size.Z / 2 * middleRatio)

	local hOffset = floorPart.Size.Y * 0.5
	local randomFrame = floorPart.CFrame
		* CFrame.new(xOffset, hOffset, zOffset)
		* CFrame.Angles(0, math.rad(math.random(0, 4) * 90), 0)

	return randomFrame
end

function UnitManager:addUnit(unitData)
	-- handle firstFrame
	if not unitData["firstFrame"] then
		unitData["firstFrame"] = self:getRandomFrame()
	end

	local unit = Unit.new(self, unitData)
	unit:init()
	self.units[unitData["unitName"]] = unit
end

function UnitManager:storeUnit(unit)
	self.user:notifySuccess(string.format("%s stored", unit.unitStats["alias"]))
	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "HammerHit",
		-- volume = 0.5,
	})

	local itemData = unit:getSaveData()

	-- TODO: do we need this?
	itemData["itemName"] = "STASHTOOL_" .. Common.getGUID()
	itemData["itemClass"] = itemData["unitClass"]
	itemData["race"] = "unit"
	itemData["noImmediateEquip"] = true

	self.user.home.itemStash:addItemMod(itemData)

	unit:destroy()
end

function UnitManager:sync(otherUser)
	for _, unit in pairs(self.units) do
		unit:sync(otherUser)
	end
end

function UnitManager:destroy()
	for _, unit in pairs(self.units) do
		unit:destroy()
	end
	self.units = {}
end

function UnitManager:saveState()
	local managerData = {}

	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

return UnitManager
