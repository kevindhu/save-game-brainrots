local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local MutationInfo = require(game.ReplicatedStorage.MutationInfo)

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

function ProbManager:generateMutationClass()
	local probMap = Common.deepCopy(MutationInfo.mutationProbMap)

	local mutationClass = Common.rollFromProbMap(probMap)
	if mutationClass == "None" then
		return nil
	end
	return mutationClass
end

return ProbManager
