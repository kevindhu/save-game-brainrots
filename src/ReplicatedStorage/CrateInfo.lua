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
		Fist1 = 10,
		Fist2 = 3,
		Fist3 = 1,
		Speed1 = 10,
		Speed2 = 3,
		Speed3 = 1,
		Rich1 = 10,
		Rich2 = 3,
		Rich3 = 1,
		Titan1 = 10,
		Titan2 = 3,
		Titan3 = 1,
		Angel1 = 10,
		Angel2 = 3,
		Angel3 = 1,
	},
	["Crate2"] = {
		Fist1 = 8,
		Fist2 = 6,
		Fist3 = 4,
		Speed1 = 8,
		Speed2 = 6,
		Speed3 = 4,
		Rich1 = 8,
		Rich2 = 6,
		Rich3 = 4,
		Titan1 = 8,
		Titan2 = 6,
		Titan3 = 4,
		Angel1 = 8,
		Angel2 = 6,
		Angel3 = 4,
	},
	["Crate3"] = {
		Fist1 = 5,
		Fist2 = 6,
		Fist3 = 7,
		Speed1 = 5,
		Speed2 = 6,
		Speed3 = 7,
		Rich1 = 5,
		Rich2 = 6,
		Rich3 = 7,
		Titan1 = 5,
		Titan2 = 6,
		Titan3 = 7,
		Angel1 = 5,
		Angel2 = 6,
		Angel3 = 7,
	},
	["LuckyBlockCrate"] = {
		Fist1 = 4,
		Fist2 = 7,
		Fist3 = 9,
		Speed1 = 4,
		Speed2 = 7,
		Speed3 = 9,
		Rich1 = 4,
		Rich2 = 7,
		Rich3 = 9,
		Titan1 = 4,
		Titan2 = 7,
		Titan3 = 9,
		Angel1 = 4,
		Angel2 = 7,
		Angel3 = 9,
	},
}

CrateInfo["imageMap"] = {
	["Crate1"] = "rbxassetid://88974090917907",
	["Crate2"] = "rbxassetid://130048882530706",
	["Crate3"] = "rbxassetid://81519367488402",

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

CrateInfo["ratingLuckMultiplier"] = {
	["Secret"] = 1.11, -- 5
	["Cosmic"] = 1.1,
	["Mythic"] = 1,
	["Legendary"] = 0.5,
	["Epic"] = 0.2,
	["Rare"] = 0.05,
	["Uncommon"] = 0.00005,
	["Common"] = 0.0,
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
