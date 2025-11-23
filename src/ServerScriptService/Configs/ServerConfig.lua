local ServerConfig = {}

ServerConfig["SERVERMANAGERS_LIST"] = {
	{ "ServerStoreManager", "serverStoreManager" },
	{ "ProxyManager", "proxyManager" },
	{ "TeleportManager", "teleportManager" },

	{ "PhysicsManager", "physicsManager" },

	{ "UserManager", "userManager" },

	{ "MapManager", "mapManager" },
	{ "ServerEventManager", "serverEventManager" },

	{ "LeaderManager", "leaderManager" },

	-- { "LikeManager", "likeManager" },

	{ "MarketManager", "marketManager" },
	{ "RagdollManager", "ragdollManager" },

	{ "WeatherManager", "weatherManager" },

	{ "LuckManager", "luckManager" },

	{ "BuyCrateManager", "buyCrateManager" },
}

ServerConfig["REPLICATED_LIST"] = {
	{ "AnimUtils", "animUtils" },
	{ "TweenManager", "tweenManager" },
	{ "MutationManager", "mutationManager" },
	{ "WeldPetManager", "weldPetManager" },
	{ "RatingManager", "ratingManager" },
	{ "RainbowManager", "rainbowManager" },
}

ServerConfig["TICK_LIST"] = {
	"userManager",
	"mapManager",
	"weatherManager",
	"luckManager",

	"buyCrateManager",
}

return ServerConfig
