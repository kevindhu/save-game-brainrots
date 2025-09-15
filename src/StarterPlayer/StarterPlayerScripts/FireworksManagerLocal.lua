local TweenService = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local playerScripts = player.PlayerScripts

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local FireworkAssets = game.ReplicatedStorage.Assets.FireworksHolder

local FireworksManager = {}
FireworksManager.__index = FireworksManager

local FireworkColors = {
	Color3.fromRGB(255, 49, 49), -- Red
	Color3.fromRGB(255, 179, 55), -- Orange
	Color3.fromRGB(255, 255, 53), -- Yellow
	Color3.fromRGB(105, 255, 79), -- Green
	Color3.fromRGB(90, 112, 255), -- Blue
	Color3.fromRGB(70, 252, 255), -- Cyan
	Color3.fromRGB(193, 85, 255), -- Purple
	Color3.fromRGB(255, 169, 225), -- Pink
}

function FireworksManager:init() end

-- Shoots multiple fireworks in sequence with sound effect
function FireworksManager:shootFireworkSequence(launchCFrame)
	local fireworkCount = math.random(6, 8)

	local colors = Common.deepCopy(FireworkColors)
	local shuffledColors = Common.shuffleList(colors)

	-- Launch multiple fireworks with slight delays
	for i = 1, fireworkCount do
		local selectedColor = shuffledColors[i]
		task.delay((i - 1) * 0.07, function()
			self:createFireworkProjectile(launchCFrame, selectedColor)
		end)
	end

	-- Play firework launch sound
	task.delay(0.1, function()
		ClientMod.soundManager:newSoundMod({
			soundClass = "FireworksLaunch",
			pos = launchCFrame.Position,
			volume = 0.1,
			rollOffMaxDistance = 200, -- 250
			rollOffMinDistance = 13,
		})
	end)
end

-- Creates a single firework projectile with trail and explosion effects
function FireworksManager:createFireworkProjectile(startCFrame, color)
	-- print("CREATING FIREWORK PROJECTILE: ", startCFrame, color)

	local fireworkPart = Instance.new("Part")
	fireworkPart.Size = Vector3.new(0.5, 0.5, 0.5)
	fireworkPart.Anchored = true
	fireworkPart.CanCollide = false
	fireworkPart.Transparency = 1
	fireworkPart.CFrame = startCFrame
	fireworkPart.Name = "firework"
	fireworkPart.Parent = workspace

	-- Setup trail effect
	local trailTemplate = FireworkAssets:FindFirstChild("Trail")
	local trailEffect
	if trailTemplate then
		trailEffect = trailTemplate:Clone()
		if trailEffect:IsA("ParticleEmitter") then
			trailEffect.Color = ColorSequence.new(color)
		end
	else
		trailEffect = nil
	end
	trailEffect.Parent = fireworkPart
	trailEffect.Enabled = true

	-- Setup spec particle effect
	local specEffect = FireworkAssets:FindFirstChild("Spec"):Clone()
	specEffect.Parent = fireworkPart
	specEffect.Enabled = true
	specEffect.Color = ColorSequence.new(Color3.new(1, 1, 1))
	specEffect.Size = NumberSequence.new(0.1)
	specEffect.Speed = NumberRange.new(0.5, 1)
	specEffect.Acceleration = Vector3.new(0, -29.4, 0)
	specEffect.Rate = 30
	specEffect.EmissionDirection = Enum.NormalId.Top
	specEffect.Lifetime = NumberRange.new(0.5, 1)
	specEffect.LightInfluence = 0
	specEffect.LockedToPart = true

	-- Create random trajectory for firework
	local randomX = math.random(-7, 7)
	local randomZ = math.random(-7, 7)

	local flightDistance = math.random(10, 16)
	local flightTimer = flightDistance / 10

	ClientMod.tweenManager:createTween({
		target = fireworkPart,
		timer = flightTimer,
		easingStyle = "Quad",
		easingDirection = "Out",
		goal = {
			CFrame = startCFrame + Vector3.new(randomX, flightDistance, randomZ),
		},
	})

	wait(flightTimer)

	-- Create explosion effects when firework reaches peak
	local explosionTemplate = FireworkAssets:FindFirstChild("Explosion")
	local explosionEffect
	if explosionTemplate then
		explosionEffect = explosionTemplate:Clone()
		if explosionEffect:IsA("ParticleEmitter") then
			explosionEffect.Color = ColorSequence.new(color)
		end
	else
		explosionEffect = nil
	end
	explosionEffect.Parent = fireworkPart
	explosionEffect:Emit(math.random(60, 100))

	-- Add sparks effect
	local sparksTemplate = FireworkAssets:FindFirstChild("Sparks")
	local sparksEffect
	if sparksTemplate then
		sparksEffect = sparksTemplate:Clone()
		if sparksEffect:IsA("ParticleEmitter") then
			sparksEffect.Color = ColorSequence.new(color)
		end
	else
		sparksEffect = nil
	end
	sparksEffect.Parent = fireworkPart
	sparksEffect:Emit(math.random(40, 80))

	-- Disable sparks after short delay
	task.delay(0.3, function()
		if sparksEffect then
			sparksEffect.Enabled = false
		end
	end)

	-- Add optional sparkle effect
	if FireworkAssets:FindFirstChild("Sparkle") then
		local sparkleTemplate = FireworkAssets:FindFirstChild("Sparkle")
		local sparkleEffect
		if sparkleTemplate then
			sparkleEffect = sparkleTemplate:Clone()
			if sparkleEffect:IsA("ParticleEmitter") then
				sparkleEffect.Color = ColorSequence.new(color)
			end
		else
			sparkleEffect = nil
		end
		sparkleEffect.Parent = fireworkPart
		sparkleEffect:Emit(math.random(20, 40))
	end

	-- Add optional flare effect
	if FireworkAssets:FindFirstChild("Flare") then
		local flareTemplate = FireworkAssets:FindFirstChild("Flare")
		local flareEffect
		if flareTemplate then
			flareEffect = flareTemplate:Clone()
			if flareEffect:IsA("ParticleEmitter") then
				flareEffect.Color = ColorSequence.new(color)
			end
		else
			flareEffect = nil
		end
		flareEffect.Parent = fireworkPart
		flareEffect:Emit(math.random(10, 30))
	end

	-- Fade out trail and spec effects over 0.3 seconds
	local fadeStartTime = tick()
	while tick() - fadeStartTime < 0.3 do
		local fadeProgress = NumberSequence.new((tick() - fadeStartTime) / 0.3)
		if trailEffect then
			trailEffect.Transparency = fadeProgress
		end
		if specEffect then
			specEffect.Transparency = fadeProgress
		end
		task.wait()
	end

	-- Disable remaining effects
	if trailEffect then
		trailEffect.Enabled = false
	end
	if specEffect then
		specEffect.Enabled = false
	end

	-- Clean up the firework part after delay
	task.delay(4, function()
		if fireworkPart then
			fireworkPart:Destroy()
		end
	end)
end

FireworksManager:init()

return FireworksManager
