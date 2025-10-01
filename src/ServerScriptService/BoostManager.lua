local ServerMod = require(game.ServerScriptService:WaitForChild("ServerMod"))

local BoostInfo = require(game.ReplicatedStorage.BoostInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, wait, routine = Common.len, Common.wait, Common.routine

local BoostManager = {}
BoostManager.__index = BoostManager

function BoostManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.boostMods = {}
	u.multipliers = {}

	setmetatable(u, BoostManager)
	return u
end

function BoostManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	routine(function()
		wait(1)
		-- self:initTestBoosts()
		self:sendBoostMods()
	end)
end

function BoostManager:initTestBoosts()
	if not Common.checkDeveloper(self.user.userId) then
		return
	end

	self:addBoostFromPotion("100xStrengthPotion_1Min")
end

function BoostManager:tickSecond()
	self:tickBoostMods()
end

function BoostManager:addBoostFromPotion(potionClass)
	local potionStats = BoostInfo:getMeta(potionClass)

	local boostClass = potionStats["boostClass"]
	local duration = potionStats["duration"]

	self:addBoostMod(boostClass, duration)
end

function BoostManager:addBoostMod(boostClass, duration)
	local boostMod = self.boostMods[boostClass]
	if not boostMod then
		boostMod = {
			boostClass = boostClass,
			duration = 0,
		}
		self.boostMods[boostClass] = boostMod
	end

	boostMod["duration"] += duration

	self:sendBoostMods()

	local boostStats = BoostInfo:getMeta(boostClass)
	local race = boostStats["race"]
	if race == "Strength" then
		self:refreshStrengthDensities()
	end
end

function BoostManager:getMultiplier(multiplierClass)
	local multipliers = self:getMultipliers()
	if not multipliers[multiplierClass] then
		return 1
	end
	return multipliers[multiplierClass]
end

function BoostManager:getMultipliers()
	local multipliers = {}
	for _, boostMod in pairs(self.boostMods) do
		local boostClass = boostMod["boostClass"]
		local boostStats = BoostInfo:getMeta(boostClass)
		local race = boostStats["race"]
		local multiplier = boostStats["multiplier"]

		if not multipliers[race] then
			multipliers[race] = 1
		end
		multipliers[race] = multipliers[race] + (multiplier - 1)
	end
	return multipliers
end

function BoostManager:refreshStrengthDensities()
	for _, unit in pairs(ServerMod.unitManager.units) do
		if unit.ropeMods[self.user.name] then
			unit:refreshAllDensities()
			break
		end
	end

	self.user:refreshWalkspeed()
end

function BoostManager:removeBoostMod(boostClass)
	self.boostMods[boostClass] = nil
	self:sendBoostMods()

	local boostStats = BoostInfo:getMeta(boostClass)
	local race = boostStats["race"]
	if race == "Strength" then
		self:refreshStrengthDensities()
	end
end

-- NOTE: should only send this once when boosts are added or removed, should not send every second!
function BoostManager:sendBoostMods()
	local boostData = {
		boostMods = self.boostMods,
	}
	-- print("SENDING BOOST MODS: ", self.boostMods)

	ServerMod:FireClient(self.user.player, "updateBoostMods", boostData)
end

function BoostManager:tickBoostMods()
	for boostRace, boostMod in pairs(self.boostMods) do
		local duration = boostMod["duration"]
		if duration <= 0 then
			self:removeBoostMod(boostRace)
		end

		boostMod["duration"] -= 1
	end
end

function BoostManager:saveState()
	local managerInfo = {
		boostMods = self.boostMods,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerInfo)
end

function BoostManager:wipe()
	self.boostMods = {}
	self:sendBoostMods()
end

return BoostManager
