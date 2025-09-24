local CrateInfo = {
	crates = {},
}

local Common = require(game.ReplicatedStorage.Common)

CrateInfo["crateList"] = {
	"Crate1",
	"Crate2",
	"Crate3",

	-- cannot buy these crates
	"SpecCrate1",
	-- "SpecCrate2",

	"LuckyBlockCrate",
}

CrateInfo["relicProbMapMapping"] = {
	["Crate1"] = {
		Relic1 = 1,
	},
	["Crate2"] = {
		Relic1 = 10,
		Relic2 = 10,
	},
	["Crate3"] = {
		Relic1 = 5,
		Relic2 = 10,
	},

	["LuckyBlockCrate"] = {
		OctopusBlueberry = 10,
		SaltCombined = 10,

		TimCheese = 10,
		GiraffeWatermelon = 10,
		MonkeyPineapple = 10,
		OwlAvocado = 10,
		OrangeDunDun = 10,
		CowPlanet = 10,
	},

	["SpecCrate1"] = {
		Ballerina = 10,
	},
}

CrateInfo["imageMap"] = {
	["Crate1"] = "rbxassetid://105347365894761",
	["Crate2"] = "rbxassetid://77670058674209",
	["Crate3"] = "rbxassetid://116080005450512",

	["SpecCrate1"] = "rbxassetid://116833654211082",
	["LuckyBlockCrate"] = "rbxassetid://95448593603129",
}

CrateInfo["aliasMap"] = {
	["Crate1"] = "Crate 1",
	["Crate2"] = "Crate 2",
	["Crate3"] = "Crate 3",

	["SpecCrate1"] = "SpecCrate 1",
	["LuckyBlockCrate"] = "Lucky Block",
}

CrateInfo["hatchTimeMap"] = {
	["Crate1"] = 2, -- 1
	["Crate2"] = 20, -- 2
	["Crate3"] = 30, -- 3

	["SpecCrate1"] = 10,
	["LuckyBlockCrate"] = 5,
}

-- do not contain gem crates
CrateInfo["stockCrateList"] = {
	"Crate1",
	"Crate2",
	"Crate3",
}

CrateInfo["stockVariationCountMap"] = {
	["Crate1"] = { 3, 10 },
	["Crate2"] = { 2, 10 },
	["Crate3"] = { 1, 1 },
}

CrateInfo["stockPriceMap"] = {
	["Crate1"] = 100,
	["Crate2"] = 1000,
	["Crate3"] = 10000,
}

CrateInfo["stockProbCountMap"] = {
	["Crate1"] = 100,
	["Crate2"] = 100,
	["Crate3"] = 100,
}

function CrateInfo:init()
	for _, crateClass in pairs(self.crateList) do
		local crateData = {
			variationCount = self.stockVariationCountMap[crateClass],
			probCount = self.stockProbCountMap[crateClass],
			price = self.stockPriceMap[crateClass],
			alias = self.aliasMap[crateClass],
			hatchTime = self.hatchTimeMap[crateClass],
			description = "An crate",

			relicProbMap = self.relicProbMapMapping[crateClass],
			image = self.imageMap[crateClass],
		}
		self.crates[crateClass] = crateData
	end
end

function CrateInfo:getMeta(itemClass, noWarn)
	self.categoryList = {
		"crates",
	}

	return Common.getInfoMeta(self, itemClass, noWarn)
end

CrateInfo:init()

return CrateInfo
