local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PetInfo = require(game.ReplicatedStorage.PetInfo)
local PetBalanceInfo = require(game.ReplicatedStorage.PetBalanceInfo)
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

		if self.user.home.tutManager.completedTutMods["CompleteTutorial"] then
			self:tryTogglePlay({
				newBool = true,
			})
		end

		self.initialized = true
	end)
end

function SaveManager:initSaveModel(saveModel)
	local topPart = saveModel.TopPart
	self.saveBaseFrame = topPart.CFrame * CFrame.new(0, topPart.Size.Y * 0.5, 0)
end

function SaveManager:startNewWaveMod()
	self.user.home.itemStash:tryStartBuySpeedTutorial()

	local probManager = self.user.home.probManager
	local pityManager = self.user.home.pityManager

	self.user.home.pityManager:incrementPetCount()

	local petClass = probManager:generatePetClass("None")

	if pityManager.mythicUnlocked then
		pityManager.mythicUnlocked = false
		petClass = probManager:generatePetClass("Mythic")
	elseif pityManager.legendaryUnlocked then
		pityManager.legendaryUnlocked = false
		-- print("GENERATING LEGENDARY PET CLASS")
		petClass = probManager:generatePetClass("Legendary")
	end

	-- override with tutorial petClass if not completed tutorial
	if not self.user.home.tutManager.completedTutMods["CompleteFirstWave"] then
		petClass = "CappuccinoAssassino"
	elseif not self.user.home.tutManager.completedTutMods["CompleteSecondWave"] then
		petClass = "TungTungSahur"
	end

	if self.cappucinoExpiree then
		self.cappucinoExpiree = nil
		petClass = "CappuccinoAssassino"
	end

	local chosenTutMod = self.user.home.tutManager.chosenTutMod
	if chosenTutMod then
		if
			Common.listContains({
				"GoToTimeWizard",
				"Buy2xSpeedCommon",
				"CloseTimeWizard",
				"Choose2xSpeedCommon",
			}, chosenTutMod["targetClass"])
		then
			-- petClass = "CappuccinoAssassino"
			if self.currWaveMod then
				self:failWaveMod(self.currWaveMod, nil)
			end
			return
		end
	end

	local petStats = PetInfo:getMeta(petClass)
	local rating = petStats["rating"]
	if Common.listContains({
		"Mythic",
		"Legendary",
	}, rating) then
		self.user:notifySuccess(string.format("A %s brainrot has spawned!", rating))
	end

	local mutationClass = probManager:generateMutationClass()

	-- self.user.home.indexManager:unlockPet(petClass, mutationClass)

	local petData = self.user.home.itemStash:generatePetData({
		petClass = petClass,
		mutationClass = mutationClass,
	})

	local petStats = PetInfo:getMeta(petClass)
	local musicRating = petStats["rating"]

	if not Common.listContains({
		"Legendary",
		"Mythic",
		"Secret",
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

	local ratingCount = WaveInfo["ratingCountMap"][rating]
	local fullRatingClass = rating .. math.random(ratingCount)

	local totalWaveData = WaveInfo["ratingWaveMap"][fullRatingClass]

	-- local totalWaveData = {
	-- 	{
	-- 		unitClass = "Unit1",
	-- 		count = 20,
	-- 		spawnTimer = 0.1, -- 0.5
	-- 	},
	-- 	-- {
	-- 	-- 	unitClass = "Unit4",
	-- 	-- 	count = 20,
	-- 	-- 	spawnTimer = 0.1, -- 0.5
	-- 	-- },
	-- 	-- {
	-- 	-- 	unitClass = "Unit3",
	-- 	-- 	count = 20,
	-- 	-- 	spawnTimer = 0.1, -- 0.5
	-- 	-- },
	-- }

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
	local newBool = data["newBool"]

	if self.tryTogglePlayExpiree and self.tryTogglePlayExpiree > ServerMod.step then
		self.user:notifyError("Clicking too fast")
		return
	end
	self.tryTogglePlayExpiree = ServerMod.step + 60 * 0.5

	-- if not completed tutorial, don't allow to play
	if not self.user.home.tutManager.completedTutMods["EquipBat1"] then
		self.user:notifyError("Cannot do this yet")
		return
	end
	if self.playing then
		if not self.user.home.tutManager.completedTutMods["CompleteTutorial"] then
			self.user:notifyError("Cannot do this yet")
			return
		end
	end

	self:togglePlay(newBool)
end

function SaveManager:togglePlay(newBool)
	self.playing = newBool

	if self.playing then
		self.startNewWaveExpiree = ServerMod.step + 60 * 0.5
		self.user.home.tutManager:updateTutMod({
			targetClass = "PressPlay",
			updateCount = 1,
		})
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

	petData["forceBottom"] = false
	petData["noClick"] = true

	local petStats = PetInfo:getMeta(petData["petClass"])
	local rating = petStats["rating"]

	local autoSellManager = self.user.home.autoSellManager
	local ratingMod = autoSellManager.ratingMods[rating]
	if not ratingMod["toggled"] then
		local sellPrice = PetInfo:calculateSellPrice({
			petClass = petData["petClass"],
			mutationClass = petData["mutationClass"],
		})
		self.user.home.itemStash:updateItemCount({
			itemName = "Coins",
			count = sellPrice,
		})
		-- print("SOLD PET IMMEDIATELY FOR: ", sellPrice)
	else
		self.user.home.itemStash:addItemMod(petData)
	end

	self.user.home.unitManager:clearAllWaveUnits(waveMod)

	local successTimer = 1.5 --3 -- 0.5
	successTimer = successTimer / self.user.home.speedManager:getSpeed()
	self.startNewWaveExpiree = ServerMod.step + 60 * successTimer

	self.user.home.tutManager:updateTutMod({
		targetClass = "CompleteFirstWave",
		updateCount = 1,
	})

	self.user.home.tutManager:updateTutMod({
		targetClass = "CompleteSecondWave",
		updateCount = 1,
	})

	self.waveMods[waveMod["waveName"]] = nil

	-- ServerMod:FireClient(self.user.player, "shootFireworks", {
	-- 	launchCFrame = self.user.currFrame,
	-- })

	local petClass = petData["petClass"]
	local waveCompletionReward = PetBalanceInfo["saveRewardCoinsMap"][petClass]

	-- print("WAVE COMPLETION REWARD: ", petClass, waveCompletionReward)

	routine(function()
		wait(1.5)
		self.user.home.itemStash:updateItemCount({
			itemName = "Coins",
			count = waveCompletionReward,
		})
	end)

	ServerMod:FireAllClients("completeWaveMod", {
		waveName = waveMod["waveName"],
		userName = self.user.name,

		petClass = petData["petClass"],
		mutationClass = petData["mutationClass"],

		pos = self.saveBaseFrame.Position,
	})
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

	local tutManager = self.user.home.tutManager
	if tutManager.completedTutMods["CompleteFirstWave"] then
		if
			not tutManager.completedTutMods["EquipFirstPet"]
			or not tutManager.completedTutMods["PlaceFirstPet"]
			or not tutManager.completedTutMods["EquipBat2"]
		then
			-- warn("NOT COMPLETED TUT MODS TO START NEW WAVE: ", tutManager.completedTutMods)
			return
		end
	end

	local chosenTutMod = tutManager.chosenTutMod
	if chosenTutMod then
		local tutName = chosenTutMod["tutName"]
		if
			Common.listContains({
				"GoToTimeWizard",
				"Buy2xSpeedCommon",
				"CloseTimeWizard",
				"Choose2xSpeedCommon",
			}, tutName)
		then
			return
		end
	end

	if self.user.home.itemStash:checkFullPets() then
		if self.checkFullPetsExpiree and self.checkFullPetsExpiree > ServerMod.step then
			return
		end
		self.checkFullPetsExpiree = ServerMod.step + 60 * 20
		self.user:notifyError("Your inventory is full!")
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

function SaveManager:wipe()
	self:destroy()

	self:togglePlay(false)
end

function SaveManager:destroy()
	local currWaveMod = self.currWaveMod
	if currWaveMod then
		self:failWaveMod(currWaveMod, nil)
	end

	self.waveMods = {}
end

return SaveManager
