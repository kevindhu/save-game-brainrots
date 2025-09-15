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

	["Bloodrot"] = {
		alias = "Volcanic",
		color = Color3.fromRGB(145, 0, 27),
		colorGradient = ColorSequence.new(Color3.fromRGB(145, 0, 27)),

		partColorIndexes = {
			Color3.fromRGB(145, 0, 27),
			Color3.fromRGB(154, 94, 100),
			Color3.fromRGB(75, 0, 7),
			Color3.fromRGB(72, 0, 2),
			Color3.fromRGB(195, 98, 100),
			Color3.fromRGB(195, 98, 100),
			Color3.fromRGB(145, 0, 27),
			Color3.fromRGB(75, 0, 7),
		},
	},

	["Rainbow"] = {
		alias = "Rainbow",
		color = Color3.fromRGB(255, 86, 86),
		colorGradient = ColorSequence.new(Color3.fromRGB(173, 79, 255)),
	},
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

if Common.isStudio then
	MutationInfo.mutationProbMap = MutationInfo.mutationProbMap_TEST
end

return MutationInfo
