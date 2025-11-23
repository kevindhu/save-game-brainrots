local TeleportService = game:GetService("TeleportService")

local ServerMod = require(game.ServerScriptService:WaitForChild("ServerMod"))

local Common = require(game.ReplicatedStorage.Common)
local len = Common.len
local routine = Common.routine
local wait = task.wait

local TeleportManager = {}
TeleportManager.__index = TeleportManager

function TeleportManager:init() end

function TeleportManager:teleportUser(user, placeId, teleportOptions)
	if Common.isStudio then
		-- warn("TELEPORTING DISABLED IN STUDIO")
		return false, "Teleporting disabled in studio"
	end

	if not teleportOptions then
		-- cannot reserve server if already private server just dont reserve
		teleportOptions = Instance.new("TeleportOptions")
		teleportOptions.ShouldReserveServer = false

		local teleportData = {
			placeId = placeId,
		}
		teleportOptions:SetTeleportData(teleportData)
	end

	user.notifyManager:notifySuccess("Teleporting to " .. placeId .. "...")

	local player = user.player

	local retryLimit = 5
	local retryCount = 0
	local success, err
	repeat
		success, err = pcall(function()
			TeleportService:TeleportAsync(placeId, { player }, teleportOptions)
		end)

		if not success then
			retryCount += 1
			if retryCount < retryLimit then
				warn(string.format("Teleport attempt %d/%d failed: %s. Retrying...", retryCount, retryLimit, err))
				wait(1)
			end
		end
	until success or retryCount >= retryLimit

	if not success then
		warn("ERROR IDLE TELEPORTING USER AFTER " .. retryLimit .. " ATTEMPTS: ", err)
	end

	return success, err
end

return TeleportManager
