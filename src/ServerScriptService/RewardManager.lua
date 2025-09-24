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
	local offlineCoinsBoost = rewardData["offlineCoinsBoost"]
	local premiumCrateClass = rewardData["premiumCrateClass"]

	local home = self.user.home
	local boostManager = home.boostManager
	local toolManager = home.toolManager
	local itemStash = home.itemStash
	local plotManager = home.plotManager
	local shopManager = home.shopManager

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

	if premiumCrateClass then
		local lastPremiumCrateClass = self.user.home.crateManager.lastPremiumCrateClass

		local count = rewardData["count"] or 1

		for i = 1, count do
			itemStash:addCrate({
				crateClass = lastPremiumCrateClass,
				mutationClass = nil,
			})
		end
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

	self.user.home.itemStash:addPet({
		petClass = petClass,
		mutationClass = mutationClass,
	})

	-- TODO: reintroduce hatching
	ServerMod:FireClient(self.user.player, "doHatch", {
		userName = self.user.name,
		petClass = petClass,
		mutationClass = mutationClass,
	})
end

function RewardManager:saveState()
	local managerData = {
		groupRewardClaimed = self.groupRewardClaimed,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function RewardManager:destroy() end

return RewardManager
