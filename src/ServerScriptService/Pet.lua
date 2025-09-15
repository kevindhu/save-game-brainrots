local ServerMod = require(script.Parent.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetInfo = require(game.ReplicatedStorage.PetInfo)
local MapInfo = require(game.ReplicatedStorage.MapInfo)
local RatingInfo = require(game.ReplicatedStorage.RatingInfo)

local TOGGLE_TEST_TORSO = false
local TICK_DELAY_COUNT = 6

local Pet = {}
Pet.__index = Pet

function Pet.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.moveTimeRatio = 0

	u.attackSpeedRatio = 1 -- 2.5

	u.totalOfflineCoins = 0

	u.leaveTimestamp = os.time()

	u.eventsList = {}

	setmetatable(u, Pet)
	return u
end

function Pet:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end
	self.user = self.owner.user

	self.petStats = PetInfo:getMeta(self.petClass)

	self.rating = self.petStats["rating"]

	self.baseMoveSpeed = 0.25
	self.attackRange = PetInfo.attackRangeMap[self.petClass] or 2

	self.baseRig = game.ReplicatedStorage.Assets[self.petClass]

	if TOGGLE_TEST_TORSO then
		local torso = Instance.new("Part")
		torso.Size = Vector3.new(1, 30, 1)
		torso.Color = Color3.fromRGB(91, 229, 107)
		torso.Anchored = true
		torso.CanCollide = false
		torso.Parent = game.Workspace.HitBoxes
		self.torso = torso
	end

	self.currFrame = self.firstFrame

	self:initAllEvents()

	routine(function()
		wait(self.hatchDelayTimer)

		for _, otherUser in pairs(ServerMod.users) do
			self:sync(otherUser)
		end

		self.initialized = true
	end)

	routine(function()
		wait(1)
		self:calculateOfflineCoins()
	end)
end

function Pet:initAllEvents()
	self:createEvent("exp", "EXP")
	self:createEvent("attack", "ATTACK")
end

function Pet:createEvent(key, alias)
	local event = Instance.new("RemoteEvent")
	event.Name = self.petName .. "_" .. alias .. "EVENT"
	event.Parent = game.ReplicatedStorage.PetEvents
	self[key .. "Event"] = event
	table.insert(self.eventsList, event)
end

local OFFLINE_DEBUFF = 0.01

function Pet:calculateOfflineCoins()
	local leaveTimestamp = self.leaveTimestamp
	if not leaveTimestamp then
		return
	end

	-- cap at 5 days
	local totalSeconds = os.time() - leaveTimestamp
	totalSeconds = math.min(totalSeconds, 60 * 60 * 24 * 5)

	local damage = self.petStats["damage"] or 10

	-- get average gem multiplier
	local totalMultiplier = 0
	for _, gem in pairs(self.user.home.gemManager.gems) do
		if gem.destroyed then
			continue
		end
		local gemStats = gem.gemStats
		local gemMultiplier = gemStats["coinMultiplier"] or 1
		totalMultiplier += gemMultiplier
	end

	local averageMultiplier = totalMultiplier / len(self.user.home.gemManager.gems)

	local coinsEarned = damage * averageMultiplier * totalSeconds * OFFLINE_DEBUFF

	self.totalOfflineCoins += coinsEarned

	-- causes offline prompt to open (exactly like build a zoo)
	-- can only collect this if over an hour
end

function Pet:sync(otherUser)
	ServerMod:FireClient(otherUser.player, "newPet", {
		petName = self.petName,
		petClass = self.petClass,

		firstFrame = self.firstFrame,
		currFrame = self.currFrame,

		baseMoveSpeed = self.baseMoveSpeed,

		attackRange = self.attackRange,

		userName = self.user.name,
		plotName = self.user.home.plotManager.plotName,

		hatchDelayTimer = self.hatchDelayTimer,

		attackSpeedRatio = self.attackSpeedRatio,

		exp = self.exp,
		level = self.level,

		baseWeight = self.baseWeight,

		-- unit metadata
		creationTimestamp = self.creationTimestamp,
		mutationClass = self.mutationClass,
		variationScale = self.variationScale,
	})
end

function Pet:tick(timeRatio)
	if not self.initialized then
		return
	end

	self:tickCurrFrame(timeRatio)
	self:tickCurrAction()
end

function Pet:tickCurrAction()
	local actionMod = self.actionMod
	if not actionMod then
		self:findRandomGem()
		return
	end

	local actionClass = actionMod.actionClass

	if actionClass == "WalkToGem" then
		local gemName = self.actionMod["gemName"]
		local gem = self.user.home.gemManager.gems[gemName]
		if not gem or gem.destroyed then
			self:findRandomGem()
			return
		end
		if not self.isStationary then
			return
		end

		-- arrived at gem
		self:updateActionMod({
			actionClass = "HitGem",
			gemName = self.actionMod["gemName"],
		})
	elseif actionClass == "HitGem" then
		self:tryAttackGem()
	end
end

local ATTACK_TIMER = 1.2

function Pet:tryAttackGem()
	local gemName = self.actionMod["gemName"]
	local gem = self.user.home.gemManager.gems[gemName]
	if not gem or gem.destroyed then
		if not self.startNewActionExpiree then
			self.startNewActionExpiree = ServerMod.step + 60 * 0.7 -- 0.2
			return
		end
		if self.startNewActionExpiree > ServerMod.step then
			return
		end
		self.startNewActionExpiree = nil

		self:findRandomGem()
		return
	end

	if self.attackExpiree and self.attackExpiree > ServerMod.step then
		return
	end

	local attackTimer = ATTACK_TIMER / self.attackSpeedRatio
	self.attackExpiree = ServerMod.step + 60 * attackTimer -- 0.5

	local baseDamage = self.petStats["attackDamage"] or 10
	local damage = math.random(baseDamage * 0.8, baseDamage * 1.2)

	gem:updateHealth(-damage, self)

	self.user.home.damageManager:addDamage(damage)

	local gemCoinMultiplier = gem.gemStats["coinMultiplier"] or 1
	local petCoinMultiplier = self.petStats["coinMultiplier"] or 1
	local coinsEarned = math.floor(damage * gemCoinMultiplier * petCoinMultiplier)

	-- zone multiplier
	local zoneCoinMultiplier = self.user.home.zoneManager:getCoinMultiplier()
	coinsEarned = coinsEarned * zoneCoinMultiplier

	-- level multiplier
	local levelMultiplier = 1 + (self.level - 1) * 0.01
	coinsEarned = coinsEarned * levelMultiplier

	-- friend multiplier
	local friendManager = self.user.home.friendManager
	local friendStrengthBoost = 1 + (friendManager.friendCount * 0.1)
	coinsEarned = coinsEarned * friendStrengthBoost

	routine(function()
		local totalDelay = 0.3 + (self.petStats["attackDelay"] or 0)
		totalDelay = totalDelay / self.attackSpeedRatio

		wait(totalDelay)

		-- TODO: modify this exp based on other stats
		local expEarned = damage
		self:updateExp(expEarned)
	end)

	self.attackEvent:FireAllClients(gemName, damage, gem.health)

	routine(function()
		wait(0.3)
		self.user.home.itemStash:updateItemCount({
			itemName = "Coins",
			count = coinsEarned,
		})
	end)
end

function Pet:findRandomGem()
	local gemManager = self.user.home.gemManager
	local gem = gemManager:getClosestUnoccupiedGem(self)
	if not gem then
		return
	end

	self:updateActionMod({
		actionClass = "WalkToGem",
		gemName = gem.gemName,
	})
end

function Pet:updateActionMod(actionData)
	self.actionMod = actionData

	-- reset stationary flag
	self.isStationary = nil

	ServerMod:FireAllClients("updatePetAction", {
		petName = self.petName,
		currFrame = self.currFrame,

		actionMod = self.actionMod,
	})
end

function Pet:startAction(actionClass)
	local actionMod = self.actionMod
	actionMod.actionClass = actionClass
end

function Pet:getGoalFrame()
	local actionMod = self.actionMod
	local actionClass = actionMod.actionClass

	local gemManager = self.user.home.gemManager

	local gem = nil
	if self.actionMod then
		local gemName = self.actionMod["gemName"]
		gem = gemManager.gems[gemName]
	end

	if actionClass == "WalkToGem" then
		if not gem or gem.destroyed then
			return self.currFrame
		end
		return CFrame.new(self:getAttackGemPos(gem))
	elseif actionClass == "HitGem" then
		return self.currFrame
	end
end

function Pet:getAttackGemPos(gem)
	local currPos = self.currFrame.Position
	local gemPos = gem.currFrame.Position

	local moveDir = (gemPos - currPos).Unit

	local attackPos = gemPos - moveDir * (self.attackRange + gem.gemStats.attackRadius)

	return attackPos
end

function Pet:tickCurrFrame(timeRatio)
	if not self.actionMod then
		return
	end

	self.moveTimeRatio += timeRatio
	if self.moveExpiree and self.moveExpiree > ServerMod.step then
		return
	end
	self.moveExpiree = ServerMod.step + TICK_DELAY_COUNT

	local currFrame = self.currFrame
	local goalFrame = self:getGoalFrame()

	local moveTimeRatio = self.moveTimeRatio

	local newPos = self:calculateNewPos(currFrame, goalFrame, moveTimeRatio)
	local newAngle = self:calculateNewAngle(currFrame, goalFrame, moveTimeRatio)

	local newFrame = CFrame.new(newPos) * newAngle
	self.currFrame = newFrame

	local changeDist = Common.getHorizontalDist(currFrame.Position, goalFrame.Position)
	local isStationary = changeDist <= 0.8
	self.isStationary = isStationary

	if self.torso then
		self.torso.CFrame = newFrame * CFrame.new(0, self.torso.Size.Y * 0.5, 0)
	end

	-- reset the moveTimeRatio
	self.moveTimeRatio = 0
end

function Pet:calculateNewAngle(currFrame, goalFrame, timeRatio)
	local newAngle = CFrame.Angles(0, 0, 0)
	return newAngle
end

-- Calculate the new position based on current movement logic
function Pet:calculateNewPos(currFrame, goalFrame, timeRatio)
	local currPos = currFrame.Position
	local goalPos = goalFrame.Position

	goalPos = Vector3.new(goalPos.X, currPos.Y, goalPos.Z)

	local goalDist = Common.getHorizontalDist(currPos, goalPos)
	if goalDist < 0.1 then
		return currPos
	end

	local travelSpeed = self.baseMoveSpeed * timeRatio
	travelSpeed = math.min(travelSpeed, goalDist)

	local newPos = currPos + (goalPos - currPos).Unit * travelSpeed

	-- reset the y value (will be handled by terrain following)
	newPos = Vector3.new(newPos.X, currPos.Y, newPos.Z)

	-- Apply terrain following to adjust Y position
	newPos = self:applyTerrainFollowing(newPos, timeRatio)

	return newPos
end

function Pet:applyTerrainFollowing(newPos, timeRatio)
	local yValue = game.Workspace.Map1.MainFloorPart.Position.Y
	local yStartPos = Vector3.new(newPos.X, yValue, newPos.Z)
	local hasFloor, goalYPos = self:getFloorPos(yStartPos)
	self.hasFloor = hasFloor

	local yLerpRatio = 0.2
	return newPos:Lerp(goalYPos, yLerpRatio * timeRatio)
end

function Pet:getFloorPos(topPos)
	local rayOrigin = Vector3.new(topPos.X, topPos.Y + 20, topPos.Z)
	local rayDirection = Vector3.new(0, -40, 0)
	local ray = Ray.new(rayOrigin, rayDirection)

	local whiteList = MapInfo:getLandWhiteList()
	local hitPart, hitPosition = workspace:FindPartOnRayWithWhitelist(ray, whiteList)
	if not hitPart then
		return false, Vector3.new(topPos.X, -40, topPos.Z)
	end

	return true, hitPosition
end

function Pet:updateExp(count)
	self.exp += count

	self:tryLevelUp()

	self.expEvent:FireAllClients(self.exp, self.level)
end

function Pet:tryLevelUp()
	local levelExpCap = PetInfo:calculateLevelExpCap(self.level, self.rating)
	if levelExpCap > self.exp then
		return
	end

	local maxLevel = RatingInfo.ratingMaxLevelMap[self.rating]
	if self.level >= maxLevel then
		warn("PET MAX LEVEL: ", self.petName, self.level, maxLevel)
		return
	end

	self.exp -= levelExpCap
	self.level += 1

	-- print("LEVELED UP TO: ", self.level, self.petName)

	self:tryLevelUp()
end

function Pet:getSaveData()
	local baseFrame = self.user.home.plotManager.plotBaseFrame:inverse() * self.firstFrame
	local firstFrameComp = { baseFrame:GetComponents() }

	local saveData = {
		petName = self.petName,
		petClass = self.petClass,
		firstFrameComp = firstFrameComp,

		leaveTimestamp = os.time(),

		-- unit metadata
		creationTimestamp = self.creationTimestamp,
		mutationClass = self.mutationClass,

		baseWeight = self.baseWeight,

		level = self.level,
		exp = self.exp,

		favorited = self.favorited,
	}

	return saveData
end

function Pet:destroy()
	if self.destroyed then
		warn("ALREADY DESTROYED USER HUH: ", self.name)
		return
	end
	self.destroyed = true

	if self.torso then
		self.torso:Destroy()
	end

	for _, event in pairs(self.eventsList) do
		event:Destroy()
	end
	self.eventsList = {}

	self.owner.pets[self.petName] = nil

	ServerMod:FireAllClients("removePet", {
		petName = self.petName,
	})
end

return Pet
