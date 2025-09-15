local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local playerScripts = player.PlayerScripts

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local AfkManager = {
	idleTimer = 0,
}
AfkManager.__index = AfkManager

function AfkManager:init()
	self:addCons()
	self:startIdleCheck()
end

function AfkManager:addCons()
	UserInputService.InputBegan:Connect(function(input, processed)
		self:resetIdleTimer()
	end)

	UserInputService.InputChanged:Connect(function(input, processed)
		self:resetIdleTimer()
	end)

	UserInputService.InputEnded:Connect(function(input, processed)
		self:resetIdleTimer()
	end)

	TeleportService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage, placeId)
		if teleportResult == Enum.TeleportResult.Flooded or teleportResult == Enum.TeleportResult.Failure then
			wait(2)
			TeleportService:Teleport(placeId, player)
		else
			warn(("Invalid teleport [%s]: %s"):format(teleportResult.Name, errorMessage))
		end
	end)
end

function AfkManager:resetIdleTimer()
	self.idleTimer = 0
end

function AfkManager:startIdleCheck()
	local MAX_IDLE_TIME = 60 * 15 -- 15 minutes
	if Common.checkDeveloper(player.UserId) then
		MAX_IDLE_TIME = 60 * 10 -- 10 minutes
	end

	routine(function()
		while true do
			wait(1)
			self.idleTimer += 1

			if self.idleTimer >= MAX_IDLE_TIME then
				ClientMod:FireServer("idleTeleport")
			end
		end
	end)
end

AfkManager:init()

return AfkManager
