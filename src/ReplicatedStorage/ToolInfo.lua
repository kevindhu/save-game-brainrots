local ToolInfo = {}

-- local Common = require(game.ReplicatedStorage.Common)

ToolInfo["vendorBasicToolList"] = {}

ToolInfo["tools"] = {
	["Hammer"] = {
		alias = "Pick Up",
		description = "A hammer for building",
		price = 0,
		image = "rbxassetid://125427347841808",
	},
}

ToolInfo["noAnimateToolRaces"] = {
	"egg",
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
