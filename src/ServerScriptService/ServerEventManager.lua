local ServerMod = require(script.Parent.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local ServerEventManager = {}

function ServerEventManager:init()
	self:addMainEvent()
	self:addCons()
end

function ServerEventManager:addMainEvent()
	local event = Instance.new("RemoteEvent")
	event.Name = "MainEvent"
	event.Parent = game.ReplicatedStorage.Events
	self.mainEvent = event
end

function ServerEventManager:addCons()
	local event = self.mainEvent
	event.OnServerEvent:connect(function(player, req, ...)
		local fullData = { ... }
		local data = fullData[1]
		self:handleRequest(player, req, data)
	end)
end

function ServerEventManager:handleRequest(player, req, data)
	if Common.testClonePlots then
		return
	end

	if req == "makeUser" then
		ServerMod.map:addUser(player)
		return
	end

	local user = ServerMod.users[player.Name]
	if not user then
		-- warn("NO USER TO DO SERVER REQUEST: " .. req)
		return
	end
	if not user.initialized or user.destroyed then
		-- warn("USER NOT AVAILABLE TO DO: " .. req)
		return
	end

	local home = user.home
	local plotManager = home.plotManager
	local shopManager = home.shopManager
	local codeManager = home.codeManager
	local toolManager = home.toolManager
	local indexManager = home.indexManager
	local tutManager = home.tutManager
	local itemStash = home.itemStash
	local tradeManager = home.tradeManager
	local rewardManager = home.rewardManager
	local petManager = home.petManager
	local afkManager = home.afkManager
	local favoriteManager = home.favoriteManager
	local alertManager = home.alertManager
	local speedManager = home.speedManager
	local saveManager = home.saveManager
	local crateManager = home.crateManager
	local autoSellManager = home.autoSellManager

	-- USER
	if req == "userDied" then
		user:die()

	-- AFKMANAGER
	elseif req == "idleTeleport" then
		afkManager:idleTeleport()

	-- PLOTMANAGER
	elseif req == "tryAddLike" then
		plotManager:tryAddLike(data)

	-- REWARDMANAGER
	elseif req == "tryClaimGroupReward" then
		rewardManager:tryClaimGroupReward()

	-- ITEMSTASH
	elseif req == "trySellItem" then
		itemStash:trySellItem(data)
	elseif req == "trySellAllToolItems" then
		itemStash:trySellAllToolItems(data)
	elseif req == "toggleItemFavorite" then
		itemStash:toggleItemFavorite(data)

	-- FAVORITEMANAGER
	elseif req == "finishFavoriteGame" then
		favoriteManager:finishFavoriteGame()

	-- ALERTMANAGER
	elseif req == "updateAlert" then
		alertManager:updateAlert(data)

	-- AUTOSELLMANAGER
	elseif req == "tryToggleAutoSellRatingMod" then
		autoSellManager:tryToggleRatingMod(data)

	-- PETMANAGER
	elseif req == "tryFeedPet" then
		petManager:tryFeedPet(data)
	elseif req == "tryPickupFromPetSpot" then
		petManager:tryPickupFromPetSpot(data)
	elseif req == "trySwapPetAtPetSpot" then
		petManager:trySwapPetAtPetSpot(data)
	elseif req == "trySwapRelicAtPetSpot" then
		petManager:trySwapRelicAtPetSpot(data)
	elseif req == "tryPickupRelicFromPetSpot" then
		petManager:tryPickupRelicFromPetSpot(data)
	elseif req == "tryLevelUpPet" then
		petManager:tryLevelUpPet(data)
	elseif req == "tryCollectCoins" then
		petManager:tryCollectCoins(data)
	elseif req == "tryUnlockPetSpot" then
		petManager:tryUnlockPetSpot(data)

	-- BUYCRATEMANAGER
	elseif req == "tryBuyCrate" then
		crateManager:tryBuyCrate(data)

	-- SAVEMANAGER
	elseif req == "tryTogglePlay" then
		saveManager:tryTogglePlay(data)

	-- CLAIM OFFLINE
	elseif req == "tryClaimOfflineCoins" then
		petManager:tryClaimOfflineCoins(data)

	-- INDEXMANAGER
	elseif req == "tryClaimIndexReward" then
		indexManager:tryClaimIndexReward(data)

	-- TUTMANAGER
	elseif req == "tryUpdateTutMod" then
		tutManager:tryUpdateTutMod(data)

	-- CODEMANAGER
	elseif req == "tryCode" then
		codeManager:tryCode(data)

	-- TOOLMANAGER
	elseif req == "tryBuyTool" then
		toolManager:tryBuyTool(data)
	elseif req == "tryPlacePetAtPetSpot" then
		toolManager:tryPlacePetAtPetSpot(data)
	elseif req == "tryPlaceRelicAtPetSpot" then
		toolManager:tryPlaceRelicAtPetSpot(data)
	elseif req == "tryPlaceCrate" then
		toolManager:tryPlaceCrate(data)
	elseif req == "tryEquipBottomMod" then
		toolManager:tryEquipBottomMod(data)

	-- SPEEDMANAGER
	elseif req == "tryToggleSpeedMod" then
		speedManager:tryToggleSpeedMod(data)
	elseif req == "tryUnlockSpeedMod" then
		speedManager:tryUnlockSpeedMod(data)

	-- TRADEMANAGER
	elseif req == "tryAcceptGift" then
		tradeManager:tryAcceptGift(data)
	elseif req == "tryStartTrade" then
		tradeManager:tryStartTrade(data)

	-- SHOPMANAGER
	elseif req == "tryBuyGamepass" then
		shopManager:tryBuyGamepass(data)
	elseif req == "tryBuyProduct" then
		shopManager:tryBuyProduct(data)
	elseif req == "tryBuyPremium" then
		shopManager:tryBuyPremium(data)
	elseif req == "tryBuyNextServerLuck" then
		shopManager:tryBuyNextServerLuck()
	end
end

ServerEventManager:init()

return ServerEventManager
