local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local TOGGLE_TEST_TORSO = false

local PetInfo = require(game.ReplicatedStorage.PetInfo)
local UnitInfo = require(game.ReplicatedStorage.UnitInfo)
local MapInfo = require(game.ReplicatedStorage.MapInfo)

local Unit = {}
Unit.__index = Unit

function Unit.new(data)
	local u = {}
	u.data = data

	setmetatable(u, Unit)
	return u
end

function Unit:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end

	local unitStats = UnitInfo:getMeta(self.unitClass)
	self.unitStats = unitStats

	self.rating = unitStats["rating"]

	if TOGGLE_TEST_TORSO then
		local torso = Instance.new("Part")
		torso.Size = Vector3.new(1, 20, 1)
		torso.Color = Color3.fromRGB(255, 0, 0)
		torso.Transparency = 0.2
		torso.Anchored = true
		torso.CanCollide = false
		torso.Parent = game.Workspace.HitBoxes
		self.torso = torso
	end

	self:initRig()
end

function Unit:updateActionFromServer(data)
	self.actionMod = data.actionMod

	local serverCurrFrame = data.currFrame

	local currFrame = self.currFrame
	if (currFrame.Position - serverCurrFrame.Position).Magnitude > 10 then
		warn("!!! UNIT FRAME MISMATCH: ", self.unitName, currFrame.Position, serverCurrFrame.Position)
		self.currFrame = serverCurrFrame
	end

	-- self.currFrame = serverCurrFrame
	-- self:updateRigFrame(serverCurrFrame)
end

function Unit:initEventReceiver(key, alias, callback)
	local unitEvents = game.ReplicatedStorage:WaitForChild("UnitEvents", 5)

	local event = unitEvents:WaitForChild(self.unitName .. "_" .. alias .. "EVENT", 5)
	if not event then
		warn("NO EVENT FOUND FOR UNIT: ", self.unitName, key, alias)
		return
	end
	self[key .. "Event"] = event

	event.OnClientEvent:Connect(callback)
end

function Unit:initRig()
	local baseRig = game.ReplicatedStorage.Assets[self.unitClass]
	if not baseRig.PrimaryPart then
		baseRig.PrimaryPart = baseRig:FindFirstChild("HumanoidRootPart")
	end

	self.baseRigScale = baseRig:GetScale()

	local rig = baseRig:Clone()
	rig.PrimaryPart.Transparency = 1 -- 0.5

	self.rig = rig

	rig.Parent = game.Workspace.UnitRigs

	Common.setCollisionGroup(rig, "Units")

	Common.weldPartsToRig(rig)

	self.humanoid = rig:WaitForChild("Humanoid", 2)

	self.humanoid.MaxHealth = self.unitStats["health"]
	self.humanoid.Health = self.unitStats["health"]

	self.humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	self.humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
	self.humanoid.DisplayName = self.unitStats["alias"]

	self.humanoid.EvaluateStateMachine = false
	self.humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	rig:SetAttribute("unitName", self.unitName)

	self.rootPart = rig:WaitForChild("HumanoidRootPart", 2)
	if not self.rootPart then
		warn("!! NO ROOT PART FOUND FOR UNIT: ", self.unitName, self.unitClass)
	end

	for _, part in pairs(rig:GetDescendants()) do
		if part:IsA("BasePart") and part ~= self.rootPart then
			part.Anchored = false
			part.CanQuery = true
		end
	end

	self:updateRigFrame(self.currFrame)
	self:refreshRigScale()

	local outerShell = Instance.new("Model")
	rig.Parent = outerShell

	local fakeHumanoid = Instance.new("Humanoid")
	fakeHumanoid.Parent = outerShell
	fakeHumanoid.EvaluateStateMachine = false

	outerShell:SetAttribute("unitName", self.unitName)
	outerShell.Parent = game.Workspace.UnitRigs
	self.outerShell = outerShell

	ClientMod.ragdollManager:setupJoints(rig)

	-- print("!! INIT RIG FOR UNIT: ", self.unitName)
end

function Unit:refreshRigScale()
	if not self.rig then
		return
	end
	local realScale = 1
	self.rig:ScaleTo(self.baseRigScale * realScale)
end

function Unit:updateRigFrame(newCurrFrame)
	local rig = self.rig
	if not rig then
		return
	end

	local rigFrame = self:getRigFrame(newCurrFrame)
	self.rigFrame = rigFrame

	-- rig:SetPrimaryPartCFrame(rigFrame)
end

function Unit:getRigFrame(newCurrFrame)
	local rootPart = self.rootPart

	local hOffset = rootPart.Size.Y * 1.5
	return newCurrFrame * CFrame.new(0, hOffset, 0)
end

function Unit:updateData(data)
	-- do nothing
end

function Unit:tickRender(timeRatio)
	if self.destroyed then
		return
	end

	self:tickCurrFrame(timeRatio)
	self:tickCurrAction(timeRatio)
end

function Unit:tickCurrAction(timeRatio)
	if not self.actionMod then
		return
	end

	-- TODO: basic logic
end

function Unit:getGoalFrame()
	local actionMod = self.actionMod
	local actionClass = actionMod.actionClass

	if actionClass == "WalkToSavePart" then
		local plotMod = ClientMod.plotManager.plotMods[self.plotName]

		local currFrame = self.currFrame
		local currPos = currFrame.Position

		local savePart = plotMod.saveModel.BasePart
		local savePos = Vector3.new(savePart.Position.X, currPos.Y, savePart.Position.Z)

		local goalAngle = Common.getCAngle(self.currFrame)
		if (currPos - savePos).Magnitude > 0.1 then
			goalAngle = Common.getCAngle(CFrame.new(currPos, savePos))
		end

		return CFrame.new(savePos) * goalAngle
	elseif actionClass == "WalkToRunawayPart" then
		return actionMod["goalFrame"]
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

	local currFrame = self.currFrame
	local goalFrame = self:getGoalFrame()

	-- Calculate position movement
	local newPos = self:calculateNewPos(currFrame, goalFrame, timeRatio)
	local newAngle = self:calculateNewAngle(currFrame, goalFrame, timeRatio)

	local changeDist = Common.getHorizontalDist(currFrame.p, goalFrame.p)
	local isStationary = changeDist <= 0.8

	-- Check if unit is stationary and update animation state if needed
	self:setStationary(isStationary)

	-- Combine position and rotation into final frame
	local newFrame = CFrame.new(newPos) * newAngle
	self.currFrame = newFrame

	if TOGGLE_TEST_TORSO then
		self.torso.CFrame = newFrame * CFrame.new(0, self.torso.Size.Y * 0.5, 0)
	end

	-- Update model position
	self:updateRigFrame(newFrame)
end

-- Calculate the new position based on current movement logic
function Unit:calculateNewPos(currFrame, goalFrame, timeRatio)
	local currPos = currFrame.p
	local goalPos = goalFrame.p

	goalPos = Vector3.new(goalPos.X, currPos.Y, goalPos.Z)

	local goalDist = Common.getHorizontalDist(currPos, goalPos)
	if goalDist < 0.1 then
		return currPos
	end

	local travelSpeed = self.baseMoveSpeed * timeRatio * ClientMod.speedManager:getSpeed(self.userName)
	travelSpeed = math.min(travelSpeed, goalDist)

	local newPos = currPos + (goalPos - currPos).Unit * travelSpeed

	-- reset the y value (will be handled by terrain following)
	newPos = Vector3.new(newPos.X, currPos.Y, newPos.Z)

	-- Apply terrain following for Y position
	newPos = self:applyTerrainFollowing(newPos, timeRatio)

	return newPos
end

function Unit:calculateNewAngle(currFrame, goalFrame, timeRatio)
	local currPos = currFrame.p
	local goalPos = goalFrame.p
	goalPos = Vector3.new(goalPos.X, currPos.Y, goalPos.Z)

	-- local goalDist = Common.getHorizontalDist(currPos, goalPos)
	-- if goalDist < 0.1 then
	-- 	return Common.getCAngle(currFrame)
	-- end
	-- local goalAngle = CFrame.new(Vector3.new(), goalPos - currPos)

	local goalAngle = Common.getCAngle(goalFrame)

	local currAngle = Common.getCAngle(currFrame)

	local lerpRatio = 0.15 -- 0.1
	local newAngle = currAngle:Lerp(goalAngle, timeRatio * lerpRatio)

	return newAngle
end

function Unit:applyTerrainFollowing(newPos, timeRatio)
	local mainFloorPart = game.Workspace:WaitForChild("Map1"):WaitForChild("MainFloorPart")
	local yValue = mainFloorPart.Position.Y
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

function Unit:addDamageFromServer(data)
	local damage = data["damage"]
	local newHealth = data["newHealth"]

	self:animateHit({
		damage = damage,
		damagePos = self.currFrame.Position,
		hitPos = self.currFrame.Position,
		newHealth = newHealth,
	})
end

function Unit:animateHit(data)
	local damagePos = data["damagePos"]
	local hitPos = data["hitPos"]
	local newHealth = data["newHealth"]
	local damage = data["damage"]

	if self.userName == player.Name then
		ClientMod.damageManager:addDamageHit({
			pos = damagePos + Vector3.new(0, 3, 0),
			damage = damage,
		})
	end

	ClientMod.soundManager:newSoundMod({
		soundClass = "PetHit" .. math.random(1, 5),
		pos = damagePos,
		volume = 0.1, -- 0.025
	})

	ClientMod.spellManager:addExplosion({
		spellClass = "RockHit",
		pos = hitPos,
		scale = 2.2, -- 1.5
	})

	local humanoid = self.humanoid
	humanoid.Health = newHealth

	-- print("ANIMATE HIT: ", newHealth, humanoid.MaxHealth)
end

-- Check if unit is stationary and update animation state
function Unit:setStationary(newBool)
	-- Only update animation state if it changed
	if self.isStationary == newBool then
		return
	end
	self.isStationary = newBool

	local unitClass = self.unitClass

	if newBool then
		local animationId = UnitInfo.animationMap["idle"]
		local trackMod = ClientMod.animUtils:animate(self, {
			race = "Movement",
			animationId = animationId,
		})
		if trackMod then
			trackMod["track"]:AdjustSpeed(ClientMod.speedManager:getSpeed(self.userName))
		end
		self.moveTrackMod = nil
	else
		local user = ClientMod.users[self.userName]
		if not user then
			return
		end

		local animationId = UnitInfo.animationMap["run"]

		-- TODO: change this based on speed
		local speedRatio = 1

		local moveTrackMod = ClientMod.animUtils:animate(self, {
			race = "Movement",
			animationId = animationId,
			speedRatio = speedRatio, --user.humanoid.WalkSpeed / 20,
		})
		if moveTrackMod then
			moveTrackMod["track"]:AdjustSpeed(ClientMod.speedManager:getSpeed(self.userName))
		end
		self.moveTrackMod = moveTrackMod
	end
end

function Unit:destroyRig()
	if self.capturedBB then
		self.capturedBB:Destroy()
		self.capturedBB = nil
	end
	if self.capturedPetRig then
		self.capturedPetRig:Destroy()
		self.capturedPetRig = nil
	end

	if self.rig then
		self.rig:Destroy()
	end

	if self.outerShell then
		self.outerShell:Destroy()
	end

	-- clear all animation tracks
	self.trackMods = {}
	self.raceTrackMods = {}
	self.animationGroupIndexMap = nil
end

function Unit:destroy(data)
	local noRagdoll = data["noRagdoll"]
	local waitTimer = data["waitTimer"] or 1

	if self.destroyed then
		return
	end
	self.destroyed = true

	local rig = self.rig
	if rig then
		ClientMod.ragdollManager:ragdollRig(rig, true)
	end

	routine(function()
		if noRagdoll then
			self:destroyRig()
		else
			wait(1.5)
			for _, child in pairs(rig:GetDescendants()) do
				if child:IsA("BasePart") then
					ClientMod.tweenManager:createTween({
						target = child,
						timer = 0.5,
						easingStyle = "Linear",
						easingDirection = "Out",
						goal = {
							Transparency = 1,
						},
					})
				elseif child:IsA("Decal") then
					ClientMod.tweenManager:createTween({
						target = child,
						timer = 0.5,
						easingStyle = "Linear",
						easingDirection = "Out",
						goal = {
							Transparency = 1,
						},
					})
				end
			end

			wait(2)
			self:destroyRig()
		end
	end)

	routine(function()
		wait(waitTimer)
		ClientMod.units[self.unitName] = nil
	end)
end

function Unit:addCapturedPetRig(petData)
	local petClass = petData["petClass"]
	local mutationClass = petData["mutationClass"]

	local head = self.rig.Torso

	local fakeRig = game.ReplicatedStorage.Assets[petClass]:Clone()

	PetInfo:refreshPetScale(fakeRig, petData)

	local modelFrame, extentsSize = fakeRig:GetBoundingBox()
	local centerOffset = modelFrame:inverse() * fakeRig.PrimaryPart.CFrame

	fakeRig:Destroy()

	local petRig = ClientMod.weldPetManager:addWeldPetRig({
		petClass = petClass,
		baseWeight = petData["baseWeight"],
		level = petData["level"],
		anchorPart = head,
		anchorOffsetFrame = centerOffset * CFrame.new(0, 0, -3),

		-- mutations
		mutationManager = ClientMod.mutationManager,
		mutationClass = mutationClass,
	})

	petRig.Name = petClass .. "_WELD_RIG"
	petRig.Parent = self.rig

	self:animatePetRig(petRig, petClass)

	local fakeRootPart = petRig:FindFirstChild("RootPart")

	local bb = game.ReplicatedStorage.Assets.CapturedBBPart.BB:Clone()
	bb.Adornee = fakeRootPart:FindFirstChild("BBAttachment")
	bb.Parent = playerGui

	local petStats = PetInfo:getMeta(petClass)

	local mutationTitle = bb.MainFrame.MutationTitle
	ClientMod.mutationManager:applyMutationColor(mutationTitle, mutationClass)

	local rating = petStats["rating"]
	local nameTitle = bb.MainFrame.NameTitle

	nameTitle.Text = petStats["alias"]
	ClientMod.ratingManager:applyRatingColor(nameTitle, rating)

	ClientMod.uiScaleManager:addDistStrokeModsFromBB({
		bb = bb,
		adornee = fakeRootPart,
		baseDistance = 40,
	})

	self.capturedBB = bb
	self.capturedPetRig = petRig
end

function Unit:animatePetRig(petRig, petClass)
	local animationId = PetInfo["idleAnimationMap"][petClass]
	local weldRigEntity = {
		rig = petRig,
	}
	local trackMod = ClientMod.animUtils:animate(weldRigEntity, {
		race = "Idle",
		animationId = animationId,
	})

	if not trackMod then
		return
	end

	trackMod["track"]:Play()
end

function Unit:captureSavePet(data)
	ClientMod.saveManager:removeWaveMod(self.userName)

	local petData = data["petData"]
	self.capturedSavedPet = true

	-- print("!! CAPTURED SAVED PET: ", self.unitName, petData)

	local laughProbMap = {
		["EvilLaugh"] = 5,
		["ClashLaugh"] = 3,
		["JokerLaugh"] = 2,
		["FrogLaugh"] = 2,
	}

	local laughClass = Common.rollFromProbMap(laughProbMap)

	if not Common.isStudio then
		ClientMod.soundManager:newSoundMod({
			soundClass = laughClass,
			pos = self.currFrame.Position,
			playbackSpeed = Common.randomBetween(0.8, 1),
		})
	end

	self.baseMoveSpeed = 0.2

	self:addCapturedPetRig(petData)

	ClientMod.animUtils:animate(self, {
		race = "HoldTool",
		animationClass = "HoldStashTool",
	})

	local plotMod = ClientMod.plotManager.plotMods[self.plotName]
	local baseGoalFrame = plotMod.runawayPart.CFrame * CFrame.Angles(0, math.rad(180), 0)

	local range = 100
	local currFrame = self.currFrame
	local goalFrame = baseGoalFrame * CFrame.new(Common.randomBetween(-range, range), 0, 0)

	local goalPos = goalFrame.Position
	goalPos = Vector3.new(goalPos.X, currFrame.Position.Y, goalPos.Z)
	local finalGoalFrame = CFrame.new(goalPos) * Common.getCAngle(CFrame.new(currFrame.Position, goalPos))

	self.actionMod = {
		actionClass = "WalkToRunawayPart",
		goalFrame = finalGoalFrame,
	}
end

return Unit
