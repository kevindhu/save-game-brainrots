local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local BaseTool = require(game.ServerScriptService.Tools.BaseTool)

local MegaScythe = {}
MegaScythe.__index = MegaScythe
setmetatable(MegaScythe, { __index = BaseTool })

local SWING_ID = 109319432298408

function MegaScythe.new(user, tool, data)
	local self = BaseTool.new(user, tool, data)

	self.flingExpiree = 0

	setmetatable(self, MegaScythe)
	return self
end

function MegaScythe:init()
	BaseTool.init(self)
end

function MegaScythe:onEquip()
	local rig = self.user.rig

	if not self.track then
		local animator = rig.Humanoid.Animator
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://" .. SWING_ID
		self.track = animator:LoadAnimation(animation)
	end
end

function MegaScythe:onActivate()
	self:doBatHit()
end

return MegaScythe
