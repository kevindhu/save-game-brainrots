local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local playerScripts = player.PlayerScripts

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local CircleManager = {}
CircleManager.__index = CircleManager

local circleGUI = playerGui:WaitForChild("CircleGUI")

function CircleManager:init()
	local templateCircleItem = circleGUI.TemplateItem
	templateCircleItem.Visible = false
	self.templateCircleItem = templateCircleItem

	-- UserInputService.InputBegan:Connect(function(input, processed)
	-- 	-- maybe only do it for mouseclick and not touched
	-- 	if not Common.listContains(Common.clickInputTypes, input.UserInputType) then
	-- 		return
	-- 	end

	-- 	local position = input.Position
	-- 	self:addExpandCircle(position)
	-- end)
end

function CircleManager:addExpandCircle(pos)
	local frame = self.templateCircleItem:Clone()
	frame.Visible = true
	frame.Parent = self.templateCircleItem.Parent

	local startRatio = 0.5 -- 0.8
	local endRatio = 1.2 -- 1.5

	local uiScale = frame.UIScale
	uiScale.Scale = startRatio

	frame.Position = UDim2.new(0, pos.X, 0, pos.Y)

	local fadeTimer = 0.3
	ClientMod.tweenManager:createTween({
		target = uiScale,
		timer = fadeTimer,
		easingStyle = "Quad",
		easingDirection = "Out",
		goal = {
			Scale = endRatio,
		},
	})

	ClientMod.tweenManager:createTween({
		target = frame,
		timer = fadeTimer,
		easingStyle = "Quad",
		easingDirection = "Out",
		goal = {
			BackgroundTransparency = 1,
		},
	})

	Debris:AddItem(frame, 3)
end

CircleManager:init()

return CircleManager
