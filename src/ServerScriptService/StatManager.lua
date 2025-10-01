local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local StatInfo = require(game.ReplicatedStorage.StatInfo)

local StatManager = {}
StatManager.__index = StatManager

function StatManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.statMods = {}

	u.leaderStatMods = {}

	setmetatable(u, StatManager)
	return u
end

function StatManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:initLeaderStats()

	self:initFirstStatMods()
	self:sendStatMods()

	routine(function()
		wait(0.2)
		self:incrementStatMod("Coins", 0)
		self:incrementStatMod("Steals", 0)
	end)
end

function StatManager:initLeaderStats()
	local player = self.user.player

	local leaderStats = Instance.new("Folder")
	leaderStats.Name = "leaderstats"
	leaderStats.Parent = player

	local statClassList = {
		"Coins",
	}
	for _, statClass in pairs(statClassList) do
		local statValue = nil
		local statStats = StatInfo:getMeta(statClass)
		if statStats["isInteger"] then
			statValue = Instance.new("IntValue")
			statValue.Value = 0
		else
			statValue = Instance.new("StringValue")
			statValue.Value = "--"
		end
		statValue.Name = statClass

		statValue.Parent = leaderStats

		self.leaderStatMods[statClass] = {
			statClass = statClass,
			value = statValue,
		}
	end
end

function StatManager:setLeaderStatMod(statClass, value)
	local leaderStatMod = self.leaderStatMods[statClass]
	if not leaderStatMod then
		return
	end

	-- print("SETTING LEADER STAT MOD: ", statClass, value)

	local statStats = StatInfo:getMeta(statClass)
	if statStats["abbreviateNum"] then
		value = Common.abbreviateNumber(value)
	end
	leaderStatMod.value.Value = value
end

function StatManager:tickSecond()
	self:incrementStatMod("Playtime", 1)
end

function StatManager:getStatMod(itemClass)
	return self.statMods[itemClass]
end

function StatManager:setStatMod(data)
	local statClass = data["statClass"]
	local count = data["count"]

	local statMod = self.statMods[statClass]
	if not statMod then
		warn(debug.traceback())
		warn("STAT MOD NOT FOUND: ", statClass, data)
		return
	end
	statMod["value"] = count

	self:setLeaderStatMod(statClass, count)

	self:sendStatMods()
end

function StatManager:incrementStatMod(statClass, count)
	local statMod = self.statMods[statClass]
	if not statMod then
		return
	end

	-- print("INCREMENTING STAT MOD: ", statClass, count)

	local newValue = statMod["value"] + count

	self:setStatMod({
		statClass = statClass,
		count = newValue,
	})
end

function StatManager:updateStatMod(statClass, count)
	local statMod = self.statMods[statClass]
	if not statMod then
		statMod = self:newStatMod(statClass)
	end
	local newValue = statMod["value"] + count

	self:setStatMod({
		statClass = statClass,
		count = newValue,
	})
end

function StatManager:initFirstStatMods()
	for _, statClass in ipairs(StatInfo.statList) do
		local statMod = self.statMods[statClass]
		if not statMod then
			statMod = self:newStatMod(statClass)
		end
	end

	for statClass, statMod in pairs(self.statMods) do
		if not Common.listContains(StatInfo.statList, statClass) then
			-- clear from statMods if not in statStatList
			self.statMods[statClass] = nil
		end
	end
end

function StatManager:newStatMod(statClass)
	local newStatMod = {
		statClass = statClass,
		value = 0,
	}

	self.statMods[statClass] = newStatMod

	return newStatMod
end

function StatManager:sendStatMods()
	ServerMod:FireAllClients("updateStatMods", {
		statMods = self.statMods,
	})
end

function StatManager:saveState()
	local managerData = {
		statMods = self.statMods,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function StatManager:wipe()
	self.statMods = {}

	self:initFirstStatMods()
	self:sendStatMods()
end

return StatManager
