local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local AfkManager = {}
AfkManager.__index = AfkManager

function AfkManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	setmetatable(u, AfkManager)
	return u
end

function AfkManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end
end

-- called from client
function AfkManager:idleTeleport()
	-- TODO: do checks to see if user is totally initialized, do not want exploiters abusing this for trade/duping
	if not self.user.initialized then
		return
	end
	if self.idleTeleporting then
		return
	end
	self.idleTeleporting = true

	-- local migrationPlaceId = Common.migrationPlaceId
	local migrationPlaceId = game.PlaceId

	local success, err = ServerMod.teleportManager:teleportUser(self.user, migrationPlaceId)

	-- print("GOT TELEPORT RESULT: ", success, err)

	self.idleTeleporting = false
end

return AfkManager
