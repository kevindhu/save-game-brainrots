local BadgeService = game:GetService("BadgeService")

local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local BadgeManager = {}
BadgeManager.__index = BadgeManager

function BadgeManager.new(user, data)
	local u = {}
	u.user = user
	u.data = data

	u.obtainedBadgeMap = {}

	setmetatable(u, BadgeManager)
	return u
end

function BadgeManager:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self.initialized = true
end

local badgeIdMap = {
	["Join"] = 4084225341372551,
	["CompleteTutorial"] = 2754110506721216,
	["BoughtTimeFromTimeWizard"] = 1850469804962762,
}

function BadgeManager:addBadge(badgeClass)
	local id = badgeIdMap[badgeClass]
	if not id then
		-- warn("NO ID FOR BADGECLASS: ", badgeClass)
		return
	end
	if self.obtainedBadgeMap[badgeClass] then
		-- warn("ALREADY OBTAINED BADGE: ", badgeClass)
		return
	end

	self.obtainedBadgeMap[badgeClass] = true
	BadgeService:AwardBadge(self.user.userId, id)
end

function BadgeManager:saveState()
	local managerData = {
		obtainedBadgeMap = self.obtainedBadgeMap,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function BadgeManager:wipe()
	self.obtainedBadgeMap = {}
end

return BadgeManager
