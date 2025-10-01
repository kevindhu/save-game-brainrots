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

	setmetatable(u, IndexManager)
	return u
end

function IndexManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:sendUnlockedPets()

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
			"Normal",
			"Gold",
			"Diamond",
			"Bubblegum",
			-- "Volcanic",
		}
		for _, mutationClass in pairs(mutationList) do
			self:unlockPet(petClass, mutationClass)
		end
	end
end

function IndexManager:unlockPet(petClass, mutationClass)
	local id = petClass .. "_" .. mutationClass

	if self.unlockedPetMap[id] then
		return
	end

	self.unlockedPetMap[id] = true
	self:sendUnlockedPets()
end

function IndexManager:sendUnlockedPets()
	ServerMod:FireClient(self.user.player, "updateUnlockedPets", {
		unlockedPetMap = self.unlockedPetMap,
	})
end

function IndexManager:wipe()
	self.unlockedPetMap = {}

	self:sendUnlockedPets()
end

function IndexManager:saveState()
	local managerData = {
		unlockedPetMap = self.unlockedPetMap,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

return IndexManager
