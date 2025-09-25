local RelicInfo = {}

RelicInfo["relicList"] = {
	"Relic1",
	"Relic2",
}

RelicInfo["damageMap"] = {
	["Relic2"] = { 2, 2.5 },
}

RelicInfo["coinsMap"] = {
	["Relic1"] = { 1, 1.5 },
}

RelicInfo["attackSpeedMap"] = {
	["Relic1"] = { 1, 3 },
	["Relic2"] = { 5, 10 },
}

RelicInfo["aliasMap"] = {
	["Relic1"] = "Relic 1",
	["Relic2"] = "Relic 2",
}

RelicInfo["colorMap"] = {
	["Relic1"] = Color3.fromRGB(232, 90, 90),
	["Relic2"] = Color3.fromRGB(86, 143, 250),
}

RelicInfo["imageMap"] = {
	["Relic1"] = "rbxassetid://60422237", -- fist
	["Relic2"] = "rbxassetid://1178571805", -- fist
}

RelicInfo["sellPriceMap"] = {
	["Relic1"] = 100,
	["Relic2"] = 200,
}

function RelicInfo:init()
	self.relics = {}

	for _, relicClass in pairs(self.relicList) do
		local relicData = {
			alias = self.aliasMap[relicClass],
			damageRange = self.damageMap[relicClass],
			coinsRange = self.coinsMap[relicClass],
			attackSpeedRange = self.attackSpeedMap[relicClass],
			image = self.imageMap[relicClass],
			color = self.colorMap[relicClass],
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
