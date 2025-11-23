local debris = game:GetService("Debris")

local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local SoundInfo = require(game.ReplicatedStorage.Data.SoundInfo)

local SoundManager = {
	soundMods = {},

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
	for soundName, soundMod in pairs(self.soundMods) do
		local expiree = soundMod["expiree"]
		if expiree < Common.getCurrentDecimalTime() then
			self:removeSoundMod(soundName)
		end
	end
end

function SoundManager:addBasicSound(soundClass, volume, playbackSpeed)
	local soundData = {
		soundClass = soundClass,
		volume = volume,
		playbackSpeed = playbackSpeed,
	}
	self:newSoundMod(soundData) -- 0.03
end

function SoundManager:newSoundMod(data)
	local soundName = data["soundName"]
	local soundClass = data["soundClass"]
	local pos = data["pos"]
	local part = data["part"]
	local volume = data["volume"] or 1
	local playbackSpeed = data["playbackSpeed"]
	local isLooped = data["isLooped"]

	if not self.toggled and not data["override"] then
		return
	end

	if not soundName then
		soundName = "SOUND_" .. Common.getGUID()
	end

	if not self:checkValidBulletSound(data) then
		return
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

	sound.RollOffMaxDistance = data["rollOffMaxDistance"] or 150 -- 200
	sound.RollOffMinDistance = data["rollOffMinDistance"] or 13
	-- sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMode = Enum.RollOffMode.Linear

	local baseVolume = soundStats["volume"] or 0.5

	local finalVolume = baseVolume * self.setRatio * self.baseVolumeMultiplier * volume
	sound.Volume = finalVolume

	sound.Name = soundClass

	-- print("FINAL VOLUME: ", finalVolume, soundClass)

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

	-- print(sound.Volume, soundClass, sound.Parent, sound.Parent.Parent)

	if soundStats["startTime"] then
		sound.TimePosition = soundStats["startTime"]
	end

	local expiree = Common.getCurrentDecimalTime() + 6 -- sound.TimeLength * 5

	if soundStats["maxTime"] then
		expiree = Common.getCurrentDecimalTime() + soundStats["maxTime"]
		-- print("MAX TIME: ", soundStats["maxTime"])
	end

	-- print("EXPIREE: ", expiree)

	local newSoundMod = {
		soundName = soundName,
		soundClass = soundClass,
		pos = pos,
		part = part,

		sound = sound,

		baseVolume = baseVolume,
		expiree = expiree,

		creationTimestamp = Common.getCurrentDecimalTime(),
	}
	self.soundMods[soundName] = newSoundMod

	return newSoundMod
end

function SoundManager:checkValidBulletSound(data)
	local soundClass = data["soundClass"]
	local pos = data["pos"]

	if soundClass ~= "Bullet1" then
		return true
	end

	local currTimestamp = Common.getCurrentDecimalTime()

	local closeBulletSoundMods = {}
	for _, soundMod in pairs(self.soundMods) do
		if soundMod["soundClass"] ~= "Bullet1" then
			continue
		end
		local otherPos = soundMod["pos"]
		local distance = (otherPos - pos).Magnitude
		if distance > 100 then
			continue
		end
		local timestampDiff = currTimestamp - soundMod["creationTimestamp"]
		if timestampDiff > 0.15 then
			continue
		end

		if distance < 100 then
			table.insert(closeBulletSoundMods, soundMod)
		end
	end

	-- print("CLOSE BULLET SOUND MODS: ", len(closeBulletSoundMods))

	return len(closeBulletSoundMods) <= 3 -- 5
end

function SoundManager:updateSetRatio(newRatio)
	self.setRatio = newRatio

	-- adjust current sounds to this volume
	for _, soundMod in pairs(self.soundMods) do
		local baseVolume = soundMod["baseVolume"]
		local sound = soundMod["sound"]

		local finalVolume = baseVolume * self.baseVolumeMultiplier * self.setRatio
		sound.Volume = finalVolume
	end
end

function SoundManager:removeSoundMod(soundName)
	local soundMod = self.soundMods[soundName]
	local part = soundMod["part"]
	local sound = soundMod["sound"]

	if sound then
		sound:Destroy()
	end
	if part then
		part:Destroy()
	end

	self.soundMods[soundName] = nil
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
