local Debris = game:GetService("Debris")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetInfo = require(game.ReplicatedStorage.PetInfo)
local RelicInfo = require(game.ReplicatedStorage.RelicInfo)

local RatingInfo = require(game.ReplicatedStorage.RatingInfo)
local PetBalanceInfo = require(game.ReplicatedStorage.PetBalanceInfo)

local PetSpot = {}
PetSpot.__index = PetSpot

function PetSpot.new(data)
	local u = {}
	u.data = data

	u.partTextureMap = {}

	u.fullRelicMods = {}

	setmetatable(u, PetSpot)
	return u
end

function PetSpot:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:initAllEvents()

	routine(function()
		self:initBuyModel()
		self:initRealModel()

		wait(1)
		if self.unlocked then
			self:unlock()
		end
	end)
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

function PetSpot:initBuyModel()
	local plotModel = game.Workspace:WaitForChild(self.plotName)

	local buyModel = plotModel:FindFirstChild("PetSpot" .. self.index)
	if not buyModel then
		warn("!! PET SPOT MODEL NOT FOUND: ", self.petSpotName, self.index)
		return
	end
	self.buyModel = buyModel

	local buyBB = game.ReplicatedStorage.Assets.BuyPlatformBBPart.BB:Clone()
	buyBB.Parent = buyModel.Collect.Attachment

	local coinsCost = PetBalanceInfo["unlockCostMap"][tostring(self.index)]
	buyBB.MainFrame.Title.Text = "$" .. Common.abbreviateNumber(coinsCost)

	self.buyBB = buyBB

	if player.Name == self.userName then
		buyModel.Collect.Touched:Connect(function(hit)
			local touchPlayer = game.Players:GetPlayerFromCharacter(hit.Parent)
			if touchPlayer ~= player then
				return
			end
			ClientMod.petManager:tryUnlockPetSpot(self, coinsCost)
		end)
	end

	ClientMod.uiScaleManager:addDistStrokeModsFromBB({
		bb = buyBB,
		adornee = buyModel.Collect,
		baseDistance = 40,
	})

	self:toggleBuyModel(false)
end

function PetSpot:toggleBuyModel(newBool)
	self.buyBB.Enabled = newBool
end

function PetSpot:unlock()
	if self.unlockedModel then
		return
	end
	self.unlockedModel = true

	self.unlocked = true

	self:toggleBuyModel(false)

	ClientMod.placeManager:refreshAllPrompts()
end

function PetSpot:initRealModel()
	local realModel = game.Workspace.BoughtPetSpots:WaitForChild(self.petSpotName, 2)
	if not realModel then
		warn("!! REAL PET SPOT MODEL NOT FOUND: ", self.petSpotName)
		return
	end

	self.realModel = realModel
	self.standPart = realModel:WaitForChild("StandPart")

	self:initLevelBB()
	self:initCollectBB()
end

function PetSpot:initLevelBB()
	local model = self.realModel
	local levelBBPart = model:WaitForChild("LevelBBPart")
	levelBBPart.CanCollide = false
	levelBBPart.Transparency = 1

	local levelBB = model:WaitForChild("LevelBBPart").BB
	local levelUpButton = levelBB.MainFrame.Button
	ClientMod.buttonManager:addActivateCons(levelUpButton, function()
		ClientMod:FireServer("tryLevelUpPet", {
			petSpotName = self.petSpotName,
		})

		ClientMod.soundManager:newSoundMod({
			soundClass = "CashBuy",
			volume = 0.2,
		})
	end)
	ClientMod.buttonManager:addBasicButtonCons(levelUpButton)
	self.levelBB = levelBB

	self:refreshLevelBB()
end

function PetSpot:initCollectBB()
	local model = self.realModel
	local collectPart = model:WaitForChild("CollectButton"):WaitForChild("Collect")
	self.collectPart = collectPart

	if player.Name == self.userName then
		collectPart.Touched:Connect(function(hit)
			local touchPlayer = game.Players:GetPlayerFromCharacter(hit.Parent)
			if touchPlayer ~= player then
				return
			end
			self:tryCollectCoins()
		end)

		-- self:initPrompts()

		ClientMod.placeManager:refreshAllPrompts()
	end

	self.collectBB = collectPart.BB
	self.collectBB.Name = "CollectBB" .. self.petSpotName
	self.collectBB.Enabled = false

	self:refreshCollectBB()
end

function PetSpot:tryCollectCoins()
	if self.collectCoinExpiree and self.collectCoinExpiree > ClientMod.step then
		return
	end
	self.collectCoinExpiree = ClientMod.step + 60 * 1

	self:animateCoinsCollection()

	ClientMod:FireServer("tryCollectCoins", {
		petSpotName = self.petSpotName,
	})
end

function PetSpot:animateCoinsCollection()
	local emitterModel = ClientMod.spellUtils:createEmitterModel({
		spellClass = "CoinsExplosion",
	})
	emitterModel.Name = "CoinsModel"

	emitterModel:SetPrimaryPartCFrame(CFrame.new(self.collectPart.Position) * CFrame.new(0, 2.5, 0))
	Debris:AddItem(emitterModel, 4)

	ClientMod.soundManager:newSoundMod({
		soundClass = "CoinCollect2",
		volume = 0.5,
		playbackSpeed = ClientMod.petManager:getCollectSpeed(),
	})

	emitterModel.PrimaryPart.Transparency = 1

	local scale = 1.1 -- 1 (orig) -- 0.5
	ClientMod.spellUtils:shootEmitter({
		emitterModel = emitterModel,
		scale = scale,
	})
end

function PetSpot:addPickupRelicPrompt()
	if self.pickupRelicPrompt then
		return
	end

	local pickupRelicPrompt = ClientMod.uiManager:createPrompt({
		actionText = "Pickup Relic",
		objectText = "",
		name = "PickupRelicPrompt",
		holdDuration = 0.1,
		enabled = true,
		maxActivationDistance = 15,
		parent = self.standPart.PickupRelicAttachment,
		keyCode = Enum.KeyCode.F,
	})
	self.pickupRelicPrompt = pickupRelicPrompt

	self.pickupRelicPrompt.Triggered:Connect(function()
		ClientMod:FireServer("tryPickupRelicFromPetSpot", {
			petSpotName = self.petSpotName,
		})
	end)
end

function PetSpot:addRelicPrompt()
	if self.relicPrompt then
		return
	end

	local relicPrompt = ClientMod.uiManager:createPrompt({
		actionText = "Add Relic",
		objectText = "",
		name = "AddRelicPrompt",
		holdDuration = 0.1,
		enabled = true,
		maxActivationDistance = 15,
		parent = self.standPart.PickupRelicAttachment,
		keyCode = Enum.KeyCode.F,
	})
	self.relicPrompt = relicPrompt

	self.relicPrompt.Triggered:Connect(function()
		local equippedToolMod = ClientMod.placeManager:getEquippedToolMod()
		ClientMod:FireServer("tryPlaceRelicAtPetSpot", {
			toolName = equippedToolMod.toolName,
			petSpotName = self.petSpotName,
		})
	end)
end

function PetSpot:addPlacePrompt()
	if self.placePrompt then
		return
	end

	local placePrompt = ClientMod.uiManager:createPrompt({
		actionText = "Place",
		objectText = "",
		name = "InteractPetPrompt",
		holdDuration = 0.1,
		enabled = true,
		maxActivationDistance = 15,
		parent = self.standPart.InteractAttachment,
	})
	self.placePrompt = placePrompt

	self.placePrompt.Triggered:Connect(function()
		local equippedToolMod = ClientMod.placeManager:getEquippedToolMod()
		ClientMod:FireServer("tryPlacePetAtPetSpot", {
			toolName = equippedToolMod.toolName,
			petSpotName = self.petSpotName,
		})
	end)
end

function PetSpot:removePlacePrompt()
	if self.placePrompt then
		self.placePrompt:Destroy()
		self.placePrompt = nil
	end
end

function PetSpot:removePickupRelicPrompt()
	if self.pickupRelicPrompt then
		self.pickupRelicPrompt:Destroy()
		self.pickupRelicPrompt = nil
	end
end

function PetSpot:removePickupPrompt()
	if self.pickupPrompt then
		self.pickupPrompt:Destroy()
		self.pickupPrompt = nil
	end
end

function PetSpot:removeRelicPrompt()
	if self.relicPrompt then
		self.relicPrompt:Destroy()
		self.relicPrompt = nil
	end
end

function PetSpot:addPickupPrompt()
	if self.pickupPrompt then
		return
	end

	local pickupPrompt = ClientMod.uiManager:createPrompt({
		actionText = "Pickup Brainrot",
		objectText = "",
		name = "PickupPetPrompt",
		holdDuration = 0.1,
		enabled = true,
		maxActivationDistance = 15,
		parent = self.standPart.InteractAttachment,
	})
	self.pickupPrompt = pickupPrompt

	pickupPrompt.Triggered:Connect(function()
		ClientMod:FireServer("tryPickupFromPetSpot", {
			petSpotName = self.petSpotName,
		})
	end)
end

function PetSpot:destroyLevelBB()
	if self.levelBB then
		self.levelBB:Destroy()
		self.levelBB = nil
	end
end

function PetSpot:updateData(data)
	local attackSpeedRatio = data["attackSpeedRatio"]
	local petData = data["petData"]

	local oldPetName = nil
	if self.petData then
		oldPetName = self.petData["petName"]
	end

	self.attackSpeedRatio = attackSpeedRatio
	self.petData = petData

	if self.petData then
		for k, v in pairs(self.petData) do
			self[k] = v
		end
		self.petStats = PetInfo:getMeta(self.petClass)

		if not oldPetName or oldPetName ~= self.petData["petName"] then
			self:refreshRig()
		end

		PetInfo:refreshPetScale(self.rig, self.petData)
	else
		self:destroyRig()
	end

	self:refreshLevelBB()
	self:refreshCollectBB()
	self:refreshPetBB()

	if self.userName == player.Name then
		ClientMod.placeManager:refreshAllPrompts()
	end
end

function PetSpot:refreshCollectBB()
	if not self.collectBB then
		return
	end

	if player.Name ~= self.userName then
		self.collectBB.Enabled = false
		return
	end

	if self.petData then
		self.collectBB.Enabled = true
	else
		self.collectBB.Enabled = false
	end
end

function PetSpot:toggleLevelBB(newBool)
	if not self.levelBB then
		return
	end
	self.levelBB.Enabled = newBool
end

function PetSpot:updateCoins(data)
	local totalCoins = data["totalCoins"]
	local totalOfflineCoins = data["totalOfflineCoins"]

	local collectBB = self.collectBB
	if not collectBB then
		return
	end

	local collectButton = collectBB.MainFrame.Button

	local offlineTitle = collectButton.OfflineTitle
	local coinsTitle = collectButton.CoinsTitle

	if totalOfflineCoins > 0 then
		offlineTitle.Text = "OFFLINE: $" .. Common.abbreviateNumber(totalOfflineCoins, 1)
		offlineTitle.Visible = true
	else
		offlineTitle.Visible = false
	end

	coinsTitle.Text = "$" .. Common.abbreviateNumber(totalCoins, 1)
end

function PetSpot:refreshLevelBB()
	local levelBB = self.levelBB
	if not levelBB then
		return
	end

	if player.Name ~= self.userName then
		levelBB.Enabled = false
		return
	end
	if not self.petData then
		levelBB.Enabled = false
		return
	end

	levelBB.Enabled = true

	local levelUpButton = levelBB.MainFrame.Button

	local levelUpPrice = PetInfo:calculateLevelUpPrice(self.petData)
	levelUpButton.PriceTitle.Text = "$" .. Common.abbreviateNumber(levelUpPrice)

	levelUpButton.LevelTitle.Text = string.format("Lvl %s > Lvl %s", self.level, self.level + 1)
end

function PetSpot:addAttack(data)
	if not self.petData then
		return
	end

	local unitName = data["unitName"]
	local newUnitHealth = data["newUnitHealth"]
	local damage = data["damage"]

	-- animate
	local animationId = PetInfo.attackAnimationMap[self.petClass]
	local trackMod = ClientMod.animUtils:animate(self, {
		race = "Action",
		animationId = animationId,
	})

	local attackSpeedRatio = self.attackSpeedRatio * ClientMod.speedManager:getSpeed(self.userName)

	if trackMod then
		local track = trackMod["track"]
		track:AdjustSpeed(attackSpeedRatio)
	end

	routine(function()
		local totalDelay = 0.3 + (self.petStats["attackDelay"] or 0)
		totalDelay = totalDelay / attackSpeedRatio

		wait(totalDelay)
		local unit = ClientMod.units[unitName]
		if not unit or not unit.rig or not unit.rig.Parent then
			-- warn("NO UNIT FOUND TO ATTACK: ", unitName)
			return
		end

		local petPos = self.currFrame.Position
		local unitPos = unit.currFrame.Position

		self:addLaser(self.rigFrame, unit.rig.Torso.CFrame)

		-- in the middle
		local attackDir = (unitPos - petPos).Unit
		local attackDist = (unitPos - petPos).Magnitude
		local damagePos = unitPos - attackDir * Common.randomBetween(0.7, 1.15)

		local hitPos = unitPos - attackDir

		unit:animateHit({
			newHealth = newUnitHealth,
			hitPos = hitPos,
			damagePos = damagePos,

			damage = damage,
		})
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
	line.Material = Enum.Material.Neon

	-- line.Color = Color3.fromRGB(255, 0, 0)
	-- line.Color = Color3.fromRGB(82, 229, 255)

	local ratingColor = RatingInfo["ratingColorMap"][self.petStats["rating"]]
	line.Color = ratingColor

	local midPos = (posA + posB) / 2
	local vect = (posB - posA).unit
	local length = (posA - posB).Magnitude
	local finalFrame = CFrame.new(midPos, midPos + vect)

	line.Size = Vector3.new(size, size, length)
	line.CFrame = finalFrame
	line.Name = "TESTLINE123"
	line.Parent = game.Workspace.HitBoxes

	routine(function()
		local timer = 0.1 -- / ClientMod.speedManager:getSpeed(self.userName)
		wait(timer)
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
	-- print("INIT RIG FOR PET SPOT: ", self.petSpotName)

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

	PetInfo:refreshPetScale(rig, self.petData)

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

	self:updateRigFrame(self.currFrame)

	local trackMod = ClientMod.animUtils:animate(self, {
		race = "Idle",
		animationId = PetInfo.idleAnimationMap[self.petClass],
	})

	self:initPetBB()
	-- print("DONE INIT RIG FOR PET SPOT: ", self.petSpotName, self.rig)
end

function PetSpot:initPetBB()
	local petBB = game.ReplicatedStorage.Assets.PetBBPart.BB:Clone()

	local fakeRootPart = self.rig:FindFirstChild("RootPart")
	petBB.Adornee = fakeRootPart:FindFirstChild("BBAttachment")

	petBB.Parent = playerGui

	petBB.Name = "PetBB" .. self.petSpotName

	-- ClientMod.ratingManager:applyRatingColor(nameTitle, self.petStats["rating"])

	petBB.MainFrame.CoinsPerSecondTitle.Text =
		string.format("$%s/s", Common.abbreviateNumber(self.petStats["coinsPerSecond"]))

	local ratingTitle = petBB.MainFrame.RatingTitle
	ratingTitle.Text = self.petStats["rating"]
	ClientMod.ratingManager:applyRatingColor(ratingTitle, self.petStats["rating"])

	local nameTitle = petBB.MainFrame.NameTitle

	local mutationPrefix = ""
	if self.mutationClass and self.mutationClass ~= "None" then
		mutationPrefix = self.mutationClass .. " "
	end

	nameTitle.Text = mutationPrefix .. self.petStats["alias"]

	self.petBB = petBB

	local relicItemList = petBB.MainFrame.RelicItemList
	relicItemList.BackgroundTransparency = 1

	self.templateRelicItem = relicItemList.TemplateItem
	self.templateRelicItem.Visible = false

	ClientMod.uiScaleManager:addDistStrokeModsFromBB({
		bb = petBB,
		adornee = fakeRootPart,
		baseDistance = 35,
	})

	self:refreshPetBB()
end

function PetSpot:refreshPetBB()
	local petBB = self.petBB
	if not petBB then
		return
	end

	petBB.MainFrame.LevelTitle.Text = string.format("Level %s", self.level)

	-- clear all relic mods
	for _, relicMod in pairs(self.fullRelicMods) do
		relicMod["frame"]:Destroy()
	end
	self.fullRelicMods = {}

	-- populate all relic mods
	for _, relicData in pairs(self.petData["relicMods"]) do
		self:newRelicMod(relicData)
	end
end

function PetSpot:newRelicMod(relicData)
	local frame = self.templateRelicItem:Clone()
	frame.Visible = true
	frame.Parent = self.templateRelicItem.Parent

	local relicName = relicData["relicName"]
	local newRelicMod = {
		relicName = relicName,
		frame = frame,
	}
	for k, v in pairs(relicData) do
		newRelicMod[k] = v
	end

	local relicClass = relicData["relicClass"]
	local relicStats = RelicInfo:getMeta(relicClass)

	frame.InnerFrame.Icon.Image = relicStats["image"]

	frame.InnerFrame.PowerTitle.Text = math.random(100, 10000)

	self.fullRelicMods[relicName] = newRelicMod

	return newRelicMod
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
	-- warn(debug.traceback())
	-- warn("DESTROYING RIG FOR PET SPOT: ", self.petSpotName)

	if self.rig then
		self.rig:Destroy()
		self.rig = nil
	end
	if self.outerShell then
		self.outerShell:Destroy()
		self.outerShell = nil
	end

	if self.petBB then
		self.petBB:Destroy()
		self.petBB = nil
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
	local newFrame =
		self.currFrame:Lerp(goalFrame, lerpRatio * timeRatio * ClientMod.speedManager:getSpeed(self.userName))

	self.currFrame = newFrame
	self:updateRigFrame(newFrame)
end

function PetSpot:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	self:destroyLevelBB()
	self:destroyRig()

	self:toggleBuyModel(false)
end

return PetSpot
