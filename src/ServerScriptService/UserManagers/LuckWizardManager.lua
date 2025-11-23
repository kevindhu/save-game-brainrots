local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local LuckInfo = require(game.ReplicatedStorage.Data.LuckInfo)

local LuckWizardManager = {}
LuckWizardManager.__index = LuckWizardManager

function LuckWizardManager.new(user, data)
	local u = {}
	u.user = user
	u.data = data

	u.currentLuck = 1
	u.maxLuck = 1

	setmetatable(u, LuckWizardManager)
	return u
end

function LuckWizardManager:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end

	routine(function()
		wait(1)
		self:sendData()
		self.initialized = true
	end)
end

function LuckWizardManager:sendData()
	ServerMod:FireClient(self.user.player, "updateWizardLuck", {
		currentLuck = self.currentLuck,
		maxLuck = self.maxLuck,
	})
end

function LuckWizardManager:saveState()
	if not self.initialized then
		return
	end

	local managerData = {
		currentLuck = self.currentLuck,
		maxLuck = self.maxLuck,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function LuckWizardManager:wipe()
	self.currentLuck = 1
	self:sendData()
end

function LuckWizardManager:tryUpgradeLuck()
	-- check if possible to upgrade
	local luckRequirementData = LuckInfo.luckRequirementMap[tostring(self.maxLuck)]
	if not luckRequirementData then
		self.user.notifyManager:notifyError("Reached maximum luck!")
		return
	end

	local coins = luckRequirementData["coins"]
	local currentCoins = self.user.itemStash:getItemCount({
		itemName = "Coins",
	})
	if currentCoins < coins then
		self.user.notifyManager:notifyError("Not enough coins!")
		return
	end

	local petClasses = luckRequirementData["petClasses"]

	for _, petClass in pairs(petClasses) do
		-- check if you own a item or petspot that has the petdata
		if not self:checkHasPet(petClass) then
			self.user.notifyManager:notifyError("You do not meet the requirements!")
			return
		end
	end

	self:upgradeLuck()

	self.user.itemStash:updateItemCount({
		itemName = "Coins",
		count = -coins,
	})

	for _, petClass in pairs(petClasses) do
		self:removeFirstPet(petClass)
	end
end

function LuckWizardManager:upgradeLuck()
	self.user.notifyManager:notifySuccess("Upgraded luck to " .. self.maxLuck .. "!")
	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "CashBuy",
	})

	self.maxLuck += 1

	self:tryAdjustLuck({
		count = 1,
	})
end

function LuckWizardManager:checkHasPet(petClass)
	for _, itemMod in pairs(self.user.itemStash.itemMods) do
		if itemMod["itemClass"] == petClass and not itemMod["favorited"] then
			return true
		end
	end

	for _, petSpot in pairs(self.user.petManager.petSpots) do
		local petData = petSpot.petData
		if not petData then
			continue
		end
		if petData["petClass"] == petClass and not petData["favorited"] then
			return true
		end
	end

	return false
end

function LuckWizardManager:removeFirstPet(petClass)
	-- first try to remove from item stash

	local itemStash = self.user.itemStash
	for _, itemMod in pairs(itemStash.itemMods) do
		if itemMod["favorited"] then
			continue
		end
		if itemMod["itemClass"] == petClass then
			itemStash:removeItemMod({
				itemName = itemMod["itemName"],
			})
			return
		end
	end

	for _, petSpot in pairs(self.user.petManager.petSpots) do
		if not petSpot.petData then
			continue
		end
		if petSpot.petData["favorited"] then
			continue
		end
		if petSpot.petData["petClass"] == petClass then
			petSpot:clearPet()
			return
		end
	end
end

function LuckWizardManager:tryAdjustLuck(data)
	local count = data["count"]
	self.currentLuck += count

	self.currentLuck = math.clamp(self.currentLuck, 1, self.maxLuck)

	self:sendData()
end

return LuckWizardManager
