local ServerMod = require(script.Parent.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local GemInfo = require(game.ReplicatedStorage.GemInfo)

local Gem = {}
Gem.__index = Gem

function Gem.new(data)
	local u = {}
	u.data = data

	setmetatable(u, Gem)
	return u
end

function Gem:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end
	self.user = self.owner.user

	self.gemStats = GemInfo:getMeta(self.gemClass)

	self.baseModel = game.ReplicatedStorage.Assets:WaitForChild(self.gemClass)

	self.isGiant = self.gemStats.isGiant
	self.currFrame = self.firstFrame

	if self.isGiant then
		routine(function()
			-- refresh all pet actions to find this gem
			for _, pet in pairs(self.user.home.petManager.pets) do
				pet:findRandomGem()
			end
		end)
	end

	for _, otherUser in pairs(ServerMod.users) do
		self:sync(otherUser)
	end
end

function Gem:updateHealth(delta, pet)
	self.health = math.clamp(self.health + delta, 0, self.maxHealth)

	if self.health <= 0 then
		self:die(pet)
	end
end

function Gem:sync(otherUser)
	ServerMod:FireClient(otherUser.player, "newGem", {
		gemName = self.gemName,
		gemClass = self.gemClass,

		userName = self.user.name,

		currFrame = self.currFrame,

		variationScale = self.variationScale,

		mutationClass = self.mutationClass,

		health = self.health,
		maxHealth = self.maxHealth,
	})
end

function Gem:die(pet)
	self.user.home.itemStash:updateItemCount({
		itemName = "Coins",
		count = self.gemStats["deathCoinsValue"],
	})

	if math.random() * 100 < self.gemStats["spawnShardProb"] then
		routine(function()
			local totalDelay = 0.3 + (pet.petStats["attackDelay"] or 0)
			totalDelay = totalDelay / pet.attackSpeedRatio
			wait(totalDelay)

			local spawnWaitTimer = 0.25
			local spawnCount = self.gemStats["deathShardCount"] or 1
			for i = 1, spawnCount do
				-- add shard to gemspawner
				self.owner:tryAddNewShard({
					shardClass = self.gemStats["deathShardClass"],
					mutationClass = self.mutationClass,
				})
				wait(spawnWaitTimer)
			end
		end)
	end

	self.owner:clearCachedGem()

	self:destroy({
		waitTimer = 1,
	})
end

function Gem:getSaveData()
	return {
		gemClass = self.gemClass,

		-- gem metadata
		variationScale = self.variationScale,
		health = self.health,
		maxHealth = self.maxHealth,
	}
end

function Gem:destroy(data)
	if self.destroyed then
		warn("ALREADY DESTROYED USER HUH: ", self.name)
		return
	end
	self.destroyed = true

	self.user.home.gemManager.gems[self.gemName] = nil

	self.owner:clearGem()

	ServerMod:FireAllClients("removeGem", {
		gemName = self.gemName,
		waitTimer = data["waitTimer"],
	})
end

return Gem
