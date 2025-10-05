local RatingInfo = {}

RatingInfo["ratingList"] = {
	"Secret",
	"Mythic",
	"Legendary",
	"Epic",
	"Rare",
	"Uncommon",
	"Common",
}

RatingInfo["ratingColorMap"] = {
	["Secret"] = Color3.fromRGB(0, 0, 0), -- Gold (Legendary)
	["Mythic"] = Color3.fromRGB(226, 43, 86), -- Purple (Epic)
	["Legendary"] = Color3.fromRGB(255, 225, 0), -- Red-Orange (Rare)
	["Epic"] = Color3.fromRGB(223, 82, 255), -- Blue (Uncommon)
	["Rare"] = Color3.fromRGB(50, 205, 50), -- Green (Common)
	["Uncommon"] = Color3.fromRGB(150, 255, 237), -- Gray (Basic)
	["Common"] = Color3.fromRGB(242, 242, 242), -- Dark Gray (Poor)
}

RatingInfo["laserThicknessMap"] = {
	["Secret"] = 0.5, -- 5
	["Cosmic"] = 0.4,
	["Mythic"] = 0.3,
	["Legendary"] = 0.24,
	["Epic"] = 0.23,
	["Rare"] = 0.22,
	["Uncommon"] = 0.21,
	["Common"] = 0.2,
}

RatingInfo["ratingMaxLevelMap"] = {
	["Secret"] = 200,
	["Mythic"] = 175,
	["Legendary"] = 150,
	["Epic"] = 125,
	["Rare"] = 100,
	["Uncommon"] = 75,
	["Common"] = 50,
}

RatingInfo["ratingGradientColorMap"] = {
	["Secret"] = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	}),
	["Mythic"] = ColorSequence.new(Color3.fromRGB(255, 24, 24)),
	["Legendary"] = ColorSequence.new(Color3.fromRGB(255, 225, 0)),
	["Epic"] = ColorSequence.new(Color3.fromRGB(231, 122, 255)),
	["Rare"] = ColorSequence.new(Color3.fromRGB(90, 255, 90)),
	["Uncommon"] = ColorSequence.new(Color3.fromRGB(182, 246, 235)),
	["Common"] = ColorSequence.new(Color3.fromRGB(242, 242, 242)),
}

return RatingInfo
