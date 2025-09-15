local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local playerScripts = player.PlayerScripts

local ClientMod = require(playerScripts.ClientMod)

local Blink = require(playerScripts.WeatherUtils.Blink)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local WeatherEffectManager = {
	effectModels = {},
}
WeatherEffectManager.__index = WeatherEffectManager

function WeatherEffectManager:init() end

function WeatherEffectManager:activateEffect(effectName)
	if effectName == "Blink" then
		Blink:Play()
	end
end

function WeatherEffectManager:removeEffectModelFromWorkspace(effectName)
	if not self.effectModels[effectName] then
		return
	end
	self.effectModels[effectName]:Destroy()
	self.effectModels[effectName] = nil
end

function WeatherEffectManager:addEffectModelToWorkspace(effectName)
	if self.effectModels[effectName] then
		return
	end

	local model = game.ReplicatedStorage.WeatherEffects[effectName]:Clone()
	model.Parent = workspace

	-- for _, descendant in model:GetDescendants() do
	-- 	if descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
	-- 		descendant.Enabled = true
	-- 	end
	-- end

	self.effectModels[effectName] = model
end

return WeatherEffectManager
