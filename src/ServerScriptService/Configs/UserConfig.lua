local RunInfo = {}

RunInfo["USERMANAGERS_LIST"] = {
	{ "IndexManager", "indexManager" },
	{ "ProbManager", "probManager" },

	{ "NotifyManager", "notifyManager" },
	{ "AlertManager", "alertManager" },

	{ "ShopManager", "shopManager" },
	{ "PlotManager", "plotManager" },
	{ "ToolManager", "toolManager" },
	{ "StatManager", "statManager" },
	{ "CodeManager", "codeManager" },

	{ "StashManager", "stashManager" },
	{ "BadgeManager", "badgeManager" },
	{ "TradeManager", "tradeManager" },

	{ "TutManager", "tutManager" },

	{ "FriendManager", "friendManager" },

	{ "TestManager", "testManager" },

	{ "BoostManager", "boostManager" },
	{ "RewardManager", "rewardManager" },

	{ "AnalyticsManager", "analyticsManager" },

	{ "PetManager", "petManager" },
	{ "UnitManager", "unitManager" },

	{ "DamageManager", "damageManager" },

	{ "AfkManager", "afkManager" },
	{ "FavoriteManager", "favoriteManager" },

	{ "SaveManager", "saveManager" },

	{ "SpeedManager", "speedManager" },

	{ "CrateManager", "crateManager" },

	{ "PityManager", "pityManager" },
	{ "AutoSellManager", "autoSellManager" },
	{ "LuckWizardManager", "luckWizardManager" },

	{ "CommandManager", "commandManager" },
}

RunInfo["TICK_SECOND_LIST"] = {
	"statManager",
	"boostManager",
}

RunInfo["TICK_LIST"] = {
	"tutManager",
	"toolManager",

	"tradeManager",

	"damageManager",
	"favoriteManager",
	"friendManager",

	"petManager",
	"unitManager",
	"saveManager",

	"toolManager",
}

RunInfo["SAVE_LIST"] = {
	"indexManager",
	"shopManager",
	"plotManager",
	"statManager",

	"badgeManager",
	"boostManager",
	"favoriteManager",

	"crateManager",
	"tutManager",

	"petManager",

	"rewardManager",
	"testManager",

	"speedManager",
	"pityManager",
	"autoSellManager",

	"saveManager",
	"luckWizardManager",

	"stashManager",
}

RunInfo["DESTROY_LIST"] = {
	"plotManager",
	"petManager",
	"unitManager",
	"saveManager",
	"commandManager",
}

RunInfo["SYNC_LIST"] = {
	"petManager",
	"unitManager",
	"speedManager",
}

return RunInfo
