local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player:WaitForChild("PlayerGui")

local ClientMod = require(playerScripts.ClientMod)

local WeatherInfo = require(game.ReplicatedStorage.WeatherInfo)

local Common = require(game.ReplicatedStorage.Common)
local routine = Common.routine

local boostGUI = playerGui:WaitForChild("BoostGUI")
local boostFrame = boostGUI.BoostFrame
local weatherTitle = boostFrame.WeatherTitle

local WeatherManager = {
	specialEventMods = {},
}
WeatherManager.__index = WeatherManager

function WeatherManager:init()
	self:addCons()
end

function WeatherManager:addCons() end

function WeatherManager:updateWeather(data)
	local eventMod = data["eventMod"]
	self.currEventMod = eventMod

	local eventClass = eventMod["eventClass"]
	local eventStats = WeatherInfo:getMeta(eventClass)

	weatherTitle.Text = string.format("[%s]", eventClass)
	weatherTitle.TextColor3 = eventStats["color"] or Color3.new(1, 1, 1)

	self:refreshFollowEmitter()
	self:setLighting()

	self:refreshSpecialEvent()
end

local specialEventMapping = {
	-- NyanCat = "NyanCat",
}

function WeatherManager:refreshSpecialEvent()
	for _, specialEventMod in pairs(self.specialEventMods) do
		specialEventMod:stop()
	end
	self.specialEventMods = {}

	local eventMod = self.currEventMod
	local eventClass = eventMod["eventClass"]

	if specialEventMapping[eventClass] then
		self:addSpecialEvent(specialEventMapping[eventClass])
	end
end

function WeatherManager:addSpecialEvent(effectName)
	local module = playerScripts.WeatherEvents:FindFirstChild(effectName)
	if not module then
		warn("NO SPECIAL EVENT MOD: ", effectName)
		return
	end

	local specialEventMod = require(module)
	specialEventMod:start()
	self.specialEventMods[effectName] = specialEventMod
end

function WeatherManager:toggleConfusion(newBool)
	local lighting = game.Lighting
	local colorCorrection = lighting:FindFirstChildOfClass("ColorCorrectionEffect")

	if newBool then
		routine(function()
			local firstTimer = 1
			ClientMod.tweenManager:createTween({
				target = colorCorrection,
				timer = firstTimer,
				easingStyle = "Quad",
				easingDirection = "Out",
				goal = {
					TintColor = Color3.fromRGB(207, 94, 238),
				},
			})
		end)
	else
		self:setLighting()
	end
end

function WeatherManager:toggleGreyscreen(newBool)
	local lighting = game.Lighting
	local colorCorrection = lighting:FindFirstChildOfClass("ColorCorrectionEffect")

	print("TOGGLING GREYSCREEN", newBool)

	if newBool then
		routine(function()
			local firstTimer = 0.2
			ClientMod.tweenManager:createTween({
				target = colorCorrection,
				timer = firstTimer,
				easingStyle = "Quad",
				easingDirection = "Out",
				goal = {
					TintColor = Color3.fromRGB(210, 255, 62),
				},
			})

			wait(firstTimer)

			local secondTimer = 0.3

			ClientMod.tweenManager:createTween({
				target = colorCorrection,
				timer = secondTimer,
				easingStyle = "Quad",
				easingDirection = "Out",
				goal = {
					TintColor = Color3.fromRGB(255, 142, 120),
				},
			})

			wait(secondTimer)

			local thirdTimer = 0.3
			ClientMod.tweenManager:createTween({
				target = colorCorrection,
				timer = thirdTimer,
				easingStyle = "Quad",
				easingDirection = "Out",
				goal = {
					Saturation = -1,
					Contrast = 0.5,
					TintColor = Color3.fromRGB(255, 255, 255),
				},
			})
		end)
	else
		self:setLighting()
	end
end

function WeatherManager:clearLighting()
	for _, child in pairs(game.Lighting:GetChildren()) do
		if Common.listContains({ "DepthofField" }, child.Name) then
			continue
		end
		if child:IsA("BlurEffect") then
			continue
		end
		if child:IsA("Folder") then
			continue
		end
		child:Destroy()
	end
end

function WeatherManager:setLighting()
	self:clearLighting()

	local currEventMod = self.currEventMod
	local eventClass = currEventMod["eventClass"]
	local eventStats = WeatherInfo:getMeta(eventClass)

	local lightingFolder = game.Lighting.LightingFolders:FindFirstChild(eventClass)
	if not lightingFolder then
		lightingFolder = game.Lighting.LightingFolders:FindFirstChild("Default")
	end

	for _, child in pairs(lightingFolder:GetChildren()) do
		if child:IsA("Folder") then
			continue
		end

		local fadeTimer = 2.5 -- 1
		ClientMod.tweenManager:createTween({
			target = game.Lighting,
			timer = fadeTimer,
			easingStyle = "Quad",
			easingDirection = "Out",
			goal = {
				[child.Name] = child.Value,
			},
		})
	end

	local cloudFadeTimer = 4 -- 2.5

	ClientMod.tweenManager:createTween({
		target = game.Workspace.Terrain.Clouds,
		timer = cloudFadeTimer,
		easingStyle = "Quad",
		easingDirection = "Out",
		goal = {
			Cover = eventStats["cloudCover"],
		},
	})

	-- include everything but DOF
	for _, shaderItem in pairs(lightingFolder.Shaders:GetChildren()) do
		if shaderItem:IsA("DepthOfFieldEffect") then
			continue
		end
		if shaderItem:IsA("BlurEffect") then
			continue
		end
		local shaderClone = shaderItem:Clone()
		shaderClone.Parent = game.Lighting
	end
end

function WeatherManager:refreshFollowEmitter()
	-- remove old emitter
	local followEmitterModel = self.followEmitterModel
	if followEmitterModel then
		followEmitterModel:Destroy()
		self.followEmitterModel = nil
	end

	local currEventMod = self.currEventMod
	local eventClass = currEventMod["eventClass"]
	local baseEmitterModel = game.ReplicatedStorage.WeatherModels:FindFirstChild(eventClass .. "EmitterModel")
	if not baseEmitterModel then
		return
	end

	followEmitterModel = baseEmitterModel:Clone()
	followEmitterModel.Parent = game.Workspace.HitBoxes

	for _, thing in pairs(followEmitterModel:GetDescendants()) do
		if thing:IsA("BasePart") then
			thing.Transparency = 1
		end
	end

	self.followEmitterModel = followEmitterModel
end

function WeatherManager:tickRender(timeRatio)
	local camera = workspace.CurrentCamera

	local cameraPos = camera.CFrame.p
	local newFrame = CFrame.new(cameraPos)

	local followEmitterModel = self.followEmitterModel
	if followEmitterModel then
		followEmitterModel:PivotTo(newFrame)
	end

	for _, specialEventMod in pairs(self.specialEventMods) do
		specialEventMod:tick(timeRatio)
	end
end

WeatherManager:init()

return WeatherManager
