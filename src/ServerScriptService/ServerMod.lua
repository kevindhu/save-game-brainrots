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

	PhysicsService:RegisterCollisionGroup("RopeRigs")
	-- PhysicsService:RegisterCollisionGroup("WeldRopeRigs")

	PhysicsService:RegisterCollisionGroup("Carpet")
	PhysicsService:RegisterCollisionGroup("Pets")
	PhysicsService:RegisterCollisionGroup("Misc")
	PhysicsService:RegisterCollisionGroup("ObtainParts")

	-- SET PLAYERS COLLIDE GROUPS
	PhysicsService:CollisionGroupSetCollidable("Players", "Players", false)

	-- SET UNITS COLLIDE GROUPS
	PhysicsService:CollisionGroupSetCollidable("Units", "Players", false)
	PhysicsService:CollisionGroupSetCollidable("Units", "Units", false)

	-- SET ROPE RIGS COLLIDE GROUPS
	PhysicsService:CollisionGroupSetCollidable("RopeRigs", "Players", false)
	PhysicsService:CollisionGroupSetCollidable("RopeRigs", "Units", false)
	PhysicsService:CollisionGroupSetCollidable("RopeRigs", "RopeRigs", true) -- false

	-- -- SET WELD ROPE RIGS COLLIDE GROUPS
	-- PhysicsService:CollisionGroupSetCollidable("WeldRopeRigs", "Players", false)
	-- PhysicsService:CollisionGroupSetCollidable("WeldRopeRigs", "Units", false)
	-- PhysicsService:CollisionGroupSetCollidable("WeldRopeRigs", "RopeRigs", false)
	-- PhysicsService:CollisionGroupSetCollidable("WeldRopeRigs", "WeldRopeRigs", true)

	-- SET CARPET COLLIDE GROUPS
	PhysicsService:CollisionGroupSetCollidable("Carpet", "Players", true)
	PhysicsService:CollisionGroupSetCollidable("Carpet", "Units", false)
	PhysicsService:CollisionGroupSetCollidable("Carpet", "RopeRigs", false)
	PhysicsService:CollisionGroupSetCollidable("Carpet", "Carpet", false)

	-- SET PETS COLLIDE GROUPS
	PhysicsService:CollisionGroupSetCollidable("Pets", "Players", false)
	PhysicsService:CollisionGroupSetCollidable("Pets", "Units", false)
	PhysicsService:CollisionGroupSetCollidable("Pets", "RopeRigs", false)
	PhysicsService:CollisionGroupSetCollidable("Pets", "Carpet", false)
	PhysicsService:CollisionGroupSetCollidable("Pets", "Pets", false)

	-- SET MISC COLLIDE GROUPS
	PhysicsService:CollisionGroupSetCollidable("Misc", "Players", false)
	PhysicsService:CollisionGroupSetCollidable("Misc", "Units", false)
	PhysicsService:CollisionGroupSetCollidable("Misc", "RopeRigs", false)
	PhysicsService:CollisionGroupSetCollidable("Misc", "Carpet", false)
	PhysicsService:CollisionGroupSetCollidable("Misc", "Pets", false)
	PhysicsService:CollisionGroupSetCollidable("Misc", "Misc", false)

	-- SET OBTAIN PARTS COLLIDE GROUPS
	PhysicsService:CollisionGroupSetCollidable("ObtainParts", "Players", true)
	PhysicsService:CollisionGroupSetCollidable("ObtainParts", "Units", false)
	PhysicsService:CollisionGroupSetCollidable("ObtainParts", "RopeRigs", false)
	PhysicsService:CollisionGroupSetCollidable("ObtainParts", "Carpet", false)
	PhysicsService:CollisionGroupSetCollidable("ObtainParts", "Pets", false)
	PhysicsService:CollisionGroupSetCollidable("ObtainParts", "ObtainParts", false)
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
