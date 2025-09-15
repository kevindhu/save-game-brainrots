local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local zoneGUI = playerGui:WaitForChild("ZoneGUI")
local buyZoneFrame = zoneGUI.BuyZoneFrame
local infoFrame = buyZoneFrame.InfoFrame

-- local EggInfo = require(game.ReplicatedStorage.EggInfo)
local ZoneInfo = require(game.ReplicatedStorage.ZoneInfo)
local GemInfo = require(game.ReplicatedStorage.GemInfo)
local ShopInfo = require(game.ReplicatedStorage.ShopInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local BuyZoneManager = {
	tabMods = {},
	spawnItemMods = {},

	unlockedZoneMap = {},
}

function BuyZoneManager:init()
	self:addCons()
	self:initAllTabMods()

	self:toggle({
		newBool = false,
	})

	self:chooseTab("Zone1")
end

function BuyZoneManager:addCons()
	buyZoneFrame.BackgroundTransparency = 1

	local closeButton = buyZoneFrame.InfoFrame.CloseButton
	ClientMod.buttonManager:addActivateCons(closeButton, function()
		self.toggleLocked = true
		self:toggle({
			newBool = false,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(closeButton)

	self.templateTabFrame = buyZoneFrame.TabFrame.ItemList.TemplateItem
	self.templateTabFrame.Visible = false
	self.templateTabFrame.BackgroundTransparency = 1

	local innerFrame = infoFrame.InnerFrame

	local buyFrame = innerFrame.BuyFrame
	buyFrame.BackgroundTransparency = 1

	local buyButton = buyFrame.BuyButton
	ClientMod.buttonManager:addActivateCons(buyButton, function()
		ClientMod:FireServer("tryBuyZone", {
			zoneClass = self.chosenTabClass,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(buyButton)

	local robuxBuyButton = buyFrame.RobuxBuyButton
	ClientMod.buttonManager:addActivateCons(robuxBuyButton, function()
		ClientMod:FireServer("tryBuyZone", {
			zoneClass = self.chosenTabClass,
			withRobux = true,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(robuxBuyButton)

	local useFrame = innerFrame.UseFrame
	ClientMod.buttonManager:addActivateCons(useFrame.UseButton, function()
		ClientMod:FireServer("tryChooseZone", {
			zoneClass = self.chosenTabClass,
		})
	end)
	useFrame.BackgroundTransparency = 1

	innerFrame.ItemList.BackgroundTransparency = 1
	innerFrame.BuyFrame.BackgroundTransparency = 1

	self.templateSpawnItemFrame = innerFrame.ItemList.TemplateItem
	self.templateSpawnItemFrame.Visible = false
	self.templateSpawnItemFrame.BackgroundTransparency = 1
end

function BuyZoneManager:updateAllZoneData(data)
	self.unlockedZoneMap = data["unlockedZoneMap"]
	self.currZoneClass = data["currZoneClass"]

	-- refresh the chosen tab
	self:chooseTab(self.chosenTabClass)
end

function BuyZoneManager:addBuyZoneArea(model)
	local buyZonePart = model:WaitForChild("BuyZonePart")

	self.buyZonePart = buyZonePart
end

function BuyZoneManager:initAllTabMods()
	for index, zoneClass in pairs(ZoneInfo.zoneList) do
		self:newTabMod({
			zoneClass = zoneClass,
			index = index,
		})
	end
end

function BuyZoneManager:newTabMod(data)
	local index = data["index"]
	local zoneClass = data["zoneClass"]

	local frame = self.templateTabFrame:Clone()
	frame.Visible = true
	frame.Parent = self.templateTabFrame.Parent

	local zoneStats = ZoneInfo:getMeta(zoneClass)

	local buyButton = frame.BuyButton
	ClientMod.buttonManager:addActivateCons(buyButton, function()
		self:chooseTab(zoneClass)
	end)
	ClientMod.buttonManager:addBasicButtonCons(buyButton)

	buyButton.Title.Text = zoneStats["alias"]

	buyButton.Icon.Image = zoneStats["spawnerImage"]

	frame.LayoutOrder = index

	local newTabMod = {
		zoneClass = zoneClass,
		frame = frame,
		index = index,
	}
	self.tabMods[zoneClass] = newTabMod

	-- ClientMod.uiScaleManager:recurseGUIForScaleMods(frame)
end

function BuyZoneManager:tick()
	local user = ClientMod:getLocalUser()
	if not user then
		return
	end

	if not self.buyZonePart then
		return
	end

	local whiteList = {
		self.buyZonePart,
	}
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
	raycastParams.FilterDescendantsInstances = whiteList

	local userPos = user.currFrame.Position
	local raycastResult = game.Workspace:Raycast(userPos + Vector3.new(0, 10, 0), Vector3.new(0, -30, 0), raycastParams)

	if not raycastResult then
		self.toggleLocked = false
		self:toggle({
			newBool = false,
		})
		return
	end

	if self.toggled or self.toggleLocked then
		return
	end

	self:toggle({
		newBool = true,
	})
end

function BuyZoneManager:chooseTab(zoneClass)
	self.chosenTabClass = zoneClass

	local zoneStats = ZoneInfo:getMeta(zoneClass)

	for _, tabMod in pairs(self.tabMods) do
		local buyButton = tabMod["frame"].BuyButton
		if tabMod["zoneClass"] == zoneClass then
			buyButton.UIStroke.Color = Color3.fromRGB(255, 255, 255)
		else
			buyButton.UIStroke.Color = Color3.fromRGB(0, 0, 0)
		end
	end

	local innerFrame = infoFrame.InnerFrame

	innerFrame.NameTitle.Text = zoneStats["alias"]

	innerFrame.Icon.Image = zoneStats["spawnerImage"]

	innerFrame.CoinMultiplierTitle.Text =
		string.format("Increased Coins: +%s%%", math.round((zoneStats["coinMultiplierRatio"] - 1) * 100))

	-- destroy all previous spawn item frames
	for _, spawnItemMod in pairs(self.spawnItemMods) do
		local frame = spawnItemMod["frame"]
		if frame then
			frame:Destroy()
		end
	end

	-- add new spawn item frames
	for gemClass, spawnItemProb in pairs(zoneStats["gemProbMap"]) do
		local gemStats = GemInfo:getMeta(gemClass)

		local frame = self.templateSpawnItemFrame:Clone()
		frame.Visible = true
		frame.Parent = self.templateSpawnItemFrame.Parent

		frame.InnerFrame.Icon.Image = GemInfo["imageMap"][gemClass] or "rbxassetid://102175783632979"

		local newSpawnItemMod = {
			gemClass = gemClass,
			frame = frame,
		}
		self.spawnItemMods[gemClass] = newSpawnItemMod
	end

	local buyFrame = innerFrame.BuyFrame
	local useFrame = innerFrame.UseFrame
	buyFrame.UnlockCashTitle.Text = "$" .. Common.commas(zoneStats["unlockPrice"])

	routine(function()
		if zoneClass == "Zone1" then
			return
		end

		local shopStats = ShopInfo:getMeta(zoneClass)
		if not shopStats then
			warn("NO SHOP STATS FOUND FOR: ", zoneClass)
			return
		end

		local productId = shopStats["id"]
		local productInfo = Common.getProductInfo(productId, Enum.InfoType.Product)
		if not productInfo then
			warn("NO PRODUCT INFO FOUND FOR: ", productId)
			return
		end
		buyFrame.RobuxBuyButton.Title.Text = Common.robuxSymbol .. productInfo["PriceInRobux"]
	end)

	useFrame.Title.Text = "Owned"
	if self.currZoneClass == zoneClass then
		useFrame.Title.Text = "Equipped"
		useFrame.UseButton.Visible = false
	else
		useFrame.UseButton.Visible = true
	end

	local unlockPreviousFrame = innerFrame.UnlockPreviousFrame
	unlockPreviousFrame.Visible = false
	buyFrame.Visible = false
	useFrame.Visible = false

	if self.unlockedZoneMap[zoneClass] then
		useFrame.Visible = true
	else
		local index = zoneStats["index"]
		local lastZoneClass = "Zone" .. (index - 1)
		if not self.unlockedZoneMap[lastZoneClass] then
			unlockPreviousFrame.Visible = true
		else
			buyFrame.Visible = true
		end
	end
end

function BuyZoneManager:toggle(data)
	local newBool = data["newBool"]

	if newBool == self.toggled then
		return
	end

	if newBool then
		ClientMod.uiManager:animateOpen(buyZoneFrame)
		ClientMod.uiManager:toggleOffAllGUI()
	end

	ClientMod.uiManager:interactMainFrame(buyZoneFrame, data)

	self.toggled = newBool
end

BuyZoneManager:init()

return BuyZoneManager
