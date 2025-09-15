local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local Egg = require(game.ServerScriptService.Egg)

local ZoneInfo = require(game.ReplicatedStorage.ZoneInfo)

local ZoneManager = {}
ZoneManager.__index = ZoneManager

function ZoneManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.currZoneClass = "Zone1"
	u.unlockedZoneMap = {}

	setmetatable(u, ZoneManager)
	return u
end

function ZoneManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	if self.isNew then
		self:unlockZone("Zone1")
		self:tryChooseZone({
			zoneClass = "Zone1",
		})
	else
		self:tryChooseZone({
			zoneClass = self.currZoneClass,
		})
	end

	routine(function()
		wait(0.5)
		self:sendData()
		self.initialized = true
	end)
end

function ZoneManager:sendData()
	local data = {
		currZoneClass = self.currZoneClass,
		unlockedZoneMap = self.unlockedZoneMap,
	}

	ServerMod:FireClient(self.user.player, "updateAllZoneData", data)
end

function ZoneManager:getCoinMultiplier()
	local zoneStats = ZoneInfo:getMeta(self.currZoneClass)
	return zoneStats["coinMultiplierRatio"]
end

function ZoneManager:tryBuyZone(data)
	local zoneClass = data["zoneClass"]
	local withRobux = data["withRobux"]

	if self.unlockedZoneMap[zoneClass] then
		self.user:notifyError("You already own this zone")
		return
	end

	if withRobux then
		self.user.home.shopManager:tryBuyProduct({
			productClass = zoneClass,
		})
		return
	end

	local zoneStats = ZoneInfo:getMeta(zoneClass)
	local unlockPrice = zoneStats["unlockPrice"]

	local totalCoinsCount = self.user.home.itemStash:getItemCount({
		itemName = "Coins",
	})

	if totalCoinsCount < unlockPrice then
		self.user:notifyError("Not Enough Coins")
		return
	end

	self.user.home.itemStash:updateItemCount({
		itemName = "Coins",
		count = -unlockPrice,
	})

	-- self.user:notifySuccess("Unlocked Zone: " .. zoneStats["alias"])

	ServerMod:FireClient(self.user.player, "newSoundMod", {
		soundClass = "Notice",
	})

	self:unlockZone(zoneClass)
	self:tryChooseZone({
		zoneClass = zoneClass,
	})
end

function ZoneManager:unlockZone(zoneClass)
	self.unlockedZoneMap[zoneClass] = true
	self:sendData()
end

function ZoneManager:tryChooseZone(data)
	local newZoneClass = data["zoneClass"]

	if self.tryChooseExpiree and self.tryChooseExpiree > ServerMod.step then
		self.user:notifyError("You are doing that too fast")
		return
	end
	self.tryChooseExpiree = ServerMod.step + 60 * 1

	local oldZoneClass = self.currZoneClass

	if not self.unlockedZoneMap[newZoneClass] then
		self.user:notifyError("You don't own this zone")
		return
	end

	self.currZoneClass = newZoneClass

	for _, gemSpawner in pairs(self.user.home.gemManager.gemSpawners) do
		gemSpawner:switchZone(oldZoneClass, newZoneClass)
	end

	self:sendData()

	print("CHOOSING ZONE: ", newZoneClass)

	if self.zoneMachine then
		self.zoneMachine:destroy()
	end

	local zoneMachine = game.ReplicatedStorage.Assets[newZoneClass .. "Machine"]:Clone()

	for _, child in pairs(zoneMachine:GetDescendants()) do
		if child:IsA("BasePart") then
			child.Anchored = true
		end
	end

	local basePart = zoneMachine.PrimaryPart

	basePart.Transparency = 1

	local machinePart = self.user.home.plotManager.machinePart

	local hOffset = -machinePart.Size.Y / 2 + zoneMachine.PrimaryPart.Size.Y / 2
	zoneMachine.Parent = self.user.home.plotManager.model
	zoneMachine:SetPrimaryPartCFrame(machinePart.CFrame * CFrame.new(0, hOffset, 0))
	self.zoneMachine = zoneMachine
end

function ZoneManager:saveState()
	local managerData = {
		currZoneClass = self.currZoneClass,
		unlockedZoneMap = self.unlockedZoneMap,
	}

	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function ZoneManager:destroy()
	if self.zoneMachine then
		self.zoneMachine:Destroy()
	end
end

return ZoneManager
