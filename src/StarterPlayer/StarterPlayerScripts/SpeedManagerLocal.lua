local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local SpeedInfo = require(game.ReplicatedStorage.SpeedInfo)
local RatingInfo = require(game.ReplicatedStorage.RatingInfo)

local speedGUI = playerGui:WaitForChild("SpeedGUI")
local speedFrame = speedGUI.SpeedFrame

local SpeedManager = {
	speed = 1,

	ratingMods = {},
	speedMods = {},

	globalSpeedMods = {},
}

function SpeedManager:init()
	self:addCons()

	self:initAllRatings()

	self:toggle({
		newBool = false,
	})
end

function SpeedManager:addCons()
	local closeButton = speedFrame.CloseButton
	ClientMod.buttonManager:addActivateCons(closeButton, function()
		local chosenTutMod = ClientMod.tutManager.chosenTutMod
		if chosenTutMod and chosenTutMod["targetClass"] == "Buy2xSpeedCommon" then
			return
		end

		ClientMod:FireServer("tryUpdateTutMod", {
			targetClass = "CloseTimeWizard",
			updateCount = 1,
		})
		self:toggle({
			newBool = false,
			animateClose = true,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(closeButton)

	self.templateRatingItem = speedFrame.RatingItemList.TemplateItem
	self.templateRatingItem.Visible = false

	self.templateRatingItem.BackgroundTransparency = 1
end

function SpeedManager:toggle(data)
	local newBool = data["newBool"]

	if newBool == self.toggled then
		return
	end

	if newBool then
		ClientMod.uiManager:animateOpen(speedFrame)
		ClientMod.uiManager:toggleOffAllGUI()
	end

	ClientMod.uiManager:interactMainFrame(speedFrame, data)

	self.toggled = newBool
end

function SpeedManager:initModel(model)
	-- print("INIT MODEL: ", model)

	local wizardModel = model:WaitForChild("TimeWizardModel")

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

	local promptText = "Open Time Wizard"

	local prompt = ClientMod.uiManager:createPrompt({
		actionText = promptText,
		objectText = nil,
		name = "TimeWizardPrompt",
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
		ClientMod:FireServer("tryUpdateTutMod", {
			targetClass = "GoToTimeWizard",
			updateCount = 1,
		})
	end)

	local vendorName = "TimeWizardVendor"
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

function SpeedManager:initAllRatings()
	local ratingList = {
		"Common",
		"Uncommon",
		"Rare",
		"Epic",
		"Legendary",
		"Mythic",
		"Secret",
	}
	for index, rating in pairs(ratingList) do
		local frame = self.templateRatingItem:Clone()
		frame.Visible = true
		frame.Parent = self.templateRatingItem.Parent

		local itemList = frame.ItemList
		itemList.BackgroundTransparency = 1

		local templateSpeedItem = itemList.TemplateItem
		templateSpeedItem.Visible = false

		frame.LayoutOrder = index

		frame.NameTitle.Text = rating

		ClientMod.ratingManager:applyRatingColor(frame.NameTitle, rating)

		local newRatingMod = {
			index = index,
			frame = frame,
			rating = rating,

			templateSpeedItem = templateSpeedItem,
		}
		self.ratingMods[rating] = newRatingMod

		for i = 1, 3 do
			self:initSpeedItem(rating, i)
		end
	end
	for _, speedMod in pairs(self.speedMods) do
		self:refreshSpeedMod(speedMod)
	end
end

function SpeedManager:getSpeedName(rating, speedIndex)
	return rating .. "Speed" .. speedIndex
end

function SpeedManager:initSpeedItem(rating, speedIndex)
	local ratingMod = self.ratingMods[rating]

	local templateSpeedItem = ratingMod["templateSpeedItem"]

	local frame = templateSpeedItem:Clone()
	frame.Visible = true
	frame.Parent = templateSpeedItem.Parent

	frame.BackgroundTransparency = 1

	frame.LayoutOrder = speedIndex

	local speedTitle = frame.ButtonFrame.SpeedTitle

	speedTitle.Text = speedIndex .. "x"
	if speedIndex == 2 then
		speedTitle.TextColor3 = Color3.fromRGB(255, 211, 90)
	elseif speedIndex == 3 then
		speedTitle.TextColor3 = Color3.fromRGB(26, 251, 255)
	end

	local speedName = self:getSpeedName(rating, speedIndex)
	local newSpeedMod = {
		speedName = speedName,
		frame = frame,
		rating = rating,
		speedIndex = speedIndex,

		unlocked = false,
		hidden = true,
	}
	self.speedMods[speedName] = newSpeedMod

	local buttonFrame = frame.ButtonFrame
	ClientMod.buttonManager:addActivateCons(buttonFrame, function()
		ClientMod:FireServer("tryToggleSpeedMod", {
			rating = rating,
			speedIndex = speedIndex,
		})
	end)

	ClientMod.buttonManager:addActivateCons(buttonFrame.BuyButton, function()
		ClientMod:FireServer("tryUnlockSpeedMod", {
			rating = rating,
			speedIndex = speedIndex,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(buttonFrame)

	if rating == "Common" and speedIndex == 2 then
		ClientMod.tutManager.speedHintItemFrame = buttonFrame.BuyButton.Cover
	end
end

function SpeedManager:updateAllSpeedMods(data)
	local userName = data["userName"]
	local fullSpeedModData = data["fullSpeedModData"]

	self.globalSpeedMods[userName] = Common.deepCopy(fullSpeedModData)

	-- print("UPDATING ALL SPEED MODS: ", userName, fullSpeedModData)

	if player.Name == userName then
		for _, speedModData in pairs(fullSpeedModData) do
			local speedName = speedModData["speedName"]
			local speedMod = self.speedMods[speedName]
			if not speedMod then
				warn("NO SPEEDMOD NAMED: ", speedName)
				return
			end
			for k, v in pairs(speedModData) do
				speedMod[k] = v
			end

			self:refreshSpeedMod(speedMod)
		end
	end

	ClientMod.saveManager:refreshSpeedFrame()
end

function SpeedManager:refreshSpeedMod(speedMod)
	local frame = speedMod["frame"]
	local rating = speedMod["rating"]
	local speedIndex = speedMod["speedIndex"]

	local unlocked = speedMod["unlocked"]
	local toggled = speedMod["toggled"]
	local hidden = speedMod["hidden"]

	local buyButton = frame.ButtonFrame.BuyButton

	if hidden then
		frame.ButtonFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		frame.ButtonFrame.Active = false

		buyButton.Visible = false
		return
	end

	frame.ButtonFrame.Active = true

	if unlocked then
		if toggled then
			frame.ButtonFrame.BackgroundColor3 = Color3.fromRGB(82, 236, 11)
		else
			frame.ButtonFrame.BackgroundColor3 = Color3.fromRGB(202, 211, 206)
		end

		buyButton.Visible = false
	else
		local speedPrice = SpeedInfo.speedPriceMap[rating][tostring(speedIndex)]

		-- print("SPEED PRICE: ", speedPrice, rating, speedIndex)

		buyButton.Visible = true
		buyButton.Title.Text = "$" .. Common.abbreviateNumber(speedPrice, 1)
	end
end

function SpeedManager:chooseNextSpeedMod()
	local currWaveMod = ClientMod.saveManager:getWaveMod(player.Name)
	if not currWaveMod then
		warn("!!! NO CURRENT WAVE MOD FOUND: ", player.Name)
		return
	end

	local rating = currWaveMod["rating"]

	local startIndex = 1

	-- see if any speed mods are unlocked
	local unlockedList = {}
	for i = 1, 3 do
		local speedName = self:getSpeedName(rating, i)
		local speedMod = self.speedMods[speedName]
		if speedMod["unlocked"] then
			table.insert(unlockedList, i)
		end
		if speedMod["toggled"] then
			startIndex = i
		end
	end

	if len(unlockedList) == 1 then
		local ratingColor = RatingInfo["ratingColorMap"][rating]
		ClientMod.notifyManager:newNotifyMod({
			txt = string.format(
				"Buy %s from the %s!",
				Common.addRichTextColor(rating, ratingColor),
				Common.addRichTextColor("Time Wizard", Color3.fromRGB(90, 255, 147))
			),
			color = Color3.fromRGB(255, 255, 255),
			-- soundClass = "ButtonClick1",
			-- volume = 0.1,
		})
		ClientMod.soundManager:addBasicSound("Pop1", 0.2)
		return
	end

	-- Find current position in unlocked list
	local currentPos = 1
	for i, unlockedIndex in ipairs(unlockedList) do
		if unlockedIndex == startIndex then
			currentPos = i
			break
		end
	end

	-- Get next position in unlocked list (wrapping around)
	local nextPos = currentPos % #unlockedList + 1
	local nextIndex = unlockedList[nextPos]

	-- print("NEXT INDEX: ", nextIndex, currentPos)

	-- toggle the next speed mod
	ClientMod:FireServer("tryToggleSpeedMod", {
		rating = rating,
		speedIndex = nextIndex,
	})
end

function SpeedManager:getSpeed(userName)
	local currWaveMod = ClientMod.saveManager:getWaveMod(userName)
	if not currWaveMod then
		-- warn("!!! NO CURRENT WAVE MOD FOUND: ", userName)
		return 1
	end

	local rating = currWaveMod["rating"]

	local speedMods = self.globalSpeedMods[userName]
	if not speedMods then
		-- warn("!!! NO SPEED MODS FOUND: ", userName)
		return 1
	end

	local chosenSpeedIndex = nil
	for i = 1, 3 do
		local speedName = self:getSpeedName(rating, i)
		local speedMod = speedMods[speedName]
		if speedMod["toggled"] then
			chosenSpeedIndex = speedMod["speedIndex"]
			break
		end
	end

	-- print("GOT CHOSEN SPEED INDEX: ", chosenSpeedIndex)

	return chosenSpeedIndex

	-- return self.speed
end

SpeedManager:init()

return SpeedManager
