local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local NotifyManager = {}
NotifyManager.__index = NotifyManager

function NotifyManager.new(user, data)
	local u = {}
	u.user = user
	u.data = data

	setmetatable(u, NotifyManager)
	return u
end

function NotifyManager:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end
end

function NotifyManager:newNotifyMod(data)
	ServerMod:FireClient(self.user.player, "addNotify", data)
end

function NotifyManager:notifySuccess(txt, duration, soundClass)
	local data = {
		txt = txt,
		notifyClass = "Success",
		duration = duration,
		soundClass = soundClass,
	}
	ServerMod:FireClient(self.user.player, "addNotify", data)
end

function NotifyManager:notifyError(txt, duration, soundClass)
	local data = {
		txt = txt,
		notifyClass = "Error",
		duration = duration,
		soundClass = soundClass,
	}
	ServerMod:FireClient(self.user.player, "addNotify", data)
end

-- function NotifyManager:saveState() end

return NotifyManager
