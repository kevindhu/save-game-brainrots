local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local shopGUI = playerGui:WaitForChild("ShopGUI")
local basicFrame = shopGUI.BasicFrame

-- local buttonGUI = playerGui:WaitForChild("ButtonGUI")
-- local leftFrame = buttonGUI.LeftFrame
-- local basicButton = leftFrame.Basic

local ToolInfo = require(game.ReplicatedStorage.ToolInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local BasicManager = {
	itemMods = {},
}

function BasicManager:init()
	self:addCons()
	self:initItemMods()

	self:toggle({
		newBool = false,
	})
end

function BasicManager:addCons()
	local closeButton = basicFrame.TopFrame.CloseButton
	ClientMod.buttonManager:addActivateCons(closeButton, function()
		self:toggle({
			newBool = false,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(closeButton)

	self.templateItemFrame = basicFrame.ItemList.TemplateItem
	self.templateItemFrame.Visible = false
end

function BasicManager:initItemMods()
	for _, toolClass in pairs(ToolInfo.vendorBasicToolList) do
		self:newItemMod({
			toolClass = toolClass,
		})
	end

	self:refreshItemMods()
end

function BasicManager:refreshItemMods()
	local currCoinsCount = ClientMod.currManager.itemMods["Coins"] or 0

	for _, itemMod in pairs(self.itemMods) do
		local frame = itemMod["frame"]
		local toolClass = itemMod["toolClass"]

		local toolStats = ToolInfo:getMeta(toolClass)

		local price = toolStats["price"]
		local buyButton = frame.InnerFrame.BuyButton
		local decorFrame = buyButton.DecorFrame
		if price > currCoinsCount then
			decorFrame.BackgroundColor3 = Color3.fromRGB(25, 130, 49)
			buyButton.Title.TextColor3 = Color3.fromRGB(99, 99, 99)
		else
			decorFrame.BackgroundColor3 = Color3.fromRGB(43, 226, 88)
			buyButton.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
end

function BasicManager:newItemMod(data)
	local toolClass = data["toolClass"]

	local frame = self.templateItemFrame:Clone()
	frame.Visible = true
	frame.Parent = self.templateItemFrame.Parent

	local toolStats = ToolInfo:getMeta(toolClass)

	-- render the frame
	local innerFrame = frame.InnerFrame
	innerFrame.DescriptionTitle.Text = toolStats["description"]
	innerFrame.NameTitle.Text = toolStats["alias"]

	local infoFrame = innerFrame.InfoFrame

	local tool = game.ReplicatedStorage.ToolModels[toolClass]
	infoFrame.Icon.Image = tool.TextureId

	local buyButton = innerFrame.BuyButton
	ClientMod.buttonManager:addActivateCons(buyButton, function()
		ClientMod:FireServer("tryBuyTool", {
			toolClass = toolClass,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(buyButton)

	buyButton.Title.Text = "$" .. Common.abbreviateNumber(toolStats["price"])

	local newItemMod = {
		toolClass = toolClass,
		frame = frame,
	}
	self.itemMods[toolClass] = newItemMod

	ClientMod.uiScaleManager:recurseGUIForScaleMods(frame)
end

function BasicManager:toggle(data)
	local newBool = data["newBool"]

	if newBool == self.toggled then
		return
	end

	if newBool then
		ClientMod.uiManager:animateOpen(basicFrame)
		ClientMod.uiManager:toggleOffAllGUI()
	end

	ClientMod.uiManager:interactMainFrame(basicFrame, data)

	self.toggled = newBool
end

BasicManager:init()

return BasicManager
