local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local SpeedInfo = require(game.ReplicatedStorage.SpeedInfo)

local SpeedManager = {}
SpeedManager.__index = SpeedManager

local ratingList = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Secret",
}

function SpeedManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.speed = 1

	u.speedMods = {}

	setmetatable(u, SpeedManager)
	return u
end

function SpeedManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:initAllSpeedMods()

	if self.isNew then
		self:unlockBasicSpeedMods()
	end

	self:sendAllSpeedMods()

	routine(function()
		wait(1)

		self:sendData()
		self.initialized = true

		wait(10)
	end)
end

function SpeedManager:initAllSpeedMods()
	for _, rating in pairs(ratingList) do
		for i = 1, 3 do
			self:initSpeedMod(rating, i)
		end
	end
end

function SpeedManager:unlockBasicSpeedMods()
	for _, rating in pairs(ratingList) do
		local index = 1

		local noSend = true
		self:unlockSpeedMod(rating, index, noSend)

		local speedName = self:getSpeedName(rating, index)
		local speedMod = self.speedMods[speedName]

		self:toggleSpeedMod(speedMod, noSend)
	end
end

function SpeedManager:tryToggleSpeedMod(data)
	local rating = data["rating"]
	local speedIndex = data["speedIndex"]

	-- toggle the new speed mod
	local speedName = self:getSpeedName(rating, speedIndex)
	local speedMod = self.speedMods[speedName]

	if rating == "Common" and speedIndex == 2 then
		self.user.home.tutManager:updateTutMod({
			targetClass = "Buy2xSpeedCommon",
			updateCount = 1,
		})
		self.user.home.tutManager:updateTutMod({
			targetClass = "Choose2xSpeedCommon",
			updateCount = 1,
		})
	end

	if not speedMod["unlocked"] then
		warn("CANNOT TOGGLE LOCKED SPEED MOD: ", speedName)
		return
	end

	self:toggleSpeedMod(speedMod)
end

function SpeedManager:tryUnlockSpeedMod(data)
	local rating = data["rating"]
	local speedIndex = data["speedIndex"]

	local speedName = self:getSpeedName(rating, speedIndex)
	local speedMod = self.speedMods[speedName]

	if speedMod["unlocked"] then
		warn("CANNOT UNLOCK UNLOCKED SPEED MOD: ", speedName)
		return
	end

	local price = SpeedInfo.speedPriceMap[rating][tostring(speedIndex)]
	local coinsCount = self.user.home.itemStash:getItemCount({
		itemName = "Coins",
	})

	if coinsCount < price then
		self.user:notifyError("Not enough coins!")
		return
	end

	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "CashBuy",
		volume = 0.3,
	})

	if rating == "Common" and speedIndex == 2 then
		self.user.home.tutManager:updateTutMod({
			targetClass = "Buy2xSpeedCommon",
			updateCount = 1,
		})
	end

	local noSend = true
	self:unlockSpeedMod(rating, speedIndex, noSend)
	self:toggleSpeedMod(speedMod, noSend)

	self.user.home.itemStash:updateItemCount({
		itemName = "Coins",
		count = -price,
	})

	self:sendAllSpeedMods()
end

function SpeedManager:toggleSpeedMod(speedMod, noSend)
	speedMod["toggled"] = true

	local speedIndex = speedMod["speedIndex"]
	local rating = speedMod["rating"]

	-- untoggle all other speed mods
	for otherSpeedIndex = 1, 3 do
		if otherSpeedIndex == speedIndex then
			continue
		end

		local otherSpeedName = self:getSpeedName(rating, otherSpeedIndex)
		local otherSpeedMod = self.speedMods[otherSpeedName]
		otherSpeedMod["toggled"] = false
	end

	if not noSend then
		self:sendAllSpeedMods()
	end
end

function SpeedManager:unlockSpeedMod(rating, speedIndex, noSend)
	local speedName = self:getSpeedName(rating, speedIndex)
	local speedMod = self.speedMods[speedName]
	if not speedMod then
		return
	end

	if speedMod["unlocked"] then
		return
	end

	speedMod["unlocked"] = true
	speedMod["hidden"] = false

	self:unhideNextSpeedMod(rating)

	if not noSend then
		self:sendAllSpeedMods()
	end
end

function SpeedManager:sendAllSpeedMods()
	ServerMod:FireAllClients("updateAllSpeedMods", {
		userName = self.user.name,
		fullSpeedModData = self.speedMods,
	})
end

function SpeedManager:sync(otherUser)
	ServerMod:FireClient(otherUser.player, "updateAllSpeedMods", {
		userName = self.user.name,
		fullSpeedModData = self.speedMods,
	})
end

function SpeedManager:unhideNextSpeedMod(rating)
	for i = 1, 3 do
		local speedName = self:getSpeedName(rating, i)
		local speedMod = self.speedMods[speedName]
		if speedMod["unlocked"] then
			continue
		end

		speedMod["hidden"] = false
		break
	end
end

function SpeedManager:initSpeedMod(rating, speedIndex)
	local speedName = self:getSpeedName(rating, speedIndex)

	if self.speedMods[speedName] then
		return
	end

	local newSpeedMod = {
		speedName = speedName,
		rating = rating,
		speedIndex = speedIndex,

		unlocked = false,
		hidden = true,
		toggled = false,
	}
	self.speedMods[speedName] = newSpeedMod
end

function SpeedManager:getSpeedName(rating, speedIndex)
	return rating .. "Speed" .. speedIndex
end

function SpeedManager:sendData()
	ServerMod:FireClient(self.user.player, "updateGameSpeed", {
		speed = self.speed,
	})
end

function SpeedManager:getSpeed()
	local saveManager = self.user.home.saveManager
	local currWaveMod = saveManager.currWaveMod
	if not currWaveMod then
		return 1
	end

	local rating = currWaveMod["rating"]

	local chosenSpeedIndex = nil
	for i = 1, 3 do
		local speedName = self:getSpeedName(rating, i)
		local speedMod = self.speedMods[speedName]
		if speedMod["toggled"] then
			chosenSpeedIndex = speedMod["speedIndex"]
			break
		end
	end

	-- print("GOT CHOSEN SPEED INDEX: ", chosenSpeedIndex)

	return chosenSpeedIndex
end

function SpeedManager:saveState()
	if not self.initialized then
		return
	end

	local managerData = {
		speedMods = self.speedMods,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

return SpeedManager
