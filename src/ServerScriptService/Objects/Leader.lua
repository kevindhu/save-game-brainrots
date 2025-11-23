-- local PathfindingService = game:GetService("PathfindingService")

local ServerMod = require(game.ServerScriptService.ServerMod)

local LeaderInfo = require(game.ReplicatedStorage.Data.LeaderInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local Leader = {}
Leader.__index = Leader

function Leader.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	u.userMods = {}
	u.userModsList = {}

	u.refreshCount = nil

	setmetatable(u, Leader)
	return u
end

local REFRESH_TIMER = 60 * 1

function Leader:init()
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self.refreshCount = 5

	self:initStats()

	for _, user in pairs(ServerMod.userManager:getAllUsers()) do
		if not user.initialized then
			continue
		end
		self:sync(user)
	end
end

function Leader:initStats()
	local stats = LeaderInfo:getMeta(self.leaderClass)
	self.stats = stats
	self.itemClass = stats["itemClass"]
end

function Leader:sync(user)
	if self.destroyed then
		return
	end

	ServerMod:FireClient(user.player, "addLeader", {
		name = self.name,
		leaderClass = self.leaderClass,
	})

	routine(function()
		wait(0.1)
		self:sendUserModsList()
	end)
end

function Leader:tickSecond()
	if self.refreshing then
		return
	end

	self.refreshCount -= 1
	if self.refreshCount > 0 then
		return
	end

	-- reset the refreshCount
	self.refreshCount = math.floor(REFRESH_TIMER)

	routine(function()
		self.refreshing = true

		local success, err = pcall(function()
			self:refresh()
		end)
		if not success then
			warn("ERROR REFRESHING LEADER: ", err)
		end

		self.refreshing = false
	end)
end

function Leader:refresh()
	local itemClass = self.itemClass

	ServerMod.leaderManager:sendUserStats(itemClass)

	local pages = ServerMod.leaderManager:getItemPages(itemClass)
	if not pages then
		return
	end
	local data = pages:GetCurrentPage()
	if not data then
		return
	end

	-- clear userMods
	self.userModsList = {}

	local rank = 1
	for _, pair in ipairs(data) do
		local userId = pair.key
		local value = pair.value

		if not value then
			warn("!!!!!!! NO VALUE FOUND FOR LEADER: ", userId, itemClass)
			value = -1
		end

		self:newUserMod(userId, rank, value)

		if rank == 1 then
			local firstUserMod = self.userMods[tostring(userId)]
			self.firstUserMod = firstUserMod
		end
		rank += 1
	end

	self:sendUserModsList()
end

function Leader:sendUserModsList()
	local data = {
		name = self.name,
		userModsList = self.userModsList,
	}

	ServerMod:FireAllClients("updateLeaderUserMods", data)
end

function Leader:newUserMod(userId, rank, score)
	local newUserMod = {
		userId = userId,
		rank = rank,
		score = score,
	}
	self.userMods[tostring(userId)] = newUserMod
	table.insert(self.userModsList, newUserMod)

	routine(function()
		local userName = Common.getUsernameFromUserId(userId)
		newUserMod["userName"] = userName
		ServerMod:FireAllClients("updateUsernameMap", { [userId] = userName })
	end)
end

return Leader
