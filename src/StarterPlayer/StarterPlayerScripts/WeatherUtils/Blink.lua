local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local ClientMod = require(playerScripts.ClientMod)

local camera = workspace.CurrentCamera

local Blink = {}
Blink.__index = Blink

function Blink:init()
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Brightness = 0 -- Start at normal brightness
	colorCorrection.TintColor = Color3.fromRGB(255, 255, 255) -- White tint
	colorCorrection.Parent = camera
	self.colorCorrection = colorCorrection
end

-- Activates the blink effect (called by WeatherEffectController:Activate("Blink"))
function Blink:Play()
	-- Instantly set screen to maximum brightness (white flash)
	self.colorCorrection.Brightness = 1

	routine(function()
		wait(1)

		local fadeToNormalTween = ClientMod.tweenManager:createTween({
			target = self.colorCorrection,
			timer = 1,
			easingStyle = "Sine",
			easingDirection = "In",
			goal = { Brightness = 0 },
		})
	end)
end

Blink:init()

return Blink
