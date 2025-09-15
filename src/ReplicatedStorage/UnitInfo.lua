-- local ContentProvider = game:GetService("ContentProvider")

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local UnitInfo = {}

UnitInfo["units"] = {
	["Unit1"] = {
		alias = "Unit1",
		health = 1000,
		speed = 10,
	},
}

function UnitInfo:init()
	-- do nothing
end

function UnitInfo:getMeta(itemClass, noWarn)
	self.categoryList = {
		"units",
	}
	return Common.getInfoMeta(self, itemClass, noWarn)
end

UnitInfo:init()

return UnitInfo
