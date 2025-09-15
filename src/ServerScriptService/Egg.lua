local ServerMod = require(script.Parent.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local EggInfo = require(game.ReplicatedStorage.EggInfo)
local MutationInfo = require(game.ReplicatedStorage.MutationInfo)
local RatingInfo = require(game.ReplicatedStorage.RatingInfo)
local PetInfo = require(game.ReplicatedStorage.PetInfo)

local Egg = {}
Egg.__index = Egg

function Egg.new(data)
	local u = {}
	u.data = data

	setmetatable(u, Egg)
	return u
end

function Egg:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end
	self.user = self.owner.user

	self.eggStats = EggInfo:getMeta(self.eggClass)

	self.baseModel = game.ReplicatedStorage.Assets[self.eggClass]

	self.currFrame = self.firstFrame

	if not self.hatchExpiree then
		-- set hatchExpiree to now + hatchTime
		self.hatchExpiree = os.time() + self.eggStats["hatchTime"]
	end

	for _, otherUser in pairs(ServerMod.users) do
		self:sync(otherUser)
	end

	self.user.home.tutManager:updateTutMod({
		targetClass = "PlaceFirstEgg",
		updateCount = 1,
	})
end

function Egg:tick()
	if not self:isHatchable() then
		return
	end

	self.user.home.tutManager:updateTutMod({
		targetClass = "WaitForFirstEgg",
		updateCount = 1,
	})
end

function Egg:sync(otherUser)
	ServerMod:FireClient(otherUser.player, "newEgg", {
		eggName = self.eggName,
		eggClass = self.eggClass,
		userName = self.user.name,

		mutationClass = self.mutationClass,

		noSpawnAnimation = self.noSpawnAnimation,

		currFrame = self.currFrame,

		hatchExpiree = self.hatchExpiree,
	})
end

function Egg:isHatchable()
	local timeRemaining = self.hatchExpiree - os.time()
	return timeRemaining <= 0
end

function Egg:tryInstantHatch()
	if self:isHatchable() then
		warn("CAN ALREADY HATCH, CANT INSTANT HATCH")
		return
	end

	self.user.home.eggManager.lastPremiumSkipEggName = self.eggName

	self.user.home.shopManager:tryBuyProduct({
		productClass = "Skip" .. self.eggClass,
	})
end

function Egg:tryHatch()
	if self.user.home.itemStash:checkFullPets() then
		self.user:notifyError("Your inventory is full!")
		return
	end

	if not self:isHatchable() then
		return
	end

	self:hatch()
end

function Egg:addLuckWeights(petProbMap)
	local totalLuck = self.user.home.plotManager:getTotalLuck()

	local luckDebuff = 0.05 -- 0.1

	for petClass, weight in pairs(petProbMap) do
		local petStats = PetInfo:getMeta(petClass)
		local rating = petStats["rating"]
		local luckMultiplier = totalLuck * RatingInfo.ratingLuckMultiplier[rating]

		local luckWeightBuff = weight * luckMultiplier * luckDebuff
		petProbMap[petClass] = weight + luckWeightBuff
	end
end

function Egg:hatch()
	local petProbMap = Common.deepCopy(self.eggStats["petProbMap"])
	-- self:addWeatherWeight(petProbMap)
	self:addLuckWeights(petProbMap)

	local petClass = Common.rollFromProbMap(petProbMap)
	local itemStash = self.user.home.itemStash
	local mutationClass = self.mutationClass

	self.user.home.indexManager:unlockPet(petClass, mutationClass)

	self.user.home.tutManager:updateTutMod({
		targetClass = "HatchFirstEgg",
		updateCount = 1,
	})

	local itemData = {
		itemName = "STASHPET_" .. Common.getGUID(),
		itemClass = petClass,
		race = "pet",

		-- unit metadata
		creationTimestamp = os.time(),
		mutationClass = mutationClass,

		hatchDelayTimer = 6,
	}
	self.user.home.petManager:fillPetDataWithDefaults(itemData)

	ServerMod:FireAllClients("addHatchAnimation", {
		eggName = self.eggName,
		hatchExpiree = self.hatchExpiree,
		itemData = itemData,
		userName = self.user.name,
	})

	local maxPetCount = self.user.home.plotManager:getMaxPetCount()

	if len(self.user.home.petManager.pets) < maxPetCount then
		local firstFrame = self.currFrame

		local petData = {
			petClass = petClass,
			firstFrame = firstFrame,
		}
		for k, v in pairs(itemData) do
			petData[k] = v
		end
		self.user.home.petManager:addPet(petData)
	else
		itemStash:addItemMod(itemData)
	end

	self:destroy()
end

function Egg:getSaveData()
	local baseFrame = self.user.home.plotManager.plotBaseFrame:inverse() * self.currFrame
	local firstFrameComp = { baseFrame:GetComponents() }

	return {
		eggName = self.eggName,
		eggClass = self.eggClass,
		userName = self.user.name,

		mutationClass = self.mutationClass,

		firstFrameComp = firstFrameComp,

		hatchExpiree = self.hatchExpiree,
	}
end

function Egg:destroy()
	if self.destroyed then
		warn("ALREADY DESTROYED USER HUH: ", self.name)
		return
	end
	self.destroyed = true

	self.owner.eggs[self.eggName] = nil

	ServerMod:FireAllClients("removeEgg", {
		eggName = self.eggName,
	})
end

return Egg
