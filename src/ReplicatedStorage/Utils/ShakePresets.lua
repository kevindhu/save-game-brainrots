local RunService = game:GetService("RunService")
local Shake = require(game.ReplicatedStorage.Packages.Shake)

local Presets = {}

Presets.Bump = {
	Amplitude = 2.5,
	Frequency = 0.25,
	FadeInTime = 0.1,
	FadeOutTime = 0.75,
	PositionInfluence = Vector3.new(0.15, 0.15, 0.15),
	RotationInfluence = Vector3.new(1, 1, 1),
}

Presets.BumpS = {
	Amplitude = 1.5,
	Frequency = 0.25,
	FadeInTime = 0.1,
	FadeOutTime = 0.75,
	PositionInfluence = Vector3.new(0.15, 0.15, 0.15),
	RotationInfluence = Vector3.new(1, 1, 1),
}

Presets.Explosion = {
	Amplitude = 5,
	Frequency = 0.1,
	FadeInTime = 0,
	FadeOutTime = 1.5,
	PositionInfluence = Vector3.new(0.25, 0.25, 0.25),
	RotationInfluence = Vector3.new(4, 1, 1),
}

Presets.Earthquake = {
	Amplitude = 0.6,
	Frequency = 0.2857142857142857,
	FadeInTime = 2,
	FadeOutTime = 10,
	PositionInfluence = Vector3.new(0.25, 0.25, 0.25),
	RotationInfluence = Vector3.new(1, 1, 4),
}

Presets.Vibration = {
	Amplitude = 0.4,
	Frequency = 0.05,
	FadeInTime = 2,
	FadeOutTime = 2,
	PositionInfluence = Vector3.new(0, 0.15, 0),
	RotationInfluence = Vector3.new(1.25, 0, 4),
}

function Presets.CreateShake(config)
	local shake = Shake.new()
	for property, value in pairs(config) do
		shake[property] = value
	end
	return shake
end

function Presets.BindShakeToCamera(shake, camera)
	local originalCFrame = nil
	local postSimConnection = nil
	local shouldRestore = true

	shake:BindToRenderStep(Shake.NextRenderName(), Enum.RenderPriority.Last.Value, function(offset, rotation, stop)
		originalCFrame = camera.CFrame

		local translation = CFrame.new(offset)
		local rx = math.rad(rotation.X)

		camera.CFrame = camera.CFrame
			* (translation * CFrame.Angles(0, math.rad(rotation.Y), 0) * CFrame.Angles(rx, 0, math.rad(rotation.Z)))

		if stop then
			shouldRestore = nil
			if postSimConnection then
				postSimConnection:Disconnect()
				postSimConnection = nil
			end
		end
	end)

	if shouldRestore == true then
		postSimConnection = RunService.PostSimulation:Connect(function()
			if originalCFrame then
				camera.CFrame = originalCFrame
			end
		end)
	end

	return function()
		if postSimConnection then
			postSimConnection:Disconnect()
			postSimConnection = nil
		end
		shake:Destroy()
	end
end

return Presets
