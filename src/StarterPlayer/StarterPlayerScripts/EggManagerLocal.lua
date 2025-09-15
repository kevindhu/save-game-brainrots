local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local EggInfo = require(game.ReplicatedStorage.EggInfo)

local Egg = require(playerScripts.EggLocal)

local EggManager = {}
EggManager.__index = EggManager

function EggManager:init() end

function EggManager:newEgg(data)
	local eggName = data.eggName
	if ClientMod.eggs[eggName] then
		return
	end

	local egg = Egg.new(data)
	egg:init()
	ClientMod.eggs[eggName] = egg

	ClientMod.placeManager:refreshAllPrompts()

	self:initEggHighlight()
end

function EggManager:initEggHighlight()
	routine(function()
		local eggHighlight = Instance.new("Highlight")
		self.eggHighlight = eggHighlight

		self.eggHighlight.FillColor = Color3.fromRGB(255, 255, 255)

		self.eggHighlight.Parent = game.Workspace.HighlightTemplateModels
		self.eggHighlight.Adornee = nil
	end)
end

function EggManager:chooseHighlightedEgg(chosenEgg)
	self.highlightedEgg = chosenEgg

	if not chosenEgg then
		self.eggHighlight.Adornee = nil
		return
	end

	self.eggHighlight.Adornee = chosenEgg.model
end

function EggManager:removeEgg(data)
	local eggName = data["eggName"]
	local egg = ClientMod.eggs[eggName]
	if not egg then
		return
	end
	egg:destroy()
end

function EggManager:addHatchAnimation(data)
	local eggName = data.eggName
	local egg = ClientMod.eggs[eggName]
	if not egg then
		return
	end
	egg:addHatchAnimation(data)
end

EggManager:init()

return EggManager
