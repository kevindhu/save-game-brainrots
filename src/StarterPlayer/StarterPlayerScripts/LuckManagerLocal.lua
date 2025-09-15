local ClientMod = require(script.Parent:WaitForChild("ClientMod"))

local player = game.Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerGui = player:WaitForChild("PlayerGui")

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local luckGUI = playerGui:WaitForChild("LuckGUI")
local luckFrame = luckGUI.LuckFrame

local LuckManager = {}

function LuckManager:init()
	luckFrame.BackgroundTransparency = 1
end

LuckManager:init()

function LuckManager:updateServerLuck(data)
	self.serverLuck = data["serverLuck"]
	self.serverLuckExpiree = data["serverLuckExpiree"]

	if self.serverLuck == 1 then
		luckFrame.Visible = false
	else
		luckFrame.Visible = true
		self:tickLuckExpiree()
	end

	ClientMod.shopManager:updateServerLuck(data)
end

function LuckManager:tick(timeRatio)
	self:tickLuckExpiree()
end

function LuckManager:tickLuckExpiree()
	if not self.serverLuckExpiree or self.serverLuckExpiree <= os.time() then
		return
	end
	local remainingSeconds = self.serverLuckExpiree - os.time()
	if remainingSeconds <= 0 then
		return
	end

	luckFrame.Title.Text = string.format(
		"[%s] x%s Server Luck",
		Common.convertSecondsToReadableString(remainingSeconds, true),
		self.serverLuck
	)
end

return LuckManager
