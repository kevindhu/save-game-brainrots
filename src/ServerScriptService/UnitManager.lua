local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local Unit = require(game.ServerScriptService.Unit)

local UnitManager = {}
UnitManager.__index = UnitManager

function UnitManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.units = {}

	setmetatable(u, UnitManager)
	return u
end

function UnitManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	routine(function()
		wait(1)
		self.initialized = true
	end)
end

function UnitManager:getClosestUnit(petPos)
	local closestDist = math.huge
	local closestUnit = nil
	for _, unit in pairs(self.units) do
		local dist = (unit.currFrame.Position - petPos).Magnitude
		if dist < closestDist then
			closestDist = dist
			closestUnit = unit
		end
	end
	return closestUnit
end

function UnitManager:tick(timeRatio)
	for _, unit in pairs(self.units) do
		unit:tick(timeRatio)
	end
end

function UnitManager:getRandomFrame()
	local plotManager = self.user.home.plotManager
	local floorPart = plotManager.floorPart

	local middleRatio = 0.8

	local xOffset = math.random(-floorPart.Size.X / 2 * middleRatio, floorPart.Size.X / 2 * middleRatio)
	local zOffset = math.random(-floorPart.Size.Z / 2 * middleRatio, floorPart.Size.Z / 2 * middleRatio)

	local hOffset = floorPart.Size.Y * 0.5
	local randomFrame = floorPart.CFrame
		* CFrame.new(xOffset, hOffset, zOffset)
		* CFrame.Angles(0, math.rad(math.random(0, 4) * 90), 0)

	return randomFrame
end

function UnitManager:getUnitStartFrame()
	local plotManager = self.user.home.plotManager
	local unitStartPart = plotManager.unitStartPart

	local unitStartFrame = unitStartPart.CFrame
		* CFrame.new(0, 0, Common.randomBetween(-30, 30))
		* CFrame.Angles(0, math.rad(-270), 0)

	return unitStartFrame
end

function UnitManager:addUnit(unitData)
	if not unitData["unitName"] then
		unitData["unitName"] = "UNIT_" .. Common.getGUID()
	end

	unitData["firstFrame"] = self:getUnitStartFrame()

	local unit = Unit.new(self, unitData)
	unit:init()
	self.units[unitData["unitName"]] = unit
end

function UnitManager:clearAllWaveUnits(waveMod)
	for _, unit in pairs(self.units) do
		if unit.capturedSavedPet then
			continue
		end

		if unit.waveMod == waveMod then
			unit:destroyImmediately()
		end
	end
end

function UnitManager:sync(otherUser)
	for _, unit in pairs(self.units) do
		unit:sync(otherUser)
	end
end

function UnitManager:destroy()
	for _, unit in pairs(self.units) do
		unit:destroyImmediately()
	end
	self.units = {}
end

function UnitManager:saveState()
	local managerData = {}

	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

return UnitManager
