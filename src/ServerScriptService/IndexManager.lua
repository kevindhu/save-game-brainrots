local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local IndexInfo = require(game.ReplicatedStorage.IndexInfo)
local PetInfo = require(game.ReplicatedStorage.PetInfo)

local IndexManager = {}
IndexManager.__index = IndexManager

function IndexManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.unlockedPetMap = {}

	u.rewardLevel = 1
	u.coinsMultiplier = 1

	setmetatable(u, IndexManager)
	return u
end

function IndexManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:sendUnlockedPets()
	self:sendRewardLevel()

	-- routine(function()
	-- 	self:unlockAllPets()
	-- end)
end

function IndexManager:unlockAllPets()
	if not Common.isStudio then
		return
	end

	for _, petClass in pairs(PetInfo.petOrderList) do
		local mutationList = {
			"None",
			"Gold",
			"Diamond",
			"Bubblegum",
			-- "Volcanic",
		}
		for _, mutationClass in pairs(mutationList) do
			if mutationClass == "None" then
				mutationClass = nil
			end
			self:unlockPet(petClass, mutationClass)
		end
	end
end

function IndexManager:tryClaimIndexReward()
	local rewardLevel = self.rewardLevel
	if rewardLevel >= IndexInfo.MAX_LEVEL then
		self.user:notifyError("You have already claimed all rewards.")
		return
	end

	local rewardStats = IndexInfo:getMeta("Reward" .. rewardLevel)
	local requirePetCount = rewardStats["requirePetCount"]
	if len(self.unlockedPetMap) < requirePetCount then
		self.user:notifyError("You need to unlock " .. requirePetCount .. " brainrots to claim this reward.")
		return
	end

	local rewardItems = rewardStats["rewardItems"]
	for itemClass, itemData in pairs(rewardItems) do
		if itemData["coinMultiplier"] then
			self.coinsMultiplier = self.coinsMultiplier + itemData["coinMultiplier"]
		elseif itemData["coinCount"] then
			self.user.home.itemStash:updateItemCount({
				itemName = "Coins",
				count = itemData["coinCount"],
			})
		end
	end

	self.user:notifySuccess("You have claimed rewards for index level " .. rewardLevel .. "!")
	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "SuccessRebirth",
		volume = 1,
	})

	self.rewardLevel += 1
	self:sendRewardLevel()
end

function IndexManager:unlockPet(petClass, mutationClass)
	local id = petClass
	if mutationClass then
		id = id .. "_" .. mutationClass
	end

	-- print("UNLOCK PET: ", petClass, mutationClass, id, self.unlockedPetMap)

	if self.unlockedPetMap[id] then
		return
	end

	self.unlockedPetMap[id] = true
	self:sendUnlockedPets()
end

function IndexManager:sendRewardLevel()
	ServerMod:FireClient(self.user.player, "updateIndexRewardLevel", {
		rewardLevel = self.rewardLevel,
	})
end

function IndexManager:sendUnlockedPets()
	ServerMod:FireClient(self.user.player, "updateUnlockedPets", {
		unlockedPetMap = self.unlockedPetMap,
	})
end

function IndexManager:saveState()
	local managerData = {
		unlockedPetMap = self.unlockedPetMap,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

return IndexManager
