local Common = require(game.ReplicatedStorage.Common)

local PLOT_COUNT = 8

local MapInfo = {
	PLOT_COUNT = PLOT_COUNT,
}

function MapInfo:getLandWhiteList()
	return {
		game.Workspace:FindFirstChild("Map1"),

		game.Workspace:FindFirstChild("Baseplate"),
		game.Workspace:FindFirstChild("SpawnLocation"),

		-- PLOTS
		game.Workspace:FindFirstChild("Plots"),
	}
end

return MapInfo
