local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local LuckInfo = require(game.ReplicatedStorage.LuckInfo)

local LuckWizardManager = {}
LuckWizardManager.__index = LuckWizardManager

function LuckWizardManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.currentLuck = 1
	u.maxLuck = 1

	setmetatable(u, LuckWizardManager)
	return u
end

function LuckWizardManager:init()
	self.user = self.owner.user
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
		self.user:notifyError("Reached maximum luck!")
		return
	end

	local coins = luckRequirementData["coins"]
	local currentCoins = self.user.home.itemStash:getItemCount({
		itemName = "Coins",
	})
	if currentCoins < coins then
		self.user:notifyError("Not enough coins!")
		return
	end

	local petClasses = luckRequirementData["petClasses"]

	for _, petClass in pairs(petClasses) do
		-- check if you own a item or petspot that has the petdata
		if not self:checkHasPet(petClass) then
			self.user:notifyError("You do not meet the requirements!")
			return
		end
	end

	self:upgradeLuck()

	self.user.home.itemStash:updateItemCount({
		itemName = "Coins",
		count = -coins,
	})

	for _, petClass in pairs(petClasses) do
		self:removeFirstPet(petClass)
	end
end

function LuckWizardManager:upgradeLuck()
	self.user:notifySuccess("Upgraded luck to " .. self.maxLuck .. "!")

	self.maxLuck += 1

	self:tryAdjustLuck({
		count = 1,
	})
end

function LuckWizardManager:checkHasPet(petClass)
	for _, itemMod in pairs(self.user.home.itemStash.itemMods) do
		if itemMod["itemClass"] == petClass and not itemMod["favorited"] then
			return true
		end
	end

	for _, petSpot in pairs(self.user.home.petManager.petSpots) do
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

	local itemStash = self.user.home.itemStash
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

	for _, petSpot in pairs(self.user.home.petManager.petSpots) do
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
