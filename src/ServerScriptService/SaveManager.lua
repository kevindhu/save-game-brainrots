local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetRollInfo = require(game.ReplicatedStorage.PetRollInfo)
local MutationInfo = require(game.ReplicatedStorage.MutationInfo)

local PetInfo = require(game.ReplicatedStorage.PetInfo)
local WaveInfo = require(game.ReplicatedStorage.WaveInfo)

local SaveManager = {}
SaveManager.__index = SaveManager

function SaveManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.waveMods = {}

	u.playing = false

	setmetatable(u, SaveManager)
	return u
end

function SaveManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	routine(function()
		wait(1.5)
		-- self:startNewWaveMod()
		self:sendPlaying()

		self.initialized = true
	end)
end

function SaveManager:initSaveModel(saveModel)
	local topPart = saveModel.TopPart
	self.saveBaseFrame = topPart.CFrame * CFrame.new(0, topPart.Size.Y * 0.5, 0)
end

function SaveManager:startNewWaveMod()
	local probManager = self.user.home.probManager
	local petClass = probManager:generatePetClass()
	local mutationClass = probManager:generateMutationClass()

	-- self.user.home.indexManager:unlockPet(petClass, mutationClass)

	local petData = {
		itemName = "STASHPET_" .. Common.getGUID(),
		itemClass = petClass,
		race = "pet",

		petClass = petClass,
		mutationClass = mutationClass,

		-- unit metadata
		creationTimestamp = os.time(),
	}
	self.user.home.petManager:fillPetDataWithDefaults(petData)

	local petStats = PetInfo:getMeta(petClass)
	local musicRating = petStats["rating"]

	if not Common.listContains({
		"Secret",
		"Mythic",
	}, musicRating) then
		musicRating = "Default"
	end

	ServerMod:FireClient(self.user.player, "setMusicRating", {
		rating = musicRating,
	})

	self:initWaveMod(petData)
end

function SaveManager:initWaveMod(petData)
	local petClass = petData["petClass"]

	local petStats = PetInfo:getMeta(petClass)
	local rating = petStats["rating"]

	local totalWaveData = WaveInfo["ratingWaveMap"][rating]

	-- print("!! TOTAL WAVE DATA: ", rating, totalWaveData)

	local totalUnitCount = 0
	for _, waveData in pairs(totalWaveData) do
		totalUnitCount += waveData["count"]
	end

	local waveName = "WAVE_" .. Common.getGUID()

	local waveMod = {
		waveName = waveName,

		plotName = self.user.home.plotManager.plotName,
		userName = self.user.name,

		rating = rating,
		totalWaveData = totalWaveData,
		killedUnitCount = 0,
		totalUnitCount = totalUnitCount,

		petData = petData,
	}
	self.waveMods[waveName] = waveMod

	self.currWaveMod = waveMod

	self:sendWaveMod(waveMod)

	routine(function()
		for _, waveData in pairs(totalWaveData) do
			local unitClass = waveData["unitClass"]
			local count = waveData["count"]
			local spawnTimer = waveData["spawnTimer"]

			if waveMod["destroyed"] or self.user.destroyed then
				return
			end

			for i = 1, count do
				if waveMod["destroyed"] or self.user.destroyed then
					return
				end

				self:addWaveUnit(waveMod, unitClass)
				wait(spawnTimer / self.user.home.speedManager:getSpeed())
			end
		end
	end)
end

function SaveManager:addWaveUnit(waveMod, unitClass)
	local unitManager = self.user.home.unitManager
	unitManager:addUnit({
		unitClass = unitClass,
		waveMod = waveMod,
	})
end

function SaveManager:killUnitFromWave(waveMod, unit)
	waveMod["killedUnitCount"] += 1

	self:updateWaveModData(waveMod)

	if waveMod["killedUnitCount"] >= waveMod["totalUnitCount"] then
		self:completeWaveMod(waveMod)
	end
end

function SaveManager:tryTogglePlay(data)
	if self.tryTogglePlayExpiree and self.tryTogglePlayExpiree > ServerMod.step then
		self.user:notifyError("Clicking too fast")
		return
	end
	self.tryTogglePlayExpiree = ServerMod.step + 60 * 0.5

	self.playing = not self.playing

	-- print("TOGGLE PLAY: ", self.playing)

	if self.playing then
		self.startNewWaveExpiree = ServerMod.step + 60 * 0.5
	else
		if self.currWaveMod then
			self:failWaveMod(self.currWaveMod, nil)
		end
	end

	self:sendPlaying()
end

function SaveManager:sendPlaying()
	ServerMod:FireClient(self.user.player, "updatePlaying", {
		playing = self.playing,
	})
end

function SaveManager:completeWaveMod(waveMod)
	if waveMod["destroyed"] then
		return
	end
	waveMod["destroyed"] = true

	-- print("COMPLETED WAVE MOD: ", waveMod)

	local petData = waveMod["petData"]
	self.user.home.indexManager:unlockPet(petData["petClass"], petData["mutationClass"])

	-- ServerMod:FireClient(self.user.player, "shootFireworks", {
	-- 	launchCFrame = self.user.currFrame,
	-- })

	ServerMod:FireAllClients("completeWaveMod", {
		waveName = waveMod["waveName"],
		userName = self.user.name,

		petClass = petData["petClass"],
		mutationClass = petData["mutationClass"],

		pos = self.saveBaseFrame.Position,
	})

	petData["forceBottom"] = false
	petData["noClick"] = true

	local itemStash = self.user.home.itemStash
	itemStash:addItemMod(petData)

	self.user.home.unitManager:clearAllWaveUnits(waveMod)

	local successTimer = 1.5 --3 -- 0.5
	successTimer = successTimer / self.user.home.speedManager:getSpeed()
	self.startNewWaveExpiree = ServerMod.step + 60 * successTimer

	self.waveMods[waveMod["waveName"]] = nil
end

function SaveManager:failWaveMod(waveMod, unit)
	if waveMod["destroyed"] then
		return
	end
	waveMod["destroyed"] = true

	-- print("FAILING WAVE MOD: ", waveMod["userName"])

	self.user.home.unitManager:clearAllWaveUnits(waveMod)

	local petData = waveMod["petData"]

	local unitName = nil
	if unit then
		unitName = unit.unitName
	end

	ServerMod:FireAllClients("failWaveMod", {
		unitName = unitName,
		userName = waveMod["userName"],
		petData = petData,
	})

	local failTimer = 1.5
	self.startNewWaveExpiree = ServerMod.step + 60 * failTimer

	self.waveMods[waveMod["waveName"]] = nil
end

function SaveManager:tick()
	if not self.initialized then
		return
	end
	if self.user.destroyed then
		return
	end

	if not self.playing then
		return
	end

	if len(self.waveMods) > 0 then
		return
	end

	if self.startNewWaveExpiree and self.startNewWaveExpiree > ServerMod.step then
		return
	end
	self:startNewWaveMod()
end

function SaveManager:sendWaveMod(waveMod)
	ServerMod:FireAllClients("addWaveMod", {
		waveMod = waveMod,
		saveBaseFrame = self.saveBaseFrame,
	})
end

function SaveManager:updateWaveModData(waveMod)
	ServerMod:FireAllClients("updateWaveModData", {
		userName = self.user.name,
		waveName = waveMod["waveName"],

		killedUnitCount = waveMod["killedUnitCount"],
		totalUnitCount = waveMod["totalUnitCount"],
	})
end

function SaveManager:saveState()
	local managerData = {}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function SaveManager:destroy()
	local currWaveMod = self.currWaveMod
	if currWaveMod then
		self:failWaveMod(currWaveMod, nil)
	end
end

return SaveManager
