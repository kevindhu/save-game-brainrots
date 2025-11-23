local ContextActionService = game:GetService("ContextActionService")

local player = game.Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerGui = player:WaitForChild("PlayerGui")

local Common = require(game.ReplicatedStorage.Common)

local ClientMod = {
	step = 0,

	-- MEMORY STORAGE
	users = {},
	leaders = {},

	units = {},

	petSpots = {},
}

function ClientMod:init()
	self:addCons()
end

function ClientMod:addCons() end

function ClientMod:getLocalUser()
	local user = self.users[player.Name]
	if not user then
		return
	end
	return user
end

function ClientMod:FireServer(...)
	local userEvent = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("MainEvent")
	userEvent:FireServer(...)
end

function ClientMod:tick(timeRatio)
	self.step += 1 * timeRatio
end

ClientMod:init()

return ClientMod
