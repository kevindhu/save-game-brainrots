local EggInfo = {
	eggs = {},
}

local Common = require(game.ReplicatedStorage.Common)

EggInfo["eggList"] = {
	"Egg1",
	"Egg2",
	"Egg3",
	"Egg4",
	"Egg5",

	-- cannot buy these eggs
	"SpecEgg1",
	-- "SpecEgg2",

	"LuckyBlockEgg",
}

EggInfo["petProbMapMapping"] = {
	["Egg1"] = {
		CappuccinoAssassino = 1,
		TungTungSahur = 1,
		TrippiTroppi = 1,
		Boneca = 1,
	},
	["Egg2"] = {
		LiriLira = 10,
		Ballerina = 10,
		FrigoCamelo = 10,
		ChimpBanana = 10,
		TaTaTaSahur = 10,
	},
	["Egg3"] = {
		CapybaraCoconut = 10,
		DolphinBanana = 10,
		FishCatLegs = 10,
		GooseBomber = 10,
		TralaleloTralala = 10,
	},
	["Egg4"] = {
		GlorboFruttoDrillo = 10,
		RhinoToast = 10,
		BrrBrrPatapim = 10,
		ElephantCoconut = 10,
	},
	["Egg5"] = {
		TimCheese = 10,
		GiraffeWatermelon = 10,
		MonkeyPineapple = 10,
		OwlAvocado = 10,
		OrangeDunDun = 10,
		CowPlanet = 10,
	},
	["Egg6"] = {
		OctopusBlueberry = 10,
		SaltCombined = 10,
		GorillaWatermelon = 10,
		-- GrapeSquid = 10,
	},
	["LuckyBlockEgg"] = {
		OctopusBlueberry = 10,
		SaltCombined = 10,

		TimCheese = 10,
		GiraffeWatermelon = 10,
		MonkeyPineapple = 10,
		OwlAvocado = 10,
		OrangeDunDun = 10,
		CowPlanet = 10,
	},

	["SpecEgg1"] = {
		Ballerina = 10,
	},
}

EggInfo["imageMap"] = {
	["Egg1"] = "rbxassetid://105347365894761",
	["Egg2"] = "rbxassetid://77670058674209",
	["Egg3"] = "rbxassetid://116080005450512",
	["Egg4"] = "rbxassetid://135952779384390",
	["Egg5"] = "rbxassetid://140730304414555",

	["SpecEgg1"] = "rbxassetid://116833654211082",
	["LuckyBlockEgg"] = "rbxassetid://95448593603129",
}

EggInfo["aliasMap"] = {
	["Egg1"] = "Egg 1",
	["Egg2"] = "Egg 2",
	["Egg3"] = "Egg 3",
	["Egg4"] = "Egg 4",
	["Egg5"] = "Egg 5",

	["SpecEgg1"] = "SpecEgg 1",
	["LuckyBlockEgg"] = "Lucky Block",
}

EggInfo["hatchTimeMap"] = {
	["Egg1"] = 2, -- 1
	["Egg2"] = 20, -- 2
	["Egg3"] = 30, -- 3
	["Egg4"] = 40, -- 4
	["Egg5"] = 50, -- 5

	["SpecEgg1"] = 10,
	["LuckyBlockEgg"] = 5,
}

-- do not contain gem eggs
EggInfo["stockEggList"] = {
	"Egg1",
	"Egg2",
	"Egg3",
	"Egg4",
	"Egg5",
}

EggInfo["stockVariationCountMap"] = {
	["Egg1"] = { 3, 10 },
	["Egg2"] = { 2, 10 },
	["Egg3"] = { 1, 1 },
	["Egg4"] = { 1, 1 },
	["Egg5"] = { 1, 1 },
}

EggInfo["stockPriceMap"] = {
	["Egg1"] = 100,
	["Egg2"] = 1000,
	["Egg3"] = 10000,
	["Egg4"] = 100000,
	["Egg5"] = 1000000,
}

EggInfo["stockProbCountMap"] = {
	["Egg1"] = 100,
	["Egg2"] = 100,
	["Egg3"] = 100,
	["Egg4"] = 100,
	["Egg5"] = 100,
}

function EggInfo:init()
	for _, eggClass in pairs(self.eggList) do
		local eggData = {
			variationCount = self.stockVariationCountMap[eggClass],
			probCount = self.stockProbCountMap[eggClass],
			price = self.stockPriceMap[eggClass],
			alias = self.aliasMap[eggClass],
			hatchTime = self.hatchTimeMap[eggClass],
			description = "An egg",

			petProbMap = self.petProbMapMapping[eggClass],
			image = self.imageMap[eggClass],
		}
		self.eggs[eggClass] = eggData
	end
end

function EggInfo:getMeta(itemClass, noWarn)
	self.categoryList = {
		"eggs",
	}

	return Common.getInfoMeta(self, itemClass, noWarn)
end

EggInfo:init()

return EggInfo
