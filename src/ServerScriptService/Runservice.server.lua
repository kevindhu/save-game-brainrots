local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local modulesToLoad = {
	{ "ProxyManager", "proxyManager" },
	{ "TweenManager", "tweenManager" },
	{ "TeleportManager", "teleportManager" },

	{ "Map", "map" },
	{ "ServerEventManager", "serverEventManager" },

	{ "LeaderManager", "leaderManager" },

	-- { "LikeManager", "likeManager" },

	{ "MarketManager", "marketManager" },
	{ "RagdollManager", "ragdollManager" },

	{ "WeatherManager", "weatherManager" },

	{ "LuckManager", "luckManager" },

	{ "BuyCrateManager", "buyCrateManager" },
}
for _, moduleData in pairs(modulesToLoad) do
	local moduleClass, moduleAlias = moduleData[1], moduleData[2]
	local module = require(game.ServerScriptService[moduleClass])
	ServerMod[moduleAlias] = module
end

local replicatedModulesToLoad = {
	{ "AnimUtils", "animUtils" },
	{ "MutationManager", "mutationManager" },
	{ "WeldPetManager", "weldPetManager" },
	{ "RatingManager", "ratingManager" },
	{ "RainbowManager", "rainbowManager" },
}
for _, moduleData in pairs(replicatedModulesToLoad) do
	local moduleClass, moduleAlias = moduleData[1], moduleData[2]
	local module = require(game.ReplicatedStorage[moduleClass])
	ServerMod[moduleAlias] = module
end

game.Players.PlayerAdded:Connect(function(player)
	-- have to load their character immediately because CharacterAutoLoads is false in game.Players
	player:LoadCharacter()
	ServerMod:refreshPlayerCount()
end)

local ServerStore = require(game.ServerScriptService.ServerStore)
ServerMod.serverStore = ServerStore

game.Players.PlayerRemoving:Connect(function(player)
	local userName = player.Name

	local user = ServerMod.users[userName]
	if user then
		user:destroy()
	else
		-- warn("NO USER FOUND WHEN REMOVING PLAYER: ", userName)
	end

	ServerMod:refreshPlayerCount()
end)

-- SERVER TICK EVENTS
game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
	local timeRatio = deltaTime / (1 / 60)

	ServerMod:tick(timeRatio)

	-- first tick users to check for cheating
	for name, user in pairs(ServerMod.users) do
		user:tick(timeRatio)
	end

	ServerMod.map:tick(timeRatio)
	ServerMod.weatherManager:tick(timeRatio)
	ServerMod.luckManager:tick(timeRatio)

	ServerMod.buyCrateManager:tick(timeRatio)

	-- ServerMod.likeManager:tick(timeRatio)

	ServerMod.rainbowManager:tickRender(timeRatio)
end)

function tickSecond()
	-- tick users
	for _, user in pairs(ServerMod.users) do
		if not user.initialized then
			continue
		end
		user.home:tickSecond()
	end

	-- tick leaders
	for _, leader in pairs(ServerMod.leaders) do
		leader:tickSecond()
	end
end

routine(function()
	while true do
		routine(function()
			local success, err = pcall(function()
				tickSecond()
			end)
			if not success then
				warn("############# TICK SECOND FAILED: ", err)
			end
		end)
		wait(1)
	end
end)
