local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local ItemInfo = require(game.ReplicatedStorage.ItemInfo)
local ToolInfo = require(game.ReplicatedStorage.ToolInfo)
local PetInfo = require(game.ReplicatedStorage.PetInfo)
local RelicInfo = require(game.ReplicatedStorage.RelicInfo)
local CrateInfo = require(game.ReplicatedStorage.CrateInfo)

local PetBalanceInfo = require(game.ReplicatedStorage.PetBalanceInfo)

local Icon = require(game.ReplicatedStorage.Libraries.Icon)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

-- local buttonGUI = playerGui:WaitForChild("ButtonGUI")
-- local buttonsFrame = buttonGUI.LeftFrame.ButtonsFrame
-- local stashButton = buttonsFrame.Stash

local stashGUI = playerGui:WaitForChild("StashGUI")
local bottomFrame = stashGUI.BottomFrame
local stashFrame = stashGUI.StashFrame
local itemInfoFrame = stashGUI.ItemInfoFrame

local ItemStash = {
	itemMods = {},
	itemModsList = {},

	bottomMods = {},
	bottomModsList = {},

	tabMods = {},

	toolClasses = {
		"Bat1",
		"Hammer",
	},
}

function ItemStash:init()
	self:addCons()
	self:addTabCons()
	self:addBottomCons()
	self:addDisplayCons()
	self:addFavoriteCons()

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		-- check if keyboard input, if not skip
		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		-- check if keycode is from 1 to 9
		local keycode = input.KeyCode
		if keycode.Value >= Enum.KeyCode.One.Value and keycode.Value <= Enum.KeyCode.Nine.Value then
			local index = keycode.Value - Enum.KeyCode.One.Value + 1
			-- print("CLICKED BOTTOM INDEX: ", index)

			if index == 1 then
				index = -1
			end

			if index == 2 then
				self:toggle({
					newBool = not self.toggled,
				})
				return
			end

			for _, bottomMod in pairs(self.bottomModsList) do
				if bottomMod["index"] == index then
					self:clickBottomItem(bottomMod)
					break
				end
			end
		end
	end)

	self:toggle({
		newBool = false,
	})

	self:updateAlert({
		bool = false,
	})

	self:chooseTab("All")
end

function ItemStash:addFavoriteCons()
	local favoriteButton = stashFrame.DecorFrame.FavoritesFrame.FavoriteButton
	ClientMod.buttonManager:addActivateCons(favoriteButton, function()
		self:toggleFavorite(not self.favoriteToggled)
	end)
	ClientMod.buttonManager:addBasicButtonCons(favoriteButton)
end

function ItemStash:toggleFavorite(newBool)
	local favoriteButton = stashFrame.DecorFrame.FavoritesFrame.FavoriteButton

	self.favoriteToggled = newBool

	if newBool then
		favoriteButton.Title.Text = "Favorite: ON"
	else
		favoriteButton.Title.Text = "Favorite: OFF"
	end
end

function ItemStash:addCons()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	self.templateStashItem = stashFrame.InnerFrame.Pages.Inventory.TemplateItem
	self.templateStashItem.Visible = false

	local closeButton = stashFrame.InnerFrame.Close
	ClientMod.buttonManager:addActivateCons(closeButton, function()
		self:toggle({
			newBool = false,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(closeButton)

	local autoSellButton = stashFrame.InnerFrame.AutoSellButton
	ClientMod.buttonManager:addActivateCons(autoSellButton, function()
		self:toggle({
			newBool = false,
		})
		ClientMod.autoSellManager:toggle({
			newBool = true,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(autoSellButton)
end

function ItemStash:addTabCons()
	local tabsFrame = stashFrame.DecorFrame.Tabs

	local tabList = {
		"All",
		"Pets",
		"Relics",
		"Crates",
	}

	for _, tabClass in ipairs(tabList) do
		local frame = tabsFrame:FindFirstChild(tabClass)
		self:newTabMod({
			tabClass = tabClass,
			frame = frame,
		})
	end
end

function ItemStash:newTabMod(tabData)
	local tabClass = tabData["tabClass"]
	local frame = tabData["frame"]

	ClientMod.buttonManager:addActivateCons(frame, function()
		self:chooseTab(tabClass)
	end)

	local newTabMod = {
		tabClass = tabClass,
		frame = frame,
	}
	self.tabMods[tabClass] = newTabMod
end

function ItemStash:chooseTab(tabClass)
	self.chosenTabClass = tabClass

	local timer = 0.3

	for currTabClass, tabMod in pairs(self.tabMods) do
		local frame = tabMod["frame"]

		if currTabClass == tabClass then
			continue
		end

		ClientMod.tweenManager:createTween({
			target = frame.UIScale,
			timer = timer,
			easingStyle = "Quad",
			easingDirection = "Out",
			goal = {
				Scale = 1,
			},
		})
	end

	local chosenTabMod = self.tabMods[tabClass]
	local frame = chosenTabMod["frame"]

	ClientMod.tweenManager:createTween({
		target = frame.UIScale,
		timer = timer,
		easingStyle = "Quad",
		easingDirection = "Out",
		goal = {
			Scale = 1.3,
		},
	})

	self:refreshGUI()
end

function ItemStash:addBottomCons()
	self.templateBottomItem = bottomFrame.TemplateItem
	self.templateBottomItem.Visible = false

	local inventoryButton = bottomFrame.Inventory
	ClientMod.buttonManager:addActivateCons(inventoryButton, function()
		self:toggle({
			newBool = not self.toggled,
		})
	end)
	self.inventoryButton = inventoryButton
	-- ClientMod.buttonManager:addBasicButtonCons(inventoryButton)
end

function ItemStash:addDisplayCons()
	local camera = workspace.CurrentCamera
	camera:GetPropertyChangedSignal("ViewportSize"):connect(function()
		self:refreshDisplay()
	end)
	self:refreshDisplay()
end

function ItemStash:chooseInfoItemMod(itemMod)
	self.chosenInfoItemMod = itemMod

	if not itemMod then
		return
	end

	local itemStats = self:getFullItemStats(itemMod["itemClass"])
	itemInfoFrame.NameTitle.Text = itemStats["alias"]

	local rating = itemStats["rating"] or "Common"

	local ratingTitle = itemInfoFrame.RatingTitle
	ratingTitle.Text = rating
	ClientMod.ratingManager:applyRatingColor(ratingTitle, rating)

	local descriptionTitle = itemInfoFrame.DescriptionTitle

	local descriptionText = self:getDescriptionText(itemMod)
	if descriptionText then
		descriptionTitle.Text = descriptionText
		descriptionTitle.Visible = true
	else
		descriptionTitle.Visible = false
		descriptionTitle.Text = ""
	end
end

function ItemStash:getDescriptionText(itemMod)
	local itemClass = itemMod["itemClass"]
	local race = itemMod["race"]

	local itemStats = self:getFullItemStats(itemClass)

	if race ~= "relic" then
		return itemStats["description"]
	end

	-- Mapping from stat keys to display names
	local statMapping = {
		coins = "Coins",
		damage = "Damage",
		attackSpeed = "Atk Speed",
		attackCount = "Bullet Count",
		critChance = "Crit Chance",
	}

	-- Order for display
	local orderList = { "coins", "damage", "attackSpeed", "attackCount" }

	local descriptionParts = {}

	for _, statKey in pairs(orderList) do
		local statValue = itemMod[statKey]

		if statValue == 1 then
			continue
		end
		if statValue and statValue > 0 then
			local displayName = statMapping[statKey]
			table.insert(descriptionParts, "x" .. Common.abbreviateNumber(statValue, 1) .. " " .. displayName)
		end
	end
	-- print(descriptionParts)

	return table.concat(descriptionParts, ", ")
end

function ItemStash:tick()
	self:tickInfoFrame()
end

function ItemStash:tickInfoFrame()
	local mouse = player:GetMouse()
	local mouseX = mouse.X
	local mouseY = mouse.Y

	if self.chosenInfoItemMod then
		itemInfoFrame.Visible = true
		local chosenFrame = self.chosenInfoItemMod.frame

		local absolutePosition = chosenFrame.AbsolutePosition
		local absoluteSize = chosenFrame.AbsoluteSize

		local uiPadding = stashGUI.UIPadding
		local paddingLeft = uiPadding.PaddingLeft.Offset
		local paddingBottom = uiPadding.PaddingBottom.Offset

		if self.chosenInfoItemMod["isBottomMod"] then
			local finalX = absolutePosition.X - paddingLeft - itemInfoFrame.AbsoluteSize.X / 2 + absoluteSize.X / 2
			local finalY = absolutePosition.Y - paddingBottom - itemInfoFrame.AbsoluteSize.Y

			itemInfoFrame.Position = UDim2.new(0, finalX, -0.03, finalY)
		else
			local finalX = mouseX - paddingLeft
			local finalY = mouseY - paddingBottom

			itemInfoFrame.Position = UDim2.new(0, finalX, 0, finalY)
		end
	else
		itemInfoFrame.Visible = false
	end
end
function ItemStash:newBottomMod(itemData)
	local itemClass = itemData["itemClass"]
	local itemName = itemData["itemName"]
	local index = itemData["index"]

	local itemStats = self:getFullItemStats(itemClass)

	local frame = self.templateBottomItem:Clone()
	frame.Visible = true
	frame.Parent = self.templateBottomItem.Parent

	frame.LayoutOrder = index

	local newBottomMod = {
		itemName = itemName,
		frame = frame,
		index = index,

		isBottomMod = true,
	}
	for k, v in pairs(itemData) do
		newBottomMod[k] = v
	end

	frame.Size = self.tileSize

	ClientMod.buttonManager:addActivateCons(frame, function()
		self:clickBottomItem(newBottomMod)
	end)

	ClientMod.buttonManager:addActivateCons(frame.CloseButton, function()
		self:removeBottomMod(newBottomMod)
		self:refreshGUI()
	end)

	local closeButton = frame.CloseButton
	closeButton.Visible = false

	local favoriteIcon = frame.FavoriteIcon
	favoriteIcon.Visible = false

	if itemClass ~= "Bat1" then
		-- add close button
		frame.MouseEnter:Connect(function()
			newBottomMod.enterStep = ClientMod.step
			closeButton.Visible = true

			self:chooseInfoItemMod(newBottomMod)
		end)

		frame.MouseLeave:Connect(function()
			-- print("MOUSE LEAVE")
			local enterStep = newBottomMod.enterStep
			routine(function()
				wait(1)
				if enterStep ~= newBottomMod.enterStep then
					return
				end
				closeButton.Visible = false
			end)

			if self.chosenInfoItemMod == newBottomMod then
				self:chooseInfoItemMod(nil)
			end
		end)
	end

	local innerFrame = frame.InnerFrame

	local mutationTitle = innerFrame.Tags.MutationTitle
	mutationTitle.Visible = false

	local race = newBottomMod["race"]
	if race == "relic" then
		innerFrame.Icon.Image = itemStats["image"]
	elseif race == "crate" then
		innerFrame.Icon.Image = itemStats["image"]
	elseif race == "pet" then
		innerFrame.Icon.Image = PetInfo:getPetImage(itemClass, newBottomMod["mutationClass"])
		ClientMod.mutationManager:applyMutationColor(mutationTitle, newBottomMod["mutationClass"])
	else
		innerFrame.Icon.Image = itemStats["image"]
	end

	-- shorten to only 10 characters max
	local alias = itemStats["alias"]
	if string.len(alias) > 13 then
		alias = string.sub(alias, 1, 13)
	end

	local nameTitle = innerFrame.Tags.NameTitle
	nameTitle.Text = alias

	local rating = itemStats["rating"]
	if not rating then
		rating = "Common"
	end
	ClientMod.ratingManager:applyRatingColor(nameTitle, rating)

	self.bottomMods[itemName] = newBottomMod
	table.insert(self.bottomModsList, newBottomMod)

	self:refreshAllBottomMods()

	-- print("NEW BOTTOM MOD: ", itemName, newBottomMod)

	if newBottomMod["petClass"] == "CappuccinoAssassino" then
		ClientMod.tutManager:initPetHintIcon(frame)
	end
	if newBottomMod["itemName"] == "Bat1" then
		ClientMod.tutManager:initBatHintIcon(frame)
	end

	return newBottomMod
end

function ItemStash:updateAlert(data)
	local bool = data["bool"]
	local count = data["count"]

	local inventoryButton = self.inventoryButton
	local alertIcon = inventoryButton.AlertIcon
	if bool then
		if self.toggled then
			local alertData = {
				moduleName = "itemStash",
				bool = false,
			}
			ClientMod:FireServer("updateAlert", alertData)
			return
		end

		alertIcon.Visible = true
		alertIcon.Title.Text = Common.abbreviateNumber(count, 1)
	else
		alertIcon.Visible = false
	end
end

function ItemStash:clickBottomItem(bottomMod)
	if self.chosenBottomMod == bottomMod then
		local chosenTutMod = ClientMod.tutManager.chosenTutMod
		if
			chosenTutMod
			and Common.listContains(
				{ "CompleteFirstWave", "CompleteSecondWave", "PressPlay", "PlaceFirstPet" },
				chosenTutMod["targetClass"]
			)
		then
			return
		end
		self:chooseBottomMod(nil)
	else
		self:chooseBottomMod(bottomMod)
	end

	local itemMod = self.itemMods[bottomMod["itemName"]]
	if itemMod or Common.listContains(self.toolClasses, bottomMod["itemName"]) then
		-- print("CLICKING BOTTOM ITEM: ", bottomMod["itemName"])
		ClientMod:FireServer("tryEquipBottomMod", {
			itemName = bottomMod["itemName"],
		})
	end
end

function ItemStash:chooseBottomMod(bottomMod)
	self.chosenBottomMod = bottomMod
	self:refreshAllBottomModTweens()
end

function ItemStash:refreshAllBottomModTweens()
	for _, bottomMod in pairs(self.bottomModsList) do
		local frame = bottomMod["frame"]
		local goalSize = self.tileSize
		if self.chosenBottomMod == bottomMod then
			goalSize = UDim2.fromOffset(self.tileSize.X.Offset * 1.1, self.tileSize.Y.Offset * 1.1)
		end

		ClientMod.tweenManager:createTween({
			target = frame,
			timer = 0.25,
			easingStyle = "Quad",
			easingDirection = "Out",
			goal = {
				Size = goalSize,
			},
		})
	end

	self.inventoryButton.Size = self.tileSize
end

function ItemStash:removeBottomMod(itemData)
	local itemName = itemData["itemName"]

	local bottomMod = self.bottomMods[itemName]
	if not bottomMod then
		return
	end

	if Common.listContains(self.toolClasses, itemName) then
		warn(debug.traceback())
		warn("REMOVING BASIC TOOL BOTTOM MOD")
		return
	end

	local frame = bottomMod.frame
	if frame then
		frame:Destroy()
	end

	self.bottomMods[itemName] = nil
	Common.removeFromTable(self.bottomModsList, bottomMod)

	if self.chosenBottomMod == bottomMod then
		-- self:chooseBottomMod(nil)
		self:clickBottomItem(bottomMod)
	end

	self:refreshAllBottomMods()
end

function ItemStash:refreshAllBottomMods()
	table.sort(self.bottomModsList, function(a, b)
		return a["index"] < b["index"]
	end)

	local index = 3
	for _, bottomMod in ipairs(self.bottomModsList) do
		local frame = bottomMod["frame"]
		local countTitle = frame.InnerFrame.CountTitle

		if bottomMod["index"] == -1 then
			countTitle.Visible = false
			continue
		end

		frame.LayoutOrder = index

		bottomMod["index"] = index

		self:refreshBottomMod(bottomMod)
		index += 1
	end
end

function ItemStash:refreshBottomMod(bottomMod)
	local index = bottomMod["index"]
	local frame = bottomMod["frame"]

	local innerFrame = frame.InnerFrame
	local countTitle = innerFrame.CountTitle

	frame.InputVisual.Title.Text = index

	local count = bottomMod["count"] or 0

	-- print("REFRESHING BOTTOM MOD: ", index, bottomMod)

	if count > 1 then
		countTitle.Text = "x" .. count
		countTitle.Visible = true
	else
		countTitle.Visible = false
	end

	local favoriteIcon = frame.FavoriteIcon
	favoriteIcon.Visible = bottomMod["favorited"]

	local relicIcon = innerFrame.RelicIcon

	local race = bottomMod["race"]
	if race == "pet" then
		local relicMods = bottomMod["relicMods"]

		if len(relicMods) > 0 then
			relicIcon.Visible = true
			for _, relicMod in pairs(relicMods) do
				local relicClass = relicMod["relicClass"]
				local relicStats = RelicInfo:getMeta(relicClass)
				relicIcon.Image = relicStats["image"]
				break
			end
		else
			relicIcon.Visible = false
		end
	else
		relicIcon.Visible = false
	end
end

function ItemStash:refreshDisplay()
	local newDevice = ClientMod.deviceManager:getDevice()
	if self.currDevice == newDevice then
		return
	end
	self.currDevice = newDevice

	if newDevice == "Mobile" then
		-- Mobile layout
		self.tileSize = UDim2.fromOffset(58, 58)
		bottomFrame.Position = UDim2.fromScale(0.475, 1)
	else
		-- Desktop layout
		self.tileSize = UDim2.fromOffset(80, 80)
		bottomFrame.Position = UDim2.fromScale(0.5, 1)
	end

	self:refreshGUI()
end

function ItemStash:toggle(data)
	local newBool = data["newBool"]

	if newBool == self.toggled then
		return
	end

	if newBool then
		ClientMod.uiManager:animateOpen(stashFrame)
		ClientMod.uiManager:toggleOffAllGUI()

		if ClientMod.alertManager then
			ClientMod.alertManager:tryClearAlert("itemStash")
		end
	else
		self:chooseInfoItemMod(nil)

		self:toggleFavorite(false)
	end

	ClientMod.uiManager:interactMainFrame(stashFrame, data)

	self.toggled = newBool
end

function ItemStash:updateAllItemMods(data)
	local noRefreshGUI = true

	-- see if any existing itemMods are not in the new data
	for itemName, itemMod in pairs(self.itemMods) do
		local newItemData = data["itemMods"][itemName]
		if not newItemData then
			self:removeItemMod(itemMod, noRefreshGUI)
		end
	end

	for _, itemData in pairs(data["itemMods"]) do
		self:updateItemMod({
			itemMod = itemData,
			noRefreshGUI = noRefreshGUI,
			noClick = true,
		})
	end

	self:refreshGUI()
end

function ItemStash:updateItemMod(data)
	local itemData = data["itemMod"]
	local noRefreshGUI = data["noRefreshGUI"]
	local noClick = data["noClick"]
	local forceBottom = data["forceBottom"]

	local itemClass = itemData["itemClass"]
	if Common.listContains({ "Coins" }, itemClass) then
		ClientMod.currManager:updateItemMod(itemData)
		return
	end

	if itemData["deleted"] then
		self:removeItemMod(itemData)
		return
	end

	local itemName = itemData["itemName"]
	local itemMod = self.itemMods[itemName]
	if not itemMod then
		itemMod = self:newItemMod(itemData)
		-- try to add to bottom mods
		if len(self.bottomModsList) < 6 or forceBottom then
			if noClick == nil then
				noClick = true
			end

			self:toggleBottomItem(itemMod, noClick)
		end
	end
	for k, v in pairs(itemData) do
		itemMod[k] = v
	end

	local bottomMod = self.bottomMods[itemName]
	if bottomMod then
		bottomMod["favorited"] = itemMod["favorited"]
		bottomMod["count"] = itemMod["count"]

		self:refreshBottomMod(bottomMod)
	end

	if not noRefreshGUI then
		self:refreshGUI()
	end
end

function ItemStash:newItemMod(itemData)
	local itemName = itemData["itemName"]

	local frame = self.templateStashItem:Clone()
	frame.Visible = true
	frame.Parent = self.templateStashItem.Parent

	local newItemMod = {
		itemName = itemName,
		frame = frame,
	}
	for k, v in pairs(itemData) do
		newItemMod[k] = v
	end

	local itemClass = itemData["itemClass"]
	local itemStats = self:getFullItemStats(itemClass)

	local buttonFrame = frame.ButtonFrame

	-- shorten to only 10 characters max
	local alias = itemStats["alias"]
	if string.len(alias) > 13 then
		alias = string.sub(alias, 1, 13)
	end

	local nameTitle = buttonFrame.NameTitle
	nameTitle.Text = alias

	local rating = itemStats["rating"]
	if not rating then
		rating = "Common"
	end
	ClientMod.ratingManager:applyRatingColor(nameTitle, rating)

	local icon = buttonFrame.Icon

	local race = newItemMod["race"]
	if race == "pet" then
		icon.Image = PetInfo:getPetImage(itemClass, newItemMod["mutationClass"])
	elseif race == "relic" then
		local relicStats = RelicInfo:getMeta(itemClass)
		icon.Image = relicStats["image"]
	elseif race == "crate" then
		local crateStats = CrateInfo:getMeta(itemClass)
		icon.Image = crateStats["image"]
	end

	-- add weight title
	local weightTitle = buttonFrame.BottomFrame.WeightTitle
	weightTitle.Visible = false
	if race == "pet" then
		local currWeight = PetInfo:getRealWeight(itemClass, newItemMod["baseWeight"], newItemMod["level"])
		newItemMod["currWeight"] = currWeight

		weightTitle.Text = Common.abbreviateNumber(currWeight, 2) .. "kg"
		weightTitle.Visible = true
	end

	local mutationClass = newItemMod["mutationClass"]

	-- add mutation title
	local mutationTitle = buttonFrame.MutationTitle
	mutationTitle.Visible = false

	-- add power title
	local powerTitle = buttonFrame.BottomFrame.PowerTitle
	powerTitle.Visible = false
	if race == "relic" then
		powerTitle.Text = RelicInfo:getTotalPower(newItemMod)
		powerTitle.Visible = true
	elseif race == "pet" then
		ClientMod.mutationManager:applyMutationColor(mutationTitle, mutationClass)
	end

	ClientMod.buttonManager:addActivateCons(buttonFrame, function()
		if self.favoriteToggled then
			ClientMod:FireServer("toggleItemFavorite", {
				itemName = itemName,
			})
			return
		end

		self:toggleBottomItem(newItemMod)
	end)

	-- ClientMod.buttonManager:addBasicButtonCons(buttonFrame)

	ClientMod.buttonManager:addButtonPressCons({
		button = buttonFrame,
		animatePress = true,
	})

	-- add close button
	frame.MouseEnter:Connect(function()
		newItemMod.enterStep = ClientMod.step

		self:chooseInfoItemMod(newItemMod)
	end)

	frame.MouseLeave:Connect(function()
		-- print("MOUSE LEAVE")
		local enterStep = newItemMod.enterStep
		routine(function()
			wait(1)
			if enterStep ~= newItemMod.enterStep then
				return
			end
		end)

		if self.chosenInfoItemMod == newItemMod then
			self:chooseInfoItemMod(nil)
		end
	end)

	frame.Name = itemName

	self.itemMods[itemName] = newItemMod
	table.insert(self.itemModsList, newItemMod)

	if race == "pet" then
		ClientMod.luckWizardManager:refreshPetMods()
	end

	return newItemMod
end

function ItemStash:toggleBottomItem(itemData, noClick)
	itemData = Common.deepCopy(itemData)
	itemData["frame"] = nil

	local itemName = itemData["itemName"]

	local bottomMod = self.bottomMods[itemName]
	if not bottomMod then
		if len(self.bottomModsList) >= 6 then
			-- get 6th bottom mod
			local currBottomMod = self.bottomModsList[6]
			self:removeBottomMod(currBottomMod)
		end
		local index = len(self.bottomModsList) + 1
		itemData["index"] = index
		bottomMod = self:newBottomMod(itemData)

		-- self:chooseBottomMod(bottomMod)
		if not noClick then
			self:clickBottomItem(bottomMod)
		end
	else
		self:removeBottomMod(itemData)
	end

	self:refreshGUI()
end

function ItemStash:getFullItemStats(itemClass)
	local itemStats = ItemInfo:getMeta(itemClass, true)
		or ToolInfo:getMeta(itemClass, true)
		or PetInfo:getMeta(itemClass, true)
		or RelicInfo:getMeta(itemClass, true)
		or CrateInfo:getMeta(itemClass, true)

	if not itemStats then
		warn("NO ITEM STATS FOUND FOR: ", itemClass)
	end

	return itemStats
end

function ItemStash:removeItemMod(itemData, noRefreshGUI)
	local itemName = itemData["itemName"]

	local itemMod = self.itemMods[itemName]
	if not itemMod then
		return
	end

	local race = itemMod["race"]

	local frame = itemMod.frame
	if frame then
		frame:Destroy()
	end

	self.itemMods[itemName] = nil
	Common.removeFromTable(self.itemModsList, itemMod)

	self:removeBottomMod(itemData)

	if not noRefreshGUI then
		self:refreshGUI()
	end

	if race == "pet" then
		ClientMod.luckWizardManager:refreshPetMods()
	end
end

function ItemStash:refreshGUI()
	local raceMap = {
		pet = 1,
		relic = 2,
		crate = 3,
	}

	local mutationMap = {
		Normal = 1,
		Gold = 2,
		Diamond = 3,
		Bubblegum = 4,
		Volcanic = 5,
	}

	-- sort the itemModsList
	table.sort(self.itemModsList, function(a, b)
		local favoritedA = a["favorited"] and 1 or 0
		local favoritedB = b["favorited"] and 1 or 0
		if favoritedA ~= favoritedB then
			return favoritedA > favoritedB
		end

		local raceAIndex = raceMap[a["race"]]
		local raceBIndex = raceMap[b["race"]]
		if raceAIndex ~= raceBIndex then
			return raceAIndex < raceBIndex
		end

		local itemClassA = a["itemClass"]
		local itemClassB = b["itemClass"]
		local coinsPerSecondA = PetBalanceInfo.coinsPerSecondMap[itemClassA] or 0
		local coinsPerSecondB = PetBalanceInfo.coinsPerSecondMap[itemClassB] or 0
		if coinsPerSecondA ~= coinsPerSecondB then
			return coinsPerSecondA > coinsPerSecondB
		end

		-- if itemClassA ~= itemClassB then
		-- 	return itemClass < itemClassB
		-- end

		local mutationAIndex = mutationMap[a["mutationClass"] or "Normal"]
		local mutationBIndex = mutationMap[b["mutationClass"] or "Normal"]
		if not mutationAIndex or not mutationBIndex then
			warn("NO MUTATION INDEX FOUND FOR: ", a["mutationClass"], b["mutationClass"], a, b)
		end
		if mutationAIndex ~= mutationBIndex then
			return mutationAIndex > mutationBIndex
		end

		-- first sort by level
		local levelA = a["level"] or 0
		local levelB = b["level"] or 0
		if levelA ~= levelB then
			return levelA > levelB
		end

		-- then sort by weight
		local currWeightA = a["currWeight"] or 0
		local currWeightB = b["currWeight"] or 0
		if currWeightA ~= currWeightB then
			return currWeightA > currWeightB
		end

		-- finally sort by itemName if everything else is the same
		return a["itemName"] < b["itemName"]
	end)

	local totalPetCount = 0
	local totalRelicCount = 0

	for i, itemMod in ipairs(self.itemModsList) do
		local frame = itemMod["frame"]
		frame.LayoutOrder = i

		local race = itemMod["race"]
		if self.chosenTabClass == "All" then
			frame.Visible = true
		elseif self.chosenTabClass == "Pets" then
			frame.Visible = (race == "pet")
		elseif self.chosenTabClass == "Relics" then
			frame.Visible = (race == "relic")
		elseif self.chosenTabClass == "Crates" then
			frame.Visible = (race == "crate")
		end

		if race == "pet" then
			totalPetCount += 1
		elseif race == "relic" then
			totalRelicCount += 1
		end

		local itemName = itemMod["itemName"]
		local bottomMod = self.bottomMods[itemName]

		local buttonFrame = frame.ButtonFrame
		if bottomMod then
			buttonFrame.Equipped.Visible = true
		else
			buttonFrame.Equipped.Visible = false
		end

		local relicIcon = buttonFrame.RelicIcon

		if race == "pet" then
			local relicMods = itemMod["relicMods"]
			if len(relicMods) > 0 then
				relicIcon.Visible = true
				for _, relicMod in pairs(relicMods) do
					local relicClass = relicMod["relicClass"]
					local relicStats = RelicInfo:getMeta(relicClass)
					relicIcon.Image = relicStats["image"]
					break
				end
			else
				relicIcon.Visible = false
			end
		else
			relicIcon.Visible = false
		end

		local favorited = itemMod["favorited"]
		if favorited then
			buttonFrame.FavoriteFrame.Visible = true
		else
			buttonFrame.FavoriteFrame.Visible = false
		end

		local countTitle = buttonFrame.CountTitle
		local count = itemMod["count"]
		if count > 1 then
			countTitle.Text = "x" .. count
			countTitle.Visible = true
		else
			countTitle.Visible = false
		end
	end

	local petTabMod = self.tabMods["Pets"]
	petTabMod["frame"].Title.BagSize.Text = string.format("%d/1000", totalPetCount)

	local relicTabMod = self.tabMods["Relics"]
	relicTabMod["frame"].Title.BagSize.Text = string.format("%d/1000", totalRelicCount)

	if ClientMod.sellPetManager then
		ClientMod.sellPetManager:refreshSellAllFrame()
	end
	if ClientMod.sellRelicManager then
		ClientMod.sellRelicManager:refreshSellAllFrame()
	end
end

ItemStash:init()

return ItemStash
