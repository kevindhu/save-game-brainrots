local ClientMod = require(script.Parent:WaitForChild("ClientMod"))

local player = game.Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerGui = player:WaitForChild("PlayerGui")

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local luckGUI = playerGui:WaitForChild("LuckGUI")
local luckWizardFrame = luckGUI.LuckWizardFrame

local LuckInfo = require(game.ReplicatedStorage.LuckInfo)
local PetInfo = require(game.ReplicatedStorage.PetInfo)

local LuckWizardManager = {
	petMods = {},

	maxLuck = -1,
	currentLuck = -1,
}
LuckWizardManager.__index = LuckWizardManager

function LuckWizardManager.new(data)
	local u = {}
	setmetatable(u, LuckWizardManager)
	return u
end

function LuckWizardManager:init()
	self:addCons()

	self:toggle({
		newBool = false,
	})
end

function LuckWizardManager:addCons()
	local closeButton = luckWizardFrame.CloseButton
	ClientMod.buttonManager:addActivateCons(closeButton, function()
		self:toggle({
			newBool = false,
			animateClose = true,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(closeButton)

	-- add connections for adjustFrame
	local adjustFrame = luckWizardFrame.AdjustFrame
	local plusButton = adjustFrame.PlusButton
	local minusButton = adjustFrame.MinusButton

	ClientMod.buttonManager:addActivateCons(plusButton, function()
		ClientMod:FireServer("tryAdjustLuckWizard", {
			count = 1,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(plusButton)

	ClientMod.buttonManager:addActivateCons(minusButton, function()
		ClientMod:FireServer("tryAdjustLuckWizard", {
			count = -1,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(minusButton)

	local upgradeButton = luckWizardFrame.Requirements.UpgradeButton
	ClientMod.buttonManager:addActivateCons(upgradeButton, function()
		ClientMod:FireServer("tryUpgradeLuckWizard", {})
	end)
	ClientMod.buttonManager:addBasicButtonCons(upgradeButton)

	self.templateUnitItem = luckWizardFrame.Requirements.ItemList.TemplateItem
	self.templateUnitItem.Visible = false
end

function LuckWizardManager:initModel(model)
	-- print("INIT MODEL: ", model)

	local wizardModel = model:WaitForChild("LuckWizardModel")

	local rig = wizardModel:WaitForChild("Rig")
	local decorRig = wizardModel:WaitForChild("DecorRig")

	local bbPart = wizardModel:WaitForChild("BBPart")
	local titleBB = bbPart:WaitForChild("BB")
	titleBB.Adornee = bbPart

	titleBB.MaxDistance = 100

	ClientMod.uiScaleManager:addDistStrokeModsFromBB({
		bb = titleBB,
		adornee = bbPart,
		baseDistance = 25,
	})

	local torso = rig:WaitForChild("Torso")

	local promptText = "Adjust Luck"

	local prompt = ClientMod.uiManager:createPrompt({
		actionText = promptText,
		objectText = nil,
		name = "LuckWizardPrompt",
		holdDuration = 0.3,
		enabled = true,
		maxActivationDistance = 18,
		parent = torso,
	})

	prompt.Triggered:Connect(function()
		if not ClientMod.tutManager.completedTutMods["CompleteTutorial"] then
			return
		end

		ClientMod.soundManager:addBasicSound("Pop1", 0.2)

		self:toggle({
			newBool = true,
		})
		-- ClientMod:FireServer("tryUpdateTutMod", {
		-- 	targetClass = "GoToTimeWizard",
		-- 	updateCount = 1,
		-- })
	end)

	local vendorName = "LuckWizardVendor"
	local newVendorMod = {
		vendorName = vendorName,
		prompt = prompt,
		torso = torso,
		rig = rig,
		decorRig = decorRig,
		decorRigBaseScale = decorRig:GetScale(),
	}
	ClientMod.vendorManager:addVendorMod(newVendorMod)
end

function LuckWizardManager:updateLuck(data)
	local currentLuck = data["currentLuck"]
	local maxLuck = data["maxLuck"]

	local oldMaxLuck = self.maxLuck

	self.currentLuck = currentLuck
	self.maxLuck = maxLuck

	self.initialized = true

	local adjustFrame = luckWizardFrame.AdjustFrame
	adjustFrame.LuckTitle.Text = "x" .. currentLuck

	self:refreshAdjustFrame()

	if oldMaxLuck ~= maxLuck then
		self:refreshRequirements()
	end
end

function LuckWizardManager:refreshAdjustFrame()
	local adjustFrame = luckWizardFrame.AdjustFrame
	local plusButton = adjustFrame.PlusButton
	local minusButton = adjustFrame.MinusButton

	if self.currentLuck ~= self.maxLuck then
		plusButton.BackgroundColor3 = Color3.fromRGB(202, 211, 206)
		plusButton.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		plusButton.BackgroundColor3 = Color3.fromRGB(85, 89, 87)
		plusButton.Title.TextColor3 = Color3.fromRGB(152, 152, 152)
	end

	if self.currentLuck ~= 1 then
		minusButton.BackgroundColor3 = Color3.fromRGB(202, 211, 206)
		minusButton.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		minusButton.BackgroundColor3 = Color3.fromRGB(85, 89, 87)
		minusButton.Title.TextColor3 = Color3.fromRGB(152, 152, 152)
	end
end

function LuckWizardManager:refreshRequirements()
	-- clear all previous pet mods
	for _, petMod in pairs(self.petMods) do
		if petMod["frame"] then
			petMod["frame"]:Destroy()
		end
	end
	self.petMods = {}

	local luckRequirementData = LuckInfo.luckRequirementMap[tostring(self.maxLuck)]
	local petClasses = luckRequirementData["petClasses"]

	print("REFRESH REQUIREMENTS: ", petClasses)

	for _, petClass in pairs(petClasses) do
		self:newPetMod(petClass)
	end

	self:refreshPetMods()
	self:refreshProgressBar()
end

function LuckWizardManager:newPetMod(petClass)
	local frame = self.templateUnitItem:Clone()
	frame.Visible = true
	frame.Parent = self.templateUnitItem.Parent

	local innerFrame = frame.InnerFrame

	local petStats = PetInfo:getMeta(petClass)

	local rating = petStats["rating"]
	innerFrame.NameTitle.Text = petStats["alias"]
	ClientMod.ratingManager:applyRatingColor(innerFrame.NameTitle, rating)

	local icon = innerFrame.Icon
	icon.Image = PetInfo:getPetImage(petClass, "Normal")

	ClientMod.buttonManager:addButtonHoverCons({
		button = innerFrame,
		easingStyle = "Quad",
		expandRatio = 1.05, -- 1.08
		noIconRotate = true,
		timer = 0.15, -- 0.15
	})

	local newPetMod = {
		frame = frame,
		petClass = petClass,
	}
	self.petMods[petClass] = newPetMod

	return newPetMod
end

function LuckWizardManager:refreshPetMods()
	for _, petMod in pairs(self.petMods) do
		local petClass = petMod.petClass
		local frame = petMod.frame

		local icon = frame.InnerFrame.Icon

		-- see if pet exists in item stash or pet spot
		if self:checkHasPet(petClass) then
			icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
		else
			icon.ImageColor3 = Color3.fromRGB(0, 0, 0)
		end
	end
end

function LuckWizardManager:checkHasPet(petClass)
	for _, itemMod in pairs(ClientMod.itemStash.itemMods) do
		if itemMod["itemClass"] == petClass and not itemMod["favorited"] then
			return true
		end
	end

	for _, petSpot in pairs(ClientMod.petSpots) do
		if petSpot.userName ~= player.Name then
			continue
		end
		local petData = petSpot.petData
		if not petData then
			continue
		end
		if petData["petClass"] == petClass and not petData["favorited"] then
			return true
		end
	end

	return false
end

function LuckWizardManager:refreshProgressBar()
	if not self.initialized then
		return
	end

	local requirementsFrame = luckWizardFrame.Requirements
	local progressBar = requirementsFrame.ProgressBar

	local luckRequirementData = LuckInfo.luckRequirementMap[tostring(self.maxLuck)]
	local requiredCoins = luckRequirementData["coins"]

	local currentCoins = ClientMod.currManager.itemMods["Coins"] or 0

	local progressRatio = currentCoins / requiredCoins
	progressRatio = math.clamp(progressRatio, 0, 1)
	progressBar.CurrProgress.Size = UDim2.fromScale(progressRatio, 1)

	progressBar.Title.Text =
		string.format("$%s / $%s", Common.abbreviateNumber(currentCoins), Common.abbreviateNumber(requiredCoins))
end

function LuckWizardManager:toggle(data)
	local newBool = data["newBool"]

	if newBool == self.toggled then
		return
	end

	if newBool then
		ClientMod.uiManager:animateOpen(luckWizardFrame)
		ClientMod.uiManager:toggleOffAllGUI()
	end

	ClientMod.uiManager:interactMainFrame(luckWizardFrame, data)

	self.toggled = newBool
end

LuckWizardManager:init()

return LuckWizardManager
