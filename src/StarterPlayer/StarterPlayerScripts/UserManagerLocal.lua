local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local User = require(playerScripts.UserLocal)

local UserManager = {}

function UserManager:init() end

function UserManager:addUser(data)
	local name = data["name"]
	if not name then
		return
	end

	local user = ClientMod.users[name]
	if user then
		-- warn("USER ALREADY EXISTS: " .. name)
		return
	end

	user = User.new(data)
	ClientMod.users[data["name"]] = user
	user:init()

	ClientMod.placeManager:refreshAllPrompts()
end

function UserManager:updateUserOwnedGamepassMods(data)
	local userName = data["userName"]
	if userName == player.Name then
		ClientMod.shopManager:updateOwnedGamepassMods(data)
	end

	local user = ClientMod.users[userName]
	if not user then
		warn("USER NOT FOUND: " .. userName)
		return
	end
end

function UserManager:updateUserStrength(data)
	local user = ClientMod:getLocalUser()
	user:updateStrength(data)
end

function UserManager:toggleRagdoll(data)
	local user = ClientMod:getLocalUser()
	if not user then
		return
	end
	user:toggleRagdoll(data)
end

function UserManager:toggleControls(data)
	local user = ClientMod:getLocalUser()
	if not user then
		return
	end
	user:toggleControls(data)
end

function UserManager:forceUserGetUp(data)
	local user = ClientMod:getLocalUser()
	if not user then
		return
	end

	user.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

function UserManager:toggleUserStone(data)
	local user = ClientMod.users[data["userName"]]
	if not user then
		return
	end
	user:toggleStone(data)
end

function UserManager:toggleUserIce(data)
	local user = ClientMod.users[data["userName"]]
	if not user then
		return
	end
	user:toggleIce(data)
end

function UserManager:updateWalkspeed(data)
	local user = ClientMod:getLocalUser()
	if not user then
		return
	end
	user:updateWalkspeed(data)
end

function UserManager:toggleInvertedControls(data)
	local user = ClientMod.users[data["userName"]]
	if not user then
		return
	end
	user:toggleInvertedControls(data)
end

function UserManager:removeUser(data)
	local name = data["name"]
	local user = ClientMod.users[name]
	if not user then
		warn("USER NOT FOUND: " .. name)
		return
	end

	user:destroy()
end

UserManager:init()

return UserManager
