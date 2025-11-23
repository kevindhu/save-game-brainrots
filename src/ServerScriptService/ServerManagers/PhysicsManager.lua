local PhysicsService = game:GetService("PhysicsService")

local PhysicsManager = {}
PhysicsManager.__index = PhysicsManager

function PhysicsManager:init()
	self:registerPhysics()
end

function PhysicsManager:registerPhysics()
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

PhysicsManager:init()

return PhysicsManager
