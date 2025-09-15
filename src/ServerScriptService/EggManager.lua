local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local Egg = require(game.ServerScriptService.Egg)

local EggInfo = require(game.ReplicatedStorage.EggInfo)

local EggManager = {}
EggManager.__index = EggManager

function EggManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.eggs = {}
	u.fullEggData = {}

	u.restockTime = 0
	u.shopStock = {}

	setmetatable(u, EggManager)
	return u
end

function EggManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:loadState()

	routine(function()
		wait(1)
		self.initialized = true
	end)

	self:sendStock()
end

function EggManager:updateStock(scheduleMod)
	local stock = scheduleMod.stock
	local restockTime = scheduleMod.restockTime

	-- print("GOT STOCK: ", stock, scheduleMod)

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

function EggManager:tryBuyEgg(data)
	local eggClass = data["eggClass"]
	local withRobux = data["withRobux"]

	if withRobux then
		self.lastPremiumEggClass = eggClass

		self.user.home.shopManager:tryBuyProduct({
			productClass = "Buy" .. eggClass,
		})
		return
	end

	local eggCount = self.shopStock[eggClass] or 0
	if eggCount <= 0 then
		self.user:notifyError("This egg is out of stock!")

		return
	end

	-- see if already have itemStash egg
	local stashEggCount = 0

	local itemStash = self.user.home.itemStash
	for _, itemMod in pairs(itemStash.itemMods) do
		if itemMod["race"] ~= "egg" then
			continue
		end
		stashEggCount += 1
	end

	if not Common.checkDeveloper(self.user.userId) then
		if not self.user.home.tutManager.completedTutMods["PlaceFirstEgg"] and stashEggCount >= 1 then
			self.user:notifyError("Cannot buy more eggs yet")
			return
		end
	end

	-- SUCCESS, REWARD THE EGG AND REMOVE CURRENCY

	self.user.home.tutManager:updateTutMod({
		targetClass = "BuyEgg1",
		updateCount = 1,
	})

	local eggStats = EggInfo:getMeta(eggClass)

	self.shopStock[eggClass] = eggCount - 1

	local mutationClass = self.user.home.probManager:generateMutationClass()
	if mutationClass and mutationClass ~= "None" then
		self.user:notifySuccess(string.format("Your %s mutated to %s!", eggStats["alias"], mutationClass))
		ServerMod:FireClient(self.user.player, "newSoundMod", {
			soundClass = "Notice",
			volume = 0.5,
		})
	end

	itemStash:addEgg({
		eggClass = eggClass,
		mutationClass = mutationClass,
	})

	-- self.user:notifySuccess("You bought 1 " .. eggStats["alias"] .. "!")

	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "CashBuy",
		volume = 0.5,
		-- pos = self.user.humanoid.RootPart.Position,
	})

	self:sendStock()
end

function EggManager:sendStock()
	ServerMod:FireClient(self.user.player, "updateEggShopStock", {
		restockTime = self.restockTime,
		stock = self.shopStock,
	})
end

function EggManager:loadState()
	local fullEggData = self.fullEggData

	-- print("GOT FULL EGG DATA: ", fullEggData)

	for eggName, eggData in pairs(fullEggData) do
		local firstFrameComp = eggData["firstFrameComp"]
		local firstFrame = self.user.home.plotManager.plotBaseFrame * CFrame.new(table.unpack(firstFrameComp))

		eggData["firstFrame"] = firstFrame
		eggData["noSpawnAnimation"] = true

		self:addEgg(eggData)
	end

	-- print("GOT NEW EGGS:", self.eggs)
end

function EggManager:getRandomFrame()
	local plotManager = self.user.home.plotManager
	local floorPart = plotManager.eggFloorPart

	local middleRatio = 0.8

	local xOffset = math.random(-floorPart.Size.X / 2 * middleRatio, floorPart.Size.X / 2 * middleRatio)
	local zOffset = math.random(-floorPart.Size.Z / 2 * middleRatio, floorPart.Size.Z / 2 * middleRatio)

	local hOffset = floorPart.Size.Y * 0.5
	local randomFrame = floorPart.CFrame
		* CFrame.new(xOffset, hOffset, zOffset)
		* CFrame.Angles(0, math.rad(math.random(0, 4) * 90), 0)

	return randomFrame
end

function EggManager:tick(timeRatio)
	for _, egg in pairs(self.eggs) do
		egg:tick(timeRatio)
	end
end

function EggManager:addEgg(data)
	local eggClass = data["eggClass"]
	local firstFrame = data["firstFrame"]

	if not data["eggName"] then
		data["eggName"] = "EGG_" .. Common.getGUID()
	end

	if not firstFrame then
		firstFrame = self:getRandomFrame()
	end

	local eggName = data["eggName"]

	local eggData = {
		owner = self,
		eggClass = eggClass,
		firstFrame = firstFrame,
	}
	-- add the rest of the metadata
	for k, v in pairs(data) do
		eggData[k] = v
	end

	local egg = Egg.new(eggData)

	egg:init()
	self.eggs[eggName] = egg
end

function EggManager:sync(otherUser)
	for _, egg in pairs(self.eggs) do
		egg:sync(otherUser)
	end
end

function EggManager:tryInstantHatchEgg(data)
	local eggName = data["eggName"]
	local egg = self.eggs[eggName]
	if not egg then
		return
	end

	egg:tryInstantHatch()
end

function EggManager:tryHatchEgg(data)
	local eggName = data["eggName"]
	local egg = self.eggs[eggName]
	if not egg then
		warn("NO EGG FOUND TO HATCH: ", eggName)
		return
	end

	egg:tryHatch()
end

function EggManager:destroy()
	for _, egg in pairs(self.eggs) do
		egg:destroy()
	end
	self.eggs = {}
end

function EggManager:saveState()
	local fullEggData = {}
	for _, egg in pairs(self.eggs) do
		fullEggData[egg.eggName] = egg:getSaveData()
	end

	local managerData = {
		restockTime = self.restockTime,
		stock = self.stock,

		fullEggData = fullEggData,

		lastPremiumEggClass = self.lastPremiumEggClass,
		lastPremiumSkipEggName = self.lastPremiumSkipEggName,
	}

	self.user.store:set(self.moduleAlias .. "Info", managerData)

	-- print("SAVED EGG STATE: ", managerData)
end

return EggManager
