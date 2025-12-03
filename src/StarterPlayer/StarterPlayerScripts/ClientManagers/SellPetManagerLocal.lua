local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local shopGUI = playerGui:WaitForChild("ShopGUI")
local sellPetFrame = shopGUI.SellPetFrame

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetInfo = require(game.ReplicatedStorage.Data.PetInfo)

local confirmSellAllModal = shopGUI.ConfirmSellAllPetsModal

local SellPetManager = {
	itemMods = {},
}

function SellPetManager:init()
	self:addCons()
	self:addConfirmSellAllCons()

	self:toggle({
		newBool = false,
	})
	self:toggleConfirmSellAllModal(false)
end

function SellPetManager:addCons()
	local closeButton = sellPetFrame.CloseButton
	ClientMod.buttonManager:addActivateCons(closeButton, function()
		self:toggle({
			newBool = false,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(closeButton)

	-- sell all cons
	local sellAllFrame = sellPetFrame.InnerFrame.SellAllFrame
	local sellEquippedFrame = sellPetFrame.InnerFrame.SellEquippedFrame

	local sellAllButton = sellAllFrame.InnerFrame.SellButton
	ClientMod.buttonManager:addActivateCons(sellAllButton, function()
		confirmSellAllModal.DescriptionTitle.Text = string.format(
			"Would you like to sell %s for %s?",
			Common.addRichTextColor(
				Common.abbreviateNumber(self.sellAllCount, 1) .. " brainrots",
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

function SellPetManager:addConfirmSellAllCons()
	local confirmButton = confirmSellAllModal.Confirm
	ClientMod.buttonManager:addActivateCons(confirmButton, function()
		ClientMod:FireServer("trySellAllToolItems", {
			race = "pet",
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

function SellPetManager:toggleConfirmSellAllModal(newBool)
	confirmSellAllModal.Visible = newBool
end

function SellPetManager:refreshEquippedItem()
	local sellEquippedFrame = sellPetFrame.InnerFrame.SellEquippedFrame
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

	if race ~= "pet" then
		innerFrame.Visible = false
		cannotSellFrame.Visible = true
		return
	end

	innerFrame.Visible = true
	cannotSellFrame.Visible = false

	innerFrame.Icon.Image = PetInfo:getPetImage(itemClass, mutationClass)

	local sellPrice = PetInfo:calculateSellPrice({
		petClass = itemClass,
		mutationClass = mutationClass,
	})

	innerFrame.CoinsTitle.Text = "$" .. Common.abbreviateNumber(sellPrice, 1)

	local currWeight = PetInfo:getRealWeight(itemClass, equippedToolMod["baseWeight"], equippedToolMod["level"])

	innerFrame.WeightTitle.Text = Common.abbreviateNumber(currWeight, 2) .. "kg"

	local mutationTitle = innerFrame.MutationTitle
	ClientMod.mutationManager:applyMutationColor(mutationTitle, mutationClass)
end

function SellPetManager:refreshSellAllFrame()
	local totalSellPrice = 0
	local sellAllCount = 0
	for _, itemMod in pairs(ClientMod.stashManager.itemMods) do
		local race = itemMod["race"]
		if race ~= "pet" then
			continue
		end
		if itemMod["deleted"] then
			continue
		end
		if itemMod["favorited"] then
			continue
		end

		local sellPrice = PetInfo:calculateSellPrice({
			petClass = itemMod["itemClass"],
			mutationClass = itemMod["mutationClass"],
		})
		totalSellPrice += sellPrice
		sellAllCount += 1
	end

	local sellAllFrame = sellPetFrame.InnerFrame.SellAllFrame
	sellAllFrame.InnerFrame.TotalPriceTitle.Text = "$" .. Common.abbreviateNumber(totalSellPrice, 1)

	self.totalSellPrice = totalSellPrice
	self.sellAllCount = sellAllCount
end

function SellPetManager:toggle(data)
	local newBool = data["newBool"]

	if newBool == self.toggled then
		return
	end

	if newBool then
		ClientMod.uiManager:animateOpen(sellPetFrame)
		ClientMod.uiManager:toggleOffAllGUI()
	end

	ClientMod.uiManager:interactMainFrame(sellPetFrame, data)

	self.toggled = newBool
end

SellPetManager:init()

return SellPetManager
