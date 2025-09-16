local UserInputService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local placeGUI = playerGui:WaitForChild("PlaceGUI")
local hintFrame = placeGUI.HintFrame

local camera = workspace.CurrentCamera

local PlaceManager = {
	rotateAngle = CFrame.Angles(0, 0, 0),
}
PlaceManager.__index = PlaceManager

function PlaceManager:init()
	self:addCons()

	self:initPlaceModel()

	self:toggleHintFrame(false)
end

function PlaceManager:initPlaceModel()
	local placeCollideModel = game.ReplicatedStorage.Assets.PlaceCollideModel:Clone()
	placeCollideModel.Parent = game.Workspace.HitBoxes

	self.placeCollideModel = placeCollideModel

	self.placeCollidePart = placeCollideModel.PrimaryPart
	self.placeCollidePart.Transparency = 1

	local prompt = ClientMod.uiManager:createPrompt({
		actionText = "Place",
		objectText = nil,
		name = "PlaceTool",
		holdDuration = 0.0001,
		enabled = true,
		maxActivationDistance = 20,
		parent = self.placeCollidePart,
	})

	self.placePrompt = prompt

	prompt.Triggered:Connect(function()
		self:tryConfirmPlacement()
	end)
end

function PlaceManager:addCons()
	-- turn these off now because we have placePrompt
	-- self:addPlacementCons()
end

function PlaceManager:addPlacementCons()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if Common.listContains({ Enum.UserInputType.MouseButton1 }, input.UserInputType) then
			self:tryConfirmPlacement()
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		self.startTouchTime = os.clock()
		self.startTouchPosition = input.Position
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if gameProcessed then
			return
		end

		if not self.startTouchTime then
			return
		end

		self.endTouchTime = os.clock()
		self.endTouchPosition = input.Position

		local distance = (self.startTouchPosition - self.endTouchPosition).Magnitude
		if distance > 10 then
			return
		end

		local timeDiff = self.endTouchTime - self.startTouchTime
		if timeDiff > 0.1 then
			return
		end

		local chosenToolMod = self:getEquippedToolMod()
		if not chosenToolMod then
			-- warn("NO CHOSEN TOOL MOD TO PLACE")
			return
		end
		local race = chosenToolMod["race"]
		if Common.listContains({ "pet" }, race) then
			self:tryConfirmPlacement()
			return
		end
	end)

	hintFrame.BackgroundTransparency = 1
end

function PlaceManager:tryConfirmPlacement()
	if not self.placeToggled then
		return
	end

	local currPlaceFrame = self.currPlaceFrame

	local equippedToolMod = self:getEquippedToolMod()
	ClientMod:FireServer("tryPlaceStashTool", {
		toolName = equippedToolMod.toolName,
		placeFrame = currPlaceFrame,
	})
end

function PlaceManager:tickRender() end

function PlaceManager:toggleHintFrame(newBool)
	hintFrame.Visible = newBool
end

function PlaceManager:getEquippedToolMod()
	if not ClientMod.toolManager then
		return
	end
	return ClientMod.toolManager:getEquippedToolMod()
end

function PlaceManager:refreshStashTool()
	local chosenToolMod = self:getEquippedToolMod()

	ClientMod.sellManager:refreshEquippedItem()

	-- print("GOT CHOSEN TOOL MOD: ", chosenToolMod)

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
	local deleteToggled = ClientMod.deleteManager.deleteToggled
	local placeToggled = self.placeToggled

	-- NOTE: have to re-set maxactivationdistance here
	-- because stupid bug when prompt is disabled it resets the value

	local petEquipped = false
	local equippedToolMod = self:getEquippedToolMod()
	if equippedToolMod and equippedToolMod["race"] == "pet" then
		petEquipped = true
	end

	-- print("PET EQUIPPED: ", petEquipped)

	for _, petSpot in pairs(ClientMod.petSpots) do
		local interactPrompt = petSpot.interactPrompt
		if petSpot.petData then
			print("PET DATA: ", petSpot.petData)
			interactPrompt.Enabled = true
			interactPrompt.ActionText = "Pickup Brainrot"
		else
			-- print("NO PET DATA: ", petSpot.petSpotName)
			interactPrompt.ActionText = "Place"
			if petEquipped then
				interactPrompt.Enabled = true
			else
				interactPrompt.Enabled = false
			end
		end
	end

	for _, user in pairs(ClientMod.users) do
		user:toggleGiftPrompt(petEquipped)
	end
end

PlaceManager:init()

return PlaceManager
