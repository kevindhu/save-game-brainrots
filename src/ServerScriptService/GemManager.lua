local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local GemSpawner = require(game.ServerScriptService.GemSpawner)

local GemManager = {}
GemManager.__index = GemManager

function GemManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.gemSpawners = {}
	u.gems = {}

	u.fullSpawnerData = {}
	u.fullShardData = {}

	setmetatable(u, GemManager)
	return u
end

function GemManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:loadState()

	self:initAllSpawners()

	routine(function()
		wait(1)
		self.initialized = true
	end)
end

function GemManager:initAllSpawners()
	local plotManager = self.user.home.plotManager
	local gemSpawnerParts = plotManager.model.GemSpawnerParts:GetChildren()

	for i, part in pairs(gemSpawnerParts) do
		local gemSpawnerName = "GEMSPAWNER_" .. i

		local gemSpawnerData = self.fullSpawnerData[gemSpawnerName] or {}

		local cachedGemMapPerZone = gemSpawnerData["cachedGemMapPerZone"]

		-- print("CACHED GEM MAP PER ZONE: ", cachedGemMapPerZone)

		local gemSpawner = GemSpawner.new({
			gemSpawnerName = gemSpawnerName,
			owner = self,
			part = part,

			cachedGemMapPerZone = cachedGemMapPerZone,
		})
		gemSpawner:init()
		self.gemSpawners[gemSpawnerName] = gemSpawner

		gemSpawner:loadState(self.fullShardData)
	end
end

function GemManager:loadState() end

function GemManager:tick(timeRatio)
	for _, gemSpawner in pairs(self.gemSpawners) do
		gemSpawner:tick(timeRatio)
	end
end

function GemManager:getGiantGemList()
	local gemModList = {}
	for _, gem in pairs(self.gems) do
		if gem.destroyed then
			continue
		end
		if gem.isGiant then
			table.insert(gemModList, {
				gem = gem,
			})
		end
	end
	return gemModList
end

function GemManager:getOccupiedGemList()
	local gemModList = {}
	for _, gem in pairs(self.gems) do
		if gem.destroyed then
			continue
		end
		-- check if its being attacked
		local petManager = self.user.home.petManager
		local isBeingAttacked = false
		for _, pet in pairs(petManager.pets) do
			if pet.actionMod and pet.actionMod["gemName"] == gem.gemName then
				isBeingAttacked = true
				break
			end
		end
		if isBeingAttacked then
			continue
		end

		table.insert(gemModList, {
			gem = gem,
		})
	end
	return gemModList
end

function GemManager:getBestGemList()
	-- first target giant gems
	local gemModList = self:getGiantGemList()

	-- then target occupied gems
	if len(gemModList) == 0 then
		gemModList = self:getOccupiedGemList()
	end

	-- then target all gems
	if len(gemModList) == 0 then
		gemModList = self:getAllGemList()
	end

	return gemModList
end

function GemManager:getClosestUnoccupiedGem(pet)
	local gemModList = self:getBestGemList()
	if len(gemModList) == 0 then
		return nil
	end

	for _, gemMod in pairs(gemModList) do
		local gem = gemMod["gem"]

		local distance = (pet.currFrame.Position - gem.currFrame.Position).Magnitude
		gemMod["distance"] = distance
	end

	table.sort(gemModList, function(a, b)
		return a["distance"] < b["distance"]
	end)

	return gemModList[1]["gem"]
end

-- NO LONGER USED
function GemManager:getRandomUnoccupiedGem()
	local gemModList = self:getBestGemList()

	local gemMod = gemModList[math.random(1, len(gemModList))]

	return gemMod["gem"]
end

function GemManager:getAllGemList()
	local gemModList = {}
	for _, gem in pairs(self.gems) do
		if gem.destroyed then
			continue
		end
		table.insert(gemModList, {
			gem = gem,
		})
	end
	return gemModList
end

function GemManager:getRandomFrame()
	local plotManager = self.user.home.plotManager
	local floorPart = plotManager.floorPart

	local middleRatio = 0.8

	local xOffset = math.random(-floorPart.Size.X / 2 * middleRatio, floorPart.Size.X / 2 * middleRatio)
	local zOffset = math.random(-floorPart.Size.Z / 2 * middleRatio, floorPart.Size.Z / 2 * middleRatio)

	local hOffset = floorPart.Size.Y * 0.5
	local randomFrame = floorPart.CFrame * CFrame.new(xOffset, hOffset, zOffset)

	return randomFrame
end

function GemManager:sync(otherUser)
	for _, gemSpawner in pairs(self.gemSpawners) do
		gemSpawner:sync(otherUser)
	end
end

function GemManager:saveState()
	local fullSpawnerData = {}

	local fullShardData = {}
	for _, gemSpawner in pairs(self.gemSpawners) do
		fullSpawnerData[gemSpawner.gemSpawnerName] = gemSpawner:getSaveData()

		for _, shard in pairs(gemSpawner.shards) do
			fullShardData[shard.shardName] = shard:getSaveData()
		end
	end

	local managerData = {
		fullSpawnerData = fullSpawnerData,
		fullShardData = fullShardData,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function GemManager:tryCollectShard(data)
	local gemSpawnerName = data["gemSpawnerName"]
	local shardName = data["shardName"]

	local gemSpawner = self.gemSpawners[gemSpawnerName]
	if not gemSpawner then
		warn("GEM SPAWNER NOT FOUND: ", gemSpawnerName)
		return
	end

	local shard = gemSpawner.shards[shardName]
	if not shard then
		warn("SHARD NOT FOUND: ", shardName, gemSpawner.shards)
		return
	end

	shard:collect()
end

function GemManager:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	for _, gemSpawner in pairs(self.gemSpawners) do
		gemSpawner:destroy()
	end
	self.gemSpawners = {}
end

return GemManager
