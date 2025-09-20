local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local MutationInfo = require(game.ReplicatedStorage.MutationInfo)
local PetRollInfo = require(game.ReplicatedStorage.PetRollInfo)

local SpeedManager = {}
SpeedManager.__index = SpeedManager

function SpeedManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.speed = 1

	setmetatable(u, SpeedManager)
	return u
end

function SpeedManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	routine(function()
		wait(1)
		self:sendData()
		self.initialized = true

		wait(10)
		self:setSpeed(3)
	end)
end

function SpeedManager:sendData()
	ServerMod:FireClient(self.user.player, "updateGameSpeed", {
		speed = self.speed,
	})
end

function SpeedManager:setSpeed(speed)
	self.speed = speed
	self:sendData()
end

function SpeedManager:getSpeed()
	return self.speed
end

return SpeedManager
