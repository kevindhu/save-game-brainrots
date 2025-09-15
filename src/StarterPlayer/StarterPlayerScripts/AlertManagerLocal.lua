local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local AlertManager = {}
AlertManager.__index = AlertManager

function AlertManager:init() end

function AlertManager:updateModuleAlert(data)
	local moduleName = data["moduleName"]
	local module = ClientMod[moduleName]
	if not module then
		warn("NO MODULE TO TOGGLE ALERT: ", moduleName)
		return
	end
	module:updateAlert(data)
end

function AlertManager:tryClearAlert(moduleName)
	local alertData = {
		moduleName = moduleName,
		bool = false,
	}
	ClientMod:FireServer("updateAlert", alertData)
end
AlertManager:init()

return AlertManager
