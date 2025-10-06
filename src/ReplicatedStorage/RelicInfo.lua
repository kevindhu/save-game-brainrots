local RelicInfo = {}

RelicInfo["relicList"] = {
	"Fist1",
	"Speed1",
	"Rich1",
	"Titan1",
	"Angel1",
}

RelicInfo["damageMap"] = {
	["Fist1"] = { 2, 2.5 },
	["Angel1"] = { 1, 1.5 },
}

RelicInfo["coinsMap"] = {
	["Rich1"] = { 1, 1.5 },
}

RelicInfo["attackCountMap"] = {
	["Angel1"] = 10, -- 2,
}

RelicInfo["attackSpeedMap"] = {
	["Speed1"] = { 2.5, 3 },
	["Titan1"] = { 5, 10 },
}

RelicInfo["aliasMap"] = {
	["Fist1"] = "Fist I",
	["Speed1"] = "Speed I",
	["Rich1"] = "Rich I",
	["Titan1"] = "Titan I",
	["Angel1"] = "Angel I",
}

RelicInfo["colorMap"] = {
	["Fist1"] = Color3.fromRGB(255, 0, 0),
	["Speed1"] = Color3.fromRGB(0, 255, 0),
	["Rich1"] = Color3.fromRGB(0, 0, 255),
	["Titan1"] = Color3.fromRGB(255, 255, 0),
	["Angel1"] = Color3.fromRGB(0, 255, 255),
}

RelicInfo["imageMap"] = {
	["Fist1"] = "rbxassetid://128681941127773",
	["Speed1"] = "rbxassetid://94894821715777",
	["Rich1"] = "rbxassetid://89899072506076",
	["Titan1"] = "rbxassetid://14782788955",
	["Angel1"] = "rbxassetid://95871347822807",
}

RelicInfo["sellPriceMap"] = {
	["Fist1"] = 100,
	["Speed1"] = 200,
	["Rich1"] = 300,
	["Titan1"] = 400,
	["Angel1"] = 500,
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
