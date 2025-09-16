-- local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local DeleteManager = {}

function DeleteManager:init()
	routine(function()
		local deleteHighlight = Instance.new("Highlight")
		self.deleteHighlight = deleteHighlight

		self.deleteHighlight.FillColor = Color3.fromRGB(255, 78, 78)

		self.deleteHighlight.Parent = game.Workspace.HighlightTemplateModels
		self.deleteHighlight.Adornee = nil

		wait(1)
		self:toggleDelete(false)
		self:chooseDeletePet(nil)
	end)
end

function DeleteManager:toggleDelete(newBool)
	self.deleteToggled = newBool

	ClientMod.placeManager:refreshAllPrompts()
end

function DeleteManager:tick() end

function DeleteManager:chooseDeletePet(chosenDeletePet)
	if not chosenDeletePet then
		self.deleteHighlight.Adornee = nil
		return
	end

	self.deleteHighlight.Adornee = chosenDeletePet.rig
end

DeleteManager:init()

return DeleteManager
