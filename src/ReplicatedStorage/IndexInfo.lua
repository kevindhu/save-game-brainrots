local IndexInfo = {
	MAX_LEVEL = 7,
}

IndexInfo["rewards"] = {
	["Reward1"] = {
		requirePetCount = 10,
		rewardItems = {
			["Coins1"] = {
				coinMultiplier = 0.2,
			},
			["Coins2"] = {
				coinCount = 1 * 1000,
			},
		},
	},
	["Reward2"] = {
		requirePetCount = 20,
		rewardItems = {
			["Coins1"] = {
				coinMultiplier = 0.2,
			},
			["Coins2"] = {
				coinCount = 10 * 1000,
			},
		},
	},
	["Reward3"] = {
		requirePetCount = 40,
		rewardItems = {
			["Coins1"] = {
				coinMultiplier = 0.2,
			},
			["Coins2"] = {
				coinCount = 20 * 1000,
			},
		},
	},
	["Reward4"] = {
		requirePetCount = 60,
		rewardItems = {
			["Coins1"] = {
				coinMultiplier = 0.2,
			},
			["Coins2"] = {
				coinCount = 50 * 1000,
			},
		},
	},
	["Reward5"] = {
		requirePetCount = 80,
		rewardItems = {
			["Coins1"] = {
				coinMultiplier = 0.2,
			},
			["Coins2"] = {
				coinCount = 100 * 1000,
			},
		},
	},
	["Reward6"] = {
		requirePetCount = 100,
		rewardItems = {
			["Coins1"] = {
				coinMultiplier = 0.2,
			},
			["Coins2"] = {
				coinCount = 1000 * 1000,
			},
		},
	},
	["Reward7"] = {
		requirePetCount = 120,
		rewardItems = {
			["Coins1"] = {
				coinMultiplier = 0.2,
			},
			["Coins2"] = {
				coinCount = 50 * 1000 * 1000,
			},
		},
	},
}

function IndexInfo:init() end

function IndexInfo:getMeta(itemClass, noWarn)
	local Common = require(game.ReplicatedStorage.Common)
	self.categoryList = {
		"rewards",
	}
	return Common.getInfoMeta(self, itemClass, noWarn)
end

IndexInfo:init()

return IndexInfo
