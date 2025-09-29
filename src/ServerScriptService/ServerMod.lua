local PhysicsService = game:GetService("PhysicsService")
local players = game:GetService("Players")

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local ServerMod = {
	step = 0,

	------ GLOBAL TABLES --------
	users = {},
	leaders = {},

	-- set as -1 first
	playerCount = -1,
}

function ServerMod:init()
	self:registerPhysics()
end

function ServerMod:tick(timeRatio)
	self.step += 1 * timeRatio
end

function ServerMod:getUserFromUserId(userId)
	for _, user in pairs(self.users) do
		if user.userId == userId then
			return user
		end
	end
	return nil
end

function ServerMod:registerPhysics()
	-- register groups
	PhysicsService:RegisterCollisionGroup("Players")
	PhysicsService:RegisterCollisionGroup("Units")
	PhysicsService:RegisterCollisionGroup("Pets")
	PhysicsService:RegisterCollisionGroup("Resources")

	-- SET PLAYERS COLLIDE GROUPS
	PhysicsService:CollisionGroupSetCollidable("Players", "Players", false)

	-- SET UNITS COLLIDE GROUPS
	PhysicsService:CollisionGroupSetCollidable("Units", "Players", false)
	PhysicsService:CollisionGroupSetCollidable("Units", "Units", false)

	-- SET PETS COLLIDE GROUPS
	PhysicsService:CollisionGroupSetCollidable("Pets", "Players", false)
	PhysicsService:CollisionGroupSetCollidable("Pets", "Units", false)
	PhysicsService:CollisionGroupSetCollidable("Pets", "Pets", false)

	-- SET RESOURCES COLLIDE GROUPS
	PhysicsService:CollisionGroupSetCollidable("Resources", "Players", false)
	PhysicsService:CollisionGroupSetCollidable("Resources", "Units", false)
	PhysicsService:CollisionGroupSetCollidable("Resources", "Pets", false)
	PhysicsService:CollisionGroupSetCollidable("Resources", "Resources", false)
end

function ServerMod:refreshPlayerCount()
	local lst = players:GetPlayers()
	local count = len(lst)
	self.playerCount = count
end

function ServerMod:checkDeveloper(user)
	return Common.checkDeveloper(user.userId)
end

function ServerMod:checkAdmin(user)
	return Common.checkAdmin(user.userId)
end

function ServerMod:FireClient(player, req, ...)
	self:FireClient_Default(player, req, ...)
end

function ServerMod:FireAllClients(req, ...)
	self:FireAllClients_Default(req, ...)
end

function ServerMod:FireClient_Default(player, ...)
	local event = game.ReplicatedStorage.Events.MainEvent
	event:FireClient(player, ...)
end

function ServerMod:FireAllClients_Default(...)
	for _, player in pairs(players:GetPlayers()) do
		local user = ServerMod.users[player.Name]
		if not user then
			continue
		end

		local event = game.ReplicatedStorage.Events.MainEvent
		event:FireClient(player, ...)
	end
end

ServerMod:init()

return ServerMod
