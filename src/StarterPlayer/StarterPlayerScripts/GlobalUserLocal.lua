local debris = game:GetService("Debris")

local player = game.Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerGui = player:WaitForChild("PlayerGui")

local ClientMod = require(playerScripts:WaitForChild("ClientMod"))

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local GlobalUser = {}
GlobalUser.__index = GlobalUser

function GlobalUser.new(data)
	local u = {}
	u.data = data

	u.tools = {}

	setmetatable(u, GlobalUser)
	return u
end

function GlobalUser:init()
	local data = self.data
	for k, v in pairs(data) do
		self[k] = v
	end
end

function GlobalUser:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	ClientMod.globalUsers[self.name] = nil
end

return GlobalUser
