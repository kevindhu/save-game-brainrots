local ServerMod = require(script.Parent.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetInfo = require(game.ReplicatedStorage.PetInfo)
local MutationInfo = require(game.ReplicatedStorage.MutationInfo)

local PetSpot = {}
PetSpot.__index = PetSpot

function PetSpot.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.eventsList = {}

	u.leaveTimestamp = os.time()

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
	self:initRealModel()

	self:initAllEvents()

	for _, otherUser in pairs(ServerMod.users) do
		if not otherUser.initialized then
			continue
		end
		self:sync(otherUser)
	end

	routine(function()
		wait(1)
		self.initialized = true

		-- print("PET SPOT INITIALIZED: ", self.petSpotName, self.unlocked)

		self:occupyWithDevPet()
	end)
end

-- only for testing
function PetSpot:occupyWithDevPet()
	if not self.user.store.noSave then
		return
	end
	if not self.unlocked then
		return
	end

	local petClassList = {
		"CappuccinoAssassino",
		"TungTungSahur",
		"TrippiTroppi",

		"Boneca",
		"LiriLira",
		"Ballerina",
		"FrigoCamelo",
		"ChimpBanana",
		"TaTaTaSahur",
		"CapybaraCoconut",
		"DolphinBanana",
		"FishCatLegs",
		"GooseBomber",
		"TralaleloTralala",
		"GlorboFruttoDrillo",
		"RhinoToast",
		"BrrBrrPatapim",
		"ElephantCoconut",
		"TimCheese",

		"Bombardino",

		"GiraffeWatermelon",
		"MonkeyPineapple",
		"OwlAvocado",
		"OrangeDunDun",
		"CowPlanet",

		"OctopusBlueberry",
		"SaltCombined",
		"GorillaWatermelon",

		"MilkShake",
		"GrapeSquid",
	}
	local randomPetClass = petClassList[math.random(1, #petClassList)]

	local probManager = self.user.home.probManager
	local randomMutationClass = probManager:generateMutationClass()

	local petData = self.user.home.itemStash:generatePetData({
		petClass = randomPetClass,
		mutationClass = randomMutationClass,
	})
	self:occupyWithPet(petData)
end

function PetSpot:initRealModel()
	-- init the real model
	local realModel = game.ReplicatedStorage.Assets.BoughtPetSpotModel:Clone()
	realModel.Name = self.petSpotName

	local buyBasePart = self.buyModel.BasePart
	realModel:PivotTo(
		buyBasePart.CFrame * CFrame.new(0, -buyBasePart.Size.Y * 0.5 + realModel.PrimaryPart.Size.Y * 0.5, 0)
	)
	realModel.Parent = game.Workspace.BoughtPetSpots

	self.realModel = realModel

	self.standPart = realModel:WaitForChild("StandPart")

	self.baseFrame = self.standPart.CFrame
		* CFrame.new(0, self.standPart.Size.Y * 0.5, 0)
		* CFrame.Angles(0, math.rad(180), 0)
	self.currFrame = self.baseFrame

	self:toggleRealModel(false)
end

local OFFLINE_DEBUFF = 0.01

function PetSpot:refreshTotalOfflineCoins(leaveTimestamp)
	self.leaveTimestamp = leaveTimestamp

	local totalSeconds = os.time() - leaveTimestamp

	-- cap at 3 days
	totalSeconds = math.min(totalSeconds, 60 * 60 * 24 * 3)

	local coinsPerSecond = self:getTotalCoinsPerSecond()

	self.petData["totalOfflineCoins"] += math.ceil(totalSeconds * coinsPerSecond * OFFLINE_DEBUFF)
end

function PetSpot:getTotalCoinsPerSecond()
	local coinsPerSecond = self.petStats["coinsPerSecond"]

	-- local rebirthManager = self.user.home.rebirthManager
	-- coinsPerSecond = coinsPerSecond * rebirthManager.rebirthCoinsMultiplier

	-- local indexManager = self.user.home.indexManager
	-- coinsPerSecond = coinsPerSecond * indexManager.coinsMultiplier

	if self.user.home.shopManager:checkOwnsGamepass("2xCoins") then
		coinsPerSecond = coinsPerSecond * 2
	end

	local relicMods = self.petData["relicMods"]

	local relicCoinsMultiplier = 1
	for _, relicData in pairs(relicMods) do
		relicCoinsMultiplier = relicCoinsMultiplier + (relicData["coins"] - 1)
	end
	coinsPerSecond = coinsPerSecond * relicCoinsMultiplier

	print("GOT RELIC COINS MULTIPLIER: ", relicCoinsMultiplier)

	coinsPerSecond = math.floor(coinsPerSecond)

	return coinsPerSecond
end

function PetSpot:refreshAttackSpeedRatio()
	if not self.petData then
		self.attackSpeedRatio = 1
		return
	end

	local level = self.petData["level"]

	local levelIncrement = 0.003
	local levelMultiplier = 1 + (level - 1) * levelIncrement
	local attackSpeedRatio = 1 * levelMultiplier

	-- add mutation multiplier
	local mutationMultiplier = 1
	local mutationClass = self.petData["mutationClass"]
	if mutationClass and mutationClass ~= "None" then
		mutationMultiplier = MutationInfo["attackSpeedMultiplierMap"][mutationClass]
	end
	attackSpeedRatio = attackSpeedRatio * mutationMultiplier

	-- add attack speed from relics
	local relicMods = self.petData["relicMods"]
	for _, relicData in pairs(relicMods) do
		local attackSpeedMultiplier = relicData["attackSpeed"]
		attackSpeedRatio = attackSpeedRatio * attackSpeedMultiplier
	end

	self.attackSpeedRatio = attackSpeedRatio

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
	self.unlocked = true

	self:toggleBuyModel(false)
	self:toggleRealModel(true)

	ServerMod:FireAllClients("unlockPetSpot", {
		petSpotName = self.petSpotName,
	})
end

function PetSpot:addRelicMod(relicData)
	local petData = self.petData
	petData["relicMods"][relicData["relicName"]] = relicData

	self:refreshAttackSpeedRatio()
	self:sendData()
end

function PetSpot:storeRelic()
	local petData = self.petData
	local relicMods = petData["relicMods"]

	if len(relicMods) == 0 then
		-- warn("NO RELIC MODS TO STORE: ", self.petSpotName)
		return
	end

	for _, relicData in pairs(relicMods) do
		local newItemMod = Common.deepCopy(relicData)
		newItemMod["noSend"] = false
		newItemMod["forceBottom"] = true
		newItemMod["noClick"] = false

		print("STORING RELIC: ", newItemMod)

		self.user.home.itemStash:addItemMod(newItemMod)
	end
	petData["relicMods"] = {}

	self:refreshAttackSpeedRatio()
	self:sendData()
end

function PetSpot:toggleRealModel(newBool)
	for _, child in pairs(self.realModel:GetDescendants()) do
		if child:GetAttribute("Transparent") then
			continue
		end

		if child:IsA("BasePart") then
			child.Transparency = newBool and 0 or 1
			child.CanCollide = newBool
			child.CanTouch = newBool
		end
		if child:IsA("SurfaceGui") then
			child.Enabled = false
		end
	end
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

	local coinsCount = self:getTotalCoinsPerSecond()

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

	local attackSpeedRatio = self.attackSpeedRatio * self.user.home.speedManager:getSpeed()
	if self.attackExpiree and self.attackExpiree > ServerMod.step then
		return
	end
	self.attackExpiree = ServerMod.step + 60 * 1 / attackSpeedRatio

	local damage = self.petStats["attackDamage"]

	local level = self.petData["level"]
	local levelMultiplier = 1 + (level - 1) * 0.01

	damage = damage * levelMultiplier

	-- add mutation multiplier
	local mutationMultiplier = 1
	local mutationClass = self.petData["mutationClass"]
	if mutationClass and mutationClass ~= "None" then
		mutationMultiplier = MutationInfo["damageMultiplierMap"][mutationClass]
	end
	damage = damage * mutationMultiplier

	-- add damage from relics
	local relicMods = self.petData["relicMods"]
	for _, relicData in pairs(relicMods) do
		local damageMultiplier = relicData["damage"]
		-- print("RELIC DAMAGE MULTIPLIER: ", damageMultiplier)
		damage = damage * damageMultiplier
	end

	local totalDelay = 0.3 + (self.petStats["attackDelay"] or 0)
	totalDelay = totalDelay / attackSpeedRatio

	targetUnit:updateHealth(-damage, self, totalDelay)

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

		plotName = self.user.home.plotManager.plotName,

		baseFrame = self.baseFrame,
		currFrame = self.currFrame,
	})
end

function PetSpot:occupyWithPet(petData)
	self.petData = petData

	self.petStats = PetInfo:getMeta(self.petData["petClass"])

	self:refreshAttackSpeedRatio()

	-- print("OCCUPYING PET SPOT: ", self.petSpotName, self.petData)

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
	ServerMod:FireAllClients("updatePetSpotCoins", {
		petSpotName = self.petSpotName,

		totalCoins = self.petData["totalCoins"],
		totalOfflineCoins = self.petData["totalOfflineCoins"],
	})
end

function PetSpot:sendData()
	ServerMod:FireAllClients("updatePetSpot", {
		petSpotName = self.petSpotName,
		petData = self.petData,

		attackSpeedRatio = self.attackSpeedRatio,
	})
end

function PetSpot:clearPet()
	-- print("CLEARING PET: ", self.petSpotName)

	self.petData = nil

	self:refreshAttackSpeedRatio()

	self:sendData()
end

function PetSpot:getSaveData()
	return {
		index = self.index,
		unlocked = self.unlocked,
		petData = self.petData,
		leaveTimestamp = os.time(),
	}
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

	-- print("DESTROYING PET SPOT: ", self.petSpotName)

	self:showBuyModel()

	if self.realModel then
		self.realModel:Destroy()
		self.realModel = nil
	end

	self.petData = nil

	self.owner.petSpots[self.petSpotName] = nil

	ServerMod:FireAllClients("removePetSpot", {
		petSpotName = self.petSpotName,
	})
end

return PetSpot
