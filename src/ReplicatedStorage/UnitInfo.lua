-- local ContentProvider = game:GetService("ContentProvider")

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local UnitInfo = {}

UnitInfo["animationMap"] = {
	["idle"] = 180435571,
	["run"] = 180426354,
}

UnitInfo["units"] = {
	["Unit1x1"] = {
		alias = "Noob",
		health = 25,
		moveSpeed = 0.25, -- 1.1,
	},
	["Unit2x1"] = {
		alias = "Big Noob",
		health = 75,
		moveSpeed = 0.2,
	},
	["Unit3x1"] = {
		alias = "Gigantic Noob",
		health = 300,
		moveSpeed = 0.18,
	},
	["Unit4x1"] = {
		alias = "Mutated king",
		health = 1200,
		moveSpeed = 0.2,
	},
	["Unit5x1"] = {
		alias = "Dominus King",
		health = 10000,
		moveSpeed = 0.25,
	},
	["Unit6x1"] = {
		alias = "1x1x1x1",
		health = 25000,
		moveSpeed = 0.35,
	},

	["Unit1x2"] = {
		alias = "Bacon",
		health = 25,
		moveSpeed = 0.25, -- 1.1,
	},
	["Unit2x2"] = {
		alias = "Hobo",
		health = 75,
		moveSpeed = 0.2,
	},
	["Unit3x2"] = {
		alias = "Gigantic Bacon",
		health = 300,
		moveSpeed = 0.18,
	},
	["Unit4x2"] = {
		alias = "Mutated king",
		health = 1200,
		moveSpeed = 0.2,
	},
	["Unit5x2"] = {
		alias = "Dominus King",
		health = 10000,
		moveSpeed = 0.25,
	},
	["Unit6x2"] = {
		alias = "1x1x1x1",
		health = 25000,
		moveSpeed = 0.35,
	},
}

UnitInfo["chatPhraseMap"] = {
	["Unit1x1"] = {
		"pls free stuff!",
		"pls brainrot plsss",
		"give brainrot pls 🥺",
		"donate pls",
		"brainrot donate pls 🥺",
		"give me brainrots!",
		"😡 MY BRAINROTS NOW!",
	},
	["Unit1x2"] = {
		"pls free stuff!",
		"pls brainrot plsss",
		"give brainrot pls 🥺",
		"donate pls",
		"brainrot donate pls 🥺",
		"give me brainrots!",
		"😡 MY BRAINROTS NOW!",
	},

	["Unit2x1"] = {
		"i want your brainrots!!!",
	},
	["Unit2x2"] = {
		"i want your brainrots!!!",
	},

	["Unit3x1"] = {
		"i want your brainrots!",
		"give me brainrots!",
		"😡 MY BRAINROTS NOW!",
	},
	["Unit3x2"] = {
		"i want your brainrots!!!",
	},

	["Unit4x1"] = {
		"😡 give me brainrots!",
		"this is mine 😈",
		"😡 MY BRAINROTS NOW!",
	},
	["Unit4x2"] = {
		"i want your brainrots!!!",
	},

	["Unit5x1"] = {
		"THIS IS MINE THIS IS MINE THIS IS MINE",
		"01101000 01101001 00001010",
	},

	["Unit6x1"] = {
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
