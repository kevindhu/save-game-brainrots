local debris = game:GetService("Debris")
local ts = game:GetService("TweenService")

local ClientMod = require(script.Parent:WaitForChild("ClientMod"))

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local SpellUtils = {}

function SpellUtils:init() end

function SpellUtils:createEmitterModel(data)
	local spellClass = data["spellClass"]

	-- Build the path to the spell model by traversing the folder structure
	local spellClassParts = string.split(spellClass, "/")
	local baseModel = game.ReplicatedStorage.Assets
	for i, part in ipairs(spellClassParts) do
		baseModel = baseModel:WaitForChild(part)
	end

	local model = baseModel:Clone()
	if model:IsA("BasePart") then
		-- create model from the base part
		local basePart = model
		local realModel = Instance.new("Model")
		basePart.Parent = realModel
		realModel.PrimaryPart = basePart
		model = realModel
	end

	if model:FindFirstChild("BasePart") then
		model.PrimaryPart = model:FindFirstChild("BasePart")
	end

	-- set the model to the workspace
	model.Parent = game.Workspace.ActiveSpellModels
	for _, thing in pairs(model:GetDescendants()) do
		if thing:IsA("BasePart") then
			thing.Transparency = 1
			thing.CanCollide = false
			thing.CanTouch = false
			thing.CanQuery = false
			thing.Anchored = true
			thing.CastShadow = false
		end
	end
	return model
end

function SpellUtils:getEmitterMap(emitterModel, emitterMod)
	local emitterList = {}
	self:getEmittersFromModel(emitterList, emitterModel)

	local emitterMap = {}
	for _, thing in pairs(emitterList) do
		local newName = thing.Name .. "_" .. Common.getGUID()
		thing.Name = newName
		emitterMap[newName] = Common.deepCopy(emitterMod)
	end
	return emitterMap
end

-- THESE EMITTERS ARE ENABLED AND DISABLED - NOT USING :EMIT()
function SpellUtils:animateEmitter(data)
	local emitterModel = data["emitterModel"]
	local emitterMap = data["emitterMap"]
	local scale = data["scale"]
	local baseColor = data["baseColor"]

	local emitters = {}
	self:getEmittersFromModel(emitters, emitterModel)

	for _, emitter in pairs(emitters) do
		local emitterMod = emitterMap[emitter.Name]

		local delayTimer = emitterMod["delay"] or 0
		routine(function()
			wait(delayTimer)
			emitter.Enabled = true
		end)

		if baseColor then
			emitter.Color = ColorSequence.new(baseColor)
		end

		if scale then
			self:scaleEmitter(emitter, scale)
		end
		local timer = emitterMod["timer"] or 0
		routine(function()
			wait(timer)
			emitter.Enabled = false
		end)
	end
end

-- THESE EMITTERS ARE SHOOTING - USING :EMIT()
function SpellUtils:shootEmitter(data)
	local emitterModel = data["emitterModel"]
	local scale = data["scale"]
	local baseColor = data["baseColor"]

	local emitters = {}
	self:getEmittersFromModel(emitters, emitterModel)

	for _, emitter in pairs(emitters) do
		if not emitter:IsA("ParticleEmitter") then
			continue
		end

		local rate = emitter:GetAttribute("EmitCount") or emitter:GetAttribute("Emit") or emitter.Rate
		local delayTimer = emitter:GetAttribute("EmitDelay") or 0

		if baseColor then
			emitter.Color = ColorSequence.new(baseColor)
		end

		routine(function()
			wait(delayTimer)
			emitter:Emit(rate)
		end)
		emitter.Rate = rate

		self:scaleEmitter(emitter, scale)
	end
end

function SpellUtils:getEmittersFromModel(emitters, thing)
	for _, descendant in pairs(thing:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			emitters[descendant] = descendant
			descendant.Enabled = false
		elseif descendant:IsA("Beam") then
			emitters[descendant] = descendant
			descendant.Enabled = false
		end
	end
end

function SpellUtils:scaleEmitter(emitter, ratio)
	if not emitter:IsA("ParticleEmitter") or not ratio then
		return
	end

	local oldSequence = emitter.Size
	local newKeypoints = {}
	for _, keypoint in pairs(oldSequence.Keypoints) do
		local timePoint = keypoint.Time
		local value = keypoint.Value * ratio
		local envelope = keypoint.Envelope * ratio

		local newPoint = NumberSequenceKeypoint.new(timePoint, value, envelope)
		table.insert(newKeypoints, newPoint)
	end

	local newSequence = NumberSequence.new(newKeypoints)
	emitter.Size = newSequence

	-- scale the speed
	local speed = emitter.Speed

	local newSpeed = NumberRange.new(speed.Min * ratio, speed.Max * ratio)
	emitter.Speed = newSpeed
end

SpellUtils:init()

return SpellUtils
