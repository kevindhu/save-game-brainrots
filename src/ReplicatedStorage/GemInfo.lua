local GemInfo = {}

local Common = require(game.ReplicatedStorage.Common)

GemInfo["imageMap"] = {
	["Gem1"] = "rbxassetid://116833654211082",
	["Gem2"] = "rbxassetid://79463901517643",
	["Gem3"] = "rbxassetid://102175783632979",
	["Gem4"] = "rbxassetid://102175783632979",
	["GiantGem1"] = "rbxassetid://102175783632979",
	["SpecEgg1Gem"] = "rbxassetid://102175783632979",
}

GemInfo["gems"] = {
	["Gem1"] = {
		health = 100,

		deathCoinsValue = 100,

		variationScale = { 0.8, 1.2 },

		spawnShardProb = 10, -- 10
		deathShardClass = "Shard1",

		rating = "Common",

		attackRadius = 3,

		coinMultiplier = 1,
	},
	["Gem2"] = {
		health = 150,
		deathCoinsValue = 100,

		variationScale = { 0.8, 1.2 },

		spawnShardProb = 10,
		deathShardClass = "Shard2",

		rating = "Common",

		attackRadius = 3.5,

		coinMultiplier = 1.1,
	},
	["Gem3"] = {
		health = 200,
		deathCoinsValue = 500,

		variationScale = { 0.8, 1.2 },

		spawnShardProb = 10,
		deathShardClass = "Shard2",

		rating = "Common",

		attackRadius = 3.5,

		coinMultiplier = 1.2,
	},
	["Gem4"] = {
		health = 250,
		deathCoinsValue = 600,

		variationScale = { 0.8, 1.2 },

		spawnShardProb = 10,
		deathShardClass = "Shard2",

		rating = "Common",

		attackRadius = 3.5,

		coinMultiplier = 1.2,
	},
	["GiantGem1"] = {
		health = 1000, -- 1000
		deathCoinsValue = 1000,

		isGiant = true,

		variationScale = { 1.6, 2 },

		spawnShardProb = 100,
		deathShardClass = "GiantShard1",
		deathShardCount = 10,

		rating = "Common",

		attackRadius = 12,

		coinMultiplier = 1.5,
	},

	["SpecEgg1Gem"] = {
		health = 150,
		deathCoinsValue = 500,

		isEggGem = true,

		variationScale = { 0.8, 1.3 },

		spawnShardProb = 100,
		deathShardClass = "SpecEgg1Shard",

		rating = "Common",

		attackRadius = 3,

		coinMultiplier = 1.5,
	},
}

function GemInfo:getMeta(itemClass, noWarn)
	self.categoryList = {
		"gems",
	}

	return Common.getInfoMeta(self, itemClass, noWarn)
end

return GemInfo
