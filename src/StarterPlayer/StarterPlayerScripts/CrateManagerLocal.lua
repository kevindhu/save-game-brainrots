local player = game.Players.LocalPlayer
local playerScripts = player.PlayerScripts
local playerGui = player.PlayerGui

local ClientMod = require(playerScripts.ClientMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local CrateInfo = require(game.ReplicatedStorage.CrateInfo)

local Crate = require(playerScripts.CrateLocal)

local CrateManager = {}
CrateManager.__index = CrateManager

function CrateManager:init() end

function CrateManager:newCrate(data)
	local crateName = data.crateName
	if ClientMod.crates[crateName] then
		return
	end

	local crate = Crate.new(data)
	crate:init()
	ClientMod.crates[crateName] = crate

	routine(function()
		wait(5)
		crate:destroy()
	end)
end

CrateManager:init()

return CrateManager
