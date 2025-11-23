local market = game:GetService("MarketplaceService")

local ServerMod = require(game.ServerScriptService.ServerMod)

local ShopInfo = require(game.ReplicatedStorage.Data.ShopInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local MarketManager = {}

function MarketManager:init()
	self:addCons()
end

function MarketManager:addCons()
	-- PRODUCT PURCHASE FINISHED
	market.PromptProductPurchaseFinished:connect(function(userId, productId, isPurchased)
		for _, user in pairs(ServerMod.userManager:getAllUsers()) do
			if user.userId ~= userId or not user.initialized then
				continue
			end
			local shopManager = user.shopManager
			shopManager:toggleProductLoading(false)
		end
	end)

	game.Players.PlayerMembershipChanged:Connect(function(player)
		if player.MembershipType == Enum.MembershipType.Premium then
			local user = ServerMod.userManager:getUser(player.Name)
			if not user or not user.initialized then
				return
			end

			user.notifyManager:notifySuccess("Thank you for purchasing Premium!", nil, "SuccessNotify1")
			local shopManager = user.shopManager
			shopManager:addPremiumBenefits()
		end
	end)

	-- PRODUCT RECEIPT PROCESSING
	market.ProcessReceipt = function(receiptData)
		local playerId = receiptData.PlayerId
		local receiptName = playerId .. "-" .. receiptData.PurchaseId

		local player = game.Players:GetPlayerByUserId(playerId)
		if not player then
			-- PLAYER LEFT / DISCONNECTED
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local user = ServerMod.userManager:getUser(player.Name)
		if not user or not user.initialized then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- PROCESS IT NOW
		local productId = receiptData.ProductId
		if not productId then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local shopManager = user.shopManager

		-- IF RECEIPT ALREADY GRANTED
		local success = shopManager:getReceiptMod(receiptName)
		if success then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		shopManager:rewardProductFromReceipt(receiptData)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- GAMEPASS PURCHASE FINISHED
	market.PromptGamePassPurchaseFinished:connect(function(player, gamepassId, purchased)
		local user = ServerMod.userManager:getUser(player.Name)

		local shopManager = user.shopManager
		shopManager:toggleProductLoading(false)
		if not purchased then
			return
		end

		local productInfo = Common.getProductInfo(gamepassId, Enum.InfoType.GamePass)
		local newRobuxCost = 0
		if productInfo then
			newRobuxCost = productInfo["PriceInRobux"]
			user.statManager:incrementStatMod("RobuxSpent", newRobuxCost)
		end

		local gamepassClass = ShopInfo:getClassFromId(gamepassId)
		if gamepassClass then
			shopManager:addGamepassFromMarket(gamepassClass)
		end
	end)
end

MarketManager:init()

return MarketManager
