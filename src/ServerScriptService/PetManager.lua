local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetInfo = require(game.ReplicatedStorage.PetInfo)
local PetBalanceInfo = require(game.ReplicatedStorage.PetBalanceInfo)

local PetSpot = require(game.ServerScriptService.PetSpot)

local PetManager = {}
PetManager.__index = PetManager

function PetManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.petSpots = {}
	u.fullPetData = {}

	u.unlockedPetSpotIndex = 1

	setmetatable(u, PetManager)
	return u
end

local PET_SPOT_COUNT = 5

function PetManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	routine(function()
		wait(1)
		self:addAllPetSpots()

		if self.isNew then
			local plotName = self.user.home.plotManager.plotName
			local firstIndex = 1
			self:tryUnlockPetSpot({
				petSpotName = plotName .. "_PetSpot" .. firstIndex,
			})
		end

		self:refreshUnlockedPetSpots()

		self.initialized = true
	end)
end

function PetManager:addAllPetSpots()
	for index = 1, PET_SPOT_COUNT do
		self:addPetSpot(index)
	end
end

function PetManager:tryUnlockPetSpot(data)
	local petSpotName = data["petSpotName"]

	local nextUnlockPetSpotName = nil
	for index = 1, PET_SPOT_COUNT do
		local plotName = self.user.home.plotManager.plotName
		local currPetSpotName = plotName .. "_PetSpot" .. index
		local currPetSpot = self.petSpots[currPetSpotName]
		if currPetSpot.unlocked then
			continue
		end
		nextUnlockPetSpotName = currPetSpotName
		break
	end

	if nextUnlockPetSpotName ~= petSpotName then
		warn("CANNOT UNLOCK THIS PET SPOT YET: ", petSpotName, nextUnlockPetSpotName)
		return
	end

	local petSpot = self.petSpots[petSpotName]
	if not petSpot then
		warn("NO PET SPOT TO UNLOCK: ", petSpotName)
		return
	end

	local index = petSpot.index
	local unlockCost = PetBalanceInfo["unlockCostMap"][tostring(index)]
	local coinsCount = self.user.home.itemStash:getItemCount({
		itemName = "Coins",
	})
	if coinsCount < unlockCost then
		self.user:notifyError("Not enough coins!")
		return
	end

	petSpot:unlock()

	self.user.home.itemStash:updateItemCount({
		itemName = "Coins",
		count = -unlockCost,
	})

	self:refreshUnlockedPetSpots()
end

function PetManager:refreshUnlockedPetSpots()
	for index = 1, PET_SPOT_COUNT do
		local plotName = self.user.home.plotManager.plotName
		local currPetSpotName = plotName .. "_PetSpot" .. index
		local currPetSpot = self.petSpots[currPetSpotName]

		-- print("SHOWING BUY MODEL FOR: ", currPetSpot.petSpotName)

		if currPetSpot.unlocked then
			continue
		end

		currPetSpot:showBuyModel()
		return
	end
end

function PetManager:addPetSpot(index)
	local plotName = self.user.home.plotManager.plotName
	local petSpotName = plotName .. "_PetSpot" .. index

	local petSpot = PetSpot.new(self, {
		petSpotName = petSpotName,
		index = index,
	})
	petSpot:init()
	self.petSpots[petSpotName] = petSpot
end

function PetManager:loadState()
	local fullPetData = self.fullPetData

	for petName, petData in pairs(fullPetData) do
		local currPetData = Common.deepCopy(petData)

		self:occupyPetSpot(self.petSpots[petName], currPetData)
	end
end

function PetManager:tick(timeRatio)
	for _, petSpot in pairs(self.petSpots) do
		petSpot:tick(timeRatio)
	end
end

function PetManager:getRandomFrame()
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

function PetManager:generateRandomBaseWeight()
	local baseWeight = Common.randomBetween(1, 1.3)

	-- if math.random() * 100 < 100 then
	-- 	baseWeight *= 100
	-- end

	return baseWeight
end

function PetManager:tryCollectCoins(data)
	local petSpotName = data["petSpotName"]
	local petSpot = self.petSpots[petSpotName]
	if not petSpot then
		warn("NO PET SPOT TO COLLECT COINS FROM: ", petSpotName)
		return
	end

	petSpot:tryCollectCoins()
end

function PetManager:fillPetDataWithDefaults(petData)
	-- handle petName
	if petData["itemName"] then
		petData["petName"] = petData["itemName"]
	end
	if not petData["petName"] then
		petData["petName"] = "PET_" .. Common.getGUID()
	end

	if not petData["baseWeight"] then
		petData["baseWeight"] = self:generateRandomBaseWeight()
	end

	-- handle levels and exp
	if not petData["level"] then
		petData["level"] = 1
	end
	if not petData["totalCoins"] then
		petData["totalCoins"] = 0
	end
	if not petData["totalOfflineCoins"] then
		petData["totalOfflineCoins"] = 0
	end
end

function PetManager:occupyPetSpot(petSpot, petData)
	self:fillPetDataWithDefaults(petData)

	petSpot:occupyWithPet(petData)
end

function PetManager:tryPickupFromPetSpot(data)
	local petSpotName = data["petSpotName"]
	local petSpot = self.petSpots[petSpotName]
	if not petSpot then
		warn("NO PET SPOT TO PICKUP FROM: ", petSpotName)
		return
	end
	if not petSpot.petData then
		warn("NO PET DATA TO PICKUP FROM: ", petSpot.petSpotName)
		return
	end

	self:storePet(petSpot)
end

function PetManager:tryLevelUpPet(data)
	local petSpotName = data["petSpotName"]
	local petSpot = self.petSpots[petSpotName]
	if not petSpot then
		warn("NO PET SPOT TO LEVEL UP: ", petSpotName)
		return
	end

	petSpot:tryLevelUp()
end

function PetManager:storePet(petSpot)
	local itemData = petSpot:getSaveData()

	local petClass = itemData["petClass"]
	local petStats = PetInfo:getMeta(petClass)

	self.user:notifySuccess(string.format("%s stored", petStats["alias"]))
	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "HammerHit",
		-- volume = 0.5,
	})

	-- TODO: do we need this?
	itemData["itemName"] = "STASHTOOL_" .. Common.getGUID()
	itemData["itemClass"] = petClass
	itemData["race"] = "pet"

	itemData["noClick"] = false
	itemData["forceBottom"] = true

	self.user.home.itemStash:addItemMod(itemData)

	petSpot:clearPet()
end

function PetManager:sync(otherUser)
	for _, petSpot in pairs(self.petSpots) do
		petSpot:sync(otherUser)
	end
end

function PetManager:destroy()
	for _, petSpot in pairs(self.petSpots) do
		petSpot:destroy()
	end
	self.petSpots = {}
end

function PetManager:saveState()
	local fullPetData = {}

	-- for _, petSpot in pairs(self.petSpots) do
	-- 	fullPetData[petSpot.petSpotName] = petSpot:getSaveData()
	-- end

	local managerData = {
		fullPetData = fullPetData,
	}

	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

return PetManager
