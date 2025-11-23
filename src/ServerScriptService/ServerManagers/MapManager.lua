local Map = {}

local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local MapInfo = require(game.ReplicatedStorage.Data.MapInfo)

function Map:init()
	if Common.testClonePlots then
		self:testClonePlots()
	end

	self:initSpawns()
	self:initFolders()

	self:initPlots()
end

function Map:testClonePlots()
	warn("####### TEST CLONE PLOTS #######")

	local cloneIndex = 1

	local basePlotModel = game.Workspace.Plots["Plot" .. cloneIndex]
	for i = 1, MapInfo.PLOT_COUNT do
		if i == cloneIndex then
			continue
		end

		local plotName = "Plot" .. i

		local oldModel = game.Workspace[plotName]
		local oldFloorPartFrame = oldModel.FloorPart.CFrame
		oldModel:Destroy()

		local model = basePlotModel:Clone()
		model.Name = plotName
		model.Parent = game.Workspace.Plots

		model.PrimaryPart = model.FloorPart
		model:PivotTo(oldFloorPartFrame)
	end
end

function Map:initSpawns()
	local spawnLocation = game.Workspace.SpawnLocation
	spawnLocation.Transparency = 1
	spawnLocation.CanCollide = false
	spawnLocation.Decal.Transparency = 1
end

function Map:initFolders()
	-- WORKSPACE FOLDERS
	local workspaceFolders = {
		"HitBoxes",

		"GlobalSounds",
		"MusicFolder",

		-- rigs
		"UserRigs",
		"PetRigs",
		"UnitRigs",

		"HighlightTemplateModels",
		"VendorHighlightModels",

		"ActiveSpellModels",

		"DamageParts",

		"NoticeModels",
		"BoughtPetSpots",
	}
	for _, folderName in pairs(workspaceFolders) do
		local folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = game.Workspace
	end

	-- REPLICATEDSTORAGE FOLDERS
	local replicatedStorageFolders = {
		"Events",
		"PetEvents",
	}
	for _, folderName in pairs(replicatedStorageFolders) do
		local folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = game.ReplicatedStorage
	end
end

function Map:initPlots()
	for i = 1, MapInfo.PLOT_COUNT do
		local plotName = "Plot" .. i
		local model = game.Workspace.Plots[plotName]
		if not model then
			warn("!! PLOT MODEL NOT FOUND: ", plotName)
			continue
		end

		model.RunawayPart.Transparency = 1
		model.UnitStartPart.Transparency = 1
	end
end

function Map:tick() end

function Map:obtainRandomPlotName()
	local emptyPlotNames = {}

	for i = 1, MapInfo.PLOT_COUNT do
		local plotName = "Plot" .. i

		-- check if this plot is used by any user
		local valid = true
		for _, user in pairs(ServerMod.userManager:getAllUsers()) do
			if not user.initialized then
				continue
			end
			if user.destroyed then
				warn("!! USER IS DESTROYED, SKIPPING: ", user.name)
				continue
			end

			local plotManager = user.plotManager
			if plotManager.plotName == plotName then
				valid = false
				break
			end
		end

		if valid then
			table.insert(emptyPlotNames, plotName)
		end
	end

	if len(emptyPlotNames) > 0 then
		return emptyPlotNames[math.random(1, #emptyPlotNames)]
	end

	warn("!!!! NO EMPTY PLOTS FOUND")
	return nil
end

Map:init()

return Map
