local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local Pet = require(game.ServerScriptService.Pet)

local PetManager = {}
PetManager.__index = PetManager

function PetManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.pets = {}
	u.fullPetData = {}

	setmetatable(u, PetManager)
	return u
end

function PetManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:loadState()

	routine(function()
		wait(1)

		if self.isNew then
			self:addTestPets()
		end

		wait(1)

		if not self.isNew then
			self:sendOfflineCoinsData()
		end

		self.initialized = true
	end)
end

function PetManager:sendOfflineCoinsData()
	local totalOfflineCoins = 0

	local totalSeconds = 0
	for _, pet in pairs(self.pets) do
		totalOfflineCoins += pet.totalOfflineCoins
		totalSeconds = math.max(totalSeconds, os.time() - pet.leaveTimestamp)
	end

	-- less than 30 minutes
	if totalSeconds < 60 * 30 then
		-- immediately just claim without boost
		print("CLAIMING WITHOUT BOOST")
		self:claimOfflineCoins({
			boost = false,
		})
		return
	end

	ServerMod:FireClient(self.user.player, "updateCoinsOfflineData", {
		totalOfflineCoins = totalOfflineCoins,
	})
end

function PetManager:loadState()
	local fullPetData = self.fullPetData

	for petName, petData in pairs(fullPetData) do
		local firstFrameComp = petData["firstFrameComp"]

		local currPetData = Common.deepCopy(petData)

		local firstFrame = self.user.home.plotManager.plotBaseFrame * CFrame.new(table.unpack(firstFrameComp))
		currPetData["firstFrame"] = firstFrame

		self:addPet(currPetData)
	end
end

function PetManager:tryRewardCoins(data)
	local petName = data["petName"]
	local pet = self.pets[petName]
	if not pet then
		-- warn("PET NOT FOUND TO REWARD COINS: ", petName)
		return
	end

	pet:tryRewardCoins()
end

function PetManager:tryStorePet(data)
	local petName = data["petName"]
	local pet = self.pets[petName]
	if not pet then
		return
	end

	self:storePet(pet)
end

function PetManager:generateRandomBaseWeight()
	local baseWeight = Common.randomBetween(1, 1.3)

	-- if math.random() * 100 < 100 then
	-- 	baseWeight *= 100
	-- end

	return baseWeight
end

function PetManager:addTestPets()
	if not Common.checkDeveloper(self.user.userId) then
		return
	end

	local petClasses = {
		-- "CowPlanet",

		-- "FishCatLegs",
		"TungTungSahur",
		-- "CappuccinoAssassino",
		-- "FrigoCamelo",
		-- "TaTaTaSahur",

		-- "ElephantCoconut",
		-- "TrippiTroppi",
		-- "DolphinBanana",
		-- "TralaleloTralala",
		-- "ChimpBanana",
		-- "Boneca",
	}

	for i = 1, 1 do
		for _, petClass in ipairs(petClasses) do
			self:addPet({
				petClass = petClass,

				mutationClass = "Gold",
				variationScale = Common.randomBetween(1, 1.2),

				baseWeight = 1,
			})
		end

		for _, petClass in ipairs(petClasses) do
			self:addPet({
				petClass = petClass,

				mutationClass = "Diamond",
				variationScale = Common.randomBetween(1, 1.2),
			})
		end

		for _, petClass in ipairs(petClasses) do
			self:addPet({
				petClass = petClass,

				mutationClass = "Bubblegum",
				variationScale = Common.randomBetween(1, 1.2),
			})
		end
	end
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
	for _, pet in pairs(self.pets) do
		totalOfflineCoins += pet.totalOfflineCoins
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
	for _, pet in pairs(self.pets) do
		pet.totalOfflineCoins = 0
		-- pet:sendData()
	end

	ServerMod:FireClient(self.user.player, "claimedOfflineCoins", {
		totalOfflineCoins = totalOfflineCoins,
	})
end

function PetManager:tick(timeRatio)
	for _, pet in pairs(self.pets) do
		pet:tick(timeRatio)
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
	if not petData["exp"] then
		petData["exp"] = 0
	end
end

function PetManager:addPet(petData)
	self:fillPetDataWithDefaults(petData)

	-- handle firstFrame
	if not petData["firstFrame"] then
		petData["firstFrame"] = self:getRandomFrame()
	end

	local pet = Pet.new(self, petData)
	pet:init()
	self.pets[petData["petName"]] = pet
end

function PetManager:storePet(pet)
	self.user:notifySuccess(string.format("%s stored", pet.petStats["alias"]))
	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "HammerHit",
		-- volume = 0.5,
	})

	local itemData = pet:getSaveData()

	-- TODO: do we need this?
	itemData["itemName"] = "STASHTOOL_" .. Common.getGUID()
	itemData["itemClass"] = itemData["petClass"]
	itemData["race"] = "pet"
	itemData["noImmediateEquip"] = true

	self.user.home.itemStash:addItemMod(itemData)

	pet:destroy()
end

function PetManager:sync(otherUser)
	for _, pet in pairs(self.pets) do
		pet:sync(otherUser)
	end
end

function PetManager:destroy()
	for _, pet in pairs(self.pets) do
		pet:destroy()
	end
	self.pets = {}
end

function PetManager:saveState()
	local fullPetData = {}
	for _, pet in pairs(self.pets) do
		fullPetData[pet.petName] = pet:getSaveData()
	end
	local managerData = {
		fullPetData = fullPetData,
	}

	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

return PetManager
