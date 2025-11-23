local LeaderInfo = {}

LeaderInfo["leaderList"] = {
	"TopCoins",
	"TopPlaytime",
}

LeaderInfo["leaders"] = {
	["TopCoins"] = {
		alias = "Top Cash",
		itemClass = "Coins",
	},
	["TopPlaytime"] = {
		alias = "Top Playtime",
		itemClass = "Playtime",
	},
}

function LeaderInfo:init() end

function LeaderInfo:getMeta(name, noWarn)
	local Common = require(game.ReplicatedStorage.Common)
	self.categoryList = {
		"leaders",
	}
	return Common.getInfoMeta(self, name, noWarn)
end

LeaderInfo:init()

return LeaderInfo
