local RatingInfo = {}

RatingInfo["ratingColorMap"] = {
	["Secret"] = Color3.fromRGB(0, 0, 0), -- Gold (Legendary)
	["Mythic"] = Color3.fromRGB(226, 43, 86), -- Purple (Epic)
	["Legendary"] = Color3.fromRGB(255, 225, 0), -- Red-Orange (Rare)
	["Epic"] = Color3.fromRGB(223, 82, 255), -- Blue (Uncommon)
	["Rare"] = Color3.fromRGB(50, 205, 50), -- Green (Common)
	["Uncommon"] = Color3.fromRGB(150, 255, 237), -- Gray (Basic)
	["Common"] = Color3.fromRGB(242, 242, 242), -- Dark Gray (Poor)
}

RatingInfo["ratingLuckMultiplier"] = {
	["Secret"] = 1.11, -- 5
	["Cosmic"] = 1.1,
	["Mythic"] = 1,
	["Legendary"] = 0.5,
	["Epic"] = 0.2,
	["Rare"] = 0.05,
	["Uncommon"] = 0.00005,
	["Common"] = 0.0,
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
