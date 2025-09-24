local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local buttonGUI = playerGui:WaitForChild("ButtonGUI")
local leftFrame = buttonGUI.LeftFrame
local dpsFrame = leftFrame.DpsFrame

local camera = workspace.CurrentCamera

local DamageManager = {}
DamageManager.__index = DamageManager

function DamageManager:init()
	dpsFrame.BackgroundTransparency = 1

	self:toggleDPSFrame(false)
end

local MAX_CAMERA_DISTANCE = 100

function DamageManager:addDamageHit(data)
	local pos = data["pos"]
	local damage = data["damage"]

	local cameraPos = camera.CFrame.Position
	if (pos - cameraPos).Magnitude > MAX_CAMERA_DISTANCE then
		return
	end

	local part = game.ReplicatedStorage.Assets.DamagePart:Clone()
	part.Transparency = 1 -- 0.5

	part.Position = pos
	part.Parent = game.Workspace.DamageParts

	local offsetPos = Common.getRandomFlatDir() * Common.randomBetween(3, 4.5)
		+ Vector3.new(0, Common.randomBetween(4, 6), 0)
	offsetPos *= 1.3 -- 1.5
	local endPos = pos + offsetPos

	local bb = part.BB
	local damageTitle = bb.Frame.Title
	damage = math.floor(damage)
	damageTitle.Text = Common.abbreviateNumber(damage, 1)

	local uiScale = damageTitle.UIScale
	uiScale.Scale = 1.5
	ClientMod.tweenManager:createTween({
		target = uiScale,
		timer = 0.2,
		easingStyle = "Quad",
		easingDirection = "Out",
		goal = {
			Scale = 1,
		},
	})

	ClientMod.uiScaleManager:addDistStrokeModsFromBB({
		bb = bb,
		adornee = part,
		baseDistance = 30,
	})

	-- tween the part up
	local fadeTimer = 0.7
	ClientMod.tweenManager:createTween({
		target = part,
		timer = fadeTimer,
		easingStyle = "Linear",
		easingDirection = "Out",
		goal = { Position = endPos },
	})

	routine(function()
		local waitTimer = 0.4
		wait(waitTimer)
		local secondFadeTimer = fadeTimer - waitTimer
		ClientMod.tweenManager:createTween({
			target = damageTitle,
			timer = secondFadeTimer,
			easingStyle = "Linear",
			easingDirection = "Out",
			goal = { TextTransparency = 1 },
		})

		ClientMod.tweenManager:createTween({
			target = damageTitle.UIStroke,
			timer = secondFadeTimer,
			easingStyle = "Linear",
			easingDirection = "Out",
			goal = { Transparency = 1 },
		})
	end)

	routine(function()
		wait(fadeTimer + 1)
		part:Destroy()
	end)
end

function DamageManager:tickRender(timeRatio)
	self:tickDPS(timeRatio)
end

function DamageManager:tickDPS(timeRatio)
	if not self.dpsExpiree or ClientMod.step > self.dpsExpiree then
		-- print("Toggling DPS frame off")
		self:toggleDPSFrame(false)
	end
end

function DamageManager:updateDPS(data)
	local dps = data["dps"]
	-- local totalDamage = data["totalDamage"]

	self.dpsExpiree = ClientMod.step + 60 * 3
	self:toggleDPSFrame(true)

	dpsFrame.DpsTitle.Text = "DPS: " .. Common.abbreviateNumber(dps, 1)
	-- dpsFrame.TotalDamageTitle.Text = "Total: " .. Common.abbreviateNumber(totalDamage)
end

function DamageManager:toggleDPSFrame(newBool)
	if newBool == self.dpsToggled then
		return
	end
	self.dpsToggled = newBool

	dpsFrame.Visible = newBool
end

DamageManager:init()

return DamageManager
