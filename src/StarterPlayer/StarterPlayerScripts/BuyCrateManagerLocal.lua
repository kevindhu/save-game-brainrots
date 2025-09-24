local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local crateGUI = playerGui:WaitForChild("CrateGUI")
local buyCrateFrame = crateGUI.BuyCrateFrame

local CrateInfo = require(game.ReplicatedStorage.CrateInfo)
local ShopInfo = require(game.ReplicatedStorage.ShopInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local BuyCrateManager = {
	itemMods = {},

	restockTime = 0,
}

function BuyCrateManager:init()
	self:addCons()
	self:initAllItemMods()

	self:toggle({
		newBool = false,
	})
end

function BuyCrateManager:addCons()
	local closeButton = buyCrateFrame.TopFrame.CloseButton
	ClientMod.buttonManager:addActivateCons(closeButton, function()
		self:toggle({
			newBool = false,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(closeButton)

	self.templateItemFrame = buyCrateFrame.ItemList.TemplateItem
	self.templateItemFrame.Visible = false
end

function BuyCrateManager:updateCrateShopStock(data)
	local restockTime = data["restockTime"]
	local stock = data["stock"]

	-- print("UPDATE CRATE SHOP STOCK: ", restockTime, stock)

	self.restockTime = restockTime

	for crateClass, count in pairs(stock) do
		self:updateItemMod(crateClass, count)
	end
end

function BuyCrateManager:initAllItemMods()
	for index, crateClass in pairs(CrateInfo.stockCrateList) do
		self:newItemMod({
			itemClass = crateClass,
			index = index,
		})
	end
end

function BuyCrateManager:tick(timeRatio)
	local restockTitle = buyCrateFrame.RestockTitle
	local secondsLeft = self.restockTime + 60 * 5 - os.time()
	restockTitle.Text = "Restock in: " .. Common.convertSecondsToReadableString(secondsLeft)
end

function BuyCrateManager:updateItemMod(crateClass, count)
	local itemMod = self.itemMods[crateClass]
	itemMod["stockCount"] = count

	-- refresh the itemMod
	self:refreshItemMod(itemMod)
end

function BuyCrateManager:refreshItemMod(itemMod)
	local frame = itemMod["frame"]
	local itemClass = itemMod["itemClass"]

	local crateStats = CrateInfo:getMeta(itemClass)

	frame.InnerFrame.StockTitle.Text = "x" .. itemMod["stockCount"]
	frame.InnerFrame.NameTitle.Text = crateStats["alias"]
	frame.InnerFrame.DescriptionTitle.Text = crateStats["description"]
end

function BuyCrateManager:newItemMod(data)
	local index = data["index"]
	local itemClass = data["itemClass"]

	local frame = self.templateItemFrame:Clone()
	frame.Visible = true
	frame.Parent = self.templateItemFrame.Parent

	local crateStats = CrateInfo:getMeta(itemClass)

	local innerFrame = frame.InnerFrame

	innerFrame.InfoFrame.Icon.Image = crateStats["image"]

	local buyButton = innerFrame.BuyButton
	ClientMod.buttonManager:addActivateCons(buyButton, function()
		ClientMod:FireServer("tryBuyCrate", {
			crateClass = itemClass,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(buyButton)

	buyButton.DecorFrame.CostFrame.Title.Text = Common.abbreviateNumber(crateStats["price"])

	local robuxBuyButton = innerFrame.RobuxBuyButton
	ClientMod.buttonManager:addActivateCons(robuxBuyButton, function()
		ClientMod:FireServer("tryBuyCrate", {
			crateClass = itemClass,
			withRobux = true,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(robuxBuyButton)

	routine(function()
		local shopStats = ShopInfo:getMeta("Buy" .. itemClass)
		local productInfo = Common.getProductInfo(shopStats["id"], Enum.InfoType.Product)
		if not productInfo then
			warn("!!! COULD NOT FIND PRODUCT INFO: ", shopStats["id"])
			robuxBuyButton.Title.Text = "error"
			return
		end

		robuxBuyButton.Title.Text = Common.robuxSymbol .. " " .. Common.abbreviateNumber(productInfo.PriceInRobux)
	end)

	frame.LayoutOrder = index

	local newItemMod = {
		itemClass = itemClass,
		frame = frame,
		index = index,

		stockCount = 0,
	}
	self.itemMods[itemClass] = newItemMod
	ClientMod.uiScaleManager:recurseGUIForScaleMods(frame)

	self:refreshItemMod(newItemMod)
end

function BuyCrateManager:toggle(data)
	local newBool = data["newBool"]

	if newBool == self.toggled then
		return
	end

	if newBool then
		ClientMod.uiManager:animateOpen(buyCrateFrame)
		ClientMod.uiManager:toggleOffAllGUI()

		ClientMod:FireServer("tryUpdateTutMod", {
			targetClass = "TeleportToCrateShop",
			updateCount = 1,
		})
	else
		ClientMod:FireServer("tryUpdateTutMod", {
			targetClass = "CloseCrateShop",
			updateCount = 1,
		})
	end

	ClientMod.uiManager:interactMainFrame(buyCrateFrame, data)

	self.toggled = newBool
end

BuyCrateManager:init()

return BuyCrateManager
