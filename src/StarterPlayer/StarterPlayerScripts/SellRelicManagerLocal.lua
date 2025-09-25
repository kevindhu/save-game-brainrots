local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local shopGUI = playerGui:WaitForChild("ShopGUI")
local sellRelicFrame = shopGUI.SellRelicFrame

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local RelicInfo = require(game.ReplicatedStorage.RelicInfo)

local confirmSellAllModal = shopGUI.ConfirmSellAllRelicsModal

local SellRelicManager = {
	itemMods = {},
}

function SellRelicManager:init()
	self:addCons()
	self:addConfirmSellAllCons()

	self:toggle({
		newBool = false,
	})
	self:toggleConfirmSellAllModal(false)

	routine(function()
		wait(1)
		self:refreshEquippedItem()
	end)
end

function SellRelicManager:addCons()
	local closeButton = sellRelicFrame.CloseButton
	ClientMod.buttonManager:addActivateCons(closeButton, function()
		self:toggle({
			newBool = false,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(closeButton)

	-- sell all cons
	local sellAllFrame = sellRelicFrame.InnerFrame.SellAllFrame
	local sellEquippedFrame = sellRelicFrame.InnerFrame.SellEquippedFrame

	local sellAllButton = sellAllFrame.InnerFrame.SellButton
	ClientMod.buttonManager:addActivateCons(sellAllButton, function()
		confirmSellAllModal.DescriptionTitle.Text = string.format(
			"Would you like to sell %s for %s?",
			Common.addRichTextColor(
				Common.abbreviateNumber(self.sellAllCount, 1) .. " relics",
				Color3.fromRGB(85, 249, 255)
			),
			Common.addRichTextColor(
				"$" .. Common.abbreviateNumber(self.totalSellPrice, 1),
				Color3.fromRGB(255, 230, 86)
			)
		)
		self:toggleConfirmSellAllModal(true)
		self:toggle({
			newBool = false,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(sellAllButton)

	-- sell equipped cons
	local sellEquippedButton = sellEquippedFrame.InnerFrame.SellButton
	ClientMod.buttonManager:addActivateCons(sellEquippedButton, function()
		local equippedToolMod = ClientMod.toolManager:getEquippedToolMod()

		local toolName = equippedToolMod.toolName
		print("SELLING ALL: ", toolName)

		ClientMod:FireServer("trySellItem", {
			itemName = equippedToolMod.toolName,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(sellEquippedButton)
end

function SellRelicManager:addConfirmSellAllCons()
	local confirmButton = confirmSellAllModal.Confirm
	ClientMod.buttonManager:addActivateCons(confirmButton, function()
		ClientMod:FireServer("trySellAllToolItems", {
			race = "relic",
		})
		self:toggleConfirmSellAllModal(false)
		self:toggle({
			newBool = true,
		})
	end)

	local cancelButton = confirmSellAllModal.Cancel
	ClientMod.buttonManager:addActivateCons(cancelButton, function()
		self:toggleConfirmSellAllModal(false)
		self:toggle({
			newBool = true,
		})
	end)
end

function SellRelicManager:toggleConfirmSellAllModal(newBool)
	confirmSellAllModal.Visible = newBool
end

function SellRelicManager:refreshEquippedItem()
	local sellEquippedFrame = sellRelicFrame.InnerFrame.SellEquippedFrame
	local innerFrame = sellEquippedFrame.InnerFrame
	local cannotSellFrame = sellEquippedFrame.CannotSellFrame

	local equippedToolMod = ClientMod.toolManager:getEquippedToolMod()

	if not equippedToolMod then
		innerFrame.Visible = false
		cannotSellFrame.Visible = true
		return
	end

	-- local itemName = data["itemName"]
	local itemClass = equippedToolMod["toolClass"]
	local race = equippedToolMod["race"]
	local mutationClass = equippedToolMod["mutationClass"]

	if race ~= "relic" then
		innerFrame.Visible = false
		cannotSellFrame.Visible = true
		return
	end

	innerFrame.Visible = true
	cannotSellFrame.Visible = false

	local relicStats = RelicInfo:getMeta(itemClass)

	innerFrame.Icon.Image = relicStats["image"]

	local sellPrice = RelicInfo:calculateSellPrice({
		relicClass = itemClass,
		mutationClass = mutationClass,
	})

	innerFrame.NameTitle.Text = relicStats["alias"]
	innerFrame.CoinsTitle.Text = "$" .. Common.abbreviateNumber(sellPrice, 1)
end

function SellRelicManager:refreshSellAllFrame()
	local totalSellPrice = 0
	local sellAllCount = 0
	for _, itemMod in pairs(ClientMod.itemStash.itemMods) do
		local race = itemMod["race"]
		if race ~= "relic" then
			continue
		end
		if itemMod["deleted"] then
			continue
		end
		if itemMod["favorited"] then
			continue
		end

		local sellPrice = RelicInfo:calculateSellPrice({
			relicClass = itemMod["itemClass"],
		})
		totalSellPrice += sellPrice
		sellAllCount += 1
	end

	local sellAllFrame = sellRelicFrame.InnerFrame.SellAllFrame
	sellAllFrame.InnerFrame.TotalPriceTitle.Text = "$" .. Common.abbreviateNumber(totalSellPrice, 1)

	self.totalSellPrice = totalSellPrice
	self.sellAllCount = sellAllCount
end

function SellRelicManager:toggle(data)
	local newBool = data["newBool"]

	if newBool == self.toggled then
		return
	end

	if newBool then
		ClientMod.uiManager:animateOpen(sellRelicFrame)
		ClientMod.uiManager:toggleOffAllGUI()
	end

	ClientMod.uiManager:interactMainFrame(sellRelicFrame, data)

	self.toggled = newBool
end

SellRelicManager:init()

return SellRelicManager
