-- local market = game:GetService("MarketplaceService")

local ServerMod = require(game.ServerScriptService.ServerMod)

-- local ShopInfo = require(game.ReplicatedStorage.ShopInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local RewardManager = {}
RewardManager.__index = RewardManager

function RewardManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.groupRewardClaimed = false

	setmetatable(u, RewardManager)
	return u
end

function RewardManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end
end

function RewardManager:addRewards(rewardData)
	local itemMod = rewardData["itemMod"]
	local gamepassClass = rewardData["gamepassClass"]
	local setServerLuck = rewardData["setServerLuck"]
	local permanentToolClass = rewardData["permanentToolClass"]
	local potionClass = rewardData["potionClass"]
	local skipEgg = rewardData["skipEgg"]
	local zoneClass = rewardData["zoneClass"]
	local offlineCoinsBoost = rewardData["offlineCoinsBoost"]

	local home = self.user.home
	local boostManager = home.boostManager
	local toolManager = home.toolManager
	local itemStash = home.itemStash
	local plotManager = home.plotManager
	local shopManager = home.shopManager
	local zoneManager = home.zoneManager

	local premiumEggClass = rewardData["premiumEggClass"]

	if gamepassClass then
		shopManager:addGamepass(gamepassClass)
	end

	if potionClass then
		boostManager:addBoostFromPotion(potionClass)
	end

	if permanentToolClass then
		toolManager:addPermanentTool(permanentToolClass)
	end

	if offlineCoinsBoost then
		self.user.home.petManager:claimOfflineCoins({
			boost = true,
		})
	end

	if zoneClass then
		zoneManager:unlockZone(zoneClass)
		zoneManager:tryChooseZone({
			zoneClass = zoneClass,
		})
	end

	if premiumEggClass then
		local lastPremiumEggClass = self.user.home.eggManager.lastPremiumEggClass

		local count = rewardData["count"] or 1

		for i = 1, count do
			local mutationClass = self.user.home.probManager:generateMutationClass()
			if mutationClass and mutationClass ~= "None" then
				self.user:notifySuccess(string.format("Your %s mutated to %s!", lastPremiumEggClass, mutationClass))
				ServerMod:FireClient(self.user.player, "newSoundMod", {
					soundClass = "Notice",
					volume = 0.5,
				})
			end

			itemStash:addEgg({
				eggClass = lastPremiumEggClass,
				mutationClass = mutationClass,
			})
		end
	end

	if skipEgg then
		local lastPremiumSkipEggName = self.user.home.eggManager.lastPremiumSkipEggName
		local egg = self.user.home.eggManager.eggs[lastPremiumSkipEggName]
		if not egg then
			warn("!!!! NO EGG FOUND FOR: ", lastPremiumSkipEggName)
			return
		end

		-- force the hatch immediately
		egg:hatch()
	end

	if itemMod then
		itemStash:updateItemCount({
			itemName = itemMod["itemName"],
			count = itemMod["count"],
		})
	end

	if setServerLuck then
		ServerMod.luckManager:setServerLuck(self.user, setServerLuck)
	end
end

function RewardManager:tryClaimGroupReward()
	if self.groupRewardClaimed then
		self.user:notifyError("You have already claimed the group reward!")
		return
	end
	if not Common.checkInGroup(self.user.player) then
		self.user:notifyError("Like and join group to claim!")
		return
	end

	self.groupRewardClaimed = true

	self.user:notifySuccess("Group reward claimed!")

	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "SuccessRebirth",
		volume = 0.5,
	})

	self:addRewards({
		itemMod = {
			itemName = "Coins",
			count = 500,
		},
	})

	local petClass = "TrippiTroppi"
	local mutationClass = nil

	local itemData = {
		itemName = "STASHTOOL_" .. Common.getGUID(),
		itemClass = petClass,
		race = "pet",

		-- unit metadata
		creationTimestamp = os.time(),
		mutationClass = mutationClass,
		totalStrength = 0,
		variationScale = 1,
	}
	self.user.home.petManager:fillPetDataWithDefaults(itemData)

	ServerMod:FireClient(self.user.player, "doHatch", {
		petClass = petClass,
		mutationClass = mutationClass,
	})

	self.user.home.itemStash:addItemMod(itemData)
end

function RewardManager:saveState()
	local managerData = {
		groupRewardClaimed = self.groupRewardClaimed,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function RewardManager:destroy() end

return RewardManager
