local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local mainEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("MainEvent")
mainEvent.OnClientEvent:connect(function(req, ...)
	local fullData = { ... }
	local data = fullData[1]

	handleRequest(req, data)
end)

function handleRequest(req, data)
	local user = ClientMod:getLocalUser()
	if not user then
		print("NO LOCAL USER FOUND FOR REQUEST WHAAAAAAAT: ", req)
		return
	end

	-- FINISH INIT
	if req == "finishUserInit" then
		user:finishInit(data)

	-- NOTIFYMANAGER
	elseif req == "addNotify" then
		ClientMod.notifyManager:newNotifyMod(data)

	-- USERMANAGER
	elseif req == "addUser" then
		ClientMod.userManager:addUser(data)
	-- elseif req == "updateUserContext" then
	-- 	ClientMod.userManager:updateUserContext(data)
	elseif req == "updateUserOwnedGamepassMods" then
		ClientMod.userManager:updateUserOwnedGamepassMods(data)
	elseif req == "removeUser" then
		ClientMod.userManager:removeUser(data)
	elseif req == "toggleRagdoll" then
		ClientMod.userManager:toggleRagdoll(data)
	elseif req == "toggleControls" then
		ClientMod.userManager:toggleControls(data)
	elseif req == "toggleUserStone" then
		ClientMod.userManager:toggleUserStone(data)
	elseif req == "toggleUserIce" then
		ClientMod.userManager:toggleUserIce(data)
	elseif req == "toggleInvertedControls" then
		ClientMod.userManager:toggleInvertedControls(data)
	elseif req == "updateWalkspeed" then
		ClientMod.userManager:updateWalkspeed(data)
	elseif req == "updateUserStrength" then
		ClientMod.userManager:updateUserStrength(data)

	-- TRADEMANAGER
	elseif req == "updateGiftMod" then
		ClientMod.tradeManager:updateGiftMod(data)

	-- FRIENDMANAGER
	elseif req == "updateFriendCount" then
		ClientMod.friendManager:updateFriendCount(data)

	-- TESTMANAGER
	elseif req == "updateRobuxCount" then
		ClientMod.testManager:updateRobuxCount(data)

	-- TUTMANAGER
	elseif req == "updateTutMods" then
		ClientMod.tutManager:updateTutMods(data)
	elseif req == "updateCompletedTutMods" then
		ClientMod.tutManager:updateCompletedTutMods(data)
	elseif req == "chooseTutMod" then
		ClientMod.tutManager:chooseTutMod(data)

	-- INDEXMANAGER
	elseif req == "updateUnlockedPets" then
		ClientMod.indexManager:updateUnlockedPets(data)
	elseif req == "updateIndexRewardLevel" then
		ClientMod.indexManager:updateIndexRewardLevel(data)

	-- SOUNDMANAGER
	elseif req == "newSoundMod" then
		ClientMod.soundManager:newSoundMod(data)

	-- PETMANAGER
	elseif req == "newPetSpot" then
		ClientMod.petManager:newPetSpot(data)
	elseif req == "removePetSpot" then
		ClientMod.petManager:removePetSpot(data)
	elseif req == "updatePetSpot" then
		ClientMod.petManager:updatePetSpot(data)
	elseif req == "updatePetSpotCoins" then
		ClientMod.petManager:updatePetSpotCoins(data)
	elseif req == "showPetSpotBuyModel" then
		ClientMod.petManager:showPetSpotBuyModel(data)
	elseif req == "unlockPetSpot" then
		ClientMod.petManager:unlockPetSpot(data)

	-- BUYCRATEMANAGER
	elseif req == "updateCrateShopStock" then
		ClientMod.buyCrateManager:updateCrateShopStock(data)

	-- FIREWORKSMANAGER
	elseif req == "shootFireworks" then
		ClientMod.fireworksManager:shootFireworkSequence(data)

	-- SAVEMANAGER
	elseif req == "addWaveMod" then
		ClientMod.saveManager:addWaveMod(data)
	elseif req == "failWaveMod" then
		ClientMod.saveManager:failWaveMod(data)
	elseif req == "completeWaveMod" then
		ClientMod.saveManager:completeWaveMod(data)
	elseif req == "updateWaveModData" then
		ClientMod.saveManager:updateWaveModData(data)
	elseif req == "updatePlaying" then
		ClientMod.saveManager:updatePlaying(data)

	-- UNITMANAGER
	elseif req == "newUnit" then
		ClientMod.unitManager:newUnit(data)
	elseif req == "removeUnit" then
		ClientMod.unitManager:removeUnit(data)
	elseif req == "updateUnitAction" then
		ClientMod.unitManager:updateUnitAction(data)

	-- MUSICMANAGER
	elseif req == "setMusicRating" then
		ClientMod.musicManager:setRating(data)

	-- SPEEDMANAGER
	elseif req == "updateAllSpeedMods" then
		ClientMod.speedManager:updateAllSpeedMods(data)

	-- UNITMANAGER
	elseif req == "bulkUpdateUnitDamage" then
		ClientMod.unitManager:bulkUpdateUnitDamage(data)

	-- ALERTMANAGER
	elseif req == "updateModuleAlert" then
		ClientMod.alertManager:updateModuleAlert(data)

	-- DAMAGEMANAGER
	elseif req == "updateDPS" then
		ClientMod.damageManager:updateDPS(data)

	-- CLAIMOFFLINEMANAGER
	elseif req == "updateCoinsOfflineData" then
		ClientMod.claimOfflineManager:updateOfflineData(data)
	elseif req == "claimedOfflineCoins" then
		ClientMod.claimOfflineManager:claimedOfflineCoins(data)

	-- BOOSTMANAGER
	elseif req == "updateBoostMods" then
		ClientMod.boostManager:updateBoostMods(data)

	-- LUCKMANAGER
	elseif req == "updateServerLuck" then
		ClientMod.luckManager:updateServerLuck(data)

	-- WEATHERMANAGER
	elseif req == "updateWeather" then
		ClientMod.weatherManager:updateWeather(data)

	-- FRIENDMANAGER
	elseif req == "updateFriends" then
		ClientMod.friendManager:updateFriends(data)

	-- ITEMSTASH
	elseif req == "updateItemMod" then
		ClientMod.itemStash:updateItemMod(data)
	elseif req == "updateAllItemMods" then
		ClientMod.itemStash:updateAllItemMods(data)

	-- FAVORITEMANAGER
	elseif req == "updateFavoriteData" then
		ClientMod.favoriteManager:updateFavoriteData(data)
	elseif req == "tryStartFavorite" then
		ClientMod.favoriteManager:tryStartFavorite()

	-- CODEMANAGER
	elseif req == "codeNotify" then
		ClientMod.codeManager:notifyText(data)

	-- SHOPMANAGER
	elseif req == "toggleProductLoading" then
		ClientMod.shopManager:toggleProductLoading(data)

	-- PLOTMANAGER
	elseif req == "updateGlobalPlot" then
		ClientMod.plotManager:updateGlobalPlot(data)
	elseif req == "clearPlotMod" then
		ClientMod.plotManager:clearPlotMod(data)

	-- CURRENCYMANAGER
	elseif req == "addCoinsNotify" then
		ClientMod.currManager:addCoinsNotify(data)

	-- TOOLMANAGER
	elseif req == "addTool" then
		ClientMod.toolManager:addTool(data)
	elseif req == "addStashTool" then
		ClientMod.toolManager:addStashTool(data)
	elseif req == "addFoodTool" then
		ClientMod.toolManager:addFoodTool(data)

	-- LEADERMANAGER
	elseif req == "addLeader" then
		ClientMod.leaderManager:addLeader(data)
	elseif req == "updateLeaderUserMods" then
		ClientMod.leaderManager:updateLeaderUserMods(data)

	-- COMMON updates
	elseif req == "updateUsernameMap" then
		Common.updateUsernameMap(data)
		ClientMod.leaderManager:refreshLeaderUsernames()

	-- GLOBAL CHAT
	elseif req == "broadcastServerMessage" then
		ClientMod.globalChatManager:broadcastServerMessage(data)
	end
end
