local TutInfo = {}

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

TutInfo["enableMapping"] = {
	["EquipBat1"] = { "PressPlay" },
	["PressPlay"] = { "CompleteFirstWave" },
	["CompleteFirstWave"] = { "EquipFirstPet" },
	["EquipFirstPet"] = { "PlaceFirstPet" },
	["PlaceFirstPet"] = { "EquipBat2" },
	["EquipBat2"] = { "CompleteSecondWave" },
	["CompleteSecondWave"] = { "CompleteTutorial" },

	-- second
	["GoToTimeWizard"] = { "Buy2xSpeedCommon" },
	["Buy2xSpeedCommon"] = { "CloseTimeWizard" },
	["CloseTimeWizard"] = { "Choose2xSpeedCommon" },
	["Choose2xSpeedCommon"] = { "FinishedTimeWizardTut" },
}

TutInfo["funnelStepList"] = {
	"EquipBat1",
	"PressPlay",
	"CompleteFirstWave",
	"EquipFirstPet",
	"PlaceFirstPet",
	"EquipBat2",
	"CompleteSecondWave",
	"CompleteTutorial",

	"GoToTimeWizard",
	"Buy2xSpeedCommon",
	"CloseTimeWizard",
	"Choose2xSpeedCommon",
	"FinishedTimeWizardTut",
}

TutInfo["tuts"] = {
	["EquipBat1"] = {
		targetClass = "EquipBat1",
		text = string.format("Equip the %s!", Common.addRichTextColor("Tung Bat", Color3.fromRGB(115, 255, 234))),

		requireMod = {
			count = 1,
		},
	},
	["PressPlay"] = {
		targetClass = "PressPlay",
		text = "Press play button!",

		requireMod = {
			count = 1,
		},
	},
	["CompleteFirstWave"] = {
		targetClass = "CompleteFirstWave",
		text = string.format(
			"Save the %s!",
			Common.addRichTextColor("Cappuccino Assassino", Color3.fromRGB(115, 255, 234))
		),

		requireMod = {
			count = 1,
		},
	},
	["EquipFirstPet"] = {
		targetClass = "EquipFirstPet",
		text = string.format(
			"Equip the %s!",
			Common.addRichTextColor("Cappuccino Assassino", Color3.fromRGB(115, 255, 234))
		),

		requireMod = {
			count = 1,
		},
	},
	["PlaceFirstPet"] = {
		targetClass = "PlaceFirstPet",
		text = "Place on the platform!",

		requireMod = {
			count = 1,
		},
	},
	["EquipBat2"] = {
		targetClass = "EquipBat2",
		text = string.format("Equip the %s!", Common.addRichTextColor("Tung Bat", Color3.fromRGB(115, 255, 234))),

		requireMod = {
			count = 1,
		},
	},
	["CompleteSecondWave"] = {
		targetClass = "CompleteSecondWave",
		text = string.format("Save the %s!", Common.addRichTextColor("Tung Tung Sahur", Color3.fromRGB(115, 255, 234))),

		requireMod = {
			count = 1,
		},
	},

	["CompleteTutorial"] = {
		targetClass = "Nothing",
		text = "You have finished the tutorial!",

		requireMod = {
			timer = 3,
		},
	},

	-- TIME WIZARD TUTORIALS
	["GoToTimeWizard"] = {
		targetClass = "GoToTimeWizard",
		text = string.format("Go to the %s!", Common.addRichTextColor("Time Wizard", Color3.fromRGB(115, 255, 234))),

		requireMod = {
			count = 1,
		},
	},
	["Buy2xSpeedCommon"] = {
		targetClass = "Buy2xSpeedCommon",
		text = "Buy the 2x Speed!",

		requireMod = {
			count = 1,
		},
	},
	["CloseTimeWizard"] = {
		targetClass = "CloseTimeWizard",
		text = "Press the close button!",

		requireMod = {
			count = 1,
		},
	},
	["Choose2xSpeedCommon"] = {
		targetClass = "Choose2xSpeedCommon",
		text = "Choose the 2x Speed!",

		requireMod = {
			count = 1,
		},
	},
	["FinishedTimeWizardTut"] = {
		targetClass = "Nothing",
		text = string.format(
			"Save the %s (2x Speed)!",
			Common.addRichTextColor("Cappuccino Assassino", Color3.fromRGB(115, 255, 234))
		),

		requireMod = {
			timer = 3,
		},
	},
}

function TutInfo:init()
	for index, tutName in pairs(self.funnelStepList) do
		self.tuts[tutName]["funnelIndex"] = index
	end
end

function TutInfo:getMeta(itemClass, noWarn)
	self.categoryList = {
		"tuts",
	}
	local Common = require(game.ReplicatedStorage.Common)
	return Common.getInfoMeta(self, itemClass, noWarn)
end

TutInfo:init()

return TutInfo
