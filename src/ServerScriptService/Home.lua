local ServerMod = require(game.ServerScriptService:WaitForChild("ServerMod"))

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local Home = {}
Home.__index = Home

function Home.new(user)
	local u = {}
	u.owner = user
	u.user = user

	setmetatable(u, Home)
	return u
end

function Home:init() end

function Home:tickSecond()
	local moduleList = {
		"statManager",
		"boostManager",
	}
	for _, moduleName in ipairs(moduleList) do
		local module = self[moduleName]
		if not module then
			continue
		end
		module:tickSecond()
	end
end

function Home:initAllModules()
	local moduleList = {
		{ "IndexManager", "indexManager" },
		{ "ProbManager", "probManager" },

		{ "AlertManager", "alertManager" },

		{ "ShopManager", "shopManager" },
		{ "PlotManager", "plotManager" },
		{ "ToolManager", "toolManager" },
		{ "StatManager", "statManager" },
		{ "CodeManager", "codeManager" },

		{ "ItemStash", "itemStash" },
		{ "BadgeManager", "badgeManager" },
		{ "TradeManager", "tradeManager" },

		{ "TutManager", "tutManager" },

		{ "FriendManager", "friendManager" },
		-- { "CheatManager", "cheatManager" },

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

		{ "AdminManager", "adminManager" },
	}
	for _, moduleInfo in ipairs(moduleList) do
		self:loadModule(moduleInfo[1], moduleInfo[2])
	end
end

function Home:loadModule(moduleName, moduleAlias)
	local store = self.user.store

	local defaultInfo = {
		isNew = true,
	}
	local managerInfo = store:get(moduleAlias .. "Info") or defaultInfo

	local Module = require(game.ServerScriptService[moduleName])

	local manager = Module.new(self, managerInfo)
	manager.moduleAlias = moduleAlias
	manager:init()
	self[moduleAlias] = manager
end

function Home:tick(timeRatio)
	if self.destroyed then
		return
	end

	local managerList = {
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
	for _, managerClass in pairs(managerList) do
		local manager = self[managerClass]
		if not manager then
			continue
		end
		manager:tick(timeRatio)
	end
end

function Home:destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true

	local managerList = {
		"plotManager",
		"petManager",
		"unitManager",
		"saveManager",
		"adminManager",
	}
	for _, managerClass in pairs(managerList) do
		local manager = self[managerClass]
		if not manager then
			continue
		end
		manager:destroy()
	end
end

function Home:sync(otherUser)
	local modules = {
		"petManager",
		"unitManager",
		"speedManager",
	}
	for _, moduleName in ipairs(modules) do
		local module = self[moduleName]
		if module then
			module:sync(otherUser)
		end
	end
end

local saveModuleList = {
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

	"itemStash",
}

function Home:saveState()
	if self.user.destroying then
		return
	end

	for _, managerClass in pairs(saveModuleList) do
		local manager = self[managerClass]
		if not manager then
			continue
		end
		manager:saveState()
	end
end

function Home:wipeAllModules()
	print("WIPE ALL MODULES")
	for _, managerClass in pairs(saveModuleList) do
		local manager = self[managerClass]
		if not manager then
			continue
		end
		manager:wipe()
	end
end

return Home
