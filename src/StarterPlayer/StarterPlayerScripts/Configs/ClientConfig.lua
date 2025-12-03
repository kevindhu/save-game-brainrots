local ClientConfig = {}

-- first load replicated modules
ClientConfig["REPLICATED_MODULES_LIST"] = {
	{ "AnimUtils", "animUtils" },
	{ "MutationManager", "mutationManager" },
	{ "WeldPetManager", "weldPetManager" },
	{ "RatingManager", "ratingManager" },
	{ "RainbowManager", "rainbowManager" },
}

ClientConfig["CLIENT_MODULES_LIST"] = {
	{ "ContentManager", "contentManager" },
	{ "DeviceManager", "deviceManager" },

	{ "HintManager", "hintManager" },

	{ "DeleteManager", "deleteManager" },

	{ "UIManager", "uiManager" },
	{ "UIScaleManager", "uiScaleManager" },
	{ "VPManager", "vpManager" },

	{ "PlaceManager", "placeManager" },

	-- required for effects
	{ "SpellManager", "spellManager" },
	{ "SpellUtils", "spellUtils" },

	{ "ButtonManager", "buttonManager" },
	{ "TweenManager", "tweenManager" },

	{ "Map", "map" },
	{ "NotifyManager", "notifyManager" },

	{ "UserManager", "userManager" },

	{ "PetManager", "petManager" },

	{ "StashManager", "stashManager" },
	{ "CurrManager", "currManager" },
	{ "PlotManager", "plotManager" },
	{ "WeatherManager", "weatherManager" },

	{ "BasicManager", "basicManager" },

	{ "SellPetManager", "sellPetManager" },
	{ "SellRelicManager", "sellRelicManager" },

	{ "IndexManager", "indexManager" },

	{ "LeaderManager", "leaderManager" },

	{ "SoundManager", "soundManager" },

	{ "ShopManager", "shopManager" },
	{ "CodeManager", "codeManager" },
	{ "GlobalChatManager", "globalChatManager" },
	{ "LuckManager", "luckManager" },

	{ "MusicManager", "musicManager" },
	{ "VendorManager", "vendorManager" },

	{ "ToolManager", "toolManager" },
	{ "TutManager", "tutManager" },
	{ "FriendManager", "friendManager" },

	{ "TradeManager", "tradeManager" },
	{ "BoostManager", "boostManager" },
	{ "TestManager", "testManager" },

	{ "UnitManager", "unitManager" },

	{ "DamageManager", "damageManager" },

	{ "AfkManager", "afkManager" },
	{ "ClaimOfflineManager", "claimOfflineManager" },

	{ "LeaveManager", "leaveManager" },
	{ "FavoriteManager", "favoriteManager" },
	{ "FireworksManager", "fireworksManager" },
	{ "AlertManager", "alertManager" },

	{ "RagdollManager", "ragdollManager" },
	{ "SaveManager", "saveManager" },
	{ "OrbManager", "orbManager" },

	-- speed manager
	{ "SpeedManager", "speedManager" },

	{ "AutoSellManager", "autoSellManager" },

	{ "BuyCrateManager", "buyCrateManager" },
	{ "LuckWizardManager", "luckWizardManager" },

	{ "CircleManager", "circleManager" },
}

ClientConfig["TICK_LIST"] = {

	"stashManager",

	"luckManager",
	"tutManager",
	"plotManager",

	"uiScaleManager",
	"musicManager",
	"vendorManager",

	"deleteManager",

	"buyEggManager",

	"hintManager",

	"tradeManager",

	"petManager",
	"orbManager",

	"buyCrateManager",

	"soundManager",
}

ClientConfig["TICK_RENDER_LIST"] = {
	"currManager",
	"weatherManager",
	"tweenManager",
	"vpManager",
	"rainbowManager",
	"placeManager",

	"petManager",
	"unitManager",

	"saveManager",
}

return ClientConfig
