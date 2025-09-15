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

		-- { "Satchel", "satchel" },

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
		{ "SellManager", "sellManager" },

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
		{ "EggManager", "eggManager" },

		{ "DamageManager", "damageManager" },

		{ "ClaimOfflineManager", "claimOfflineManager" },
		{ "AfkManager", "afkManager" },

		{ "LeaveManager", "leaveManager" },
		{ "FavoriteManager", "favoriteManager" },
		{ "FireworksManager", "fireworksManager" },
		{ "HatchManager", "hatchManager" },
		{ "AlertManager", "alertManager" },
	}

	local startTime = os.clock()

	for _, moduleInfo in ipairs(modulesToLoad) do
		local moduleClass, moduleAlias = moduleInfo[1], moduleInfo[2]
		local module = require(script.Parent:WaitForChild(moduleClass .. "Local"))
		ClientMod[moduleAlias] = module
	end

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
		"sellManager",
		"tradeManager",
		"uiScaleManager",
		"musicManager",
		"vendorManager",

		"gemManager",
		"deleteManager",

		"hintManager",

		-- "placeManager",
	}
	for _, moduleName in ipairs(moduleList) do
		if ClientMod[moduleName] then
			ClientMod[moduleName]:tick(timeRatio)
		end
	end

	for _, user in pairs(ClientMod.users) do
		user:tick()
	end

	for _, egg in pairs(ClientMod.eggs) do
		egg:tick(timeRatio)
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
	}
	for _, moduleName in ipairs(moduleList) do
		if ClientMod[moduleName] then
			ClientMod[moduleName]:tickRender(timeRatio)
		end
	end

	local petParts = {}
	local petCFrames = {}
	for _, pet in pairs(ClientMod.pets) do
		pet:tickRender(timeRatio)
		table.insert(petParts, pet.rig.PrimaryPart)
		table.insert(petCFrames, pet.rigFrame)
	end

	ClientMod.petManager:updatePetFrames(petParts, petCFrames)
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
