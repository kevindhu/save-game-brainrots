local ServerMod = require(game.ServerScriptService.ServerMod)

local TutInfo = require(game.ReplicatedStorage.TutInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local CheatManager = {}
CheatManager.__index = CheatManager

function CheatManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.cheatCount = 0

	setmetatable(u, CheatManager)
	return u
end

function CheatManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end
end

function CheatManager:tick(timeRatio)
	self:tickCheckTeleport(timeRatio)
	self:tickCheatCountReset()
	self:tickKickIfCheating(timeRatio)
end

function CheatManager:updateWalkSpeed(data)
	local clientWalkSpeed = data["walkSpeed"]
	if not tonumber(clientWalkSpeed) then
		return
	end

	local humanoid = self.user.humanoid
	if not humanoid then
		return
	end

	local assignedWalkSpeed = self.user:getWalkspeed()
	local walkSpeedDiff = math.abs(clientWalkSpeed - assignedWalkSpeed)

	if walkSpeedDiff > 1 then
		self.user:refreshWalkspeed()
		-- print("WALKSPEED IS NOT MATCHING: ", clientWalkSpeed, assignedWalkSpeed, self.user.name)
		self.cheatCount += 1
	end
end

function CheatManager:tickCheckTeleport(timeRatio)
	local oldCurrFrame = self.validCurrFrame

	local rootPart = self.user.rootPart

	local newFrame = rootPart.CFrame

	if not oldCurrFrame then
		self:setValidCurrFrame(newFrame)
		return
	end

	-- add teleport count if magnitude > 4
	local oldFrame = oldCurrFrame
	local magnitude = (newFrame.p - oldFrame.p).Magnitude
	if timeRatio > 1 then
		magnitude = magnitude / timeRatio
	end

	if magnitude < 5.5 then
		self:setValidCurrFrame(newFrame)
		return
	end

	if self.noCheatExpiree and self.noCheatExpiree > ServerMod.step and magnitude < 12 then
		-- warn("DETECTED BUT NOT CHEATING: ", self.user.name, magnitude)
		self:setValidCurrFrame(newFrame)
		return
	end

	-- print("GOT MAGNITUDE: ", magnitude, self.user.name)

	-- self:tryDrawLine(oldCurrFrame, newFrame)

	self:teleportBack(oldCurrFrame, newFrame)
end

function CheatManager:tryDrawLine(oldFrame, newFrame)
	Common.createTestLine(oldFrame.Position, newFrame.Position, 10, Color3.fromRGB(255, 0, 0))
end

function CheatManager:setValidCurrFrame(newFrame)
	self.validCurrFrame = newFrame
end

function CheatManager:tickCheatCountReset()
	if self.checkCheatCountExpiree and self.checkCheatCountExpiree > os.time() then
		return
	end
	-- every 2 minutes, reset cheat count
	self.checkCheatCountExpiree = os.time() + 60 * 2

	self.cheatCount = 0
end

function CheatManager:checkPullingAnyUnits()
	for _, unit in pairs(ServerMod.unitManager.units) do
		if unit.ropeMods[self.user.name] then
			return true
		end
	end
	return false
end

function CheatManager:teleportBack(oldCurrFrame, newFrame)
	self.cheatExpiree = ServerMod.step + 60 * 2

	self.cheatCount += 1

	-- print("CHEAT COUNT: ", self.cheatCount, self.user.name)

	if not self:checkPullingAnyUnits() then
		self:setValidCurrFrame(newFrame)
		return
	end

	local rootPart = self.user.rootPart
	rootPart.CFrame = oldCurrFrame
end

function CheatManager:tickKickIfCheating()
	if self.cheatCount > 100 then
		-- give ambiguous kick message
		self.user:kick("Something went wrong. Please rejoin the game")
	end
end

return CheatManager
