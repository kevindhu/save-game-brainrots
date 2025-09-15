local player = game.Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerGui = player:WaitForChild("PlayerGui")

local ClientMod = require(playerScripts:WaitForChild("ClientMod"))

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local MapInfo = require(game.ReplicatedStorage.MapInfo)

local BaseTool = require(game.ReplicatedStorage.ClientTools.BaseToolLocal)

local Hammer = {}
Hammer.__index = Hammer
setmetatable(Hammer, { __index = BaseTool })

function Hammer.new(tool, data)
	local self = BaseTool.new(tool, data)

	setmetatable(self, Hammer)
	return self
end

function Hammer:init()
	BaseTool.init(self)
end

function Hammer:onActivate() end

function Hammer:onEquip()
	ClientMod.deleteManager:toggleDelete(true)
	self.equipped = true
end

function Hammer:onUnequip()
	ClientMod.deleteManager:toggleDelete(false)
	self.equipped = false
end

return Hammer
