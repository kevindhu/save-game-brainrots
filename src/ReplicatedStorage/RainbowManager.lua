local UserInputService = game:GetService("UserInputService")

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local RainbowManager = {
	rainbowMods = {},
}
RainbowManager.__index = RainbowManager

function RainbowManager:init() end

local colors = {
	Color3.fromRGB(255, 0, 4),
	Color3.fromRGB(255, 0, 242),
	Color3.fromRGB(0, 132, 255),
	Color3.fromRGB(17, 255, 0),
	Color3.fromRGB(227, 225, 230),
	Color3.fromRGB(227, 225, 230),
	Color3.fromRGB(231, 64, 64),
	Color3.fromRGB(24, 49, 159),
}

local TOTAL_COLORS = 4

function RainbowManager:addRainbowRig(rig)
	for _, part in pairs(rig:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end
		if part.Name == "HumanoidRootPart" or part.Name == "RootPart" then
			continue
		end

		self:newRainbowMod({
			part = part,
			baseColor = part.Color,
		})
	end
end

function RainbowManager:tickRender(timeRatio)
	self:tickAllRainbowMods(timeRatio)
end

function RainbowManager:tickAllRainbowMods()
	local t = os.clock()

	local i = math.floor(t % TOTAL_COLORS + 1)

	local newColor = colors[i]:Lerp(colors[i % TOTAL_COLORS + 1], t % 1)

	for _, rainbowMod in pairs(self.rainbowMods) do
		self:tickRainbow(rainbowMod, newColor)
	end
end

function RainbowManager:tickRainbow(rainbowMod, newColor)
	local rainbowName = rainbowMod["rainbowName"]
	local part = rainbowMod["part"]

	if not part or not part.Parent then
		-- warn("PART IS GONE: ", rainbowName)
		self.rainbowMods[rainbowName] = nil
		return
	end

	local t = os.clock()

	local interval = 0.05
	local part = rainbowMod["part"]
	local cameraFrame = workspace.CurrentCamera.CFrame
	local partPosition = part.Position

	if part then
		local cameraDistance = (
			(math.abs(partPosition.X - cameraFrame.X) + math.abs(partPosition.Z - cameraFrame.Z)) / 10
		)
		local intervalMultiplier = math.clamp(cameraDistance + 1, 1, 2.5)
		interval *= intervalMultiplier
	end

	local durationSinceLastUpdate = t - rainbowMod.lastUpdate
	if durationSinceLastUpdate < interval then
		return
	end

	rainbowMod.lastUpdate = t

	local colorToApply = newColor

	local baseColor = rainbowMod["baseColor"]
	if baseColor then
		local _, _, defaultV = baseColor:ToHSV()
		local h, s, _ = newColor:ToHSV()
		colorToApply = Color3.fromHSV(h, math.max(s - 0.4, 0), math.min(defaultV + 0.2, 1))

		-- do a ratio of 0.9 to 0.1 for the baseColor
		-- colorToApply = baseColor:Lerp(newColor, 0.1)
	end

	part.Color = colorToApply
	for _, child in pairs(part:GetChildren()) do
		if child:IsA("SurfaceAppearance") then
			child.Color = colorToApply
		end
	end
end

function RainbowManager:newRainbowMod(data)
	local part = data["part"]
	local baseColor = data["baseColor"]

	local rainbowName = "RAINBOW_" .. Common.getGUID()
	local newRainbowMod = {
		rainbowName = rainbowName,
		part = part,
		lastUpdate = 0,
		baseColor = baseColor,
	}
	self.rainbowMods[rainbowName] = newRainbowMod

	return newRainbowMod
end

return RainbowManager
