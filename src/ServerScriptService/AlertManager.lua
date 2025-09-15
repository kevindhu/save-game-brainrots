local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local AlertManager = {}
AlertManager.__index = AlertManager

function AlertManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.alertMods = {}

	setmetatable(u, AlertManager)
	return u
end

function AlertManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	for _, alertMod in pairs(self.alertMods) do
		self:sendAlert(alertMod)
	end
end

function AlertManager:incrementAlertCount(data)
	local moduleName = data["moduleName"]
	local count = data["count"]

	local alertMod = self.alertMods[moduleName]
	if not alertMod then
		alertMod = self:newAlertMod({
			moduleName = moduleName,
		})
	end
	alertMod["count"] += count

	self:sendAlert(alertMod)
end

function AlertManager:updateAlert(data)
	local bool = data["bool"]
	if not bool then
		self:removeAlertMod(data)
		return
	end
	-- can override previous alertMod
	local alertMod = self:newAlertMod(data)
	self:sendAlert(alertMod)
end

function AlertManager:removeAlertMod(data)
	local moduleName = data["moduleName"]

	local alertMod = self.alertMods[moduleName]
	if not alertMod then
		return
	end

	-- send a fake copy of it being false
	alertMod["bool"] = false
	self:sendAlert(alertMod)

	self.alertMods[moduleName] = nil
end

function AlertManager:newAlertMod(data)
	local moduleName = data["moduleName"]

	if typeof(moduleName) ~= "string" then
		return
	end

	local newAlertMod = {
		moduleName = moduleName,
		bool = true,

		-- metadata
		count = 0,
	}
	for k, v in pairs(data) do
		newAlertMod[k] = v
	end
	self.alertMods[moduleName] = newAlertMod

	return newAlertMod
end

function AlertManager:sendAlert(alertMod)
	ServerMod:FireClient(self.user.player, "updateModuleAlert", alertMod)
end

function AlertManager:saveState()
	local managerInfo = {
		alertMods = self.alertMods,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerInfo)
end

return AlertManager
