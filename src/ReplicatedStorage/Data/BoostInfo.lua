local BoostInfo = {}

BoostInfo["boosts"] = {
	["1.5xStrength"] = {
		alias = "1.5x Strength",
		race = "Strength",
		multiplier = 1.5,
	},
	["2xStrength"] = {
		alias = "2x Strength",
		race = "Strength",
		multiplier = 2,
	},
	["5xStrength"] = {
		alias = "5x Strength",
		race = "Strength",
		multiplier = 5,
	},
	["10xStrength"] = {
		alias = "10x Strength",
		race = "Strength",
		multiplier = 10,
	},
	["100xStrength"] = {
		alias = "100x Strength",
		race = "Strength",
		multiplier = 100,
	},
}

BoostInfo["potions"] = {
	["1.5xStrengthPotion_10Min"] = {
		boostClass = "1.5xStrength",
		duration = 60 * 10,
	},
	["2xStrengthPotion_1Min"] = {
		boostClass = "2xStrength",
		duration = 60 * 1,
	},
	["5xStrengthPotion_1Min"] = {
		boostClass = "5xStrength",
		duration = 60 * 1,
	},

	-- 10x Strength
	["10xStrengthPotion_1Min"] = {
		boostClass = "10xStrength",
		duration = 60 * 1,
	},

	-- 100x Strength
	["100xStrengthPotion_1Min"] = {
		boostClass = "100xStrength",
		duration = 60 * 1,
	},
}

function BoostInfo:getMeta(itemClass, noWarn)
	local Common = require(game.ReplicatedStorage.Common)
	self.categoryList = {
		"boosts",
		"potions",
	}
	return Common.getInfoMeta(self, itemClass, noWarn)
end

return BoostInfo
