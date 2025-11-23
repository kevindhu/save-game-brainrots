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
	u.fullPetSpotData = {}

	u.unlockedPetSpotIndex = 1

	setmetatable(u, PetManager)
	return u
end

local PET_SPOT_COUNT = 20 -- 10 -- 5

function PetManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:addAllPetSpots()

	routine(function()
		wait(0.5)
		if self.isNew then
			local plotName = self.user.home.plotManager.plotName

			self:tryUnlockPetSpot({
				petSpotName = plotName .. "_PetSpot" .. 1,
				noSound = true,
			})
		else
			self:loadState()
		end

		self:refreshBuyModels()

		wait(1)
		if not self.isNew then
			self:sendOfflineCoinsData()
		end

		self.initialized = true
	end)
end

function PetManager:loadState()
	local fullPetSpotData = self.fullPetSpotData

	print("LOAD STATE: ", fullPetSpotData)

	for _, petSpotData in pairs(fullPetSpotData) do
		local petData = petSpotData.petData
		local chosenPetSpot = nil
		for _, petSpot in pairs(self.petSpots) do
			if petSpot.index == petSpotData.index then
				chosenPetSpot = petSpot
				break
			end
		end
		if not chosenPetSpot then
			warn("!!! NO PET SPOT TO LOAD STATE FOR: ", petSpotData.index)
			continue
		end

		-- print("GOT PET SPOT DATA: ", petSpotData.index, petSpotData.unlocked, petData)

		if petSpotData.unlocked then
			chosenPetSpot:unlock()
		end

		if petData then
			chosenPetSpot:occupyWithPet(petData)
			chosenPetSpot:refreshTotalOfflineCoins(petSpotData.leaveTimestamp)
		end
	end
end

function PetManager:sendOfflineCoinsData()
	local totalOfflineCoins = 0

	local totalSeconds = 0
	for _, petSpot in pairs(self.petSpots) do
		if not petSpot.petData then
			continue
		end

		totalOfflineCoins += petSpot.petData.totalOfflineCoins
		totalSeconds = math.max(totalSeconds, os.time() - petSpot.leaveTimestamp)
	end

	-- -- less than 30 minutes
	-- if totalSeconds < 60 * 30 then
	-- 	-- immediately just claim without boost
	-- 	print("CLAIMING WITHOUT BOOST")
	-- 	self:claimOfflineCoins({
	-- 		boost = false,
	-- 	})
	-- 	return
	-- end

	ServerMod:FireClient(self.user.player, "updateCoinsOfflineData", {
		totalOfflineCoins = totalOfflineCoins,
	})
end

function PetManager:tryClaimOfflineCoins(data)
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

function PetManager:claimOfflineCoins(data)
	local boost = data["boost"]

	self.claimedOfflineCoins = true

	local totalOfflineCoins = 0
	for _, petSpot in pairs(self.petSpots) do
		if not petSpot.petData then
			continue
		end
		totalOfflineCoins += petSpot.petData.totalOfflineCoins
	end

	if boost then
		totalOfflineCoins = totalOfflineCoins * 10
	end

	self.user.home.itemStash:updateItemCount({
		itemName = "Coins",
		count = totalOfflineCoins,
	})

	-- clear all offline coins
	for _, petSpot in pairs(self.petSpots) do
		if not petSpot.petData then
			continue
		end
		petSpot.petData.totalOfflineCoins = 0
	end

	ServerMod:FireClient(self.user.player, "claimedOfflineCoins", {
		totalOfflineCoins = totalOfflineCoins,
	})
end

function PetManager:addAllPetSpots()
	for index = 1, PET_SPOT_COUNT do
		self:addPetSpot(index)
	end
end

function PetManager:tryUnlockPetSpot(data)
	local petSpotName = data["petSpotName"]
	local noSound = data["noSound"]

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
	local unlockCost = PetBalanceInfo["petSpotUnlockCostMap"][tostring(index)]
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

	if not noSound then
		ServerMod:FireClient(self.user.player, "newSoundMod", {
			soundClass = "CashBuy",
			volume = 0.5,
		})
	end

	self:refreshBuyModels()
end

function PetManager:refreshBuyModels()
	for index = 1, PET_SPOT_COUNT do
		local plotName = self.user.home.plotManager.plotName
		local currPetSpotName = plotName .. "_PetSpot" .. index
		local currPetSpot = self.petSpots[currPetSpotName]

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

function PetManager:fillPetDataWithDefaults(petData)
	petData["petName"] = petData["itemName"]

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

	if not petData["relicMods"] then
		petData["relicMods"] = {}
	end
end

function PetManager:generateRandomBaseWeight()
	local baseWeight = Common.randomBetween(1, 1.3)
	-- local baseWeight = Common.randomBetween(3, 10)

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

function PetManager:occupyPetSpot(petSpot, petData)
	self.user.home.tutManager:updateTutMod({
		targetClass = "PlaceFirstPet",
		updateCount = 1,
	})

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

function PetManager:trySwapPetAtPetSpot(data)
	local petSpotName = data["petSpotName"]
	local petSpot = self.petSpots[petSpotName]
	if not petSpot then
		warn("NO PET SPOT TO SWAP PET AT: ", petSpotName)
		return
	end
	self:tryPickupFromPetSpot(data)

	if self.swapPetExpiree and self.swapPetExpiree > ServerMod.step then
		self.user:notifyError("Please wait before trying again")
		return
	end
	self.swapPetExpiree = ServerMod.step + 60 * 0.2

	self.user.home.toolManager:tryPlacePetAtPetSpot(data)
end

function PetManager:tryPickupRelicFromPetSpot(data)
	local petSpotName = data["petSpotName"]
	local petSpot = self.petSpots[petSpotName]
	if not petSpot then
		warn("NO PET SPOT TO PICKUP RELIC FROM: ", petSpotName)
		return
	end
	if not petSpot.petData then
		warn("NO PET DATA TO PICKUP FROM: ", petSpot.petSpotName)
		return
	end

	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "SproutPop1",
	})

	petSpot:storeRelic()
end

function PetManager:trySwapRelicAtPetSpot(data)
	local petSpotName = data["petSpotName"]
	local petSpot = self.petSpots[petSpotName]
	if not petSpot then
		warn("NO PET SPOT TO SWAP RELIC AT: ", petSpotName)
		return
	end

	if self.swapRelicExpiree and self.swapRelicExpiree > ServerMod.step then
		self.user:notifyError("Please wait before trying again")
		return
	end
	self.swapRelicExpiree = ServerMod.step + 60 * 0.2

	self:tryPickupRelicFromPetSpot(data)
	self.user.home.toolManager:tryPlaceRelicAtPetSpot(data)
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

function PetManager:getPetValue(itemMod)
	local petClass = itemMod["itemClass"]
	local petStats = PetInfo:getMeta(petClass)

	-- TODO: add equipped relic value

	return petStats["attackDamage"] / (petStats["attackDelay"] or 0.05)
end

function PetManager:tryEquipBestPets(data)
	-- pickup all pets
	for _, petSpot in pairs(self.petSpots) do
		if not petSpot.petData then
			continue
		end

		self:tryPickupFromPetSpot({
			petSpotName = petSpot.petSpotName,
		})
	end

	local bestItemModList = {}
	for _, itemMod in pairs(self.user.home.itemStash.itemMods) do
		if itemMod["race"] ~= "pet" then
			continue
		end
		table.insert(bestItemModList, itemMod)
	end

	table.sort(bestItemModList, function(a, b)
		local aValue = self:getPetValue(a)
		local bValue = self:getPetValue(b)
		return aValue > bValue
	end)

	for i = 1, PET_SPOT_COUNT do
		local petSpotName = self.user.home.plotManager.plotName .. "_PetSpot" .. i
		local petSpot = self.petSpots[petSpotName]
		if not petSpot or not petSpot.unlocked then
			continue
		end

		local itemMod = bestItemModList[i]

		self:placePetFromItemStash(itemMod, petSpot)
	end
end

function PetManager:placePetFromItemStash(itemMod, petSpot)
	local petData = {
		petClass = itemMod["itemClass"],
	}
	for k, v in pairs(itemMod) do
		petData[k] = v
	end

	self:occupyPetSpot(petSpot, petData)

	self.user.home.itemStash:removeItemMod({
		itemName = itemMod["itemName"],
	})
end

function PetManager:placeRelicFromItemStash(itemMod, petSpot)
	local newItemMod = Common.deepCopy(itemMod)
	petSpot:addRelicMod(newItemMod)

	self.user.home.itemStash:removeItemMod({
		itemName = itemMod["itemName"],
	})
end

function PetManager:storePet(petSpot)
	local itemData = Common.deepCopy(petSpot.petData)
	itemData["noClick"] = false
	itemData["forceBottom"] = true

	self.user.home.itemStash:addItemMod(itemData)

	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "SproutPop1",
	})

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
	local fullPetSpotData = {}

	for _, petSpot in pairs(self.petSpots) do
		local petSpotData = petSpot:getSaveData()
		fullPetSpotData[petSpot.petSpotName] = petSpotData
	end

	local managerData = {
		fullPetSpotData = fullPetSpotData,
	}

	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function PetManager:wipe()
	-- clear all pet spots
	for _, petSpot in pairs(self.petSpots) do
		petSpot:destroy()
	end
	self.petSpots = {}

	self.fullPetSpotData = {}
	self.unlockedPetSpotIndex = 1

	self:addAllPetSpots()

	local plotName = self.user.home.plotManager.plotName

	self:tryUnlockPetSpot({
		petSpotName = plotName .. "_PetSpot" .. 1,
	})

	self:refreshBuyModels()
end

return PetManager
