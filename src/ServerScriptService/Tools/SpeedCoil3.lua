local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local BaseTool = require(game.ServerScriptService.Tools.BaseTool)

local ToolInfo = require(game.ReplicatedStorage.ToolInfo)

local SpeedCoil = {}
SpeedCoil.__index = SpeedCoil
setmetatable(SpeedCoil, { __index = BaseTool })

function SpeedCoil.new(user, tool, data)
	local self = BaseTool.new(user, tool, data)

	setmetatable(self, SpeedCoil)
	return self
end

function SpeedCoil:init()
	BaseTool.init(self)

	local toolStats = ToolInfo:getMeta(self.toolClass)
	self.coilBoostCount = toolStats["coilBoostCount"]
end

function SpeedCoil:onEquip()
	BaseTool.onEquip(self)
	self.user:refreshWalkspeed()

	ServerMod:FireAllClients("newSoundMod", {
		soundClass = "CoilStart",
		part = self.tool.Handle,
	})
end

function SpeedCoil:onUnequip()
	BaseTool.onUnequip(self)

	if self.user.destroyed or self.user.dead then
		return
	end
	self.user:refreshWalkspeed()
end

return SpeedCoil
