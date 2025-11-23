local DataStoreService = game:GetService("DataStoreService")

local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local CrateInfo = require(game.ReplicatedStorage.Data.CrateInfo)
local SaveInfo = require(game.ReplicatedStorage.Data.SaveInfo)

local BuyCrateManager = {
	stockSchedule = {},
}
BuyCrateManager.__index = BuyCrateManager

local CRATE_INFO_VERSION = "v.0.0.1"
local STOCK_SCHEDULE_KEY = "StockSchedule_" .. CRATE_INFO_VERSION
local RESTOCK_INTERVAL = 5 * 60 -- 5 minutes in seconds
local RESTOCKS_TO_SCHEDULE = 60 -- 60 restocks (5 hours) worth of stock to generate

local DEBUG_ENABLED = false
function printDebug(...)
	if not DEBUG_ENABLED then
		return
	end
	print(...)
end

function BuyCrateManager:init()
	self.stockScheduleStore = DataStoreService:GetDataStore("StockSchedules_" .. SaveInfo.VERSION)

	-- Create a random fuzziness value (1 minute to 2 hours) for this server
	self.restockFuzziness = math.random(60, 2 * 60 * 60)

	routine(function()
		wait(1)

		-- for testing, toggle
		self.firstLoadSuccess = true
		-- self.firstLoadSuccess = self:loadStockSchedule()

		self.checkRetryLoadExpiree = os.time() + 30
		self.initialized = true
	end)
end

function BuyCrateManager:loadStockSchedule()
	local maxRetries = 5
	local retryCount = 0
	local success, scheduleMod

	while retryCount < maxRetries do
		success, scheduleMod = pcall(function()
			return self.stockScheduleStore:GetAsync(STOCK_SCHEDULE_KEY)
		end)

		-- Check if we have a valid schedule that extends into the future
		if success then
			if not scheduleMod then
				self:generateStockSchedule()
				scheduleMod = self.stockSchedule
			end

			self.stockSchedule = scheduleMod["schedule"]
			self.scheduleEndTime = scheduleMod["endTime"]

			return true
		else
			printDebug("FAILED TO LOAD STOCK SCHEDULE: ", success, scheduleMod)
			retryCount += 1
			if retryCount < maxRetries then
				warn(
					"Failed to load stock schedule (attempt "
						.. retryCount
						.. "/"
						.. maxRetries
						.. "). Retrying in 10 seconds..."
				)
				wait(10)
			end
		end
	end

	-- If we get here, all retries failed
	warn("Failed to load stock schedule after " .. maxRetries .. " attempts. A schedule must be generated.")
	self.stockSchedule = {}

	return false
end

function BuyCrateManager:generateStockSchedule()
	local now = os.time()
	local schedule = {}

	-- Determine the actual start time
	local startTime = now
	if self.stockSchedule and len(self.stockSchedule) > 0 and self.scheduleEndTime then
		-- Use the end time of existing schedule to extend from
		printDebug("EXTENDING SCHEDULE FROM: ", self.scheduleEndTime)
		startTime = self.scheduleEndTime
	end

	-- If extending existing schedule, start with existing entries
	if self.stockSchedule then
		-- Copy existing schedule entries
		for key, scheduleMod in pairs(self.stockSchedule) do
			schedule[key] = scheduleMod
		end
	end

	-- Trim old entries (older than 60 minutes from now)
	local trimThreshold = now - (60 * 60) -- 60 minutes ago
	for key, scheduleMod in pairs(schedule) do
		if scheduleMod.restockTime < trimThreshold then
			schedule[key] = nil
		end
	end

	local endTime = now + (RESTOCKS_TO_SCHEDULE * RESTOCK_INTERVAL)
	local currentTime = startTime

	-- Generate stock schedules for each 5-minute interval
	while currentTime < endTime do
		-- Calculate the exact restock time (aligned to 5-minute intervals from epoch)
		local intervalsSinceEpoch = math.floor(currentTime / RESTOCK_INTERVAL)
		local restockTime = intervalsSinceEpoch * RESTOCK_INTERVAL

		-- Only add future restock events that don't already exist
		if not schedule[tostring(restockTime)] then
			local newStock = {}

			-- Go through all crates in the crate list
			for _, crateClass in pairs(CrateInfo.stockCrateList) do
				local crateData = CrateInfo.crates[crateClass]

				-- Check if this crate should be restocked based on probCount
				local randomNum = math.random() * 100

				if randomNum < crateData.probCount then
					-- Generate stock count based on variationCount
					local minCount = crateData.variationCount[1]
					local maxCount = crateData.variationCount[2]
					local stockCount = math.random(minCount, maxCount)

					newStock[crateClass] = stockCount
				else
					newStock[crateClass] = 0
				end
			end

			printDebug("NEW STOCK: ", newStock)

			local newScheduleMod = {
				restockTime = restockTime,
				stock = newStock,
			}
			schedule[tostring(restockTime)] = newScheduleMod
		end

		-- Move to next restock interval
		currentTime = restockTime + RESTOCK_INTERVAL
	end

	-- Store the schedule in memory
	self.stockSchedule = schedule
	self.scheduleStartTime = startTime
	self.scheduleEndTime = endTime

	-- Store it in the DataStore for all servers
	local success, result = pcall(function()
		self.stockScheduleStore:SetAsync(STOCK_SCHEDULE_KEY, {
			startTime = startTime,
			endTime = endTime,
			schedule = schedule,
			generatedAt = now,
		})
	end)

	if not success then
		warn("Failed to save stock schedule:", result)
		return false
	end

	printDebug("Generated stock schedule until", os.date("%Y-%m-%d %H:%M:%S", self.scheduleEndTime))

	return true
end

function BuyCrateManager:checkRestock()
	if self.checkRestockExpiree and self.checkRestockExpiree > ServerMod.step then
		return
	end
	self.checkRestockExpiree = ServerMod.step + 30 -- Check every 30 seconds

	printDebug("CHECKING RESTOCK: ", self.stockSchedule)

	if not self.stockSchedule or len(self.stockSchedule) == 0 then
		return
	end

	local oldActiveScheduleMod = self.activeScheduleMod
	local oldRestockTime = 0
	if oldActiveScheduleMod then
		oldRestockTime = oldActiveScheduleMod.restockTime
	end

	local activeScheduleMod = self:getActiveScheduleMod()
	local restockTime = activeScheduleMod.restockTime

	if activeScheduleMod and math.abs(restockTime - oldRestockTime) > 60 and restockTime > oldRestockTime then
		self.activeScheduleMod = activeScheduleMod
		self:applyRestock(activeScheduleMod)
	end
end

function BuyCrateManager:checkScheduleGeneration()
	-- cannot generate a schedule if failed to first load! Corrupted server!
	if not self.firstLoadSuccess then
		return
	end

	if self.checkGenerateExpiree and self.checkGenerateExpiree > os.time() then
		return
	end
	self.checkGenerateExpiree = os.time() + 5

	-- Check if we need to generate a new schedule
	if not self.scheduleEndTime then
		self.scheduleEndTime = os.time()
	end

	local now = os.time()
	local bufferTime = 10 * RESTOCK_INTERVAL -- 10 restocks (50 minutes) buffer

	-- If we're within buffer time + fuzziness of the end time, try to generate
	if (now + bufferTime + self.restockFuzziness) > self.scheduleEndTime then
		printDebug("END OF STOCK SCHEDULE, AUTOMATICALLY GENERATING NEW SCHEDULE")
		self:generateStockSchedule()
	end
end

function BuyCrateManager:getActiveScheduleMod()
	local currTimestamp = os.time()

	-- Find the most recent restock that should be active
	local latestRestock = nil
	local latestTime = 0

	for _, scheduleMod in pairs(self.stockSchedule) do
		local restockTime = scheduleMod["restockTime"]
		if currTimestamp >= restockTime and restockTime > latestTime then
			latestRestock = scheduleMod
			latestTime = restockTime
		end
	end

	return latestRestock
end

function BuyCrateManager:applyRestock(scheduleMod)
	self.currentStock = scheduleMod.stock
	self.lastRestockTime = scheduleMod.restockTime

	printDebug("APPLYING RESTOCK: ", scheduleMod.stock)

	-- Sync to all users
	for _, user in pairs(ServerMod.userManager:getAllUsers()) do
		if not user.initialized then
			continue
		end

		user.notifyManager:notifySuccess("The crate shop has been restocked!")
		ServerMod:FireClient(user.player, "newSoundMod", {
			soundClass = "SoftSuccess",
		})
		self:sync(user)
	end

	printDebug("APPLIED RESTOCK: ", os.date("%Y-%m-%d %H:%M:%S", scheduleMod.restockTime), ":", scheduleMod.stock)
end

function BuyCrateManager:sync(user)
	if not self.activeScheduleMod then
		return
	end

	user.crateManager:updateStock(self.activeScheduleMod)
end

function BuyCrateManager:retryLoadStockSchedule()
	if self.checkRetryLoadExpiree and self.checkRetryLoadExpiree > os.time() then
		return
	end
	self.checkRetryLoadExpiree = os.time() + 60

	self:loadStockSchedule()
end

function BuyCrateManager:tick()
	if not self.initialized then
		return
	end

	self:retryLoadStockSchedule()
	self:checkRestock()
	self:checkScheduleGeneration()
end

BuyCrateManager:init()

return BuyCrateManager
