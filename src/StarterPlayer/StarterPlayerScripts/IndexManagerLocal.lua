local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local PetInfo = require(game.ReplicatedStorage.PetInfo)
local IndexInfo = require(game.ReplicatedStorage.IndexInfo)
local ItemInfo = require(game.ReplicatedStorage.ItemInfo)
local RatingInfo = require(game.ReplicatedStorage.RatingInfo)
local MutationInfo = require(game.ReplicatedStorage.MutationInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local buttonGUI = playerGui:WaitForChild("ButtonGUI")
local buttonsFrame = buttonGUI.LeftFrame.ButtonsFrame
local indexButton = buttonsFrame.Index

local indexGUI = playerGui:WaitForChild("IndexGUI")
local indexFrame = indexGUI.IndexFrame
local outerFrame = indexFrame.MainFrame.OuterFrame

local IndexManager = {
	petMods = {},
	unlockedPetMap = {},
	rewardItemMods = {},

	rewardLevel = 1,
}
IndexManager.__index = IndexManager

function IndexManager:init()
	self:addCons()

	self:toggle({
		newBool = false,
	})

	routine(function()
		wait(1)

		self:initTabList()

		self:initAllPetMods({
			mutationClass = "Normal",
		})
	end)
end

function IndexManager:initTabList()
	local tabList = {
		"Normal",
		"Gold",
		"Diamond",
		"Bubblegum",

		-- "Volcanic",
		-- "Rainbow",
	}

	local tabListFrame = indexFrame.TabFrame.TabListFrame
	tabListFrame.BackgroundTransparency = 1

	local templateTabItem = tabListFrame.TemplateItem
	templateTabItem.Visible = false
	self.templateTabItem = templateTabItem

	for _, tabClass in pairs(tabList) do
		local tabButton = self.templateTabItem:Clone()
		tabButton.Visible = true
		tabButton.Parent = self.templateTabItem.Parent

		local title = tabButton.InnerFrame.Title
		title.Text = tabClass

		ClientMod.buttonManager:addActivateCons(tabButton, function()
			self:initAllPetMods({
				mutationClass = tabClass,
			})
			self.chosenMutationClass = tabClass

			self:refreshTotalUnlocked()
		end)

		ClientMod.buttonManager:addButtonPressCons({
			button = tabButton,
			animatePress = true,
		})

		local mutationClass = tabClass
		if mutationClass ~= "Normal" then
			ClientMod.mutationManager:applyMutationColor(title, mutationClass)
		end
	end
end

function IndexManager:addCons()
	indexFrame.BackgroundTransparency = 1

	ClientMod.hintManager:addHintFrameCons({
		frame = indexButton,
		alias = "Index",
	})

	ClientMod.buttonManager:addActivateCons(indexButton, function()
		self:toggle({
			newBool = not self.toggled,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(indexButton)

	local closeButton = indexFrame.MainFrame.CloseButton
	ClientMod.buttonManager:addActivateCons(closeButton, function()
		self:toggle({
			newBool = false,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(closeButton)

	outerFrame.ItemList.BackgroundTransparency = 1

	self.templatePetItem = outerFrame.ItemList.TemplateItem
	self.templatePetItem.Visible = false

	-- local rewardFrame = indexFrame.MainFrame.RewardFrame
	-- rewardFrame.Visible = false

	-- self.templateRewardItem = rewardFrame.InnerFrame.ItemList.TemplateItem
	-- self.templateRewardItem.Visible = false
end

function IndexManager:toggle(data)
	local newBool = data["newBool"]

	if newBool then
		ClientMod.uiManager:animateOpen(indexFrame)
		ClientMod.uiManager:toggleOffAllGUI()

		-- do the animation every time
		self:refreshTotalUnlocked()
	end

	ClientMod.uiManager:interactMainFrame(indexFrame, data)

	self.toggled = newBool
end

function IndexManager:initAllPetMods(data)
	local mutationClass = data["mutationClass"]

	-- clear all previous petMods
	for _, petMod in pairs(self.petMods) do
		petMod["frame"]:Destroy()
	end
	self.petMods = {}

	for index, petClass in pairs(PetInfo.petOrderList) do
		self:newPetMod(petClass, index, mutationClass)
	end

	self:refreshAllPetMods()
end

function IndexManager:newPetMod(petClass, index, mutationClass)
	local frame = self.templatePetItem:Clone()
	frame.Visible = true
	frame.Parent = self.templatePetItem.Parent

	local petStats = PetInfo:getMeta(petClass)

	local innerFrame = frame.InnerFrame

	frame.BackgroundTransparency = 1 -- 0.5

	local rating = petStats["rating"]
	ClientMod.ratingManager:applyRatingColor(innerFrame.NameTitle, rating)
	ClientMod.ratingManager:applyRatingColor(innerFrame.UnknownTitle, rating)

	local mutationTitle = innerFrame.MutationTitle
	ClientMod.mutationManager:applyMutationColor(mutationTitle, mutationClass)

	-- innerFrame.UIStroke.UIGradient.Color = RatingInfo.ratingGradientColorMap[rating]

	local ratingGradient = RatingInfo.ratingGradientColorMap[rating]
	innerFrame.Gradient.UIGradient.Color = ratingGradient

	local icon = innerFrame.Icon
	icon.Image = PetInfo:getPetImage(petClass, mutationClass)

	frame.LayoutOrder = index

	ClientMod.buttonManager:addButtonHoverCons({
		button = innerFrame,
		easingStyle = "Quad",
		expandRatio = 1.05, -- 1.08
		noIconRotate = true,
		timer = 0.15, -- 0.15

		-- icon
		expandIcon = false,

		-- noDisableHover = true,
	})

	local newPetMod = {
		frame = frame,
		petClass = petClass,
		index = index,
		mutationClass = mutationClass,
	}
	self.petMods[petClass] = newPetMod
end

function IndexManager:updateIndexRewardLevel(data)
	local rewardLevel = data["rewardLevel"]
	self.rewardLevel = rewardLevel

	-- add rewards later (JUST COPY TRADE BRAINROT AND MAKE IT VERY SIMPLE)
	if true then
		return
	end

	-- remove all previous rewardItemMods
	for _, rewardItemMod in pairs(self.rewardItemMods) do
		rewardItemMod["frame"]:Destroy()
	end
	self.rewardItemMods = {}

	local rewardStats = IndexInfo:getMeta("Reward" .. self.rewardLevel)
	local rewardItems = rewardStats["rewardItems"]
	for itemClass, itemData in pairs(rewardItems) do
		self:newRewardItem(itemClass, itemData)
	end

	self:refreshTotalUnlocked()
end

function IndexManager:newRewardItem(rewardClass, itemData)
	local frame = self.templateRewardItem:Clone()
	frame.Visible = true
	frame.Parent = self.templateRewardItem.Parent

	-- local icon = frame.Icon

	local innerFrame = frame.InnerFrame
	local topTitle = innerFrame.TopFrame.Title

	local itemClass
	if itemData["coinMultiplier"] then
		local coinMultiplier = itemData["coinMultiplier"]
		itemClass = "Coins"
		topTitle.Text = string.format("+x%s Multiplier", coinMultiplier)
	elseif itemData["coinCount"] then
		itemClass = "Coins"
		topTitle.Text = "x" .. Common.abbreviateNumber(itemData["coinCount"])
	end

	local itemStats = ItemInfo:getMeta(itemClass)
	innerFrame.Icon.Image = itemStats["image"]

	local newRewardItemMod = {
		rewardClass = rewardClass,
		frame = frame,
	}
	self.rewardItemMods[rewardClass] = newRewardItemMod
end

function IndexManager:updateUnlockedPets(data)
	local unlockedPetMap = data["unlockedPetMap"]
	self.unlockedPetMap = unlockedPetMap

	self:refreshAllPetMods()
	self:refreshTotalUnlocked()
end

function IndexManager:refreshAllPetMods()
	-- print("REFRESH ALL PET MODS: ", self.unlockedPetMap, self.petMods)

	for _, petMod in pairs(self.petMods) do
		local petClass = petMod.petClass
		local mutationClass = petMod.mutationClass

		local frame = petMod.frame

		local id = petClass .. "_" .. mutationClass

		local innerFrame = frame.InnerFrame
		local icon = innerFrame.Icon

		-- local petCount = ClientMod.petCountManager:getTotalPetCount(petClass, mutationClass)

		local hasUnlocked = self.unlockedPetMap[id]

		local petStats = PetInfo:getMeta(petClass)

		local nameTitle = innerFrame.NameTitle
		if hasUnlocked then
			icon.ImageColor3 = Color3.fromRGB(255, 255, 255)
			innerFrame.NameTitle.Visible = true
			innerFrame.UnknownTitle.Visible = false

			nameTitle.Text = petStats["alias"]
		else
			icon.ImageColor3 = Color3.fromRGB(0, 0, 0)
			innerFrame.NameTitle.Visible = false
			innerFrame.UnknownTitle.Visible = true

			nameTitle.Text = "???"
		end
	end
end

function IndexManager:refreshTotalUnlocked()
	local topFrame = indexFrame.MainFrame.TopFrame

	local progressBar = topFrame.CountBar.ProgressBar
	progressBar.Size = UDim2.fromScale(0, 1)

	local totalPetList = PetInfo.petOrderList
	local maxPetCount = len(totalPetList)

	local currPetCount = 0
	for _, petClass in pairs(totalPetList) do
		local id = petClass
		if self.chosenMutationClass then
			id = id .. "_" .. self.chosenMutationClass
		end

		if self.unlockedPetMap[id] then
			currPetCount += 1
		end
	end

	local progressRatio = math.min(currPetCount / maxPetCount, 1)

	topFrame.CountBar.Title.Text = string.format("Discovered: %s/%s", currPetCount, maxPetCount)

	ClientMod.tweenManager:createTween({
		target = progressBar,
		timer = 1,
		easingStyle = "Quad",
		easingDirection = "Out",
		goal = {
			Size = UDim2.fromScale(progressRatio, 1),
		},
	})
end

IndexManager:init()

return IndexManager
