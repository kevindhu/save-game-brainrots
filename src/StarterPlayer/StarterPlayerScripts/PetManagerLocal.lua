local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetInfo = require(game.ReplicatedStorage.PetInfo)

local PetSpot = require(playerScripts.PetSpotLocal)

local shopGUI = playerGui:WaitForChild("ShopGUI")
local confirmUnlockModal = shopGUI.ConfirmUnlockPetSpotModal

local PetManager = {
	collectCount = 1,
}
PetManager.__index = PetManager

function PetManager:init()
	self:addConfirmModalCons()
end

function PetManager:addConfirmModalCons()
	local confirmButton = confirmUnlockModal.Confirm
	ClientMod.buttonManager:addActivateCons(confirmButton, function()
		local petSpot = self.chosenBuyPetSpot
		ClientMod:FireServer("tryUnlockPetSpot", {
			petSpotName = petSpot.petSpotName,
		})
		self:toggleConfirmUnlockModal(false)
	end)

	local cancelButton = confirmUnlockModal.Cancel
	ClientMod.buttonManager:addActivateCons(cancelButton, function()
		self:toggleConfirmUnlockModal(false)
	end)
end

function PetManager:toggleConfirmUnlockModal(newBool)
	confirmUnlockModal.Visible = newBool
end

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
		warn("!!! NO PET SPOT TO UPDATE: ", petSpotName)
		return
	end

	petSpot:updateData(data)
end

function PetManager:updatePetSpotCoins(data)
	local petSpotName = data["petSpotName"]
	local petSpot = ClientMod.petSpots[petSpotName]
	if not petSpot then
		return
	end
	petSpot:updateCoins(data)
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

function PetManager:tick()
	self:tickCollectExpiree()
end

function PetManager:tickCollectExpiree()
	if self.collectExpiree and ClientMod.step > self.collectExpiree then
		self.collectCount = 1
		self.collectExpiree = nil
	end
end

function PetManager:updatePetSpotFrames(petParts, petCFrames)
	if len(petParts) == 0 then
		return
	end

	workspace:BulkMoveTo(petParts, petCFrames, Enum.BulkMoveMode.FireCFrameChanged)
end

local COLLECT_MAX_INDEX = 20
function PetManager:getCollectSpeed()
	self.collectCount += 1
	self.collectExpiree = ClientMod.step + 60 * 2

	self.collectCount = self.collectCount % COLLECT_MAX_INDEX

	local finalSpeed = 1 + (self.collectCount / COLLECT_MAX_INDEX) * 1

	return finalSpeed
end

-- open the confirm modal
function PetManager:tryUnlockPetSpot(petSpot, coinsCost)
	confirmUnlockModal.DescriptionTitle.Text =
		string.format("Buy this platform for $%s?", Common.abbreviateNumber(coinsCost))

	self.chosenBuyPetSpot = petSpot

	self:toggleConfirmUnlockModal(true)
end

function PetManager:showPetSpotBuyModel(data)
	local petSpotName = data["petSpotName"]
	local petSpot = ClientMod.petSpots[petSpotName]
	if not petSpot then
		return
	end
	petSpot:toggleBuyModel(true)
end

function PetManager:unlockPetSpot(data)
	local petSpotName = data["petSpotName"]
	local petSpot = ClientMod.petSpots[petSpotName]
	if not petSpot then
		return
	end
	petSpot:unlock()
end

PetManager:init()

return PetManager
