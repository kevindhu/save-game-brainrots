local ShopInfo = {
	idMap = {},
}

ShopInfo["gamepassList"] = {
	"VIP",
	"2xCoins",
	"SuperLuck",
	"2xDamage",

	-- "SmallLuck",
}

ShopInfo["gamepasses"] = {
	["VIP"] = {
		id = 1522290454,
	},
	["2xCoins"] = {
		id = 1521918513,
	},
	["SuperLuck"] = {
		id = 1522080496,
	},
	["2xDamage"] = {
		id = 1520574579,
	},
	["NoSafeZone"] = {
		id = 1521282552,
	},
}

ShopInfo["productList"] = {}

ShopInfo["products"] = {
	-- coins boost
	["OfflineCoinsClaimBoost"] = {
		alias = "Offline Coins Boost",
		description = "Claim 10x more coins when you come back!",
		id = 3407093721,

		rewards = {
			offlineCoinsBoost = true,
		},
	},

	["BuyCrate1"] = {
		id = 3424425318,
		rewards = {
			premiumCrateClass = "Crate1",
		},
	},
	["BuyCrate2"] = {
		id = 3424425370,
		rewards = {
			premiumCrateClass = "Crate2",
		},
	},
	["BuyCrate3"] = {
		id = 3424425425,
		rewards = {
			premiumCrateClass = "Crate3",
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
