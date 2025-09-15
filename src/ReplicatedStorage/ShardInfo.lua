local ShardInfo = {}

local Common = require(game.ReplicatedStorage.Common)

ShardInfo["shards"] = {
	["Shard1"] = {
		coinsValue = 5,
	},
	["Shard2"] = {
		coinsValue = 10,
	},

	["GiantShard1"] = {
		coinsValue = 100,
	},

	["SpecEgg1Shard"] = {
		coinsValue = 10,
		eggClass = "SpecEgg1",
	},
}

function ShardInfo:getMeta(itemClass, noWarn)
	self.categoryList = {
		"shards",
	}

	return Common.getInfoMeta(self, itemClass, noWarn)
end

return ShardInfo
