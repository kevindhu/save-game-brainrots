local ServerMod = require(game.ServerScriptService.ServerMod)

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

	local pingRemoteFunction = Instance.new("RemoteFunction")
	pingRemoteFunction.Name = "PingRemoteFunction"
	pingRemoteFunction.Parent = game.ReplicatedStorage.Events
	self.pingRemoteFunction = pingRemoteFunction

	pingRemoteFunction.OnServerInvoke = function(player)
		return tick()
	end
end

function ServerEventManager:getPing(player)
	return self.pingRemoteFunction:InvokeClient(player)
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
		ServerMod.userManager:addUser(player)
		return
	end

	local user = ServerMod.userManager:getUser(player.Name)
	if not user then
		-- warn("NO USER TO DO SERVER REQUEST: " .. req)
		return
	end
	if not user.initialized or user.destroyed then
		-- warn("USER NOT AVAILABLE TO DO: " .. req)
		return
	end

	local plotManager = user.plotManager
	local shopManager = user.shopManager
	local codeManager = user.codeManager
	local toolManager = user.toolManager
	local tutManager = user.tutManager
	local itemStash = user.itemStash
	local tradeManager = user.tradeManager
	local rewardManager = user.rewardManager
	local petManager = user.petManager
	local afkManager = user.afkManager
	local favoriteManager = user.favoriteManager
	local alertManager = user.alertManager
	local speedManager = user.speedManager
	local saveManager = user.saveManager
	local crateManager = user.crateManager
	local autoSellManager = user.autoSellManager
	local luckWizardManager = user.luckWizardManager

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
	elseif req == "tryEquipBestPets" then
		petManager:tryEquipBestPets(data)

	-- BUYCRATEMANAGER
	elseif req == "tryBuyCrate" then
		crateManager:tryBuyCrate(data)

	-- SAVEMANAGER
	elseif req == "tryTogglePlay" then
		saveManager:tryTogglePlay(data)

	-- CLAIM OFFLINE
	elseif req == "tryClaimOfflineCoins" then
		petManager:tryClaimOfflineCoins(data)

	-- TUTMANAGER
	elseif req == "tryUpdateTutMod" then
		tutManager:tryUpdateTutMod(data)

	-- CODEMANAGER
	elseif req == "tryCode" then
		codeManager:tryCode(data)

	-- LUCKWIZARDMANAGER
	elseif req == "tryAdjustLuckWizard" then
		luckWizardManager:tryAdjustLuck(data)
	elseif req == "tryUpgradeLuckWizard" then
		luckWizardManager:tryUpgradeLuck()

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
