local RunService = game:GetService("RunService")

local player = game.Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerGui = player:WaitForChild("PlayerGui")

local ClientMod = require(playerScripts:WaitForChild("ClientMod"))

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

-- INIT ROBLOX CORE
routine(function()
	local ChatService = game:GetService("Chat")
	ChatService.BubbleChatEnabled = true
	ChatService:SetBubbleChatSettings({
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 30,
		Font = Enum.Font.Cartoon,
		Transparency = 0.1,
		MinimizeDistance = 100,
	})
end)

function LoadAllModules()
	-- first load replicated modules
	local replicatedModulesToLoad = {
		{ "AnimUtils", "animUtils" },
		{ "MutationManager", "mutationManager" },
		{ "PetPosManager", "petPosManager" },
		{ "WeldPetManager", "weldPetManager" },
		{ "RatingManager", "ratingManager" },
		{ "RainbowManager", "rainbowManager" },
	}
	for _, moduleInfo in ipairs(replicatedModulesToLoad) do
		local moduleClass, moduleAlias = moduleInfo[1], moduleInfo[2]
		local module = require(game.ReplicatedStorage[moduleClass])
		ClientMod[moduleAlias] = module
	end

	local modulesToLoad = {
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

		-- { "AdminManager", "adminManager" },
		-- { "PingManager", "pingManager" },
	}

	local startTime = os.clock()

	for _, moduleInfo in ipairs(modulesToLoad) do
		local moduleClass, moduleAlias = moduleInfo[1], moduleInfo[2]
		local module = require(script.Parent:WaitForChild(moduleClass .. "Local"))
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

	local moduleList = {
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
		"pingManager",
	}
	for _, moduleName in ipairs(moduleList) do
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

	local moduleList = {
		"currManager",
		"weatherManager",
		"tweenManager",
		"vpManager",
		"rainbowManager",
		"placeManager",
		-- "uiScaleManager",

		"petManager",
		"unitManager",

		"saveManager",
	}
	for _, moduleName in ipairs(moduleList) do
		if ClientMod[moduleName] then
			ClientMod[moduleName]:tickRender(timeRatio)
		end
	end
end)

function tickSecond()
	ClientMod.boostManager:tickSecond()

	-- for _, pet in pairs(ClientMod.pets) do
	-- 	pet:tickSecond()
	-- end
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
