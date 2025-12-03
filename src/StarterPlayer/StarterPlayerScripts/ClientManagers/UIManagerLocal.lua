local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local playerScripts = player.PlayerScripts

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine

local buttonGUI = playerGui:WaitForChild("ButtonGUI")
local stashGUI = playerGui:WaitForChild("StashGUI")

local UIManager = {}

function UIManager:init()
	self:addCons()
end

function UIManager:addCons()
	local blur = game.Lighting:FindFirstChild("Blur")
	if not blur then
		blur = Instance.new("BlurEffect")
		blur.Parent = game.Lighting
	end
end

function UIManager:animateOpen(frame)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)

	local startPos = UDim2.fromScale(0.5, 0.25)
	local endPos = UDim2.fromScale(0.5, 0.5)

	frame.Position = startPos

	ClientMod.tweenManager:createTween({
		target = frame,
		timer = 0.15,
		easingStyle = "Back",
		easingDirection = "Out",
		repeatCount = 0,
		goal = {
			Position = endPos,
		},
	})
end

function UIManager:animateClose(frame)
	routine(function()
		wait(0.05)
		frame.Visible = false
	end)

	local startPos = UDim2.fromScale(0.5, 0.5)
	local endPos = UDim2.fromScale(0.5, 0.25)

	frame.Position = startPos

	ClientMod.tweenManager:createTween({
		target = frame,
		timer = 0.15,
		easingStyle = "Back",
		easingDirection = "Out",
		repeatCount = 0,
		goal = {
			Position = endPos,
		},
	})
end

function UIManager:tryAnimateClose(frame, data)
	local newBool = data["newBool"]
	local animateClose = data["animateClose"]

	-- JUST FOR TESTING IF ITS BETTER
	animateClose = false

	if not newBool and animateClose then
		self:animateClose(frame)
	else
		frame.Visible = newBool
	end
end

function UIManager:handleFOV(data)
	local newBool = data["newBool"]

	if self.fovToggled == newBool then
		return
	end
	self.fovToggled = newBool

	local camera = workspace.CurrentCamera

	local finalFOV = 70
	if newBool then
		finalFOV = 55
	end

	ClientMod.tweenManager:createTween({
		target = camera,
		timer = 0.15,
		easingStyle = "Quad",
		easingDirection = "Out",
		goal = { FieldOfView = finalFOV },
	})
end

function UIManager:createPrompt(data)
	local actionText = data["actionText"]
	local objectText = data["objectText"] or ""
	local name = data["name"]
	local holdDuration = data["holdDuration"]
	local enabled = data["enabled"]
	local maxActivationDistance = data["maxActivationDistance"] or 1
	local parent = data["parent"]
	local keyCode = data["keyCode"]
	local uiOffset = data["uiOffset"]

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText

	if uiOffset then
		prompt.UIOffset = uiOffset
	end

	-- prompt.Style = Enum.ProximityPromptStyle.Custom

	prompt.MaxActivationDistance = maxActivationDistance

	-- prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow

	prompt.KeyboardKeyCode = keyCode or Enum.KeyCode.E

	prompt.Name = name
	prompt.Enabled = enabled
	prompt.HoldDuration = holdDuration
	prompt.RequiresLineOfSight = false

	prompt.Parent = parent

	return prompt
end

function UIManager:handleBlur(data)
	local newBool = data["newBool"]
	local noBlur = data["noBlur"]

	if noBlur and newBool == false then
		return
	end

	if self.blurToggled == newBool then
		return
	end
	self.blurToggled = newBool

	local blurEffect = game.Lighting.Blur
	blurEffect.Enabled = true

	local finalSize = 0
	if newBool then
		finalSize = 20
	end

	ClientMod.tweenManager:createTween({
		target = blurEffect,
		timer = 0.15,
		easingStyle = "Quad",
		easingDirection = "Out",
		goal = { Size = finalSize },
	})
end

function UIManager:interactMainFrame(frame, data)
	self:tryAnimateClose(frame, data)
	self:handleBlur(data)
	self:handleFOV(data)
end

function UIManager:toggleHUD(newBool)
	buttonGUI.Enabled = newBool
	stashGUI.Enabled = newBool
end

local managerList = {
	"shopManager",
	"basicManager",
	"indexManager",
	"luckWizardManager",
	"speedManager",
	"stashManager",
}

function UIManager:toggleOffAllGUI()
	for _, managerClass in pairs(managerList) do
		if not ClientMod[managerClass] then
			continue
		end
		ClientMod[managerClass]:toggle({
			newBool = false,
			animateClose = false,
			noBlur = true,
		})
	end
end

function UIManager:addBBToPlayerGUI(bb, defaultDistance)
	bb.ResetOnSpawn = false
	local oldParent = bb.Parent
	bb.Adornee = oldParent
	bb.Parent = playerGui

	-- don't do this yet
	-- self:recurseGUIForBBStrokes(bb, defaultDistance, bb)

	return bb
end

UIManager:init()

return UIManager
