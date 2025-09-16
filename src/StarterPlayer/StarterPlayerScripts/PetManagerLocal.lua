local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetInfo = require(game.ReplicatedStorage.PetInfo)

local PetSpot = require(playerScripts.PetSpotLocal)

local PetManager = {}
PetManager.__index = PetManager

function PetManager:init() end

function PetManager:newPetSpot(data)
	local petSpotName = data.petSpotName
	if ClientMod.petSpots[petSpotName] then
		return
	end

	local petSpot = PetSpot.new(data)
	petSpot:init()
	ClientMod.petSpots[petSpotName] = petSpot
end

function PetManager:updatePetSpot(data)
	local petSpotName = data["petSpotName"]
	local petSpot = ClientMod.petSpots[petSpotName]
	if not petSpot then
		return
	end

	petSpot:updateData(data)
end

function PetManager:removePetSpot(data)
	local petSpotName = data["petSpotName"]
	local petSpot = ClientMod.petSpots[petSpotName]
	if not petSpot then
		return
	end
	petSpot:destroy()

	ClientMod.petSpots[petSpotName] = nil
end

function PetManager:tickRender(timeRatio)
	local petParts = {}
	local petCFrames = {}

	for _, petSpot in pairs(ClientMod.petSpots) do
		petSpot:tickRender(timeRatio)
		if not petSpot.rig or not petSpot.rig.PrimaryPart then
			continue
		end

		table.insert(petParts, petSpot.rig.PrimaryPart)
		table.insert(petCFrames, petSpot.rigFrame)
	end
	self:updatePetSpotFrames(petParts, petCFrames)
end

function PetManager:updatePetSpotFrames(petParts, petCFrames)
	if len(petParts) == 0 then
		return
	end

	workspace:BulkMoveTo(petParts, petCFrames, Enum.BulkMoveMode.FireCFrameChanged)
end

PetManager:init()

return PetManager
