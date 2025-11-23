local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local playerScripts = player.PlayerScripts

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local CommandManager = {
	idleTimer = 0,
}
CommandManager.__index = CommandManager

function CommandManager:init()
	self:addCons()
end

function CommandManager:addCons() end

CommandManager:init()

return CommandManager
