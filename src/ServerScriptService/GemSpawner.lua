local ServerMod = require(script.Parent.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local Gem = require(game.ServerScriptService.Gem)
local Shard = require(game.ServerScriptService.Shard)

local GemInfo = require(game.ReplicatedStorage.GemInfo)
local ZoneInfo = require(game.ReplicatedStorage.ZoneInfo)
local RatingInfo = require(game.ReplicatedStorage.RatingInfo)
local MutationInfo = require(game.ReplicatedStorage.MutationInfo)
local ShardInfo = require(game.ReplicatedStorage.ShardInfo)

local GemSpawner = {}
GemSpawner.__index = GemSpawner

function GemSpawner.new(data)
	local u = {}
	u.data = data

	u.respawnExpiree = 0

	u.shards = {}
	u.cachedGemMapPerZone = {}

	setmetatable(u, GemSpawner)
	return u
end

function GemSpawner:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end
	self.user = self.owner.user

	self.part.Transparency = 1 -- 0.5
	self.currFrame = self.part.CFrame * CFrame.new(0, -self.part.Size.Y / 2, 0)

	-- self:addTestShards()
end

function GemSpawner:loadState(fullShardData)
	for _, shardData in pairs(fullShardData) do
		if shardData["gemSpawnerName"] ~= self.gemSpawnerName then
			continue
		end

		self:addShard({
			shardClass = shardData["shardClass"],
			mutationClass = shardData["mutationClass"],
			noAnimate = true,
		})
	end
end

function GemSpawner:addTestShards()
	routine(function()
		wait(1)
		while true do
			self:tryAddNewShard({
				shardClass = "Shard1",
			})
			wait(Common.randomBetween(1, 3))
		end
	end)
end

function GemSpawner:cacheGemForZone(gem, zoneClass)
	self.cachedGemMapPerZone[zoneClass] = gem:getSaveData()
end

function GemSpawner:switchZone(oldZoneClass, newZoneClass)
	if self.gem then
		self:cacheGemForZone(self.gem, oldZoneClass)
		self.gem:destroy({
			waitTimer = 0,
		})
	end

	self.respawnExpiree = 0
end

function GemSpawner:getNewShardPos()
	local shootDistance = Common.randomBetween(8, 11)
	local randomFrame = self.currFrame * CFrame.new(Common.getRandomFlatDir() * shootDistance)

	local randomPos = randomFrame.Position
	-- randomPos += Vector3.new(0, 1, 0)

	return randomPos
end

function GemSpawner:tryAddNewShard(data)
	local shardClass = data["shardClass"]
	local mutationClass = data["mutationClass"]

	local shardStats = ShardInfo:getMeta(shardClass)

	local eggShardCount = 0
	for _, shard in pairs(self.shards) do
		if shard.shardStats["eggClass"] then
			eggShardCount += 1
		end
	end

	print("EGG SHARD COUNT: ", eggShardCount)

	if shardStats["eggClass"] then
		if eggShardCount >= 20 then
			return
		end
	else
		if len(self.shards) >= 6 then
			-- warn("TOO MANY SHARDS: ", self.gemSpawnerName)
			return
		end
	end

	self:addShard(data)
end

function GemSpawner:sync(otherUser)
	for _, shard in pairs(self.shards) do
		shard:sync(otherUser)
	end

	if self.gem then
		self.gem:sync(otherUser)
	end
end

function GemSpawner:addShard(data)
	local shardClass = data["shardClass"]
	local mutationClass = data["mutationClass"]
	local noAnimate = data["noAnimate"]

	local shardData = {
		shardName = "SHARD_" .. Common.getGUID(),
		shardClass = shardClass,

		userName = self.user.name,
		gemSpawnerName = self.gemSpawnerName,

		creationTimestamp = os.time(),

		startPos = self.currFrame.Position,
		currPos = self:getNewShardPos(),
		mutationClass = mutationClass,
		noAnimate = noAnimate,
	}
	local shard = Shard.new(self, shardData)
	shard:init()
	self.shards[shard.shardName] = shard
end

function GemSpawner:clearGem()
	local spawnTimer = Common.randomBetween(0.2, 3)
	-- local spawnTimer = 0.01

	self.respawnExpiree = ServerMod.step + 60 * spawnTimer

	-- after respawnExpiree is set, then remove the gem
	self.gem = nil
end

function GemSpawner:tick(timeRatio)
	self:trySpawnGem()
end

function GemSpawner:getSaveData()
	local zoneClass = self.user.home.zoneManager.currZoneClass
	if self.gem then
		self:cacheGemForZone(self.gem, zoneClass)
	end

	for currZoneClass, _ in pairs(self.cachedGemMapPerZone) do
		-- clear all cached gems for other zones
		if currZoneClass ~= zoneClass then
			self.cachedGemMapPerZone[currZoneClass] = nil
		end
	end

	local saveData = {
		cachedGemMapPerZone = self.cachedGemMapPerZone,
	}

	return saveData
end

function GemSpawner:trySpawnGem()
	if self.gem then
		return
	end

	if self.respawnExpiree > ServerMod.step then
		return
	end

	local zoneClass = self.user.home.zoneManager.currZoneClass

	local gemData = self.cachedGemMapPerZone[zoneClass]
	if not gemData then
		gemData = {
			gemClass = self:rollGemClass(),

			-- gem metadata (filled in later)
			variationScale = nil,
			health = nil,
			maxHealth = nil,
		}
	end

	self:addGem(gemData)
end

function GemSpawner:addLuckWeights(gemProbMap)
	local totalLuck = self.user.home.plotManager:getTotalLuck()

	local luckDebuff = 0.05 -- 0.1

	for gemClass, weight in pairs(gemProbMap) do
		local gemStats = GemInfo:getMeta(gemClass)
		local rating = gemStats["rating"]
		if not rating then
			warn("NO RATING FOR GEM: ", gemClass)
			rating = "Common"
		end
		local luckMultiplier = totalLuck * RatingInfo.ratingLuckMultiplier[rating]

		local luckWeightBuff = weight * luckMultiplier * luckDebuff
		gemProbMap[gemClass] = weight + luckWeightBuff
	end
end

function GemSpawner:rollGemClass()
	local zoneClass = self.user.home.zoneManager.currZoneClass
	local zoneStats = ZoneInfo:getMeta(zoneClass)

	local gemProbMap = Common.deepCopy(zoneStats["gemProbMap"])
	self:addLuckWeights(gemProbMap)

	local chosenGemClass = Common.rollFromProbMap(gemProbMap)

	return chosenGemClass
end

function GemSpawner:clearCachedGem()
	self.cachedGemMapPerZone[self.user.home.zoneManager.currZoneClass] = nil
end

function GemSpawner:addGem(data)
	local gemClass = data["gemClass"]

	local gemName = "GEM_" .. Common.getGUID()

	local offsetFrame = CFrame.new(Common.getRandomFlatDir() * Common.randomBetween(0.5, 4))

	local gemStats = GemInfo:getMeta(gemClass)

	if not data["variationScale"] then
		local variationScaleList = gemStats.variationScale
		local variationScale = Common.randomBetween(variationScaleList[1], variationScaleList[2])
		data["variationScale"] = variationScale
	end

	if not data["health"] then
		local maxHealth = gemStats.health * data["variationScale"]
		data["health"] = maxHealth
		data["maxHealth"] = maxHealth
	end

	if gemStats["isEggGem"] then
		data["mutationClass"] = self.user.home.probManager:generateMutationClass()
	end

	local gemData = {
		owner = self,
		gemClass = gemClass,
		gemName = gemName,
		firstFrame = self.currFrame * offsetFrame,

		health = data["health"],
		maxHealth = data["maxHealth"],
		variationScale = data["variationScale"],
	}
	-- add the rest of the metadata
	for k, v in pairs(data) do
		gemData[k] = v
	end

	local gem = Gem.new(gemData)
	gem:init()
	self.gem = gem

	self.user.home.gemManager.gems[gemName] = gem
end

function GemSpawner:destroy()
	if self.destroyed then
		warn("ALREADY DESTROYED USER HUH: ", self.name)
		return
	end
	self.destroyed = true

	if self.gem then
		self.gem:destroy({
			waitTimer = 0,
		})
	end

	ServerMod:FireAllClients("removeGemSpawner", {
		gemSpawnerName = self.gemSpawnerName,
	})

	self.user.home.gemManager.gemSpawners[self.gemSpawnerName] = nil
end

return GemSpawner
