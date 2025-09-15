local AnimInfo = require(game.ReplicatedStorage.AnimInfo)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local AnimUtils = {}
AnimUtils.__index = AnimUtils

function AnimUtils:init() end

function AnimUtils:clearAnimations(entity)
	if entity.destroyed then
		return
	end

	if not entity.raceTrackMods then
		return
	end
	for _, trackMod in pairs(entity.raceTrackMods) do
		trackMod["track"]:Stop()
		trackMod["track"]:Destroy()
	end
	entity.raceTrackMods = {}
end

function AnimUtils:animate(entity, data)
	if not entity.raceTrackMods then
		entity.raceTrackMods = {}
	end
	if not entity.trackMods then
		entity.trackMods = {}
	end

	local race = data["race"]
	local animationGroupClass = data["animationGroupClass"]
	local animationClass = data["animationClass"]
	local animationId = data["animationId"]
	local speedRatio = data["speedRatio"]

	if animationGroupClass then
		-- Animation groups allow cycling through a sequence of similar animations
		-- (e.g. attack1, attack2, attack3) to add variety
		local animationIds = AnimInfo.animationGroups[animationGroupClass]

		if not entity.animationGroupIndexMap then
			entity.animationGroupIndexMap = {}
		end
		if not entity.animationGroupIndexMap[animationGroupClass] then
			entity.animationGroupIndexMap[animationGroupClass] = 0
		end
		-- Increment and cycle through animations in this group
		entity.animationGroupIndexMap[animationGroupClass] += 1
		local index = (entity.animationGroupIndexMap[animationGroupClass] - 1) % #animationIds + 1
		animationId = animationIds[index]
	elseif not animationId then
		-- Single animation use case
		animationId = AnimInfo:getMeta(animationClass)
		if not animationId then
			warn("ANIMATION NOT FOUND: " .. animationClass)
			return
		end
	end

	local fadeTimer = 0.3

	-- Stop and clean up any existing animation of the same race
	-- "Race" refers to animation priority/category (e.g. "Walk", "Attack", "Idle")
	local oldTrackMod = entity.raceTrackMods[race]
	if oldTrackMod then
		local track = oldTrackMod["track"]
		track:AdjustWeight(0, fadeTimer)
		-- track:Destroy()
		entity.raceTrackMods[race] = nil
	end

	-- Get or create the animation track
	local trackMod = self:getTrackMod(entity, animationId)
	if not trackMod then
		-- warn(debug.traceback())
		-- warn("COULD NOT GET TRACK MOD: ", entity:getName(), animationId)
		return
	end

	local track = trackMod["track"]
	track:Play()
	track:AdjustWeight(1, fadeTimer)

	if speedRatio then
		track:AdjustSpeed(1 * speedRatio)
	end

	local newTrackMod = {
		animationId = animationId,
		track = track,
	}
	entity.raceTrackMods[race] = newTrackMod

	return trackMod
end

function AnimUtils:getTrackMod(entity, id)
	-- Handle special cases
	if tonumber(id) <= 0 then
		-- warn(debug.traceback())
		-- warn("NO TRACKMOD FOR: ", entity.unitClass or entity.petClass, id)
		return
	end

	local rig = entity.rig
	if not rig then
		return
	end
	local humanoid = rig:FindFirstChildWhichIsA("AnimationController")
	if not humanoid then
		humanoid = rig:FindFirstChildWhichIsA("Humanoid")
	end

	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChild("Animator")
	if not animator then
		animator = humanoid
	end

	-- Animation caching system: reuse tracks when possible to avoid
	-- creating unnecessary Animation instances
	local trackMods = entity.trackMods
	if trackMods[id] then
		if trackMods[id]["animator"] == animator then
			return trackMods[id]
		end
		-- warn("ANIMATOR CHANGED FOR ENTITY: ", entity:getName(), id)
	end

	-- Create and load a new animation when not cached
	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://" .. id

	local track = animator:LoadAnimation(animation)
	track.Name = "ANIMTRACK " .. id

	-- Cache the track for future use
	local newTrackMod = {
		track = track,
		animation = animation,
		animator = animator,
		markerConnections = {},
	}
	trackMods[id] = newTrackMod

	-- print("NEW TRACK MOD: ", newTrackMod, entity:getName(), id)

	local markerClasses = {
		"LeftSwingStart",
		"LeftSwingEnd",
		"RightSwingStart",
		"RightSwingEnd",
	}
	for _, markerClass in pairs(markerClasses) do
		local con = track:GetMarkerReachedSignal(markerClass):Connect(function(paramString)
			entity:handleAnimateMarker(markerClass)
		end)
		newTrackMod["markerConnections"][markerClass] = con
	end

	return newTrackMod
end

AnimUtils:init()

return AnimUtils
