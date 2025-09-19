local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local UnitInfo = require(game.ReplicatedStorage.UnitInfo)

local Unit = require(playerScripts.UnitLocal)

local UnitManager = {}
UnitManager.__index = UnitManager

function UnitManager:init() end

function UnitManager:newUnit(data)
	local unitName = data.unitName
	if ClientMod.units[unitName] then
		return
	end

	-- print("!! NEW UNIT: ", data)

	local unit = Unit.new(data)
	unit:init()
	ClientMod.units[unitName] = unit
end

function UnitManager:updateUnitAction(data)
	local unitName = data["unitName"]
	local unit = ClientMod.units[unitName]
	if not unit then
		return
	end
	unit:updateActionFromServer(data)
end

function UnitManager:updateUnitData(data)
	local unitName = data["unitName"]
	local unit = ClientMod.units[unitName]
	if not unit then
		warn("!!! NO PET FOUND TO UPDATE DATA: ", unitName)
		return
	end

	unit:updateData(data)
end

function UnitManager:updateUnitFrame(data)
	local unitName = data["unitName"]
	local unit = ClientMod.units[unitName]
	if not unit then
		return
	end

	unit:updateFrameFromServer(data)
end

function UnitManager:removeUnit(data)
	local unitName = data["unitName"]
	local unit = ClientMod.units[unitName]
	if not unit then
		return
	end
	unit:destroy(data)
end

function UnitManager:bulkUpdateUnitDamage(data)
	local bulkDamageMods = data["bulkDamageMods"]
	for unitName, damageList in pairs(bulkDamageMods) do
		local unit = ClientMod.units[unitName]
		if not unit then
			continue
		end

		local damageMod = {
			damage = damageList[1],
			newHealth = damageList[2],
		}
		unit:addDamageFromServer(damageMod)
	end
end

function UnitManager:updateUnitFrames(unitParts, unitCFrames)
	workspace:BulkMoveTo(unitParts, unitCFrames, Enum.BulkMoveMode.FireCFrameChanged)
end

function UnitManager:unitCapturedSavedPet(data)
	local unitName = data["unitName"]
	local unit = ClientMod.units[unitName]
	if not unit then
		return
	end
	unit:captureSavePet(data)
end

function UnitManager:tickRender(timeRatio)
	local unitParts = {}
	local unitCFrames = {}
	for _, unit in pairs(ClientMod.units) do
		unit:tickRender(timeRatio)

		if unit.destroyed then
			continue
		end

		table.insert(unitParts, unit.rig.PrimaryPart)
		table.insert(unitCFrames, unit.rigFrame)
	end

	self:updateUnitFrames(unitParts, unitCFrames)
end

UnitManager:init()

return UnitManager
