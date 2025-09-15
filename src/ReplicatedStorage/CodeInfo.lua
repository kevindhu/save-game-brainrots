local CodeInfo = {}

CodeInfo["codes"] = {
	["tutorial"] = {
		rewards = {
			{
				itemMod = {
					itemName = "Coins",
					count = 250,
				},
			},
		},
	},
	["release"] = {
		rewards = {
			{
				itemMod = {
					itemName = "Coins",
					count = 500,
				},
			},
		},
	},

	["updatefun"] = {
		-- expiree = 1742642344 + 60 * 60 * 24 * 30,
		rewards = {
			{
				itemMod = {
					itemName = "Coins",
					count = 5000,
				},
			},
		},
	},
}

function CodeInfo:init() end

function CodeInfo:getMeta(itemClass, noWarn)
	local Common = require(game.ReplicatedStorage.Common)
	self.categoryList = {
		"codes",
	}
	return Common.getInfoMeta(self, itemClass, noWarn)
end

CodeInfo:init()

return CodeInfo
