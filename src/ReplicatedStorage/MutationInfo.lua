local Common = require(game.ReplicatedStorage.Common)

local MutationInfo = {}

MutationInfo["mutations"] = {
	["None"] = {
		alias = "None",
		color = Color3.fromRGB(255, 255, 255),
		colorGradient = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
	},
	["Gold"] = {
		alias = "Gold",
		color = Color3.fromRGB(255, 215, 0),
		colorGradient = ColorSequence.new(Color3.fromRGB(255, 215, 0)),
	},
	["Diamond"] = {
		alias = "Diamond",
		color = Color3.fromRGB(37, 196, 254),
		colorGradient = ColorSequence.new(Color3.fromRGB(37, 196, 254)),
	},
	["Bubblegum"] = {
		alias = "Bubblegum",
		color = Color3.fromRGB(255, 92, 255),
		colorGradient = ColorSequence.new(Color3.fromRGB(255, 182, 255)),
	},
	["Volcanic"] = {
		alias = "Volcanic",
		color = Color3.fromRGB(255, 94, 0),
		colorGradient = ColorSequence.new(Color3.fromRGB(255, 94, 0)),
	},

	["Rainbow"] = {
		alias = "Rainbow",
		color = Color3.fromRGB(255, 86, 86),
		colorGradient = ColorSequence.new(Color3.fromRGB(173, 79, 255)),
	},
}

MutationInfo["damageMultiplierMap"] = {
	["None"] = 1,
	["Gold"] = 1,
	["Diamond"] = 1,
	["Bubblegum"] = 1.5,
	["Volcanic"] = 1,
}

MutationInfo["attackSpeedMultiplierMap"] = {
	["None"] = 1,
	["Gold"] = 1.05,
	["Diamond"] = 1.11,
	["Bubblegum"] = 1.13,
	["Volcanic"] = 1.15,
}

MutationInfo["mutationProbMap"] = {
	None = 5000, -- 1000,

	Gold = 400, -- 1000
	Giant = 100, -- 100

	-- rarest cause best
	Rainbow = 50,
}

MutationInfo["mutationProbMap_TEST"] = {
	None = 1000, -- 1000,

	Gold = 10000, -- 1000
	Diamond = 10000,
	Bubblegum = 10000,
}

-- if Common.isStudio then
-- 	MutationInfo.mutationProbMap = MutationInfo.mutationProbMap_TEST
-- end

return MutationInfo
