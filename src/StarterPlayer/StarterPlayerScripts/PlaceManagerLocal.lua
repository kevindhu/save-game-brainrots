local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local placeGUI = playerGui:WaitForChild("PlaceGUI")

local camera = workspace.CurrentCamera

local PlaceManager = {
	rotateAngle = CFrame.Angles(0, 0, 0),
}
PlaceManager.__index = PlaceManager

function PlaceManager:init()
	self:addCons()
end

function PlaceManager:addCons() end

function PlaceManager:tickRender() end

function PlaceManager:getEquippedToolMod()
	if not ClientMod.toolManager then
		return
	end
	return ClientMod.toolManager:getEquippedToolMod()
end

function PlaceManager:refreshStashTool()
	local chosenToolMod = self:getEquippedToolMod()

	ClientMod.sellPetManager:refreshEquippedItem()
	ClientMod.sellRelicManager:refreshEquippedItem()

	local user = ClientMod:getLocalUser()

	if not chosenToolMod then
		self:togglePlace(false)
		ClientMod.animUtils:clearAnimations(user)
		return
	end

	ClientMod.animUtils:animate(user, {
		race = "HoldTool",
		animationClass = "HoldStashTool",
	})

	self:togglePlace(true)
end

function PlaceManager:togglePlace(newBool)
	self.placeToggled = newBool

	self:refreshAllPrompts()
end

function PlaceManager:refreshAllPrompts()
	routine(function()
		self:doFullPromptRefresh()
		wait(0.1)
		self:doFullPromptRefresh()
	end)
end

function PlaceManager:doFullPromptRefresh()
	local petEquipped = false
	local relicEquipped = false

	local equippedToolMod = self:getEquippedToolMod()

	if equippedToolMod then
		if equippedToolMod["race"] == "pet" then
			petEquipped = true
		elseif equippedToolMod["race"] == "relic" then
			relicEquipped = true
		end
	end

	for _, petSpot in pairs(ClientMod.petSpots) do
		if not petSpot.unlocked then
			petSpot:removePlacePrompt()
			petSpot:removePickupPrompt()
			petSpot:removeRelicPrompt()
			petSpot:removePickupRelicPrompt()
			petSpot:removeSwapPetPrompt()
			petSpot:removeSwapRelicPrompt()
			continue
		end

		if not petEquipped then
			petSpot:removePlacePrompt()
		end
		if not relicEquipped then
			petSpot:removeRelicPrompt()
			if petSpot.petData and len(petSpot.petData["relicMods"]) > 0 then
				petSpot:addPickupRelicPrompt()
			end
		end

		if not petSpot.petData then
			petSpot:removePickupPrompt()
			petSpot:removeRelicPrompt()
			petSpot:removePickupRelicPrompt()
			petSpot:removeSwapPetPrompt()
			petSpot:removeSwapRelicPrompt()
		else
			if petEquipped then
				petSpot:addSwapPetPrompt()
				petSpot:removePickupPrompt()
			else
				petSpot:addPickupPrompt()
				petSpot:removeSwapPetPrompt()
			end

			local relicMods = petSpot.petData["relicMods"]

			if relicEquipped then
				petSpot:removePickupRelicPrompt()

				if len(relicMods) == 0 then
					petSpot:addRelicPrompt()
					petSpot:removeSwapRelicPrompt()
				else
					petSpot:addSwapRelicPrompt()
					petSpot:removeRelicPrompt()
				end
			else
				petSpot:removeRelicPrompt()
				petSpot:removeSwapRelicPrompt()

				if len(relicMods) == 0 then
					petSpot:removePickupRelicPrompt()
				else
					petSpot:addPickupRelicPrompt()
				end
			end
		end

		if petEquipped then
			if not petSpot.petData then
				petSpot:addPlacePrompt()
			end
		end
	end

	for _, user in pairs(ClientMod.users) do
		user:toggleGiftPrompt(petEquipped)
	end
end

PlaceManager:init()

return PlaceManager
