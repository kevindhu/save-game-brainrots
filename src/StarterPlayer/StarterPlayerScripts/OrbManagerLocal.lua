local debris = game:GetService("Debris")
local ts = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)
local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetInfo = require(game.ReplicatedStorage.PetInfo)
local RatingInfo = require(game.ReplicatedStorage.RatingInfo)

local orbGUI = playerGui:WaitForChild("OrbGUI")

local buttonGUI = playerGui:WaitForChild("ButtonGUI")
local leftFrame = buttonGUI.LeftFrame
local middleFrame = buttonGUI.MiddleFrame

local OrbManager = {
	orbMods = {},
	screenOrbMods = {},
}

function OrbManager:init()
	if game.PlaceId == Common.afkPlaceId then
		return
	end

	self:addCons()
end

function OrbManager:addCons()
	self.templateOrbItem = orbGUI.OrbItem
	self.templateOrbItem.Visible = false

	routine(function()
		Common.setCollisionGroup(game.ReplicatedStorage.Assets.CoinsModel, "Resources")
	end)
end

function OrbManager:tick(timeRatio)
	self:tickOrbPos(timeRatio)
	self:tickScreenOrbs(timeRatio)
end

function OrbManager:tickOrbPos()
	for orbName, orbMod in pairs(self.orbMods) do
		local model = orbMod["model"]

		local basePart = orbMod["basePart"]
		model:PivotTo(CFrame.new(basePart.Position))

		local idleExpiree = orbMod["idleExpiree"]
		if ClientMod.step > idleExpiree then
			self:removeOrbMod(orbName)
		end
	end
end

function OrbManager:tickScreenOrbs(timeRatio)
	for _, screenOrbMod in pairs(self.screenOrbMods) do
		local expiree = screenOrbMod["expiree"]
		local frame = screenOrbMod["frame"]

		if ClientMod.step > expiree then
			if frame then
				frame:Destroy()
			end
			self.screenOrbMods[frame] = nil
			continue
		end
		local rotationSpeed = 10 -- 5
		frame.Rotation = frame.Rotation + rotationSpeed * timeRatio
	end
end

function OrbManager:newOrbMod(data)
	local orbName = data["name"]
	local startPos = data["startPos"] -- Vector3.new(0, 600, 0)
	local direction = data["direction"]
	local value = data["value"]
	local velMagnitude = data["velMagnitude"]
	local itemClass = data["itemClass"]
	local petClass = data["petClass"]
	local mutationClass = data["mutationClass"]

	if not velMagnitude then
		velMagnitude = math.random(100, 150) * 0.01 -- 100
	end

	local height = 3 -- 4

	direction = direction.unit
	direction = direction + Vector3.new(0, height, 0)
	direction = direction.unit

	local startFrame = CFrame.new(startPos)

	local model = game.ReplicatedStorage.Assets[itemClass .. "Model"]:Clone()
	model.Parent = game.Workspace.HitBoxes

	self:weldOrbDecor(model)

	model:PivotTo(startFrame)
	model.PrimaryPart.Transparency = 1 -- 0.5

	local basePart = model.PrimaryPart
	basePart.Anchored = false

	local properties = self:generatePhysicalProperties()
	basePart.CustomPhysicalProperties = properties

	local dist = math.random(30, 50) -- 80, 100
	basePart.AssemblyLinearVelocity = direction * dist * velMagnitude

	routine(function()
		self:animateBB(model.DecorPart, petClass, mutationClass)
	end)

	local newOrbMod = {
		name = orbName,

		model = model,
		basePart = basePart,

		value = value,
		idleExpiree = ClientMod.step + 60 * 3, -- 60 * 2 (orig)
	}
	self.orbMods[orbName] = newOrbMod
end

function OrbManager:animateBB(decorPart, petClass, mutationClass)
	local bb = decorPart.BB
	local icon = bb.MainFrame.Icon
	local uiScale = icon.UIScale

	local rating = PetInfo:getMeta(petClass)["rating"]
	local ratingColor = RatingInfo["ratingColorMap"][rating]
	decorPart.Sparkle.Color = ColorSequence.new(ratingColor)

	bb.Size = UDim2.fromScale(8, 8)

	icon.Image = PetInfo:getPetImage(petClass, mutationClass)

	uiScale.Scale = 0

	local info = TweenInfo.new(
		1.1, -- Time
		Enum.EasingStyle.Elastic, -- Bounce  -- EasingStyle
		Enum.EasingDirection.Out, -- EasingDirection
		0, -- RepeatCount (when less than zero the tween will loop indefinitely)
		false, -- Reverses (tween will reverse once reaching it's goal)
		0 -- DelayTime
	)
	local goal = {
		Scale = 1.1,
	}
	local expandTween = ts:Create(uiScale, info, goal)
	expandTween:Play()

	wait(1.35)

	ClientMod.soundManager:newSoundMod({
		soundClass = "CoinCollect3",
		volume = 0.2,
	})

	-- TURN EMITTERS OFF FIRST
	for _, thing in pairs(decorPart:GetDescendants()) do
		if thing:IsA("ParticleEmitter") then
			thing.Enabled = false
		end
	end

	wait(0.15)

	local info = TweenInfo.new(
		0.2, -- Time
		Enum.EasingStyle.Quad, -- Bounce  -- EasingStyle
		Enum.EasingDirection.Out, -- EasingDirection
		0, -- RepeatCount (when less than zero the tween will loop indefinitely)
		false, -- Reverses (tween will reverse once reaching it's goal)
		0 -- DelayTime
	)
	local goal = {
		Scale = 0,
	}
	local shrinkTween = ts:Create(uiScale, info, goal)
	shrinkTween:Play()

	self:newScreenOrb(decorPart, petClass, mutationClass)
end

-- turn the orb position into on screen coordinate and tween to the cash position
function OrbManager:newScreenOrb(decorPart, petClass, mutationClass)
	local screenPosition, inView = workspace.CurrentCamera:WorldToScreenPoint(decorPart.Position)
	local screenVector = Vector2.new(screenPosition.X, screenPosition.Y)

	local frame = self.templateOrbItem:Clone()
	frame.Visible = true

	frame.BackgroundTransparency = 1
	frame.Position = UDim2.new(0, screenVector.X, 0, screenVector.Y)

	frame.Parent = self.templateOrbItem.Parent

	self.screenOrbMods[frame] = {
		frame = frame,
		expiree = ClientMod.step + 60 * 5,
	}

	-- local targetIcon = leftFrame.ButtonsFrame.Index
	local targetIcon = middleFrame

	local petStats = PetInfo:getMeta(petClass)
	frame.Icon.Image = PetInfo:getPetImage(petClass, mutationClass)

	local iconScale = frame.Icon.UIScale
	iconScale.Scale = 0.2

	local travelTimer = 0.2
	local info = TweenInfo.new(
		travelTimer, -- Time
		Enum.EasingStyle.Quad, -- EasingStyle
		Enum.EasingDirection.Out, -- EasingDirection
		0, -- RepeatCount (when less than zero the tween will loop indefinitely)
		false, -- Reverses (tween will reverse once reaching it's goal)
		0 -- DelayTime
	)
	local goal = {
		Scale = 1,
	}

	local scaleTween = ts:Create(iconScale, info, goal)
	scaleTween:Play()

	local endAbsolutePos = targetIcon.AbsolutePosition
	local endPos = UDim2.new(
		0,
		endAbsolutePos.X + targetIcon.AbsoluteSize.X * 0.5,
		0,
		endAbsolutePos.Y + targetIcon.AbsoluteSize.Y * 0.1 + frame.AbsoluteSize.Y * 0.5
	)

	local travelTimer = 0.5
	local info = TweenInfo.new(
		travelTimer, -- Time
		Enum.EasingStyle.Linear, -- EasingStyle
		Enum.EasingDirection.Out, -- EasingDirection
		0, -- RepeatCount (when less than zero the tween will loop indefinitely)
		false, -- Reverses (tween will reverse once reaching it's goal)
		0 -- DelayTime
	)
	local goal = {
		Position = endPos,
	}
	local moveTween = ts:Create(frame, info, goal)
	moveTween:Play()

	-- routine(function()
	-- 	wait(travelTimer)
	-- 	if itemClass == "Coins" then
	-- 		local icon = coinsFrame.Icon
	-- 		ClientMod.currManager:animateIconBounce(icon)
	-- 	end
	-- end)

	local info = TweenInfo.new(
		travelTimer - 0, -- Time
		Enum.EasingStyle.Linear, -- EasingStyle
		Enum.EasingDirection.Out, -- EasingDirection
		0, -- RepeatCount (when less than zero the tween will loop indefinitely)
		false, -- Reverses (tween will reverse once reaching it's goal)
		0 -- DelayTime
	)
	local goal = {
		ImageTransparency = 1,
	}
	local fadeTween = ts:Create(frame.Icon, info, goal)
	fadeTween:Play()

	debris:AddItem(frame, 3)
end

function OrbManager:weldOrbDecor(model)
	local basePart = model.PrimaryPart
	local decorPart = model.DecorPart

	local weld = Instance.new("Motor6D")
	weld.Part0 = decorPart
	weld.Part1 = basePart
	weld.C0 = decorPart.CFrame:inverse() * basePart.CFrame
	weld.C1 = CFrame.new(0, 0, 0)
	weld.Name = "GemWeld123"
	weld.Parent = decorPart

	decorPart.Anchored = false
end

function OrbManager:removeOrbMod(orbName)
	local orbMod = self.orbMods[orbName]

	local model = orbMod["model"]
	if model then
		model:Destroy()
	end

	self.orbMods[orbName] = nil
end

function OrbManager:generatePhysicalProperties()
	local density = 10 -- 10
	local friction = 0.5 -- 0.1
	local elasticity = 0.5 -- 0.8 -- 0.2 (orig)
	local frictionWeight = 1
	local elasticityWeight = 5 -- 2

	-- Construct new PhysicalProperties and set
	local properties = PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)
	return properties
end

OrbManager:init()

return OrbManager
