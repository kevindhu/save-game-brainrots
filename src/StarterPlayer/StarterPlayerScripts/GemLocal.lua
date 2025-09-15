local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local GemInfo = require(game.ReplicatedStorage.GemInfo)

local Gem = {}
Gem.__index = Gem

function Gem.new(data)
	local u = {}
	u.data = data

	setmetatable(u, Gem)
	return u
end

function Gem:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end

	local gemStats = GemInfo:getMeta(self.gemClass)
	self.gemStats = gemStats

	self:initModel()
end

function Gem:getModelScale()
	local healthRatio = self.health / self.maxHealth

	-- print("HEALTH RATIO", healthRatio)

	local minScale = 0.4 -- 0.2
	local scaleRatio = (1 - minScale) * healthRatio + minScale
	local goalScale = self.baseScale * scaleRatio

	return goalScale
end

function Gem:initModel()
	local baseModel = game.ReplicatedStorage.Assets:WaitForChild(self.gemClass)
	self.baseModel = baseModel
	self.baseScale = baseModel:GetScale() * self.variationScale

	local model = baseModel:Clone()

	if self.mutationClass and self.mutationClass ~= "None" then
		-- print("ADDING MUTATION AURA", self.mutationClass)
		local weldPartsModel = ClientMod.mutationManager:addMutationAura(model, self.mutationClass)
		weldPartsModel:ScaleTo(weldPartsModel:GetScale() * 2.25)
	end

	for _, child in pairs(model:GetDescendants()) do
		if child:IsA("BasePart") then
			child.CanCollide = false
			child.Anchored = true
		end
	end

	model.Parent = game.Workspace.GemModels
	self.model = model

	if not model.PrimaryPart then
		warn("!! NO PRIMARY PART FOUND FOR GEM: ", self.gemName, self.gemClass)
		model.PrimaryPart = model:FindFirstChild("RootPart")
	end

	model.PrimaryPart.Transparency = 1 -- 0.5

	model:ScaleTo(self.baseScale * 0.1)

	local modelGoalScale = self:getModelScale()

	ClientMod.tweenManager:createTween({
		target = model,
		timer = 0.6,
		easingStyle = "Elastic",
		easingDirection = "Out",
		goal = { Scale = modelGoalScale },
	})

	model:PivotTo(
		self.currFrame * CFrame.new(0, model.PrimaryPart.Size.Y / 2, 0) * CFrame.Angles(0, math.random(100), 0)
	)
end

function Gem:animateHit(newHealth)
	self.health = newHealth

	local modelGoalScale = self:getModelScale()

	local timer = 0.1 -- 0.2
	local easingStyle = "Back"

	if newHealth <= 0 then
		self.model:PivotTo(self.currFrame * CFrame.new(0, -100, 0))
		return
	end

	ClientMod.tweenManager:createTween({
		target = self.model,
		timer = timer,
		easingStyle = easingStyle,
		easingDirection = "Out",
		goal = { Scale = modelGoalScale },
	})
end

function Gem:destroyModel()
	if self.model then
		self.model:Destroy()
	end
end

function Gem:destroy(data)
	if self.destroyed then
		return
	end
	self.destroyed = true

	routine(function()
		local waitTimer = data["waitTimer"] or 0
		wait(waitTimer)
		self:destroyModel()

		ClientMod.gems[self.gemName] = nil
	end)
end

return Gem
