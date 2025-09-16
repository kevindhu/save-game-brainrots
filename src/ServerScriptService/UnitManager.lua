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

	routine(function()
		self:addTestUnits()
	end)
end

function UnitManager:addTestUnits()
	while true do
		self:addUnit({
			unitClass = "Unit1",
		})
		wait(1)
	end
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
	local unitStartFrame = plotManager.unitStartPart.CFrame

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

function UnitManager:sync(otherUser)
	for _, unit in pairs(self.units) do
		unit:sync(otherUser)
	end
end

function UnitManager:destroy()
	for _, unit in pairs(self.units) do
		unit:destroy()
	end
	self.units = {}
end

function UnitManager:saveState()
	local managerData = {}

	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

return UnitManager
