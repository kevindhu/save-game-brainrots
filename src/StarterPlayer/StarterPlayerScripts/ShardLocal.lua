local debris = game:GetService("Debris")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local BezierTween = require(game.ReplicatedStorage.Libraries.BezierTween)

local ShardInfo = require(game.ReplicatedStorage.ShardInfo)

local Shard = {}
Shard.__index = Shard

function Shard.new(data)
	local u = {}
	u.data = data

	setmetatable(u, Shard)
	return u
end

function Shard:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end

	local shardStats = ShardInfo:getMeta(self.shardClass)
	self.shardStats = shardStats

	self.randomAngleOffset = CFrame.Angles(math.random() * 5, math.random() * 5, math.random() * 5)

	local baseModel = game.ReplicatedStorage.Assets:WaitForChild(self.shardClass)
	self.currPos = self.currPos + Vector3.new(0, baseModel.PrimaryPart.Size.Y * 0.25, 0)

	self:initModel()
end

function Shard:initModel()
	local model = game.ReplicatedStorage.Assets:WaitForChild(self.shardClass):Clone()

	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("BasePart") then
			child.CanCollide = false
			child.Anchored = true
		end
	end

	model.Parent = game.Workspace.ShardModels
	self.model = model

	if self.mutationClass and self.mutationClass ~= "None" then
		ClientMod.mutationManager:addMutationAura(model, self.mutationClass)
	end

	model.Name = self.shardName

	local baseScale = model:GetScale()
	local startScale = baseScale * 0.1

	self:addPrompt()

	if os.time() - self.creationTimestamp > 10 then
		model:PivotTo(CFrame.new(self.currPos) * self.randomAngleOffset)
		return
	end

	model:ScaleTo(startScale)
	ClientMod.tweenManager:createTween({
		target = model,
		timer = 0.6,
		easingStyle = "Elastic",
		easingDirection = "Out",
		goal = { Scale = baseScale },
	})

	self:doBezierTravelTween(model, self.startPos, self.currPos)

	-- local finalFrame = CFrame.new(self.currPos)
	-- model:PivotTo(finalFrame)
end

function Shard:tickRender()
	if not self.referencePart then
		return
	end

	self.model:PivotTo(self.referencePart.CFrame * self.randomAngleOffset)
end

function Shard:doBezierTravelTween(model, startPos, endPos)
	-- add bezier tween

	local midPos = (startPos + endPos) / 2

	midPos += Vector3.new(0, math.random(18, 25), 0)

	-- model:PivotTo(CFrame.new(startPos) * CFrame.Angles(math.random() * 5, math.random() * 5, math.random() * 5))

	local bezierTween = BezierTween.new(startPos)
	bezierTween:AddBezierPoint(midPos)
	bezierTween:AddBezierPoint(endPos)

	local travelTimer = 0.5 -- 0.5
	if self.noAnimate then
		travelTimer = 0.01
	end

	local referencePart = model.PrimaryPart:Clone()
	local travelTween = bezierTween:CreateTween(
		referencePart,
		{ "CFrame" },
		TweenInfo.new(travelTimer, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
		false
	)

	self.referencePart = referencePart
	travelTween:Play()

	travelTween.Completed:Connect(function()
		referencePart:Destroy()
	end)
end

function Shard:addPrompt()
	if player.Name ~= self.userName then
		return
	end

	local prompt = ClientMod.uiManager:createPrompt({
		actionText = "Collect",
		objectText = nil,
		name = "CollectShard",
		holdDuration = 0.00001,
		enabled = false,
		maxActivationDistance = 20,
		parent = self.model.PrimaryPart,
	})

	self.collectPrompt = prompt

	prompt.Triggered:Connect(function()
		ClientMod:FireServer("tryCollectShard", {
			shardName = self.shardName,
			gemSpawnerName = self.gemSpawnerName,
		})

		ClientMod.soundManager:newSoundMod({
			soundClass = "ShardCollect2",
			volume = 0.5,
			playbackSpeed = ClientMod.gemManager:getShardCollectSpeed(),
		})

		if not self.shardStats["eggClass"] then
			self:animateCollect()
		end
	end)
end

function Shard:animateCollect()
	local emitterModel = ClientMod.spellUtils:createEmitterModel({
		spellClass = "CoinsExplosion",
	})
	emitterModel.Name = "CoinsModel"

	emitterModel:SetPrimaryPartCFrame(CFrame.new(self.currPos))
	debris:AddItem(emitterModel, 4)

	emitterModel.PrimaryPart.Transparency = 1

	local scale = 0.8 -- 1 (orig) -- 0.5
	ClientMod.spellUtils:shootEmitter({
		emitterModel = emitterModel,
		scale = scale,
	})
end

function Shard:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	if self.model then
		self.model:Destroy()
	end
end

return Shard
