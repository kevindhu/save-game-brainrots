local ServerMod = require(game.ServerScriptService.ServerMod)

-- local SetInfo = require(game.ReplicatedStorage.SetInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local DamageManager = {}
DamageManager.__index = DamageManager

function DamageManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.dpsTimer = 1
	u.dpsWindowSeconds = 5 -- Track DPS over x seconds

	u.currDamageList = {} -- Queue to store damage for each second
	u.totalDamage = 0

	u.dpsStep = 0
	u.lastDPS = 0

	setmetatable(u, DamageManager)
	return u
end

function DamageManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	-- Initialize damage list with zeros
	for i = 1, self.dpsWindowSeconds do
		table.insert(self.currDamageList, 0)
	end
end

function DamageManager:tick()
	self:tickDPS()
end

function DamageManager:addDamage(damage)
	-- Add to current second's damage
	self.currDamageList[#self.currDamageList] += damage
	self.totalDamage += damage
end

function DamageManager:tickDPS()
	if not self.dpsStep or self.dpsStep > ServerMod.step then
		return
	end

	self.dpsStep = ServerMod.step + 60 * self.dpsTimer

	-- Calculate total damage over the window
	local windowDamage = 0
	for _, damage in ipairs(self.currDamageList) do
		windowDamage += damage
	end

	-- Calculate DPS over the window
	local newDPS = windowDamage / self.dpsWindowSeconds

	-- Rotate the damage list (remove oldest, add new entry)
	table.remove(self.currDamageList, 1)
	table.insert(self.currDamageList, 0)

	-- Don't send to client if the DPS is 0 twice in a row
	if newDPS == 0 and self.lastDPS == 0 then
		-- reset the total damage too
		self.totalDamage = 0
		return
	end
	ServerMod:FireClient(self.user.player, "updateDPS", {
		dps = newDPS,
		totalDamage = self.totalDamage,
	})
	self.lastDPS = newDPS
end

function DamageManager:saveState()
	local managerData = {}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

return DamageManager
