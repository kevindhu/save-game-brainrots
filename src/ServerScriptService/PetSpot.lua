local ServerMod = require(script.Parent.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

-- local PetSpotInfo = require(game.ReplicatedStorage.PetSpotInfo)

local PetSpot = {}
PetSpot.__index = PetSpot

function PetSpot.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.eventsList = {}

	setmetatable(u, PetSpot)
	return u
end

function PetSpot:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:initModel()
	self.standPart = self.model:WaitForChild("StandPart")

	self.baseFrame = self.standPart.CFrame * CFrame.new(0, self.standPart.Size.Y * 0.5, 0)
	self.currFrame = self.baseFrame

	self:initAllEvents()

	for _, otherUser in pairs(ServerMod.users) do
		self:sync(otherUser)
	end
end

function PetSpot:initAllEvents()
	self:createEvent("attack", "ATTACK")
end

function PetSpot:createEvent(key, alias)
	local event = Instance.new("RemoteEvent")
	event.Name = self.petSpotName .. "_" .. alias .. "EVENT"
	event.Parent = game.ReplicatedStorage.PetEvents
	self[key .. "Event"] = event
	table.insert(self.eventsList, event)
end

function PetSpot:initModel()
	local plotModel = self.user.home.plotManager.model
	local model = plotModel:FindFirstChild("PetSpot" .. self.index)
	if not model then
		warn("!! PET SPOT MODEL NOT FOUND: ", self.petSpotName, self.index)
		return
	end

	self.model = model
end

function PetSpot:tick(timeRatio)
	if not self.petData then
		return
	end

	self:tickAttack(timeRatio)
end

function PetSpot:tickAttack(timeRatio)
	if not self.petData then
		return
	end

	local closestDist = math.huge
	local targetUnit = nil

	local currPosition = self.currFrame.Position

	for _, unit in pairs(self.user.home.unitManager.units) do
		local dist = Common.getHorizontalDist(currPosition, unit.currFrame.p)
		if dist < closestDist then
			closestDist = dist
			targetUnit = unit
		end
	end

	if not targetUnit then
		return
	end

	if self.attackExpiree and self.attackExpiree > ServerMod.step then
		return
	end
	self.attackExpiree = ServerMod.step + 60 * 0.2 -- 0.5

	local damage = math.random(200, 300)

	targetUnit:updateHealth(-damage, self)

	self.user.home.damageManager:addDamage(damage)

	self.attackEvent:FireAllClients(targetUnit.unitName, damage, targetUnit.health)
end

function PetSpot:sync(otherUser)
	ServerMod:FireClient(otherUser.player, "newPetSpot", {
		petSpotName = self.petSpotName,
		index = self.index,

		petData = self.petData,

		baseFrame = self.baseFrame,
		currFrame = self.currFrame,

		userName = self.user.name,
	})
end

function PetSpot:occupyWithPet(petData)
	self.petData = petData

	print("OCCUPYING PET SPOT: ", self.petSpotName, self.petData)

	self:sendData()
end

function PetSpot:sendData()
	ServerMod:FireClient(self.user.player, "updatePetSpot", {
		petSpotName = self.petSpotName,
		petData = self.petData,

		attackSpeedRatio = 2,
	})
end

function PetSpot:clearPet()
	self.petData = nil

	self:sendData()
end

function PetSpot:getSaveData()
	local petData = self.petData
	if not petData then
		return nil
	end

	return petData
end

function PetSpot:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	for _, event in pairs(self.eventsList) do
		event:Destroy()
	end
	self.eventsList = {}

	self.petData = nil

	self.owner.petSpots[self.petSpotName] = nil

	ServerMod:FireAllClients("removePetSpot", {
		petSpotName = self.petSpotName,
	})
end

return PetSpot
