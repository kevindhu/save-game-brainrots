local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local BaseTool = require(game.ServerScriptService.Tools.BaseTool)

local Hammer = {}
Hammer.__index = Hammer
setmetatable(Hammer, { __index = BaseTool })

function Hammer.new(user, tool, data)
	local self = BaseTool.new(user, tool, data)

	setmetatable(self, Hammer)
	return self
end

function Hammer:init()
	BaseTool.init(self)
end

function Hammer:onEquip() end

function Hammer:onActivate() end

return Hammer
