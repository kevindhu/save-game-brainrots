local RelicInfo = {}

RelicInfo["relicList"] = {
	"Fist1",
	"Fist2",
	"Fist3",
	"Speed1",
	"Speed2",
	"Speed3",
	"Rich1",
	"Rich2",
	"Rich3",
	"Titan1",
	"Titan2",
	"Titan3",
	"Angel1",
	"Angel2",
	"Angel3",
}

RelicInfo["damageMap"] = {
	["Fist1"] = { 1.1, 1.15 },
	["Fist2"] = { 1.2, 1.3 },
	["Fist3"] = { 1.35, 1.45 },
	["Angel1"] = { 0.8, 1 },
	["Angel2"] = { 0.75, 0.95 },
	["Angel3"] = { 0.7, 0.9 },
}

RelicInfo["coinsMap"] = {
	["Rich1"] = { 1.1, 1.2 },
	["Rich2"] = { 1.25, 1.35 },
	["Rich3"] = { 1.4, 1.5 },
}

RelicInfo["attackCountMap"] = {
	["Angel1"] = 2,
	["Angel2"] = 3,
	["Angel3"] = 4,
}

RelicInfo["attackSpeedMap"] = {
	["Fist1"] = { 0, 0 },
	["Fist2"] = { 0.05, 0.05 },
	["Fist3"] = { 0.1, 0.1 },
	["Speed1"] = { 1.1, 1.2 },
	["Speed2"] = { 1.25, 1.35 },
	["Speed3"] = { 1.45, 1.55 },
	["Titan1"] = { 5, 6 },
	["Titan2"] = { 6, 8 },
	["Titan3"] = { 8, 10 },
}

RelicInfo["critChanceMap"] = {
	["Fist1"] = 0,
	["Fist2"] = 0.02,
	["Fist3"] = 0.05,
}

RelicInfo["healthMap"] = {
	["Titan1"] = { 1.1, 1.2 },
	["Titan2"] = { 1.25, 1.35 },
	["Titan3"] = { 1.4, 1.5 },
}

RelicInfo["aliasMap"] = {
	["Fist1"] = "Fist I",
	["Fist2"] = "Fist II",
	["Fist3"] = "Fist III",
	["Speed1"] = "Speed I",
	["Speed2"] = "Speed II",
	["Speed3"] = "Speed III",
	["Rich1"] = "Rich I",
	["Rich2"] = "Rich II",
	["Rich3"] = "Rich III",
	["Titan1"] = "Titan I",
	["Titan2"] = "Titan II",
	["Titan3"] = "Titan III",
	["Angel1"] = "Angel I",
	["Angel2"] = "Angel II",
	["Angel3"] = "Angel III",
}

RelicInfo["colorMap"] = {
	["Fist1"] = Color3.fromRGB(255, 0, 0),
	["Fist2"] = Color3.fromRGB(255, 0, 0),
	["Fist3"] = Color3.fromRGB(255, 0, 0),
	["Speed1"] = Color3.fromRGB(0, 255, 0),
	["Speed2"] = Color3.fromRGB(0, 255, 0),
	["Speed3"] = Color3.fromRGB(0, 255, 0),
	["Rich1"] = Color3.fromRGB(0, 0, 255),
	["Rich2"] = Color3.fromRGB(0, 0, 255),
	["Rich3"] = Color3.fromRGB(0, 0, 255),
	["Titan1"] = Color3.fromRGB(255, 255, 0),
	["Titan2"] = Color3.fromRGB(255, 255, 0),
	["Titan3"] = Color3.fromRGB(255, 255, 0),
	["Angel1"] = Color3.fromRGB(0, 255, 255),
	["Angel2"] = Color3.fromRGB(0, 255, 255),
	["Angel3"] = Color3.fromRGB(0, 255, 255),
}

RelicInfo["imageMap"] = {
	["Fist1"] = "rbxassetid://128681941127773",
	["Fist2"] = "rbxassetid://128681941127773",
	["Fist3"] = "rbxassetid://128681941127773",
	["Speed1"] = "rbxassetid://94894821715777",
	["Speed2"] = "rbxassetid://94894821715777",
	["Speed3"] = "rbxassetid://94894821715777",
	["Rich1"] = "rbxassetid://89899072506076",
	["Rich2"] = "rbxassetid://89899072506076",
	["Rich3"] = "rbxassetid://89899072506076",
	["Titan1"] = "rbxassetid://100897107067509",
	["Titan2"] = "rbxassetid://100897107067509",
	["Titan3"] = "rbxassetid://100897107067509",
	["Angel1"] = "rbxassetid://95871347822807",
	["Angel2"] = "rbxassetid://95871347822807",
	["Angel3"] = "rbxassetid://95871347822807",
}

RelicInfo["sellPriceMap"] = {
	["Fist1"] = 100,
	["Fist2"] = 250,
	["Fist3"] = 400,
	["Speed1"] = 100,
	["Speed2"] = 250,
	["Speed3"] = 400,
	["Rich1"] = 100,
	["Rich2"] = 250,
	["Rich3"] = 400,
	["Titan1"] = 100,
	["Titan2"] = 250,
	["Titan3"] = 400,
	["Angel1"] = 100,
	["Angel2"] = 250,
	["Angel3"] = 400,
}

function RelicInfo:getTotalPower(data)
	-- local relicClass = data["relicClass"]

	local coins = data["coins"]
	local damage = data["damage"]
	local attackSpeed = data["attackSpeed"]
	local attackCount = data["attackCount"]

	local total = coins + damage + attackSpeed + attackCount

	return math.floor(total * 100)
end

function RelicInfo:init()
	self.relics = {}

	for _, relicClass in pairs(self.relicList) do
		local relicData = {
			alias = self.aliasMap[relicClass],
			image = self.imageMap[relicClass],
			color = self.colorMap[relicClass],

			-- stats
			damageRange = self.damageMap[relicClass],
			coinsRange = self.coinsMap[relicClass],
			attackSpeedRange = self.attackSpeedMap[relicClass],
			attackCount = self.attackCountMap[relicClass],
			critChance = self.critChanceMap[relicClass],
			healthRange = self.healthMap[relicClass],
		}
		self.relics[relicClass] = relicData
	end
end

function RelicInfo:calculateSellPrice(data)
	local relicClass = data["relicClass"]
	local sellPrice = self.sellPriceMap[relicClass]
	return sellPrice
end

function RelicInfo:getMeta(itemClass, noWarn)
	local Common = require(game.ReplicatedStorage.Common)
	self.categoryList = {
		"relics",
	}
	return Common.getInfoMeta(self, itemClass, noWarn)
end

RelicInfo:init()

return RelicInfo
