local DataStoreService = game:GetService("DataStoreService")

local ServerMod = require(script.Parent.ServerMod)

local SaveInfo = require(game.ReplicatedStorage.SaveInfo)
local LeaderInfo = require(game.ReplicatedStorage.LeaderInfo)

local Leader = require(script.Parent.Leader)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local LeaderManager = {
	sendExpirees = {},
	getExpirees = {},
	getPageMap = {},
}

function LeaderManager:init()
	routine(function()
		self:initLeaders()
	end)
end

function LeaderManager:initLeaders()
	-- if SaveInfo.NO_SAVE then
	-- 	return
	-- end

	local leaderList = LeaderInfo.leaderList
	for _, leaderClass in pairs(leaderList) do
		self:newLeader(leaderClass)
	end
end

function LeaderManager:newLeader(leaderClass)
	local leaderName = leaderClass .. "_" .. Common.getGUID()

	local leaderData = {
		name = leaderName,
		leaderClass = leaderClass,
	}
	local leader = Leader.new(self, leaderData)
	leader:init()
	ServerMod.leaders[leader.name] = leader
end

function LeaderManager:getOrderedStore(itemClass)
	return DataStoreService:GetOrderedDataStore(itemClass .. SaveInfo.ODS_VERSION)
end

function LeaderManager:sendTotalToDatastore(statManager, itemClass)
	local statMod = statManager:getStatMod(itemClass)
	if not statMod then
		warn("NO STAT MOD FOUND FOR: ", itemClass, statManager.user.name, statManager.statMods)
		return
	end

	local value = statMod["value"]
	value = math.floor(value)

	-- if Common.checkDeveloper(statManager.user.userId) then
	-- 	value = 0
	-- end

	local success, err = pcall(function()
		local orderedDataStore = self:getOrderedStore(itemClass)
		local userId = statManager.user.userId
		orderedDataStore:SetAsync(userId, value)
	end)

	if not success then
		warn("BAD SET ORDERED DATASTORE ATTEMPT: ", itemClass, err)
		return
	end
end

function LeaderManager:sendUserStats(itemClass)
	if self.sendExpirees[itemClass] and self.sendExpirees[itemClass] > ServerMod.step then
		return
	end
	self.sendExpirees[itemClass] = ServerMod.step + 60 * 5

	for name, user in pairs(ServerMod.users) do
		if not user.initialized then
			continue
		end
		self:sendTotalToDatastore(user.home.statManager, itemClass)
	end
end

function LeaderManager:getItemPages(itemClass)
	if self.getExpirees[itemClass] and self.getExpirees[itemClass] > ServerMod.step then
		local cachedPageMap = self.getPageMap[itemClass]
		return cachedPageMap
	end
	self.getExpirees[itemClass] = ServerMod.step + 60 * 5

	local ods = self:getOrderedStore(itemClass)
	local pages
	local maxPlayers = 50 -- 100
	local success, message = pcall(function()
		pages = ods:GetSortedAsync(false, maxPlayers)
	end)

	if not success then
		warn("FAILED TO GET LEADER ITEM PAGES: ", message)
		return
	end

	self.getPageMap[itemClass] = pages

	return pages
end

LeaderManager:init()

return LeaderManager
