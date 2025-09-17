local ServerMod = require(script.Parent.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetInfo = require(game.ReplicatedStorage.PetInfo)

local PetSpot = {}
PetSpot.__index = PetSpot

function PetSpot.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.eventsList = {}

	setmetatable(u, PetSpot)
	return u
end

function PetSpot:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:refreshAttackSpeedRatio()

	self:initBuyModel()
	self:initAllEvents()

	for _, otherUser in pairs(ServerMod.users) do
		self:sync(otherUser)
	end
end

function PetSpot:refreshAttackSpeedRatio()
	if not self.petData then
		self.attackSpeedRatio = 1
		return
	end

	local level = self.petData["level"]

	local levelIncrement = 0.003
	local levelMultiplier = 1 + (level - 1) * levelIncrement
	self.attackSpeedRatio = 1 * levelMultiplier

	-- print("ATTACK SPEED RATIO: ", self.attackSpeedRatio)
end

function PetSpot:initAllEvents()
	self:createEvent("attack", "ATTACK")
end

function PetSpot:createEvent(key, alias)
	local event = Instance.new("RemoteEvent")
	event.Name = self.petSpotName .. "_" .. alias .. "EVENT"
	event.Parent = game.ReplicatedStorage.PetEvents
	self[key .. "Event"] = event
	table.insert(self.eventsList, event)
end

function PetSpot:toggleBuyModel(newBool)
	for _, child in pairs(self.buyModel:GetChildren()) do
		if child:IsA("BasePart") then
			child.Transparency = newBool and 0 or 1
			child.CanCollide = newBool
			child.CanTouch = newBool
		end
	end
end

function PetSpot:unlock()
	self:toggleBuyModel(false)

	-- init the real model
	local model = game.ReplicatedStorage.Assets.BoughtPetSpotModel:Clone()
	model.Name = self.petSpotName

	local buyBasePart = self.buyModel.BasePart
	model:PivotTo(buyBasePart.CFrame * CFrame.new(0, -buyBasePart.Size.Y * 0.5 + model.PrimaryPart.Size.Y * 0.5, 0))
	model.Parent = game.Workspace.BoughtPetSpots

	self.standPart = model:WaitForChild("StandPart")
	self.baseFrame = self.standPart.CFrame * CFrame.new(0, self.standPart.Size.Y * 0.5, 0)
	self.currFrame = self.baseFrame

	self.unlocked = true

	ServerMod:FireAllClients("unlockPetSpot", {
		petSpotName = self.petSpotName,
	})
end

function PetSpot:showBuyModel()
	self:toggleBuyModel(true)

	ServerMod:FireAllClients("showPetSpotBuyModel", {
		petSpotName = self.petSpotName,
	})
end

function PetSpot:initBuyModel()
	local plotModel = self.user.home.plotManager.model
	local buyModel = plotModel:FindFirstChild("PetSpot" .. self.index)
	if not buyModel then
		warn("!! PET SPOT MODEL NOT FOUND: ", self.index, plotModel.Name)
		return
	end

	self.buyModel = buyModel

	self:toggleBuyModel(false)
end

function PetSpot:tick(timeRatio)
	if not self.petData then
		return
	end

	self:tickAttack(timeRatio)
	self:tickCoinsGeneration(timeRatio)
end

function PetSpot:tickCoinsGeneration(timeRatio)
	if self.coinGenerationExpiree and self.coinGenerationExpiree > ServerMod.step then
		return
	end
	self.coinGenerationExpiree = ServerMod.step + 60 * 1

	local coinsCount = self.petStats["coinsPerSecond"]

	-- TODO: add multipliers here

	self.petData["totalCoins"] += coinsCount

	self:sendCoinsData()
end

function PetSpot:tickAttack(timeRatio)
	if not self.petData then
		return
	end

	local closestDist = math.huge
	local targetUnit = nil

	local currPosition = self.currFrame.Position

	for _, unit in pairs(self.user.home.unitManager.units) do
		if unit.inSafeZone then
			continue
		end
		if unit.dead then
			continue
		end
		if unit.capturedSavedPet then
			continue
		end

		local dist = Common.getHorizontalDist(currPosition, unit.currFrame.p)
		if dist < closestDist then
			closestDist = dist
			targetUnit = unit
		end
	end

	if not targetUnit then
		return
	end

	if self.attackExpiree and self.attackExpiree > ServerMod.step then
		return
	end
	self.attackExpiree = ServerMod.step + 60 * 1 / self.attackSpeedRatio

	local damage = math.random(200, 300)

	local level = self.petData["level"]
	local levelMultiplier = 1 + (level - 1) * 0.01

	-- print("LEVEL MULTIPLIER: ", levelMultiplier)

	damage = damage * levelMultiplier

	local totalDelay = 0.3 + (self.petStats["attackDelay"] or 0)
	totalDelay = totalDelay / self.attackSpeedRatio

	routine(function()
		targetUnit:updateHealth(-damage, self, totalDelay)
	end)

	self.user.home.damageManager:addDamage(damage)

	self.attackEvent:FireAllClients(targetUnit.unitName, damage, targetUnit.health)
end

function PetSpot:tryLevelUp()
	local petData = self.petData
	if not petData then
		warn("NO PET DATA TO LEVEL UP: ", self.petSpotName)
		return
	end

	local maxLevel = PetInfo:getMaxLevel(self.petStats["rating"])
	if petData["level"] >= maxLevel then
		self.user:notifyError("Already max level!")
		return
	end

	local price = PetInfo:calculateLevelUpPrice(petData)
	local coinsCount = self.user.home.itemStash:getItemCount({
		itemName = "Coins",
	})

	if coinsCount < price then
		self.user:notifyError("Not enough coins!")
		return
	end

	petData["level"] += 1

	self.user.home.itemStash:updateItemCount({
		itemName = "Coins",
		count = -price,
	})

	self:refreshAttackSpeedRatio()

	self:sendData()
end

function PetSpot:sync(otherUser)
	ServerMod:FireClient(otherUser.player, "newPetSpot", {
		petSpotName = self.petSpotName,
		index = self.index,

		petData = self.petData,

		userName = self.user.name,

		unlocked = self.unlocked,
	})
end

function PetSpot:occupyWithPet(petData)
	self.petData = petData

	if self.petData then
		for k, v in pairs(self.petData) do
			self[k] = v
		end
		self.petStats = PetInfo:getMeta(self.petClass)
	end

	self:refreshAttackSpeedRatio()

	print("OCCUPYING PET SPOT: ", self.petSpotName, self.petData)

	self:sendData()
end

function PetSpot:tryCollectCoins()
	if not self.petData then
		return
	end

	local coinsCount = self.petData["totalCoins"]

	self.user.home.itemStash:updateItemCount({
		itemName = "Coins",
		count = coinsCount,
	})
	self.petData["totalCoins"] = 0

	self:sendCoinsData()
end

function PetSpot:sendCoinsData()
	ServerMod:FireClient(self.user.player, "updatePetSpotCoins", {
		petSpotName = self.petSpotName,

		totalCoins = self.petData["totalCoins"],
		totalOfflineCoins = self.petData["totalOfflineCoins"],
	})
end

function PetSpot:sendData()
	ServerMod:FireClient(self.user.player, "updatePetSpot", {
		petSpotName = self.petSpotName,
		petData = self.petData,

		attackSpeedRatio = self.attackSpeedRatio,
	})
end

function PetSpot:clearPet()
	self.petData = nil

	self:refreshAttackSpeedRatio()

	self:sendData()
end

function PetSpot:getSaveData()
	local petData = self.petData
	if not petData then
		return nil
	end

	return petData
end

function PetSpot:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	for _, event in pairs(self.eventsList) do
		event:Destroy()
	end
	self.eventsList = {}

	if self.model then
		self.model:Destroy()
		self.model = nil
	end

	self:showBuyModel()

	self.petData = nil

	self.owner.petSpots[self.petSpotName] = nil

	ServerMod:FireAllClients("removePetSpot", {
		petSpotName = self.petSpotName,
	})
end

return PetSpot
