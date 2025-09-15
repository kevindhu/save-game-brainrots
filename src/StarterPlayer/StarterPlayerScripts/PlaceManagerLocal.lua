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
		if Common.listContains({ "pet", "egg" }, race) then
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

function PlaceManager:tickRender()
	self:tickPlaceFrame()
end

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

	-- update pets
	for _, pet in pairs(ClientMod.pets) do
		local deletePrompt = pet.deletePrompt
		if not deletePrompt then
			continue
		end
		deletePrompt.Enabled = deleteToggled
		deletePrompt.MaxActivationDistance = 15
	end

	for _, egg in pairs(ClientMod.eggs) do
		local hatchPrompt = egg.hatchPrompt
		if not hatchPrompt then
			continue
		end
		hatchPrompt.Enabled = not deleteToggled and not placeToggled
		hatchPrompt.MaxActivationDistance = 12
	end

	for _, user in pairs(ClientMod.users) do
		user:toggleGiftPrompt(petEquipped)
	end
end

function PlaceManager:raycastPlaceModel(frame)
	local whiteList = {}

	local chosenToolMod = self:getEquippedToolMod()
	local race = chosenToolMod["race"]
	if race == "pet" then
		table.insert(whiteList, ClientMod.plotManager.floorPart)
		table.insert(whiteList, ClientMod.plotManager.eggFloorPart)
	elseif race == "egg" then
		table.insert(whiteList, ClientMod.plotManager.eggFloorPart)
		table.insert(whiteList, ClientMod.plotManager.floorPart)
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
	raycastParams.FilterDescendantsInstances = whiteList

	local raycastResult =
		workspace:Raycast(frame.Position + Vector3.new(0, 10, 0), Vector3.new(0, -20, 0), raycastParams)

	if not raycastResult then
		return CFrame.new(0, -100, 0)
	end

	local finalFrame = CFrame.new(raycastResult.Position) * Common.getCAngle(ClientMod.plotManager.floorPart.CFrame)
	return finalFrame
end

function PlaceManager:tickPlaceFrame()
	local user = ClientMod:getLocalUser()
	if not user then
		return
	end

	if not self.placeToggled then
		self:setPlaceFrame(Vector3.new(0, -100, 0))
		return
	end

	local userFrame = user.currFrame
	local userPos = userFrame.Position

	local cameraHorizontalDir = camera.CFrame.LookVector
	cameraHorizontalDir = Vector3.new(cameraHorizontalDir.X, 0, cameraHorizontalDir.Z)

	local newPos = userPos -- + cameraHorizontalDir * 15
	local newFrame = CFrame.new(newPos)
	newFrame = self:raycastPlaceModel(newFrame)

	self:setPlaceFrame(newFrame.Position)
end

function PlaceManager:setPlaceFrame(pos)
	local floorPart = ClientMod.plotManager.floorPart
	if not floorPart then
		return
	end

	local frame = CFrame.new(pos) * Common.getCAngle(floorPart.CFrame)
	self.currPlaceFrame = frame

	self:setPlaceModel(frame)
end

function PlaceManager:setPlaceModel(frame)
	local hOffset = self.placeCollideModel.PrimaryPart.Size.Y / 2
	local finalFrame = frame * CFrame.new(0, hOffset, 0)

	if self:checkValidPlacement() then
		for _, thing in pairs(self.placeCollideModel:GetDescendants()) do
			if not thing:IsA("BasePart") then
				continue
			end
			thing.Color = Color3.fromRGB(159, 159, 162)
		end
		self.placePrompt.Enabled = true
	else
		for _, thing in pairs(self.placeCollideModel:GetDescendants()) do
			if not thing:IsA("BasePart") then
				continue
			end
			thing.Color = Color3.fromRGB(141, 3, 6)
		end
		self.placePrompt.Enabled = false
	end

	self.placeCollideModel:SetPrimaryPartCFrame(finalFrame)
end

function PlaceManager:checkValidPlacement()
	local chosenToolMod = self:getEquippedToolMod()
	if not chosenToolMod then
		return false
	end

	local race = chosenToolMod["race"]
	if race == "pet" then
		-- TODO: check if enough room
		return true
	elseif race == "egg" then
		local placeCollidePart = self.placeCollidePart

		-- see if this placeCollidePart collides with other eggs
		local filter = OverlapParams.new()
		filter.FilterType = Enum.RaycastFilterType.Include
		for _, egg in pairs(ClientMod.eggs) do
			filter:AddToFilter(egg.placeCollidePart)
		end

		local foundParts = game.Workspace:GetPartsInPart(placeCollidePart, filter)
		if len(foundParts) > 0 then
			-- not valid
			return false
		end

		-- check raycast to the ground
		local whiteList = {
			ClientMod.plotManager.eggFloorPart,
			ClientMod.plotManager.floorPart,
		}
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
		raycastParams.FilterDescendantsInstances = whiteList

		local raycastResult =
			workspace:Raycast(placeCollidePart.Position + Vector3.new(0, 10, 0), Vector3.new(0, -20, 0), raycastParams)

		if not raycastResult then
			return false
		end

		return true
	end
end

PlaceManager:init()

return PlaceManager
