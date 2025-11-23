local DataStoreService = game:GetService("DataStoreService")

local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local WeatherInfo = require(game.ReplicatedStorage.Data.WeatherInfo)
local SaveInfo = require(game.ReplicatedStorage.Data.SaveInfo)

local WeatherManager = {
	weatherSchedule = {},
}
WeatherManager.__index = WeatherManager

local version = SaveInfo.VERSION
local WEATHER_SCHEDULE_KEY = "WeatherSchedule_" .. version
local DAYS_TO_SCHEDULE = 60 -- 60 -- Days worth of weather events to generate

function WeatherManager:init()
	self.weatherScheduleStore = DataStoreService:GetDataStore("WeatherSchedules_" .. SaveInfo.VERSION)

	-- Create a random fuzziness value (1-10 hours in seconds) for this server
	self.generationFuzziness = math.random(3600, 36000) -- 1 to 10 hours in seconds

	routine(function()
		wait(1)
		-- self:loadWeatherSchedule()

		self.initialized = true
	end)
end

function WeatherManager:loadWeatherSchedule()
	local maxRetries = 5
	local retryCount = 0
	local success, scheduleMod

	while retryCount < maxRetries do
		success, scheduleMod = pcall(function()
			return self.weatherScheduleStore:GetAsync(WEATHER_SCHEDULE_KEY)
		end)

		-- Check if we have a valid schedule that extends into the future
		if success then
			if not scheduleMod then
				self:generateWeatherSchedule()
				scheduleMod = self.weatherSchedule
			end

			self.weatherSchedule = scheduleMod["schedule"]
			self.scheduleEndTime = scheduleMod["endTime"]

			-- print("Loaded existing weather schedule until", os.date("%Y-%m-%d %H:%M:%S", self.scheduleEndTime))

			self.weatherLoadFailed = false
			return true
		else
			print("FAILED TO LOAD WEATHER SCHEDULE: ", success, scheduleMod)
			retryCount += 1
			if retryCount < maxRetries then
				warn(
					"Failed to load weather schedule (attempt "
						.. retryCount
						.. "/"
						.. maxRetries
						.. "). Retrying in 10 seconds..."
				)
				wait(10) -- Wait 10 seconds before retrying
			end
		end
	end

	-- If we get here, all retries failed
	warn("Failed to load weather schedule after " .. maxRetries .. " attempts. A schedule must be generated.")
	self.weatherSchedule = {}
	self.weatherLoadFailed = true

	return false
end

function WeatherManager:generateWeatherSchedule()
	local now = os.time()
	local startTime = now
	local dayInSeconds = 86400
	local endTime = now + (DAYS_TO_SCHEDULE * dayInSeconds)

	local schedule = {}
	local currentTime = startTime

	-- Generate weather events back-to-back with no gaps
	while currentTime < endTime do
		local weatherType = Common.rollFromProbMap(WeatherInfo.eventWeightMap)
		local intensity = math.random(1, 10) -- Weather intensity 1-10

		-- Get duration range for this weather type
		local weatherInfo = WeatherInfo.events[weatherType]
		local durationRange = weatherInfo.durationRange or { 3, 6 } -- Default 3-6 minutes
		local durationMinutes = math.random(durationRange[1], durationRange[2])
		local durationSeconds = durationMinutes * 60

		local weatherEndTime = currentTime + durationSeconds

		-- Only add future weather events
		if currentTime >= now or Common.isStudio then
			local newScheduleMod = {
				startTime = currentTime,
				endTime = weatherEndTime,
				eventClass = weatherType,
				intensity = intensity,
				durationMinutes = durationMinutes,
			}
			schedule[tostring(currentTime)] = newScheduleMod
		end

		-- Move directly to the end of this event (no gap)
		currentTime = weatherEndTime
	end

	-- Store the schedule in memory
	self.weatherSchedule = schedule
	self.scheduleStartTime = startTime
	self.scheduleEndTime = endTime

	-- Store it in the DataStore for all servers
	local success, result = pcall(function()
		self.weatherScheduleStore:SetAsync(WEATHER_SCHEDULE_KEY, {
			startTime = startTime,
			endTime = endTime,
			schedule = schedule,
			generatedAt = now,
		})
	end)

	if not success then
		warn("Failed to save weather schedule:", result)
		return false
	end

	-- local pacificTime = os.date("%Y-%m-%d %H:%M:%S", self.scheduleEndTime - 8 * 3600) -- Simplified to PST (UTC-8)
	-- print("Generated weather schedule until", pacificTime, "(Pacific Time)")

	return true
end

function WeatherManager:checkStartNewWeather()
	if self.checkStartNewWeatherExpiree and self.checkStartNewWeatherExpiree > ServerMod.step then
		return
	end
	self.checkStartNewWeatherExpiree = ServerMod.step + 60 * 0.5

	if self.currentWeather then
		return
	end
	if not self.weatherSchedule or len(self.weatherSchedule) == 0 then
		return
	end

	local activeScheduleMod = self:getActiveScheduleMod()

	if activeScheduleMod then
		self:startWeatherEvent(activeScheduleMod)
	end
end

function WeatherManager:checkScheduleGeneration()
	-- cannot generate a schedule if failed to load weather data! Corrupted server!
	if self.weatherLoadFailed then
		return
	end

	if self.checkGenerateExpiree and self.checkGenerateExpiree > os.time() then
		return
	end
	self.checkGenerateExpiree = os.time() + 5

	-- Check if we need to generate a new schedule
	if not self.scheduleEndTime then
		-- 100% will generate a new schedule
		-- print("NO SCHEDULE END TIME, GENERATING NEW SCHEDULE")
		self.scheduleEndTime = os.time()
	end

	local now = os.time()
	local bufferDays = 3 * 86400 -- 3 days in seconds

	-- If we're within (3 days + fuzziness) of the end time, try to generate
	if (now + bufferDays + self.generationFuzziness) > self.scheduleEndTime then
		-- print("END OF WEATHER SCHEDULE, AUTOMATICALLY GENERATING NEW SCHEDULE")
		self:generateWeatherSchedule()
	end
end

function WeatherManager:getActiveScheduleMod()
	local currTimestamp = os.time()

	-- Find the weather event that should be active at this time
	for _, scheduleMod in pairs(self.weatherSchedule) do
		local startTime = scheduleMod["startTime"]
		local endTime = scheduleMod["endTime"]
		if currTimestamp >= startTime and currTimestamp < endTime then
			return scheduleMod
		end
	end
	return nil
end

function WeatherManager:startWeatherEvent(scheduleMod)
	if self.currentScheduleMod and self.currentScheduleMod["endTime"] > os.time() then
		return
	end

	-- Implement your weather event logic here
	self.currentScheduleMod = scheduleMod
	self.endTime = scheduleMod["endTime"]

	-- local remainingSeconds = self.endTime - os.time()
	-- print("Starting weather event: ", scheduleMod)
	-- print("Remaining seconds: ", remainingSeconds)

	for _, user in pairs(ServerMod.userManager:getAllUsers()) do
		self:sync(user)
	end
end

function WeatherManager:sync(user)
	if not self.currentScheduleMod then
		return
	end

	local weatherData = {
		eventMod = {
			eventClass = self.currentScheduleMod["eventClass"],
		},
	}
	ServerMod:FireClient(user.player, "updateWeather", weatherData)
end

function WeatherManager:tick()
	if not self.initialized then
		return
	end

	self:retryFailedWeatherSchedule()

	self:checkStartNewWeather()
	self:checkScheduleGeneration()
end

function WeatherManager:retryFailedWeatherSchedule()
	if not self.weatherLoadFailed then
		return
	end
	if self.checkRetryLoadExpiree and self.checkRetryLoadExpiree > os.time() then
		return
	end
	self.checkRetryLoadExpiree = os.time() + 30

	self:loadWeatherSchedule()
end

WeatherManager:init()

return WeatherManager
