local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetInfo = require(game.ReplicatedStorage.PetInfo)
local MapInfo = require(game.ReplicatedStorage.MapInfo)

local PetSpot = {}
PetSpot.__index = PetSpot

function PetSpot.new(data)
	local u = {}
	u.data = data

	u.partTextureMap = {}

	setmetatable(u, PetSpot)
	return u
end

function PetSpot:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:initModel()
	self:initPrompts()

	self:initAllEvents()
end

function PetSpot:initAllEvents()
	self:initEventReceiver("attack", "ATTACK", function(unitName, damage, newUnitHealth)
		self:addAttack({
			unitName = unitName,
			damage = damage,
			newUnitHealth = newUnitHealth,
		})
	end)
end

function PetSpot:initEventReceiver(key, alias, callback)
	local petEvents = game.ReplicatedStorage:WaitForChild("PetEvents", 5)

	local event = petEvents:WaitForChild(self.petSpotName .. "_" .. alias .. "EVENT", 5)
	if not event then
		warn("NO EVENT FOUND FOR PET SPOT: ", self.petSpotName, key, alias)
		return
	end
	self[key .. "Event"] = event

	event.OnClientEvent:Connect(callback)
end

function PetSpot:initModel()
	local plotModel = ClientMod.plotManager.model
	local model = plotModel:FindFirstChild("PetSpot" .. self.index)
	if not model then
		warn("!! PET SPOT MODEL NOT FOUND: ", self.petSpotName, self.index)
		return
	end
	self.model = model

	self.standPart = model:WaitForChild("StandPart")
end

function PetSpot:initPrompts()
	local interactPrompt = ClientMod.uiManager:createPrompt({
		actionText = "Interact",
		objectText = "",
		name = "InteractPetPrompt",
		holdDuration = 0.1,
		enabled = true,
		maxActivationDistance = 15,
		parent = self.standPart.InteractAttachment,
	})
	self.interactPrompt = interactPrompt

	self.interactPrompt.Triggered:Connect(function()
		local equippedToolMod = ClientMod.placeManager:getEquippedToolMod()
		if self.petData then
			ClientMod:FireServer("tryPickupFromPetSpot", {
				petSpotName = self.petSpotName,
			})
		else
			ClientMod:FireServer("tryPlacePetAtPetSpot", {
				toolName = equippedToolMod.toolName,
				petSpotName = self.petSpotName,
			})
		end
	end)
end

function PetSpot:updateData(data)
	local attackSpeedRatio = data["attackSpeedRatio"]
	local petData = data["petData"]

	self.attackSpeedRatio = attackSpeedRatio
	self.petData = petData

	local oldPetName = self.petName

	if not self.petData then
		self:destroyRig()
		if self.userName == player.Name then
			ClientMod.placeManager:refreshAllPrompts()
		end
		return
	end

	for k, v in pairs(self.petData) do
		self[k] = v
	end

	self.petStats = PetInfo:getMeta(self.petClass)

	if oldPetName ~= self.petName then
		print("REFRESHING RIG FOR PET SPOT: ", self.petSpotName)
		self:refreshRig()
	end

	if self.userName == player.Name then
		ClientMod.placeManager:refreshAllPrompts()
	end
end

function PetSpot:addAttack(data)
	-- print("ADDING ATTACK FOR PET SPOT: ", self.petSpotName)

	local unitName = data["unitName"]
	local newUnitHealth = data["newUnitHealth"]
	local damage = data["damage"]

	-- animate
	local animationId = PetInfo.attackAnimationMap[self.petClass]
	local trackMod = ClientMod.animUtils:animate(self, {
		race = "Action",
		animationId = animationId,
	})

	if trackMod then
		local track = trackMod["track"]
		track:AdjustSpeed(self.attackSpeedRatio)
	end

	routine(function()
		local totalDelay = 0.3 + (self.petStats["attackDelay"] or 0)
		totalDelay = totalDelay / self.attackSpeedRatio

		wait(totalDelay)
		local unit = ClientMod.units[unitName]
		if not unit then
			warn("NO UNIT FOUND: ", unitName)
			return
		end

		local petPos = self.currFrame.Position
		local unitPos = unit.currFrame.Position

		self:addLaser(self.rigFrame, unit.rig.Torso.CFrame)

		-- in the middle
		local attackDir = (unitPos - petPos).Unit
		local attackDist = (unitPos - petPos).Magnitude
		local damagePos = petPos + attackDir * attackDist * 0.85

		if self.userName == player.Name then
			ClientMod.damageManager:addDamageHit({
				pos = damagePos + Vector3.new(0, 3, 0),
				damage = damage,
			})
		end

		ClientMod.soundManager:newSoundMod({
			soundClass = "PetHit" .. math.random(1, 5),
			pos = damagePos,
			volume = 0.025, -- 0.1
		})

		local hitPos = unitPos - attackDir

		ClientMod.spellManager:addExplosion({
			spellClass = "RockHit",
			pos = hitPos,
			scale = 2.2, -- 1.5
		})

		unit:animateHit(newUnitHealth)
	end)
end

function PetSpot:addLaser(petFrame, unitFrame)
	local posA = petFrame.Position
	local posB = unitFrame.Position

	local size = 0.2

	local line = Instance.new("Part")

	line.Anchored = true
	line.CanCollide = false
	line.Parent = workspace

	-- line.Color = Color3.fromRGB(255, 0, 0)
	line.Color = Color3.fromRGB(82, 229, 255)

	local midPos = (posA + posB) / 2
	local vect = (posB - posA).unit
	local length = (posA - posB).Magnitude
	local finalFrame = CFrame.new(midPos, midPos + vect)

	line.Size = Vector3.new(size, size, length)
	line.CFrame = finalFrame
	line.Name = "TESTLINE123"
	line.Parent = game.Workspace.HitBoxes

	routine(function()
		wait(0.1)
		line:Destroy()
	end)

	return line
end

function PetSpot:refreshRig()
	if self.rig then
		self:destroyRig()
	end

	self:initRig()
end

function PetSpot:initRig()
	print("INIT RIG FOR PET SPOT: ", self.petSpotName)

	local baseRig = game.ReplicatedStorage.Assets[self.petClass]
	if not baseRig.PrimaryPart then
		baseRig.PrimaryPart = baseRig:FindFirstChild("HumanoidRootPart")
	end

	self.baseRigScale = baseRig:GetScale()

	local rig = baseRig:Clone()
	rig.PrimaryPart.Transparency = 1 -- 0.5

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

	-- print("DONE INIT RIG FOR PET SPOT: ", self.petSpotName)

	self:updateRigFrame(self.currFrame)

	-- self:initBB()
end

function PetSpot:updateRigFrame(newCurrFrame)
	local rig = self.rig
	if not rig then
		return
	end

	local rootPart = self.rootPart
	local hOffset = rootPart.Size.Y * 0.5
	local rigFrame = newCurrFrame * CFrame.new(0, hOffset, 0)

	self.rigFrame = rigFrame

	-- rig:SetPrimaryPartCFrame(rigFrame)
end

function PetSpot:destroyRig()
	if self.rig then
		self.rig:Destroy()
	end
	if self.outerShell then
		self.outerShell:Destroy()
	end
end

function PetSpot:tickRender(timeRatio)
	self:tickCurrFrame(timeRatio)
end

function PetSpot:tickCurrFrame(timeRatio)
	if not self.petData then
		return
	end

	local closestDist = math.huge
	local targetUnit = nil

	local currPosition = self.currFrame.Position

	for _, unit in pairs(ClientMod.units) do
		local dist = Common.getHorizontalDist(currPosition, unit.currFrame.p)
		if dist < closestDist then
			closestDist = dist
			targetUnit = unit
		end
	end

	local goalFrame = self.baseFrame
	if targetUnit then
		local lookPosition = targetUnit.currFrame.Position
		lookPosition = Vector3.new(lookPosition.X, currPosition.Y, lookPosition.Z)

		goalFrame = CFrame.new(currPosition, lookPosition)
	end

	local lerpRatio = 0.05
	local newFrame = self.currFrame:Lerp(goalFrame, lerpRatio * timeRatio)

	self.currFrame = newFrame
	self:updateRigFrame(newFrame)
end

function PetSpot:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	self:destroyRig()
end

return PetSpot
