-- local ContentProvider = game:GetService("ContentProvider")

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local UnitInfo = {}

UnitInfo["animationMap"] = {
	["idle"] = 180435571,
	["run"] = 180426354,
}

UnitInfo["units"] = {
	["Unit1"] = {
		alias = "Noob",
		health = 10,
		moveSpeed = 0.2, -- 1.1,

		attackRange = 2,
	},
	["Unit2"] = {
		alias = "Big Noob",
		health = 50,
		moveSpeed = 0.3,

		attackRange = 2,
	},
	["Unit3"] = {
		alias = "Gigantic Noob",
		health = 10000,
		moveSpeed = 0.4,

		attackRange = 2,
	},
	["Unit4"] = {
		alias = "Mutated king",
		health = 1,
		moveSpeed = 0.4,

		attackRange = 2,
	},
	["Unit5"] = {
		alias = "Dominus King",
		health = 1,
		moveSpeed = 0.4,

		attackRange = 2,
	},
	["Unit6"] = {
		alias = "1x1x1x1",
		health = 1,
		moveSpeed = 0.4,

		attackRange = 2,
	},
}

UnitInfo["chatPhraseMap"] = {
	["Unit1"] = {
		"pls free stuff!",
		"pls brainrot plsss",
		"give brainrot pls 🥺",
		"donate pls",
		"brainrot donate pls 🥺",
		"give me brainrots!",
		"😡 MY BRAINROTS NOW!",
	},
	["Unit2"] = {
		"i want your brainrots!!!",
	},
	["Unit3"] = {
		"i want your brainrots!",
		"give me brainrots!",
		"😡 MY BRAINROTS NOW!",
	},
	["Unit4"] = {
		"😡 give me brainrots!",
		"this is mine 😈",
		"😡 MY BRAINROTS NOW!",
	},
	["Unit5"] = {
		"THIS IS MINE THIS IS MINE THIS IS MINE",
		"01101000 01101001 00001010",
	},
	["Unit6"] = {
		"01101000 01101001 00001010",
		"01101001 00100000 01110111 01101001 01101100 01101100 00100000 01101000 01100001 01111000 00100000 01110101 00001010",
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
