local TweenService = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local playerScripts = player.PlayerScripts

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local TweenManager = {
	modelMods = {},
}

function TweenManager:init() end

function TweenManager:createTweenInfo(data)
	local tweenInfo = TweenInfo.new(
		data.timer,
		data.easingStyle,
		data.easingDirection,
		data.repeatCount,
		data.reverses,
		data.delayTime
	)
	return tweenInfo
end

-- STANDARD TWEEN
function TweenManager:createTween(data)
	local target = data["target"]
	local goal = data["goal"]

	local easingStyleString = data["easingStyle"]
	local easingDirectionString = data["easingDirection"]

	-- print("REVERSES: ", data.reverses)

	local tweenInfo = self:createTweenInfo({
		timer = data.timer,
		easingStyle = Enum.EasingStyle[easingStyleString],
		easingDirection = Enum.EasingDirection[easingDirectionString],
		repeatCount = data.repeatCount or 0,
		reverses = data.reverses or false,
		delayTime = data.delayTime or 0,
	})

	if target:IsA("Model") then
		self:addModelMod(target, goal, tweenInfo)
		return
	end

	local tween = TweenService:Create(target, tweenInfo, goal)

	tween:Play()
	return tween
end

function TweenManager:addModelMod(target, goal, tweenInfo)
	local tweenName = "MODELTWEEN_" .. Common.getGUID()

	local startMods = {}
	local goalMods = {}
	for key, value in pairs(goal) do
		if key == "Scale" then
			startMods[key] = target:GetScale()
			goalMods[key] = value
		elseif key == "Position" then
			startMods[key] = target.PrimaryPart.Position
			goalMods[key] = value
		elseif key == "CFrame" then
			startMods[key] = target.PrimaryPart.CFrame
			goalMods[key] = value
		end
	end

	local newModelMod = {
		tweenName = tweenName,
		model = target,
		tweenInfo = tweenInfo,

		startMods = startMods,
		goalMods = goalMods,

		currTime = 0,
		totalTime = tweenInfo.Time,
	}
	self.modelMods[tweenName] = newModelMod
end

function TweenManager:tickRender(timeRatio)
	for _, modelMod in pairs(self.modelMods) do
		self:tickModelMod(modelMod, timeRatio)
	end
end

function TweenManager:tickModelMod(modelMod, timeRatio)
	local model = modelMod["model"]
	local tweenInfo = modelMod["tweenInfo"]

	local currTime = modelMod["currTime"]
	local totalTime = modelMod["totalTime"]

	local startMods = modelMod["startMods"]
	local goalMods = modelMod["goalMods"]

	local newTime = currTime + timeRatio / 60
	if newTime > totalTime then
		self:removeModelMod(modelMod)
		return
	end

	local alpha = TweenService:GetValue(newTime / totalTime, tweenInfo.EasingStyle, tweenInfo.EasingDirection)

	for key, _ in pairs(goalMods) do
		local startValue = startMods[key]
		local goalValue = goalMods[key]

		if key == "Scale" then
			local newValue = startValue + alpha * (goalValue - startValue)
			model:ScaleTo(newValue)
		elseif key == "Position" then
			local newValue = startValue + alpha * (goalValue - startValue)
			model:MoveTo(newValue)
		elseif key == "CFrame" then
			local newValue = startValue:Lerp(goalValue, alpha)
			model:SetPrimaryPartCFrame(newValue)
		end
	end

	modelMod["currTime"] = newTime
end

function TweenManager:removeModelMod(modelMod)
	local tweenName = modelMod["tweenName"]
	self.modelMods[tweenName] = nil
end

TweenManager:init()

return TweenManager
