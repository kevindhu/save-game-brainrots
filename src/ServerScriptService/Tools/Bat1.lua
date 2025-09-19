local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local BaseTool = require(game.ServerScriptService.Tools.BaseTool)

local Bat = {}
Bat.__index = Bat
setmetatable(Bat, { __index = BaseTool })

local SWING_ID = 90567855405019

function Bat.new(user, tool, data)
	local self = BaseTool.new(user, tool, data)

	self.flingExpiree = 0

	setmetatable(self, Bat)
	return self
end

function Bat:init()
	BaseTool.init(self)
end

function Bat:onEquip()
	local rig = self.user.rig

	if not self.track then
		local animator = rig.Humanoid.Animator
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://" .. SWING_ID
		self.track = animator:LoadAnimation(animation)
	end
end

function Bat:onActivate()
	self:doBatHit()
end

return Bat
