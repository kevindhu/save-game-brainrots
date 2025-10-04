local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local MutationInfo = require(game.ReplicatedStorage.MutationInfo)
local PetBalanceInfo = require(game.ReplicatedStorage.PetBalanceInfo)
local PetInfo = require(game.ReplicatedStorage.PetInfo)

local ProbManager = {}
ProbManager.__index = ProbManager

function ProbManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	setmetatable(u, ProbManager)
	return u
end

function ProbManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	-- self:loadState()

	routine(function()
		wait(0.5)
		self.initialized = true
	end)
end

function ProbManager:generatePetClass(chosenRating)
	local petProbMap = Common.deepCopy(PetBalanceInfo.petProbMap)

	if chosenRating ~= "None" then
		for petClass, weight in pairs(petProbMap) do
			local petStats = PetInfo:getMeta(petClass)
			if petStats["rating"] ~= chosenRating then
				petProbMap[petClass] = nil
			end
		end
	end

	-- self:addWeatherWeight(petProbMap)
	-- self:addLuckWeights(petProbMap)

	print("PET PROB MAP: ", petProbMap)

	local petClass = Common.rollFromProbMap(petProbMap)
	return petClass
end

function ProbManager:generateMutationClass()
	local probMap = Common.deepCopy(MutationInfo.mutationProbMap)

	local mutationClass = Common.rollFromProbMap(probMap)
	return mutationClass
end

return ProbManager
