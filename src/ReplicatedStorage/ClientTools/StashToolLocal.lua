local player = game.Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerGui = player:WaitForChild("PlayerGui")

local ClientMod = require(playerScripts:WaitForChild("ClientMod"))

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local MapInfo = require(game.ReplicatedStorage.MapInfo)

local BaseTool = require(game.ReplicatedStorage.ClientTools.BaseToolLocal)

local StashTool = {}
StashTool.__index = StashTool
setmetatable(StashTool, { __index = BaseTool })

function StashTool.new(tool, data)
	local self = BaseTool.new(tool, data)

	setmetatable(self, StashTool)
	return self
end

function StashTool:init()
	BaseTool.init(self)
end

function StashTool:onEquip()
	BaseTool.onEquip(self)
	ClientMod.placeManager:refreshStashTool()
	ClientMod.placeManager:refreshAllPrompts()
end

function StashTool:onUnequip()
	BaseTool.onUnequip(self)
	ClientMod.placeManager:refreshStashTool()
	ClientMod.placeManager:refreshAllPrompts()
end

function StashTool:onActivate()
	BaseTool.onActivate(self)
	if self.race == "crate" then
		ClientMod:FireServer("tryPlaceCrate", {
			toolName = self.toolName,
		})
	end
end

function StashTool:destroy()
	BaseTool.destroy(self)
end

return StashTool
