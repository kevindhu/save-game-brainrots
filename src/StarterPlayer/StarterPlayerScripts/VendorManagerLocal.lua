local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local VendorManager = {
	vendorMods = {},
}
VendorManager.__index = VendorManager

function VendorManager:init()
	routine(function()
		local chooseHighlight = Instance.new("Highlight")
		self.chooseHighlight = chooseHighlight
		chooseHighlight.Name = "ChooseHighlight"
		chooseHighlight.FillTransparency = 1 -- 0.5
		self.chooseHighlight.Parent = game.Workspace.VendorHighlightModels
		self.chooseHighlight.Adornee = nil

		self:initModels()
	end)
end

function VendorManager:initModels()
	local shopList = {
		"EggShop",
		"SellPets",
	}

	for _, shopClass in pairs(shopList) do
		self:newVendorMod(shopClass)
	end
end

local MAX_ACTIVATION_DISTANCE = 18

function VendorManager:newVendorMod(shopClass)
	local vendorModel = game.Workspace:WaitForChild(shopClass .. "Model")

	local rig = vendorModel:WaitForChild("Rig")
	local decorRig = vendorModel:WaitForChild("DecorRig")

	local bbPart = vendorModel:WaitForChild("BBPart")
	local titleBB = bbPart:WaitForChild("BB")
	titleBB.Adornee = bbPart

	titleBB.MaxDistance = 100

	ClientMod.uiScaleManager:addDistStrokeModsFromBB({
		bb = titleBB,
		adornee = bbPart,
		baseDistance = 25,
	})

	local torso = rig:WaitForChild("Torso")

	local promptText = "Buy"
	if shopClass == "SellUnit" then
		promptText = "Sell"
	end

	local prompt = ClientMod.uiManager:createPrompt({
		actionText = promptText,
		objectText = nil,
		name = "VendorPrompt",
		holdDuration = 0.3,
		enabled = true,
		maxActivationDistance = MAX_ACTIVATION_DISTANCE,
		parent = torso,
	})

	prompt.Triggered:Connect(function()
		-- ClientMod.buttonManager:addButtonPressSound()
		ClientMod.soundManager:addBasicSound("Pop1")

		if shopClass == "SellPets" then
			ClientMod.sellManager:toggle({
				newBool = true,
			})
		elseif shopClass == "EggShop" then
			ClientMod.buyEggManager:toggle({
				newBool = true,
			})
		end
	end)

	local newVendorMod = {
		vendorModel = vendorModel,
		prompt = prompt,
		torso = torso,
		rig = rig,
		decorRig = decorRig,
		decorRigBaseScale = decorRig:GetScale(),
	}
	self.vendorMods[shopClass] = newVendorMod
end

function VendorManager:tick()
	local userFrame = ClientMod:getLocalUser().currFrame
	if not userFrame then
		return
	end

	local chosenVendorMod = nil
	local closestDistance = MAX_ACTIVATION_DISTANCE
	for _, vendorMod in pairs(self.vendorMods) do
		local torso = vendorMod.torso
		if not torso then
			continue
		end

		local distance = (torso.Position - userFrame.Position).Magnitude

		if distance < closestDistance then
			closestDistance = distance
			chosenVendorMod = vendorMod
		end
	end

	if not chosenVendorMod then
		self.chooseHighlight.Adornee = nil
		self.chosenVendorMod = nil
		return
	end

	self:chooseVendorMod(chosenVendorMod)
end

function VendorManager:chooseVendorMod(vendorMod)
	if self.chosenVendorMod == vendorMod then
		return
	end
	self.chosenVendorMod = vendorMod

	local decorRig = vendorMod["decorRig"]
	self.chooseHighlight.Adornee = decorRig

	local startScale = vendorMod["decorRigBaseScale"]
	local endScale = startScale * 1.035

	routine(function()
		local outTimer = 0.26
		-- animate rig
		ClientMod.tweenManager:createTween({
			target = decorRig,
			timer = outTimer,
			easingStyle = "Quad",
			easingDirection = "Out",
			goal = { Scale = endScale },
		})

		wait(outTimer)

		local inTimer = 0.25
		ClientMod.tweenManager:createTween({
			target = decorRig,
			timer = inTimer,
			easingStyle = "Quad",
			easingDirection = "In",
			goal = { Scale = startScale },
		})
	end)
end

VendorManager:init()

return VendorManager
