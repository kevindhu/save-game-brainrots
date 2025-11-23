local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local RatingInfo = require(game.ReplicatedStorage.Data.RatingInfo)

local AutoSellManager = {
	autoSellMods = {},
}
AutoSellManager.__index = AutoSellManager

function AutoSellManager.new(user, data)
	local u = {}
	u.user = user
	u.data = data

	u.ratingMods = {}

	setmetatable(u, AutoSellManager)
	return u
end

function AutoSellManager:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end

	routine(function()
		self:initAllRatingMods()
		self:sendAllRatingMods()

		self.initialized = true
	end)
end

function AutoSellManager:initAllRatingMods()
	for _, rating in pairs(RatingInfo.ratingList) do
		local ratingMod = self.ratingMods[rating]
		if not ratingMod then
			ratingMod = {
				rating = rating,
				toggled = true,
			}
			self.ratingMods[rating] = ratingMod
		end
	end
end

function AutoSellManager:tryToggleRatingMod(data)
	local rating = data["rating"]

	local ratingMod = self.ratingMods[rating]
	if not ratingMod then
		warn("NO RATING MOD NAMED: ", rating)
		return
	end
	ratingMod["toggled"] = not ratingMod["toggled"]

	self:sendAllRatingMods()
end

function AutoSellManager:sendAllRatingMods()
	ServerMod:FireAllClients("updateAutoSellRatingMods", {
		userName = self.user.name,
		ratingMods = self.ratingMods,
	})
end

function AutoSellManager:saveState()
	local managerData = {
		ratingMods = self.ratingMods,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

function AutoSellManager:wipe()
	self.ratingMods = {}
	self:initAllRatingMods()
	self:sendAllRatingMods()
end

return AutoSellManager
