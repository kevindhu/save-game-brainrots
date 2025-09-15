local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local MusicInfo = require(game.ReplicatedStorage.MusicInfo)

local Icon = require(game.ReplicatedStorage.Libraries.Icon)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local MusicManager = {
	musicMods = {},
	setRatio = 1,

	recentSongList = {},
}

function MusicManager:init()
	self:initSimpleIcon()

	local playing = true
	if Common.isStudio then
		playing = false
	end

	self:toggle({
		newBool = playing,
	})

	routine(function()
		wait(2)
		self.initialized = true
	end)
end

function MusicManager:initSimpleIcon()
	local musicIcon = Icon.new()
	musicIcon:setImage(95959674424370)
	musicIcon:setOrder(1)

	musicIcon:oneClick(true)
	musicIcon.selected:Connect(function()
		self:toggle({
			newBool = not self.toggled,
		})
	end)

	self.musicIcon = musicIcon
end

function MusicManager:tick()
	if not self.initialized then
		return
	end
	self:tickMusic()
end

function MusicManager:tickMusic()
	if not self.toggled then
		return
	end

	local songMod = self.songMod
	if songMod then
		local song = songMod["song"]
		local timeLeft = song.TimeLength - song.TimePosition
		if timeLeft > 2 then
			return
		end
	end

	if self.startSongExpiree and self.startSongExpiree > ClientMod.step then
		return
	end
	self.startSongExpiree = ClientMod.step + 60 * 0.5

	self:playNewSong()
end

function MusicManager:getNewSongData()
	local songDataList = {}

	if not self.firstSong then
		self.firstSong = true
		return MusicInfo["songs"][1]
	end

	local recentSongList = self.recentSongList
	for _, songData in ipairs(MusicInfo["songs"]) do
		if Common.listContains(recentSongList, songData) then
			continue
		end
		table.insert(songDataList, songData)
	end
	return songDataList[math.random(1, #songDataList)]
end

local VOLUME_BUFF = 1 -- 1.5

function MusicManager:playNewSong()
	local newSongData = self:getNewSongData()

	table.insert(self.recentSongList, newSongData)

	-- keep recent song list to 4
	if len(self.recentSongList) > 4 then
		table.remove(self.recentSongList, 1)
	end

	local soundId = newSongData[1]
	local finalVolume = newSongData[2]

	finalVolume = finalVolume * VOLUME_BUFF

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. soundId
	sound.Volume = finalVolume
	sound.PlaybackSpeed = 1
	sound.Parent = game.SoundService
	sound.Name = "Music"

	sound:Play()

	local newSongMod = {
		song = sound,
	}

	local fadeTimer = 2

	ClientMod.tweenManager:createTween({
		target = sound,
		timer = fadeTimer,
		easingStyle = "Quad",
		easingDirection = "Out",
		goal = {
			Volume = finalVolume,
		},
	})

	local oldSongMod = self.songMod
	if oldSongMod then
		local song = oldSongMod["song"]
		ClientMod.tweenManager:createTween({
			target = song,
			timer = fadeTimer,
			easingStyle = "Quad",
			easingDirection = "Out",
			goal = { Volume = 0 },
		})

		routine(function()
			wait(fadeTimer)
			song:Destroy()
		end)
	end

	self.songMod = newSongMod
end

function MusicManager:toggle(data)
	local newBool = data["newBool"]

	local musicIcon = self.musicIcon
	if newBool then
		musicIcon:setImage(302250236)
	else
		musicIcon:setImage(16332006068)
	end

	self.toggled = newBool

	local songMod = self.songMod
	if songMod then
		local song = songMod["song"]
		if newBool then
			song:Resume()
		else
			song:Pause()
		end
	end
end

MusicManager:init()

return MusicManager
