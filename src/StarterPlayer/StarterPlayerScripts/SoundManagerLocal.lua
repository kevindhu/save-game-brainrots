local debris = game:GetService("Debris")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local SoundInfo = require(game.ReplicatedStorage.SoundInfo)

local SoundManager = {
	soundMods = {},

	expireeStep = 0,
	expireeTimer = 10,

	setRatio = 1,
	baseVolumeMultiplier = 3.5, -- 3 (orig)
}

function SoundManager:init()
	self:toggle({
		newBool = true,
	})
end

function SoundManager:tick()
	self:tickExpirees()
end

function SoundManager:tickExpirees()
	local step = ClientMod.step
	if self.expireeStep + self.expireeTimer > step then
		return
	end
	self.expireeStep = step

	for name, soundMod in pairs(self.soundMods) do
		local expiree = soundMod["expiree"]
		if expiree == "none" then
			continue
		end
		if expiree < step then
			-- print("REMOVING SOUNDMOD DUE TO EXPIREE: ", name)
			self:removeSoundMod(name)
		end
	end
end

function SoundManager:addBasicSound(soundClass, volume, playbackSpeed)
	local soundData = {
		soundClass = soundClass,
		volume = volume,
		playbackSpeed = playbackSpeed,
	}
	ClientMod.soundManager:newSoundMod(soundData) -- 0.03
end

function SoundManager:newSoundMod(data)
	local soundName = data["soundName"]
	local soundClass = data["soundClass"]

	if not soundName then
		soundName = "SOUND_" .. Common.getGUID()
	end

	local pos = data["pos"]
	local part = data["part"]

	local volume = data["volume"] or 1
	local noExpiree = data["noExpiree"]
	local playbackSpeed = data["playbackSpeed"]
	local isLooped = data["isLooped"]

	if not self.toggled and not data["override"] then
		return
	end

	local oldSoundMod = self.soundMods[soundName]
	if oldSoundMod then
		self:removeSoundMod(soundName)
	end

	if pos then
		if not part then
			part = Instance.new("Part")
			part.Size = Vector3.new(1, 1, 1)
			part.Anchored = true
			part.CanCollide = false
			part.Transparency = 1 -- 0.9
			part.Parent = game.Workspace.GlobalSounds

			-- this is a temp part, so put it in debris
			debris:AddItem(part, 20)
		end
		part.CFrame = CFrame.new(pos)
	end

	local soundStats = SoundInfo.sounds[soundClass]

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. soundStats["id"]

	if not playbackSpeed then
		playbackSpeed = soundStats["playbackSpeed"] or 1
	end

	sound.PlaybackSpeed = playbackSpeed

	sound.RollOffMaxDistance = data["rollOffMaxDistance"] or 200 -- 200
	sound.RollOffMinDistance = data["rollOffMinDistance"] or 13
	-- sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMode = Enum.RollOffMode.Linear

	local baseVolume = soundStats["volume"] or 0.5

	local finalVolume = baseVolume * self.setRatio * self.baseVolumeMultiplier * volume
	sound.Volume = finalVolume

	if not part then
		sound.Parent = game.Workspace.GlobalSounds
	else
		sound.Parent = part
	end

	if isLooped then
		-- print("LOOPING SOUND: ", sound)
		sound.Looped = true
	end

	sound:Play()

	if soundStats["startTime"] then
		sound.TimePosition = soundStats["startTime"]
	end

	local expiree = ClientMod.step + 60 * 15
	if noExpiree then
		expiree = "none"
	end

	local soundTimer = sound.TimeLength * 60
	-- print("GOT SOUND TIMER STEPS: ", soundTimer)

	local newSoundMod = {
		soundName = soundName,
		part = part,
		sound = sound,
		soundClass = soundClass,
		baseVolume = baseVolume,
		expiree = expiree,
		soundExpiree = ClientMod.step + soundTimer,

		noDestroyPart = data["noDestroyPart"],
	}
	self.soundMods[soundName] = newSoundMod

	return newSoundMod
end

function SoundManager:updateSetRatio(newRatio)
	self.setRatio = newRatio

	-- print("UPDATED SET RATIO: ", self.setRatio)

	-- adjust current sounds to this volume
	for _, soundMod in pairs(self.soundMods) do
		local baseVolume = soundMod["baseVolume"]
		local sound = soundMod["sound"]

		local finalVolume = baseVolume * self.baseVolumeMultiplier * self.setRatio
		sound.Volume = finalVolume
	end
end

function SoundManager:removeSoundMod(name)
	local soundMod = self.soundMods[name]
	local part = soundMod["part"]
	local sound = soundMod["sound"]

	sound:Destroy()
	if part and not soundMod["noDestroyPart"] then
		part:Destroy()
	end

	self.soundMods[name] = nil
end

function SoundManager:toggle(data)
	local newBool = data["newBool"]
	if newBool == self.toggled then
		return
	end

	for soundName, soundMod in pairs(self.soundMods) do
		local sound = soundMod["sound"]
		local baseVolume = soundMod["baseVolume"]
		if newBool then
			local finalVolume = baseVolume * self.baseVolumeMultiplier * self.setRatio
			sound.Volume = finalVolume
		else
			sound.Volume = 0
		end
	end

	self.toggled = newBool
end

SoundManager:init()

return SoundManager
