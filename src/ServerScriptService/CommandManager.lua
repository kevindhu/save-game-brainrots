local ServerMod = require(game.ServerScriptService.ServerMod)

local Cmdr = require(game.ReplicatedStorage.Libraries.Cmdr)
-- Cmdr:RegisterDefaultCommands()

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local CommandManager = {}
CommandManager.__index = CommandManager

function CommandManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	setmetatable(u, CommandManager)
	return u
end

function CommandManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self:addCons()
end

function CommandManager:addCons()
	self.chattedConnection = self.user.player.Chatted:Connect(function(message)
		self:handleChat(message)
	end)
end

function CommandManager:handleChat(message)
	-- see if there is / before the message
	if message:sub(1, 1) ~= "/" then
		warn("NO / BEFORE MESSAGE: ", message)
		return
	end

	-- get the message after the /
	message = message:sub(2)
	message = message:lower()

	self:processCommand(message)
end

function CommandManager:checkValidRole()
	local validRoleList = {
		"Owner",
		"Admin",
		"Testers",
	}
	if Common.listContains(validRoleList, self.user.groupRole) then
		return true
	end
	return false
end

function CommandManager:processCommand(message)
	if not self:checkValidRole() then
		warn("INVALID ROLE FOR COMMAND: ", message, self.user.groupRole)
		return
	end

	print("PROCESSING COMMAND: ", message, self.user.groupRole)
	if message == "wipe" then
		self.user.home:wipeAllModules()
	end
end

function CommandManager:destroy()
	-- prevent memory leak
	if self.chattedConnection then
		self.chattedConnection:Disconnect()
		self.chattedConnection = nil
	end
end

return CommandManager
