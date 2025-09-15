local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local TOGGLE_TEST_TORSO = false

local PetInfo = require(game.ReplicatedStorage.PetInfo)
local MapInfo = require(game.ReplicatedStorage.MapInfo)

local Pet = {}
Pet.__index = Pet

function Pet.new(data)
	local u = {}
	u.data = data

	u.foodTimer = 0

	u.partTextureMap = {}

	setmetatable(u, Pet)
	return u
end

function Pet:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end

	local petStats = PetInfo:getMeta(self.petClass)
	self.petStats = petStats

	self.rating = petStats["rating"]

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

	self:initAllEvents()
end

function Pet:initAllEvents()
	self:initEventReceiver("attack", "ATTACK", function(gemName, damage, newGemHealth)
		self:addAttack({
			gemName = gemName,
			damage = damage,
			newGemHealth = newGemHealth,
		})
	end)

	self:initEventReceiver("exp", "EXP", function(exp, level)
		self:updateExp(exp, level)
	end)
end

function Pet:initEventReceiver(key, alias, callback)
	local petEvents = game.ReplicatedStorage:WaitForChild("PetEvents", 5)

	local event = petEvents:WaitForChild(self.petName .. "_" .. alias .. "EVENT", 5)
	if not event then
		warn("NO EVENT FOUND FOR PET: ", self.petName, key, alias)
		return
	end
	self[key .. "Event"] = event

	event.OnClientEvent:Connect(callback)
end

function Pet:updateExp(exp, level)
	local oldLevel = self.level

	self.exp = exp
	self.level = level

	if oldLevel ~= level then
		self:refreshRigScale()
	end

	self:refreshExpBar()
end

function Pet:refreshRigScale()
	if not self.rig then
		return
	end
	local realScale = PetInfo:getRealScale(self.baseWeight, self.level)
	self.rig:ScaleTo(self.baseRigScale * realScale)
end

function Pet:refreshExpBar()
	local bb = self.bb
	if not bb then
		return
	end

	local levelExpCap = PetInfo:calculateLevelExpCap(self.level, self.rating)

	bb.MainFrame.LevelTitle.Text = "Level " .. self.level

	local expBar = bb.MainFrame.ExpBar
	expBar.Title.Text =
		string.format("%s/%s", Common.abbreviateNumber(self.exp) .. "XP", Common.abbreviateNumber(levelExpCap) .. "XP")

	local progressRatio = self.exp / levelExpCap
	progressRatio = math.clamp(progressRatio, 0, 1)
	expBar.CurrProgress.Size = UDim2.fromScale(progressRatio, 1)
end

function Pet:initRig()
	local baseRig = game.ReplicatedStorage.Assets[self.petClass]
	if not baseRig.PrimaryPart then
		baseRig.PrimaryPart = baseRig:FindFirstChild("HumanoidRootPart")
	end

	self.baseRigScale = baseRig:GetScale()

	local rig = baseRig:Clone()
	rig.PrimaryPart.Transparency = 1 -- 0.5

	local armsHoldPart = rig:FindFirstChild("ArmsHoldPart")
	if armsHoldPart then
		armsHoldPart.Transparency = 1 -- 0.5
		armsHoldPart.Color = Color3.fromRGB(83, 164, 250)
		-- weld to rootPart
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rig.PrimaryPart
		weld.Part1 = armsHoldPart
		weld.Parent = armsHoldPart
		self.armsHoldPart = armsHoldPart
	end

	local rootPartMotor = rig.PrimaryPart:FindFirstChild("RootPart")
	if not rootPartMotor then
		local rootPart = rig:FindFirstChild("RootPart") or rig:FindFirstChild("FakeRootPart")
		rootPartMotor = Instance.new("Motor6D")

		rootPartMotor.Part0 = rig.PrimaryPart
		rootPartMotor.Part1 = rootPart
		rootPartMotor.C0 = rig.PrimaryPart.CFrame:inverse() * rootPart.CFrame
		rootPartMotor.C1 = CFrame.new(0, 0, 0)
		rootPartMotor.Name = "RootPart"

		rootPartMotor.Parent = rig.PrimaryPart
	end

	self.rig = rig

	if self.mutationClass then
		ClientMod.mutationManager:addMutationToRig(self, rig, self.mutationClass)
	end

	rig.Parent = game.Workspace.PetRigs

	Common.setCollisionGroup(rig, "Pets")

	Common.weldPartsToRig(rig)

	rig:SetAttribute("petName", self.petName)

	self.rootPart = rig:WaitForChild("HumanoidRootPart", 2)
	if not self.rootPart then
		warn("!! NO ROOT PART FOUND FOR PET: ", self.petName, self.petClass)
	end

	for _, part in pairs(rig:GetDescendants()) do
		if part:IsA("BasePart") and part ~= self.rootPart then
			part.Anchored = false
			part.CanQuery = true
		end
	end

	self:updateRigFrame(self.currFrame)
	self:refreshRigScale()

	for _, child in pairs(rig:GetDescendants()) do
		if child:IsA("BasePart") then
			local textureMod = {}
			textureMod["Color"] = child.Color
			textureMod["Transparency"] = child.Transparency

			if child:IsA("MeshPart") then
				textureMod["TextureID"] = child.TextureID

				local surfaceAppearance = child:FindFirstChildWhichIsA("SurfaceAppearance")
				if surfaceAppearance then
					textureMod["SurfaceAppearance"] = surfaceAppearance:Clone()
				end
			end
			self.partTextureMap[child] = textureMod
		end
	end

	local outerShell = Instance.new("Model")
	rig.Parent = outerShell

	local fakeHumanoid = Instance.new("Humanoid")
	fakeHumanoid.Parent = outerShell
	fakeHumanoid.EvaluateStateMachine = false

	outerShell:SetAttribute("petName", self.petName)
	outerShell.Parent = game.Workspace.PetRigs
	self.outerShell = outerShell

	self:initBB()
	self:initDeletePrompt()
end

function Pet:initDeletePrompt()
	local prompt = ClientMod.uiManager:createPrompt({
		actionText = "Store",
		objectText = self.petStats["alias"],
		name = "DeletePet",
		holdDuration = 0.1,
		enabled = true,
		maxActivationDistance = 15,
		parent = self.rig.RootPart,
	})

	self.deletePrompt = prompt

	prompt.Triggered:Connect(function()
		ClientMod:FireServer("tryStorePet", {
			petName = self.petName,
		})
	end)

	prompt.Parent = self.rig.RootPart.AuraAttachment
end

function Pet:updateRigFrame(newCurrFrame)
	local rig = self.rig
	if not rig then
		return
	end

	local rigFrame = self:getRigFrame(newCurrFrame)
	self.rigFrame = rigFrame

	-- rig:SetPrimaryPartCFrame(rigFrame)
end

function Pet:getRigFrame(newCurrFrame)
	local rootPart = self.rootPart

	local hOffset = rootPart.Size.Y * 0.5
	return newCurrFrame * CFrame.new(0, hOffset, 0)
end

function Pet:updateData(data)
	self:refreshBB()
end

function Pet:updateMoveAnimation(animationClass)
	if self.moveAnimationClass == animationClass then
		return
	end
	self.moveAnimationClass = animationClass

	local animationId = PetInfo[animationClass .. "AnimationMap"][self.petClass]

	ClientMod.animUtils:animate(self, {
		race = "Movement",
		animationId = animationId,
	})
end

function Pet:tickRender(timeRatio)
	self:tickCurrFrame(timeRatio)
	self:tickCurrAction(timeRatio)
end

function Pet:tickCurrAction(timeRatio)
	if not self.actionMod then
		return
	end

	local actionClass = self.actionMod.actionClass

	if actionClass == "HitGem" then
		local gem = ClientMod.gems[self.actionMod["gemName"]]
		if not gem then
			return
		end
	end
end

function Pet:addAttack(data)
	local gemName = data["gemName"]
	local newGemHealth = data["newGemHealth"]
	local damage = data["damage"]

	-- animate
	local animationId = PetInfo.attackAnimationMap[self.petClass]
	local trackMod = ClientMod.animUtils:animate(self, {
		race = "Action",
		animationId = animationId,
	})

	-- print("ANIMATION ID: ", animationId, trackMod)

	if trackMod then
		local track = trackMod["track"]
		track:AdjustSpeed(self.attackSpeedRatio)
	end

	routine(function()
		local totalDelay = 0.3 + (self.petStats["attackDelay"] or 0)
		totalDelay = totalDelay / self.attackSpeedRatio

		wait(totalDelay)
		local gem = ClientMod.gems[gemName]
		if not gem then
			warn("NO GEM FOUND: ", gemName)
			return
		end

		local petPos = self.currFrame.Position
		local gemPos = gem.currFrame.Position

		-- in the middle
		local midPos = (petPos + gemPos) / 2

		if self.userName == player.Name then
			ClientMod.damageManager:addDamageHit({
				pos = midPos + Vector3.new(0, 3, 0),
				damage = damage,
			})
		end

		ClientMod.soundManager:newSoundMod({
			soundClass = "PetHit" .. math.random(1, 5),
			pos = midPos,
			volume = 0.025, -- 0.1
		})

		local hitDir = (gemPos - petPos).Unit
		local hitPos = petPos + hitDir * 3 + Vector3.new(0, 2, 0)

		ClientMod.spellManager:addExplosion({
			-- spellClass = "AttackSlice2",
			spellClass = "RockHit",
			pos = hitPos,
			scale = 2.2, -- 1.5
			-- baseColor = Color3.fromRGB(255, 0, 0),
		})

		if newGemHealth <= 0 then
			-- ClientMod.soundManager:newSoundMod({
			-- 	soundClass = "BoopHit" .. math.random(1, 5),
			-- 	pos = self.currFrame.Position,
			-- 	volume = 0.08,
			-- })

			local extentsSize = gem.model:GetExtentsSize()

			ClientMod.spellManager:addExplosion({
				-- spellClass = "AttackSlice2",
				spellClass = "RockDestroy",
				pos = gemPos + Vector3.new(0, extentsSize.Y / 2, 0),
				scale = 2, -- 1.5
				-- baseColor = Color3.fromRGB(255, 0, 0),
			})
		end

		gem:animateHit(newGemHealth)
	end)
end

function Pet:initBB()
	if self.destroyed then
		return
	end

	local bb = game.ReplicatedStorage.Assets.PetBBPart.BB:Clone()

	bb.Name = "PetBB_" .. self.petName

	self.bb = bb

	local fakeRootPart = self.rig:FindFirstChild("RootPart")
	bb.Adornee = fakeRootPart:FindFirstChild("BBAttachment")
	bb.MaxDistance = 100
	bb.StudsOffset = Vector3.new(0, 0, 0)
	bb.Parent = playerGui

	local rating = self.petStats["rating"]
	ClientMod.ratingManager:applyRatingColor(bb.MainFrame.NameTitle, rating)

	ClientMod.uiScaleManager:addDistStrokeModsFromBB({
		bb = bb,
		adornee = fakeRootPart,
		baseDistance = 30,
	})

	self:refreshBB()
end

function Pet:refreshBB()
	local bb = self.bb
	if not bb then
		return
	end

	bb.MainFrame.NameTitle.Text = self.petStats["alias"]

	local mutationClass = self.mutationClass
	local mutationTitle = bb.MainFrame.MutationTitle
	ClientMod.mutationManager:applyMutationColor(mutationTitle, mutationClass)

	self:refreshExpBar()
end

function Pet:getGoalFrame()
	local actionMod = self.actionMod
	local actionClass = actionMod.actionClass

	local gem = nil
	if actionMod then
		local gemName = actionMod["gemName"]
		gem = ClientMod.gems[gemName]
	end

	if actionClass == "WalkToGem" then
		if not gem then
			return self.currFrame
		end

		local attackPos = self:getAttackGemPos(gem)

		local lookAngle = Common.getCAngle(self.currFrame)
		local distance = Common.getHorizontalDist(self.currFrame.Position, attackPos)
		if distance > 0.2 then
			local lookFrame = CFrame.new(self.currFrame.Position, attackPos)
			lookAngle = Common.getCAngle(lookFrame)
		end

		return CFrame.new(attackPos) * lookAngle * CFrame.new(0, 0, -distance)
	elseif actionClass == "HitGem" then
		if not gem then
			return self.currFrame
		end

		local attackFrame = self.currFrame

		local gemPosition = gem.currFrame.Position
		gemPosition = Vector3.new(gemPosition.X, attackFrame.Position.Y, gemPosition.Z)

		return CFrame.new(attackFrame.Position, gemPosition)
	end
end

function Pet:getAttackGemPos(gem)
	local currPos = self.currFrame.Position
	local gemPos = gem.currFrame.Position

	local moveDir = (gemPos - currPos).Unit
	local attackPos = gemPos - moveDir * (self.attackRange + gem.gemStats.attackRadius)

	return attackPos
end

function Pet:updateActionFromServer(data)
	self.actionMod = data.actionMod

	local serverCurrFrame = data.currFrame

	local currFrame = self.currFrame
	if (currFrame.Position - serverCurrFrame.Position).Magnitude > 10 then
		warn("!!! PET FRAME MISMATCH: ", self.petName, currFrame.Position, serverCurrFrame.Position)
		self.currFrame = serverCurrFrame
	end

	-- self.currFrame = serverCurrFrame
	-- self:updateRigFrame(serverCurrFrame)
end

function Pet:tickCurrFrame(timeRatio)
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
function Pet:calculateNewPos(currFrame, goalFrame, timeRatio)
	local currPos = currFrame.p
	local goalPos = goalFrame.p

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

	-- Apply terrain following for Y position
	newPos = self:applyTerrainFollowing(newPos, timeRatio)

	return newPos
end

function Pet:calculateNewAngle(currFrame, goalFrame, timeRatio)
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

function Pet:applyTerrainFollowing(newPos, timeRatio)
	local mainFloorPart = game.Workspace:WaitForChild("Map1"):WaitForChild("MainFloorPart")
	local yValue = mainFloorPart.Position.Y
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

-- Check if unit is stationary and update animation state
function Pet:setStationary(newBool)
	-- Only update animation state if it changed
	if self.isStationary == newBool then
		return
	end
	self.isStationary = newBool

	-- print("IS STATIONARY: ", newBool, self.currFrame.Position)

	local petClass = self.petClass

	if newBool then
		local animationId = PetInfo.idleAnimationMap[petClass]
		ClientMod.animUtils:animate(self, {
			race = "Movement",
			animationId = animationId,
		})
		self.moveTrackMod = nil
	else
		local user = ClientMod.users[self.userName]
		if not user then
			return
		end

		local animationId = PetInfo.runningAnimationMap[petClass]

		-- TODO: change this based on speed
		local speedRatio = 1

		local moveTrackMod = ClientMod.animUtils:animate(self, {
			race = "Movement",
			animationId = animationId,
			speedRatio = speedRatio, --user.humanoid.WalkSpeed / 20,
		})
		self.moveTrackMod = moveTrackMod
	end
end

function Pet:destroyRig()
	if self.rig then
		self.rig:Destroy()
	end

	if self.outerShell then
		self.outerShell:Destroy()
	end

	if self.bb then
		self.bb:Destroy()
	end

	-- clear all animation tracks
	self.trackMods = {}
	self.raceTrackMods = {}
	self.animationGroupIndexMap = nil
end

function Pet:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	self:destroyRig()
end

return Pet
