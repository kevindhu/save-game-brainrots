local TutInfo = {}

TutInfo["enableMapping"] = {
	["TeleportToEggShop1"] = { "BuyFirstEgg" },
	["BuyFirstEgg"] = { "CloseEggShop1" },
	["CloseEggShop1"] = { "PlaceFirstEgg" },
	["PlaceFirstEgg"] = { "WaitForFirstEgg" },
	["WaitForFirstEgg"] = { "HatchFirstEgg" },
	["HatchFirstEgg"] = { "WaitForHatchingComplete" },
	["WaitForHatchingComplete"] = { "TeleportToEggShop2" },
	["TeleportToEggShop2"] = { "BuySecondEgg" },
	["BuySecondEgg"] = { "CompleteTutorial" },
}

TutInfo["tuts"] = {
	["TeleportToEggShop1"] = {
		targetClass = "TeleportToEggShop",
		text = "Go to the Egg Shop!",

		requireMod = {
			count = 1,
		},
		funnelStep = 1,
	},
	["BuyFirstEgg"] = {
		targetClass = "BuyEgg1",
		text = "Buy the <b>Common Egg</b>!",

		requireMod = {
			count = 1,
		},
		funnelStep = 2,
	},
	["CloseEggShop1"] = {
		targetClass = "CloseEggShop",
		text = "Close the <b>Egg Shop</b>!",

		requireMod = {
			count = 1,
		},
		funnelStep = 3,
	},
	["PlaceFirstEgg"] = {
		targetClass = "PlaceFirstEgg",
		text = "Place the Egg!",

		requireMod = {
			count = 1,
		},
		funnelStep = 4,
	},
	["WaitForFirstEgg"] = {
		targetClass = "WaitForFirstEgg",
		text = "Wait for the Egg to Hatch",
		-- text = "",

		requireMod = {
			count = 1,
		},
		funnelStep = 5,
	},
	["HatchFirstEgg"] = {
		targetClass = "HatchFirstEgg",
		text = "Get close to the Egg to complete Hatching!",

		requireMod = {
			count = 1,
		},
		funnelStep = 6,
	},
	["WaitForHatchingComplete"] = {
		targetClass = "Nothing",
		text = "",

		requireMod = {
			timer = 8, -- 6.5
		},
		funnelStep = 7,
	},
	["TeleportToEggShop2"] = {
		targetClass = "TeleportToEggShop",
		text = "Buy more Eggs to get better Brainrots!",

		requireMod = {
			count = 1,
		},
		funnelStep = 8,
	},
	["BuySecondEgg"] = {
		targetClass = "BuyEgg1",
		text = "Buy Another Egg!",

		requireMod = {
			count = 1,
		},
		funnelStep = 9,
	},

	["CompleteTutorial"] = {
		targetClass = "Nothing",
		text = "You have finished the Tutorial! Enter Code 'tutorial' for Rewards!",

		requireMod = {
			timer = 10,
		},
		funnelStep = 10,
	},
}

function TutInfo:init() end

function TutInfo:getMeta(itemClass, noWarn)
	self.categoryList = {
		"tuts",
	}
	local Common = require(game.ReplicatedStorage.Common)
	return Common.getInfoMeta(self, itemClass, noWarn)
end

TutInfo:init()

return TutInfo
