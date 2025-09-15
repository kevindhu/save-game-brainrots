local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local FriendManager = {}
FriendManager.__index = FriendManager

function FriendManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.friendCount = 0

	setmetatable(u, FriendManager)
	return u
end

function FriendManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self.initialized = true
end

function FriendManager:tick()
	if self.tryRefreshFriendCountExpiree and self.tryRefreshFriendCountExpiree > ServerMod.step then
		return
	end
	self.tryRefreshFriendCountExpiree = ServerMod.step + 60 * 5

	self:refreshFriendCount()
end

function FriendManager:refreshFriendCount()
	if self.user.destroyed then
		return
	end

	local friendMap = {}
	for _, otherUser in pairs(ServerMod.users) do
		if otherUser.destroyed then
			continue
		end
		if otherUser == self.user then
			continue
		end
		if self.user.player:IsFriendsWith(otherUser.userId) then
			friendMap[otherUser.userId] = true
		end
	end

	local friendCount = len(friendMap)

	-- if Common.isStudio then
	-- 	friendCount = 5
	-- end

	self.friendCount = friendCount

	ServerMod:FireClient(self.user.player, "updateFriends", {
		friendMap = friendMap,
		friendCount = friendCount,
	})
end

function FriendManager:saveState()
	local managerData = {}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

return FriendManager
