local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local EggInfo = require(game.ReplicatedStorage.EggInfo)
local PetInfo = require(game.ReplicatedStorage.PetInfo)

local Egg = {}
Egg.__index = Egg

function Egg.new(data)
	local u = {}
	u.data = data

	setmetatable(u, Egg)
	return u
end

function Egg:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end

	local eggStats = EggInfo:getMeta(self.eggClass)
	self.eggStats = eggStats

	self:initModel()
	self:initPrompt()
	self:initBB()
end

function Egg:initBB()
	local bb = game.ReplicatedStorage.Assets.EggBBPart.BB:Clone()
	bb.Parent = playerGui
	bb.Adornee = self.model.PrimaryPart.BBAttachment
	bb.MaxDistance = 100

	self.bb = bb

	ClientMod.uiScaleManager:addDistStrokeModsFromBB({
		bb = bb,
		adornee = self.model.PrimaryPart,
		baseDistance = 30,
	})
end

function Egg:initPrompt()
	local prompt = ClientMod.uiManager:createPrompt({
		actionText = "Click to skip",
		name = "InstantHatchEgg",
		holdDuration = 0.2,
		enabled = false,
		parent = self.model.PrimaryPart,
	})
	self.hatchPrompt = prompt

	prompt.PromptShown:Connect(function()
		ClientMod.eggManager:chooseHighlightedEgg(self)
	end)
	prompt.PromptHidden:Connect(function()
		if ClientMod.eggManager.highlightedEgg ~= self then
			return
		end
		ClientMod.eggManager:chooseHighlightedEgg(nil)
	end)

	prompt.Triggered:Connect(function()
		if not self.isHatchable then
			ClientMod:FireServer("tryInstantHatchEgg", {
				eggName = self.eggName,
			})
			return
		end

		ClientMod:FireServer("tryHatchEgg", {
			eggName = self.eggName,
		})
	end)
end

function Egg:initModel()
	local baseModel = game.ReplicatedStorage.Assets[self.eggClass]
	self.baseModel = baseModel
	self.baseScale = baseModel:GetScale()

	local model = baseModel:Clone()
	model.Parent = game.Workspace.EggModels
	self.model = model

	model.PrimaryPart = model:FindFirstChild("RootPart")

	if self.mutationClass and self.mutationClass ~= "None" then
		ClientMod.mutationManager:addMutationAura(model, self.mutationClass)
	end

	for _, child in pairs(model:GetDescendants()) do
		if not child:IsA("BasePart") then
			continue
		end
		child.Anchored = true
		child.CanCollide = false
	end

	local basePart = model.PrimaryPart
	basePart:SetAttribute("eggName", self.eggName)
	self.basePart = basePart

	local modelFrame = self.currFrame * CFrame.new(0, model.PrimaryPart.Size.Y / 2, 0)
	model:SetPrimaryPartCFrame(modelFrame)

	local placeCollideModel = game.ReplicatedStorage.Assets.PlaceCollideModel:Clone()
	placeCollideModel:PivotTo(self.currFrame * CFrame.new(0, placeCollideModel.PrimaryPart.Size.Y / 2, 0))
	placeCollideModel.Parent = game.Workspace.HitBoxes

	self.placeCollidePart = placeCollideModel.PrimaryPart

	for _, child in pairs(placeCollideModel:GetDescendants()) do
		if not child:IsA("BasePart") then
			continue
		end
		child.Transparency = 1
	end

	self.placeCollideModel = placeCollideModel

	-- add notice
	local noticeModel = game.ReplicatedStorage.Assets.NoticeModel:Clone()
	noticeModel.Parent = game.Workspace.NoticeModels
	self.noticeModel = noticeModel

	noticeModel:SetPrimaryPartCFrame(
		modelFrame * CFrame.new(0, model.PrimaryPart.Size.Y / 2 + 3, 0) * CFrame.Angles(0, math.rad(90), 0)
	)

	self:toggleNotice(false)

	if not self.noSpawnAnimation then
		model:ScaleTo(self.baseScale * 0.1)
		ClientMod.tweenManager:createTween({
			target = model,
			timer = 0.6,
			easingStyle = "Elastic",
			easingDirection = "Out",
			goal = { Scale = self.baseScale },
		})
	else
		model:ScaleTo(self.baseScale)
	end
end

function Egg:toggleNotice(newBool)
	if self.noticeToggled == newBool then
		return
	end
	self.noticeToggled = newBool

	for _, child in pairs(self.noticeModel:GetDescendants()) do
		if not child:IsA("BasePart") then
			continue
		end
		child.Transparency = newBool and 0 or 1
	end
end

function Egg:tick()
	if self.destroyed then
		return
	end

	self:tickExpiree()
end

function Egg:toggleHatchable(newBool)
	if self.isHatchable == newBool then
		return
	end
	self.isHatchable = newBool

	self:toggleNotice(newBool)

	if newBool then
		self.hatchPrompt.ActionText = "Hatch"
		self.hatchPrompt.Name = "HatchEgg"
	end
end

function Egg:tickExpiree()
	local timeRemaining = self.hatchExpiree - Common.getCurrentDecimalTime()

	timeRemaining = math.max(0, timeRemaining)

	local hatchTime = self.eggStats["hatchTime"]
	local progressRatio = 1 - (timeRemaining / hatchTime)

	local bb = self.bb
	local hatchTitle = bb.MainFrame.HatchTitle

	local progressBar = bb.MainFrame.ProgressBar
	progressBar.Title.Text = Common.convertSecondsToReadableString(timeRemaining)

	progressBar.CurrProgress.Size = UDim2.fromScale(progressRatio, 1)

	if timeRemaining <= 0 then
		self:toggleHatchable(true)
		hatchTitle.Text = "Ready"
		progressBar.Title.Text = "Hatch!"
	end
end

function Egg:destroyModel()
	if self.model then
		self.model:Destroy()
	end
	if self.noticeModel then
		self.noticeModel:Destroy()
	end
	if self.placeCollideModel then
		self.placeCollideModel:Destroy()
	end
end

function Egg:addHatchAnimation(data)
	if self.hatchPrompt then
		self.hatchPrompt:Destroy()
	end

	self.destroyed = true

	if self.bb then
		self.bb:Destroy()
	end

	local model = self.model

	-- remove notice immediately on hatch
	local noticeModel = self.noticeModel
	if noticeModel then
		noticeModel:Destroy()
	end

	local baseFrame = self.currFrame * CFrame.new(0, model.PrimaryPart.Size.Y / 2, 0)

	for i = 1, 8 do
		local currFrame
		if i % 2 == 0 then
			currFrame = baseFrame * CFrame.Angles(0, math.rad(30), 0)
		else
			currFrame = baseFrame * CFrame.Angles(0, math.rad(-30), 0)
		end

		local swingTimer = 0.5

		ClientMod.soundManager:newSoundMod({
			soundClass = "EggHit1",
			pos = model.PrimaryPart.Position,
			volume = 0.3,
		})

		ClientMod.tweenManager:createTween({
			target = model,
			timer = swingTimer,
			easingStyle = "Elastic",
			easingDirection = "Out",
			goal = { CFrame = currFrame },
		})
		wait(swingTimer)
	end

	-- print("DONE SWINGING")

	local itemData = data.itemData

	local anchorPart = model.PrimaryPart:Clone()
	anchorPart.Transparency = 1
	anchorPart.CanCollide = false
	anchorPart.Parent = game.Workspace.HitBoxes

	-- add the pet model
	local petClass = itemData.itemClass
	local fakePetRig = ClientMod.weldPetManager:addWeldPetRig({
		petClass = petClass,
		baseWeight = itemData.baseWeight,
		level = itemData.level,
		anchorPart = anchorPart,

		-- mutations
		mutationManager = ClientMod.mutationManager,
		mutationClass = itemData.mutationClass,
		noParent = true,
	})

	local finalScale = fakePetRig:GetScale()
	local startScale = finalScale * 0.1

	local hatchPos = model.PrimaryPart.Position

	ClientMod.soundManager:newSoundMod({
		soundClass = "EggBreak2",
		pos = hatchPos,
		volume = 0.4,
	})

	ClientMod.soundManager:newSoundMod({
		soundClass = petClass,
		pos = hatchPos,
		volume = 0.35,
		rollOffMaxDistance = 300,
	})

	-- ClientMod.spellManager:addExplosion({
	-- 	-- spellClass = "AttackSlice2",
	-- 	spellClass = "SpawnPetExplosion",
	-- 	pos = model.PrimaryPart.Position,
	-- 	scale = 2, -- 1.5
	-- 	-- baseColor = Color3.fromRGB(255, 0, 0),
	-- })

	self.iceModel = ClientMod.spellManager:addAnimatedEmitter({
		spellClass = "SpawnPetExplosion",
		emitterMod = {
			timer = 0.5,
		},
		scale = 1,
		frame = CFrame.new(hatchPos),
	})

	local user = ClientMod.users[data["userName"]]
	if user then
		ClientMod.fireworksManager:shootFireworkSequence(user.currFrame)
	end

	ClientMod.hatchManager:doHatch({
		petClass = petClass,
		mutationClass = itemData.mutationClass,
	})

	-- first scale down
	fakePetRig:ScaleTo(startScale)

	local scaleUpTimer = 2 -- 1

	ClientMod.tweenManager:createTween({
		target = fakePetRig,
		timer = scaleUpTimer,
		easingStyle = "Elastic",
		easingDirection = "Out",
		goal = { Scale = finalScale },
	})
	fakePetRig.Name = itemData.itemClass .. "_HATCH_RIG"
	fakePetRig.Parent = game.Workspace.HitBoxes

	routine(function()
		wait()
		self:animatePetRig(fakePetRig, petClass)

		wait(2)

		fakePetRig:Destroy()
		anchorPart:Destroy()
	end)

	self:destroyModel()
	ClientMod.eggs[self.eggName] = nil
end

function Egg:animatePetRig(fakePetRig, petClass)
	local animationId = PetInfo["idleAnimationMap"][petClass]
	local weldRigEntity = {
		rig = fakePetRig,
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

function Egg:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	if self.bb then
		self.bb:Destroy()
	end

	self:destroyModel()
	ClientMod.eggs[self.eggName] = nil
end

return Egg
