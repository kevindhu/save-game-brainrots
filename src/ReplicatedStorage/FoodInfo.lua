local FoodInfo = {}

FoodInfo["fullFoodList"] = {
	"Snack",
	"Cake",
	"SuperFood",
	"PullFood1",
	"PullFood2",
	"SpeedFood1",
	"SpeedFood2",
}

FoodInfo["aliasMap"] = {
	["Snack"] = "Snack",
	["Cake"] = "Cake",
	["SuperFood"] = "Super Food",
	["PullFood1"] = "Pull Food 1",
	["SpeedFood1"] = "Speed Food 1",
	["PullFood2"] = "Pull Food 2",
	["SpeedFood2"] = "Speed Food 2",
}

FoodInfo["durationMap"] = {
	["Snack"] = 60 * 2,
	["Cake"] = 60 * 2,
	["SuperFood"] = 60 * 3,
	["PullFood1"] = 60 * 10,
	["SpeedFood1"] = 60 * 5,
}

FoodInfo["rebirthLevelMap"] = {
	["Snack"] = 1,
	["Cake"] = 1,
	["SuperFood"] = 2,
	["PullFood1"] = 2,
	["SpeedFood1"] = 2,
}

FoodInfo["strengthIncreaseMultiplierMap"] = {
	["Snack"] = 1.5,
	["Cake"] = 2,
	["SuperFood"] = 2,
}

FoodInfo["pullStrengthMultiplierMap"] = {
	["PullFood1"] = 1.5,
	["PullFood2"] = 2,
}

FoodInfo["pullSpeedIncreaseMap"] = {
	["SpeedFood1"] = 1.5,
	["SpeedFood2"] = 2,
}

FoodInfo["descriptionMap"] = {
	["Snack"] = "Tastes great!",
	["Cake"] = "The cake is a lie!",
	["SuperFood"] = "The best food in the world!",
	["PullFood1"] = "Increases pull strength!",
	["SpeedFood1"] = "Increases pull speed!",
	["PullFood2"] = "Increases pull strength!",
	["SpeedFood2"] = "Increases pull speed!",
}

-- VENDOR SPECIFIC DATA
FoodInfo["vendorFoodList"] = {
	"Snack",
	"Cake",
	"SuperFood",
	"PullFood1",
	"SpeedFood1",
}

FoodInfo["vendorPriceMap"] = {
	["Snack"] = 1000,
	["Cake"] = 2000,
	["SuperFood"] = 5000,
	["PullFood1"] = 20000,
	["SpeedFood1"] = 50000,

	["PullFood2"] = 100000,
	["SpeedFood2"] = 300000,
}

function FoodInfo:calculateSellPrice(data)
	local foodClass = data["foodClass"]
	local foodStats = self:getMeta(foodClass)

	local sellPrice = foodStats["price"] * 0.1
	return sellPrice
end

function FoodInfo:init()
	self.food = {}
	for _, foodClass in pairs(self.fullFoodList) do
		local foodData = {}
		foodData["price"] = self.vendorPriceMap[foodClass]
		foodData["alias"] = self.aliasMap[foodClass]
		foodData["duration"] = self.durationMap[foodClass]
		foodData["rebirthLevel"] = self.rebirthLevelMap[foodClass]
		foodData["description"] = self.descriptionMap[foodClass]

		foodData["strengthIncreaseMultiplier"] = self.strengthIncreaseMultiplierMap[foodClass]
		foodData["pullStrengthMultiplier"] = self.pullStrengthMultiplierMap[foodClass]
		foodData["pullSpeedIncrease"] = self.pullSpeedIncreaseMap[foodClass]

		self.food[foodClass] = foodData
	end
end

function FoodInfo:getMeta(itemClass, noWarn)
	local Common = require(game.ReplicatedStorage.Common)
	self.categoryList = {
		"food",
	}
	return Common.getInfoMeta(self, itemClass, noWarn)
end

FoodInfo:init()

return FoodInfo
