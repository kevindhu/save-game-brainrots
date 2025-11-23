local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local User = require(game.ServerScriptService.Objects.User)

local UserManager = {
	users = {},
}
UserManager.__index = UserManager

function UserManager:init()
	self:addCons()
end

function UserManager:addCons()
	-- game.Players.PlayerAdded:Connect(function(player)
	-- 	-- have to load their character immediately because CharacterAutoLoads is false in game.Players
	-- 	player:LoadCharacter()
	-- end)

	game.Players.PlayerRemoving:Connect(function(player)
		self:removeUser(player)
	end)
end

function UserManager:addUser(player)
	if self.users[player.Name] then
		warn("!!! ALREADY HAVE THIS USER: ", player.Name)
		return
	end

	local user = User.new(player)
	routine(function()
		user:init()
	end)

	-- FIRST put it in the storage so you can send events!
	self.users[user.name] = user
end

function UserManager:getUser(name)
	return self.users[name]
end

function UserManager:getUserFromUserId(userId)
	for _, user in pairs(self.users) do
		if user.userId == userId then
			return user
		end
	end
	return nil
end

function UserManager:removeUser(player)
	local user = self.users[player.Name]
	if not user then
		warn("NO USER TO REMOVE: ", player.Name)
		return
	end
	user:destroy()
	self.users[player.Name] = nil
end

function UserManager:tick(timeRatio)
	for _, user in pairs(self.users) do
		if not user.initialized or user.destroyed then
			continue
		end
		user:tick(timeRatio)
	end
end

function UserManager:tickSecond()
	for _, user in pairs(self.users) do
		if not user.initialized or user.destroyed then
			continue
		end
		user:tickSecond()
	end
end

function UserManager:getAllUsers()
	return self.users
end

function UserManager:getAllInitUsers()
	local users = {}
	for _, user in pairs(self.users) do
		if not user.initialized then
			continue
		end
		users[user.name] = user
	end
	return users
end

UserManager:init()

return UserManager
