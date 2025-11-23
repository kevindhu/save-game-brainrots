local players = game:GetService("Players")

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local ServerMod = {
	step = 0,
}

function ServerMod:tick(timeRatio)
	self.step += 1 * timeRatio
end

function ServerMod:FireClient(player, req, ...)
	local mainEvent = game.ReplicatedStorage.Events.MainEvent
	mainEvent:FireClient(player, req, ...)
end

function ServerMod:FireAllClients(...)
	local mainEvent = game.ReplicatedStorage.Events.MainEvent

	for _, player in pairs(players:GetPlayers()) do
		local user = ServerMod.userManager:getUser(player.Name)
		if not user then
			continue
		end

		mainEvent:FireClient(player, ...)
	end
end

return ServerMod
