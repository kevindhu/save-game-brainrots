local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local ServerConfig = require(game.ServerScriptService.Configs.ServerConfig)

function LoadAllModules()
	for _, moduleData in pairs(ServerConfig.SERVERMANAGERS_LIST) do
		local moduleClass, moduleAlias = moduleData[1], moduleData[2]
		local module = require(game.ServerScriptService.ServerManagers[moduleClass])
		ServerMod[moduleAlias] = module
	end

	local replicatedModulesToLoad = ServerConfig.REPLICATED_LIST
	for _, moduleData in pairs(replicatedModulesToLoad) do
		local moduleClass, moduleAlias = moduleData[1], moduleData[2]
		local module = require(game.ReplicatedStorage.SharedManagers[moduleClass])
		ServerMod[moduleAlias] = module
	end
end

function TickSecond()
	-- tick users
	ServerMod.userManager:tickSecond()
	ServerMod.leaderManager:tickSecond()
end

function StartAllEvents()
	-- SERVER TICK EVENTS
	game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		local timeRatio = deltaTime / (1 / 60)
		ServerMod:tick(timeRatio)

		for _, managerClass in pairs(ServerConfig.TICK_LIST) do
			local manager = ServerMod[managerClass]
			if not manager or not manager.tick then
				warn("NO TICK FUNCTION FOR MANAGER: ", managerClass)
				continue
			end
			manager:tick(timeRatio)
		end
	end)

	routine(function()
		while true do
			routine(function()
				local success, err = pcall(function()
					TickSecond()
				end)
				if not success then
					warn("############# TICK SECOND FAILED: ", err)
				end
			end)
			wait(1)
		end
	end)
end

function Run()
	LoadAllModules()
	StartAllEvents()
end

Run()
