local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local Crate = require(game.ServerScriptService.Objects.Crate)

local CrateInfo = require(game.ReplicatedStorage.Data.CrateInfo)

local CrateManager = {}
CrateManager.__index = CrateManager

function CrateManager.new(user, data)
	local u = {}
	u.user = user
	u.data = data

	u.crates = {}
	u.shopStock = {}

	u.restockTime = 0

	setmetatable(u, CrateManager)
	return u
end

function CrateManager:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:sendStock()
end

function CrateManager:updateStock(scheduleMod)
	-- print("UPDATE CRATE STOCK: ", scheduleMod)

	local stock = scheduleMod.stock
	local restockTime = scheduleMod.restockTime

	-- cannot restock if its the same timestamp
	local timeDifference = restockTime - self.restockTime
	if timeDifference < 5 then
		-- print("SAME RESTOCK TIME: ", restockTime, self.restockTime)
		return
	end
	self.restockTime = restockTime
	self.shopStock = Common.deepCopy(stock)

	self:sendStock()
end

function CrateManager:tryBuyCrate(data)
	local crateClass = data["crateClass"]
	local withRobux = data["withRobux"]

	if withRobux then
		self.lastPremiumCrateClass = crateClass

		self.user.shopManager:tryBuyProduct({
			productClass = "Buy" .. crateClass,
		})
		return
	end

	local crateCount = self.shopStock[crateClass] or 0
	if crateCount <= 0 then
		self.user.notifyManager:notifyError("This crate is out of stock!")
		return
	end

	-- see if already have stashManager crate
	local stashCrateCount = 0

	local stashManager = self.user.stashManager
	for _, itemMod in pairs(stashManager.itemMods) do
		if itemMod["race"] ~= "crate" then
			continue
		end
		stashCrateCount += 1
	end

	-- if not Common.checkDeveloper(self.user.userId) then
	-- 	if not self.user.tutManager.completedTutMods["PlaceFirstCrate"] and stashCrateCount >= 1 then
	-- 		self.user.notifyManager:notifyError("Cannot buy more crates yet")
	-- 		return
	-- 	end
	-- end

	-- SUCCESS, REWARD THE CRATE AND REMOVE CURRENCY

	self.user.tutManager:updateTutMod({
		targetClass = "BuyCrate1",
		updateCount = 1,
	})

	local crateStats = CrateInfo:getMeta(crateClass)

	self.shopStock[crateClass] = crateCount - 1

	stashManager:addCrate({
		crateClass = crateClass,
	})

	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "CashBuy",
		volume = 0.5,
	})

	self:sendStock()
end

function CrateManager:sendStock()
	ServerMod:FireClient(self.user.player, "updateCrateShopStock", {
		restockTime = self.restockTime,
		stock = self.shopStock,
	})
end

function CrateManager:tick(timeRatio)
	for _, crate in pairs(self.crates) do
		crate:tick(timeRatio)
	end
end

function CrateManager:addCrate(data)
	local crateClass = data["crateClass"]
	local firstFrame = self.user.currFrame

	if not data["crateName"] then
		data["crateName"] = "CRATE_" .. Common.getGUID()
	end

	local crateName = data["crateName"]

	local crateData = {
		owner = self,
		crateClass = crateClass,
		firstFrame = firstFrame,
	}
	-- add the rest of the metadata
	for k, v in pairs(data) do
		crateData[k] = v
	end

	local crate = Crate.new(crateData)
	crate:init()
	self.crates[crateName] = crate
end

function CrateManager:sync(otherUser)
	for _, crate in pairs(self.crates) do
		crate:sync(otherUser)
	end
end

function CrateManager:saveState()
	local managerData = {
		restockTime = self.restockTime,
		stock = self.stock,

		lastPremiumCrateClass = self.lastPremiumCrateClass,
		lastPremiumSkipCrateName = self.lastPremiumSkipCrateName,
	}

	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function CrateManager:wipe()
	self.crates = {}
	self.shopStock = {}
	self.restockTime = 0

	self.lastPremiumCrateClass = nil
	self.lastPremiumSkipCrateName = nil

	self:sendStock()
end

return CrateManager
