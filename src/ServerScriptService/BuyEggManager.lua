local DataStoreService = game:GetService("DataStoreService")

local ServerMod = require(game.ServerScriptService.ServerMod)

local Common = require(game.ReplicatedStorage.Common)
local len, routine, wait = Common.len, Common.routine, Common.wait

local EggInfo = require(game.ReplicatedStorage.EggInfo)
local SaveInfo = require(game.ReplicatedStorage.SaveInfo)

local BuyEggManager = {
	stockSchedule = {},
}
BuyEggManager.__index = BuyEggManager

local EGG_INFO_VERSION = "v.0.0.1"
local STOCK_SCHEDULE_KEY = "StockSchedule_" .. EGG_INFO_VERSION
local RESTOCK_INTERVAL = 5 * 60 -- 5 minutes in seconds
local RESTOCKS_TO_SCHEDULE = 60 -- 60 restocks (5 hours) worth of stock to generate

function BuyEggManager:init()
	self.stockScheduleStore = DataStoreService:GetDataStore("StockSchedules_" .. SaveInfo.VERSION)

	-- Create a random fuzziness value (1 minute to 2 hours) for this server
	self.restockFuzziness = math.random(60, 2 * 60 * 60)

	routine(function()
		wait(1)

		-- for testing, toggle
		-- self.firstLoadSuccess = true
		self.firstLoadSuccess = self:loadStockSchedule()

		self.checkRetryLoadExpiree = os.time() + 30
		self.initialized = true
	end)
end

function BuyEggManager:loadStockSchedule()
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
			print("FAILED TO LOAD STOCK SCHEDULE: ", success, scheduleMod)
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

function BuyEggManager:generateStockSchedule()
	local now = os.time()
	local schedule = {}

	-- Determine the actual start time
	local startTime = now
	if self.stockSchedule and len(self.stockSchedule) > 0 and self.scheduleEndTime then
		-- Use the end time of existing schedule to extend from
		print("EXTENDING SCHEDULE FROM: ", self.scheduleEndTime)
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

			-- Go through all eggs in the egg list
			for _, eggClass in pairs(EggInfo.stockEggList) do
				local eggData = EggInfo.eggs[eggClass]

				-- Check if this egg should be restocked based on probCount
				local randomNum = math.random() * 100

				if randomNum < eggData.probCount then
					-- Generate stock count based on variationCount
					local minCount = eggData.variationCount[1]
					local maxCount = eggData.variationCount[2]
					local stockCount = math.random(minCount, maxCount)

					newStock[eggClass] = stockCount
				else
					newStock[eggClass] = 0
				end
			end

			-- print("NEW STOCK: ", newStock)

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

	print("Generated stock schedule until", os.date("%Y-%m-%d %H:%M:%S", self.scheduleEndTime))

	return true
end

function BuyEggManager:checkRestock()
	if self.checkRestockExpiree and self.checkRestockExpiree > ServerMod.step then
		return
	end
	self.checkRestockExpiree = ServerMod.step + 30 -- Check every 30 seconds

	-- print("CHECKING RESTOCK: ", self.stockSchedule)

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

function BuyEggManager:checkScheduleGeneration()
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
		print("END OF STOCK SCHEDULE, AUTOMATICALLY GENERATING NEW SCHEDULE")
		self:generateStockSchedule()
	end
end

function BuyEggManager:getActiveScheduleMod()
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

function BuyEggManager:applyRestock(scheduleMod)
	self.currentStock = scheduleMod.stock
	self.lastRestockTime = scheduleMod.restockTime

	-- print("APPLYING RESTOCK: ", scheduleMod.stock)

	-- Sync to all users
	for _, user in pairs(ServerMod.users) do
		if not user.initialized then
			continue
		end

		user:notifySuccess("The egg shop has been restocked!")
		ServerMod:FireClient(user.player, "newSoundMod", {
			soundClass = "SoftSuccess",
		})
		self:sync(user)
	end

	print("APPLIED RESTOCK: ", os.date("%Y-%m-%d %H:%M:%S", scheduleMod.restockTime), ":", scheduleMod.stock)
end

function BuyEggManager:sync(user)
	if not self.activeScheduleMod then
		return
	end

	user.home.eggManager:updateStock(self.activeScheduleMod)
end

function BuyEggManager:retryLoadStockSchedule()
	if self.checkRetryLoadExpiree and self.checkRetryLoadExpiree > os.time() then
		return
	end
	self.checkRetryLoadExpiree = os.time() + 60

	self:loadStockSchedule()
end

function BuyEggManager:tick()
	if not self.initialized then
		return
	end

	self:retryLoadStockSchedule()
	self:checkRestock()
	self:checkScheduleGeneration()
end

BuyEggManager:init()

return BuyEggManager
