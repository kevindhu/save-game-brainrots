local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

-- local ToolInfo = require(game.ReplicatedStorage.ToolInfo)

local ToolManager = {
	toolMods = {},
	stashToolMods = {},
	foodToolMods = {},
}
ToolManager.__index = ToolManager

function ToolManager:init()
	self:addCons()
end

function ToolManager:addCons() end

function ToolManager:addTool(data)
	local tool = data["tool"]
	local toolName = data["toolName"]
	local toolClass = data["toolClass"]

	local toolScriptDirectory = game.ReplicatedStorage.ClientTools:FindFirstChild(toolClass .. "Local")
	if not toolScriptDirectory then
		toolScriptDirectory = game.ReplicatedStorage.ClientTools.BaseToolLocal
	end

	local ToolModule = require(toolScriptDirectory)
	local toolMod = ToolModule.new(tool, {
		toolName = toolName,
		toolClass = toolClass,
	})
	toolMod:init()
	self.toolMods[toolName] = toolMod
end

function ToolManager:getEquippedToolMod()
	for _, toolMod in pairs(self.toolMods) do
		if toolMod.equipped then
			return toolMod
		end
	end
end

function ToolManager:addStashTool(data)
	local tool = data["tool"]
	local toolName = data["toolName"]

	local toolScriptDirectory = game.ReplicatedStorage.ClientTools.StashToolLocal

	local ToolModule = require(toolScriptDirectory)

	local toolMod = ToolModule.new(tool, data)
	toolMod:init()
	self.stashToolMods[toolName] = toolMod
	self.toolMods[toolName] = toolMod
end

function ToolManager:addFoodTool(data)
	local tool = data["tool"]
	local toolName = data["toolName"]

	local toolScriptDirectory = game.ReplicatedStorage.ClientTools.FoodToolLocal

	local ToolModule = require(toolScriptDirectory)

	local toolMod = ToolModule.new(tool, data)
	toolMod:init()
	self.foodToolMods[toolName] = toolMod
	self.toolMods[toolName] = toolMod
end

function ToolManager:removeToolMod(toolName)
	self.toolMods[toolName] = nil
	self.stashToolMods[toolName] = nil
	self.foodToolMods[toolName] = nil
end

ToolManager:init()

return ToolManager
