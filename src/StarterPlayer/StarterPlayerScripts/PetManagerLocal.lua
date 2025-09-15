local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetInfo = require(game.ReplicatedStorage.PetInfo)

local Pet = require(playerScripts.PetLocal)

local PetManager = {}
PetManager.__index = PetManager

function PetManager:init() end

function PetManager:newPet(data)
	local petName = data.petName
	if ClientMod.pets[petName] then
		return
	end

	local pet = Pet.new(data)
	pet:init()
	ClientMod.pets[petName] = pet

	-- if pet.userName == player.Name then
	-- 	ClientMod.petChooseManager:refreshAllPetMods()
	-- end

	routine(function()
		ClientMod.placeManager:refreshAllPrompts()
		wait(0.1)
		ClientMod.placeManager:refreshAllPrompts()
	end)
end

function PetManager:updatePetAction(data)
	local petName = data["petName"]
	local pet = ClientMod.pets[petName]
	if not pet then
		return
	end
	pet:updateActionFromServer(data)
end

function PetManager:updatePetData(data)
	local petName = data["petName"]
	local pet = ClientMod.pets[petName]
	if not pet then
		warn("!!! NO PET FOUND TO UPDATE DATA: ", petName)
		return
	end

	pet:updateData(data)

	-- try update the best pet for this plot
	self:updateBestPetForPlot(pet.plotName)
end

function PetManager:updateBestPetForPlot(plotName)
	local petList = {}
	for _, pet in pairs(ClientMod.pets) do
		if pet.plotName ~= plotName then
			continue
		end
		table.insert(petList, pet)
	end
	table.sort(petList, function(a, b)
		return a.totalStrength > b.totalStrength
	end)

	local bestPet = petList[1]
	ClientMod.plotManager:addBestPetSign(bestPet)
end

function PetManager:updatePetFrame(data)
	local petName = data["petName"]
	local pet = ClientMod.pets[petName]
	if not pet then
		return
	end

	pet:updateFrameFromServer(data)
end

function PetManager:updatePetFrames(petParts, petCFrames)
	workspace:BulkMoveTo(petParts, petCFrames, Enum.BulkMoveMode.FireCFrameChanged)
end

function PetManager:addRewardCoins(data)
	local petName = data["petName"]

	local pet = ClientMod.pets[petName]
	if not pet then
		return
	end
	pet:addRewardCoins(data)
end

function PetManager:removePet(data)
	local petName = data["petName"]
	local pet = ClientMod.pets[petName]
	if not pet then
		return
	end
	pet:destroy()

	ClientMod.pets[petName] = nil

	-- if pet.userName == player.Name then
	-- 	ClientMod.petChooseManager:refreshAllPetMods()
	-- end
end

PetManager:init()

return PetManager
