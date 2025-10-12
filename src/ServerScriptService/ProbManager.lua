local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local MutationInfo = require(game.ReplicatedStorage.MutationInfo)
local PetBalanceInfo = require(game.ReplicatedStorage.PetBalanceInfo)
local PetInfo = require(game.ReplicatedStorage.PetInfo)
local CrateInfo = require(game.ReplicatedStorage.CrateInfo)

local ProbManager = {}
ProbManager.__index = ProbManager

function ProbManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.testLuck = 0

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

		-- self:simulateLuckRuns()
	end)
end

function ProbManager:getTotalLuck()
	local totalUserLuck = 0
	if self.user.home.shopManager:checkOwnsGamepass("SuperLuck") then
		totalUserLuck += 2
	end

	local wizardLuck = self.user.home.luckWizardManager.currentLuck
	totalUserLuck += wizardLuck

	local serverLuck = ServerMod.luckManager.serverLuck - 1
	local totalLuck = totalUserLuck * 50 + serverLuck * 100

	-- totalLuck = 10 -- 10000

	return totalLuck
end

-- using debuff algorithm
function ProbManager:addLuckWeights(probMap, totalLuck, race)
	for itemClass, weight in pairs(probMap) do
		local rating = "None"
		if race == "pet" then
			local relicStats = PetInfo:getMeta(itemClass)
			rating = relicStats["rating"]
		end

		local debuffMultiplier = PetBalanceInfo.ratingDebuffMultiplier[rating]
		local debuffCount = debuffMultiplier * totalLuck

		local finalDebuff = 1 / (1 + debuffCount)

		-- print("GOT FINAL DEBUFF: ", finalDebuff, rating, totalLuck)

		weight = weight * finalDebuff
		probMap[itemClass] = weight
	end
end

function ProbManager:simulateLuckRuns()
	self:simulateWithLuck(0)
	self:simulateWithLuck(1000)

	self:simulateWithLuck(10000)
	self:simulateWithLuck(20000)
	self:simulateWithLuck(30000)
	self:simulateWithLuck(40000)
	self:simulateWithLuck(50000)
	self:simulateWithLuck(60000)
	self:simulateWithLuck(70000)
	self:simulateWithLuck(80000)
end

function ProbManager:simulateWithLuck(totalLuck)
	local probMap = Common.deepCopy(PetBalanceInfo.petProbMap)
	self:addLuckWeights(probMap, totalLuck, "pet")

	local countMap = {}
	-- do 10000 rolls and map the counts
	for i = 1, 100000 do
		local itemClass = Common.rollFromProbMap(probMap)
		countMap[itemClass] = (countMap[itemClass] or 0) + 1
	end

	-- local testPetClass = "OrangeDunDun"
	-- local testPetClass = "TungTungSahur"
	local testPetClass = "MilkShake"

	print("SIMULATION COUNT MAP: ", testPetClass, countMap, countMap[testPetClass], totalLuck)
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

	local totalLuck = self:getTotalLuck()

	-- TOGGLE FOR TESTING LUCK
	-- totalLuck = self.testLuck
	-- self.testLuck += 10 -- 10000

	print("GOT TOTAL LUCK: ", totalLuck)

	self:addLuckWeights(petProbMap, totalLuck, "pet")

	-- self:simulateWithLuck(totalLuck)

	local petClass = Common.rollFromProbMap(petProbMap)
	return petClass
end

function ProbManager:generateMutationClass()
	local probMap = Common.deepCopy(MutationInfo.mutationProbMap)

	local mutationClass = Common.rollFromProbMap(probMap)
	return mutationClass
end

return ProbManager
