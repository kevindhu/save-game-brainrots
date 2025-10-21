local ServerMod = require(script.Parent.ServerMod)

local Players = game:GetService("Players")

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local ServerStore = {
	profiles = {},
}

function ServerStore:init() end

function ServerStore:releaseProfile(profile)
	profile:EndSession()
end

function ServerStore:getVersionQuery(profileKey, minDate, maxDate)
	local ProfileStore = require(script.Parent.ProfileStore)
	local profileStore = ProfileStore.New("PlayerData", {})

	local versionQuery = profileStore:VersionQuery(profileKey, Enum.SortDirection.Descending, minDate, maxDate)
	return versionQuery
end

function ServerStore:getPlayerProfile(user, profileKey, addUserId, viewOnly)
	local ProfileStore = require(script.Parent.ProfileStore)

	-- Define a proper template
	local PROFILE_TEMPLATE = {
		-- Add your default data structure here
	}
	local profileStore = ProfileStore.New("PlayerData", PROFILE_TEMPLATE)

	local startTime = os.clock()
	local profile

	if viewOnly then
		profile = profileStore:GetAsync(profileKey)
	else
		profile = profileStore:StartSessionAsync(profileKey, {
			Cancel = function()
				return user.player.Parent ~= Players
			end,
		})
	end

	if Common.checkDeveloper(user.userId) then
		print("LOAD PROFILE: ", os.clock() - startTime)
	end

	local player = user.player
	if profile ~= nil then
		if addUserId then
			profile:AddUserId(user.userId) -- GDPR compliance
		end

		-- -- Reconcile to ensure all template fields exist
		-- profile:Reconcile()

		profile.OnSessionEnd:Connect(function()
			self.profiles[player] = nil
			-- The profile could've been loaded on another Roblox server:
			player:Kick("Unable to load saved data, please rejoin.")
		end)

		if player:IsDescendantOf(Players) == true then
			self.profiles[player] = profile
		else
			-- Player left before the profile loaded:
			profile:EndSession()
		end
	else
		-- The profile couldn't be loaded possibly due to other
		--   Roblox servers trying to load this profile at the same time:
		player:Kick("Unable to load saved data, please rejoin.")
	end

	return profile
end

ServerStore:init()

return ServerStore
