local StatInfo = {}

StatInfo.statList = {
	"Playtime",
	"RobuxSpent",

	"Coins",
	"TotalCoins",
}

StatInfo["stats"] = {
	["Playtime"] = {
		alias = "Playtime",
		colonNotation = true,
	},
	["RobuxSpent"] = {
		alias = "Robux Spent",
		robuxNotation = true,
	},

	-- currencies
	["Coins"] = {
		alias = "Coins",
		abbreviateNum = true,
	},

	-- total currencies
	["TotalCoins"] = {
		alias = "Coins",
		abbreviateNum = true,
	},
}

function StatInfo:init()
	self.categoryList = {
		"stats",
	}
	for index, statClass in pairs(self.statList) do
		local statData = self.stats[statClass]
		statData["index"] = index
	end
end

function StatInfo:getMeta(itemClass, noWarn)
	local Common = require(game.ReplicatedStorage.Common)
	return Common.getInfoMeta(self, itemClass, noWarn)
end

StatInfo:init()

return StatInfo
