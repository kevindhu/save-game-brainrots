local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local ShopInfo = require(game.ReplicatedStorage.ShopInfo)

local TestManager = {}
TestManager.__index = TestManager

function TestManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.robuxCount = 0

	setmetatable(u, TestManager)
	return u
end

function TestManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	if self.isNew then
		self.robuxCount = 50000 -- 5000
	end

	self:sendRobuxCount()
end

function TestManager:updateRobuxCount(newRobuxCount)
	self.robuxCount += newRobuxCount
	self.robuxCount = math.max(self.robuxCount, 0)

	self:sendRobuxCount()
end

function TestManager:sendRobuxCount()
	ServerMod:FireClient(self.user.player, "updateRobuxCount", {
		robuxCount = self.robuxCount,
	})
end

function TestManager:checkToggled()
	return game.PlaceId == Common.testPlaceId
end

function TestManager:tryBuyProduct(productId)
	local productInfo = Common.getProductInfo(productId, Enum.InfoType.Product)
	if not productInfo then
		self.user:notifyError("!! PRODUCT NOT FOUND: " .. productId)
		return
	end

	local robuxPrice = productInfo["PriceInRobux"]

	if self.robuxCount < robuxPrice then
		self.user:notifyError("Not enough robux to purchase")
		return
	end
	self.user:notifySuccess("Thank you for your purchase!")
	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "CashBuy",
		volume = 0.5,
	})

	local productClass = ShopInfo:getClassFromId(productId)
	local productStats = ShopInfo:getMeta(productClass)

	local shopManager = self.user.home.shopManager

	local receiptData = {
		receiptName = self.user.userId .. "-" .. Common.getGUID() .. "-" .. os.time(),
		productClass = productClass,
		currencySpent = robuxPrice,
		currencyType = "FakeRobux",
		placeWherePurchased = game.PlaceId,
		playerId = self.user.userId,
		purchaseId = os.time(),
	}
	shopManager:newReceiptMod(receiptData)

	-- add the product rewards
	local rewardData = productStats["rewards"]
	self.user.home.rewardManager:addRewards(rewardData)

	-- pay the robuxPrice
	self:updateRobuxCount(-robuxPrice)
end

function TestManager:tryBuyGamepass(gamepassClass)
	local gamepassStats = ShopInfo:getMeta(gamepassClass)
	local gamepassId = gamepassStats["id"]

	local productInfo = Common.getProductInfo(gamepassId, Enum.InfoType.GamePass)
	if not productInfo then
		self.user:notifyError("!! GAMEPASS NOT FOUND: " .. gamepassClass)
		return
	end

	local robuxPrice = productInfo["PriceInRobux"]

	if self.robuxCount < robuxPrice then
		self.user:notifyError("Not enough robux to purchase")
		return
	end
	self.user:notifySuccess("Thank you for your purchase!")
	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "CashBuy",
		volume = 0.5,
	})

	local shopManager = self.user.home.shopManager
	shopManager:addGamepass(gamepassClass)

	-- pay the robuxPrice
	self:updateRobuxCount(-robuxPrice)
end

function TestManager:saveState()
	local managerData = {
		robuxCount = self.robuxCount,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function TestManager:wipe()
	self.robuxCount = 50000
	self:sendRobuxCount()
end

return TestManager
