local RunService = game:GetService("RunService")

local player = game.Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerGui = player:WaitForChild("PlayerGui")

local ClientMod = require(playerScripts:WaitForChild("ClientMod"))

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

-- first load replicated modules
local REPLICATED_MODULES_LIST = {
	{ "AnimUtils", "animUtils" },
	{ "MutationManager", "mutationManager" },
	{ "WeldPetManager", "weldPetManager" },
	{ "RatingManager", "ratingManager" },
	{ "RainbowManager", "rainbowManager" },
}

local CLIENT_MODULES_LIST = {
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

	{ "ItemStash", "itemStash" },
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

local TICK_LIST = {

	"itemStash",

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

local TICK_RENDER_LIST = {
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

function LoadAllModules()
	for _, moduleInfo in ipairs(REPLICATED_MODULES_LIST) do
		local moduleClass, moduleAlias = moduleInfo[1], moduleInfo[2]
		local modulePath = game.ReplicatedStorage:WaitForChild("SharedManagers"):WaitForChild(moduleClass, 2)
		if not modulePath then
			warn("!!! NO MODULE PATH FOUND: ", moduleClass)
			continue
		end
		ClientMod[moduleAlias] = require(modulePath)
	end

	local startTime = os.clock()

	for _, moduleInfo in ipairs(CLIENT_MODULES_LIST) do
		local moduleClass, moduleAlias = moduleInfo[1], moduleInfo[2]
		local module = require(playerScripts:WaitForChild("ClientManagers"):WaitForChild(moduleClass .. "Local"))
		ClientMod[moduleAlias] = module
	end

	ClientMod.itemStash:newBottomMod({
		itemName = "Bat1",
		itemClass = "Bat1",
		mutationClass = nil,
		index = -1,
	})
	ClientMod.itemStash:refreshAllBottomModTweens()

	-- print(("CLIENT LOAD MODULES: %.2f seconds"):format(os.clock() - startTime))
end

function LoadUsers()
	ClientMod.userManager:addUser({
		name = player.Name,
		player = player,
	})
end

LoadAllModules()
LoadUsers()

RunService.Heartbeat:Connect(function(deltaTime)
	local timeRatio = deltaTime / (1 / 60)

	ClientMod:tick(timeRatio)

	for _, moduleName in ipairs(TICK_LIST) do
		if ClientMod[moduleName] then
			-- print("TICKING MODULE: ", moduleName)
			ClientMod[moduleName]:tick(timeRatio)
		end
	end

	for _, user in pairs(ClientMod.users) do
		user:tick()
	end
end)

RunService.RenderStepped:Connect(function(deltaTime)
	local timeRatio = deltaTime / (1 / 60)

	for _, moduleName in ipairs(TICK_RENDER_LIST) do
		if ClientMod[moduleName] then
			ClientMod[moduleName]:tickRender(timeRatio)
		end
	end
end)

function tickSecond()
	ClientMod.boostManager:tickSecond()
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
