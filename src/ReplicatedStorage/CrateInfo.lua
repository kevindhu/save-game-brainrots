local CrateInfo = {
	crates = {},
}

local Common = require(game.ReplicatedStorage.Common)

CrateInfo["crateList"] = {
	"Crate1",
	"Crate2",
	"Crate3",

	"LuckyBlockCrate",
}

CrateInfo["relicProbMapMapping"] = {
	["Crate1"] = {
		Fist1 = 1,
	},
	["Crate2"] = {
		Fist1 = 10,
		Speed1 = 10,
	},
	["Crate3"] = {
		Fist1 = 5,
		Speed1 = 10,
		Rich1 = 10,
		Titan1 = 10,
		Angel1 = 10,
	},

	["LuckyBlockCrate"] = {
		Fist1 = 5,
		Speed1 = 10,
		Rich1 = 10,
		Titan1 = 10,
		Angel1 = 10,
	},
}

CrateInfo["imageMap"] = {
	["Crate1"] = "rbxassetid://105347365894761",
	["Crate2"] = "rbxassetid://77670058674209",
	["Crate3"] = "rbxassetid://116080005450512",

	["LuckyBlockCrate"] = "rbxassetid://95448593603129",
}

CrateInfo["aliasMap"] = {
	["Crate1"] = "Crate 1",
	["Crate2"] = "Crate 2",
	["Crate3"] = "Crate 3",

	["LuckyBlockCrate"] = "Lucky Block",
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
			description = "A crate with random relics",

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
