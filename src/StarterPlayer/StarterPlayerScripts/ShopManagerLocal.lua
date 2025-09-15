local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)
local buttonGUI = playerGui:WaitForChild("ButtonGUI")
local buttonsFrame = buttonGUI.LeftFrame.ButtonsFrame
local shopButton = buttonsFrame.Shop

local exclusiveShopGUI = playerGui:WaitForChild("ExclusiveShopGUI")
local shopFrame = exclusiveShopGUI.ShopFrame

local blackGUI = playerGui:WaitForChild("BlackGUI")
local productLoadingFrame = blackGUI.BlackFrame.LoadingFrame

local ShopInfo = require(game.ReplicatedStorage.ShopInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local ShopManager = {
	gamepassMods = {},
	gamepassModsList = {},

	productMods = {},
	productModsList = {},

	currencyMods = {},
	ownedGamepassMods = {},
}

function ShopManager:init()
	self:addCons()

	self:initGamepassMods()
	-- self:initProductMods()

	self:addLuckyBlockCons()
	self:addServerLuckCons()

	self:initCurrencyMods()

	self:toggle({
		newBool = false,
		animateClose = false,
	})
end

function ShopManager:addServerLuckCons()
	local serverLuckFrame = shopFrame.MainItemList.Products.ServerLuck
	local buyButton = serverLuckFrame.BuyButton
	ClientMod.buttonManager:addActivateCons(buyButton, function()
		ClientMod:FireServer("tryBuyNextServerLuck", {})
	end)
end

function ShopManager:addLuckyBlockCons()
	local luckyBlockFrame = shopFrame.MainItemList.LuckyBlock
	local buy10Button = luckyBlockFrame.BuyButtonList.Buy10Button
	local buy3Button = luckyBlockFrame.BuyButtonList.Buy3Button
	local buy1Button = luckyBlockFrame.BuyButtonList.Buy1Button

	ClientMod.buttonManager:addActivateCons(buy10Button, function()
		ClientMod:FireServer("tryBuyProduct", {
			productClass = "LuckyBlock10",
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(buy10Button)

	local productStats = ShopInfo:getMeta("LuckyBlock10")
	self:retryProductPrice(buy10Button.Title, productStats["id"], Enum.InfoType.Product)

	ClientMod.buttonManager:addActivateCons(buy3Button, function()
		ClientMod:FireServer("tryBuyProduct", {
			productClass = "LuckyBlock3",
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(buy3Button)

	local productStats = ShopInfo:getMeta("LuckyBlock3")
	self:retryProductPrice(buy3Button.Title, productStats["id"], Enum.InfoType.Product)

	ClientMod.buttonManager:addActivateCons(buy1Button, function()
		ClientMod:FireServer("tryBuyProduct", {
			productClass = "LuckyBlock1",
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(buy1Button)

	local productStats = ShopInfo:getMeta("LuckyBlock1")
	self:retryProductPrice(buy1Button.Title, productStats["id"], Enum.InfoType.Product)
end

local TOP_PADDING_RATIO = 0.09

function ShopManager:moveMainInventory(yRatio)
	-- roll the position
	local mainItemList = shopFrame.MainItemList
	local absoluteCanvasSize = mainItemList.AbsoluteCanvasSize
	local absoluteWindowSize = mainItemList.AbsoluteWindowSize

	yRatio = yRatio - TOP_PADDING_RATIO

	local ratio = yRatio / self.totalYRatio

	local yPos = absoluteCanvasSize.Y * ratio -- - absoluteWindowSize.Y / 2
	ClientMod.tweenManager:createTween({
		target = mainItemList,
		timer = 0.25,
		easingStyle = "Quad",
		easingDirection = "Out",
		goal = {
			CanvasPosition = Vector2.new(0, yPos),
		},
	})
end

function ShopManager:initGamepassMods()
	for index, gamepassClass in pairs(ShopInfo.gamepassList) do
		self:newGamepassMod({
			gamepassClass = gamepassClass,
			index = index,
		})
	end
end

function ShopManager:initProductMods()
	for index, productClass in pairs(ShopInfo.productList) do
		self:newProductMod({
			productClass = productClass,
			index = index,
		})
	end
end

function ShopManager:initCurrencyMods()
	for currencyClass, _ in pairs(ShopInfo.currencies) do
		self:newCurrencyMod({
			currencyClass = currencyClass,
		})
	end
end

function ShopManager:newCurrencyMod(data)
	local currencyClass = data["currencyClass"]

	local frame = shopFrame.MainItemList.Coins.InnerFrame.ItemList:FindFirstChild(currencyClass)
	if not frame then
		warn("!!! COULD NOT FIND CURRENCY MOD: ", currencyClass)
		return
	end

	local innerFrame = frame.InnerFrame
	local buyButton = innerFrame.BuyButton
	ClientMod.buttonManager:addActivateCons(buyButton, function()
		ClientMod:FireServer("tryBuyProduct", {
			productClass = currencyClass,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(buyButton)

	local currencyStats = ShopInfo:getMeta(currencyClass)

	local coinsAmount = currencyStats["rewards"]["itemMod"]["count"]
	innerFrame.CoinsAmount.Text = Common.abbreviateNumber(coinsAmount) .. " Coins"

	self:retryProductPrice(buyButton.Title, currencyStats["id"], Enum.InfoType.Product)

	local newCurrencyMod = {
		currencyClass = currencyClass,
		frame = frame,
	}
	self.currencyMods[currencyClass] = newCurrencyMod

	return newCurrencyMod
end

function indexComp(modA, modB)
	-- print(modA, modB)
	local indexA = modA["index"]
	local indexB = modB["index"]

	return indexA < indexB
end

function ShopManager:refreshAllGamepassMods()
	table.sort(self.gamepassModsList, indexComp)
	local layoutIndex = 0
	for _, gamepassMod in pairs(self.gamepassModsList) do
		local frame = gamepassMod["frame"]
		if not frame then
			continue
		end
		frame.LayoutOrder = layoutIndex
		layoutIndex += 1
	end
	for _, gamepassMod in pairs(self.gamepassMods) do
		self:refreshGamepassMod(gamepassMod)
	end
end

function ShopManager:refreshAllProductMods()
	table.sort(self.productModsList, indexComp)
	local layoutIndex = 0
	for _, productMod in pairs(self.productModsList) do
		local frame = productMod["frame"]
		if not frame then
			continue
		end
		frame.LayoutOrder = layoutIndex
		layoutIndex += 1
	end
	for _, productMod in pairs(self.productMods) do
		self:refreshProductMod(productMod)
	end
end

function ShopManager:refreshProductMod(productMod)
	local productClass = productMod["productClass"]
	local frame = productMod["frame"]
	if not frame then
		return
	end

	local productStats = ShopInfo:getMeta(productClass)

	local buttonFrame = frame.ButtonFrame
	local innerFrame = buttonFrame.InnerFrame

	innerFrame.Icon.Image = productStats["image"]
	innerFrame.Icon.ImageColor3 = productStats["imageColor"] or Color3.fromRGB(255, 255, 255)
	innerFrame.Title.Text = productStats["alias"]
	innerFrame.DescriptionTitle.Text = productStats["description"]
end

function ShopManager:refreshGamepassMod(gamepassMod)
	local gamepassClass = gamepassMod["gamepassClass"]
	local frame = gamepassMod["frame"]
	if not frame then
		return
	end

	local passStats = ShopInfo:getMeta(gamepassClass)

	local buttonFrame = frame.ButtonFrame
	local ownedBool = self.ownedGamepassMods[gamepassClass]

	-- print("OWNED BOOL: ", ownedBool, frame, gamepassClass)

	buttonFrame.OwnedFrame.Visible = ownedBool
end

function ShopManager:newGamepassMod(data)
	local gamepassClass = data["gamepassClass"]

	local stats = ShopInfo:getMeta(gamepassClass)

	local frame = shopFrame.MainItemList.Pass.ItemList:FindFirstChild(gamepassClass)
	if not frame then
		warn("!!! COULD NOT FIND GAMEPASS MOD: ", gamepassClass)
		return
	end

	local buttonFrame = frame.ButtonFrame

	local buyButton = buttonFrame.BuyButton

	local passId = stats["id"]
	self:retryProductPrice(buyButton.Title, passId, Enum.InfoType.GamePass)

	ClientMod.buttonManager:addBasicButtonCons(buyButton)

	ClientMod.buttonManager:addActivateCons(buyButton, function()
		if self.ownedGamepassMods[gamepassClass] then
			ClientMod.notifyManager:notifyError("You already own this gamepass!")
			return
		end

		ClientMod:FireServer("tryBuyGamepass", {
			gamepassClass = gamepassClass,
		})
	end)

	frame.BackgroundTransparency = 1

	local newGamepassMod = {
		gamepassClass = gamepassClass,
		frame = frame,
	}
	self.gamepassMods[gamepassClass] = newGamepassMod
	table.insert(self.gamepassModsList, newGamepassMod)

	for k, v in pairs(data) do
		newGamepassMod[k] = v
	end

	return newGamepassMod
end

function ShopManager:retryProductPrice(title, productId, productType)
	routine(function()
		title.Text = "loading..."

		local productInfo = nil
		local retryLimit = 5
		local retryCount = 0

		-- Keep retrying until we get the info or hit the retry limit
		while retryCount < retryLimit and not productInfo do
			productInfo = Common.getProductInfo(productId, productType)

			if not productInfo or not productInfo["PriceInRobux"] then
				warn("Failed to get PRODUCTINFO (Attempt " .. retryCount + 1 .. "/" .. retryLimit .. "): ", productId)
				retryCount = retryCount + 1
				task.wait(10) -- Wait a second before retrying
			end
		end
		if not productInfo or not productInfo["PriceInRobux"] then
			warn("COULD NOT GET PRODUCTINFO after " .. retryLimit .. " attempts: ", productId)
			return
		end

		local robuxPrice = productInfo["PriceInRobux"]
		title.Text = Common.robuxSymbol .. " " .. Common.abbreviateNumber(robuxPrice)
	end)
end

function ShopManager:newProductMod(data)
	local productClass = data["productClass"]

	local productStats = ShopInfo:getMeta(productClass)

	local frame = self.templateProductItem:Clone()
	frame.Visible = true
	frame.Parent = self.templateProductItem.Parent

	local buttonFrame = frame.ButtonFrame
	local innerFrame = buttonFrame.InnerFrame

	local buyButton = innerFrame.BuyButton
	self:retryProductPrice(buyButton.Title, productStats["id"], Enum.InfoType.Product)

	ClientMod.buttonManager:addBasicButtonCons(buyButton)

	ClientMod.buttonManager:addActivateCons(buyButton, function()
		ClientMod:FireServer("tryBuyProduct", {
			productClass = productClass,
		})
	end)

	frame.BackgroundTransparency = 1

	local newProductMod = {
		frame = frame,
		productClass = productClass,
	}
	self.productMods[productClass] = newProductMod
	table.insert(self.productModsList, newProductMod)

	for k, v in pairs(data) do
		newProductMod[k] = v
	end

	return newProductMod
end

function ShopManager:updateOwnedGamepassMods(data)
	self.ownedGamepassMods = data["gamepassMods"]
	self:refreshAllGamepassMods()
end

function ShopManager:checkOwnsGamepass(gamepassClass)
	return self.ownedGamepassMods[gamepassClass] ~= nil
end

function ShopManager:addCons()
	productLoadingFrame.BackgroundTransparency = 1
	productLoadingFrame.Visible = true

	ClientMod.buttonManager:addActivateCons(shopButton, function()
		self:toggle({
			newBool = not self.toggled,
			animateClose = true,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(shopButton)

	ClientMod.hintManager:addHintFrameCons({
		frame = shopButton,
		alias = "Shop",
	})

	local closeButton = shopFrame.CloseButton
	ClientMod.buttonManager:addActivateCons(closeButton, function()
		self:toggle({
			newBool = false,
			animateClose = true,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(closeButton)

	local mainItemList = shopFrame.MainItemList

	local templateProductItem = mainItemList.Products.ItemList.TemplateItem
	templateProductItem.Visible = false
	self.templateProductItem = templateProductItem

	shopFrame.TabListFrame.BackgroundTransparency = 1
end

function ShopManager:toggle(data)
	local newBool = data["newBool"]

	if newBool == self.toggled then
		return
	end

	if newBool then
		ClientMod.uiManager:animateOpen(shopFrame)
		ClientMod.uiManager:toggleOffAllGUI()
	end

	ClientMod.uiManager:interactMainFrame(shopFrame, data)

	self.toggled = newBool
end

function ShopManager:toggleProductLoading(newBool)
	if newBool == self.loadingToggled then
		return
	end
	self.loadingToggled = newBool

	if newBool then
		ClientMod.soundManager:newSoundMod({
			soundClass = "ProductStarted2",
		})
	end

	local newTransparency = 1
	if newBool then
		newTransparency = 0.5
	end

	local fadeTimer = 0.5
	ClientMod.tweenManager:createTween({
		target = productLoadingFrame,
		timer = fadeTimer,
		easingStyle = "Quad",
		easingDirection = "Out",
		goal = {
			BackgroundTransparency = newTransparency,
		},
	})
end

local nextServerLuckMap = {
	["1"] = "2",
	["2"] = "4",
	["4"] = "8",
	["8"] = "16",
	["16"] = "16",
}

function ShopManager:updateServerLuck(data)
	local serverLuck = data["serverLuck"]
	local serverLuckExpiree = data["serverLuckExpiree"]

	local serverLuckFrame = shopFrame.MainItemList.Products.ServerLuck

	local nextServerLuckCount = nextServerLuckMap[tostring(serverLuck)]
	serverLuckFrame.ProgressTitle.Text = string.format(
		"%s > %s",
		serverLuck .. "x",
		Common.addRichTextColor(nextServerLuckCount .. "x", Color3.fromRGB(84, 250, 109))
	)

	local buyButton = serverLuckFrame.BuyButton
	routine(function()
		local productClass = ShopInfo:getNextServerLuckProduct(serverLuck)
		local productId = ShopInfo:getMeta(productClass)["id"]

		-- print("GOT PRODUCT ID: ", productId, productClass)

		local productInfo = Common.getProductInfo(productId, Enum.InfoType.Product)
		if not productInfo then
			warn("!!! COULD NOT FIND PRODUCT INFO: ", productId)
			buyButton.Title.Text = "error"
			return
		end

		buyButton.Title.Text = productInfo["PriceInRobux"] .. " R$"
	end)
end

ShopManager:init()

return ShopManager
