local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local autoSellGUI = playerGui:WaitForChild("AutoSellGUI")
local autoSellFrame = autoSellGUI.AutoSellFrame

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local RatingInfo = require(game.ReplicatedStorage.RatingInfo)

local SellPetManager = {
	ratingMods = {},
}

function SellPetManager:init()
	self:addCons()

	self:toggle({
		newBool = false,
	})
end

function SellPetManager:addCons()
	local closeButton = autoSellFrame.CloseButton
	ClientMod.buttonManager:addActivateCons(closeButton, function()
		self:toggle({
			newBool = false,
		})
		ClientMod.itemStash:toggle({
			newBool = true,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(closeButton)

	self.templateRatingItem = autoSellFrame.ItemList.TemplateItem
	self.templateRatingItem.Visible = false
	self.templateRatingItem.BackgroundTransparency = 1
end

function SellPetManager:initAllRatingMods()
	for index, rating in pairs(RatingInfo.ratingList) do
		self:initRatingMod(rating, index)
	end
end

function SellPetManager:initRatingMod(rating, index)
	local frame = self.templateRatingItem:Clone()
	frame.Visible = true
	frame.Parent = self.templateRatingItem.Parent

	frame.LayoutOrder = -index

	local buttonFrame = frame.ButtonFrame
	ClientMod.buttonManager:addActivateCons(buttonFrame, function()
		ClientMod:FireServer("tryToggleAutoSellRatingMod", {
			rating = rating,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(buttonFrame)

	buttonFrame.Title.Text = rating

	local newRatingMod = {
		frame = frame,
	}
	self.ratingMods[rating] = newRatingMod
end

function SellPetManager:updateRatingMods(data)
	-- clear all previous ratingMods
	for _, ratingMod in pairs(self.ratingMods) do
		ratingMod["frame"]:Destroy()
	end
	self.ratingMods = {}

	-- remake all ratingMods
	self:initAllRatingMods()

	for ratingClass, ratingData in pairs(data["ratingMods"]) do
		local ratingMod = self.ratingMods[ratingClass]
		for k, v in pairs(ratingData) do
			ratingMod[k] = v
		end
	end

	self:refreshAllRatingMods()

	ClientMod.saveManager:refreshCurrWaveModFrame()
end

function SellPetManager:refreshAllRatingMods()
	for ratingClass, ratingMod in pairs(self.ratingMods) do
		local frame = ratingMod["frame"]
		local toggled = ratingMod["toggled"]

		local buttonFrame = frame.ButtonFrame

		if toggled then
			ClientMod.ratingManager:applyRatingColor(buttonFrame, ratingClass)
			buttonFrame.Title.UIStroke.Color = Color3.fromRGB(0, 0, 0)
		else
			buttonFrame.BackgroundColor3 = Color3.fromRGB(222, 222, 222)
			buttonFrame.Title.UIStroke.Color = Color3.fromRGB(158, 158, 158)
		end
	end
end

function SellPetManager:toggle(data)
	local newBool = data["newBool"]

	if newBool == self.toggled then
		return
	end

	if newBool then
		ClientMod.uiManager:animateOpen(autoSellFrame)
		ClientMod.uiManager:toggleOffAllGUI()
	end

	ClientMod.uiManager:interactMainFrame(autoSellFrame, data)

	self.toggled = newBool
end

SellPetManager:init()

return SellPetManager
