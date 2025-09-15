local ServerMod = require(script.Parent.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local LuckManager = {
	serverLuck = 1,
}

function LuckManager:init() end

function LuckManager:tick(timeRatio)
	self:tickServerLuck(timeRatio)
end

function LuckManager:tickServerLuck(timeRatio)
	if not self.serverLuckExpiree or self.serverLuckExpiree > os.time() then
		return
	end
	self.serverLuckExpiree = nil
	self.serverLuck = 1

	self:sendServerLuck()
end

local SERVER_LUCK_TIMER = 60 * 15 -- 15 minutes

function LuckManager:setServerLuck(purchaseUser, newLuck)
	self.serverLuckExpiree = os.time() + SERVER_LUCK_TIMER
	self.serverLuck = newLuck

	for _, user in pairs(ServerMod.users) do
		user:notifySuccess(string.format("%s has bought %sx Server Luck!", purchaseUser.name, newLuck))
	end

	self:sendServerLuck()
end

function LuckManager:sync(user)
	ServerMod:FireClient(user.player, "updateServerLuck", {
		serverLuck = self.serverLuck,
		serverLuckExpiree = self.serverLuckExpiree,
	})
end

function LuckManager:sendServerLuck()
	ServerMod:FireAllClients("updateServerLuck", {
		serverLuck = self.serverLuck,
		serverLuckExpiree = self.serverLuckExpiree,
	})
end

LuckManager:init()

return LuckManager
