local Common = require(game.ReplicatedStorage.Common)

local PLOT_COUNT = 8

local MapInfo = {
	PLOT_COUNT = PLOT_COUNT,
}

function MapInfo:getLandWhiteList()
	return {
		game.Workspace:FindFirstChild("Baseplate"),
		game.Workspace:FindFirstChild("Map1"),
		game.Workspace:FindFirstChild("SpawnLocation"),

		-- PLOTS
		game.Workspace:FindFirstChild("Plot1"),
		game.Workspace:FindFirstChild("Plot2"),
		game.Workspace:FindFirstChild("Plot3"),
		game.Workspace:FindFirstChild("Plot4"),
		game.Workspace:FindFirstChild("Plot5"),
		game.Workspace:FindFirstChild("Plot6"),
		game.Workspace:FindFirstChild("Plot7"),
		game.Workspace:FindFirstChild("Plot8"),
	}
end

return MapInfo
