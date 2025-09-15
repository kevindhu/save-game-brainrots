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

local MAX_ACTIVATION_DISTANCE = 15

function DeleteManager:tick()
	local userFrame = ClientMod:getLocalUser().currFrame
	if not userFrame then
		return
	end

	if not self.deleteToggled then
		self:chooseDeletePet(nil)
		return
	end

	local chosenDeletePet = nil
	local closestDistance = MAX_ACTIVATION_DISTANCE
	for _, pet in pairs(ClientMod.pets) do
		if not pet.deletePrompt then
			continue
		end

		local distance = (pet.rig.RootPart.AuraAttachment.WorldCFrame.Position - userFrame.Position).Magnitude

		if distance < closestDistance then
			closestDistance = distance
			chosenDeletePet = pet
		end
	end

	self:chooseDeletePet(chosenDeletePet)
end

function DeleteManager:chooseDeletePet(chosenDeletePet)
	if not chosenDeletePet then
		self.deleteHighlight.Adornee = nil
		return
	end

	self.deleteHighlight.Adornee = chosenDeletePet.rig
end

DeleteManager:init()

return DeleteManager
