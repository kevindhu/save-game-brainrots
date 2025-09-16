local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local MutationInfo = require(game.ReplicatedStorage.MutationInfo)

local FavoriteManager = {}
FavoriteManager.__index = FavoriteManager

function FavoriteManager.new(owner, data)
	local u = {}
	u.owner = owner
	u.data = data

	setmetatable(u, FavoriteManager)
	return u
end

function FavoriteManager:init()
	self.user = self.owner.user
	for k, v in pairs(self.data) do
		self[k] = v
	end

	self.favoriteGameExpiree = os.time() + math.random(60 * 0.5, 60 * 1)
	-- self.favoriteGameExpiree = os.time() + 3

	routine(function()
		wait(0.5)
		self.initialized = true
		self:sendFavoriteData()
	end)
end

function FavoriteManager:finishFavoriteGame()
	self.hasFavoritedGame = true
	self:sendFavoriteData()

	-- print("FINISHED FAVORITE GAME")
end

function FavoriteManager:tick()
	if self.hasFavoritedGame then
		return
	end
	if not self.initialized then
		return
	end

	if not self.user.home.tutManager:checkHasCompletedAllTutorials() then
		return
	end

	if self.favoriteGameExpiree and self.favoriteGameExpiree > os.time() then
		return
	end
	self.favoriteGameExpiree = os.time() + math.random(60 * 15, 60 * 45)

	self:tryStartFavorite()
end

function FavoriteManager:tryStartFavorite()
	ServerMod:FireClient(self.user.player, "tryStartFavorite")
end

function FavoriteManager:sendFavoriteData()
	local data = {
		hasFavoritedGame = self.hasFavoritedGame,
	}
	ServerMod:FireClient(self.user.player, "updateFavoriteData", data)
end

function FavoriteManager:saveState()
	local managerData = {
		hasFavoritedGame = self.hasFavoritedGame,
	}
	self.user.store:set(self.moduleAlias .. "Info", managerData)
end

return FavoriteManager
