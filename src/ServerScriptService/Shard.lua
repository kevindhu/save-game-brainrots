local ServerMod = require(script.Parent.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local ShardInfo = require(game.ReplicatedStorage.ShardInfo)

local Shard = {}
Shard.__index = Shard

function Shard.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	setmetatable(u, Shard)
	return u
end

function Shard:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end
	self.user = self.owner.user

	self.shardStats = ShardInfo:getMeta(self.shardClass)

	if not self.noAnimate then
		ServerMod:FireClient(self.user.player, "newSoundMod", {
			soundClass = "SproutPop2",
			volume = 1,
		})
	end

	for _, user in pairs(ServerMod.users) do
		self:sync(user)
	end

	routine(function()
		wait(5)
		if self.user.home.shopManager:checkOwnsGamepass("AutoCollectShards") then
			self:collect()
		end
	end)
end

function Shard:sync(otherUser)
	if not otherUser.initialized then
		return
	end

	ServerMod:FireClient(otherUser.player, "addShard", {
		shardName = self.shardName,
		shardClass = self.shardClass,

		creationTimestamp = self.creationTimestamp,

		gemSpawnerName = self.gemSpawnerName,

		mutationClass = self.mutationClass,

		userName = self.user.name,

		startPos = self.startPos,
		currPos = self.currPos,

		noAnimate = self.noAnimate,
	})
end

function Shard:collect()
	if self.collected then
		return
	end
	self.collected = true

	-- warn("COLLECTING SHARD: ", self.shardName)

	self.user.home.itemStash:updateItemCount({
		itemName = "Coins",
		count = self.shardStats["coinsValue"],
	})

	local eggClass = self.shardStats["eggClass"]
	if eggClass then
		-- TODO: carry mutation from the shard
		self.user.home.itemStash:addEgg({
			eggClass = eggClass,
			mutationClass = self.mutationClass,
		})
	end

	self:destroy()
end

function Shard:destroy()
	if self.destroyed then
		warn("ALREADY DESTROYED USER HUH: ", self.name)
		return
	end
	self.destroyed = true

	self.owner.shards[self.shardName] = nil

	ServerMod:FireAllClients("removeShard", {
		shardName = self.shardName,
	})
end

function Shard:getSaveData()
	local currFrame = CFrame.new(self.currPos)
	local baseFrame = self.user.home.plotManager.plotBaseFrame:inverse() * currFrame

	return {
		shardName = self.shardName,
		gemSpawnerName = self.gemSpawnerName,

		shardClass = self.shardClass,
		mutationClass = self.mutationClass,

		currFrameComp = { baseFrame:GetComponents() },
	}
end

return Shard
