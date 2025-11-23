local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local playerGui = player.PlayerGui
local playerScripts = player.PlayerScripts

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local CmdrClient = require(game.ReplicatedStorage:WaitForChild("CmdrClient"))

CmdrClient:SetActivationKeys({ Enum.KeyCode.F2 })

local CommandManager = {
	idleTimer = 0,
}
CommandManager.__index = CommandManager

function CommandManager:init()
	self:addCons()
end

function CommandManager:addCons()
	-- Cmdr:Register(function(args)
	-- 	local command = args[1]
	-- 	local target = args[2]
	-- 	local value = args[3]

	-- 	if command == "tp" then
	-- 		TeleportService:Teleport(target, player)
	-- 	end
	-- end)
end

CommandManager:init()

return CommandManager
