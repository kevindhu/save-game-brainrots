local ToolInfo = {}

-- local Common = require(game.ReplicatedStorage.Common)

ToolInfo["vendorBasicToolList"] = {}

ToolInfo["tools"] = {
	["Bat1"] = {
		alias = "Bat",
		description = "A bat for hitting",
		price = 0,
		image = "rbxassetid://70735417680990",
	},
	["Hammer"] = {
		alias = "Pick Up",
		description = "A hammer for building",
		price = 0,
		image = "rbxassetid://125427347841808",
	},
}

ToolInfo["noAnimateToolRaces"] = {
	"pet",
}

function ToolInfo:getMeta(itemClass, noWarn)
	self.categoryList = {
		"tools",
	}

	local Common = require(game.ReplicatedStorage.Common)
	return Common.getInfoMeta(self, itemClass, noWarn)
end

return ToolInfo
