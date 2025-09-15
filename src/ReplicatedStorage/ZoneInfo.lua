local ZoneInfo = {}

local Common = require(game.ReplicatedStorage.Common)

ZoneInfo["zoneList"] = {
	"Zone1",
	"Zone2",
	"Zone3",
}

ZoneInfo["zones"] = {
	["Zone1"] = {
		alias = "Common Spawner",
		description = "Starter zone",
		spawnerImage = "rbxassetid://116833654211082",
		gemProbMap = {
			Gem1 = 100,
			Gem2 = 100,
			SpecEgg1Gem = 5000000, -- 5
			GiantGem1 = 0.1, -- 0.1,
		},

		coinMultiplierRatio = 1,

		index = 1,

		unlockPrice = 0,
	},
	["Zone2"] = {
		alias = "Rare Spawner",
		description = "Starter zone",
		spawnerImage = "rbxassetid://102175783632979",
		gemProbMap = {
			Gem2 = 10,
			Gem3 = 100,
			Gem4 = 100,
		},

		coinMultiplierRatio = 1.1,

		index = 2,

		unlockPrice = 100,
	},
	["Zone3"] = {
		alias = "Epic Spawner",
		description = "Starter zone",
		spawnerImage = "rbxassetid://136553284725379",
		gemProbMap = {
			Gem1 = 10,
			Gem2 = 10,
			Gem3 = 100,
		},

		coinMultiplierRatio = 1.2,

		index = 3,

		unlockPrice = 100,
	},
}

function ZoneInfo:getMeta(itemClass, noWarn)
	self.categoryList = {
		"zones",
	}

	return Common.getInfoMeta(self, itemClass, noWarn)
end

return ZoneInfo
