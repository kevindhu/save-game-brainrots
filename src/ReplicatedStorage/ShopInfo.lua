local ShopInfo = {
	idMap = {},
}

ShopInfo["gamepassList"] = {
	"VIP",
	"2xCoins",
	"10MorePets",
	-- "BigLuck",
	-- "SmallLuck",
}

ShopInfo["gamepasses"] = {
	["VIP"] = {
		id = 1441235390,
	},
	["2xCoins"] = {
		id = 1438643814,
	},
	["BigLuck"] = {
		id = 1438879429,
	},
	["SmallLuck"] = {
		id = 1442739646,
	},

	["10MorePets"] = {
		id = 1462499604,
	},
}

ShopInfo["productList"] = {
	"LuckyBlock10",
	"LuckyBlock3",
	"LuckyBlock1",

	"BuyEgg1",
	"BuyEgg2",
	"BuyEgg3",
	"BuyEgg4",
	"BuyEgg5",

	"SkipEgg1",
	"SkipEgg2",
	"SkipEgg3",
	"SkipEgg4",
	"SkipEgg5",

	"SkipSpecEgg1",
}

ShopInfo["products"] = {
	["LuckyBlock10"] = {
		id = 3403802653,
		rewards = {
			premiumEggClass = "LuckyBlockEgg",
			count = 10,
		},
	},
	["LuckyBlock3"] = {
		id = 3403802796,
		rewards = {
			premiumEggClass = "LuckyBlockEgg",
			count = 3,
		},
	},
	["LuckyBlock1"] = {
		id = 3403802926,
		rewards = {
			premiumEggClass = "LuckyBlockEgg",
			count = 1,
		},
	},

	["BuyEgg1"] = {
		id = 3378332057,
		rewards = {
			premiumEggClass = "Egg1",
		},
	},
	["BuyEgg2"] = {
		id = 3378332143,
		rewards = {
			premiumEggClass = "Egg2",
		},
	},
	["BuyEgg3"] = {
		id = 3378332206,
		rewards = {
			premiumEggClass = "Egg3",
		},
	},
	["BuyEgg4"] = {
		id = 3378332276,
		rewards = {
			premiumEggClass = "Egg4",
		},
	},
	["BuyEgg5"] = {
		id = 3378332373,
		rewards = {
			premiumEggClass = "Egg5",
		},
	},

	-- SKIPPING EGG TIMERS
	["SkipEgg1"] = {
		id = 3378332448,
		rewards = {
			skipEgg = true,
		},
	},
	["SkipEgg2"] = {
		id = 3378332553,
		rewards = {
			skipEgg = true,
		},
	},
	["SkipEgg3"] = {
		id = 3378332615,
		rewards = {
			skipEgg = true,
		},
	},
	["SkipEgg4"] = {
		id = 3378332671,
		rewards = {
			skipEgg = true,
		},
	},
	["SkipEgg5"] = {
		id = 3378332721,
		rewards = {
			skipEgg = true,
		},
	},

	-- special eggs
	["SkipSpecEgg1"] = {
		id = 3384246660,
		rewards = {
			skipEgg = true,
		},
	},
	["SkipSpecEgg2"] = {
		id = 0,
		rewards = {
			skipEgg = true,
		},
	},

	-- lucky block egg
	["SkipLuckyBlockEgg"] = {
		id = 3384246660,
		rewards = {
			skipEgg = true,
		},
	},

	-- ZONES
	["Zone2"] = {
		id = 3385181091,
		rewards = {
			zoneClass = "Zone2",
		},
	},
	["Zone3"] = {
		id = 3385181272,
		rewards = {
			zoneClass = "Zone3",
		},
	},
	["Zone4"] = {
		id = 3384246909,
		rewards = {
			zoneClass = "Zone4",
		},
	},

	-- coins boost
	["OfflineCoinsClaimBoost"] = {
		alias = "Offline Coins Boost",
		description = "Claim 10x more coins when you come back!",
		id = 3379340754,

		rewards = {
			offlineCoinsBoost = true,
		},
	},
}

ShopInfo["currencies"] = {
	["Coins1"] = {
		id = 3365897403,

		rewards = {
			itemMod = {
				itemName = "Coins",
				count = 2500,
			},
		},
	},
	["Coins2"] = {
		id = 3365897623,

		rewards = {
			itemMod = {
				itemName = "Coins",
				count = 7500,
			},
		},
	},
	["Coins3"] = {
		id = 3365897715,

		rewards = {
			itemMod = {
				itemName = "Coins",
				count = 50 * 1000,
			},
		},
	},
	["Coins4"] = {
		id = 3365897858,

		rewards = {
			itemMod = {
				itemName = "Coins",
				count = 500 * 1000,
			},
		},
	},
	["Coins5"] = {
		id = 3365897936,

		rewards = {
			itemMod = {
				itemName = "Coins",
				count = 10 * 1000 * 1000,
			},
		},
	},
}

function ShopInfo:init()
	self.categoryList = {
		"gamepasses",

		-- products
		"currencies",
		"products",
		"luckProducts",
	}
	for _, categoryClass in pairs(self.categoryList) do
		local mods = self[categoryClass]
		for itemClass, mod in pairs(mods) do
			local id = mod["id"]

			-- map the ids to the classes
			self.idMap[id] = itemClass
		end
	end
end

ShopInfo["luckProducts"] = {
	["ServerLuck1"] = {
		id = 3365896173,

		rewards = {
			setServerLuck = 2,
		},
	},
	["ServerLuck2"] = {
		id = 3365896299,

		rewards = {
			setServerLuck = 4,
		},
	},
	["ServerLuck3"] = {
		id = 3365896461,

		rewards = {
			setServerLuck = 8,
		},
	},
	["ServerLuck4"] = {
		id = 3365896558,

		rewards = {
			setServerLuck = 16,
		},
	},
}

function ShopInfo:getNextServerLuckProduct(serverLuck)
	local serverLuckProductMap = {
		["1"] = "ServerLuck1",
		["2"] = "ServerLuck2",
		["4"] = "ServerLuck3",
		["8"] = "ServerLuck4",
		["16"] = "ServerLuck4",
	}
	local productClass = serverLuckProductMap[tostring(serverLuck)]
	return productClass
end

function ShopInfo:getClassFromId(id)
	return ShopInfo.idMap[id]
end

function ShopInfo:getMeta(itemClass, noWarn)
	local Common = require(game.ReplicatedStorage.Common)
	return Common.getInfoMeta(self, itemClass, noWarn)
end

ShopInfo:init()

return ShopInfo
