local TeleportService = game:GetService("TeleportService")

local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local playerScripts = player.PlayerScripts

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local PingManager = {
	idleTimer = 0,
}
PingManager.__index = PingManager

function PingManager:init() end

function PingManager:tick()
	if self.pingExpiree and self.pingExpiree > Common.getCurrentDecimalTime() then
		return
	end
	self.pingExpiree = Common.getCurrentDecimalTime() + 1

	local startTime = tick()
	local pingFunction = game.ReplicatedStorage.Events:WaitForChild("PingRemoteFunction")
	local serverTime = pingFunction:InvokeServer()

	local receivedTime = tick() - serverTime
	local sentTime = serverTime - startTime

	print("FINAL PING: ", (receivedTime + sentTime) * 1000, receivedTime * 1000, sentTime * 1000)
end

PingManager:init()

return PingManager
