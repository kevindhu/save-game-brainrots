local RunService = game:GetService("RunService")

local player = game.Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts")
local playerGui = player:WaitForChild("PlayerGui")

local ClientMod = require(playerScripts:WaitForChild("ClientMod"))

local ClientConfig = require(playerScripts.Configs.ClientConfig)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

function LoadAllModules()
	for _, moduleInfo in ipairs(ClientConfig.REPLICATED_MODULES_LIST) do
		local moduleClass, moduleAlias = moduleInfo[1], moduleInfo[2]
		local modulePath = game.ReplicatedStorage:WaitForChild("SharedManagers"):WaitForChild(moduleClass, 2)
		if not modulePath then
			warn("!!! NO MODULE PATH FOUND: ", moduleClass)
			continue
		end
		ClientMod[moduleAlias] = require(modulePath)
	end

	local startTime = os.clock()

	for _, moduleInfo in ipairs(ClientConfig.CLIENT_MODULES_LIST) do
		local moduleClass, moduleAlias = moduleInfo[1], moduleInfo[2]
		local module = require(playerScripts:WaitForChild("ClientManagers"):WaitForChild(moduleClass .. "Local"))
		ClientMod[moduleAlias] = module
	end

	ClientMod.stashManager:newBottomMod({
		itemName = "Bat1",
		itemClass = "Bat1",
		mutationClass = nil,
		index = -1,
	})
	ClientMod.stashManager:refreshAllBottomModTweens()

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

	for _, moduleName in ipairs(ClientConfig.TICK_LIST) do
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

	for _, moduleName in ipairs(ClientConfig.TICK_RENDER_LIST) do
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
