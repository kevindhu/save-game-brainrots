local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local eggGUI = playerGui:WaitForChild("EggGUI")
local buyEggFrame = eggGUI.BuyEggFrame

local EggInfo = require(game.ReplicatedStorage.EggInfo)
local ShopInfo = require(game.ReplicatedStorage.ShopInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local BuyEggManager = {
	itemMods = {},

	restockTime = 0,
}

function BuyEggManager:init()
	self:addCons()
	self:initAllItemMods()

	self:toggle({
		newBool = false,
	})

	routine(function()
		wait(1)
		ClientMod.tutManager:initBuyEggHintIcons()
	end)
end

function BuyEggManager:addCons()
	local closeButton = buyEggFrame.TopFrame.CloseButton
	ClientMod.buttonManager:addActivateCons(closeButton, function()
		self:toggle({
			newBool = false,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(closeButton)

	self.templateItemFrame = buyEggFrame.ItemList.TemplateItem
	self.templateItemFrame.Visible = false
end

function BuyEggManager:updateEggShopStock(data)
	local restockTime = data["restockTime"]
	local stock = data["stock"]

	self.restockTime = restockTime

	for eggClass, count in pairs(stock) do
		self:updateItemMod(eggClass, count)
	end
end

function BuyEggManager:initAllItemMods()
	for index, eggClass in pairs(EggInfo.stockEggList) do
		self:newItemMod({
			itemClass = eggClass,
			index = index,
		})
	end
end

function BuyEggManager:tick(timeRatio)
	local restockTitle = buyEggFrame.RestockTitle
	local secondsLeft = self.restockTime + 60 * 5 - os.time()
	restockTitle.Text = "Restock in: " .. Common.convertSecondsToReadableString(secondsLeft)
end

function BuyEggManager:updateItemMod(eggClass, count)
	local itemMod = self.itemMods[eggClass]
	itemMod["stockCount"] = count

	-- refresh the itemMod
	self:refreshItemMod(itemMod)
end

function BuyEggManager:refreshItemMod(itemMod)
	local frame = itemMod["frame"]
	local itemClass = itemMod["itemClass"]

	local eggStats = EggInfo:getMeta(itemClass)

	frame.InnerFrame.StockTitle.Text = "x" .. itemMod["stockCount"]
	frame.InnerFrame.NameTitle.Text = eggStats["alias"]
	frame.InnerFrame.DescriptionTitle.Text = eggStats["description"]
end

function BuyEggManager:newItemMod(data)
	local index = data["index"]
	local itemClass = data["itemClass"]

	local frame = self.templateItemFrame:Clone()
	frame.Visible = true
	frame.Parent = self.templateItemFrame.Parent

	local eggStats = EggInfo:getMeta(itemClass)

	local innerFrame = frame.InnerFrame

	innerFrame.InfoFrame.Icon.Image = eggStats["image"]

	local buyButton = innerFrame.BuyButton
	ClientMod.buttonManager:addActivateCons(buyButton, function()
		ClientMod:FireServer("tryBuyEgg", {
			eggClass = itemClass,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(buyButton)

	buyButton.DecorFrame.CostFrame.Title.Text = Common.abbreviateNumber(eggStats["price"])

	local robuxBuyButton = innerFrame.RobuxBuyButton
	ClientMod.buttonManager:addActivateCons(robuxBuyButton, function()
		ClientMod:FireServer("tryBuyEgg", {
			eggClass = itemClass,
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

function BuyEggManager:toggle(data)
	local newBool = data["newBool"]

	if newBool == self.toggled then
		return
	end

	if newBool then
		ClientMod.uiManager:animateOpen(buyEggFrame)
		ClientMod.uiManager:toggleOffAllGUI()

		ClientMod:FireServer("tryUpdateTutMod", {
			targetClass = "TeleportToEggShop",
			updateCount = 1,
		})
	else
		ClientMod:FireServer("tryUpdateTutMod", {
			targetClass = "CloseEggShop",
			updateCount = 1,
		})
	end

	ClientMod.uiManager:interactMainFrame(buyEggFrame, data)

	self.toggled = newBool
end

BuyEggManager:init()

return BuyEggManager
