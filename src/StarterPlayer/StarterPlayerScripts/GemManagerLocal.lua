local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local GemInfo = require(game.ReplicatedStorage.GemInfo)

local Gem = require(playerScripts.GemLocal)
local Shard = require(playerScripts.ShardLocal)

local GemManager = {
	shardCollectCount = 1,
	shardCollectExpiree = nil,
}
GemManager.__index = GemManager

function GemManager:init() end

function GemManager:newGem(data)
	local gemName = data.gemName
	if ClientMod.gems[gemName] then
		return
	end

	local gem = Gem.new(data)
	gem:init()
	ClientMod.gems[gemName] = gem
end

function GemManager:updateGemData(data)
	local gemName = data["gemName"]
	local gem = ClientMod.gems[gemName]
	if not gem then
		warn("!!! NO PET FOUND TO UPDATE DATA: ", gemName)
		return
	end

	gem:updateData(data)

	-- try update the best gem for this plot
	self:updateBestGemForPlot(gem.plotName)
end

function GemManager:removeGem(data)
	local gemName = data["gemName"]
	local gem = ClientMod.gems[gemName]
	if not gem then
		return
	end
	gem:destroy(data)
end

local SHARD_MAX_INDEX = 20
function GemManager:getShardCollectSpeed()
	self.shardCollectCount += 1
	self.shardCollectExpiree = ClientMod.step + 60 * 2

	self.shardCollectCount = self.shardCollectCount % SHARD_MAX_INDEX

	local finalSpeed = 1 + (self.shardCollectCount / SHARD_MAX_INDEX) * 1

	return finalSpeed
end

function GemManager:tick()
	self:tickShardCollectExpiree()
end

function GemManager:tickShardCollectExpiree()
	if self.shardCollectExpiree and ClientMod.step > self.shardCollectExpiree then
		self.shardCollectCount = 1
		self.shardCollectExpiree = nil
	end
end

function GemManager:addShard(data)
	local shardName = data["shardName"]
	local shard = ClientMod.shards[shardName]
	if shard then
		-- warn("!!! SHARD ALREADY EXISTS: ", shardName)
		return
	end

	shard = Shard.new(data)
	shard:init()
	ClientMod.shards[shardName] = shard

	ClientMod.placeManager:refreshAllPrompts()
end

function GemManager:removeShard(data)
	local shardName = data["shardName"]
	local shard = ClientMod.shards[shardName]
	if not shard then
		warn("!!! SHARD NOT FOUND: ", shardName)
		return
	end

	shard:destroy()
	ClientMod.shards[shardName] = nil
end

function GemManager:removeGemSpawner(data)
	local gemSpawnerName = data["gemSpawnerName"]

	for _, shard in pairs(ClientMod.shards) do
		if shard.gemSpawnerName == gemSpawnerName then
			shard:destroy()
		end
	end
end

GemManager:init()

return GemManager
