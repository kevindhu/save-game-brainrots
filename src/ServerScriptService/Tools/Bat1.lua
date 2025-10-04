local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local BaseTool = require(game.ServerScriptService.Tools.BaseTool)

local Bat = {}
Bat.__index = Bat
setmetatable(Bat, { __index = BaseTool })

function Bat.new(user, tool, data)
	local self = BaseTool.new(user, tool, data)

	self.isTickable = true

	self.swingAnimationId = 90567855405019
	self.batSwingCooldown = 0.45 -- 0.2

	self.batDamage = 70 -- 1000

	setmetatable(self, Bat)
	return self
end

function Bat:init()
	BaseTool.init(self)
end

function Bat:tick()
	self:tryBatHit()
end

function Bat:tryBatHit()
	-- print("TRY BAT HIT")

	if not self.user.rig then
		return
	end
	if not self.equipped then
		return
	end

	local closestUnitDistance = math.huge
	for _, unit in pairs(self.user.home.unitManager.units) do
		local dist = (unit.currFrame.Position - self.user.rig.HumanoidRootPart.Position).Magnitude
		if dist < closestUnitDistance then
			closestUnitDistance = dist
		end
	end

	if closestUnitDistance < 20 then
		self:doBatHit()
	end
end

function Bat:onEquip()
	BaseTool.onEquip(self)

	local rig = self.user.rig

	if not self.track then
		local animator = rig.Humanoid.Animator
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://" .. self.swingAnimationId
		self.track = animator:LoadAnimation(animation)
	end
end

function Bat:onActivate()
	self:doBatHit()
end

return Bat
