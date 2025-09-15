local debris = game:GetService("Debris")

local ClientMod = require(script.Parent:WaitForChild("ClientMod"))

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local MapInfo = require(game.ReplicatedStorage.MapInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local SpellManager = {
	spells = {},
}
SpellManager.__index = SpellManager

function SpellManager:init() end

-- SPECIFIC UTILS
function SpellManager:addExplosion(data)
	local spellClass = data["spellClass"]
	local pos = data["pos"]
	local frame = data["frame"]
	local scale = data["scale"] or 0.5
	local baseColor = data["baseColor"]

	local emitterModel = ClientMod.spellUtils:createEmitterModel({
		spellClass = spellClass,
	})

	if not frame then
		frame = CFrame.new(pos)
	end

	routine(function()
		emitterModel:PivotTo(frame)
		ClientMod.spellUtils:shootEmitter({
			emitterModel = emitterModel,
			scale = scale,
			baseColor = baseColor,
		})
	end)

	debris:AddItem(emitterModel, 6)
	return emitterModel
end

function SpellManager:addAnimatedEmitter(data)
	local spellClass = data["spellClass"]
	local frame = data["frame"]
	local baseColor = data["baseColor"]
	local emitterMod = data["emitterMod"]
	local scale = data["scale"] or 1.5

	local emitterModel = ClientMod.spellUtils:createEmitterModel({
		spellClass = spellClass,
	})

	emitterModel:PivotTo(frame)

	local emitterMap = ClientMod.spellUtils:getEmitterMap(emitterModel, emitterMod)
	ClientMod.spellUtils:animateEmitter({
		emitterModel = emitterModel,
		emitterMap = emitterMap,
		scale = scale,
		baseColor = baseColor,
	})
	return emitterModel
end

function SpellManager:getFloorPos(goalPos)
	-- raycast down to find ground
	local rayOrigin = Vector3.new(goalPos.X, goalPos.Y + 20, goalPos.Z)
	local rayDirection = Vector3.new(0, -40, 0)
	local ray = Ray.new(rayOrigin, rayDirection)

	local whiteList = MapInfo:getLandWhiteList()
	local hitPart, hitPosition = workspace:FindPartOnRayWithWhitelist(ray, whiteList)
	if not hitPart then
		hitPosition = goalPos
	end
	return hitPosition
end

SpellManager:init()

return SpellManager
