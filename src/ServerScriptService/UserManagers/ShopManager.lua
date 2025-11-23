local market = game:GetService("MarketplaceService")

local ServerMod = require(game.ServerScriptService.ServerMod)

local ShopInfo = require(game.ReplicatedStorage.Data.ShopInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local ShopManager = {}
ShopManager.__index = ShopManager

function ShopManager.new(user, data)
	local u = {}
	u.user = user
	u.data = data

	u.gamepassMods = {}
	u.receiptMods = {}
	u.giftUserMods = {}

	setmetatable(u, ShopManager)
	return u
end

function ShopManager:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:sync(self.user)

	routine(function()
		self:refreshGamepasses()
		self:sync(self.user)

		if self.user.player.MembershipType == Enum.MembershipType.Premium then
			self:addPremiumBenefits()
		end
	end)
end

function ShopManager:rewardProductFromReceipt(receiptData)
	local productId = receiptData["ProductId"]

	local productClass = ShopInfo:getClassFromId(productId)
	local productStats = ShopInfo:getMeta(productClass)

	routine(function()
		local productInfo = Common.getProductInfo(productId, Enum.InfoType.Product)
		if not productInfo then
			warn("NO PRODUCT INFO FOUND FOR: ", productId)
			return
		end

		local robuxCost = productInfo["PriceInRobux"]
		self.user.statManager:incrementStatMod("RobuxSpent", robuxCost)

		print("LOGGING PURCHASE: ", robuxCost, productClass)

		self.user.analyticsManager:logCustomEvent("Purchases", robuxCost, {
			"Product",
		})
	end)

	self.user.notifyManager:notifySuccess("Thank you for your purchase!")
	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "CashBuy",
		volume = 0.5,
	})

	-- add the receiptMod
	local receiptName = receiptData["PlayerId"] .. "-" .. receiptData["PurchaseId"]
	receiptData["receiptName"] = receiptName
	receiptData["currencyType"] = "Robux"
	receiptData["productClass"] = productClass
	self:newReceiptMod(receiptData)

	-- add the product rewards
	local rewardData = productStats["rewards"]

	if self.giftingUserId then
		self:addGiftUserMod({
			receiptName = receiptName,
			userId = self.giftingUserId,
			productClass = productClass,
		})
		-- clear the giftingUserId
		self.giftingUserId = nil

		self:tryResolveGiftUserMods()
		return
	end
	self.user.rewardManager:addRewards(rewardData)
end

function ShopManager:tick()
	self:tickResolveGiftUserMods()
end

function ShopManager:tickResolveGiftUserMods()
	if self.checkResolveGiftExpiree and self.checkResolveGiftExpiree > ServerMod.step then
		return
	end
	-- every 5 seconds
	self.checkResolveGiftExpiree = ServerMod.step + 60 * 5
	self:tryResolveGiftUserMods()
end

function ShopManager:tryResolveGiftUserMods()
	for receiptName, giftUserMod in pairs(self.giftUserMods) do
		local userId = giftUserMod["userId"]
		local otherUser = ServerMod.userManager:getUserFromUserId(userId)
		if not otherUser or not otherUser.initialized then
			continue
		end

		local productClass = giftUserMod["productClass"]
		local productStats = ShopInfo:getMeta(productClass)

		otherUser.notifyManager:notifySuccess("%s gifted you '%s'!", self.user.name, productStats["alias"])

		local otherRewardManager = otherUser.rewardManager
		otherRewardManager:addRewards(productClass)

		-- clear the receipt
		self.giftUserMods[receiptName] = nil
	end
end

function ShopManager:addGiftUserMod(data)
	local receiptName = data["receiptName"]
	local userId = data["userId"]
	local productClass = data["productClass"]

	local newGiftUserMod = {
		userId = userId,
		productClass = productClass,
		purchaseTime = os.time(),
	}
	self.giftUserMods[receiptName] = newGiftUserMod
end

function ShopManager:getReceiptMod(receiptName)
	return self.receiptMods[receiptName]
end

function ShopManager:newReceiptMod(receiptData)
	local newReceiptMod = {
		purchaseId = receiptData["PurchaseId"],
		playerId = receiptData["PlayerId"],
		productId = receiptData["ProductId"],

		-- cannot put this in the datastore, its an Enum!
		-- currencyType = receiptData["CurrencyType"],

		currencySpent = receiptData["CurrencySpent"],
		placeWherePurchased = receiptData["PlaceIdWherePurchased"],
		productClass = receiptData["productClass"],
		receiptName = receiptData["receiptName"],
		timestamp = os.time(),
	}

	-- print(typeof(receiptData["CurrencyType"]))

	self.receiptMods[receiptData["receiptName"]] = newReceiptMod
end

function ShopManager:tryBuyGamepass(data)
	local gamepassClass = data["gamepassClass"]
	local giftingUserId = data["giftingUserId"]

	if self.gamepassMods[gamepassClass] then
		self.user.notifyManager:notifyError("You already have this gamepass!")
		return
	end

	if giftingUserId then
		self:tryBuyProduct({
			productClass = gamepassClass .. "Gift",
			giftingUserId = giftingUserId,
		})
		return
	end

	local gamepassStats = ShopInfo:getMeta(gamepassClass)
	if not gamepassStats then
		warn("NO GAMEPASS STATS FOUND FOR: ", gamepassClass)
		return
	end

	local testManager = self.user.testManager
	if testManager:checkToggled() then
		testManager:tryBuyGamepass(gamepassClass)
		return
	end

	local gamepassId = gamepassStats["id"]

	self:toggleProductLoading(true)
	market:PromptGamePassPurchase(self.user.player, gamepassId)
end

function ShopManager:tryBuyProduct(data)
	local productClass = data["productClass"]

	local productId = ShopInfo:getMeta(productClass)["id"]
	if not productId then
		warn("NO ID FOUND FOR PRODUCTCLASS: ", productClass)
		return
	end

	local valid, reasonText = self:checkValidProduct(productClass)
	if not valid then
		self.user.notifyManager:notifyError(string.format("Cannot buy product: %s", reasonText))
		return
	end

	self.giftingUserId = data["giftingUserId"]

	local testManager = self.user.testManager
	if testManager:checkToggled() then
		testManager:tryBuyProduct(productId)
		return
	end

	self:toggleProductLoading(true)
	market:PromptProductPurchase(self.user.player, productId)
end

function ShopManager:addPremiumBenefits()
	-- self.user.afkManager:startTimer()
end

function ShopManager:tryBuyPremium(data)
	local player = self.user.player

	if player.MembershipType == Enum.MembershipType.Premium then
		self.user.notifyManager:notifyError("You already have Premium!")
		return
	end
	market:PromptPremiumPurchase(player)
end

function ShopManager:checkValidProduct(productClass)
	-- see if even buyable
	local productStats = ShopInfo:getMeta(productClass)

	local rewards = productStats["rewards"]
	if rewards["permanentToolClass"] then
		local toolMod = self.user.toolManager.permanentToolMods[rewards["permanentToolClass"]]
		if toolMod then
			return false, "You already have this tool!"
		end
	end

	local policyMod = self.user.policyMod
	if policyMod["ArePaidRandomItemsRestricted"] and not productStats["notRestrictedPaidItem"] then
		-- NOTE: safest option but maybe could be more lenient like down below
		return false, "Restricted paid item!"
	end

	return true
end

function ShopManager:checkOwnsGamepass(gamepassClass)
	return self.gamepassMods[gamepassClass] ~= nil
end

function ShopManager:addGamepassFromMarket(gamepassClass)
	self.user.notifyManager:notifySuccess("Thank you for your purchase!")
	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "CashBuy",
		volume = 0.5,
	})

	routine(function()
		local id = ShopInfo:getMeta(gamepassClass)["id"]
		local productInfo = Common.getProductInfo(id, Enum.InfoType.GamePass)

		if not productInfo then
			warn("NO PRODUCT INFO FOUND FOR: ", gamepassClass)
			return
		end

		local robuxCost = productInfo["PriceInRobux"]
		self.user.statManager:incrementStatMod("RobuxSpent", robuxCost)

		print("LOGGING PURCHASE: ", robuxCost, gamepassClass)

		self.user.analyticsManager:logCustomEvent("Purchases", robuxCost, {
			"Gamepass",
		})
	end)

	self:addGamepass(gamepassClass)
end

function ShopManager:addGamepass(gamepassClass)
	local newGamePassMod = {
		purchaseTime = os.time(),
	}
	self.gamepassMods[gamepassClass] = newGamePassMod

	for _, otherUser in pairs(ServerMod.userManager:getAllUsers()) do
		self:sync(otherUser)
	end

	self:addGamepassBenefits(gamepassClass)
end

function ShopManager:addGamepassBenefits(gamepassClass)
	-- TODO: add all benefits here
	self.user:refreshWalkspeed()

	self.user.plotManager:refreshSafeZone()
end

function ShopManager:tryBuyNextServerLuck()
	local serverLuck = ServerMod.luckManager.serverLuck
	local productClass = ShopInfo:getNextServerLuckProduct(serverLuck)

	self:tryBuyProduct({
		productClass = productClass,
	})
end

function ShopManager:toggleProductLoading(newBool)
	ServerMod:FireClient(self.user.player, "toggleProductLoading", newBool)
end

function ShopManager:sync(user)
	ServerMod:FireClient(user.player, "updateUserOwnedGamepassMods", {
		userName = self.user.name,
		gamepassMods = self.gamepassMods,
	})
end

function ShopManager:refreshGamepasses()
	local userId = self.user.userId

	-- add all the gamepasses from roblox API calls
	for gamepassClass, _ in pairs(ShopInfo.gamepasses) do
		local gamepassId = ShopInfo:getMeta(gamepassClass)["id"]
		local ownsPass
		local success, response = pcall(function()
			ownsPass = market:UserOwnsGamePassAsync(userId, gamepassId)
		end)
		if not ownsPass then
			continue
		end
		if self.gamepassMods[gamepassClass] then
			continue
		end
		self:addGamepass(gamepassClass)
	end

	-- refresh all the benefits
	for gamepassClass, gamepassMod in pairs(self.gamepassMods) do
		self:addGamepassBenefits(gamepassClass)
	end
end

function ShopManager:wipe()
	self.gamepassMods = {}
	self.receiptMods = {}
	self.giftUserMods = {}

	self:refreshGamepasses()
	self:sync(self.user)
end

function ShopManager:saveState()
	local managerData = {
		gamepassMods = self.gamepassMods,
		receiptMods = self.receiptMods,
		giftUserMods = self.giftUserMods,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function ShopManager:destroy() end

return ShopManager
