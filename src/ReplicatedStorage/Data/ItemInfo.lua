local ItemInfo = {}

ItemInfo["currencies"] = {
	["Coins"] = {
		alias = "Coins",
		image = "rbxassetid://87861169766396",
	},
}

function ItemInfo:init()
	for _, itemMod in pairs(self.currencies) do
		itemMod["tabGroup"] = "Currencies"
	end
end

function ItemInfo:getMeta(itemClass, noWarn)
	local Common = require(game.ReplicatedStorage.Common)
	self.categoryList = {
		"currencies",
	}
	return Common.getInfoMeta(self, itemClass, noWarn)
end

ItemInfo:init()

return ItemInfo
