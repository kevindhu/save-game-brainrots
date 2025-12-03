local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local TradeManager = {}
TradeManager.__index = TradeManager

function TradeManager.new(user, data)
	local u = {}
	u.user = user
	u.data = data

	u.giftMods = {}

	setmetatable(u, TradeManager)
	return u
end

function TradeManager:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end
end

local GIFT_EXPIREE = 60
function TradeManager:tick()
	for gifterUserName, giftMod in pairs(self.giftMods) do
		if giftMod["expiree"] < os.time() then
			print("GIFT EXPIRED FOR: ", gifterUserName)
			self:clearGift(gifterUserName)
		end
	end
end

function TradeManager:tryStartTrade(data)
	local userName = data["userName"]

	local otherUser = ServerMod.userManager:getUser(userName)
	if not otherUser then
		warn("!!! NO OTHER USER FOUND FOR: ", userName)
		return
	end
	if otherUser == self.user then
		warn("!!! CAN'T SEND GIFT REQUEST TO YOURSELF: ", userName)
		return
	end

	-- get equipped toolMod
	local toolMod = self.user.toolManager:getEquippedToolMod()
	if not toolMod then
		warn("!!! NO EQUIPPED TOOL FOUND FOR: ", self.user.userName)
		return
	end
	if toolMod["race"] ~= "pet" then
		warn("!!! CAN'T GIFT NON-PET ITEM: ", toolMod["toolClass"])
		self.user.notifyManager:notifyError("Can't gift this item!")
		return
	end

	if otherUser.tradeManager:hasGiftRequest(self.user.name) then
		self.user.notifyManager:notifyError("Already sending a gift")
		return
	end

	local giftMod = {
		itemName = toolMod.toolName,
		itemClass = toolMod.toolClass,
		race = toolMod.race,
		expiree = os.time() + GIFT_EXPIREE,
	}
	otherUser.tradeManager:addGiftMod(self.user.name, giftMod)
end

function TradeManager:hasGiftRequest(userName)
	return self.giftMods[userName] ~= nil
end

function TradeManager:addGiftMod(userName, giftMod)
	if self.giftMods[userName] then
		warn("!!! GIFT MOD ALREADY EXISTS FOR: ", userName)
		return
	end

	self.giftMods[userName] = giftMod
	self:sendGiftMod(userName)
end

function TradeManager:sendGiftMod(userName)
	local giftMod = self.giftMods[userName]
	if not giftMod then
		warn("NO GIFT MOD FOUND FOR: ", userName)
		return
	end

	ServerMod:FireClient(self.user.player, "updateGiftMod", {
		gifterUserName = userName,
		giftMod = giftMod,
	})
end

function TradeManager:tryAcceptGift(data)
	local gifterUserName = data["gifterUserName"]
	local acceptBool = data["acceptBool"]

	local giftMod = self.giftMods[gifterUserName]
	if not giftMod then
		self.user.notifyManager:notifyError("Gift no longer available")
		return
	end

	local gifterUser = ServerMod.userManager:getUser(gifterUserName)
	if not gifterUser then
		self.user.notifyManager:notifyError("Other player left the game")
		return
	end
	if gifterUser.destroyed then
		self.user.notifyManager:notifyError("Other player left the game")
		return
	end
	if self.user.stashManager:checkFullPets() then
		self.user.notifyManager:notifyError("Your inventory is full!")
		return
	end

	if not acceptBool then
		-- decline the gift
		self:clearGift(gifterUserName)
		return
	end

	-- accept the gift
	local itemName = giftMod["itemName"]
	local itemMod = gifterUser.stashManager:getItemMod(itemName)

	-- item could be already deleted
	if not itemMod then
		warn("!!! NO ITEM MOD FOUND FOR: ", itemName)
		self.user.notifyManager:notifyError(string.format("Gift no longer available"))
		return
	end

	-- add the item to the user's stash
	local newItemMod = Common.deepCopy(itemMod)
	self.user.stashManager:addItemMod(newItemMod)

	-- remove the item from the gifter's stash and tools
	gifterUser.toolManager:removeStashTool({
		toolName = itemName,
	})
	gifterUser.stashManager:removeItemMod({
		itemName = itemName,
	})

	self:clearGift(gifterUserName)
end

function TradeManager:clearGift(gifterUserName)
	self.giftMods[gifterUserName] = nil
end

return TradeManager
