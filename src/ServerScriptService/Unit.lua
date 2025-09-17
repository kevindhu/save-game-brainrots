local ServerMod = require(script.Parent.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local UnitInfo = require(game.ReplicatedStorage.UnitInfo)
local MapInfo = require(game.ReplicatedStorage.MapInfo)

local TOGGLE_TEST_TORSO = false
local TICK_DELAY_COUNT = 6

local Unit = {}
Unit.__index = Unit

function Unit.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.moveTimeRatio = 0

	u.inSafeZone = true

	setmetatable(u, Unit)
	return u
end

function Unit:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end
	self.user = self.owner.user

	self.unitStats = UnitInfo:getMeta(self.unitClass)

	self.baseMoveSpeed = self.unitStats["moveSpeed"]

	self.baseRig = game.ReplicatedStorage.Assets[self.unitClass]

	self.health = self.unitStats["health"]
	self.maxHealth = self.unitStats["health"]

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

	routine(function()
		for _, otherUser in pairs(ServerMod.users) do
			self:sync(otherUser)
		end

		self:updateActionMod({
			actionClass = "WalkToSavePart",
		})

		self.initialized = true
	end)
end

function Unit:updateHealth(delta, attacker, totalDelay)
	self.health += delta

	-- print("!! UNIT HEALTH: ", self.unitName, self.health)

	if self.health <= 0 then
		self:die(totalDelay)
	end
end

function Unit:die(totalDelay)
	if self.dead then
		return
	end
	self.dead = true

	routine(function()
		wait(totalDelay)
		self:destroy({
			waitTimer = 1,
		})

		local waveMod = self.waveMod
		self.user.home.saveManager:killUnitFromWave(waveMod, self)
	end)
end

function Unit:sync(otherUser)
	ServerMod:FireClient(otherUser.player, "newUnit", {
		unitName = self.unitName,
		unitClass = self.unitClass,

		firstFrame = self.firstFrame,
		currFrame = self.currFrame,

		baseMoveSpeed = self.baseMoveSpeed,

		userName = self.user.name,
		plotName = self.user.home.plotManager.plotName,
	})
end

function Unit:tick(timeRatio)
	if not self.initialized then
		return
	end
	if self.capturedSavedPet or self.destroyed or self.dead then
		return
	end

	self:tickCurrFrame(timeRatio)
	self:tickCurrAction()
end

function Unit:tickCurrAction()
	local actionMod = self.actionMod
	local actionClass = actionMod.actionClass

	if actionClass == "WalkToSavePart" then
		if self.isStationary then
			self:captureSavedPet()
		end
	end
end

function Unit:captureSavedPet()
	if self.capturedSavedPet then
		return
	end
	self.capturedSavedPet = true

	local waveMod = self.waveMod

	self.user.home.saveManager:failWaveMod(waveMod, self)

	routine(function()
		wait(5)
		self:destroyImmediately()
	end)
end

function Unit:destroyImmediately()
	-- print("!! DESTROYING UNIT: ", self.unitName)
	self:destroy({
		waitTimer = 0,
		noRagdoll = true,
	})
end

function Unit:updateActionMod(actionData)
	self.actionMod = actionData

	-- reset stationary flag
	self.isStationary = nil

	ServerMod:FireAllClients("updateUnitAction", {
		unitName = self.unitName,
		currFrame = self.currFrame,

		actionMod = self.actionMod,
	})
end

function Unit:startAction(actionClass)
	local actionMod = self.actionMod
	actionMod.actionClass = actionClass
end

function Unit:getGoalFrame()
	local actionMod = self.actionMod
	local actionClass = actionMod.actionClass

	if actionClass == "WalkToSavePart" then
		return self.user.home.plotManager.saveModel.BasePart.CFrame
	else
		warn("!!! NO ACTION CLASS: ", actionClass)
	end
end

function Unit:getAttackUnitPos(unit)
	local currPos = self.currFrame.Position
	local unitPos = unit.currFrame.Position

	local moveDir = (unitPos - currPos).Unit

	local attackPos = unitPos - moveDir * (self.attackRange + unit.unitStats.attackRadius)

	return attackPos
end

function Unit:tickCurrFrame(timeRatio)
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

	self:checkSafeZone()

	local changeDist = Common.getHorizontalDist(currFrame.Position, goalFrame.Position)
	local isStationary = changeDist <= 0.8
	self.isStationary = isStationary

	if self.torso then
		self.torso.CFrame = newFrame * CFrame.new(0, self.torso.Size.Y * 0.5, 0)
	end

	-- reset the moveTimeRatio
	self.moveTimeRatio = 0
end

function Unit:checkSafeZone()
	local safeZone = self.user.home.plotManager.safeZone

	local currPosition = self.currFrame.Position
	local rayOrigin = Vector3.new(currPosition.X, safeZone.Position.Y + 10, currPosition.Z)
	local rayDirection = Vector3.new(0, -20, 0)
	local ray = Ray.new(rayOrigin, rayDirection)

	local whiteList = {
		safeZone,
	}
	local hitPart, hitPosition = workspace:FindPartOnRayWithWhitelist(ray, whiteList)
	if not hitPart then
		self.inSafeZone = false
		return
	end

	self.inSafeZone = true
end

function Unit:calculateNewAngle(currFrame, goalFrame, timeRatio)
	local newAngle = CFrame.Angles(0, 0, 0)
	return newAngle
end

-- Calculate the new position based on current movement logic
function Unit:calculateNewPos(currFrame, goalFrame, timeRatio)
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

function Unit:applyTerrainFollowing(newPos, timeRatio)
	local yValue = game.Workspace.Map1.MainFloorPart.Position.Y
	local yStartPos = Vector3.new(newPos.X, yValue, newPos.Z)
	local hasFloor, goalYPos = self:getFloorPos(yStartPos)
	self.hasFloor = hasFloor

	local yLerpRatio = 0.2
	return newPos:Lerp(goalYPos, yLerpRatio * timeRatio)
end

function Unit:getFloorPos(topPos)
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

function Unit:destroy(data)
	if self.destroyed then
		-- warn("ALREADY DESTROYED UNIT HUH: ", self.name)
		return
	end
	self.destroyed = true

	if self.torso then
		self.torso:Destroy()
	end

	self.owner.units[self.unitName] = nil

	ServerMod:FireAllClients("removeUnit", {
		unitName = self.unitName,
		waitTimer = data["waitTimer"] or 1,
		noRagdoll = data["noRagdoll"],
	})
end

return Unit
