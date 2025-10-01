local Common = require(game.ReplicatedStorage.Common)

local MutationInfo = {}

MutationInfo["mutations"] = {
	["Normal"] = {
		alias = "Normal",
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

	-- not yet added
	-- ["Volcanic"] = {
	-- 	alias = "Volcanic",
	-- 	color = Color3.fromRGB(255, 94, 0),
	-- 	colorGradient = ColorSequence.new(Color3.fromRGB(255, 94, 0)),
	-- },
}

MutationInfo["damageMultiplierMap"] = {
	["Normal"] = 1,
	["Gold"] = 1,
	["Diamond"] = 1,
	["Bubblegum"] = 1.5,
}

MutationInfo["attackSpeedMultiplierMap"] = {
	["Normal"] = 1,
	["Gold"] = 1.05,
	["Diamond"] = 1.11,
	["Bubblegum"] = 1.13,
}

MutationInfo["mutationProbMap"] = {
	Normal = 5000, -- 1000,

	Gold = 400, -- 1000
	Diamond = 100, -- 100

	-- rarest cause best
	Bubblegum = 50,
}

return MutationInfo
